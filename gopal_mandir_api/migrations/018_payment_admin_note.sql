-- Admin follow-up notes when resolving failed/pending payments offline

ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS payment_admin_note TEXT;

ALTER TABLE event_donations
  ADD COLUMN IF NOT EXISTS payment_admin_note TEXT;

ALTER TABLE seva_bookings
  ADD COLUMN IF NOT EXISTS payment_admin_note TEXT;
