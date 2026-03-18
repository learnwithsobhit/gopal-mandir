mod models;
mod routes;

use actix_cors::Cors;
use actix_web::{App, HttpServer, web};
use sqlx::postgres::PgPoolOptions;
use std::env;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file for local development
    dotenv::dotenv().ok();

    // Railway sets PORT env var; default to 8080 for local dev
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_addr = format!("0.0.0.0:{}", port);

    // Database connection
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set (in .env or Railway environment)");

    println!("🙏 Jai Gopal! Gopal Mandir API starting...");
    println!("🛕 Connecting to PostgreSQL...");

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to connect to PostgreSQL");

    println!("✅ Connected to PostgreSQL");

    // Run migrations
    println!("📦 Running migrations...");
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");
    println!("✅ Migrations complete");

    println!("🛕 Server running at http://{}", bind_addr);

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            .app_data(web::Data::new(pool.clone()))
            .service(routes::get_aarti)
            .service(routes::get_events)
            .service(routes::join_event)
            .service(routes::like_event)
            .service(routes::get_event_likes_count)
            .service(routes::get_event_comments)
            .service(routes::add_event_comment)
            .service(routes::membership_request_otp)
            .service(routes::membership_verify_otp)
            .service(routes::membership_me)
            .service(routes::membership_logout)
            .service(routes::submit_volunteer_request)
            .service(routes::get_gallery)
            .service(routes::get_gallery_image_proxy)
            .service(routes::like_gallery)
            .service(routes::get_gallery_likes_count)
            .service(routes::get_gallery_comments)
            .service(routes::add_gallery_comment)
            .service(routes::get_prasad)
            .service(routes::get_seva)
            .service(routes::get_announcements)
            .service(routes::get_daily_quote)
            .service(routes::get_temple_info)
            .service(routes::submit_donation)
            .service(routes::get_live_darshan)
            .service(routes::get_panchang)
            .service(routes::create_prasad_order)
            .service(routes::create_seva_booking)
            .service(routes::list_prasad_orders)
            .service(routes::update_prasad_order)
            .service(routes::cancel_prasad_order)
            .service(routes::list_seva_bookings)
            .service(routes::update_seva_booking)
            .service(routes::cancel_seva_booking)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
