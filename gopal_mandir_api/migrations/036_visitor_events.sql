-- Anonymous screen-view analytics (IP/UA filled at ingest).
-- If deploy fails with VersionMismatch(36), the DB already applied a different
-- revision of this file once: run
--   DELETE FROM _sqlx_migrations WHERE version = 36;
-- then redeploy (DDL below is idempotent via IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS visitor_events (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    screen TEXT NOT NULL,
    session_id TEXT NULL,
    platform TEXT NOT NULL,
    app_version TEXT NULL,
    ip_seen TEXT NULL,
    forwarded_for TEXT NULL,
    user_agent TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_visitor_events_occurred_at
    ON visitor_events (occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_visitor_events_ip_occurred
    ON visitor_events (ip_seen, occurred_at DESC);
