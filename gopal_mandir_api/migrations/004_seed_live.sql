-- Seed a single live darshan config row if table is empty

INSERT INTO live_darshan (title, stream_url, is_live, description)
SELECT
  'Shri Gopal Mandir — Live Darshan',
  'https://www.youtube.com/live',
  FALSE,
  ''
WHERE NOT EXISTS (SELECT 1 FROM live_darshan);

