use actix_web::{get, post, web, HttpResponse};
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
    println!("Events: {:?}", pool);
    match sqlx::query_as::<_, Event>("SELECT * FROM events ORDER BY id")
        .fetch_all(pool.get_ref())
        .await
    {
        Ok(data) => {
            println!("Events: {:?}", data);
            HttpResponse::Ok().json(ApiResponse { success: true, data })
        }
        Err(e) => {
            println!("Error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        }))}
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
