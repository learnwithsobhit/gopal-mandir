-- Support time-bounded scans for admin activity feed (WHERE created_at > $1 ORDER BY created_at DESC).
CREATE INDEX IF NOT EXISTS idx_members_created_at ON members (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_event_participations_created_at ON event_participations (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pooja_bookings_created_at ON pooja_bookings (created_at DESC);
