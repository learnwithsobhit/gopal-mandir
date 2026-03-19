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

pub fn bearer_token(req: &HttpRequest) -> Option<String> {
    let header = req.headers().get("authorization")?.to_str().ok()?;
    let header = header.trim();
    let prefix = "Bearer ";
    if header.len() <= prefix.len() || !header.starts_with(prefix) {
        return None;
    }
    Some(header[prefix.len()..].trim().to_string())
}
