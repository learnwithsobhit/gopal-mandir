-- Learning hub: topics (courses) + public registrations

CREATE TABLE IF NOT EXISTS learning_topics (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    category_key VARCHAR(80) NOT NULL DEFAULT 'general',
    description TEXT NOT NULL DEFAULT '',
    teacher_name VARCHAR(200) NOT NULL DEFAULT '',
    delivery_mode VARCHAR(20) NOT NULL DEFAULT 'online'
        CHECK (delivery_mode IN ('online', 'offline', 'both')),
    schedule_summary TEXT NOT NULL DEFAULT '',
    duration_summary TEXT NOT NULL DEFAULT '',
    location_note TEXT,
    max_participants INTEGER CHECK (max_participants IS NULL OR max_participants > 0),
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_learning_topics_published_sort
    ON learning_topics (is_published, sort_order, id);

CREATE INDEX IF NOT EXISTS idx_learning_topics_category
    ON learning_topics (category_key);

CREATE TABLE IF NOT EXISTS learning_registrations (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER NOT NULL REFERENCES learning_topics (id) ON DELETE RESTRICT,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(200),
    notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'new'
        CHECK (status IN ('new', 'confirmed', 'cancelled', 'waitlist')),
    admin_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_learning_registrations_topic_created
    ON learning_registrations (topic_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_learning_registrations_status_created
    ON learning_registrations (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_learning_registrations_phone_created
    ON learning_registrations (phone, created_at DESC);
