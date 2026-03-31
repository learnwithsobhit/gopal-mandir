ALTER TABLE festival_calendar
  ADD COLUMN IF NOT EXISTS icon_url TEXT,
  ADD COLUMN IF NOT EXISTS banner_url TEXT;

CREATE TABLE IF NOT EXISTS festival_media (
  id SERIAL PRIMARY KEY,
  festival_id INT NOT NULL REFERENCES festival_calendar(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  image_url TEXT NOT NULL DEFAULT '',
  video_url TEXT NOT NULL DEFAULT '',
  media_type TEXT NOT NULL DEFAULT 'image',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_media_festival_id
  ON festival_media (festival_id);

CREATE INDEX IF NOT EXISTS idx_festival_media_sort
  ON festival_media (festival_id, sort_order, id);

CREATE TABLE IF NOT EXISTS festival_media_likes (
  id SERIAL PRIMARY KEY,
  media_id INT NOT NULL REFERENCES festival_media(id) ON DELETE CASCADE,
  name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_media_likes_media_id
  ON festival_media_likes (media_id);

CREATE TABLE IF NOT EXISTS festival_media_comments (
  id SERIAL PRIMARY KEY,
  media_id INT NOT NULL REFERENCES festival_media(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_media_comments_media_id
  ON festival_media_comments (media_id);
