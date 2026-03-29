//! Shared helpers for pooja appointment routes (public + admin).

use chrono::{DateTime, FixedOffset, NaiveDate, NaiveTime, TimeZone, Utc};
use sqlx::PgPool;

pub async fn compute_scheduled_at_utc(
    pool: &PgPool,
    booking_date: &str,
    slot_id: i32,
) -> Result<DateTime<Utc>, String> {
    let st: Option<NaiveTime> =
        sqlx::query_scalar("SELECT start_time FROM pooja_slot_definitions WHERE id = $1")
            .bind(slot_id)
            .fetch_optional(pool)
            .await
            .map_err(|e| e.to_string())?;
    let Some(naive_t) = st else {
        return Err("Invalid slot".into());
    };
    let nd =
        NaiveDate::parse_from_str(booking_date, "%Y-%m-%d").map_err(|_| "Invalid date".to_string())?;
    let offset = FixedOffset::east_opt(5 * 3600 + 1800).ok_or_else(|| "tz".to_string())?;
    let naive_dt = nd.and_time(naive_t);
    let local = offset
        .from_local_datetime(&naive_dt)
        .single()
        .ok_or_else(|| "Invalid local time".to_string())?;
    Ok(local.with_timezone(&Utc))
}

pub async fn count_blocking_bookings(
    pool: &PgPool,
    booking_date: NaiveDate,
    slot_id: i32,
    officiant: &str,
    exclude_id: Option<i32>,
) -> Result<i64, sqlx::Error> {
    if let Some(eid) = exclude_id {
        sqlx::query_scalar(
            "SELECT COUNT(*)::bigint FROM pooja_bookings
             WHERE booking_date = $1 AND slot_id = $2 AND officiant = $3
               AND booking_status IN ('pending_confirmation','confirmed')
               AND id <> $4",
        )
        .bind(booking_date)
        .bind(slot_id)
        .bind(officiant)
        .bind(eid)
        .fetch_one(pool)
        .await
    } else {
        sqlx::query_scalar(
            "SELECT COUNT(*)::bigint FROM pooja_bookings
             WHERE booking_date = $1 AND slot_id = $2 AND officiant = $3
               AND booking_status IN ('pending_confirmation','confirmed')",
        )
        .bind(booking_date)
        .bind(slot_id)
        .bind(officiant)
        .fetch_one(pool)
        .await
    }
}

pub async fn max_per_slot(pool: &PgPool, officiant: &str) -> Result<i32, sqlx::Error> {
    let o: Option<i32> =
        sqlx::query_scalar("SELECT max_per_slot_per_day FROM pooja_capacity_rules WHERE officiant = $1")
            .bind(officiant)
            .fetch_optional(pool)
            .await?;
    Ok(o.unwrap_or(1))
}

pub async fn slot_has_capacity(
    pool: &PgPool,
    booking_date: NaiveDate,
    slot_id: i32,
    officiant: &str,
    exclude_booking_id: Option<i32>,
) -> Result<bool, sqlx::Error> {
    let cap = max_per_slot(pool, officiant).await?;
    let booked = count_blocking_bookings(pool, booking_date, slot_id, officiant, exclude_booking_id).await?;
    Ok(booked < cap as i64)
}

pub async fn booking_amount_paise(
    pool: &PgPool,
    offering_id: i32,
    package_id: Option<i32>,
) -> Result<i32, String> {
    if let Some(pid) = package_id {
        let row: Option<(i32, i32)> = sqlx::query_as(
            "SELECT o.base_price_paise, p.additional_price_paise
             FROM pooja_offerings o
             JOIN pooja_offering_packages p ON p.offering_id = o.id AND p.id = $2 AND p.active = TRUE
             WHERE o.id = $1 AND o.active = TRUE",
        )
        .bind(offering_id)
        .bind(pid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        let Some((base, add)) = row else {
            return Err("Invalid offering or package".into());
        };
        Ok(base + add)
    } else {
        let base: Option<i32> =
            sqlx::query_scalar("SELECT base_price_paise FROM pooja_offerings WHERE id = $1 AND active = TRUE")
                .bind(offering_id)
                .fetch_optional(pool)
                .await
                .map_err(|e| e.to_string())?;
        base.ok_or_else(|| "Invalid offering".into())
    }
}
