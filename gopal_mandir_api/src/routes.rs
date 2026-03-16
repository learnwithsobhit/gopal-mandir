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
