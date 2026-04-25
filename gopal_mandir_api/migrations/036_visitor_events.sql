-- Anonymous in-app screen views for admin analytics (IP/UA from request).

CREATE TABLE IF NOT EXISTS visitor_events (
    id           BIGSERIAL PRIMARY KEY,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    screen       TEXT NOT NULL,
    session_id   TEXT,
    platform     TEXT NOT NULL,
    app_version  TEXT,
    ip_seen      TEXT,
    forwarded_for TEXT,
    user_agent   TEXT
);

CREATE INDEX IF NOT EXISTS visitor_events_occurred_at_idx
    ON visitor_events (occurred_at DESC);

CREATE INDEX IF NOT EXISTS visitor_events_ip_occurred_idx
    ON visitor_events (ip_seen, occurred_at DESC);
