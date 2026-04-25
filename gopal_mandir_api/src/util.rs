use actix_web::HttpRequest;
use sha2::{Digest, Sha256};

pub fn normalize_phone(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }
    let mut out = String::new();
    for (i, ch) in trimmed.chars().enumerate() {
        if ch.is_ascii_digit() {
            out.push(ch);
        } else if ch == '+' && i == 0 {
            out.push(ch);
        }
    }
    let digits: String = out.chars().filter(|c| c.is_ascii_digit()).collect();
    if digits.len() < 8 || digits.len() > 15 {
        return None;
    }
    Some(if out.starts_with('+') {
        out
    } else {
        format!("+{}", digits)
    })
}

pub fn sha256_hex(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}

pub fn truncate_payment_reason(s: &str) -> String {
    s.chars().take(500).collect()
}

/// Best-effort client IP for logging behind Railway / reverse proxies.
/// Stores first hop of `X-Forwarded-For` when present, else `X-Real-IP`,
/// else the direct peer address.
pub fn client_ip_seen(req: &HttpRequest) -> Option<String> {
    if let Some(xff) = req.headers().get("x-forwarded-for").and_then(|v| v.to_str().ok()) {
        let first = xff.split(',').next().map(str::trim).filter(|s| !s.is_empty());
        if let Some(ip) = first {
            return Some(ip.to_string());
        }
    }
    if let Some(xri) = req.headers().get("x-real-ip").and_then(|v| v.to_str().ok()) {
        let t = xri.trim();
        if !t.is_empty() {
            return Some(t.to_string());
        }
    }
    req.peer_addr().map(|a| a.ip().to_string())
}

/// Raw `X-Forwarded-For` header value (may be a comma-separated chain).
pub fn forwarded_for_raw(req: &HttpRequest) -> Option<String> {
    req.headers()
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.chars().take(2048).collect())
}

pub fn bearer_token(req: &HttpRequest) -> Option<String> {
    let header = req.headers().get("authorization")?.to_str().ok()?;
    let header = header.trim();
    let prefix = "Bearer ";
    if header.len() <= prefix.len() || !header.starts_with(prefix) {
        return None;
    }
    Some(header[prefix.len()..].trim().to_string())
}
