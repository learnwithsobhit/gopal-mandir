-- Prasad: subtotal, 10% delivery fee, temple vs online payment, Razorpay reconciliation

ALTER TABLE prasad_orders
  ADD COLUMN IF NOT EXISTS subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivery_fee DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) NOT NULL DEFAULT 'temple';

-- Backfill: historical rows = item total only, no delivery fee, pay at temple
UPDATE prasad_orders SET subtotal = total_amount, delivery_fee = 0, payment_method = 'temple'
WHERE subtotal = 0 AND delivery_fee = 0;

ALTER TABLE prasad_orders
  ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20),
  ADD COLUMN IF NOT EXISTS gateway VARCHAR(32),
  ADD COLUMN IF NOT EXISTS gateway_order_id VARCHAR(64),
  ADD COLUMN IF NOT EXISTS gateway_payment_id VARCHAR(64),
  ADD COLUMN IF NOT EXISTS amount_paise INTEGER,
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_failure_reason TEXT,
  ADD COLUMN IF NOT EXISTS payment_updated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_admin_note TEXT;

ALTER TABLE prasad_orders
  DROP CONSTRAINT IF EXISTS prasad_orders_payment_method_check;

ALTER TABLE prasad_orders
  ADD CONSTRAINT prasad_orders_payment_method_check
  CHECK (payment_method IN ('online', 'temple'));

ALTER TABLE prasad_orders
  DROP CONSTRAINT IF EXISTS prasad_orders_payment_status_check;

ALTER TABLE prasad_orders
  ADD CONSTRAINT prasad_orders_payment_status_check
  CHECK (
    payment_status IS NULL
    OR payment_status IN ('pending', 'paid', 'failed', 'refunded')
  );

CREATE UNIQUE INDEX IF NOT EXISTS idx_prasad_orders_gateway_order
  ON prasad_orders (gateway, gateway_order_id)
  WHERE gateway_order_id IS NOT NULL AND gateway IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_prasad_orders_payment_followup
  ON prasad_orders (created_at DESC)
  WHERE payment_status IN ('failed', 'pending');
