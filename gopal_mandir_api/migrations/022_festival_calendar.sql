-- Date-wise festivals/events calendar (multiple entries per date)
CREATE TABLE IF NOT EXISTS festival_calendar (
  id SERIAL PRIMARY KEY,
  for_date DATE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_calendar_for_date
  ON festival_calendar (for_date);

CREATE INDEX IF NOT EXISTS idx_festival_calendar_date_sort
  ON festival_calendar (for_date, sort_order, id);
