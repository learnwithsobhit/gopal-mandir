-- Add Google Maps URL column to temple_info

ALTER TABLE temple_info
ADD COLUMN IF NOT EXISTS maps_url TEXT;

-- Seed maps_url for existing temple row (id = 1 assumed)
UPDATE temple_info
SET maps_url = 'https://maps.app.goo.gl/XSL5PhfsBq92c6k9A'
WHERE id = 1;

