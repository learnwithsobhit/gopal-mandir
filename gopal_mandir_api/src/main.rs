mod models;
mod routes;
mod seed_data;

use actix_cors::Cors;
use actix_web::{App, HttpServer};
use std::env;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Railway sets PORT env var; default to 8080 for local dev
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_addr = format!("0.0.0.0:{}", port);

    println!("🙏 Jai Gopal! Gopal Mandir API starting...");
    println!("🛕 Server running at http://{}", bind_addr);

    HttpServer::new(|| {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            .service(routes::get_aarti)
            .service(routes::get_events)
            .service(routes::get_gallery)
            .service(routes::get_prasad)
            .service(routes::get_seva)
            .service(routes::get_announcements)
            .service(routes::get_daily_quote)
            .service(routes::get_temple_info)
            .service(routes::submit_donation)
    })
    .bind(&bind_addr)?
    .run()
    .await
}

