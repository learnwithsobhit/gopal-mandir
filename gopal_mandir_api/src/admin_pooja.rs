//! Admin: pooja offerings, packages, capacity, bookings.

use actix_web::{get, patch, post, web, HttpRequest, HttpResponse};
use chrono::NaiveDate;
use sqlx::PgPool;

use crate::admin::require_admin;
use crate::models::*;
use crate::pooja_logic::{booking_amount_paise, compute_scheduled_at_utc, slot_has_capacity};

#[get("/api/admin/pooja/meta")]
pub async fn admin_pooja_meta(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let slots: Result<Vec<PoojaSlotDefinition>, _> = sqlx::query_as(
        "SELECT id, label, start_time, end_time, sort_order FROM pooja_slot_definitions ORDER BY sort_order, id",
    )
    .fetch_all(pool.get_ref())
    .await;

    let guru: Option<i32> = sqlx::query_scalar(
        "SELECT max_per_slot_per_day FROM pooja_capacity_rules WHERE officiant = 'guru'",
    )
    .fetch_optional(pool.get_ref())
    .await
    .unwrap_or(None);
    let baba: Option<i32> = sqlx::query_scalar(
        "SELECT max_per_slot_per_day FROM pooja_capacity_rules WHERE officiant = 'baba'",
    )
    .fetch_optional(pool.get_ref())
    .await
    .unwrap_or(None);

    match slots {
        Ok(s) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": {
                "slots": s,
                "guru_max_per_slot": guru.unwrap_or(1),
                "baba_max_per_slot": baba.unwrap_or(1),
            }
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/pooja/capacity")]
pub async fn admin_pooja_patch_capacity(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPatchPoojaCapacityRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    if let Some(g) = body.guru_max_per_slot {
        if g < 1 {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "guru_max_per_slot must be >= 1"
            }));
        }
        if let Err(e) = sqlx::query(
            "UPDATE pooja_capacity_rules SET max_per_slot_per_day = $1, updated_at = NOW() WHERE officiant = 'guru'",
        )
        .bind(g)
        .execute(pool.get_ref())
        .await
        {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("{}", e)
            }));
        }
    }

    if let Some(b) = body.baba_max_per_slot {
        if b < 1 {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "baba_max_per_slot must be >= 1"
            }));
        }
        if let Err(e) = sqlx::query(
            "UPDATE pooja_capacity_rules SET max_per_slot_per_day = $1, updated_at = NOW() WHERE officiant = 'baba'",
        )
        .bind(b)
        .execute(pool.get_ref())
        .await
        {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("{}", e)
            }));
        }
    }

    HttpResponse::Ok().json(SimpleActionResponse {
        success: true,
        message: "Capacity updated".to_string(),
    })
}

#[get("/api/admin/pooja/offerings")]
pub async fn admin_pooja_list_offerings(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let rows: Result<Vec<PoojaOfferingAdminRow>, _> = sqlx::query_as(
        "SELECT id, name, description, base_price_paise, slots_consumed, active, sort_order, created_at
         FROM pooja_offerings ORDER BY sort_order, id",
    )
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(offerings) => {
            let mut out: Vec<AdminPoojaOfferingOut> = Vec::new();
            for o in offerings {
                let oid = o.id;
                let packages: Vec<PoojaPackageAdminRow> = match sqlx::query_as(
                    "SELECT id, offering_id, name, description, additional_price_paise, active, sort_order
                     FROM pooja_offering_packages WHERE offering_id = $1 ORDER BY sort_order, id",
                )
                .bind(oid)
                .fetch_all(pool.get_ref())
                .await
                {
                    Ok(p) => p,
                    Err(e) => {
                        return HttpResponse::InternalServerError().json(serde_json::json!({
                            "success": false,
                            "error": format!("{}", e)
                        }))
                    }
                };
                out.push(AdminPoojaOfferingOut { offering: o, packages });
            }
            HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": out }))
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[post("/api/admin/pooja/offerings")]
pub async fn admin_pooja_create_offering(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreatePoojaOfferingRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let name = body.name.trim();
    if name.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name required"
        }));
    }
    if body.base_price_paise < 0 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "invalid base_price_paise"
        }));
    }

    let desc = body.description.as_deref().unwrap_or("").trim().to_string();
    let slots = body.slots_consumed.unwrap_or(1).max(1);
    let active = body.active.unwrap_or(true);
    let sort = body.sort_order.unwrap_or(0);

    let r = sqlx::query_scalar::<_, i32>(
        "INSERT INTO pooja_offerings (name, description, base_price_paise, slots_consumed, active, sort_order)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING id",
    )
    .bind(name)
    .bind(&desc)
    .bind(body.base_price_paise)
    .bind(slots)
    .bind(active)
    .bind(sort)
    .fetch_one(pool.get_ref())
    .await;

    match r {
        Ok(id) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "id": id
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[patch("/api/admin/pooja/offerings/{id}")]
pub async fn admin_pooja_patch_offering(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchPoojaOfferingRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let r = sqlx::query(
        "UPDATE pooja_offerings SET
            name = COALESCE($1, name),
            description = COALESCE($2, description),
            base_price_paise = COALESCE($3, base_price_paise),
            slots_consumed = COALESCE($4, slots_consumed),
            active = COALESCE($5, active),
            sort_order = COALESCE($6, sort_order)
         WHERE id = $7",
    )
    .bind(body.name.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty()))
    .bind(body.description.as_ref().map(|s| s.trim().to_string()))
    .bind(body.base_price_paise)
    .bind(body.slots_consumed)
    .bind(body.active)
    .bind(body.sort_order)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(x) if x.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Offering updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[post("/api/admin/pooja/offerings/{offering_id}/packages")]
pub async fn admin_pooja_create_package(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    offering_id: web::Path<i32>,
    body: web::Json<AdminCreatePoojaPackageRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let offering_id = offering_id.into_inner();
    let name = body.name.trim();
    if name.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name required"
        }));
    }
    let desc = body.description.as_deref().unwrap_or("").trim().to_string();
    let add = body.additional_price_paise.unwrap_or(0).max(0);
    let active = body.active.unwrap_or(true);
    let sort = body.sort_order.unwrap_or(0);

    let r = sqlx::query_scalar::<_, i32>(
        "INSERT INTO pooja_offering_packages (offering_id, name, description, additional_price_paise, active, sort_order)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING id",
    )
    .bind(offering_id)
    .bind(name)
    .bind(&desc)
    .bind(add)
    .bind(active)
    .bind(sort)
    .fetch_one(pool.get_ref())
    .await;

    match r {
        Ok(id) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "id": id })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[patch("/api/admin/pooja/packages/{id}")]
pub async fn admin_pooja_patch_package(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchPoojaPackageRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let r = sqlx::query(
        "UPDATE pooja_offering_packages SET
            name = COALESCE($1, name),
            description = COALESCE($2, description),
            additional_price_paise = COALESCE($3, additional_price_paise),
            active = COALESCE($4, active),
            sort_order = COALESCE($5, sort_order)
         WHERE id = $6",
    )
    .bind(body.name.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty()))
    .bind(body.description.as_ref().map(|s| s.trim().to_string()))
    .bind(body.additional_price_paise)
    .bind(body.active)
    .bind(body.sort_order)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(x) if x.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Package updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[get("/api/admin/pooja/bookings")]
pub async fn admin_pooja_list_bookings(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminPoojaBookingsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let st = q.booking_status.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());
    let off = q.officiant.as_ref().map(|s| s.trim().to_lowercase()).filter(|s| s == "guru" || s == "baba");
    let from_d = q
        .from_date
        .as_ref()
        .and_then(|s| NaiveDate::parse_from_str(s.trim(), "%Y-%m-%d").ok());
    let to_d = q
        .to_date
        .as_ref()
        .and_then(|s| NaiveDate::parse_from_str(s.trim(), "%Y-%m-%d").ok());

    let rows = sqlx::query_as::<_, AdminPoojaBookingView>(
        "SELECT
            b.id,
            b.reference_id,
            b.booking_status,
            b.payment_expected,
            b.payment_status,
            b.created_at,
            b.updated_at,
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
            b.payment_updated_at,
            b.payment_admin_note
         FROM pooja_bookings b
         JOIN pooja_offerings o ON o.id = b.offering_id
         JOIN pooja_slot_definitions s ON s.id = b.slot_id
         LEFT JOIN pooja_offering_packages p ON p.id = b.package_id
         WHERE ($1::TEXT IS NULL OR b.booking_status = $1)
           AND ($2::TEXT IS NULL OR b.officiant = $2)
           AND ($3::DATE IS NULL OR b.booking_date >= $3)
           AND ($4::DATE IS NULL OR b.booking_date <= $4)
         ORDER BY b.created_at DESC
         LIMIT $5 OFFSET $6",
    )
    .bind(&st)
    .bind(&off)
    .bind(from_d)
    .bind(to_d)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}

#[patch("/api/admin/pooja/booking/{reference_id}")]
pub async fn admin_pooja_patch_booking(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminPatchPoojaBookingRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let reference_id = reference_id.into_inner();

    let cur: Option<(
        i32,
        String,
        String,
        Option<String>,
        i32,
        Option<i32>,
        Option<i32>,
        NaiveDate,
        i32,
        String,
    )> = sqlx::query_as(
        "SELECT b.id, b.booking_status, b.payment_status, b.payment_expected, b.offering_id, b.package_id,
                b.amount_paise, b.booking_date, b.slot_id, b.officiant
         FROM pooja_bookings b WHERE b.reference_id = $1 LIMIT 1",
    )
    .bind(&reference_id)
    .fetch_optional(pool.get_ref())
    .await
    .unwrap_or(None);

    let Some((bid, bstatus, _pay_status, _pay_exp, offering_id, package_id, amount_paise, _old_date, _old_slot, officiant)) =
        cur
    else {
        return HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        }));
    };

    // Admin reschedule override
    if let (Some(ref dstr), Some(new_slot)) = (&body.reschedule_booking_date, body.reschedule_slot_id) {
        let new_date = match NaiveDate::parse_from_str(dstr.trim(), "%Y-%m-%d") {
            Ok(d) => d,
            Err(_) => {
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "success": false,
                    "error": "reschedule_booking_date must be YYYY-MM-DD"
                }))
            }
        };
        match slot_has_capacity(pool.get_ref(), new_date, new_slot, &officiant, Some(bid)).await {
            Ok(true) => {}
            Ok(false) => {
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "success": false,
                    "error": "Target slot is full"
                }))
            }
            Err(e) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("{}", e)
                }))
            }
        }
        let new_scheduled = match compute_scheduled_at_utc(pool.get_ref(), dstr.trim(), new_slot).await {
            Ok(t) => t,
            Err(msg) => {
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "success": false,
                    "error": msg
                }))
            }
        };
        let _ = sqlx::query(
            "UPDATE pooja_bookings SET booking_date = $1, slot_id = $2, scheduled_at = $3, updated_at = NOW()
             WHERE reference_id = $4",
        )
        .bind(new_date)
        .bind(new_slot)
        .bind(new_scheduled)
        .bind(&reference_id)
        .execute(pool.get_ref())
        .await;
        let _ = sqlx::query(
            "INSERT INTO pooja_booking_events (booking_id, event_type, payload)
             VALUES ($1, 'admin_reschedule', NULL)",
        )
        .bind(bid)
        .execute(pool.get_ref())
        .await;
    }

    let new_bstatus = body.booking_status.as_ref().map(|s| s.trim().to_lowercase()).filter(|s| !s.is_empty());
    let new_pay_exp = body
        .payment_expected
        .as_ref()
        .map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty());

    if let Some(ref ns) = new_bstatus {
        let allowed = ["pending_confirmation", "confirmed", "completed", "cancelled"];
        if !allowed.contains(&ns.as_str()) {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid booking_status"
            }));
        }

        if ns == "confirmed" && bstatus == "pending_confirmation" {
            let pe = match new_pay_exp.as_deref() {
                Some("online") | Some("offline") => new_pay_exp.clone().unwrap(),
                _ => {
                    return HttpResponse::BadRequest().json(serde_json::json!({
                        "success": false,
                        "error": "payment_expected (online or offline) required when confirming"
                    }))
                }
            };
            let amt = amount_paise.unwrap_or(0);
            let final_amt = if amt > 0 {
                amt
            } else {
                match booking_amount_paise(pool.get_ref(), offering_id, package_id).await {
                    Ok(a) => a,
                    Err(msg) => {
                        return HttpResponse::BadRequest().json(serde_json::json!({
                            "success": false,
                            "error": msg
                        }))
                    }
                }
            };
            if let Err(e) = sqlx::query(
                "UPDATE pooja_bookings SET booking_status = 'confirmed', payment_expected = $1,
                 payment_status = 'pending', amount_paise = COALESCE(amount_paise, $2), updated_at = NOW()
                 WHERE reference_id = $3",
            )
            .bind(&pe)
            .bind(final_amt)
            .bind(&reference_id)
            .execute(pool.get_ref())
            .await
            {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("{}", e)
                }));
            }
        } else {
            if let Err(e) = sqlx::query(
                "UPDATE pooja_bookings SET booking_status = $1, updated_at = NOW() WHERE reference_id = $2",
            )
            .bind(ns)
            .bind(&reference_id)
            .execute(pool.get_ref())
            .await
            {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("{}", e)
                }));
            }
        }
    } else if let Some(ref pe) = new_pay_exp {
        if pe != "online" && pe != "offline" {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "payment_expected must be online or offline"
            }));
        }
        if bstatus == "confirmed" {
            let _ = sqlx::query(
                "UPDATE pooja_bookings SET payment_expected = $1, updated_at = NOW() WHERE reference_id = $2",
            )
            .bind(pe)
            .bind(&reference_id)
            .execute(pool.get_ref())
            .await;
        }
    }

    HttpResponse::Ok().json(SimpleActionResponse {
        success: true,
        message: "Booking updated".to_string(),
    })
}

#[patch("/api/admin/pooja/bookings/payment/{reference_id}")]
pub async fn admin_pooja_patch_booking_payment(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminPatchPaymentRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let new_status = match crate::admin::admin_parse_patch_payment_status(&body) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let admin_note = match crate::admin::required_admin_payment_note(&body.admin_note) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let gateway_id = crate::admin::optional_payment_trim(&body.gateway_payment_id, 64);
    let reference_id = reference_id.into_inner();

    let r = sqlx::query(
        "UPDATE pooja_bookings SET
            payment_status = $1,
            payment_updated_at = NOW(),
            paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END,
            payment_failure_reason = CASE WHEN $1 IN ('paid','refunded') THEN NULL ELSE payment_failure_reason END,
            gateway_payment_id = CASE WHEN $2 IS NOT NULL THEN $2 ELSE gateway_payment_id END,
            payment_admin_note = $3
         WHERE reference_id = $4
           AND (
             (payment_status IN ('failed','pending') AND $1 IN ('paid','refunded'))
             OR (payment_status = 'paid' AND $1 = 'refunded')
           )",
    )
    .bind(&new_status)
    .bind(&gateway_id)
    .bind(&admin_note)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Payment updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Pooja booking not found or payment status cannot be changed"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("{}", e)
        })),
    }
}
