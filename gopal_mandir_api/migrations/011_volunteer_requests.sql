-- Volunteer requests (open to all)

CREATE TABLE IF NOT EXISTS volunteer_requests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(200),
    area VARCHAR(100) NOT NULL DEFAULT '',
    availability TEXT NOT NULL DEFAULT '',
    message TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_volunteer_requests_phone_created_at
    ON volunteer_requests(phone, created_at DESC);

