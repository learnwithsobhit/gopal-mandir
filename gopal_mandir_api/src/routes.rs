use actix_web::{get, post, patch, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use crate::models::*;
use crate::util::{bearer_token, normalize_phone, sha256_hex};
use chrono::{Duration, Utc};
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
