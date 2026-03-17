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

#[derive(Debug, Deserialize)]
pub struct EventParticipationRequest {
    pub name: String,
    pub phone: String,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct EventParticipationResponse {
    pub success: bool,
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct EventComment {
    pub id: i32,
    pub event_id: i32,
    pub name: String,
    pub comment: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct GalleryComment {
    pub id: i32,
    pub gallery_id: i32,
    pub name: String,
    pub comment: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct NewCommentRequest {
    pub name: String,
    pub comment: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct LikeCount {
    pub count: i64,
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

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct HinduPanchang {
    pub id: i32,
    pub for_date: String,
    pub content: String,
    pub created_at: DateTime<Utc>,
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

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct PrasadOrderView {
    pub id: i32,
    pub reference_id: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub fulfillment: String,
    pub quantity: i32,
    pub total_amount: f64,
    pub name: String,
    pub phone: String,
    pub address: Option<String>,
    pub notes: Option<String>,
    pub prasad_item_id: i32,
    pub prasad_name: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdatePrasadOrderRequest {
    pub quantity: Option<i32>,
    pub fulfillment: Option<String>, // pickup | delivery
    pub address: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct SimpleActionResponse {
    pub success: bool,
    pub message: String,
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

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct SevaBookingView {
    pub id: i32,
    pub reference_id: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub name: String,
    pub phone: String,
    pub preferred_date: Option<String>,
    pub notes: Option<String>,
    pub seva_item_id: i32,
    pub seva_name: String,
    pub seva_category: String,
    pub seva_price: f64,
}

#[derive(Debug, Deserialize)]
pub struct UpdateSevaBookingRequest {
    pub preferred_date: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: T,
}
