CREATE TABLE IF NOT EXISTS daily_upasana_items (
    id SERIAL PRIMARY KEY,
    for_date DATE NOT NULL,
    title VARCHAR(160) NOT NULL,
    category VARCHAR(80) NOT NULL DEFAULT '',
    content TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (for_date, title)
);

