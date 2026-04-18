-- Astrology / muhurat consultation requests (fire-and-forget form)

CREATE TABLE IF NOT EXISTS astro_consult_requests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(200),
    category VARCHAR(50) NOT NULL DEFAULT 'astrology',
    subject VARCHAR(300) NOT NULL DEFAULT '',
    question TEXT NOT NULL,
    dob_date DATE,
    dob_time TIME,
    birth_place VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    admin_note TEXT NOT NULL DEFAULT '',
    answered_by UUID REFERENCES admins(id) ON DELETE SET NULL,
    answered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_astro_consult_requests_status_created
    ON astro_consult_requests(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_astro_consult_requests_phone_created
    ON astro_consult_requests(phone, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_astro_consult_requests_category_created
    ON astro_consult_requests(category, created_at DESC);
