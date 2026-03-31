use actix_web::{get, post, patch, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use crate::models::*;
use crate::razorpay::{self, RazorpayConfig};
use crate::util::{bearer_token, normalize_phone, sha256_hex, truncate_payment_reason};
use serde_json::{json, Value};
use chrono::{Datelike, Duration, Utc};
use rand::Rng;
use uuid::Uuid;
use std::env;

/// Allowed hosts for image proxy (avoids open proxy abuse). Add more if you use other CDNs.
const IMAGE_PROXY_ALLOWED_HOSTS: &[&str] = &[
    "images.cdn-files-a.com",
    "images.cdn-files.com",
];

// ──────────────────────────────────────────────
// Membership (free) + phone OTP + sessions
// ──────────────────────────────────────────────

#[post("/api/membership/request-otp")]
pub async fn membership_request_otp(
    pool: web::Data<PgPool>,
    body: web::Json<MembershipRequestOtpRequest>,
) -> HttpResponse {
    let phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"success": false, "error": "Invalid phone"})),
    };

    // Basic rate limit: max 3 OTP requests per 10 minutes per phone.
    let recent = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM member_otp WHERE phone = $1 AND created_at > NOW() - INTERVAL '10 minutes'",
    )
    .bind(&phone)
    .fetch_one(pool.get_ref())
    .await;
    if let Ok(count) = recent {
        if count >= 3 {
            return HttpResponse::TooManyRequests().json(serde_json::json!({
                "success": false,
                "error": "Too many OTP requests. Please try again later."
            }));
        }
    }

    let otp_num: u32 = rand::thread_rng().gen_range(0..=999_999);
    let otp = format!("{:06}", otp_num);
    let pepper = env::var("MEMBERSHIP_OTP_PEPPER").unwrap_or_else(|_| "dev".to_string());
    let otp_hash = sha256_hex(&format!("{}:{}:{}", phone, otp, pepper));
    let expires_at = Utc::now() + Duration::minutes(5);
    let id = Uuid::new_v4();

    let result = sqlx::query(
        "INSERT INTO member_otp (id, phone, otp_hash, expires_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(id)
    .bind(&phone)
    .bind(&otp_hash)
    .bind(expires_at)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(MembershipRequestOtpResponse {
            success: true,
            otp,
            expires_in_sec: 300,
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to create OTP: {}", e)
        })),
    }
}

#[post("/api/membership/verify-otp")]
pub async fn membership_verify_otp(
    pool: web::Data<PgPool>,
    body: web::Json<MembershipVerifyOtpRequest>,
) -> HttpResponse {
    let phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"success": false, "error": "Invalid phone"})),
    };
    let otp = body.otp.trim().to_string();
    if otp.len() != 6 || !otp.chars().all(|c| c.is_ascii_digit()) {
        return HttpResponse::BadRequest().json(serde_json::json!({"success": false, "error": "Invalid OTP"}));
    }

    let mut tx = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let row = sqlx::query_as::<_, (Uuid, String, chrono::DateTime<Utc>, i32, Option<chrono::DateTime<Utc>>)>(
        "SELECT id, otp_hash, expires_at, attempts, consumed_at
         FROM member_otp
         WHERE phone = $1
         ORDER BY created_at DESC
         LIMIT 1",
    )
    .bind(&phone)
    .fetch_optional(&mut *tx)
    .await;

    let (otp_id, otp_hash, expires_at, attempts, consumed_at) = match row {
        Ok(Some(r)) => r,
        Ok(None) => {
            let _ = tx.rollback().await;
            return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "OTP not found"}));
        }
        Err(e) => {
            let _ = tx.rollback().await;
            return HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Database error: {}", e)}));
        }
    };

    if consumed_at.is_some() {
        let _ = tx.rollback().await;
        return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "OTP already used"}));
    }
    if Utc::now() > expires_at {
        let _ = tx.rollback().await;
        return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "OTP expired"}));
    }
    if attempts >= 5 {
        let _ = tx.rollback().await;
        return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Too many attempts"}));
    }

    let pepper = env::var("MEMBERSHIP_OTP_PEPPER").unwrap_or_else(|_| "dev".to_string());
    let expected = sha256_hex(&format!("{}:{}:{}", phone, otp, pepper));

    if expected != otp_hash {
        let _ = sqlx::query("UPDATE member_otp SET attempts = attempts + 1 WHERE id = $1")
            .bind(otp_id)
            .execute(&mut *tx)
            .await;
        let _ = tx.commit().await;
        return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Invalid OTP"}));
    }

    // Consume OTP
    if let Err(e) = sqlx::query("UPDATE member_otp SET consumed_at = NOW() WHERE id = $1 AND consumed_at IS NULL")
        .bind(otp_id)
        .execute(&mut *tx)
        .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Failed to consume OTP: {}", e)}));
    }

    let name = body.name.clone().unwrap_or_default().trim().to_string();
    let email = body.email.clone().unwrap_or_default().trim().to_string();

    // Upsert member by phone. Only overwrite name/email if non-empty.
    let member_id = Uuid::new_v4();
    let member_row = sqlx::query_as::<_, Member>(
        "INSERT INTO members (id, phone, name, email, status)
         VALUES ($1, $2, $3, $4, 'active')
         ON CONFLICT (phone) DO UPDATE SET
           name = COALESCE(NULLIF(EXCLUDED.name, ''), members.name),
           email = COALESCE(NULLIF(EXCLUDED.email, ''), members.email),
           updated_at = NOW()
         RETURNING id, phone, name, email, status, created_at, updated_at",
    )
    .bind(member_id)
    .bind(&phone)
    .bind(&name)
    .bind(&email)
    .fetch_one(&mut *tx)
    .await;

    let member = match member_row {
        Ok(m) => m,
        Err(e) => {
            let _ = tx.rollback().await;
            return HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Failed to upsert member: {}", e)}));
        }
    };

    // Create session
    let raw_token = Uuid::new_v4().to_string();
    let token_hash = sha256_hex(&raw_token);
    let session_id = Uuid::new_v4();
    let expires_at = Utc::now() + Duration::days(30);

    if let Err(e) = sqlx::query(
        "INSERT INTO member_sessions (id, member_id, token_hash, expires_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(session_id)
    .bind(member.id)
    .bind(&token_hash)
    .bind(expires_at)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Failed to create session: {}", e)}));
    }

    if let Err(e) = tx.commit().await {
        return HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Database error: {}", e)}));
    }

    HttpResponse::Ok().json(MembershipVerifyOtpResponse {
        success: true,
        token: raw_token,
        member,
    })
}

#[get("/api/membership/me")]
pub async fn membership_me(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    let token = match bearer_token(&req) {
        Some(t) => t,
        None => return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Missing token"})),
    };
    let token_hash = sha256_hex(&token);

    let row = sqlx::query_as::<_, Member>(
        "SELECT m.id, m.phone, m.name, m.email, m.status, m.created_at, m.updated_at
         FROM member_sessions s
         JOIN members m ON m.id = s.member_id
         WHERE s.token_hash = $1 AND s.expires_at > NOW()
         LIMIT 1",
    )
    .bind(&token_hash)
    .fetch_optional(pool.get_ref())
    .await;

    match row {
        Ok(Some(member)) => HttpResponse::Ok().json(MembershipMeResponse { success: true, member }),
        Ok(None) => HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Invalid session"})),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({"success": false, "error": format!("Database error: {}", e)})),
    }
}

#[post("/api/membership/logout")]
pub async fn membership_logout(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    let token = match bearer_token(&req) {
        Some(t) => t,
        None => return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Missing token"})),
    };
    let token_hash = sha256_hex(&token);

    let _ = sqlx::query("DELETE FROM member_sessions WHERE token_hash = $1")
        .bind(&token_hash)
        .execute(pool.get_ref())
        .await;

    HttpResponse::Ok().json(MembershipLogoutResponse { success: true })
}

// ──────────────────────────────────────────────
// Volunteer requests (open to all)
// ──────────────────────────────────────────────

#[post("/api/volunteer")]
pub async fn submit_volunteer_request(
    pool: web::Data<PgPool>,
    body: web::Json<VolunteerRequest>,
) -> HttpResponse {
    let name = body.name.trim().to_string();
    if name.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Name is required"
        }));
    }
    let phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid phone"
            }))
        }
    };
    let email = body.email.clone().unwrap_or_default().trim().to_string();
    let area = body.area.clone().unwrap_or_default().trim().to_string();
    let availability = body.availability.clone().unwrap_or_default().trim().to_string();
    let message = body.message.clone().unwrap_or_default().trim().to_string();

    let result = sqlx::query(
        "INSERT INTO volunteer_requests (name, phone, email, area, availability, message)
         VALUES ($1, $2, NULLIF($3, ''), $4, $5, $6)",
    )
    .bind(&name)
    .bind(&phone)
    .bind(&email)
    .bind(&area)
    .bind(&availability)
    .bind(&message)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Thank you for volunteering! We will contact you soon.".to_string(),
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to submit volunteer request: {}", e)
        })),
    }
}

#[post("/api/feedback")]
pub async fn submit_feedback(
    pool: web::Data<PgPool>,
    body: web::Json<FeedbackRequest>,
) -> HttpResponse {
    let name = body
        .name
        .clone()
        .unwrap_or_default()
        .trim()
        .to_string();
    let email = body
        .email
        .clone()
        .unwrap_or_default()
        .trim()
        .to_string();
    let phone = body
        .phone
        .clone()
        .unwrap_or_default()
        .trim()
        .to_string();
    let message = body.message.trim().to_string();
    let source = body
        .source
        .clone()
        .unwrap_or_else(|| "app".to_string())
        .trim()
        .to_string();
    let rating = body.rating;

    if message.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "message is required"
        }));
    }
    if !(1..=5).contains(&rating) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "rating must be between 1 and 5"
        }));
    }

    let reference_id = format!(
        "FDBK-{}",
        uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000")
    );

    let result = sqlx::query(
        "INSERT INTO feedback_items (name, email, phone, rating, message, source, reference_id)
         VALUES ($1, NULLIF($2,''), NULLIF($3,''), $4, $5, $6, $7)",
    )
    .bind(if name.is_empty() { "Anonymous" } else { &name })
    .bind(&email)
    .bind(&phone)
    .bind(rating as i16)
    .bind(&message)
    .bind(if source.is_empty() { "app" } else { &source })
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(FeedbackResponse {
            success: true,
            message: "Thank you for your feedback. Jai Gopal!".to_string(),
            reference_id,
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save feedback: {}", e)
        })),
    }
}

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

#[derive(Debug, serde::Deserialize)]
pub struct GalleryQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

#[get("/api/gallery")]
pub async fn get_gallery(
    pool: web::Data<PgPool>,
    q: web::Query<GalleryQuery>,
) -> HttpResponse {
    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(20).min(50).max(1);
    let offset = (page - 1) * per_page;

    match sqlx::query_as::<_, GalleryItem>(
        "SELECT * FROM gallery ORDER BY id LIMIT $1 OFFSET $2",
    )
    .bind(per_page as i64)
    .bind(offset as i64)
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

#[derive(Debug, serde::Deserialize)]
pub struct ImageProxyQuery {
    pub url: String,
}

#[get("/api/gallery/proxy")]
pub async fn get_gallery_image_proxy(q: web::Query<ImageProxyQuery>) -> HttpResponse {
    let url = match url::Url::parse(&q.url) {
        Ok(u) => u,
        Err(_) => return HttpResponse::BadRequest().body("Invalid url parameter"),
    };
    if url.scheme() != "https" {
        return HttpResponse::BadRequest().body("Only https URLs are allowed");
    }
    let host = url.host_str().unwrap_or("");
    let allowed = IMAGE_PROXY_ALLOWED_HOSTS
        .iter()
        .any(|h| host == *h || host.ends_with(&format!(".{}", h)))
        || host.ends_with(".amazonaws.com")
        || host.ends_with(".cloudfront.net");
    if !allowed {
        return HttpResponse::Forbidden().body("URL host not allowed for proxy");
    }

    let client = match reqwest::Client::builder().build() {
        Ok(c) => c,
        Err(e) => return HttpResponse::InternalServerError().body(format!("Client error: {}", e)),
    };
    let resp = match client.get(url.as_str()).send().await {
        Ok(r) => r,
        Err(e) => return HttpResponse::BadGateway().body(format!("Upstream error: {}", e)),
    };
    if !resp.status().is_success() {
        return HttpResponse::BadGateway().body("Upstream returned non-success");
    }
    let content_type = resp
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("image/jpeg")
        .to_string();
    let bytes = match resp.bytes().await {
        Ok(b) => b,
        Err(e) => return HttpResponse::InternalServerError().body(format!("Body error: {}", e)),
    };
    HttpResponse::Ok()
        .insert_header(("content-type", content_type))
        .insert_header(("cache-control", "public, max-age=86400"))
        .body(bytes.to_vec())
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
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM event_likes WHERE event_id = $1",
            )
            .bind(event_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
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
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM event_comments WHERE event_id = $1",
            )
            .bind(event_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
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
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM gallery_likes WHERE gallery_id = $1",
            )
            .bind(gallery_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
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
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM gallery_comments WHERE gallery_id = $1",
            )
            .bind(gallery_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
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
    match sqlx::query_as::<_, DailyQuote>(
        "SELECT id, shlok, translation, source
         FROM daily_quotes
         ORDER BY id DESC
         LIMIT 1"
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

#[get("/api/site/landing-audio")]
pub async fn get_landing_audio(pool: web::Data<PgPool>) -> HttpResponse {
    let url: Option<String> = sqlx::query_scalar(
        "SELECT value FROM site_kv WHERE key = 'landing_audio_url'",
    )
    .fetch_optional(pool.get_ref())
    .await
    .unwrap_or(None);

    HttpResponse::Ok().json(serde_json::json!({
        "success": true,
        "url": url.unwrap_or_default()
    }))
}

#[post("/api/donation")]
pub async fn submit_donation(
    pool: web::Data<PgPool>,
    body: web::Json<DonationRequest>,
) -> HttpResponse {
    let reference_id = format!("GOPAL-{}", uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000"));
    let amount_paise = (body.amount * 100.0).round() as i32;

    // Legacy path: record as paid (honor-system / pre-gateway clients). Prefer /api/donation/checkout for online pay.
    let result = sqlx::query(
        "INSERT INTO donations (name, amount, purpose, phone, email, reference_id, payment_status, amount_paise, paid_at)
         VALUES ($1, $2, $3, $4, $5, $6, 'paid', $7, NOW())"
    )
        .bind(&body.name)
        .bind(body.amount)
        .bind(&body.purpose)
        .bind(&body.phone)
        .bind(&body.email)
        .bind(&reference_id)
        .bind(amount_paise)
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

#[post("/api/events/{id}/donate")]
pub async fn submit_event_donation(
    pool: web::Data<PgPool>,
    id: web::Path<i32>,
    body: web::Json<EventDonationRequest>,
) -> HttpResponse {
    let event_id = id.into_inner();

    let event_exists = sqlx::query_scalar::<_, i32>("SELECT id FROM events WHERE id = $1")
        .bind(event_id)
        .fetch_optional(pool.get_ref())
        .await;

    match event_exists {
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Event not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
        Ok(Some(_)) => {}
    }

    let name = body.name.trim();
    if name.is_empty() || body.amount <= 0.0 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name and a positive amount are required"
        }));
    }

    let reference_id = format!(
        "EVTDON-{}",
        uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000")
    );

    let amount_paise = (body.amount * 100.0).round() as i32;

    let result = sqlx::query(
        "INSERT INTO event_donations (event_id, name, amount, phone, email, message, reference_id, payment_status, amount_paise, paid_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'paid', $8, NOW())",
    )
    .bind(event_id)
    .bind(name)
    .bind(body.amount)
    .bind(&body.phone)
    .bind(&body.email)
    .bind(&body.message)
    .bind(&reference_id)
    .bind(amount_paise)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(EventDonationResponse {
            success: true,
            message: format!(
                "Dhanyavaad! Your donation of ₹{} has been recorded. Jai Gopal!",
                body.amount
            ),
            reference_id,
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save event donation: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Razorpay checkout (India) — general + event donations
// ──────────────────────────────────────────────

/// Minimum online donation / event donation: ₹100 (10_000 paise).
fn amount_to_paise(amount: f64) -> Option<i64> {
    if amount <= 0.0 {
        return None;
    }
    let p = (amount * 100.0).round() as i64;
    if p < 10_000 {
        return None;
    }
    if p > 50_000_000 {
        return None;
    } // ₹5,00,000 cap per order
    Some(p)
}

/// Line subtotal, 10% delivery fee (delivery only), and grand total (2 decimal places).
fn prasad_order_totals(price: f64, quantity: i32, fulfillment: &str) -> (f64, f64, f64) {
    let subtotal = price * quantity as f64;
    let delivery_fee = if fulfillment.trim().eq_ignore_ascii_case("delivery") {
        ((subtotal * 0.10) * 100.0).round() / 100.0
    } else {
        0.0
    };
    let total = ((subtotal + delivery_fee) * 100.0).round() / 100.0;
    (subtotal, delivery_fee, total)
}

fn json_nonempty_order_id(val: Option<&Value>) -> Option<String> {
    let v = val?;
    match v {
        Value::String(s) if !s.is_empty() => Some(s.clone()),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

/// Razorpay `payment.failed` sometimes omits `order_id` on the payment entity; `order.payment_failed` carries it on the order entity.
fn webhook_failure_order_id(v: &Value) -> Option<String> {
    if let Some(pay) = v.pointer("/payload/payment/entity") {
        if let Some(oid) = json_nonempty_order_id(pay.get("order_id")) {
            return Some(oid);
        }
    }
    v.pointer("/payload/order/entity/id")
        .and_then(|x| json_nonempty_order_id(Some(x)))
}

fn razorpay_payment_failure_reason(pay: &Value) -> String {
    let code = pay
        .get("error_code")
        .or_else(|| pay.get("code"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let desc = pay
        .get("error_description")
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let reason = pay
        .get("error_reason")
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let step = pay
        .get("error_step")
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let s = format!("{} {} {} {}", code, desc, reason, step);
    s.trim().chars().take(500).collect::<String>()
}

async fn mark_razorpay_order_paid(
    pool: &PgPool,
    order_id: &str,
    payment_id: &str,
) -> Result<bool, sqlx::Error> {
    let r = sqlx::query(
        "UPDATE donations SET payment_status = 'paid', gateway_payment_id = $1,
         paid_at = COALESCE(paid_at, NOW()), payment_updated_at = NOW(), payment_failure_reason = NULL
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(payment_id)
    .bind(order_id)
    .execute(pool)
    .await?;
    if r.rows_affected() > 0 {
        return Ok(true);
    }
    let r2 = sqlx::query(
        "UPDATE event_donations SET payment_status = 'paid', gateway_payment_id = $1,
         paid_at = COALESCE(paid_at, NOW()), payment_updated_at = NOW(), payment_failure_reason = NULL
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(payment_id)
    .bind(order_id)
    .execute(pool)
    .await?;
    if r2.rows_affected() > 0 {
        return Ok(true);
    }
    let r3 = sqlx::query(
        "UPDATE seva_bookings SET payment_status = 'paid', gateway_payment_id = $1,
         paid_at = COALESCE(paid_at, NOW()), payment_updated_at = NOW(), payment_failure_reason = NULL
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(payment_id)
    .bind(order_id)
    .execute(pool)
    .await?;
    if r3.rows_affected() > 0 {
        return Ok(true);
    }
    let r3p = sqlx::query(
        "UPDATE pooja_bookings SET payment_status = 'paid', gateway_payment_id = $1,
         paid_at = COALESCE(paid_at, NOW()), payment_updated_at = NOW(), payment_failure_reason = NULL
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(payment_id)
    .bind(order_id)
    .execute(pool)
    .await?;
    if r3p.rows_affected() > 0 {
        return Ok(true);
    }
    let r4 = sqlx::query(
        "UPDATE prasad_orders SET payment_status = 'paid', gateway_payment_id = $1,
         paid_at = COALESCE(paid_at, NOW()), payment_updated_at = NOW(), payment_failure_reason = NULL
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(payment_id)
    .bind(order_id)
    .execute(pool)
    .await?;
    Ok(r4.rows_affected() > 0)
}

async fn razorpay_order_already_recorded_paid(
    pool: &PgPool,
    order_id: &str,
    payment_id: &str,
) -> Result<bool, sqlx::Error> {
    let d: bool = sqlx::query_scalar(
        "SELECT EXISTS(
            SELECT 1 FROM donations
            WHERE gateway = 'razorpay' AND gateway_order_id = $1
              AND gateway_payment_id = $2 AND payment_status = 'paid'
        )",
    )
    .bind(order_id)
    .bind(payment_id)
    .fetch_one(pool)
    .await?;
    if d {
        return Ok(true);
    }
    let e: bool = sqlx::query_scalar(
        "SELECT EXISTS(
            SELECT 1 FROM event_donations
            WHERE gateway = 'razorpay' AND gateway_order_id = $1
              AND gateway_payment_id = $2 AND payment_status = 'paid'
        )",
    )
    .bind(order_id)
    .bind(payment_id)
    .fetch_one(pool)
    .await?;
    if e {
        return Ok(true);
    }
    let s: bool = sqlx::query_scalar(
        "SELECT EXISTS(
            SELECT 1 FROM seva_bookings
            WHERE gateway = 'razorpay' AND gateway_order_id = $1
              AND gateway_payment_id = $2 AND payment_status = 'paid'
        )",
    )
    .bind(order_id)
    .bind(payment_id)
    .fetch_one(pool)
    .await?;
    if s {
        return Ok(true);
    }
    let pj: bool = sqlx::query_scalar(
        "SELECT EXISTS(
            SELECT 1 FROM pooja_bookings
            WHERE gateway = 'razorpay' AND gateway_order_id = $1
              AND gateway_payment_id = $2 AND payment_status = 'paid'
        )",
    )
    .bind(order_id)
    .bind(payment_id)
    .fetch_one(pool)
    .await?;
    if pj {
        return Ok(true);
    }
    let p: bool = sqlx::query_scalar(
        "SELECT EXISTS(
            SELECT 1 FROM prasad_orders
            WHERE gateway = 'razorpay' AND gateway_order_id = $1
              AND gateway_payment_id = $2 AND payment_status = 'paid'
        )",
    )
    .bind(order_id)
    .bind(payment_id)
    .fetch_one(pool)
    .await?;
    Ok(p)
}

async fn mark_razorpay_order_failed(
    pool: &PgPool,
    order_id: &str,
    reason: &str,
) -> Result<(), sqlx::Error> {
    let reason: String = reason.chars().take(500).collect();
    sqlx::query(
        "UPDATE donations SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .execute(pool)
    .await?;
    sqlx::query(
        "UPDATE event_donations SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .execute(pool)
    .await?;
    sqlx::query(
        "UPDATE seva_bookings SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .execute(pool)
    .await?;
    sqlx::query(
        "UPDATE pooja_bookings SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .execute(pool)
    .await?;
    sqlx::query(
        "UPDATE prasad_orders SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .execute(pool)
    .await?;
    Ok(())
}

/// Mark pending rows failed when app reports gateway error; requires order_id + reference_id match (no Razorpay signature).
async fn mark_razorpay_client_reported_failed(
    pool: &PgPool,
    order_id: &str,
    reference_id: &str,
    reason: &str,
) -> Result<u64, sqlx::Error> {
    let reason: String = reason.chars().take(500).collect();
    let mut total: u64 = 0;
    let r = sqlx::query(
        "UPDATE donations SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND reference_id = $3
           AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .bind(reference_id)
    .execute(pool)
    .await?;
    total += r.rows_affected();
    let r2 = sqlx::query(
        "UPDATE event_donations SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND reference_id = $3
           AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .bind(reference_id)
    .execute(pool)
    .await?;
    total += r2.rows_affected();
    let r3 = sqlx::query(
        "UPDATE seva_bookings SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND reference_id = $3
           AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .bind(reference_id)
    .execute(pool)
    .await?;
    total += r3.rows_affected();
    let r3p = sqlx::query(
        "UPDATE pooja_bookings SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND reference_id = $3
           AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .bind(reference_id)
    .execute(pool)
    .await?;
    total += r3p.rows_affected();
    let r4 = sqlx::query(
        "UPDATE prasad_orders SET payment_status = 'failed', payment_failure_reason = $1,
         payment_updated_at = NOW()
         WHERE gateway = 'razorpay' AND gateway_order_id = $2 AND reference_id = $3
           AND payment_status = 'pending'",
    )
    .bind(&reason)
    .bind(order_id)
    .bind(reference_id)
    .execute(pool)
    .await?;
    total += r4.rows_affected();
    Ok(total)
}

#[post("/api/donation/checkout")]
pub async fn donation_checkout(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    body: web::Json<DonationRequest>,
) -> HttpResponse {
    let Some(amount_paise) = amount_to_paise(body.amount) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "amount must be at least ₹100"
        }));
    };

    let reference_id =
        format!("GOPAL-{}", uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000"));

    let Some(cfg) = rz.as_ref().as_ref() else {
        let reason = truncate_payment_reason(
            "Online payments are not configured on server (set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET). Donor can be contacted using details below.",
        );
        let ins = sqlx::query(
            "INSERT INTO donations (name, amount, purpose, phone, email, reference_id,
             payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, 'failed', NULL, NULL, $7, $8, NOW())",
        )
        .bind(&body.name)
        .bind(body.amount)
        .bind(&body.purpose)
        .bind(&body.phone)
        .bind(&body.email)
        .bind(&reference_id)
        .bind(amount_paise as i32)
        .bind(&reason)
        .execute(pool.get_ref())
        .await;
        if let Err(e) = ins {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Could not record donation: {}", e)
            }));
        }
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Online payments are not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
            "reference_id": reference_id,
            "recorded": true
        }));
    };

    let receipt: String = reference_id.chars().take(40).collect();
    let notes = json!({
        "dm_kind": "general",
    });

    let order = match razorpay::create_order(cfg, amount_paise, &receipt, notes).await {
        Ok(o) => o,
        Err(e) => {
            let reason = truncate_payment_reason(&format!("Razorpay create order failed: {}", e));
            let ins = sqlx::query(
                "INSERT INTO donations (name, amount, purpose, phone, email, reference_id,
                 payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
                 VALUES ($1, $2, $3, $4, $5, $6, 'failed', NULL, NULL, $7, $8, NOW())",
            )
            .bind(&body.name)
            .bind(body.amount)
            .bind(&body.purpose)
            .bind(&body.phone)
            .bind(&body.email)
            .bind(&reference_id)
            .bind(amount_paise as i32)
            .bind(&reason)
            .execute(pool.get_ref())
            .await;
            if ins.is_ok() {
                return HttpResponse::BadGateway().json(serde_json::json!({
                    "success": false,
                    "error": format!("Could not start payment: {}", e),
                    "reference_id": reference_id,
                    "recorded": true
                }));
            }
            return HttpResponse::BadGateway().json(serde_json::json!({
                "success": false,
                "error": format!("Could not start payment: {}", e)
            }));
        }
    };

    let insert = sqlx::query(
        "INSERT INTO donations (name, amount, purpose, phone, email, reference_id,
         payment_status, gateway, gateway_order_id, amount_paise)
         VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'razorpay', $7, $8)",
    )
    .bind(&body.name)
    .bind(body.amount)
    .bind(&body.purpose)
    .bind(&body.phone)
    .bind(&body.email)
    .bind(&reference_id)
    .bind(&order.id)
    .bind(amount_paise as i32)
    .execute(pool.get_ref())
    .await;

    if let Err(e) = insert {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save donation: {}", e)
        }));
    }

    HttpResponse::Ok().json(DonationCheckoutResponse {
        success: true,
        key_id: cfg.key_id.clone(),
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        reference_id,
    })
}

#[post("/api/events/{id}/donate/checkout")]
pub async fn event_donation_checkout(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    id: web::Path<i32>,
    body: web::Json<EventDonationRequest>,
) -> HttpResponse {
    let event_id = id.into_inner();

    let event_exists = sqlx::query_scalar::<_, i32>("SELECT id FROM events WHERE id = $1")
        .bind(event_id)
        .fetch_optional(pool.get_ref())
        .await;

    match event_exists {
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Event not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
        Ok(Some(_)) => {}
    }

    let name = body.name.trim();
    if name.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name is required"
        }));
    }

    let Some(amount_paise) = amount_to_paise(body.amount) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "amount must be at least ₹100"
        }));
    };

    let reference_id = format!(
        "EVTDON-{}",
        uuid::Uuid::new_v4().to_string().split('-').next().unwrap_or("0000")
    );

    let Some(cfg) = rz.as_ref().as_ref() else {
        let reason = truncate_payment_reason(
            "Online payments are not configured on server (set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET). Donor can be contacted using details below.",
        );
        let ins = sqlx::query(
            "INSERT INTO event_donations (event_id, name, amount, phone, email, message, reference_id,
             payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'failed', NULL, NULL, $8, $9, NOW())",
        )
        .bind(event_id)
        .bind(name)
        .bind(body.amount)
        .bind(&body.phone)
        .bind(&body.email)
        .bind(&body.message)
        .bind(&reference_id)
        .bind(amount_paise as i32)
        .bind(&reason)
        .execute(pool.get_ref())
        .await;
        if let Err(e) = ins {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Could not record event donation: {}", e)
            }));
        }
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Online payments are not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
            "reference_id": reference_id,
            "recorded": true
        }));
    };

    let receipt: String = reference_id.chars().take(40).collect();
    let notes = json!({
        "dm_kind": "event",
        "event_id": event_id.to_string(),
    });

    let order = match razorpay::create_order(cfg, amount_paise, &receipt, notes).await {
        Ok(o) => o,
        Err(e) => {
            let reason = truncate_payment_reason(&format!("Razorpay create order failed: {}", e));
            let ins = sqlx::query(
                "INSERT INTO event_donations (event_id, name, amount, phone, email, message, reference_id,
                 payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, 'failed', NULL, NULL, $8, $9, NOW())",
            )
            .bind(event_id)
            .bind(name)
            .bind(body.amount)
            .bind(&body.phone)
            .bind(&body.email)
            .bind(&body.message)
            .bind(&reference_id)
            .bind(amount_paise as i32)
            .bind(&reason)
            .execute(pool.get_ref())
            .await;
            if ins.is_ok() {
                return HttpResponse::BadGateway().json(serde_json::json!({
                    "success": false,
                    "error": format!("Could not start payment: {}", e),
                    "reference_id": reference_id,
                    "recorded": true
                }));
            }
            return HttpResponse::BadGateway().json(serde_json::json!({
                "success": false,
                "error": format!("Could not start payment: {}", e)
            }));
        }
    };

    let insert = sqlx::query(
        "INSERT INTO event_donations (event_id, name, amount, phone, email, message, reference_id,
         payment_status, gateway, gateway_order_id, amount_paise)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', 'razorpay', $8, $9)",
    )
    .bind(event_id)
    .bind(name)
    .bind(body.amount)
    .bind(&body.phone)
    .bind(&body.email)
    .bind(&body.message)
    .bind(&reference_id)
    .bind(&order.id)
    .bind(amount_paise as i32)
    .execute(pool.get_ref())
    .await;

    if let Err(e) = insert {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save event donation: {}", e)
        }));
    }

    HttpResponse::Ok().json(DonationCheckoutResponse {
        success: true,
        key_id: cfg.key_id.clone(),
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        reference_id,
    })
}

#[post("/api/payments/razorpay/verify")]
pub async fn razorpay_verify_payment(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    body: web::Json<RazorpayVerifyRequest>,
) -> HttpResponse {
    let Some(cfg) = rz.as_ref().as_ref() else {
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Payments not configured"
        }));
    };

    if !razorpay::verify_payment_signature(
        &body.order_id,
        &body.payment_id,
        &body.signature,
        &cfg.key_secret,
    ) {
        return HttpResponse::Unauthorized().json(serde_json::json!({
            "success": false,
            "error": "Invalid signature"
        }));
    }

    match mark_razorpay_order_paid(pool.get_ref(), &body.order_id, &body.payment_id).await {
        Ok(true) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Ok(false) => {
            match razorpay_order_already_recorded_paid(pool.get_ref(), &body.order_id, &body.payment_id).await {
                Ok(true) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "duplicate": true })),
                Ok(false) => HttpResponse::NotFound().json(serde_json::json!({
                    "success": false,
                    "error": "No pending payment for this order"
                })),
                Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": e.to_string()
                })),
            }
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": e.to_string()
        })),
    }
}

#[post("/api/payments/razorpay/client-failed")]
pub async fn razorpay_client_failed(
    pool: web::Data<PgPool>,
    body: web::Json<RazorpayClientFailedRequest>,
) -> HttpResponse {
    let order_id = body.order_id.trim();
    let reference_id = body.reference_id.trim();
    if order_id.is_empty() || reference_id.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "order_id and reference_id are required"
        }));
    }
    let reason = body
        .reason
        .as_deref()
        .unwrap_or("Payment failed in checkout")
        .trim();
    let reason = if reason.is_empty() {
        "Payment failed in checkout"
    } else {
        reason
    };
    match mark_razorpay_client_reported_failed(pool.get_ref(), order_id, reference_id, reason).await {
        Ok(0) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "No matching pending payment for this order and reference"
        })),
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": e.to_string()
        })),
    }
}

#[post("/api/payments/razorpay/webhook")]
pub async fn razorpay_webhook(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    req: HttpRequest,
    body: web::Bytes,
) -> HttpResponse {
    let Some(cfg) = rz.as_ref().as_ref() else {
        return HttpResponse::Ok().finish();
    };
    if cfg.webhook_secret.is_empty() {
        eprintln!("RAZORPAY_WEBHOOK_SECRET not set; ignoring Razorpay webhooks");
        return HttpResponse::Ok().finish();
    }

    let sig = match req.headers().get("X-Razorpay-Signature") {
        Some(h) => match h.to_str() {
            Ok(s) => s,
            Err(_) => return HttpResponse::BadRequest().finish(),
        },
        None => return HttpResponse::Unauthorized().finish(),
    };

    if !razorpay::verify_webhook_signature(&body, sig, &cfg.webhook_secret) {
        return HttpResponse::Unauthorized().finish();
    }

    let v: Value = match serde_json::from_slice(&body) {
        Ok(x) => x,
        Err(_) => return HttpResponse::BadRequest().finish(),
    };

    let event = v.get("event").and_then(|x| x.as_str()).unwrap_or("");

    match event {
        "payment.captured" => {
            let pay = v
                .pointer("/payload/payment/entity")
                .cloned()
                .unwrap_or(Value::Null);
            let order_id = pay.get("order_id").and_then(|x| x.as_str()).unwrap_or("");
            let payment_id = pay.get("id").and_then(|x| x.as_str()).unwrap_or("");
            if order_id.is_empty() || payment_id.is_empty() {
                return HttpResponse::Ok().finish();
            }
            let _ = mark_razorpay_order_paid(pool.get_ref(), order_id, payment_id).await;
            HttpResponse::Ok().finish()
        }
        "payment.failed" => {
            let pay = v
                .pointer("/payload/payment/entity")
                .cloned()
                .unwrap_or(Value::Null);
            let order_id = webhook_failure_order_id(&v).unwrap_or_default();
            if !order_id.is_empty() {
                let mut reason = razorpay_payment_failure_reason(&pay);
                if reason.is_empty() {
                    reason = "payment failed".to_string();
                }
                let _ = mark_razorpay_order_failed(pool.get_ref(), &order_id, &reason).await;
            } else {
                eprintln!(
                    "Razorpay webhook payment.failed: could not resolve order_id (set RAZORPAY_WEBHOOK_SECRET and enable order.payment_failed too)"
                );
            }
            HttpResponse::Ok().finish()
        }
        "order.payment_failed" => {
            let order_id = v
                .pointer("/payload/order/entity/id")
                .and_then(|x| json_nonempty_order_id(Some(x)))
                .unwrap_or_default();
            let pay = v
                .pointer("/payload/payment/entity")
                .cloned()
                .unwrap_or(Value::Null);
            let mut reason = razorpay_payment_failure_reason(&pay);
            if reason.is_empty() {
                reason = "order payment failed".to_string();
            }
            if !order_id.is_empty() {
                let _ = mark_razorpay_order_failed(pool.get_ref(), &order_id, &reason).await;
            } else {
                eprintln!("Razorpay webhook order.payment_failed: missing order id");
            }
            HttpResponse::Ok().finish()
        }
        _ => HttpResponse::Ok().finish(),
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

#[derive(serde::Deserialize)]
pub struct DailyUpasanaQuery {}

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

#[get("/api/daily-upasana")]
pub async fn get_daily_upasana(
    pool: web::Data<PgPool>,
    _q: web::Query<DailyUpasanaQuery>,
) -> HttpResponse {
    let query = sqlx::query_as::<_, DailyUpasanaItem>(
        "SELECT
            id,
            title,
            category,
            content,
            sort_order,
            is_published,
            created_at,
            updated_at
         FROM daily_upasana_items
         WHERE is_published = TRUE
         ORDER BY sort_order ASC, title ASC, id ASC",
    );

    match query.fetch_all(pool.get_ref()).await {
        Ok(data) if !data.is_empty() => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Daily upasana not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/festivals")]
pub async fn get_festivals(
    pool: web::Data<PgPool>,
    q: web::Query<FestivalListQuery>,
) -> HttpResponse {
    let year = q.year.unwrap_or_else(|| chrono::Utc::now().year());
    let month = q.month.unwrap_or_else(|| chrono::Utc::now().month());
    if !(1..=12).contains(&month) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "month must be between 1 and 12"
        }));
    }

    match sqlx::query_as::<_, FestivalEntry>(
        "SELECT
            id,
            to_char(for_date, 'YYYY-MM-DD') as for_date,
            title,
            description,
            icon_url,
            banner_url,
            sort_order,
            is_active,
            created_at,
            updated_at
         FROM festival_calendar
         WHERE EXTRACT(YEAR FROM for_date) = $1
           AND EXTRACT(MONTH FROM for_date) = $2
           AND is_active = TRUE
         ORDER BY for_date ASC, sort_order ASC, id ASC",
    )
    .bind(year)
    .bind(month as i32)
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

#[get("/api/festivals/months")]
pub async fn get_festival_months(pool: web::Data<PgPool>) -> HttpResponse {
    match sqlx::query_as::<_, FestivalMonthBucket>(
        "SELECT
            EXTRACT(YEAR FROM for_date)::INT as year,
            EXTRACT(MONTH FROM for_date)::INT as month,
            to_char(date_trunc('month', for_date), 'Mon YYYY') as month_label,
            COUNT(*)::BIGINT as item_count
         FROM festival_calendar
         WHERE is_active = TRUE
         GROUP BY date_trunc('month', for_date), EXTRACT(YEAR FROM for_date), EXTRACT(MONTH FROM for_date)
         ORDER BY date_trunc('month', for_date) DESC",
    )
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

#[get("/api/festivals/{id}")]
pub async fn get_festival_detail(pool: web::Data<PgPool>, id: web::Path<i32>) -> HttpResponse {
    match sqlx::query_as::<_, FestivalEntry>(
        "SELECT
            id,
            to_char(for_date, 'YYYY-MM-DD') as for_date,
            title,
            description,
            icon_url,
            banner_url,
            sort_order,
            is_active,
            created_at,
            updated_at
         FROM festival_calendar
         WHERE id = $1
           AND is_active = TRUE
         LIMIT 1",
    )
    .bind(id.into_inner())
    .fetch_optional(pool.get_ref())
    .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Festival not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/festivals/{id}/media")]
pub async fn get_festival_media(pool: web::Data<PgPool>, id: web::Path<i32>) -> HttpResponse {
    match sqlx::query_as::<_, FestivalMediaItem>(
        "SELECT
            id,
            festival_id,
            title,
            image_url,
            video_url,
            media_type,
            sort_order,
            created_at,
            updated_at
         FROM festival_media
         WHERE festival_id = $1
         ORDER BY sort_order ASC, id ASC",
    )
    .bind(id.into_inner())
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

#[post("/api/festival-media/{media_id}/like")]
pub async fn like_festival_media(
    pool: web::Data<PgPool>,
    media_id: web::Path<i32>,
    body: web::Json<serde_json::Value>,
) -> HttpResponse {
    let media_id = media_id.into_inner();
    let like_name = body
        .get("name")
        .and_then(|v| v.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty());
    let result = sqlx::query(
        "INSERT INTO festival_media_likes (media_id, name) VALUES ($1, $2)",
    )
    .bind(media_id)
    .bind(like_name)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM festival_media_likes WHERE media_id = $1",
            )
            .bind(media_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to like festival media: {}", e)
        })),
    }
}

#[get("/api/festival-media/{media_id}/likes/count")]
pub async fn get_festival_media_likes_count(
    pool: web::Data<PgPool>,
    media_id: web::Path<i32>,
) -> HttpResponse {
    let media_id = media_id.into_inner();
    let row = sqlx::query_as::<_, LikeCount>(
        "SELECT COUNT(*) as count FROM festival_media_likes WHERE media_id = $1",
    )
    .bind(media_id)
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

#[get("/api/festival-media/{media_id}/comments")]
pub async fn get_festival_media_comments(
    pool: web::Data<PgPool>,
    media_id: web::Path<i32>,
) -> HttpResponse {
    let media_id = media_id.into_inner();
    let rows = sqlx::query_as::<_, FestivalMediaComment>(
        "SELECT id, media_id, name, comment, created_at
         FROM festival_media_comments
         WHERE media_id = $1
         ORDER BY created_at DESC LIMIT 100",
    )
    .bind(media_id)
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

#[post("/api/festival-media/{media_id}/comments")]
pub async fn add_festival_media_comment(
    pool: web::Data<PgPool>,
    media_id: web::Path<i32>,
    body: web::Json<NewCommentRequest>,
) -> HttpResponse {
    let media_id = media_id.into_inner();
    let result = sqlx::query(
        "INSERT INTO festival_media_comments (media_id, name, comment) VALUES ($1, $2, $3)",
    )
    .bind(media_id)
    .bind(&body.name)
    .bind(&body.comment)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => {
            let row = sqlx::query_as::<_, LikeCount>(
                "SELECT COUNT(*) as count FROM festival_media_comments WHERE media_id = $1",
            )
            .bind(media_id)
            .fetch_one(pool.get_ref())
            .await;
            match row {
                Ok(count) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": count.count })),
                Err(_) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "count": 0_i64 })),
            }
        }
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to add comment: {}", e)
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

    let payment_method = body
        .payment_method
        .as_deref()
        .unwrap_or("temple")
        .trim()
        .to_lowercase();
    if payment_method == "online" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Use POST /api/prasad/order/checkout for online payment"
        }));
    }
    if payment_method != "temple" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "payment_method must be temple or use checkout for online"
        }));
    }

    let fulfillment = body.fulfillment.trim().to_lowercase();
    if fulfillment == "delivery" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Home delivery requires online payment. Use checkout or choose temple pickup."
        }));
    }
    if fulfillment != "pickup" && fulfillment != "delivery" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "fulfillment must be pickup or delivery"
        }));
    }

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

    let (subtotal, delivery_fee, total_amount) =
        prasad_order_totals(price, body.quantity, &fulfillment);

    let result = sqlx::query(
        "INSERT INTO prasad_orders (prasad_item_id, quantity, fulfillment, name, phone, address, notes,
         subtotal, delivery_fee, total_amount, reference_id, payment_method, payment_status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NULL)",
    )
    .bind(body.prasad_item_id)
    .bind(body.quantity)
    .bind(&fulfillment)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.address)
    .bind(&body.notes)
    .bind(subtotal)
    .bind(delivery_fee)
    .bind(total_amount)
    .bind(&reference_id)
    .bind("temple")
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(PrasadOrderResponse {
            success: true,
            message: format!(
                "Booking created for {} item(s). Pay ₹{} at temple when you collect. Jai Gopal!",
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

#[post("/api/prasad/order/checkout")]
pub async fn prasad_order_checkout(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    body: web::Json<PrasadOrderRequest>,
) -> HttpResponse {
    let fulfillment = body.fulfillment.trim().to_lowercase();
    if fulfillment != "pickup" && fulfillment != "delivery" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "fulfillment must be pickup or delivery"
        }));
    }

    if fulfillment == "delivery" {
        let addr = body.address.as_deref().unwrap_or("").trim();
        if addr.is_empty() {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Address is required for delivery"
            }));
        }
    }

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

    let (subtotal, delivery_fee, total_amount) =
        prasad_order_totals(price, body.quantity, &fulfillment);

    let Some(amount_paise) = amount_to_paise(total_amount) else {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Order total must be at least ₹100 for online payment"
        }));
    };

    let reference_id = format!(
        "PRASAD-{}",
        uuid::Uuid::new_v4()
            .to_string()
            .split('-')
            .next()
            .unwrap_or("0000")
    );

    let Some(cfg) = rz.as_ref().as_ref() else {
        let reason = truncate_payment_reason(
            "Online payments are not configured on server (set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET).",
        );
        let ins = sqlx::query(
            "INSERT INTO prasad_orders (prasad_item_id, quantity, fulfillment, name, phone, address, notes,
             subtotal, delivery_fee, total_amount, reference_id, payment_method,
             payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'online','failed',NULL,NULL,$12,$13,NOW())",
        )
        .bind(body.prasad_item_id)
        .bind(body.quantity)
        .bind(&fulfillment)
        .bind(&body.name)
        .bind(&body.phone)
        .bind(&body.address)
        .bind(&body.notes)
        .bind(subtotal)
        .bind(delivery_fee)
        .bind(total_amount)
        .bind(&reference_id)
        .bind(amount_paise as i32)
        .bind(&reason)
        .execute(pool.get_ref())
        .await;
        if let Err(e) = ins {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Could not record prasad order: {}", e)
            }));
        }
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Online payments are not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
            "reference_id": reference_id,
            "recorded": true
        }));
    };

    let receipt: String = reference_id.chars().take(40).collect();
    let notes = json!({
        "dm_kind": "prasad",
        "reference_id": reference_id.clone(),
    });

    let order = match razorpay::create_order(cfg, amount_paise, &receipt, notes).await {
        Ok(o) => o,
        Err(e) => {
            let reason = truncate_payment_reason(&format!("Razorpay create order failed: {}", e));
            let ins = sqlx::query(
                "INSERT INTO prasad_orders (prasad_item_id, quantity, fulfillment, name, phone, address, notes,
                 subtotal, delivery_fee, total_amount, reference_id, payment_method,
                 payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'online','failed',NULL,NULL,$12,$13,NOW())",
            )
            .bind(body.prasad_item_id)
            .bind(body.quantity)
            .bind(&fulfillment)
            .bind(&body.name)
            .bind(&body.phone)
            .bind(&body.address)
            .bind(&body.notes)
            .bind(subtotal)
            .bind(delivery_fee)
            .bind(total_amount)
            .bind(&reference_id)
            .bind(amount_paise as i32)
            .bind(&reason)
            .execute(pool.get_ref())
            .await;
            if ins.is_ok() {
                return HttpResponse::BadGateway().json(serde_json::json!({
                    "success": false,
                    "error": format!("Could not start payment: {}", e),
                    "reference_id": reference_id,
                    "recorded": true
                }));
            }
            return HttpResponse::BadGateway().json(serde_json::json!({
                "success": false,
                "error": format!("Could not start payment: {}", e)
            }));
        }
    };

    let insert = sqlx::query(
        "INSERT INTO prasad_orders (prasad_item_id, quantity, fulfillment, name, phone, address, notes,
         subtotal, delivery_fee, total_amount, reference_id, payment_method,
         payment_status, gateway, gateway_order_id, amount_paise, status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'online','pending','razorpay',$12,$13,'pending')",
    )
    .bind(body.prasad_item_id)
    .bind(body.quantity)
    .bind(&fulfillment)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.address)
    .bind(&body.notes)
    .bind(subtotal)
    .bind(delivery_fee)
    .bind(total_amount)
    .bind(&reference_id)
    .bind(&order.id)
    .bind(amount_paise as i32)
    .execute(pool.get_ref())
    .await;

    if let Err(e) = insert {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save prasad order: {}", e)
        }));
    }

    HttpResponse::Ok().json(DonationCheckoutResponse {
        success: true,
        key_id: cfg.key_id.clone(),
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        reference_id,
    })
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

    let price_row = sqlx::query_scalar::<_, f64>(
        "SELECT price FROM seva_items WHERE id = $1 AND available = TRUE",
    )
    .bind(body.seva_item_id)
    .fetch_optional(pool.get_ref())
    .await;

    let item_price = match price_row {
        Ok(Some(p)) => p,
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
    };
    let amount_paise = (item_price * 100.0).round() as i32;

    let result = sqlx::query(
        "INSERT INTO seva_bookings (seva_item_id, name, phone, preferred_date, notes, reference_id,
         payment_status, amount_paise, paid_at)
         VALUES ($1,$2,$3,$4,$5,$6,'paid',$7,NOW())"
    )
    .bind(body.seva_item_id)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.preferred_date)
    .bind(&body.notes)
    .bind(&reference_id)
    .bind(amount_paise)
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

#[post("/api/seva/booking/checkout")]
pub async fn seva_booking_checkout(
    pool: web::Data<PgPool>,
    rz: web::Data<Option<RazorpayConfig>>,
    body: web::Json<SevaBookingRequest>,
) -> HttpResponse {
    let price_row = sqlx::query_scalar::<_, f64>(
        "SELECT price FROM seva_items WHERE id = $1 AND available = TRUE",
    )
    .bind(body.seva_item_id)
    .fetch_optional(pool.get_ref())
    .await;

    let item_price = match price_row {
        Ok(Some(p)) => p,
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
    };

    if item_price < 100.0 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "This seva item price must be at least ₹100 for online payment"
        }));
    }

    let amount_paise = (item_price * 100.0).round() as i64;
    if amount_paise < 10_000 {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Invalid amount for checkout"
        }));
    }

    let reference_id = format!(
        "SEVA-{}",
        uuid::Uuid::new_v4()
            .to_string()
            .split('-')
            .next()
            .unwrap_or("0000")
    );

    let Some(cfg) = rz.as_ref().as_ref() else {
        let reason = truncate_payment_reason(
            "Online payments are not configured on server (set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET).",
        );
        let ins = sqlx::query(
            "INSERT INTO seva_bookings (seva_item_id, name, phone, preferred_date, notes, reference_id,
             payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at, status)
             VALUES ($1, $2, $3, $4, $5, $6, 'failed', NULL, NULL, $7, $8, NOW(), 'pending')",
        )
        .bind(body.seva_item_id)
        .bind(&body.name)
        .bind(&body.phone)
        .bind(&body.preferred_date)
        .bind(&body.notes)
        .bind(&reference_id)
        .bind(amount_paise as i32)
        .bind(&reason)
        .execute(pool.get_ref())
        .await;
        if let Err(e) = ins {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Could not record seva booking: {}", e)
            }));
        }
        return HttpResponse::ServiceUnavailable().json(serde_json::json!({
            "success": false,
            "error": "Online payments are not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
            "reference_id": reference_id,
            "recorded": true
        }));
    };

    let receipt: String = reference_id.chars().take(40).collect();
    let notes = json!({
        "dm_kind": "seva",
        "reference_id": reference_id.clone(),
    });

    let order = match razorpay::create_order(cfg, amount_paise, &receipt, notes).await {
        Ok(o) => o,
        Err(e) => {
            let reason = truncate_payment_reason(&format!("Razorpay create order failed: {}", e));
            let ins = sqlx::query(
                "INSERT INTO seva_bookings (seva_item_id, name, phone, preferred_date, notes, reference_id,
                 payment_status, gateway, gateway_order_id, amount_paise, payment_failure_reason, payment_updated_at, status)
                 VALUES ($1, $2, $3, $4, $5, $6, 'failed', NULL, NULL, $7, $8, NOW(), 'pending')",
            )
            .bind(body.seva_item_id)
            .bind(&body.name)
            .bind(&body.phone)
            .bind(&body.preferred_date)
            .bind(&body.notes)
            .bind(&reference_id)
            .bind(amount_paise as i32)
            .bind(&reason)
            .execute(pool.get_ref())
            .await;
            if ins.is_ok() {
                return HttpResponse::BadGateway().json(serde_json::json!({
                    "success": false,
                    "error": format!("Could not start payment: {}", e),
                    "reference_id": reference_id,
                    "recorded": true
                }));
            }
            return HttpResponse::BadGateway().json(serde_json::json!({
                "success": false,
                "error": format!("Could not start payment: {}", e)
            }));
        }
    };

    let insert = sqlx::query(
        "INSERT INTO seva_bookings (seva_item_id, name, phone, preferred_date, notes, reference_id,
         payment_status, gateway, gateway_order_id, amount_paise, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'razorpay', $7, $8, 'pending')",
    )
    .bind(body.seva_item_id)
    .bind(&body.name)
    .bind(&body.phone)
    .bind(&body.preferred_date)
    .bind(&body.notes)
    .bind(&reference_id)
    .bind(&order.id)
    .bind(amount_paise as i32)
    .execute(pool.get_ref())
    .await;

    if let Err(e) = insert {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save seva booking: {}", e)
        }));
    }

    HttpResponse::Ok().json(DonationCheckoutResponse {
        success: true,
        key_id: cfg.key_id.clone(),
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        reference_id,
    })
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
            o.subtotal,
            o.delivery_fee,
            o.payment_method,
            o.payment_status,
            o.gateway,
            o.gateway_order_id,
            o.gateway_payment_id,
            o.payment_failure_reason,
            o.payment_updated_at,
            o.payment_admin_note,
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

    let caller_phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid phone"
            }))
        }
    };
    let order_phone = normalize_phone(&existing.phone).unwrap_or_else(|| existing.phone.trim().to_string());
    if caller_phone != order_phone {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "success": false,
            "error": "Phone does not match this booking"
        }));
    }

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
        body.address.clone().or(existing.address.clone())
    } else {
        None
    };
    let new_notes = body.notes.clone().or(existing.notes);

    if existing.payment_method == "temple" && new_fulfillment == "delivery" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Cannot switch pay-at-temple pickup to home delivery. Cancel and place a new order with online payment."
        }));
    }

    let pending_online = existing.gateway_order_id.is_some()
        && existing.payment_status.as_deref() == Some("pending");
    if pending_online {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Cannot edit order while online payment is pending. Complete or cancel payment first."
        }));
    }

    let paid_online = existing.payment_method == "online"
        && existing.payment_status.as_deref() == Some("paid");
    if paid_online {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Cannot edit a paid online order. Contact the temple for changes."
        }));
    }

    if new_fulfillment == "delivery" {
        let addr = new_address.as_deref().unwrap_or("").trim();
        if addr.is_empty() {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Address is required for delivery"
            }));
        }
    }

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

    let (subtotal, delivery_fee, total_amount) =
        prasad_order_totals(price, new_qty, &new_fulfillment);

    let result = sqlx::query(
        "UPDATE prasad_orders
         SET quantity = $1, fulfillment = $2, address = $3, notes = $4,
             subtotal = $5, delivery_fee = $6, total_amount = $7
         WHERE reference_id = $8",
    )
    .bind(new_qty)
    .bind(&new_fulfillment)
    .bind(&new_address)
    .bind(&new_notes)
    .bind(subtotal)
    .bind(delivery_fee)
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
            s.price as seva_price,
            b.payment_status,
            b.gateway,
            b.gateway_order_id,
            b.gateway_payment_id,
            b.payment_failure_reason,
            b.payment_updated_at
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
