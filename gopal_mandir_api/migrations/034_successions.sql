-- Succession (परम्परा) lineage of mahants / acharyas at the temple.
-- Ordered by `position` (1 = earliest / founding). `tenure_text` is kept
-- free-form so historical entries can say "c. 1890 – 1945"; the nullable
-- DATE columns below allow precise sort tiebreaks when known.

CREATE TABLE IF NOT EXISTS successions (
    id SERIAL PRIMARY KEY,
    position INTEGER NOT NULL,
    name TEXT NOT NULL,
    title TEXT,
    tenure_text TEXT,
    tenure_start DATE,
    tenure_end DATE,
    bio TEXT,
    quote TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_successions_position ON successions(position);
