//! Admin (CRM) API: OTP auth, presigned S3 uploads, gallery/live-darshan/prasad management.

use actix_web::{delete, get, patch, post, web, HttpRequest, HttpResponse};
use chrono::{Duration, Utc};
use rand::Rng;
use sqlx::PgPool;
use std::env;
use uuid::Uuid;

use crate::s3_presign::{encode_s3_object_path, path_style_object_path, presign_put_url};

use crate::models::*;
use crate::util::{bearer_token, normalize_phone, sha256_hex};

const MAX_PRESIGN_BYTES: i64 = 100 * 1024 * 1024; // 100 MB

pub(crate) async fn require_admin(pool: &PgPool, req: &HttpRequest) -> Result<Admin, HttpResponse> {
    let token = match bearer_token(req) {
        Some(t) => t,
        None => {
            return Err(HttpResponse::Unauthorized().json(serde_json::json!({
                "success": false,
                "error": "Missing token"
            })))
        }
    };
    let token_hash = sha256_hex(&token);
    let row = sqlx::query_as::<_, Admin>(
        "SELECT a.id, a.phone, a.name, a.status, a.created_at, a.updated_at
         FROM admin_sessions s
         JOIN admins a ON a.id = s.admin_id
         WHERE s.token_hash = $1 AND s.expires_at > NOW() AND a.status = 'active'
         LIMIT 1",
    )
    .bind(&token_hash)
    .fetch_optional(pool)
    .await;

    match row {
        Ok(Some(admin)) => Ok(admin),
        Ok(None) => Err(HttpResponse::Unauthorized().json(serde_json::json!({
            "success": false,
            "error": "Invalid session"
        }))),
        Err(e) => Err(HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        }))),
    }
}

pub(crate) fn admin_parse_patch_payment_status(body: &AdminPatchPaymentRequest) -> Result<String, &'static str> {
    let s = body.payment_status.trim().to_lowercase();
    if s != "paid" && s != "refunded" {
        return Err("payment_status must be paid or refunded");
    }
    Ok(s)
}

pub(crate) fn optional_payment_trim(opt: &Option<String>, max_chars: usize) -> Option<String> {
    opt.as_ref()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .map(|s| s.chars().take(max_chars).collect())
}

const MIN_ADMIN_PAYMENT_NOTE_LEN: usize = 3;
const MAX_ADMIN_PAYMENT_NOTE_LEN: usize = 500;

/// Required audit note when admin changes payment status (trim, length bounds).
pub(crate) fn required_admin_payment_note(opt: &Option<String>) -> Result<String, &'static str> {
    let s = opt
        .as_ref()
        .map(|x| x.trim())
        .filter(|x| !x.is_empty())
        .ok_or("admin_note is required")?;
    if s.chars().count() < MIN_ADMIN_PAYMENT_NOTE_LEN {
        return Err("admin_note must be at least 3 characters");
    }
    Ok(s.chars().take(MAX_ADMIN_PAYMENT_NOTE_LEN).collect())
}

fn validate_media_type(ct: &str, ext_in: &str) -> Option<&'static str> {
    let ct = ct.trim().to_lowercase();
    let ext_lower = ext_in.trim().to_lowercase();
    let ext = ext_lower.trim_start_matches('.');
    match ext {
        "jpg" | "jpeg" if ct == "image/jpeg" || ct == "image/jpg" => Some("image/jpeg"),
        "png" if ct == "image/png" => Some("image/png"),
        "webp" if ct == "image/webp" => Some("image/webp"),
        "gif" if ct == "image/gif" => Some("image/gif"),
        "mp4" if ct == "video/mp4" => Some("video/mp4"),
        "mov" if ct == "video/quicktime" => Some("video/quicktime"),
        "mp3" if ct == "audio/mpeg" || ct == "audio/mp3" => Some("audio/mpeg"),
        _ => None,
    }
}

fn public_object_url(bucket: &str, region: &str, key: &str) -> String {
    if let Ok(base) = env::var("MEDIA_PUBLIC_BASE_URL") {
        let b = base.trim_end_matches('/');
        format!("{}/{}", b, key)
    } else {
        format!("https://{}.s3.{}.amazonaws.com/{}", bucket, region, key)
    }
}

#[post("/api/admin/request-otp")]
pub async fn admin_request_otp(
    pool: web::Data<PgPool>,
    body: web::Json<AdminRequestOtpRequest>,
) -> HttpResponse {
    let phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid phone"
            }))
        }
    };

    let is_admin = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM admins WHERE phone = $1 AND status = 'active')",
    )
    .bind(&phone)
    .fetch_one(pool.get_ref())
    .await;

    match is_admin {
        Ok(true) => {}
        Ok(false) => {
            return HttpResponse::Forbidden().json(serde_json::json!({
                "success": false,
                "error": "This phone is not registered as an admin"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    }

    let attempts_limit: i64 = 3;
    let rate_limit_window = Duration::minutes(10);
    let now = Utc::now();
    let recent = sqlx::query_as::<_, (i64, Option<chrono::DateTime<Utc>>)>(
        "SELECT COUNT(*) as count, MIN(created_at) as first_at
         FROM admin_otp
         WHERE phone = $1 AND created_at > NOW() - INTERVAL '10 minutes'",
    )
    .bind(&phone)
    .fetch_one(pool.get_ref())
    .await;
    if let Ok((count, first_at)) = recent {
        let attempts_used = count.max(0);
        let attempts_remaining = (attempts_limit - attempts_used).max(0);
        if attempts_used >= attempts_limit {
            let retry_after_sec = first_at
                .map(|t| ((t + rate_limit_window - now).num_seconds()).max(1))
                .unwrap_or(rate_limit_window.num_seconds().max(1));
            return HttpResponse::TooManyRequests()
                .insert_header(("Retry-After", retry_after_sec.to_string()))
                .json(serde_json::json!({
                    "success": false,
                    "error": "Too many OTP requests. Please wait before trying again.",
                    "attempts_used": attempts_used,
                    "attempts_limit": attempts_limit,
                    "attempts_remaining": attempts_remaining,
                    "retry_after_sec": retry_after_sec
                }));
        }
    }

    let otp_num: u32 = rand::thread_rng().gen_range(0..=999_999);
    let otp = format!("{:06}", otp_num);
    let pepper = env::var("ADMIN_OTP_PEPPER").unwrap_or_else(|_| "dev".to_string());
    let otp_hash = sha256_hex(&format!("{}:{}:{}", phone, otp, pepper));
    let expires_at = Utc::now() + Duration::minutes(5);
    let id = Uuid::new_v4();

    let result = sqlx::query(
        "INSERT INTO admin_otp (id, phone, otp_hash, expires_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(id)
    .bind(&phone)
    .bind(&otp_hash)
    .bind(expires_at)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(AdminRequestOtpResponse {
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

#[post("/api/admin/verify-otp")]
pub async fn admin_verify_otp(
    pool: web::Data<PgPool>,
    body: web::Json<AdminVerifyOtpRequest>,
) -> HttpResponse {
    let phone = match normalize_phone(&body.phone) {
        Some(p) => p,
        None => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid phone"
            }))
        }
    };
    let otp = body.otp.trim().to_string();
    if otp.len() != 6 || !otp.chars().all(|c| c.is_ascii_digit()) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Invalid OTP"
        }));
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
         FROM admin_otp
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
            return HttpResponse::Unauthorized()
                .json(serde_json::json!({"success": false, "error": "OTP not found"}));
        }
        Err(e) => {
            let _ = tx.rollback().await;
            return HttpResponse::InternalServerError()
                .json(serde_json::json!({"success": false, "error": format!("Database error: {}", e)}));
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

    let pepper = env::var("ADMIN_OTP_PEPPER").unwrap_or_else(|_| "dev".to_string());
    let expected = sha256_hex(&format!("{}:{}:{}", phone, otp, pepper));

    if expected != otp_hash {
        let _ = sqlx::query("UPDATE admin_otp SET attempts = attempts + 1 WHERE id = $1")
            .bind(otp_id)
            .execute(&mut *tx)
            .await;
        let _ = tx.commit().await;
        return HttpResponse::Unauthorized().json(serde_json::json!({"success": false, "error": "Invalid OTP"}));
    }

    if let Err(e) = sqlx::query("UPDATE admin_otp SET consumed_at = NOW() WHERE id = $1 AND consumed_at IS NULL")
        .bind(otp_id)
        .execute(&mut *tx)
        .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to consume OTP: {}", e)
        }));
    }

    let name_update = body.name.clone().unwrap_or_default().trim().to_string();
    let admin_row = if !name_update.is_empty() {
        sqlx::query_as::<_, Admin>(
            "UPDATE admins SET name = $2, updated_at = NOW() WHERE phone = $1 AND status = 'active'
             RETURNING id, phone, name, status, created_at, updated_at",
        )
        .bind(&phone)
        .bind(&name_update)
        .fetch_optional(&mut *tx)
        .await
    } else {
        sqlx::query_as::<_, Admin>(
            "SELECT id, phone, name, status, created_at, updated_at FROM admins
             WHERE phone = $1 AND status = 'active' LIMIT 1",
        )
        .bind(&phone)
        .fetch_optional(&mut *tx)
        .await
    };

    let admin = match admin_row {
        Ok(Some(a)) => a,
        Ok(None) => {
            let _ = tx.rollback().await;
            return HttpResponse::Forbidden().json(serde_json::json!({
                "success": false,
                "error": "Admin not found"
            }));
        }
        Err(e) => {
            let _ = tx.rollback().await;
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
    };

    let raw_token = Uuid::new_v4().to_string();
    let token_hash = sha256_hex(&raw_token);
    let session_id = Uuid::new_v4();
    let expires_at = Utc::now() + Duration::days(30);

    if let Err(e) = sqlx::query(
        "INSERT INTO admin_sessions (id, admin_id, token_hash, expires_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(session_id)
    .bind(admin.id)
    .bind(&token_hash)
    .bind(expires_at)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to create session: {}", e)
        }));
    }

    if let Err(e) = tx.commit().await {
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        }));
    }

    HttpResponse::Ok().json(AdminVerifyOtpResponse {
        success: true,
        token: raw_token,
        admin,
    })
}

#[get("/api/admin/me")]
pub async fn admin_me(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    match require_admin(pool.get_ref(), &req).await {
        Ok(admin) => HttpResponse::Ok().json(AdminMeResponse { success: true, admin }),
        Err(resp) => resp,
    }
}

#[post("/api/admin/logout")]
pub async fn admin_logout(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    let token = match bearer_token(&req) {
        Some(t) => t,
        None => {
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "success": false,
                "error": "Missing token"
            }))
        }
    };
    let token_hash = sha256_hex(&token);
    let _ = sqlx::query("DELETE FROM admin_sessions WHERE token_hash = $1")
        .bind(&token_hash)
        .execute(pool.get_ref())
        .await;
    HttpResponse::Ok().json(AdminLogoutResponse { success: true })
}

#[post("/api/admin/media/presign")]
pub async fn admin_media_presign(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPresignRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let bucket = match env::var("S3_BUCKET") {
        Ok(b) if !b.trim().is_empty() => b,
        _ => {
            return HttpResponse::ServiceUnavailable().json(serde_json::json!({
                "success": false,
                "error": "S3_BUCKET is not configured"
            }))
        }
    };

    let region = env::var("AWS_REGION").unwrap_or_else(|_| "us-east-1".to_string());
    let access_key = match env::var("AWS_ACCESS_KEY_ID") {
        Ok(k) if !k.trim().is_empty() => k,
        _ => {
            return HttpResponse::ServiceUnavailable().json(serde_json::json!({
                "success": false,
                "error": "AWS_ACCESS_KEY_ID is not configured"
            }))
        }
    };
    let secret_key = match env::var("AWS_SECRET_ACCESS_KEY") {
        Ok(k) if !k.trim().is_empty() => k,
        _ => {
            return HttpResponse::ServiceUnavailable().json(serde_json::json!({
                "success": false,
                "error": "AWS_SECRET_ACCESS_KEY is not configured"
            }))
        }
    };

    if let Some(sz) = body.size_bytes {
        if sz <= 0 || sz > MAX_PRESIGN_BYTES {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": format!("size_bytes must be between 1 and {}", MAX_PRESIGN_BYTES)
            }));
        }
    }

    let canonical_ct = match validate_media_type(&body.content_type, &body.file_ext) {
        Some(ct) => ct.to_string(),
        None => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Unsupported content_type / file_ext combination"
            }))
        }
    };

    let prefix = body
        .object_key_prefix
        .as_deref()
        .unwrap_or("uploads")
        .trim()
        .trim_matches('/');
    if prefix.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Invalid object_key_prefix"
        }));
    }

    let ext_norm = body.file_ext.trim().to_lowercase();
    let ext = ext_norm.trim_start_matches('.');
    let key = format!("{}/{}.{}", prefix, Uuid::new_v4(), ext);

    let endpoint = env::var("S3_ENDPOINT").ok().filter(|s| !s.trim().is_empty());

    let (host_header, canonical_uri, use_https) = if let Some(ref ep) = endpoint {
        let u = match url::Url::parse(ep.trim()) {
            Ok(u) => u,
            Err(e) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Invalid S3_ENDPOINT: {}", e)
                }))
            }
        };
        let https = u.scheme() == "https";
        let host = match u.host_str() {
            Some(h) => h.to_string(),
            None => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": "S3_ENDPOINT has no host"
                }))
            }
        };
        let host_header = match u.port() {
            Some(p) => format!("{}:{}", host, p),
            None => host,
        };
        let uri = path_style_object_path(bucket.trim(), &key);
        (host_header, uri, https)
    } else {
        let host_header = format!("{}.s3.{}.amazonaws.com", bucket.trim(), region.trim());
        let uri = encode_s3_object_path(&key);
        (host_header, uri, true)
    };

    let upload_url = match presign_put_url(
        &host_header,
        &canonical_uri,
        region.trim(),
        access_key.trim(),
        secret_key.trim(),
        &canonical_ct,
        900,
        use_https,
    ) {
        Ok(u) => u,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Presign failed: {}", e)
            }))
        }
    };
    let public_url = public_object_url(&bucket, &region, &key);

    HttpResponse::Ok().json(AdminPresignResponse {
        success: true,
        upload_url,
        public_url,
        key,
        expires_in_sec: 900,
    })
}

#[derive(serde::Deserialize)]
pub struct AdminGalleryListQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
    pub category: Option<String>,
}

#[get("/api/admin/gallery")]
pub async fn admin_list_gallery(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminGalleryListQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(20).min(100).max(1);
    let offset = (page - 1) * per_page;

    let rows = if let Some(ref cat) = q.category {
        let cat_trim = cat.trim();
        if cat_trim.is_empty() {
            sqlx::query_as::<_, GalleryItem>(
                "SELECT * FROM gallery ORDER BY id DESC LIMIT $1 OFFSET $2",
            )
            .bind(per_page as i64)
            .bind(offset as i64)
            .fetch_all(pool.get_ref())
            .await
        } else {
            sqlx::query_as::<_, GalleryItem>(
                "SELECT * FROM gallery WHERE category = $1 ORDER BY id DESC LIMIT $2 OFFSET $3",
            )
            .bind(cat_trim)
            .bind(per_page as i64)
            .bind(offset as i64)
            .fetch_all(pool.get_ref())
            .await
        }
    } else {
        sqlx::query_as::<_, GalleryItem>(
            "SELECT * FROM gallery ORDER BY id DESC LIMIT $1 OFFSET $2",
        )
        .bind(per_page as i64)
        .bind(offset as i64)
        .fetch_all(pool.get_ref())
        .await
    };

    match rows {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/gallery")]
pub async fn admin_create_gallery(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateGalleryRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let title = body.title.trim();
    if title.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title is required"
        }));
    }
    let category = body.category.trim();
    if category.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "category is required"
        }));
    }

    let media_type = body
        .media_type
        .as_deref()
        .unwrap_or("image")
        .trim()
        .to_lowercase();
    if media_type != "image" && media_type != "video" && media_type != "audio" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "media_type must be image, video, or audio"
        }));
    }

    let image_url = body.image_url.trim();
    let video_url = body.video_url.as_deref().unwrap_or("").trim();
    if media_type == "image" && image_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "image_url is required for image media"
        }));
    }
    if media_type == "video" && video_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "video_url is required for video media"
        }));
    }
    if media_type == "audio" && video_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "video_url is required for audio media (MP3 URL)"
        }));
    }

    let row = sqlx::query_as::<_, GalleryItem>(
        "INSERT INTO gallery (title, image_url, category, video_url, media_type)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *",
    )
    .bind(title)
    .bind(if image_url.is_empty() { "" } else { image_url })
    .bind(category)
    .bind(video_url)
    .bind(&media_type)
    .fetch_one(pool.get_ref())
    .await;

    match row {
        Ok(item) => HttpResponse::Ok().json(ApiResponse { success: true, data: item }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/gallery/{id}")]
pub async fn admin_patch_gallery(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchGalleryRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, GalleryItem>("SELECT * FROM gallery WHERE id = $1")
        .bind(id)
        .fetch_optional(pool.get_ref())
        .await;

    let mut row = match existing {
        Ok(Some(g)) => g,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    if let Some(ref t) = body.title {
        let t = t.trim();
        if !t.is_empty() {
            row.title = t.to_string();
        }
    }
    if let Some(ref c) = body.category {
        let c = c.trim();
        if !c.is_empty() {
            row.category = c.to_string();
        }
    }
    if let Some(ref u) = body.image_url {
        row.image_url = u.trim().to_string();
    }
    if let Some(ref u) = body.video_url {
        row.video_url = u.trim().to_string();
    }
    if let Some(ref m) = body.media_type {
        let m = m.trim().to_lowercase();
        if m == "image" || m == "video" || m == "audio" {
            row.media_type = m;
        }
    }

    let updated = sqlx::query_as::<_, GalleryItem>(
        "UPDATE gallery SET title = $2, category = $3, image_url = $4, video_url = $5, media_type = $6
         WHERE id = $1
         RETURNING *",
    )
    .bind(id)
    .bind(&row.title)
    .bind(&row.category)
    .bind(&row.image_url)
    .bind(&row.video_url)
    .bind(&row.media_type)
    .fetch_one(pool.get_ref())
    .await;

    match updated {
        Ok(item) => HttpResponse::Ok().json(ApiResponse { success: true, data: item }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/gallery/{id}")]
pub async fn admin_delete_gallery(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let r = sqlx::query("DELETE FROM gallery WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Deleted".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/admin/live-darshan")]
pub async fn admin_get_live_darshan(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

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

#[patch("/api/admin/live-darshan")]
pub async fn admin_patch_live_darshan(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPatchLiveDarshanRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let current = match sqlx::query_as::<_, LiveDarshanInfo>("SELECT * FROM live_darshan ORDER BY id LIMIT 1")
        .fetch_optional(pool.get_ref())
        .await
    {
        Ok(Some(c)) => c,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Live darshan config not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let title = match &body.title {
        None => current.title.clone(),
        Some(s) => {
            let t = s.trim();
            if t.is_empty() {
                current.title.clone()
            } else {
                t.chars().take(200).collect()
            }
        }
    };
    let stream_url = match &body.stream_url {
        None => current.stream_url.clone(),
        Some(s) => s.trim().to_string(),
    };
    let is_live = body.is_live.unwrap_or(current.is_live);
    let description = match &body.description {
        None => current.description.clone(),
        Some(s) => s.trim().chars().take(8000).collect(),
    };

    if is_live && stream_url.trim().is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Cannot mark live without a non-empty stream_url"
        }));
    }
    if !stream_url.trim().is_empty() {
        if let Err(msg) = validate_live_stream_url(&stream_url) {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }));
        }
    }

    let updated = sqlx::query_as::<_, LiveDarshanInfo>(
        "UPDATE live_darshan SET title = $2, stream_url = $3, is_live = $4, description = $5, updated_at = NOW()
         WHERE id = $1
         RETURNING *",
    )
    .bind(current.id)
    .bind(&title)
    .bind(&stream_url)
    .bind(is_live)
    .bind(&description)
    .fetch_one(pool.get_ref())
    .await;

    match updated {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[derive(serde::Deserialize)]
pub struct AdminPrasadOrdersQuery {
    pub status: Option<String>,
    pub from_date: Option<String>,
    pub to_date: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[get("/api/admin/prasad/orders")]
pub async fn admin_list_prasad_orders(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminPrasadOrdersQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);

    let status_filter = q.status.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());
    let from_d = q.from_date.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());
    let to_d = q.to_date.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());

    let rows = sqlx::query_as::<_, PrasadOrderView>(
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
         WHERE ($1::text IS NULL OR o.status = $1)
           AND ($2::text IS NULL OR o.created_at::date >= $2::date)
           AND ($3::text IS NULL OR o.created_at::date <= $3::date)
         ORDER BY o.created_at DESC
         LIMIT $4 OFFSET $5",
    )
    .bind(status_filter.as_deref())
    .bind(from_d.as_deref())
    .bind(to_d.as_deref())
    .bind(limit)
    .bind(offset)
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

#[patch("/api/admin/prasad/order/{reference_id}")]
pub async fn admin_patch_prasad_order(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminUpdatePrasadStatusRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let reference_id = reference_id.into_inner();
    let status = body.status.trim().to_lowercase();
    if status.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "status is required"
        }));
    }

    let allowed = ["pending", "confirmed", "ready", "completed", "cancelled"];
    if !allowed.contains(&status.as_str()) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Invalid status"
        }));
    }

    let r = sqlx::query(
        "UPDATE prasad_orders SET status = $1 WHERE reference_id = $2",
    )
    .bind(&status)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Order updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Order not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/prasad/order/{reference_id}/payment")]
pub async fn admin_patch_prasad_order_payment(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminPatchPaymentRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let new_status = match admin_parse_patch_payment_status(&body) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let admin_note = match required_admin_payment_note(&body.admin_note) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let gateway_id = optional_payment_trim(&body.gateway_payment_id, 64);
    let reference_id = reference_id.into_inner();

    let r = sqlx::query(
        "UPDATE prasad_orders SET
            payment_status = $1,
            payment_updated_at = NOW(),
            paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END,
            payment_failure_reason = CASE WHEN $1 IN ('paid','refunded') THEN NULL ELSE payment_failure_reason END,
            gateway_payment_id = CASE WHEN $2 IS NOT NULL THEN $2 ELSE gateway_payment_id END,
            payment_admin_note = $3
         WHERE reference_id = $4
           AND payment_method = 'online'
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
            "error": "Prasad order not found, not online payment, or payment status cannot be changed"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Panchang CRUD
// ──────────────────────────────────────────────

#[derive(serde::Deserialize)]
pub struct AdminPanchangQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

#[get("/api/admin/panchang")]
pub async fn admin_list_panchang(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminPanchangQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(50).min(200);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    match sqlx::query_as::<_, HinduPanchang>(
        "SELECT id, for_date::TEXT as for_date, content, created_at
         FROM hindu_panchang
         ORDER BY for_date DESC
         LIMIT $1 OFFSET $2",
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data,
            "page": page,
            "per_page": per_page
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/panchang")]
pub async fn admin_create_panchang(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreatePanchangRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let for_date = body.for_date.trim();
    let content = body.content.trim();
    if for_date.is_empty() || content.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "for_date and content are required"
        }));
    }
    let parsed_date = match chrono::NaiveDate::parse_from_str(for_date, "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid date format, use YYYY-MM-DD"
            }));
        }
    };

    match sqlx::query_as::<_, HinduPanchang>(
        "INSERT INTO hindu_panchang (for_date, content)
         VALUES ($1, $2)
         RETURNING id, for_date::TEXT as for_date, content, created_at",
    )
    .bind(parsed_date)
    .bind(content)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => {
            let msg = format!("{}", e);
            if msg.contains("duplicate key") || msg.contains("unique constraint") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "success": false,
                    "error": format!("Panchang for {} already exists", for_date)
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        }
    }
}

#[patch("/api/admin/panchang/{id}")]
pub async fn admin_patch_panchang(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchPanchangRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, HinduPanchang>(
        "SELECT id, for_date::TEXT as for_date, content, created_at FROM hindu_panchang WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Panchang entry not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
    };

    let new_content = body.content.as_deref().unwrap_or(&existing.content).trim().to_string();
    let new_date_str = body.for_date.as_deref().unwrap_or(&existing.for_date).trim().to_string();
    let parsed_date = match chrono::NaiveDate::parse_from_str(&new_date_str, "%Y-%m-%d") {
        Ok(d) => d,
        Err(_) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Invalid date format, use YYYY-MM-DD"
            }));
        }
    };

    match sqlx::query_as::<_, HinduPanchang>(
        "UPDATE hindu_panchang SET for_date = $1, content = $2
         WHERE id = $3
         RETURNING id, for_date::TEXT as for_date, content, created_at",
    )
    .bind(parsed_date)
    .bind(&new_content)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => {
            let msg = format!("{}", e);
            if msg.contains("duplicate key") || msg.contains("unique constraint") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "success": false,
                    "error": format!("Panchang for {} already exists", new_date_str)
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        }
    }
}

#[delete("/api/admin/panchang/{id}")]
pub async fn admin_delete_panchang(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    match sqlx::query("DELETE FROM hindu_panchang WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Entry not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/admin/daily-upasana")]
pub async fn admin_list_daily_upasana(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminDailyUpasanaQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(50).min(200).max(1);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;
    let title_filter = q.title.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let title_like = title_filter.map(|s| format!("%{}%", s));

    match sqlx::query_as::<_, DailyUpasanaItem>(
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
         WHERE ($1::TEXT IS NULL OR title ILIKE $1 OR category ILIKE $1)
         ORDER BY sort_order ASC, title ASC, id ASC
         LIMIT $2 OFFSET $3",
    )
    .bind(title_like.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data,
            "page": page,
            "per_page": per_page
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/daily-upasana")]
pub async fn admin_create_daily_upasana(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateDailyUpasanaRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let title = body.title.trim();
    let content = body.content.trim();
    if title.is_empty() || content.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title and content are required"
        }));
    }
    let category = body.category.as_deref().unwrap_or("").trim();
    let sort_order = body.sort_order.unwrap_or(0);
    let is_published = body.is_published.unwrap_or(false);

    match sqlx::query_as::<_, DailyUpasanaItem>(
        "INSERT INTO daily_upasana_items (title, category, content, sort_order, is_published)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING
            id,
            title,
            category,
            content,
            sort_order,
            is_published,
            created_at,
            updated_at",
    )
    .bind(title)
    .bind(category)
    .bind(content)
    .bind(sort_order)
    .bind(is_published)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => {
            let msg = format!("{}", e);
            if msg.contains("duplicate key") || msg.contains("unique constraint") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "success": false,
                    "error": "An upasana item with this title already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        }
    }
}

#[patch("/api/admin/daily-upasana/{id}")]
pub async fn admin_patch_daily_upasana(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchDailyUpasanaRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, DailyUpasanaItem>(
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
         WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Daily upasana item not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
    };

    let new_title = body.title.as_deref().unwrap_or(&existing.title).trim().to_string();
    let new_content = body.content.as_deref().unwrap_or(&existing.content).trim().to_string();
    if new_title.is_empty() || new_content.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title and content are required"
        }));
    }
    let new_category = body.category.as_deref().unwrap_or(&existing.category).trim().to_string();
    let new_sort_order = body.sort_order.unwrap_or(existing.sort_order);
    let new_is_published = body.is_published.unwrap_or(existing.is_published);

    match sqlx::query_as::<_, DailyUpasanaItem>(
        "UPDATE daily_upasana_items
         SET
            title = $1,
            category = $2,
            content = $3,
            sort_order = $4,
            is_published = $5,
            updated_at = NOW()
         WHERE id = $6
         RETURNING
            id,
            title,
            category,
            content,
            sort_order,
            is_published,
            created_at,
            updated_at",
    )
    .bind(new_title)
    .bind(new_category)
    .bind(new_content)
    .bind(new_sort_order)
    .bind(new_is_published)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => {
            let msg = format!("{}", e);
            if msg.contains("duplicate key") || msg.contains("unique constraint") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "success": false,
                    "error": "An upasana item with this title already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        }
    }
}

#[delete("/api/admin/daily-upasana/{id}")]
pub async fn admin_delete_daily_upasana(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    match sqlx::query("DELETE FROM daily_upasana_items WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Daily upasana item not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

fn parse_yyyy_mm_dd(raw: &str) -> Result<chrono::NaiveDate, &'static str> {
    chrono::NaiveDate::parse_from_str(raw, "%Y-%m-%d")
        .map_err(|_| "Invalid date format, use YYYY-MM-DD")
}

#[get("/api/admin/festivals")]
pub async fn admin_list_festivals(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminListFestivalQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(50).min(200).max(1);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    let from_date = q.from_date.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let to_date = q.to_date.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let search = q.q.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let search_like = search.map(|s| format!("%{}%", s));

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
         WHERE ($1::TEXT IS NULL OR for_date >= $1::DATE)
           AND ($2::TEXT IS NULL OR for_date <= $2::DATE)
           AND ($3::TEXT IS NULL OR title ILIKE $3 OR description ILIKE $3)
         ORDER BY for_date DESC, sort_order ASC, id ASC
         LIMIT $4 OFFSET $5",
    )
    .bind(from_date)
    .bind(to_date)
    .bind(search_like.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data,
            "page": page,
            "per_page": per_page
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/festivals")]
pub async fn admin_create_festival(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateFestivalRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let for_date = body.for_date.trim();
    let title = body.title.trim();
    let description = body.description.trim();
    if for_date.is_empty() || title.is_empty() || description.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "for_date, title and description are required"
        }));
    }
    let parsed_date = match parse_yyyy_mm_dd(for_date) {
        Ok(d) => d,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };

    let sort_order = body.sort_order.unwrap_or(0);
    let is_active = body.is_active.unwrap_or(true);
    let icon_url = body.icon_url.as_deref().unwrap_or("").trim();
    let banner_url = body.banner_url.as_deref().unwrap_or("").trim();

    match sqlx::query_as::<_, FestivalEntry>(
        "INSERT INTO festival_calendar
            (for_date, title, description, icon_url, banner_url, sort_order, is_active)
         VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''), $6, $7)
         RETURNING
            id,
            to_char(for_date, 'YYYY-MM-DD') as for_date,
            title,
            description,
            icon_url,
            banner_url,
            sort_order,
            is_active,
            created_at,
            updated_at",
    )
    .bind(parsed_date)
    .bind(title)
    .bind(description)
    .bind(icon_url)
    .bind(banner_url)
    .bind(sort_order)
    .bind(is_active)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/festivals/{id}")]
pub async fn admin_patch_festival(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchFestivalRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, FestivalEntry>(
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
         WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Festival entry not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let new_date_str = body.for_date.as_deref().unwrap_or(&existing.for_date).trim().to_string();
    let new_date = match parse_yyyy_mm_dd(&new_date_str) {
        Ok(d) => d,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let new_title = body.title.as_deref().unwrap_or(&existing.title).trim().to_string();
    let new_description = body
        .description
        .as_deref()
        .unwrap_or(&existing.description)
        .trim()
        .to_string();
    if new_title.is_empty() || new_description.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title and description cannot be empty"
        }));
    }
    let new_sort = body.sort_order.unwrap_or(existing.sort_order);
    let new_active = body.is_active.unwrap_or(existing.is_active);
    let new_icon = body.icon_url.as_ref().map(|s| s.trim().to_string()).or(existing.icon_url);
    let new_banner = body
        .banner_url
        .as_ref()
        .map(|s| s.trim().to_string())
        .or(existing.banner_url);

    match sqlx::query_as::<_, FestivalEntry>(
        "UPDATE festival_calendar
         SET for_date = $1,
             title = $2,
             description = $3,
             icon_url = NULLIF($4, ''),
             banner_url = NULLIF($5, ''),
             sort_order = $6,
             is_active = $7,
             updated_at = NOW()
         WHERE id = $8
         RETURNING
            id,
            to_char(for_date, 'YYYY-MM-DD') as for_date,
            title,
            description,
            icon_url,
            banner_url,
            sort_order,
            is_active,
            created_at,
            updated_at",
    )
    .bind(new_date)
    .bind(&new_title)
    .bind(&new_description)
    .bind(new_icon.unwrap_or_default())
    .bind(new_banner.unwrap_or_default())
    .bind(new_sort)
    .bind(new_active)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/festivals/{id}")]
pub async fn admin_delete_festival(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    match sqlx::query("DELETE FROM festival_calendar WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Festival entry not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/admin/festivals/{id}/media")]
pub async fn admin_list_festival_media(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let festival_id = id.into_inner();
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
    .bind(festival_id)
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

#[post("/api/admin/festivals/{id}/media")]
pub async fn admin_create_festival_media(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminCreateFestivalMediaRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let festival_id = id.into_inner();
    let title = body.title.trim();
    if title.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title is required"
        }));
    }
    let media_type = body
        .media_type
        .as_deref()
        .unwrap_or("image")
        .trim()
        .to_lowercase();
    if media_type != "image" && media_type != "video" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "media_type must be image or video"
        }));
    }
    let image_url = body.image_url.as_deref().unwrap_or("").trim();
    let video_url = body.video_url.as_deref().unwrap_or("").trim();
    if media_type == "image" && image_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "image_url is required for image media"
        }));
    }
    if media_type == "video" && video_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "video_url is required for video media"
        }));
    }

    let sort_order = body.sort_order.unwrap_or(0);
    match sqlx::query_as::<_, FestivalMediaItem>(
        "INSERT INTO festival_media
            (festival_id, title, image_url, video_url, media_type, sort_order)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING
            id,
            festival_id,
            title,
            image_url,
            video_url,
            media_type,
            sort_order,
            created_at,
            updated_at",
    )
    .bind(festival_id)
    .bind(title)
    .bind(image_url)
    .bind(video_url)
    .bind(media_type)
    .bind(sort_order)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/festival-media/{media_id}")]
pub async fn admin_patch_festival_media(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    media_id: web::Path<i32>,
    body: web::Json<AdminPatchFestivalMediaRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let media_id = media_id.into_inner();
    let existing = sqlx::query_as::<_, FestivalMediaItem>(
        "SELECT
            id, festival_id, title, image_url, video_url, media_type, sort_order, created_at, updated_at
         FROM festival_media WHERE id = $1",
    )
    .bind(media_id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(x)) => x,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Festival media not found"
            }))
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }))
        }
    };

    let title = body.title.as_deref().unwrap_or(&existing.title).trim().to_string();
    if title.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title cannot be empty"
        }));
    }
    let media_type = body
        .media_type
        .as_deref()
        .unwrap_or(&existing.media_type)
        .trim()
        .to_lowercase();
    if media_type != "image" && media_type != "video" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "media_type must be image or video"
        }));
    }
    let image_url = body.image_url.as_deref().unwrap_or(&existing.image_url).trim().to_string();
    let video_url = body.video_url.as_deref().unwrap_or(&existing.video_url).trim().to_string();
    if media_type == "image" && image_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "image_url is required for image media"
        }));
    }
    if media_type == "video" && video_url.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "video_url is required for video media"
        }));
    }
    let sort_order = body.sort_order.unwrap_or(existing.sort_order);

    match sqlx::query_as::<_, FestivalMediaItem>(
        "UPDATE festival_media
         SET title = $2,
             image_url = $3,
             video_url = $4,
             media_type = $5,
             sort_order = $6,
             updated_at = NOW()
         WHERE id = $1
         RETURNING
            id,
            festival_id,
            title,
            image_url,
            video_url,
            media_type,
            sort_order,
            created_at,
            updated_at",
    )
    .bind(media_id)
    .bind(title)
    .bind(image_url)
    .bind(video_url)
    .bind(media_type)
    .bind(sort_order)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(ApiResponse { success: true, data }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/festival-media/{media_id}")]
pub async fn admin_delete_festival_media(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    media_id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    match sqlx::query("DELETE FROM festival_media WHERE id = $1")
        .bind(media_id.into_inner())
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Deleted".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Festival media not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Seva Items CRUD
// ──────────────────────────────────────────────

#[derive(serde::Deserialize)]
pub struct AdminSevaItemsQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

#[get("/api/admin/seva/items")]
pub async fn admin_list_seva_items(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminSevaItemsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(50).min(200);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    match sqlx::query_as::<_, SevaItem>(
        "SELECT id, name, description, price, category, available
         FROM seva_items ORDER BY id LIMIT $1 OFFSET $2",
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data,
            "page": page,
            "per_page": per_page
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/seva/items")]
pub async fn admin_create_seva_item(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateSevaItemRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let name = body.name.trim();
    let category = body.category.trim();
    if name.is_empty() || category.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name and category are required"
        }));
    }
    let description = body.description.as_deref().unwrap_or("").trim();
    let available = body.available.unwrap_or(true);

    match sqlx::query_as::<_, SevaItem>(
        "INSERT INTO seva_items (name, description, price, category, available)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, name, description, price, category, available",
    )
    .bind(name)
    .bind(description)
    .bind(body.price)
    .bind(category)
    .bind(available)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/seva/items/{id}")]
pub async fn admin_patch_seva_item(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchSevaItemRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, SevaItem>(
        "SELECT id, name, description, price, category, available FROM seva_items WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Seva item not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
    };

    let new_name = body.name.as_deref().unwrap_or(&existing.name).trim().to_string();
    let new_desc = body.description.as_deref().unwrap_or(&existing.description).trim().to_string();
    let new_price = body.price.unwrap_or(existing.price);
    let new_cat = body.category.as_deref().unwrap_or(&existing.category).trim().to_string();
    let new_avail = body.available.unwrap_or(existing.available);

    match sqlx::query_as::<_, SevaItem>(
        "UPDATE seva_items SET name = $1, description = $2, price = $3, category = $4, available = $5
         WHERE id = $6
         RETURNING id, name, description, price, category, available",
    )
    .bind(&new_name)
    .bind(&new_desc)
    .bind(new_price)
    .bind(&new_cat)
    .bind(new_avail)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/seva/items/{id}")]
pub async fn admin_delete_seva_item(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    match sqlx::query("DELETE FROM seva_items WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Seva item not found"
        })),
        Err(e) => {
            let msg = format!("{}", e);
            if msg.contains("foreign key") || msg.contains("violates") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "success": false,
                    "error": "Cannot delete: seva item has existing bookings"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "success": false,
                    "error": format!("Database error: {}", e)
                }))
            }
        }
    }
}

// ──────────────────────────────────────────────
// Admin Seva Bookings
// ──────────────────────────────────────────────

#[get("/api/admin/seva/bookings")]
pub async fn admin_list_seva_bookings(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminSevaBookingsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let status_filter = q.status.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty());

    let rows = sqlx::query_as::<_, AdminSevaBookingView>(
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
            b.payment_updated_at,
            b.payment_admin_note
         FROM seva_bookings b
         JOIN seva_items s ON s.id = b.seva_item_id
         WHERE ($1::TEXT IS NULL OR b.status = $1)
         ORDER BY b.created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(&status_filter)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/seva/booking/{reference_id}")]
pub async fn admin_patch_seva_booking(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminUpdateSevaBookingStatusRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let reference_id = reference_id.into_inner();
    let status = body.status.trim().to_lowercase();
    if status.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "status is required"
        }));
    }

    let allowed = ["pending", "confirmed", "completed", "cancelled"];
    if !allowed.contains(&status.as_str()) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "Invalid status"
        }));
    }

    let r = sqlx::query(
        "UPDATE seva_bookings SET status = $1 WHERE reference_id = $2",
    )
    .bind(&status)
    .bind(&reference_id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Booking updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Booking not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/seva/bookings/payment/{reference_id}")]
pub async fn admin_patch_seva_booking_payment(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    reference_id: web::Path<String>,
    body: web::Json<AdminPatchPaymentRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let new_status = match admin_parse_patch_payment_status(&body) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let admin_note = match required_admin_payment_note(&body.admin_note) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let gateway_id = optional_payment_trim(&body.gateway_payment_id, 64);
    let reference_id = reference_id.into_inner();

    let r = sqlx::query(
        "UPDATE seva_bookings SET
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
            "error": "Seva booking not found or payment status cannot be changed"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Events CRUD
// ──────────────────────────────────────────────

#[derive(serde::Deserialize)]
pub struct AdminEventsQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

#[get("/api/admin/events")]
pub async fn admin_list_events(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminEventsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let page = q.page.unwrap_or(1).max(1);
    let per_page = q.per_page.unwrap_or(50).min(200);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    match sqlx::query_as::<_, Event>(
        "SELECT id, title, date, description, image_url, is_featured
         FROM events ORDER BY id DESC LIMIT $1 OFFSET $2",
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data,
            "page": page,
            "per_page": per_page
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/events")]
pub async fn admin_create_event(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateEventRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let title = body.title.trim();
    let date = body.date.trim();
    if title.is_empty() || date.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "title and date are required"
        }));
    }
    let description = body.description.as_deref().unwrap_or("").trim();
    let image_url = body.image_url.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let is_featured = body.is_featured.unwrap_or(false);

    match sqlx::query_as::<_, Event>(
        "INSERT INTO events (title, date, description, image_url, is_featured)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, title, date, description, image_url, is_featured",
    )
    .bind(title)
    .bind(date)
    .bind(description)
    .bind(&image_url)
    .bind(is_featured)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/events/{id}")]
pub async fn admin_patch_event(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchEventRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, Event>(
        "SELECT id, title, date, description, image_url, is_featured FROM events WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
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
    };

    let new_title = body.title.as_deref().unwrap_or(&existing.title).trim().to_string();
    let new_date = body.date.as_deref().unwrap_or(&existing.date).trim().to_string();
    let new_desc = body.description.as_deref().unwrap_or(&existing.description).trim().to_string();
    let new_image = if body.image_url.is_some() {
        body.image_url.as_deref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty())
    } else {
        existing.image_url.clone()
    };
    let new_featured = body.is_featured.unwrap_or(existing.is_featured);

    match sqlx::query_as::<_, Event>(
        "UPDATE events SET title = $1, date = $2, description = $3, image_url = $4, is_featured = $5
         WHERE id = $6
         RETURNING id, title, date, description, image_url, is_featured",
    )
    .bind(&new_title)
    .bind(&new_date)
    .bind(&new_desc)
    .bind(&new_image)
    .bind(new_featured)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/events/{id}")]
pub async fn admin_delete_event(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    match sqlx::query("DELETE FROM events WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Event not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Event Participations
// ──────────────────────────────────────────────

#[get("/api/admin/events/participations")]
pub async fn admin_list_event_participations(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminEventParticipationsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let event_id_filter = q.event_id;

    let rows = sqlx::query_as::<_, AdminEventParticipationView>(
        "SELECT
            p.id,
            p.event_id,
            e.title as event_title,
            p.name,
            p.phone,
            p.notes,
            p.created_at
         FROM event_participations p
         JOIN events e ON e.id = p.event_id
         WHERE ($1::INT IS NULL OR p.event_id = $1)
         ORDER BY p.created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(&event_id_filter)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin general donations (follow-up / failed payments)
// ──────────────────────────────────────────────

#[get("/api/admin/donations")]
pub async fn admin_list_donations(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminDonationsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let status_filter = q
        .payment_status
        .as_ref()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    let search_raw = q
        .search
        .as_ref()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    let search_pat = search_raw.as_ref().map(|s| format!("%{}%", s.replace('%', "\\%")));

    let rows = sqlx::query_as::<_, AdminDonationView>(
        "SELECT
            d.id,
            d.name,
            d.amount,
            d.purpose,
            d.phone,
            d.email,
            d.reference_id,
            d.payment_status,
            d.gateway,
            d.gateway_order_id,
            d.gateway_payment_id,
            d.payment_failure_reason,
            d.payment_updated_at,
            d.payment_admin_note,
            d.created_at
         FROM donations d
         WHERE ($1::TEXT IS NULL OR d.payment_status = $1)
         AND ($2::TEXT IS NULL OR (
            d.name ILIKE $2 OR COALESCE(d.email, '') ILIKE $2 OR COALESCE(d.phone, '') ILIKE $2
            OR d.reference_id ILIKE $2 OR d.purpose ILIKE $2
            OR COALESCE(d.payment_failure_reason, '') ILIKE $2
         ))
         ORDER BY d.created_at DESC
         LIMIT $3 OFFSET $4",
    )
    .bind(&status_filter)
    .bind(&search_pat)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Event Donations
// ──────────────────────────────────────────────

#[get("/api/admin/events/donations")]
pub async fn admin_list_event_donations(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminEventDonationsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let event_id_filter = q.event_id;

    let rows = sqlx::query_as::<_, AdminEventDonationView>(
        "SELECT
            d.id,
            d.event_id,
            e.title as event_title,
            d.name,
            d.amount,
            d.phone,
            d.email,
            d.message,
            d.reference_id,
            d.payment_status,
            d.gateway,
            d.gateway_order_id,
            d.gateway_payment_id,
            d.payment_failure_reason,
            d.payment_updated_at,
            d.payment_admin_note,
            d.created_at
         FROM event_donations d
         JOIN events e ON e.id = d.event_id
         WHERE ($1::INT IS NULL OR d.event_id = $1)
         ORDER BY d.created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(&event_id_filter)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/donations/{id}")]
pub async fn admin_patch_donation_payment(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchPaymentRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let new_status = match admin_parse_patch_payment_status(&body) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let admin_note = match required_admin_payment_note(&body.admin_note) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let gateway_id = optional_payment_trim(&body.gateway_payment_id, 64);
    let id = id.into_inner();

    let r = sqlx::query(
        "UPDATE donations SET
            payment_status = $1,
            payment_updated_at = NOW(),
            paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END,
            payment_failure_reason = CASE WHEN $1 IN ('paid','refunded') THEN NULL ELSE payment_failure_reason END,
            gateway_payment_id = CASE WHEN $2 IS NOT NULL THEN $2 ELSE gateway_payment_id END,
            payment_admin_note = $3
         WHERE id = $4
           AND (
             (payment_status IN ('failed','pending') AND $1 IN ('paid','refunded'))
             OR (payment_status = 'paid' AND $1 = 'refunded')
           )",
    )
    .bind(&new_status)
    .bind(&gateway_id)
    .bind(&admin_note)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Payment updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Donation not found or payment status cannot be changed"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/events/donations/{id}")]
pub async fn admin_patch_event_donation_payment(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchPaymentRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let new_status = match admin_parse_patch_payment_status(&body) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let admin_note = match required_admin_payment_note(&body.admin_note) {
        Ok(s) => s,
        Err(msg) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": msg
            }))
        }
    };
    let gateway_id = optional_payment_trim(&body.gateway_payment_id, 64);
    let id = id.into_inner();

    let r = sqlx::query(
        "UPDATE event_donations SET
            payment_status = $1,
            payment_updated_at = NOW(),
            paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END,
            payment_failure_reason = CASE WHEN $1 IN ('paid','refunded') THEN NULL ELSE payment_failure_reason END,
            gateway_payment_id = CASE WHEN $2 IS NOT NULL THEN $2 ELSE gateway_payment_id END,
            payment_admin_note = $3
         WHERE id = $4
           AND (
             (payment_status IN ('failed','pending') AND $1 IN ('paid','refunded'))
             OR (payment_status = 'paid' AND $1 = 'refunded')
           )",
    )
    .bind(&new_status)
    .bind(&gateway_id)
    .bind(&admin_note)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: "Payment updated".to_string(),
        }),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Event donation not found or payment status cannot be changed"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Aarti CRUD
// ──────────────────────────────────────────────

#[get("/api/admin/aarti")]
pub async fn admin_list_aarti(
    pool: web::Data<PgPool>,
    req: HttpRequest,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    match sqlx::query_as::<_, AartiSchedule>(
        "SELECT id, name, time, description, is_special FROM aarti_schedule ORDER BY id",
    )
    .fetch_all(pool.get_ref())
    .await
    {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/aarti")]
pub async fn admin_create_aarti(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminCreateAartiRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let name = body.name.trim();
    let time = body.time.trim();
    if name.is_empty() || time.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "name and time are required"
        }));
    }
    let description = body.description.as_deref().unwrap_or("").trim();
    let is_special = body.is_special.unwrap_or(false);

    match sqlx::query_as::<_, AartiSchedule>(
        "INSERT INTO aarti_schedule (name, time, description, is_special)
         VALUES ($1, $2, $3, $4)
         RETURNING id, name, time, description, is_special",
    )
    .bind(name)
    .bind(time)
    .bind(description)
    .bind(is_special)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/aarti/{id}")]
pub async fn admin_patch_aarti(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchAartiRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let existing = sqlx::query_as::<_, AartiSchedule>(
        "SELECT id, name, time, description, is_special FROM aarti_schedule WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    let existing = match existing {
        Ok(Some(e)) => e,
        Ok(None) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Aarti not found"
            }));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "success": false,
                "error": format!("Database error: {}", e)
            }));
        }
    };

    let new_name = body.name.as_deref().unwrap_or(&existing.name).trim().to_string();
    let new_time = body.time.as_deref().unwrap_or(&existing.time).trim().to_string();
    let new_desc = body.description.as_deref().unwrap_or(&existing.description).trim().to_string();
    let new_special = body.is_special.unwrap_or(existing.is_special);

    match sqlx::query_as::<_, AartiSchedule>(
        "UPDATE aarti_schedule SET name = $1, time = $2, description = $3, is_special = $4
         WHERE id = $5
         RETURNING id, name, time, description, is_special",
    )
    .bind(&new_name)
    .bind(&new_time)
    .bind(&new_desc)
    .bind(new_special)
    .bind(id)
    .fetch_one(pool.get_ref())
    .await
    {
        Ok(row) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": row
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[delete("/api/admin/aarti/{id}")]
pub async fn admin_delete_aarti(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    match sqlx::query("DELETE FROM aarti_schedule WHERE id = $1")
        .bind(id)
        .execute(pool.get_ref())
        .await
    {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Deleted"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Aarti not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Members
// ──────────────────────────────────────────────

#[get("/api/admin/members")]
pub async fn admin_list_members(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminMembersQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let status_filter = q.status.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let search_filter = q.search.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let search_pattern = search_filter.map(|s| format!("%{}%", s));

    let rows = sqlx::query_as::<_, Member>(
        "SELECT id, phone, name, email, status, created_at, updated_at
         FROM members
         WHERE ($1::TEXT IS NULL OR status = $1)
           AND ($2::TEXT IS NULL OR name ILIKE $2 OR phone ILIKE $2)
         ORDER BY created_at DESC
         LIMIT $3 OFFSET $4",
    )
    .bind(&status_filter)
    .bind(&search_pattern)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/members/{id}")]
pub async fn admin_patch_member(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<uuid::Uuid>,
    body: web::Json<AdminPatchMemberRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    let status = body.status.trim().to_lowercase();
    if status != "active" && status != "suspended" {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "status must be 'active' or 'suspended'"
        }));
    }

    let r = sqlx::query(
        "UPDATE members SET status = $1, updated_at = NOW() WHERE id = $2",
    )
    .bind(&status)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Member updated"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Member not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Volunteers
// ──────────────────────────────────────────────

#[get("/api/admin/volunteers")]
pub async fn admin_list_volunteers(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminVolunteersQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let status_filter = q.status.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());

    let rows = sqlx::query_as::<_, AdminVolunteerView>(
        "SELECT id, name, phone, email, area, availability, message, status, created_at
         FROM volunteer_requests
         WHERE ($1::TEXT IS NULL OR status = $1)
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(&status_filter)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/volunteers/{id}")]
pub async fn admin_patch_volunteer(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchVolunteerStatusRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();
    let status = body.status.trim().to_lowercase();
    let allowed = ["new", "contacted", "approved", "rejected"];
    if !allowed.contains(&status.as_str()) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "status must be one of: new, contacted, approved, rejected"
        }));
    }

    let r = sqlx::query("UPDATE volunteer_requests SET status = $1 WHERE id = $2")
        .bind(&status)
        .bind(id)
        .execute(pool.get_ref())
        .await;

    match r {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Volunteer request updated"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Volunteer request not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

// ──────────────────────────────────────────────
// Admin Feedback CRM
// ──────────────────────────────────────────────

#[get("/api/admin/feedback")]
pub async fn admin_list_feedback(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminFeedbackQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let limit = q.limit.unwrap_or(50).min(200).max(1);
    let offset = q.offset.unwrap_or(0).max(0);
    let search = q
        .search
        .as_deref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| format!("%{}%", s));
    let status = q.status.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let priority = q
        .priority
        .as_deref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty());

    let rows = sqlx::query_as::<_, AdminFeedbackView>(
        "SELECT
            f.id, f.name, f.email, f.phone, f.rating, f.message, f.source,
            f.status, f.priority, f.owner_admin_id, a.name as owner_name,
            f.reference_id, f.created_at, f.updated_at,
            COALESCE((
              SELECT COUNT(*) FROM feedback_responses r WHERE r.feedback_id = f.id
            ), 0)::BIGINT as response_count
         FROM feedback_items f
         LEFT JOIN admins a ON a.id = f.owner_admin_id
         WHERE ($1::TEXT IS NULL OR f.status = $1)
           AND ($2::TEXT IS NULL OR f.priority = $2)
           AND ($3::SMALLINT IS NULL OR f.rating = $3)
           AND ($4::UUID IS NULL OR f.owner_admin_id = $4)
           AND ($5::TEXT IS NULL OR f.name ILIKE $5 OR COALESCE(f.email,'') ILIKE $5 OR COALESCE(f.phone,'') ILIKE $5 OR f.message ILIKE $5 OR f.reference_id ILIKE $5)
         ORDER BY f.created_at DESC
         LIMIT $6 OFFSET $7",
    )
    .bind(status)
    .bind(priority)
    .bind(q.rating)
    .bind(q.owner_admin_id)
    .bind(search)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": data })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/admin/feedback/{id}")]
pub async fn admin_get_feedback_detail(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let row = sqlx::query_as::<_, AdminFeedbackDetailView>(
        "SELECT
            f.id, f.name, f.email, f.phone, f.rating, f.message, f.source,
            f.status, f.priority, f.owner_admin_id, a.name as owner_name,
            f.reference_id, f.created_at, f.updated_at
         FROM feedback_items f
         LEFT JOIN admins a ON a.id = f.owner_admin_id
         WHERE f.id = $1
         LIMIT 1",
    )
    .bind(id)
    .fetch_optional(pool.get_ref())
    .await;

    match row {
        Ok(Some(data)) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": data })),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({ "success": false, "error": "Feedback not found" })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/feedback/{id}")]
pub async fn admin_patch_feedback(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminPatchFeedbackRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    if let Some(s) = &body.status {
        let allowed = ["new", "triaged", "in_progress", "resolved", "closed"];
        if !allowed.contains(&s.trim()) {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "invalid status"
            }));
        }
    }
    if let Some(p) = &body.priority {
        let allowed = ["low", "medium", "high", "critical"];
        if !allowed.contains(&p.trim()) {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "invalid priority"
            }));
        }
    }

    let result = sqlx::query(
        "UPDATE feedback_items
         SET status = COALESCE(NULLIF($1,''), status),
             priority = COALESCE(NULLIF($2,''), priority),
             owner_admin_id = COALESCE($3, owner_admin_id),
             updated_at = NOW()
         WHERE id = $4",
    )
    .bind(body.status.as_deref().map(|s| s.trim()))
    .bind(body.priority.as_deref().map(|s| s.trim()))
    .bind(body.owner_admin_id)
    .bind(id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(r) if r.rows_affected() > 0 => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Feedback updated"
        })),
        Ok(_) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Feedback not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[get("/api/admin/feedback/{id}/responses")]
pub async fn admin_list_feedback_responses(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }
    let id = id.into_inner();

    let rows = sqlx::query_as::<_, AdminFeedbackThreadItem>(
        "SELECT
            r.id, r.feedback_id, r.author_type, r.author_admin_id,
            a.name as author_name, r.message, r.is_public, r.created_at
         FROM feedback_responses r
         LEFT JOIN admins a ON a.id = r.author_admin_id
         WHERE r.feedback_id = $1
         ORDER BY r.created_at ASC",
    )
    .bind(id)
    .fetch_all(pool.get_ref())
    .await;

    match rows {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": data })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[post("/api/admin/feedback/{id}/responses")]
pub async fn admin_add_feedback_response(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    id: web::Path<i32>,
    body: web::Json<AdminAddFeedbackResponseRequest>,
) -> HttpResponse {
    let admin = match require_admin(pool.get_ref(), &req).await {
        Ok(a) => a,
        Err(resp) => return resp,
    };
    let id = id.into_inner();
    let message = body.message.trim();
    if message.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "message is required"
        }));
    }

    let exists = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM feedback_items WHERE id = $1")
        .bind(id)
        .fetch_one(pool.get_ref())
        .await;
    match exists {
        Ok(0) => {
            return HttpResponse::NotFound().json(serde_json::json!({
                "success": false,
                "error": "Feedback not found"
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
        "INSERT INTO feedback_responses (feedback_id, author_type, author_admin_id, message, is_public)
         VALUES ($1, 'admin', $2, $3, $4)",
    )
    .bind(id)
    .bind(admin.id)
    .bind(message)
    .bind(body.is_public.unwrap_or(false))
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "message": "Response added"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Failed to save response: {}", e)
        })),
    }
}

#[get("/api/admin/feedback/analytics")]
pub async fn admin_feedback_analytics(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    q: web::Query<AdminFeedbackAnalyticsQuery>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let from_date = q.from_date.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());
    let to_date = q.to_date.as_deref().map(|s| s.trim()).filter(|s| !s.is_empty());

    let agg_row = sqlx::query_as::<_, (i64, i64, i64, i64, Option<f64>, i64, i64, i64, i64, i64)>(
        "SELECT
            COUNT(*)::BIGINT as total,
            COUNT(*) FILTER (WHERE status = 'new')::BIGINT as new_count,
            COUNT(*) FILTER (WHERE status = 'in_progress')::BIGINT as in_progress_count,
            COUNT(*) FILTER (WHERE status = 'resolved')::BIGINT as resolved_count,
            AVG(rating)::FLOAT8 as avg_rating,
            COUNT(*) FILTER (WHERE rating = 1)::BIGINT as rating_1,
            COUNT(*) FILTER (WHERE rating = 2)::BIGINT as rating_2,
            COUNT(*) FILTER (WHERE rating = 3)::BIGINT as rating_3,
            COUNT(*) FILTER (WHERE rating = 4)::BIGINT as rating_4,
            COUNT(*) FILTER (WHERE rating = 5)::BIGINT as rating_5
         FROM feedback_items
         WHERE ($1::DATE IS NULL OR created_at::date >= $1::date)
           AND ($2::DATE IS NULL OR created_at::date <= $2::date)",
    )
    .bind(from_date)
    .bind(to_date)
    .fetch_one(pool.get_ref())
    .await;

    let trend_rows = sqlx::query_as::<_, AdminFeedbackDailyBucket>(
        "SELECT
            to_char(created_at::date, 'YYYY-MM-DD') as day,
            COUNT(*)::BIGINT as count
         FROM feedback_items
         WHERE ($1::DATE IS NULL OR created_at::date >= $1::date)
           AND ($2::DATE IS NULL OR created_at::date <= $2::date)
         GROUP BY created_at::date
         ORDER BY created_at::date ASC",
    )
    .bind(from_date)
    .bind(to_date)
    .fetch_all(pool.get_ref())
    .await;

    match (agg_row, trend_rows) {
        (Ok(a), Ok(trend)) => {
            let data = AdminFeedbackAnalytics {
                total: a.0,
                new_count: a.1,
                in_progress_count: a.2,
                resolved_count: a.3,
                avg_rating: a.4.unwrap_or(0.0),
                rating_1: a.5,
                rating_2: a.6,
                rating_3: a.7,
                rating_4: a.8,
                rating_5: a.9,
                trend,
            };
            HttpResponse::Ok().json(serde_json::json!({ "success": true, "data": data }))
        }
        (Err(e), _) | (_, Err(e)) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

fn validate_landing_audio_url(raw: &str) -> Result<(), &'static str> {
    let t = raw.trim();
    if t.is_empty() {
        return Ok(());
    }
    let u = match url::Url::parse(t) {
        Ok(u) => u,
        Err(_) => return Err("invalid URL"),
    };
    if u.scheme() != "https" {
        return Err("only https URLs are allowed");
    }
    Ok(())
}

const MAX_LIVE_STREAM_URL_CHARS: usize = 2048;

fn validate_live_stream_url(raw: &str) -> Result<(), &'static str> {
    let t = raw.trim();
    if t.is_empty() {
        return Ok(());
    }
    if t.chars().count() > MAX_LIVE_STREAM_URL_CHARS {
        return Err("stream_url is too long (max 2048 characters)");
    }
    let u = match url::Url::parse(t) {
        Ok(u) => u,
        Err(_) => return Err("invalid stream_url"),
    };
    match u.scheme() {
        "https" => Ok(()),
        "http" => Err("stream_url must use https"),
        _ => Err("stream_url must be an https URL"),
    }
}

#[get("/api/admin/daily-quote")]
pub async fn admin_get_daily_quote(pool: web::Data<PgPool>, req: HttpRequest) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    match sqlx::query_as::<_, DailyQuote>(
        "SELECT id, shlok, translation, source
         FROM daily_quotes
         ORDER BY id DESC
         LIMIT 1",
    )
    .fetch_optional(pool.get_ref())
    .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "No quote found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/daily-quote")]
pub async fn admin_patch_daily_quote(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPatchDailyQuoteRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let shlok = body.shlok.trim();
    let translation = body.translation.trim();
    let source = body.source.trim();

    if shlok.is_empty() || translation.is_empty() || source.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": "shlok, translation and source are required"
        }));
    }

    let updated = sqlx::query_as::<_, DailyQuote>(
        "WITH latest AS (
            SELECT id FROM daily_quotes ORDER BY id DESC LIMIT 1
         )
         UPDATE daily_quotes
         SET shlok = $1, translation = $2, source = $3
         WHERE id = (SELECT id FROM latest)
         RETURNING id, shlok, translation, source",
    )
    .bind(shlok)
    .bind(translation)
    .bind(source)
    .fetch_optional(pool.get_ref())
    .await;

    let result = match updated {
        Ok(Some(row)) => Ok(row),
        Ok(None) => sqlx::query_as::<_, DailyQuote>(
            "INSERT INTO daily_quotes (shlok, translation, source)
             VALUES ($1, $2, $3)
             RETURNING id, shlok, translation, source",
        )
        .bind(shlok)
        .bind(translation)
        .bind(source)
        .fetch_one(pool.get_ref())
        .await,
        Err(e) => Err(e),
    };

    match result {
        Ok(data) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

const MAX_TEMPLE_ABOUT_CHARS: usize = 50_000;

#[patch("/api/admin/temple-about")]
pub async fn admin_patch_temple_about(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPatchTempleAboutRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let content = body.about_content.trim();
    if content.chars().count() > MAX_TEMPLE_ABOUT_CHARS {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": format!("about_content must be at most {} characters", MAX_TEMPLE_ABOUT_CHARS)
        }));
    }
    let content = content.to_string();

    match sqlx::query_as::<_, TempleInfo>(
        "UPDATE temple_info
         SET about_content = $1
         WHERE id = (SELECT id FROM temple_info ORDER BY id ASC LIMIT 1)
         RETURNING id, name, address, city, phone, email, website, opening_time, closing_time, latitude, longitude, maps_url, about_content",
    )
    .bind(&content)
    .fetch_optional(pool.get_ref())
    .await
    {
        Ok(Some(data)) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": data
        })),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "success": false,
            "error": "Temple info row not found"
        })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}

#[patch("/api/admin/site/landing-audio")]
pub async fn admin_patch_landing_audio(
    pool: web::Data<PgPool>,
    req: HttpRequest,
    body: web::Json<AdminPatchLandingAudioRequest>,
) -> HttpResponse {
    if let Err(resp) = require_admin(pool.get_ref(), &req).await {
        return resp;
    }

    let url = body.audio_url.trim().to_string();
    if let Err(msg) = validate_landing_audio_url(&url) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "success": false,
            "error": msg
        }));
    }

    let res = sqlx::query(
        "INSERT INTO site_kv (key, value, updated_at) VALUES ('landing_audio_url', $1, NOW())
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()",
    )
    .bind(&url)
    .execute(pool.get_ref())
    .await;

    match res {
        Ok(_) => HttpResponse::Ok().json(SimpleActionResponse {
            success: true,
            message: if url.is_empty() {
                "Landing audio disabled".to_string()
            } else {
                "Landing audio updated".to_string()
            },
        }),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({
            "success": false,
            "error": format!("Database error: {}", e)
        })),
    }
}
