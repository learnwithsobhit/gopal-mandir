//! Minimal SigV4 presigned PUT for S3-compatible endpoints (no AWS SDK).

use chrono::Utc;
use hmac::{Hmac, Mac};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;

type HmacSha256 = Hmac<Sha256>;

fn sha256_hex(data: impl AsRef<[u8]>) -> String {
    let mut h = Sha256::new();
    h.update(data.as_ref());
    hex::encode(h.finalize())
}

fn sign_hmac(key: &[u8], msg: &[u8]) -> Vec<u8> {
    let mut mac = HmacSha256::new_from_slice(key).expect("HMAC key length");
    mac.update(msg);
    mac.finalize().into_bytes().to_vec()
}

fn signing_key(secret: &str, date_stamp: &str, region: &str, service: &str) -> Vec<u8> {
    let k_date = sign_hmac(format!("AWS4{}", secret).as_bytes(), date_stamp.as_bytes());
    let k_region = sign_hmac(&k_date, region.as_bytes());
    let k_service = sign_hmac(&k_region, service.as_bytes());
    sign_hmac(&k_service, b"aws4_request")
}

/// Build a presigned PUT URL. `host` is the HTTP Host header value (no port unless needed).
/// `canonical_uri` must start with `/` and use URI-encoded path segments for the object key.
/// `use_https` selects the URL scheme for the returned string.
pub fn presign_put_url(
    host: &str,
    canonical_uri: &str,
    region: &str,
    access_key: &str,
    secret_key: &str,
    content_type: &str,
    expires_secs: u64,
    use_https: bool,
) -> Result<String, &'static str> {
    if !canonical_uri.starts_with('/') {
        return Err("canonical_uri must start with /");
    }
    let now = Utc::now();
    let amz_date = now.format("%Y%m%dT%H%M%SZ").to_string();
    let date_stamp = now.format("%Y%m%d").to_string();
    let credential_scope = format!("{}/{}/s3/aws4_request", date_stamp, region);
    let credential = format!("{}/{}", access_key, credential_scope);

    let mut params: BTreeMap<String, String> = BTreeMap::new();
    params.insert(
        "X-Amz-Algorithm".into(),
        "AWS4-HMAC-SHA256".into(),
    );
    params.insert("X-Amz-Credential".into(), credential);
    params.insert("X-Amz-Date".into(), amz_date.clone());
    params.insert("X-Amz-Expires".into(), expires_secs.to_string());
    params.insert("X-Amz-SignedHeaders".into(), "content-type;host".into());

    let canonical_qs = params
        .iter()
        .map(|(k, v)| {
            format!(
                "{}={}",
                utf8_encode_query_key(k),
                utf8_encode_query_val(v)
            )
        })
        .collect::<Vec<_>>()
        .join("&");

    let canonical_headers = format!(
        "content-type:{}\nhost:{}\n",
        content_type.trim(),
        host.trim()
    );
    let signed_headers = "content-type;host";
    let payload_hash = "UNSIGNED-PAYLOAD";

    let canonical_request = format!(
        "PUT\n{}\n{}\n{}\n{}\n{}",
        canonical_uri, canonical_qs, canonical_headers, signed_headers, payload_hash
    );

    let hashed_request = sha256_hex(canonical_request.as_bytes());
    let string_to_sign = format!(
        "AWS4-HMAC-SHA256\n{}\n{}\n{}",
        amz_date, credential_scope, hashed_request
    );

    let key = signing_key(secret_key, &date_stamp, region, "s3");
    let sig = hex::encode(sign_hmac(&key, string_to_sign.as_bytes()));

    let mut full_params = params;
    full_params.insert("X-Amz-Signature".into(), sig);

    let query = full_params
        .iter()
        .map(|(k, v)| {
            format!(
                "{}={}",
                utf8_encode_query_key(k),
                utf8_encode_query_val(v)
            )
        })
        .collect::<Vec<_>>()
        .join("&");

    let scheme = if use_https { "https" } else { "http" };
    Ok(format!(
        "{}://{}{}?{}",
        scheme,
        host.trim(),
        canonical_uri,
        query
    ))
}

fn utf8_encode_query_key(s: &str) -> String {
    urlencoding::encode(s).replace('+', "%20")
}

fn utf8_encode_query_val(s: &str) -> String {
    urlencoding::encode(s).replace('+', "%20")
}

/// Encode each path segment (between slashes) for S3 virtual-hosted-style URI (`/key`).
pub fn encode_s3_object_path(key: &str) -> String {
    let mut out = String::from("/");
    let parts: Vec<&str> = key.split('/').filter(|p| !p.is_empty()).collect();
    for (i, p) in parts.iter().enumerate() {
        if i > 0 {
            out.push('/');
        }
        out.push_str(&urlencoding::encode(p).replace('+', "%20"));
    }
    out
}

/// Path-style URI: `/bucket/key/segments...` (MinIO, custom `S3_ENDPOINT`).
pub fn path_style_object_path(bucket: &str, key: &str) -> String {
    let mut segs: Vec<&str> = vec![bucket.trim()];
    segs.extend(key.split('/').map(str::trim).filter(|s| !s.is_empty()));
    let mut out = String::new();
    for s in segs {
        out.push('/');
        out.push_str(&urlencoding::encode(s).replace('+', "%20"));
    }
    out
}
