//! Thin Redis-backed read-through cache.
//!
//! Design:
//! - Graceful degradation. If `REDIS_URL` is unset or the connection fails,
//!   every method becomes a no-op and [`Cache::get_or_compute`] simply calls
//!   the provided `compute` closure so the app still works without Redis.
//! - Namespace version counters for O(1) invalidation: keys embed a counter
//!   read from `ver:{ns}`. Admin mutations call [`Cache::invalidate`] which
//!   `INCR`s that counter; old keys are orphaned and expire via TTL.
//! - `redis::aio::ConnectionManager` is cheap to clone and auto-reconnects,
//!   so a single instance is shared via `web::Data<Cache>`.
//!
//! Boilerplate at call sites is kept minimal via [`Cache::get_or_compute`],
//! which wraps any `FnOnce() -> Future<Result<T, sqlx::Error>>`.

use std::future::Future;
use std::time::Duration;

use redis::aio::ConnectionManager;
use redis::AsyncCommands;
use serde::de::DeserializeOwned;
use serde::Serialize;

#[derive(Clone)]
pub struct Cache {
    conn: Option<ConnectionManager>,
}

#[derive(Debug, Serialize)]
pub struct CacheStats {
    pub enabled: bool,
    pub hits: u64,
    pub misses: u64,
    pub dbsize: i64,
    pub hit_rate_pct: f64,
}

impl Cache {
    /// Build a `Cache` from the `REDIS_URL` env var. Any failure (missing
    /// var, DNS error, unreachable host) returns a disabled cache with a
    /// log line; the app keeps serving from Postgres.
    pub async fn from_env() -> Self {
        let url = match std::env::var("REDIS_URL") {
            Ok(u) if !u.trim().is_empty() => u,
            _ => {
                println!(
                    "⚠️  Redis: REDIS_URL not set — namespace cache disabled (serving from DB)"
                );
                return Self { conn: None };
            }
        };

        let client = match redis::Client::open(url) {
            Ok(c) => c,
            Err(e) => {
                println!("⚠️  Redis: invalid REDIS_URL ({}) — cache disabled", e);
                return Self { conn: None };
            }
        };

        match ConnectionManager::new(client).await {
            Ok(conn) => {
                println!("✅ Redis: connected (namespace cache enabled)");
                Self { conn: Some(conn) }
            }
            Err(e) => {
                println!(
                    "⚠️  Redis: connection failed ({}) — cache disabled, serving from DB",
                    e
                );
                Self { conn: None }
            }
        }
    }

    pub fn is_enabled(&self) -> bool {
        self.conn.is_some()
    }

    /// Current version counter for `ns`, or 0 when cache is disabled / Redis
    /// errored. A missing key is treated as 0 (first generation).
    pub async fn version(&self, ns: &str) -> u64 {
        let Some(mut conn) = self.conn.clone() else { return 0; };
        let key = format!("ver:{}", ns);
        conn.get::<_, Option<u64>>(&key)
            .await
            .ok()
            .flatten()
            .unwrap_or(0)
    }

    /// Bump the namespace version, orphaning all existing `cache:{ns}:*:v{n}`
    /// keys. Called from admin mutation handlers.
    pub async fn invalidate(&self, ns: &str) {
        let Some(mut conn) = self.conn.clone() else { return; };
        let key = format!("ver:{}", ns);
        let _: Result<i64, _> = conn.incr(&key, 1).await;
    }

    /// Delete a specific key. Used for per-date caches (e.g. panchang)
    /// where namespace-level invalidation would be overly broad.
    pub async fn del(&self, key: &str) {
        let Some(mut conn) = self.conn.clone() else { return; };
        let _: Result<i64, _> = conn.del(key).await;
    }

    /// Read-through helper. Returns cached value when present, otherwise runs
    /// `compute`, stores the result with `ttl`, and returns it. Cache misses
    /// are silent on Redis errors — the fetch always happens as a fallback.
    pub async fn get_or_compute<T, F, Fut, E>(
        &self,
        ns: &str,
        suffix: &str,
        ttl: Duration,
        compute: F,
    ) -> Result<T, E>
    where
        T: Serialize + DeserializeOwned,
        F: FnOnce() -> Fut,
        Fut: Future<Output = Result<T, E>>,
    {
        let version = self.version(ns).await;
        let key = format!("cache:{}:{}:v{}", ns, suffix, version);

        if let Some(hit) = self.get_json::<T>(&key).await {
            self.incr_stat("hits").await;
            return Ok(hit);
        }

        self.incr_stat("misses").await;
        let value = compute().await?;
        self.set_json(&key, &value, ttl).await;
        Ok(value)
    }

    async fn get_json<T: DeserializeOwned>(&self, key: &str) -> Option<T> {
        let mut conn = self.conn.clone()?;
        let raw: Option<String> = conn.get(key).await.ok().flatten();
        let raw = raw?;
        serde_json::from_str(&raw).ok()
    }

    async fn set_json<T: Serialize>(&self, key: &str, value: &T, ttl: Duration) {
        let Some(mut conn) = self.conn.clone() else { return; };
        let Ok(payload) = serde_json::to_string(value) else { return; };
        let ttl_secs = ttl.as_secs().max(1) as u64;
        let _: Result<(), _> = conn.set_ex(key, payload, ttl_secs).await;
    }

    /// Binary cache for the image proxy. The content-type is stored in a
    /// companion key so we can return the correct header on a hit.
    pub async fn get_bytes(&self, key: &str) -> Option<(Vec<u8>, String)> {
        let mut conn = self.conn.clone()?;
        let bytes: Option<Vec<u8>> = conn.get(key).await.ok().flatten();
        let bytes = bytes?;
        let ct_key = format!("{}:ct", key);
        let content_type: String = conn
            .get::<_, Option<String>>(&ct_key)
            .await
            .ok()
            .flatten()
            .unwrap_or_else(|| "image/jpeg".to_string());
        Some((bytes, content_type))
    }

    pub async fn set_bytes(&self, key: &str, bytes: &[u8], content_type: &str, ttl: Duration) {
        let Some(mut conn) = self.conn.clone() else { return; };
        let ttl_secs = ttl.as_secs().max(1) as u64;
        let _: Result<(), _> = conn.set_ex(key, bytes.to_vec(), ttl_secs).await;
        let ct_key = format!("{}:ct", key);
        let _: Result<(), _> = conn.set_ex(&ct_key, content_type.to_string(), ttl_secs).await;
    }

    pub async fn incr_stat(&self, field: &str) {
        let Some(mut conn) = self.conn.clone() else { return; };
        let _: Result<i64, _> = conn.hincr("cache:stats", field, 1).await;
    }

    pub async fn stats(&self) -> CacheStats {
        let Some(mut conn) = self.conn.clone() else {
            return CacheStats {
                enabled: false,
                hits: 0,
                misses: 0,
                dbsize: 0,
                hit_rate_pct: 0.0,
            };
        };
        let hits: u64 = conn
            .hget::<_, _, Option<u64>>("cache:stats", "hits")
            .await
            .ok()
            .flatten()
            .unwrap_or(0);
        let misses: u64 = conn
            .hget::<_, _, Option<u64>>("cache:stats", "misses")
            .await
            .ok()
            .flatten()
            .unwrap_or(0);
        let dbsize: i64 = redis::cmd("DBSIZE")
            .query_async(&mut conn)
            .await
            .unwrap_or(0);
        let total = hits + misses;
        let hit_rate_pct = if total > 0 {
            (hits as f64 * 100.0) / total as f64
        } else {
            0.0
        };
        CacheStats {
            enabled: true,
            hits,
            misses,
            dbsize,
            hit_rate_pct,
        }
    }
}
