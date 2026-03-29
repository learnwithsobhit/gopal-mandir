//! Public API: Guru/Baba pooja appointments.

use actix_web::{get, patch, post, web, HttpResponse};
use chrono::{Duration, NaiveDate, Utc};
use serde::Serialize;
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::*;
use crate::pooja_logic::{
    booking_amount_paise, compute_scheduled_at_utc, count_blocking_bookings, max_per_slot, slot_has_capacity,
};
use crate::razorpay::{self, RazorpayConfig};
use crate::util::truncate_payment_reason;

const RESCHEDULE_CUTOFF_HOURS: i64 = 48;

fn parse_officiant(s: &str) -> Option<&'static str> {
    match s.trim().to_lowercase().as_str() {
        "guru" => Some("guru"),
        "baba" => Some("baba"),
        _ => None,
    }
}

fn venue_db(s: &str) -> Option<&'static str> {
    match s.trim().to_lowercase().as_str() {
        "temple" => Some("temple"),
        "devotee_home" | "home" => Some("devotee_home"),
        _ => None,
    }
}

fn member_may_change_event_time(scheduled_at: chrono::DateTime<Utc>) -> bool {
    let cutoff = scheduled_at - Duration::hours(RESCHEDULE_CUTOFF_HOURS);
    Utc::now() <= cutoff
}

#[derive(Serialize)]
struct PoojaAvailabilitySlot {
    slot_id: i32,
    label: String,
    capacity: i32,
    booked: i64,
    available: i64,
}

#[derive(Serialize)]
struct PoojaAvailabilityDay {
    date: String,
    officiant: String,
    slots: Vec<PoojaAvailabilitySlot>,
}

#[get("/api/pooja/offerings")]
pub async fn pooja_list_offerings(pool: web::Data<PgPool>) -> HttpResponse {
    let offerings: Vec<(i32, String, String, i32, i32, i32)> = match sqlx::query_as(
        "SELECT id, name, description, base_price_paise, slots_consumed, sort_order
         FROM pooja_offerings WHERE active = TRUE ORDER BY sort_order, id",
    )
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(v) => v,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let mut out: Vec<PoojaOfferingWithPackages> = Vec::new();
    for (id, name, description, base_price_paise, slots_consumed, sort_order) in offerings {
        let packages = match sqlx::query_as::<_, PoojaOfferingPackageRow>(
            "SELECT id, offering_id, name, description, additional_price_paise, sort_order
             FROM pooja_offering_packages WHERE offering_id = $1 AND active = TRUE
             ORDER BY sort_order, id",
        )
        .bind(id)
        .fetch_all(pool.get_ref())
        .await
        {
            Ok(v) => v,
            Err(e) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        };
        out.push(PoojaOfferingWithPackages {
            id,
            name,
            description,
            base_price_paise,
            slots_consumed,
            sort_order,
            packages,
        });
    }

    HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": out }))
}

#[derive(serde::Deserialize)]
pub struct PoojaAvailabilityQuery {
    pub officiant: String,
    pub from: String,
    pub to: String,
}

#[get("/api/pooja/availability")]
pub async fn pooja_availability(
    pool: web::Data<PgPool>,
    q: web::Query<PoojaAvailabilityQuery>,
) -> HttpResponse {
    let Some(off) = parse_officiant(&q.officiant) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "officiant must be guru or baba"
        }));
    };

    let from_d = match NaiveDate::parse_from_str(q.from.trim(), "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "from must be YYYY-MM-DD"
            }))
        }
    };
    let to_d = match NaiveDate::parse_from_str(q.to.trim(), "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "to must be YYYY-MM-DD"
            }))
        }
    };
    if to_d < from_d {
        return HttpResponse::BadRequest()
            .json(serde_json::json!({ "success": false, "error": "to before from" }));
    }

    let slots: Vec<PoojaSlotDefinition> = match sqlx::query_as(
        "SELECT id, label, start_time, end_time, sort_order FROM pooja_slot_definitions ORDER BY sort_order, id",
    )
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(v) => v,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let cap = match max_per_slot(pool.get_ref(), off).await {
        Ok(c) => c,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let mut days: Vec<PoojaAvailabilityDay> = Vec::new();
    let mut d = from_d;
    while d <= to_d {
        let mut day_slots: Vec<PoojaAvailabilitySlot> = Vec::new();
        for sl in &slots {
            let booked: i64 = match count_blocking_bookings(pool.get_ref(), d, sl.id, off, None).await {
                Ok(n) => n,
                Err(e) => {
                    return HttpResponse::InternalServerError().json(serde_json::json!({
                        "success": false,
                        "error": format!("Database error: {}", e)
                    }))
                }
            };
            let available = (cap as i64 - booked).max(0);
            day_slots.push(PoojaAvailabilitySlot {
                slot_id: sl.id,
                label: sl.label.clone(),
                capacity: cap,
                booked,
                available,
            });
        }
        days.push(PoojaAvailabilityDay {
            date: d.format("%Y-%m-%d").to_string(),
            officiant: off.to_string(),
            slots: day_slots,
        });
        d = match d.succ_opt() {
            Some(x) => x,
            None => break,
        };
    }

    HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": days }))
}

#[post("/api/pooja/booking")]
pub async fn pooja_create_booking(
    pool: web::Data<PgPool>,
    body: web::Json<PoojaBookingCreateRequest>,
) -> HttpResponse {
    let Some(off) = parse_officiant(&body.officiant) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "officiant must be guru or baba"
        }));
    };
    let Some(venue) = venue_db(&body.venue) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "venue must be temple or devotee_home"
        }));
    };
    if venue == "devotee_home" {
        let addr = body.address.as_ref().map(|s| s.trim()).unwrap_or("");
        if addr.is_empty() {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "address required for home visit"
            }));
        }
    }

    let booking_date = match NaiveDate::parse_from_str(body.booking_date.trim(), "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "booking_date must be YYYY-MM-DD"
            }))
        }
    };

    let scheduled_at = match compute_scheduled_at_utc(pool.get_ref(), body.booking_date.trim(), body.slot_id).await {
        Ok(t) => t,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };

    let amount = match booking_amount_paise(pool.get_ref(), body.offering_id, body.package_id).await {
        Ok(a) => a,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };

    match slot_has_capacity(pool.get_ref(), booking_date, body.slot_id, off, None).await {
        Ok(true) => {}
        Ok(false) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "This slot is fully booked"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    }

    let reference_id = format!(
        "POOJA-{}",
        Uuid::new_v4()
            .to_string()
            .split('-')
            .next()
            .unwrap_or("0000")
    );

    let addr = body.address.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());
    let notes = body.notes.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());

    let ins = sqlx::query(
        "INSERT INTO pooja_bookings (
            reference_id, offering_id, package_id, officiant, slot_id, booking_date, scheduled_at,
            venue, address, name, phone, notes, booking_status, payment_status, amount_paise
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'pending_confirmation','not_applicable',$13)",
    )
    .bind(&reference_id)
    .bind(body.offering_id)
    .bind(body.package_id)
    .bind(off)
    .bind(body.slot_id)
    .bind(booking_date)
    .bind(scheduled_at)
    .bind(venue)
    .bind(&addr)
    .bind(body.name.trim())
    .bind(body.phone.trim())
    .bind(&notes)
    .bind(amount)
    .execute(pool.get_ref())
    .await;

    match ins {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Booking request submitted. You will be contacted after admin confirmation.",
            "reference_id": reference_id
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to create booking: {}", e)
        })),
    }
}

#[post("/api/pooja/booking/checkout")]
pub async fn pooja_booking_checkout(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    body: web::Json<PoojaCheckoutRequest>,
) -> HttpResponse {
    let reference_id = body.reference_id.trim();
    if reference_id.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "reference_id required"
        }));
    }

    let row: Option<(i32, String, String, Option<String>, i32, Option<String>)> =
        match sqlx::query_as(
            "SELECT id, booking_status, payment_status, payment_expected, amount_paise, gateway_order_id
             FROM pooja_bookings WHERE reference_id = $1 LIMIT 1",
        )
        .bind(reference_id)
        .fetch_optional(pool.get_ref())
        .await
        {
            Ok(r) => r,
            Err(e) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        };

    let Some((bid, bstatus, pay_status, pay_exp, amount_paise, existing_order)) = row else {
        return HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        }));
    };

    if bstatus != "confirmed" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Booking must be confirmed by admin before online payment"
        }));
    }
    if pay_exp.as_deref() != Some("online") {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "This booking is not set for online payment"
        }));
    }
    if pay_status != "pending" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Payment not pending for this booking"
        }));
    }

    let amount_paise = amount_paise as i64;
    if amount_paise < 10_000 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Amount too small for online checkout (minimum ₹100)"
        }));
    }

    if existing_order.as_ref().map(|s| !s.is_empty()).unwrap_or(false) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Payment order already created; complete or cancel in app"
        }));
    }

    let Some(cfg) = rz.as_ref().as_ref() else {
        let reason = truncate_payment_reason(
            "Online payments are not configured on server (set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET).",
        );
        let _ = sqlx::query(
            "UPDATE pooja_bookings SET payment_status = 'failed', payment_failure_reason = $1,
             payment_updated_at = NOW() WHERE id = $2 AND payment_status = 'pending'",
        )
        .bind(&reason)
        .bind(bid)
        .execute(pool.get_ref())
        .await;
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Online payments are not configured.",
            "reference_id": reference_id
        }));
    };

    let receipt: String = reference_id.chars().take(40).collect();
    let notes = json!({
        "dm_kind": "pooja",
        "reference_id": reference_id,
    });

    let order = match razorpay::create_order(cfg, amount_paise, &receipt, notes).await {
        Ok(o) => o,
        Err(e) => {
            let reason = truncate_payment_reason(&format!("Razorpay create order failed: {}", e));
            let _ = sqlx::query(
                "UPDATE pooja_bookings SET payment_status = 'failed', payment_failure_reason = $1,
                 payment_updated_at = NOW() WHERE id = $2 AND payment_status = 'pending'",
            )
            .bind(&reason)
            .bind(bid)
            .execute(pool.get_ref())
            .await;
            return HttpResponse::BadGateway().json(serde_json::json!({
                "success": false,
                "error": format!("Could not start payment: {}", e)
            }));
        }
    };

    let upd = sqlx::query(
        "UPDATE pooja_bookings SET gateway = 'razorpay', gateway_order_id = $1,
         payment_failure_reason = NULL, payment_updated_at = NOW()
         WHERE id = $2 AND payment_status = 'pending'",
    )
    .bind(&order.id)
    .bind(bid)
    .execute(pool.get_ref())
    .await;

    if let Err(e) = upd {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save order: {}", e)
        }));
    }

    HttpResponse::Ok().json(DonationCheckoutResponse {
        success: true,
        key_id: cfg.key_id.clone(),
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        reference_id: reference_id.to_string(),
    })
}

#[get("/api/pooja/bookings")]
pub async fn pooja_list_bookings(pool: web::Data<PgPool>, q: web::Query<PhoneQuery>) -> HttpResponse {
    match sqlx::query_as::<_, PoojaBookingView>(
        "SELECT
            b.id,
            b.reference_id,
            b.booking_status,
            b.payment_expected,
            b.payment_status,
            b.created_at,
            b.booking_date,
            b.scheduled_at,
            b.officiant,
            b.slot_id,
            s.label AS slot_label,
            b.venue,
            b.address,
            b.name,
            b.phone,
            b.notes,
            b.offering_id,
            o.name AS offering_name,
            b.package_id,
            p.name AS package_name,
            b.amount_paise,
            b.gateway,
            b.gateway_order_id,
            b.gateway_payment_id,
            b.payment_failure_reason,
            b.payment_updated_at
         FROM pooja_bookings b
         JOIN pooja_offerings o ON o.id = b.offering_id
         JOIN pooja_slot_definitions s ON s.id = b.slot_id
         LEFT JOIN pooja_offering_packages p ON p.id = b.package_id
         WHERE b.phone = $1
         ORDER BY b.created_at DESC
         LIMIT 100",
    )
    .bind(q.phone.trim())
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/pooja/booking/{reference_id}/reschedule")]
pub async fn pooja_reschedule_booking(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
    body: web::Json<PoojaRescheduleRequest>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();

    let existing: Option<(i32, chrono::DateTime<Utc>, String, NaiveDate, i32, String)> =
        match sqlx::query_as(
            "SELECT id, scheduled_at, booking_status, booking_date, slot_id, officiant
             FROM pooja_bookings WHERE reference_id = $1 LIMIT 1",
        )
        .bind(&reference_id)
        .fetch_optional(pool.get_ref())
        .await
        {
            Ok(r) => r,
            Err(e) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        };

    let Some((id, scheduled_at, bstatus, _old_date, _old_slot, officiant)) = existing else {
        return HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        }));
    };

    if bstatus == "cancelled" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Booking is cancelled"
        }));
    }

    if !member_may_change_event_time(scheduled_at) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": format!(
                "Changes are only allowed at least {} hours before the scheduled time",
                RESCHEDULE_CUTOFF_HOURS
            )
        }));
    }

    let new_date = match NaiveDate::parse_from_str(body.booking_date.trim(), "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "booking_date must be YYYY-MM-DD"
            }))
        }
    };

    let new_scheduled = match compute_scheduled_at_utc(pool.get_ref(), body.booking_date.trim(), body.slot_id).await {
        Ok(t) => t,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };

    match slot_has_capacity(pool.get_ref(), new_date, body.slot_id, &officiant, Some(id)).await {
        Ok(true) => {}
        Ok(false) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "New slot is fully booked"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    }

    let r = sqlx::query(
        "UPDATE pooja_bookings SET booking_date = $1, slot_id = $2, scheduled_at = $3, updated_at = NOW()
         WHERE reference_id = $4",
    )
    .bind(new_date)
    .bind(body.slot_id)
    .bind(new_scheduled)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(_) => {
            let _ = sqlx::query(
                "INSERT INTO pooja_booking_events (booking_id, event_type, payload)
                 VALUES ($1, 'member_reschedule', NULL)",
            )
            .bind(id)
            .execute(pool.get_ref())
            .await;
            HttpResponse::Ok().json(SimpleActionResponse {
                success: true,
                message: "Booking rescheduled".to_string(),
            })
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed: {}", e)
        })),
    }
}

#[post("/api/pooja/booking/{reference_id}/cancel")]
pub async fn pooja_cancel_booking(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();

    let existing: Option<(chrono::DateTime<Utc>, String)> = match sqlx::query_as(
        "SELECT scheduled_at, booking_status FROM pooja_bookings WHERE reference_id = $1 LIMIT 1",
    )
    .bind(&reference_id)
    .fetch_optional(pool.get_ref())
    .await
    {
        Ok(r) => r,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let Some((scheduled_at, bstatus)) = existing else {
        return HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        }));
    };

    if bstatus == "cancelled" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Already cancelled"
        }));
    }

    if !member_may_change_event_time(scheduled_at) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": format!(
                "Cancellation only allowed at least {} hours before the scheduled time",
                RESCHEDULE_CUTOFF_HOURS
            )
        }));
    }

    let result = sqlx::query(
        "UPDATE pooja_bookings SET booking_status = 'cancelled', updated_at = NOW()
         WHERE reference_id = $1 AND booking_status <> 'cancelled'",
    )
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Booking cancelled".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed: {}", e)
        })),
    }
}
