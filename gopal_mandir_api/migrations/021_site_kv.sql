-- Key-value site settings (landing audio URL, etc.)

CREATE TABLE IF NOT EXISTS site_kv (
  key VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO site_kv (key, value) VALUES (
  'landing_audio_url',
  'https://mandir-s3-034035677610-ap-south-1-an.s3.ap-south-1.amazonaws.com/gallery/76f2e0d5-63d0-4041-a687-b1134aa3284a.mp3'
) ON CONFLICT (key) DO NOTHING;
