use actix_web::{get, post, web, HttpResponse};
use crate::models::*;
use crate::seed_data;

#[get("/api/aarti")]
pub async fn get_aarti() -> HttpResponse {
    let data = seed_data::get_aarti_schedule();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/events")]
pub async fn get_events() -> HttpResponse {
    let data = seed_data::get_events();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/gallery")]
pub async fn get_gallery() -> HttpResponse {
    let data = seed_data::get_gallery();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/prasad")]
pub async fn get_prasad() -> HttpResponse {
    let data = seed_data::get_prasad_items();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/seva")]
pub async fn get_seva() -> HttpResponse {
    let data = seed_data::get_seva_items();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/announcements")]
pub async fn get_announcements() -> HttpResponse {
    let data = seed_data::get_announcements();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/daily-quote")]
pub async fn get_daily_quote() -> HttpResponse {
    let data = seed_data::get_daily_quote();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[get("/api/temple-info")]
pub async fn get_temple_info() -> HttpResponse {
    let data = seed_data::get_temple_info();
    HttpResponse::Ok().json(ApiResponse {
        success: true,
        data,
    })
}

#[post("/api/donation")]
pub async fn submit_donation(body: web::Json<DonationRequest>) -> HttpResponse {
    // In a real app, this would save to a database and integrate with a payment gateway
    let reference_id = format!("GOPAl-{}", chrono::Utc::now().timestamp());
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
