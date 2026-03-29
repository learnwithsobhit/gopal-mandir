-- Guru/Baba pooja appointment booking

CREATE TABLE pooja_slot_definitions (
  id SERIAL PRIMARY KEY,
  label VARCHAR(100) NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  sort_order INT NOT NULL DEFAULT 0
);

INSERT INTO pooja_slot_definitions (label, start_time, end_time, sort_order) VALUES
  ('Morning', '06:00', '10:00', 0),
  ('Afternoon', '10:00', '14:00', 1),
  ('Evening', '16:00', '20:00', 2);

CREATE TABLE pooja_offerings (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  base_price_paise INT NOT NULL CHECK (base_price_paise >= 0),
  slots_consumed INT NOT NULL DEFAULT 1 CHECK (slots_consumed >= 1),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pooja_offering_packages (
  id SERIAL PRIMARY KEY,
  offering_id INT NOT NULL REFERENCES pooja_offerings(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  additional_price_paise INT NOT NULL DEFAULT 0 CHECK (additional_price_paise >= 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE pooja_capacity_rules (
  officiant VARCHAR(20) NOT NULL PRIMARY KEY CHECK (officiant IN ('guru','baba')),
  max_per_slot_per_day INT NOT NULL DEFAULT 1 CHECK (max_per_slot_per_day >= 1),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO pooja_capacity_rules (officiant, max_per_slot_per_day) VALUES ('guru', 1), ('baba', 1);

CREATE TABLE pooja_bookings (
  id SERIAL PRIMARY KEY,
  reference_id VARCHAR(60) NOT NULL UNIQUE,
  offering_id INT NOT NULL REFERENCES pooja_offerings(id) ON DELETE RESTRICT,
  package_id INT REFERENCES pooja_offering_packages(id) ON DELETE SET NULL,
  officiant VARCHAR(20) NOT NULL CHECK (officiant IN ('guru','baba')),
  slot_id INT NOT NULL REFERENCES pooja_slot_definitions(id) ON DELETE RESTRICT,
  booking_date DATE NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  venue VARCHAR(20) NOT NULL CHECK (venue IN ('temple','devotee_home')),
  address TEXT,
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  notes TEXT,
  booking_status VARCHAR(40) NOT NULL DEFAULT 'pending_confirmation'
    CHECK (booking_status IN ('pending_confirmation','confirmed','completed','cancelled')),
  payment_expected VARCHAR(20) CHECK (payment_expected IS NULL OR payment_expected IN ('online','offline')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'not_applicable'
    CHECK (payment_status IN ('not_applicable','pending','paid','failed','refunded')),
  gateway VARCHAR(32),
  gateway_order_id VARCHAR(64),
  gateway_payment_id VARCHAR(64),
  amount_paise INT,
  paid_at TIMESTAMPTZ,
  payment_failure_reason TEXT,
  payment_updated_at TIMESTAMPTZ,
  payment_admin_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pooja_bookings_phone ON pooja_bookings(phone);
CREATE INDEX idx_pooja_bookings_sched ON pooja_bookings (booking_date, slot_id, officiant);

CREATE INDEX idx_pooja_bookings_availability ON pooja_bookings (officiant, slot_id, booking_date)
  WHERE booking_status IN ('pending_confirmation','confirmed');

CREATE UNIQUE INDEX idx_pooja_bookings_gateway_order
  ON pooja_bookings (gateway, gateway_order_id)
  WHERE gateway_order_id IS NOT NULL AND gateway IS NOT NULL;

CREATE TABLE pooja_booking_events (
  id BIGSERIAL PRIMARY KEY,
  booking_id INT NOT NULL REFERENCES pooja_bookings(id) ON DELETE CASCADE,
  event_type VARCHAR(40) NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO pooja_offerings (name, description, base_price_paise, slots_consumed, sort_order) VALUES
  ('General Pooja', 'Sankalp and pooja with Guru Ji or Baba Ji', 250000, 1, 0),
  ('Griha Pravesh', 'House warming ceremony', 510000, 1, 1),
  ('Marriage (Vivah)', 'Wedding rituals and hawan', 1100000, 1, 2),
  ('Yagyopaveet', 'Sacred thread ceremony', 350000, 1, 3),
  ('Special Hawan', 'Custom hawan and offerings', 310000, 1, 4),
  ('Child Sanskar', 'Naming and child sanskar', 210000, 1, 5),
  ('Swarg Chadai / Shradh', 'Last rites and peace rituals', 410000, 1, 6);

INSERT INTO pooja_offering_packages (offering_id, name, description, additional_price_paise, sort_order)
SELECT id, 'Standard', 'Standard samagri and duration', 0, 0 FROM pooja_offerings WHERE name = 'General Pooja';

INSERT INTO pooja_offering_packages (offering_id, name, description, additional_price_paise, sort_order)
SELECT id, 'Premium', 'Extended ceremony + extra offerings', 100000, 1 FROM pooja_offerings WHERE name = 'General Pooja';

INSERT INTO pooja_offering_packages (offering_id, name, description, additional_price_paise, sort_order)
SELECT id, 'Standard', 'Standard', 0, 0 FROM pooja_offerings WHERE name = 'Griha Pravesh';

INSERT INTO pooja_offering_packages (offering_id, name, description, additional_price_paise, sort_order)
SELECT id, 'Premium', 'Larger hawan setup', 150000, 1 FROM pooja_offerings WHERE name = 'Griha Pravesh';
