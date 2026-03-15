use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AartiSchedule {
    pub id: u32,
    pub name: String,
    pub time: String,
    pub description: String,
    pub is_special: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Event {
    pub id: u32,
    pub title: String,
    pub date: String,
    pub description: String,
    pub image_url: Option<String>,
    pub is_featured: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GalleryItem {
    pub id: u32,
    pub title: String,
    pub image_url: String,
    pub category: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PrasadItem {
    pub id: u32,
    pub name: String,
    pub description: String,
    pub price: f64,
    pub image_url: Option<String>,
    pub available: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SevaItem {
    pub id: u32,
    pub name: String,
    pub description: String,
    pub price: f64,
    pub category: String,
    pub available: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Announcement {
    pub id: u32,
    pub title: String,
    pub message: String,
    pub date: String,
    pub is_urgent: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DailyQuote {
    pub shlok: String,
    pub translation: String,
    pub source: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TempleInfo {
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

#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: T,
}
