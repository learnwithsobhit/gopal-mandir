use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AartiSchedule {
    pub id: i32,
    pub name: String,
    pub time: String,
    pub description: String,
    pub is_special: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct Event {
    pub id: i32,
    pub title: String,
    pub date: String,
    pub description: String,
    pub image_url: Option<String>,
    pub is_featured: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct GalleryItem {
    pub id: i32,
    pub title: String,
    pub image_url: String,
    pub category: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct PrasadItem {
    pub id: i32,
    pub name: String,
    pub description: String,
    pub price: f64,
    pub image_url: Option<String>,
    pub available: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct SevaItem {
    pub id: i32,
    pub name: String,
    pub description: String,
    pub price: f64,
    pub category: String,
    pub available: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct Announcement {
    pub id: i32,
    pub title: String,
    pub message: String,
    pub date: String,
    pub is_urgent: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct DailyQuote {
    pub id: i32,
    pub shlok: String,
    pub translation: String,
    pub source: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct TempleInfo {
    pub id: i32,
    pub name: String,
    pub address: String,
    pub city: String,
    pub phone: String,
    pub email: String,
    pub website: String,
    pub opening_time: String,
    pub closing_time: String,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Deserialize)]
pub struct DonationRequest {
    pub name: String,
    pub amount: f64,
    pub purpose: String,
    pub phone: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct DonationResponse {
    pub success: bool,
    pub message: String,
    pub reference_id: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct LiveDarshanInfo {
    pub id: i32,
    pub title: String,
    pub stream_url: String,
    pub is_live: bool,
    pub description: String,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct PrasadOrderRequest {
    pub prasad_item_id: i32,
    pub quantity: i32,
    pub fulfillment: String, // pickup | delivery
    pub name: String,
    pub phone: String,
    pub address: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct PrasadOrder {
    pub id: i32,
    pub prasad_item_id: i32,
    pub quantity: i32,
    pub fulfillment: String,
    pub name: String,
    pub phone: String,
    pub address: Option<String>,
    pub notes: Option<String>,
    pub total_amount: f64,
    pub status: String,
    pub reference_id: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct PrasadOrderResponse {
    pub success: bool,
    pub message: String,
    pub reference_id: String,
}

#[derive(Debug, Deserialize)]
pub struct SevaBookingRequest {
    pub seva_item_id: i32,
    pub name: String,
    pub phone: String,
    pub preferred_date: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct SevaBookingResponse {
    pub success: bool,
    pub message: String,
    pub reference_id: String,
}

#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: T,
}
