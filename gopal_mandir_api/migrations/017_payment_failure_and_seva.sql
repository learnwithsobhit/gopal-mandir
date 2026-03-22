-- Failure context for donor follow-up; payment columns for seva_bookings

ALTER TABLE donations
  ADD COLUMN payment_failure_reason TEXT,
  ADD COLUMN payment_updated_at TIMESTAMPTZ;

CREATE INDEX idx_donations_payment_followup ON donations (created_at DESC)
  WHERE payment_status IN ('failed', 'pending');

ALTER TABLE event_donations
  ADD COLUMN payment_failure_reason TEXT,
  ADD COLUMN payment_updated_at TIMESTAMPTZ;

CREATE INDEX idx_event_donations_payment_followup ON event_donations (created_at DESC)
  WHERE payment_status IN ('failed', 'pending');

ALTER TABLE seva_bookings
  ADD COLUMN payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  ADD COLUMN gateway VARCHAR(32),
  ADD COLUMN gateway_order_id VARCHAR(64),
  ADD COLUMN gateway_payment_id VARCHAR(64),
  ADD COLUMN amount_paise INTEGER,
  ADD COLUMN paid_at TIMESTAMPTZ,
  ADD COLUMN payment_failure_reason TEXT,
  ADD COLUMN payment_updated_at TIMESTAMPTZ;

UPDATE seva_bookings b
SET
  payment_status = 'paid',
  paid_at = b.created_at,
  amount_paise = ROUND(s.price::numeric * 100)::integer
FROM seva_items s
WHERE s.id = b.seva_item_id
  AND b.gateway_order_id IS NULL;

ALTER TABLE seva_bookings
  ADD CONSTRAINT seva_bookings_payment_status_check
  CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded'));

CREATE UNIQUE INDEX idx_seva_bookings_gateway_order
  ON seva_bookings (gateway, gateway_order_id)
  WHERE gateway_order_id IS NOT NULL AND gateway IS NOT NULL;

CREATE INDEX idx_seva_bookings_payment_followup ON seva_bookings (created_at DESC)
  WHERE payment_status IN ('failed', 'pending');
