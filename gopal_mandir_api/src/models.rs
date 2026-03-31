use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::{DateTime, NaiveDate, NaiveTime, Utc};
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
pub struct DailyUpasanaItem {
    pub id: i32,
    pub title: String,
    pub category: String,
    pub content: String,
    pub sort_order: i32,
    pub is_published: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
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

#[derive(Debug, Serialize)]
pub struct DonationCheckoutResponse {
    pub success: bool,
    pub key_id: String,
    pub order_id: String,
    pub amount: i64,
    pub currency: String,
    pub reference_id: String,
}

#[derive(Debug, Deserialize)]
pub struct RazorpayVerifyRequest {
    pub order_id: String,
    pub payment_id: String,
    pub signature: String,
}

/// App-reported checkout failure (gateway error). Secured by matching order_id + reference_id to a pending row.
#[derive(Debug, Deserialize)]
pub struct RazorpayClientFailedRequest {
    pub order_id: String,
    pub reference_id: String,
    pub reason: Option<String>,
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

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct FestivalEntry {
    pub id: i32,
    pub for_date: String,
    pub title: String,
    pub description: String,
    pub icon_url: Option<String>,
    pub banner_url: Option<String>,
    pub sort_order: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct FestivalMonthBucket {
    pub year: i32,
    pub month: i32,
    pub month_label: String,
    pub item_count: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct FestivalMediaItem {
    pub id: i32,
    pub festival_id: i32,
    pub title: String,
    pub image_url: String,
    pub video_url: String,
    pub media_type: String,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct FestivalMediaComment {
    pub id: i32,
    pub media_id: i32,
    pub name: String,
    pub comment: String,
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
    /// `temple` = pay when collecting (pickup only). `online` is rejected here — use `/api/prasad/order/checkout`.
    #[serde(default)]
    pub payment_method: Option<String>,
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
    pub subtotal: f64,
    pub delivery_fee: f64,
    pub payment_method: String,
    pub payment_status: Option<String>,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub amount_paise: Option<i32>,
    pub paid_at: Option<DateTime<Utc>>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
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
    pub subtotal: f64,
    pub delivery_fee: f64,
    pub payment_method: String,
    pub payment_status: Option<String>,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
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
    pub payment_status: String,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
}

/// Admin seva bookings list (includes internal payment note; not exposed on public APIs).
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminSevaBookingView {
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
    pub payment_status: String,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
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
pub struct PhoneQuery {
    pub phone: String,
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

#[derive(Debug, Deserialize)]
pub struct AdminDailyUpasanaQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
    pub title: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreateDailyUpasanaRequest {
    pub title: String,
    pub category: Option<String>,
    pub content: String,
    pub sort_order: Option<i32>,
    pub is_published: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchDailyUpasanaRequest {
    pub title: Option<String>,
    pub category: Option<String>,
    pub content: Option<String>,
    pub sort_order: Option<i32>,
    pub is_published: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreateFestivalRequest {
    pub for_date: String,
    pub title: String,
    pub description: String,
    pub icon_url: Option<String>,
    pub banner_url: Option<String>,
    pub sort_order: Option<i32>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchFestivalRequest {
    pub for_date: Option<String>,
    pub title: Option<String>,
    pub description: Option<String>,
    pub icon_url: Option<String>,
    pub banner_url: Option<String>,
    pub sort_order: Option<i32>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminListFestivalQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
    pub from_date: Option<String>,
    pub to_date: Option<String>,
    pub q: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct FestivalListQuery {
    pub year: Option<i32>,
    pub month: Option<u32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreateFestivalMediaRequest {
    pub title: String,
    pub image_url: Option<String>,
    pub video_url: Option<String>,
    pub media_type: Option<String>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchFestivalMediaRequest {
    pub title: Option<String>,
    pub image_url: Option<String>,
    pub video_url: Option<String>,
    pub media_type: Option<String>,
    pub sort_order: Option<i32>,
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
    pub payment_status: String,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminDonationView {
    pub id: i32,
    pub name: String,
    pub amount: f64,
    pub purpose: String,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub reference_id: String,
    pub payment_status: String,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Admin-only: set payment to paid/refunded after offline donor follow-up.
#[derive(Debug, Deserialize)]
pub struct AdminPatchPaymentRequest {
    pub payment_status: String,
    pub gateway_payment_id: Option<String>,
    pub admin_note: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminDonationsQuery {
    pub payment_status: Option<String>,
    pub search: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
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
// Feedback (Rate Us)
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct FeedbackRequest {
    pub name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub rating: i32,
    pub message: String,
    pub source: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct FeedbackResponse {
    pub success: bool,
    pub message: String,
    pub reference_id: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminFeedbackView {
    pub id: i32,
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub rating: i16,
    pub message: String,
    pub source: String,
    pub status: String,
    pub priority: String,
    pub owner_admin_id: Option<Uuid>,
    pub owner_name: Option<String>,
    pub reference_id: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub response_count: i64,
}

#[derive(Debug, Deserialize)]
pub struct AdminFeedbackQuery {
    pub status: Option<String>,
    pub priority: Option<String>,
    pub rating: Option<i16>,
    pub search: Option<String>,
    pub owner_admin_id: Option<Uuid>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminFeedbackDetailView {
    pub id: i32,
    pub name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub rating: i16,
    pub message: String,
    pub source: String,
    pub status: String,
    pub priority: String,
    pub owner_admin_id: Option<Uuid>,
    pub owner_name: Option<String>,
    pub reference_id: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminFeedbackThreadItem {
    pub id: i32,
    pub feedback_id: i32,
    pub author_type: String,
    pub author_admin_id: Option<Uuid>,
    pub author_name: Option<String>,
    pub message: String,
    pub is_public: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchFeedbackRequest {
    pub status: Option<String>,
    pub priority: Option<String>,
    pub owner_admin_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct AdminAddFeedbackResponseRequest {
    pub message: String,
    pub is_public: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AdminFeedbackAnalyticsQuery {
    pub from_date: Option<String>,
    pub to_date: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminFeedbackDailyBucket {
    pub day: String,
    pub count: i64,
}

#[derive(Debug, Serialize)]
pub struct AdminFeedbackAnalytics {
    pub total: i64,
    pub new_count: i64,
    pub in_progress_count: i64,
    pub resolved_count: i64,
    pub avg_rating: f64,
    pub rating_1: i64,
    pub rating_2: i64,
    pub rating_3: i64,
    pub rating_4: i64,
    pub rating_5: i64,
    pub trend: Vec<AdminFeedbackDailyBucket>,
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

// ──────────────────────────────────────────────
// Pooja / Guru-Baba appointments
// ──────────────────────────────────────────────

#[derive(Debug, Serialize, Clone, FromRow)]
pub struct PoojaSlotDefinition {
    pub id: i32,
    pub label: String,
    pub start_time: NaiveTime,
    pub end_time: NaiveTime,
    pub sort_order: i32,
}

#[derive(Debug, Serialize, Clone, FromRow)]
pub struct PoojaOfferingPackageRow {
    pub id: i32,
    pub offering_id: i32,
    pub name: String,
    pub description: String,
    pub additional_price_paise: i32,
    pub sort_order: i32,
}

#[derive(Debug, Serialize)]
pub struct PoojaOfferingWithPackages {
    pub id: i32,
    pub name: String,
    pub description: String,
    pub base_price_paise: i32,
    pub slots_consumed: i32,
    pub sort_order: i32,
    pub packages: Vec<PoojaOfferingPackageRow>,
}

#[derive(Debug, Deserialize)]
pub struct PoojaBookingCreateRequest {
    pub offering_id: i32,
    pub package_id: Option<i32>,
    pub officiant: String,
    pub booking_date: String,
    pub slot_id: i32,
    pub venue: String,
    pub address: Option<String>,
    pub name: String,
    pub phone: String,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct PoojaCheckoutRequest {
    pub reference_id: String,
}

#[derive(Debug, Deserialize)]
pub struct PoojaRescheduleRequest {
    pub booking_date: String,
    pub slot_id: i32,
}

#[derive(Debug, Serialize, Clone, FromRow)]
pub struct PoojaBookingView {
    pub id: i32,
    pub reference_id: String,
    pub booking_status: String,
    pub payment_expected: Option<String>,
    pub payment_status: String,
    pub created_at: DateTime<Utc>,
    pub booking_date: NaiveDate,
    pub scheduled_at: DateTime<Utc>,
    pub officiant: String,
    pub slot_id: i32,
    pub slot_label: String,
    pub venue: String,
    pub address: Option<String>,
    pub name: String,
    pub phone: String,
    pub notes: Option<String>,
    pub offering_id: i32,
    pub offering_name: String,
    pub package_id: Option<i32>,
    pub package_name: Option<String>, // NULL when no package
    pub amount_paise: Option<i32>,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AdminPoojaBookingView {
    pub id: i32,
    pub reference_id: String,
    pub booking_status: String,
    pub payment_expected: Option<String>,
    pub payment_status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub booking_date: NaiveDate,
    pub scheduled_at: DateTime<Utc>,
    pub officiant: String,
    pub slot_id: i32,
    pub slot_label: String,
    pub venue: String,
    pub address: Option<String>,
    pub name: String,
    pub phone: String,
    pub notes: Option<String>,
    pub offering_id: i32,
    pub offering_name: String,
    pub package_id: Option<i32>,
    pub package_name: Option<String>, // NULL when no package
    pub amount_paise: Option<i32>,
    pub gateway: Option<String>,
    pub gateway_order_id: Option<String>,
    pub gateway_payment_id: Option<String>,
    pub payment_failure_reason: Option<String>,
    pub payment_updated_at: Option<DateTime<Utc>>,
    pub payment_admin_note: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPoojaBookingsQuery {
    pub booking_status: Option<String>,
    pub officiant: Option<String>,
    pub from_date: Option<String>,
    pub to_date: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchPoojaBookingRequest {
    pub booking_status: Option<String>,
    pub payment_expected: Option<String>,
    pub reschedule_booking_date: Option<String>,
    pub reschedule_slot_id: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreatePoojaOfferingRequest {
    pub name: String,
    pub description: Option<String>,
    pub base_price_paise: i32,
    pub slots_consumed: Option<i32>,
    pub active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchPoojaOfferingRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub base_price_paise: Option<i32>,
    pub slots_consumed: Option<i32>,
    pub active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminCreatePoojaPackageRequest {
    pub name: String,
    pub description: Option<String>,
    pub additional_price_paise: Option<i32>,
    pub active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchPoojaPackageRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub additional_price_paise: Option<i32>,
    pub active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchPoojaCapacityRequest {
    pub guru_max_per_slot: Option<i32>,
    pub baba_max_per_slot: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchLandingAudioRequest {
    /// Empty string disables landing audio.
    pub audio_url: String,
}

#[derive(Debug, Deserialize)]
pub struct AdminPatchDailyQuoteRequest {
    pub shlok: String,
    pub translation: String,
    pub source: String,
}

#[derive(Debug, Serialize)]
pub struct PoojaCapacityRulesView {
    pub guru_max_per_slot: i32,
    pub baba_max_per_slot: i32,
}

#[derive(Debug, Serialize, FromRow)]
pub struct PoojaOfferingAdminRow {
    pub id: i32,
    pub name: String,
    pub description: String,
    pub base_price_paise: i32,
    pub slots_consumed: i32,
    pub active: bool,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Clone, FromRow)]
pub struct PoojaPackageAdminRow {
    pub id: i32,
    pub offering_id: i32,
    pub name: String,
    pub description: String,
    pub additional_price_paise: i32,
    pub active: bool,
    pub sort_order: i32,
}

#[derive(Debug, Serialize)]
pub struct AdminPoojaOfferingOut {
    #[serde(flatten)]
    pub offering: PoojaOfferingAdminRow,
    pub packages: Vec<PoojaPackageAdminRow>,
}
