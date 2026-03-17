-- Likes and comments for events and gallery items

CREATE TABLE IF NOT EXISTS event_likes (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_likes_event_id
    ON event_likes(event_id);

CREATE TABLE IF NOT EXISTS event_comments (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_comments_event_id
    ON event_comments(event_id);

CREATE TABLE IF NOT EXISTS gallery_likes (
    id SERIAL PRIMARY KEY,
    gallery_id INTEGER NOT NULL REFERENCES gallery(id) ON DELETE CASCADE,
    name VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gallery_likes_gallery_id
    ON gallery_likes(gallery_id);

CREATE TABLE IF NOT EXISTS gallery_comments (
    id SERIAL PRIMARY KEY,
    gallery_id INTEGER NOT NULL REFERENCES gallery(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gallery_comments_gallery_id
    ON gallery_comments(gallery_id);

