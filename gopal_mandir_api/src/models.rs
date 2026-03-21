use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::{DateTime, Utc};
use uuid::Uuid;

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
    pub video_url: String,
    pub media_type: String,
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
    pub maps_url: Option<String>,
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
    /// Must match the order's phone (normalized) — prevents arbitrary reference_id updates.
    pub phone: String,
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

// ──────────────────────────────────────────────
// Membership (free) + phone OTP + sessions
// ──────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct Member {
    pub id: Uuid,
    pub phone: String,
    pub name: String,
    pub email: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct MembershipRequestOtpRequest {
    pub phone: String,
}

#[derive(Debug, Serialize)]
pub struct MembershipRequestOtpResponse {
    pub success: bool,
    pub otp: String,
    pub expires_in_sec: i64,
}

#[derive(Debug, Deserialize)]
pub struct MembershipVerifyOtpRequest {
    pub phone: String,
    pub otp: String,
    pub name: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct MembershipVerifyOtpResponse {
    pub success: bool,
    pub token: String,
    pub member: Member,
}

#[derive(Debug, Serialize)]
pub struct MembershipMeResponse {
    pub success: bool,
    pub member: Member,
}

#[derive(Debug, Serialize)]
pub struct MembershipLogoutResponse {
    pub success: bool,
}

// ──────────────────────────────────────────────
// Admin (CRM) auth
// ──────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct Admin {
    pub id: Uuid,
    pub phone: String,
    pub name: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct AdminRequestOtpRequest {
    pub phone: String,
}

#[derive(Debug, Serialize)]
pub struct AdminRequestOtpResponse {
    pub success: bool,
    pub otp: String,
    pub expires_in_sec: i64,
}

#[derive(Debug, Deserialize)]
pub struct AdminVerifyOtpRequest {
    pub phone: String,
    pub otp: String,
    pub name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AdminVerifyOtpResponse {
    pub success: bool,
    pub token: String,
    pub admin: Admin,
}

#[derive(Debug, Serialize)]
pub struct AdminMeResponse {
    pub success: bool,
    pub admin: Admin,
}

#[derive(Debug, Serialize)]
pub struct AdminLogoutResponse {
    pub success: bool,
}

#[derive(Debug, Deserialize)]
pub struct AdminPresignRequest {
    pub content_type: String,
    pub file_ext: String,
    /// Optional logical prefix under the bucket, e.g. "gallery" -> gallery/{uuid}.ext
    pub object_key_prefix: Option<String>,
    /// Declared file size in bytes (optional); used for validation only.
    pub size_bytes: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct AdminPresignResponse {
    pub success: bool,
    pub upload_url: String,
    pub public_url: String,
    pub key: String,
    pub expires_in_sec: i64,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreateGalleryRequest {
    pub title: String,
    pub category: String,
    pub image_url: String,
    pub video_url: Option<String>,
    pub media_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchGalleryRequest {
    pub title: Option<String>,
    pub category: Option<String>,
    pub image_url: Option<String>,
    pub video_url: Option<String>,
    pub media_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchLiveDarshanRequest {
    pub title: Option<String>,
    pub stream_url: Option<String>,
    pub is_live: Option<bool>,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminUpdatePrasadStatusRequest {
    pub status: String,
}

// ──────────────────────────────────────────────
// Admin Panchang CRUD
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminCreatePanchangRequest {
    pub for_date: String,
    pub content: String,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchPanchangRequest {
    pub for_date: Option<String>,
    pub content: Option<String>,
}

// ──────────────────────────────────────────────
// Event Donations (public + admin)
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct EventDonationRequest {
    pub name: String,
    pub amount: f64,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub message: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct EventDonationResponse {
    pub success: bool,
    pub message: String,
    pub reference_id: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminEventDonationView {
    pub id: i32,
    pub event_id: i32,
    pub event_title: String,
    pub name: String,
    pub amount: f64,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub message: Option<String>,
    pub reference_id: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct AdminEventDonationsQuery {
    pub event_id: Option<i32>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

// ──────────────────────────────────────────────
// Admin Events CRUD
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminCreateEventRequest {
    pub title: String,
    pub date: String,
    pub description: Option<String>,
    pub image_url: Option<String>,
    pub is_featured: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchEventRequest {
    pub title: Option<String>,
    pub date: Option<String>,
    pub description: Option<String>,
    pub image_url: Option<String>,
    pub is_featured: Option<bool>,
}

// ──────────────────────────────────────────────
// Admin Event Participations
// ──────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminEventParticipationView {
    pub id: i32,
    pub event_id: i32,
    pub event_title: String,
    pub name: String,
    pub phone: String,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct AdminEventParticipationsQuery {
    pub event_id: Option<i32>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

// ──────────────────────────────────────────────
// Admin Seva Items CRUD
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminCreateSevaItemRequest {
    pub name: String,
    pub description: Option<String>,
    pub price: f64,
    pub category: String,
    pub available: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchSevaItemRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub price: Option<f64>,
    pub category: Option<String>,
    pub available: Option<bool>,
}

// ──────────────────────────────────────────────
// Admin Seva Bookings
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminSevaBookingsQuery {
    pub status: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct AdminUpdateSevaBookingStatusRequest {
    pub status: String,
}

// ──────────────────────────────────────────────
// Admin Aarti CRUD
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminCreateAartiRequest {
    pub name: String,
    pub time: String,
    pub description: Option<String>,
    pub is_special: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchAartiRequest {
    pub name: Option<String>,
    pub time: Option<String>,
    pub description: Option<String>,
    pub is_special: Option<bool>,
}

// ──────────────────────────────────────────────
// Admin Members
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AdminMembersQuery {
    pub status: Option<String>,
    pub search: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchMemberRequest {
    pub status: String,
}

// ──────────────────────────────────────────────
// Admin Volunteers
// ──────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminVolunteerView {
    pub id: i32,
    pub name: String,
    pub phone: String,
    pub email: Option<String>,
    pub area: String,
    pub availability: String,
    pub message: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct AdminVolunteersQuery {
    pub status: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchVolunteerStatusRequest {
    pub status: String,
}

// ──────────────────────────────────────────────
// Volunteer requests
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct VolunteerRequest {
    pub name: String,
    pub phone: String,
    pub email: Option<String>,
    pub area: Option<String>,
    pub availability: Option<String>,
    pub message: Option<String>,
}
