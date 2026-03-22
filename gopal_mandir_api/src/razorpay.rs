//! Razorpay Orders API + webhook / payment signature verification.

use hmac::{Hmac, Mac};
use serde::Deserialize;
use serde_json::json;
use sha2::Sha256;
use std::env;

type HmacSha256 = Hmac<Sha256>;

#[derive(Clone)]
pub struct RazorpayConfig {
    pub key_id: String,
    pub key_secret: String,
    pub webhook_secret: String,
}

impl RazorpayConfig {
    pub fn from_env() -> Option<Self> {
        let key_id = env::var("RAZORPAY_KEY_ID").ok()?;
        let key_secret = env::var("RAZORPAY_KEY_SECRET").ok()?;
        let webhook_secret = env::var("RAZORPAY_WEBHOOK_SECRET").unwrap_or_default();
        if key_id.is_empty() || key_secret.is_empty() {
            return None;
        }
        Some(Self {
            key_id,
            key_secret,
            webhook_secret,
        })
    }
}

#[derive(Debug, Deserialize)]
pub struct RazorpayOrderResponse {
    pub id: String,
    pub amount: i64,
    pub currency: String,
}

/// HMAC-SHA256 hex of raw webhook body using webhook secret.
pub fn verify_webhook_signature(body: &[u8], signature_header: &str, secret: &str) -> bool {
    if secret.is_empty() || signature_header.is_empty() {
        return false;
    }
    let mut mac = HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC key length");
    mac.update(body);
    let expected = hex::encode(mac.finalize().into_bytes());
    constant_time_eq(&expected, signature_header)
}

/// App success callback: HMAC-SHA256 hex of `order_id|payment_id` using key_secret.
pub fn verify_payment_signature(order_id: &str, payment_id: &str, signature: &str, key_secret: &str) -> bool {
    if order_id.is_empty() || payment_id.is_empty() || signature.is_empty() {
        return false;
    }
    let msg = format!("{}|{}", order_id, payment_id);
    let mut mac = HmacSha256::new_from_slice(key_secret.as_bytes()).expect("HMAC key length");
    mac.update(msg.as_bytes());
    let expected = hex::encode(mac.finalize().into_bytes());
    constant_time_eq(&expected, signature)
}

fn constant_time_eq(a: &str, b: &str) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.bytes()
        .zip(b.bytes())
        .fold(0u8, |acc, (x, y)| acc | (x ^ y))
        == 0
}

pub async fn create_order(
    cfg: &RazorpayConfig,
    amount_paise: i64,
    receipt: &str,
    notes: serde_json::Value,
) -> Result<RazorpayOrderResponse, String> {
    let client = reqwest::Client::new();

    let body = json!({
        "amount": amount_paise,
        "currency": "INR",
        "receipt": receipt,
        "notes": notes,
    });

    let resp = client
        .post("https://api.razorpay.com/v1/orders")
        .basic_auth(&cfg.key_id, Some(&cfg.key_secret))
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    if !resp.status().is_success() {
        let text = resp.text().await.unwrap_or_default();
        return Err(format!("Razorpay error: {}", text));
    }

    resp.json::<RazorpayOrderResponse>()
        .await
        .map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn payment_sig_matches_razorpay_style() {
        let secret = "whsec_test_secret";
        let order_id = "order_test";
        let pay_id = "pay_test";
        let mut mac = HmacSha256::new_from_slice(secret.as_bytes()).unwrap();
        mac.update(format!("{}|{}", order_id, pay_id).as_bytes());
        let sig = hex::encode(mac.finalize().into_bytes());
        assert!(verify_payment_signature(order_id, pay_id, &sig, secret));
        assert!(!verify_payment_signature(order_id, pay_id, "deadbeef", secret));
    }

    #[test]
    fn webhook_sig_matches_hmac_of_body() {
        let secret = "webhook_secret_abc";
        let body = br#"{"event":"payment.captured"}"#;
        let mut mac = HmacSha256::new_from_slice(secret.as_bytes()).unwrap();
        mac.update(body);
        let sig = hex::encode(mac.finalize().into_bytes());
        assert!(verify_webhook_signature(body, &sig, secret));
        assert!(!verify_webhook_signature(body, "00", secret));
    }
}
