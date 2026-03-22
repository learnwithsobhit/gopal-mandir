-- Payment gateway fields for India (Razorpay orders + webhook reconciliation)

ALTER TABLE donations
  ADD COLUMN payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  ADD COLUMN gateway VARCHAR(32),
  ADD COLUMN gateway_order_id VARCHAR(64),
  ADD COLUMN gateway_payment_id VARCHAR(64),
  ADD COLUMN amount_paise INTEGER,
  ADD COLUMN paid_at TIMESTAMPTZ;

UPDATE donations SET
  payment_status = 'paid',
  paid_at = created_at,
  amount_paise = ROUND(amount::numeric * 100)::integer;

ALTER TABLE donations
  ADD CONSTRAINT donations_payment_status_check
  CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded'));

CREATE UNIQUE INDEX idx_donations_gateway_order
  ON donations (gateway, gateway_order_id)
  WHERE gateway_order_id IS NOT NULL AND gateway IS NOT NULL;

CREATE INDEX idx_donations_payment_status_paid ON donations (created_at DESC)
  WHERE payment_status = 'paid';

-- event_donations
ALTER TABLE event_donations
  ADD COLUMN payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  ADD COLUMN gateway VARCHAR(32),
  ADD COLUMN gateway_order_id VARCHAR(64),
  ADD COLUMN gateway_payment_id VARCHAR(64),
  ADD COLUMN amount_paise INTEGER,
  ADD COLUMN paid_at TIMESTAMPTZ;

UPDATE event_donations SET
  payment_status = 'paid',
  paid_at = created_at,
  amount_paise = ROUND(amount::numeric * 100)::integer;

ALTER TABLE event_donations
  ADD CONSTRAINT event_donations_payment_status_check
  CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded'));

CREATE UNIQUE INDEX idx_event_donations_gateway_order
  ON event_donations (gateway, gateway_order_id)
  WHERE gateway_order_id IS NOT NULL AND gateway IS NOT NULL;

CREATE INDEX idx_event_donations_payment_status_paid ON event_donations (created_at DESC)
  WHERE payment_status = 'paid';
