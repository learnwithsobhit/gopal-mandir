CREATE TABLE IF NOT EXISTS feedback_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    message TEXT NOT NULL,
    source VARCHAR(30) NOT NULL DEFAULT 'app',
    status VARCHAR(30) NOT NULL DEFAULT 'new',
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    owner_admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    reference_id VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback_responses (
    id SERIAL PRIMARY KEY,
    feedback_id INTEGER NOT NULL REFERENCES feedback_items(id) ON DELETE CASCADE,
    author_type VARCHAR(20) NOT NULL DEFAULT 'admin',
    author_admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feedback_items_status_created
    ON feedback_items(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_items_priority_created
    ON feedback_items(priority, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_items_rating_created
    ON feedback_items(rating, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_items_owner
    ON feedback_items(owner_admin_id);
CREATE INDEX IF NOT EXISTS idx_feedback_responses_feedback_created
    ON feedback_responses(feedback_id, created_at ASC);
