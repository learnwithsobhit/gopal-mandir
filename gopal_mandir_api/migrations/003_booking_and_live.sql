-- Booking + Live Darshan tables

CREATE TABLE IF NOT EXISTS live_darshan (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL DEFAULT 'Live Darshan',
    stream_url TEXT NOT NULL,
    is_live BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prasad orders created by devotees
CREATE TABLE IF NOT EXISTS prasad_orders (
    id SERIAL PRIMARY KEY,
    prasad_item_id INTEGER NOT NULL REFERENCES prasad_items(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    fulfillment VARCHAR(20) NOT NULL CHECK (fulfillment IN ('pickup', 'delivery')),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    address TEXT,
    notes TEXT,
    total_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    reference_id VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prasad_orders_created_at ON prasad_orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prasad_orders_reference_id ON prasad_orders(reference_id);

-- Seva booking requests
CREATE TABLE IF NOT EXISTS seva_bookings (
    id SERIAL PRIMARY KEY,
    seva_item_id INTEGER NOT NULL REFERENCES seva_items(id) ON DELETE RESTRICT,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    preferred_date VARCHAR(50),
    notes TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    reference_id VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seva_bookings_created_at ON seva_bookings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_seva_bookings_reference_id ON seva_bookings(reference_id);

