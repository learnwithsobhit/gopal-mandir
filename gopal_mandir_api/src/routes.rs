use actix_web::{get, post, patch, web, HttpResponse};
use sqlx::PgPool;
use crate::models::*;

#[get("/api/aarti")]
pub async fn get_aarti(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, AartiSchedule>("SELECT * FROM aarti_schedule ORDER BY id")
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

#[get("/api/events")]
pub async fn get_events(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, Event>("SELECT * FROM events ORDER BY id")
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

#[post("/api/events/{event_id}/join")]
pub async fn join_event(
    pool: web::Data<PgPool>,
    event_id: web::Path<i32>,
    body: web::Json<EventParticipationRequest>,
) -> HttpResponse {
    let event_id = event_id.into_inner();

    // Ensure event exists
    let exists = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM events WHERE id = $1",
    )
    .bind(event_id)
    .fetch_one(pool.get_ref())
    .await;

    match exists {
        Ok(0) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Event not found"
            }))
        }
        Ok(_) => {}
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    }

    let result = sqlx::query(
        "INSERT INTO event_participations (event_id, name, phone, notes)
         VALUES ($1, $2, $3, $4)",
    )
    .bind(event_id)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.notes)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(EventParticipationResponse {
            success: true,
            message: "Your participation has been recorded. Jai Gopal!".to_string(),
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save participation: {}", e)
        })),
    }
}

#[get("/api/gallery")]
pub async fn get_gallery(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, GalleryItem>("SELECT * FROM gallery ORDER BY id")
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

#[post("/api/events/{event_id}/like")]
pub async fn like_event(
    pool: web::Data<PgPool>,
    event_id: web::Path<i32>,
    body: web::Json<Option<EventParticipationRequest>>,
) -> HttpResponse {
    let event_id = event_id.into_inner();

    let result = sqlx::query(
        "INSERT INTO event_likes (event_id, name) VALUES ($1, $2)",
    )
    .bind(event_id)
    .bind(body.as_ref().as_ref().map(|b| b.name.clone()))
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to like event: {}", e)
        })),
    }
}

#[get("/api/events/{event_id}/likes/count")]
pub async fn get_event_likes_count(
    pool: web::Data<PgPool>,
    event_id: web::Path<i32>,
) -> HttpResponse {
    let event_id = event_id.into_inner();
    let row = sqlx::query_as::<_, LikeCount>(
        "SELECT COUNT(*) as count FROM event_likes WHERE event_id = $1",
    )
    .bind(event_id)
    .fetch_one(pool.get_ref())
    .await;

    match row {
        Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/events/{event_id}/comments")]
pub async fn get_event_comments(
    pool: web::Data<PgPool>,
    event_id: web::Path<i32>,
) -> HttpResponse {
    let event_id = event_id.into_inner();
    let rows = sqlx::query_as::<_, EventComment>(
        "SELECT * FROM event_comments WHERE event_id = $1 ORDER BY created_at DESC LIMIT 100",
    )
    .bind(event_id)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/events/{event_id}/comments")]
pub async fn add_event_comment(
    pool: web::Data<PgPool>,
    event_id: web::Path<i32>,
    body: web::Json<NewCommentRequest>,
) -> HttpResponse {
    let event_id = event_id.into_inner();

    let result = sqlx::query(
        "INSERT INTO event_comments (event_id, name, comment) VALUES ($1, $2, $3)",
    )
    .bind(event_id)
    .bind(&body.name)
    .bind(&body.comment)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to add comment: {}", e)
        })),
    }
}

#[post("/api/gallery/{gallery_id}/like")]
pub async fn like_gallery(
    pool: web::Data<PgPool>,
    gallery_id: web::Path<i32>,
    body: web::Json<Option<EventParticipationRequest>>,
) -> HttpResponse {
    let gallery_id = gallery_id.into_inner();

    let result = sqlx::query(
        "INSERT INTO gallery_likes (gallery_id, name) VALUES ($1, $2)",
    )
    .bind(gallery_id)
    .bind(body.as_ref().as_ref().map(|b| b.name.clone()))
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to like gallery item: {}", e)
        })),
    }
}

#[get("/api/gallery/{gallery_id}/likes/count")]
pub async fn get_gallery_likes_count(
    pool: web::Data<PgPool>,
    gallery_id: web::Path<i32>,
) -> HttpResponse {
    let gallery_id = gallery_id.into_inner();
    let row = sqlx::query_as::<_, LikeCount>(
        "SELECT COUNT(*) as count FROM gallery_likes WHERE gallery_id = $1",
    )
    .bind(gallery_id)
    .fetch_one(pool.get_ref())
    .await;

    match row {
        Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/gallery/{gallery_id}/comments")]
pub async fn get_gallery_comments(
    pool: web::Data<PgPool>,
    gallery_id: web::Path<i32>,
) -> HttpResponse {
    let gallery_id = gallery_id.into_inner();
    let rows = sqlx::query_as::<_, GalleryComment>(
        "SELECT * FROM gallery_comments WHERE gallery_id = $1 ORDER BY created_at DESC LIMIT 100",
    )
    .bind(gallery_id)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/gallery/{gallery_id}/comments")]
pub async fn add_gallery_comment(
    pool: web::Data<PgPool>,
    gallery_id: web::Path<i32>,
    body: web::Json<NewCommentRequest>,
) -> HttpResponse {
    let gallery_id = gallery_id.into_inner();

    let result = sqlx::query(
        "INSERT INTO gallery_comments (gallery_id, name, comment) VALUES ($1, $2, $3)",
    )
    .bind(gallery_id)
    .bind(&body.name)
    .bind(&body.comment)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to add comment: {}", e)
        })),
    }
}
#[get("/api/prasad")]
pub async fn get_prasad(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, PrasadItem>("SELECT * FROM prasad_items ORDER BY id")
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

#[get("/api/seva")]
pub async fn get_seva(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, SevaItem>("SELECT * FROM seva_items ORDER BY id")
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

#[get("/api/announcements")]
pub async fn get_announcements(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, Announcement>("SELECT * FROM announcements ORDER BY id DESC")
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

#[get("/api/daily-quote")]
pub async fn get_daily_quote(pool: web::Data<PgPool>) -> HttpResponse {
    // Pick a random quote (or rotate by day)
    match sqlx::query_as::<_, DailyQuote>(
        "SELECT * FROM daily_quotes ORDER BY RANDOM() LIMIT 1"
    )
        .fetch_optional(pool.get_ref())
        .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "No quotes found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/temple-info")]
pub async fn get_temple_info(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, TempleInfo>("SELECT * FROM temple_info LIMIT 1")
        .fetch_optional(pool.get_ref())
        .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Temple info not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/donation")]
pub async fn submit_donation(
    pool: web::Data<PgPool>,
    body: web::Json<DonationRequest>,
) -> HttpResponse {
    let reference_id = format!("GOPAL-{}", uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000"));

    // Save donation to database
    let result = sqlx::query(
        "INSERT INTO donations (name, amount, purpose, phone, email, reference_id) VALUES ($1, $2, $3, $4, $5, $6)"
    )
        .bind(&body.name)
        .bind(body.amount)
        .bind(&body.purpose)
        .bind(&body.phone)
        .bind(&body.email)
        .bind(&reference_id)
        .execute(pool.get_ref())
        .await;

    match result {
        Ok(_) => {
            let response = DonationResponse {
                success: true,
                message: format!(
                    "Dhanyavaad! Your donation of ₹{} for {} has been recorded. Jai Gopal!",
                    body.amount, body.purpose
                ),
                reference_id,
            };
            HttpResponse::Ok().json(response)
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save donation: {}", e)
        })),
    }
}

#[get("/api/live-darshan")]
pub async fn get_live_darshan(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, LiveDarshanInfo>("SELECT * FROM live_darshan ORDER BY id LIMIT 1")
        .fetch_optional(pool.get_ref())
        .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Live darshan config not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[derive(serde::Deserialize)]
pub struct PanchangQuery {
    pub date: Option<String>,
}

#[get("/api/panchang")]
pub async fn get_panchang(
    pool: web::Data<PgPool>,
    q: web::Query<PanchangQuery>,
) -> HttpResponse {
    // If date provided, use it; otherwise default to CURRENT_DATE
    let (sql, bind_date_opt) = if let Some(ref d) = q.date {
        (
            "SELECT
                id,
                to_char(for_date, 'YYYY-MM-DD') as for_date,
                content,
                created_at
             FROM hindu_panchang
             WHERE for_date = $1::date
             LIMIT 1",
            Some(d.clone()),
        )
    } else {
        (
            "SELECT
                id,
                to_char(for_date, 'YYYY-MM-DD') as for_date,
                content,
                created_at
             FROM hindu_panchang
             WHERE for_date = CURRENT_DATE
             LIMIT 1",
            None,
        )
    };

    let mut query = sqlx::query_as::<_, HinduPanchang>(sql);
    if let Some(d) = bind_date_opt {
        query = query.bind(d);
    }

    let row = query.fetch_optional(pool.get_ref()).await;

    match row {
        Ok(Some(data)) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Panchang for requested date not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/prasad/order")]
pub async fn create_prasad_order(
    pool: web::Data<PgPool>,
    body: web::Json<PrasadOrderRequest>,
) -> HttpResponse {
    let reference_id = format!(
        "PRASAD-{}",
        uuid::Uuid::new_v4()
            .to_string()
            .split('-')
            .next()
            .unwrap_or("0000")
    );

    // Lookup price so client can't tamper with totals
    let price_row = sqlx::query_scalar::<_, f64>(
        "SELECT price FROM prasad_items WHERE id = $1 AND available = TRUE",
    )
    .bind(body.prasad_item_id)
    .fetch_optional(pool.get_ref())
    .await;

    let price = match price_row {
        Ok(Some(price)) => price,
        Ok(None) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Prasad item not available"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    if body.quantity <= 0 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Quantity must be greater than 0"
        }));
    }

    let total_amount = price * (body.quantity as f64);

    let result = sqlx::query(
        "INSERT INTO prasad_orders (prasad_item_id, quantity, fulfillment, name, phone, address, notes, total_amount, reference_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)"
    )
    .bind(body.prasad_item_id)
    .bind(body.quantity)
    .bind(body.fulfillment.to_lowercase())
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.address)
    .bind(&body.notes)
    .bind(total_amount)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(PrasadOrderResponse {
            success: true,
            message: format!(
                "Booking created for {} item(s). Total ₹{}. Jai Gopal!",
                body.quantity,
                total_amount.round() as i64
            ),
            reference_id,
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to create prasad order: {}", e)
        })),
    }
}

#[post("/api/seva/booking")]
pub async fn create_seva_booking(
    pool: web::Data<PgPool>,
    body: web::Json<SevaBookingRequest>,
) -> HttpResponse {
    let reference_id = format!(
        "SEVA-{}",
        uuid::Uuid::new_v4()
            .to_string()
            .split('-')
            .next()
            .unwrap_or("0000")
    );

    // Validate item is available
    let exists = sqlx::query_scalar::<_, i32>(
        "SELECT id FROM seva_items WHERE id = $1 AND available = TRUE",
    )
    .bind(body.seva_item_id)
    .fetch_optional(pool.get_ref())
    .await;

    match exists {
        Ok(Some(_)) => {}
        Ok(None) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Seva item not available"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    }

    let result = sqlx::query(
        "INSERT INTO seva_bookings (seva_item_id, name, phone, preferred_date, notes, reference_id)
         VALUES ($1,$2,$3,$4,$5,$6)"
    )
    .bind(body.seva_item_id)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.preferred_date)
    .bind(&body.notes)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(SevaBookingResponse {
            success: true,
            message: "Seva booking request submitted. Jai Gopal!".to_string(),
            reference_id,
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to create seva booking: {}", e)
        })),
    }
}

#[derive(serde::Deserialize)]
pub struct PhoneQuery {
    pub phone: String,
}

#[get("/api/prasad/orders")]
pub async fn list_prasad_orders(
    pool: web::Data<PgPool>,
    q: web::Query<PhoneQuery>,
) -> HttpResponse {
    match sqlx::query_as::<_, PrasadOrderView>(
        "SELECT
            o.id,
            o.reference_id,
            o.status,
            o.created_at,
            o.fulfillment,
            o.quantity,
            o.total_amount,
            o.name,
            o.phone,
            o.address,
            o.notes,
            o.prasad_item_id,
            p.name as prasad_name
         FROM prasad_orders o
         JOIN prasad_items p ON p.id = o.prasad_item_id
         WHERE o.phone = $1
         ORDER BY o.created_at DESC
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

#[patch("/api/prasad/order/{reference_id}")]
pub async fn update_prasad_order(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
    body: web::Json<UpdatePrasadOrderRequest>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();

    // get existing (and ensure not cancelled)
    let existing = sqlx::query_as::<_, PrasadOrder>(
        "SELECT * FROM prasad_orders WHERE reference_id = $1 LIMIT 1",
    )
    .bind(&reference_id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(o)) => o,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Booking not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    if existing.status == "cancelled" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Booking already cancelled"
        }));
    }

    let new_qty = body.quantity.unwrap_or(existing.quantity);
    if new_qty <= 0 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Quantity must be greater than 0"
        }));
    }

    let new_fulfillment = body
        .fulfillment
        .clone()
        .unwrap_or(existing.fulfillment)
        .to_lowercase();

    if new_fulfillment != "pickup" && new_fulfillment != "delivery" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Fulfillment must be pickup or delivery"
        }));
    }

    let new_address = if new_fulfillment == "delivery" {
        body.address.clone().or(existing.address)
    } else {
        None
    };
    let new_notes = body.notes.clone().or(existing.notes);

    // price lookup for new total
    let price_row = sqlx::query_scalar::<_, f64>(
        "SELECT price FROM prasad_items WHERE id = $1",
    )
    .bind(existing.prasad_item_id)
    .fetch_optional(pool.get_ref())
    .await;

    let price = match price_row {
        Ok(Some(p)) => p,
        Ok(None) => 0.0,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let total_amount = price * (new_qty as f64);

    let result = sqlx::query(
        "UPDATE prasad_orders
         SET quantity = $1, fulfillment = $2, address = $3, notes = $4, total_amount = $5
         WHERE reference_id = $6",
    )
    .bind(new_qty)
    .bind(&new_fulfillment)
    .bind(&new_address)
    .bind(&new_notes)
    .bind(total_amount)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Booking updated".to_string(),
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to update booking: {}", e)
        })),
    }
}

#[post("/api/prasad/order/{reference_id}/cancel")]
pub async fn cancel_prasad_order(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();
    let result = sqlx::query(
        "UPDATE prasad_orders SET status = 'cancelled' WHERE reference_id = $1 AND status <> 'cancelled'",
    )
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                return HttpResponse::NotFound().json(serde_json::json!({
                    "success": false,
                    "error": "Booking not found or already cancelled"
                }));
            }
            HttpResponse::Ok().json(SimpleActionResponse {
                success: true,
                message: "Booking cancelled".to_string(),
            })
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to cancel booking: {}", e)
        })),
    }
}

#[get("/api/seva/bookings")]
pub async fn list_seva_bookings(
    pool: web::Data<PgPool>,
    q: web::Query<PhoneQuery>,
) -> HttpResponse {
    match sqlx::query_as::<_, SevaBookingView>(
        "SELECT
            b.id,
            b.reference_id,
            b.status,
            b.created_at,
            b.name,
            b.phone,
            b.preferred_date,
            b.notes,
            b.seva_item_id,
            s.name as seva_name,
            s.category as seva_category,
            s.price as seva_price
         FROM seva_bookings b
         JOIN seva_items s ON s.id = b.seva_item_id
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

#[patch("/api/seva/booking/{reference_id}")]
pub async fn update_seva_booking(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
    body: web::Json<UpdateSevaBookingRequest>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();

    let existing = sqlx::query_scalar::<_, String>(
        "SELECT status FROM seva_bookings WHERE reference_id = $1 LIMIT 1",
    )
    .bind(&reference_id)
    .fetch_optional(pool.get_ref())
    .await;

    let status = match existing {
        Ok(Some(s)) => s,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Booking not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    if status == "cancelled" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Booking already cancelled"
        }));
    }

    let result = sqlx::query(
        "UPDATE seva_bookings SET preferred_date = COALESCE($1, preferred_date), notes = COALESCE($2, notes)
         WHERE reference_id = $3",
    )
    .bind(&body.preferred_date)
    .bind(&body.notes)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Booking updated".to_string(),
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to update booking: {}", e)
        })),
    }
}

#[post("/api/seva/booking/{reference_id}/cancel")]
pub async fn cancel_seva_booking(
    pool: web::Data<PgPool>,
    reference_id: web::Path<String>,
) -> HttpResponse {
    let reference_id = reference_id.into_inner();
    let result = sqlx::query(
        "UPDATE seva_bookings SET status = 'cancelled' WHERE reference_id = $1 AND status <> 'cancelled'",
    )
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                return HttpResponse::NotFound().json(serde_json::json!({
                    "success": false,
                    "error": "Booking not found or already cancelled"
                }));
            }
            HttpResponse::Ok().json(SimpleActionResponse {
                success: true,
                message: "Booking cancelled".to_string(),
            })
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to cancel booking: {}", e)
        })),
    }
}
