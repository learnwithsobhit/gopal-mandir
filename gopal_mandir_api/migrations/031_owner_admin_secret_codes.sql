-- Owner/admin roles and owner-generated one-time secret codes.
ALTER TABLE admins
    ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'admin';

-- Keep role data clean for legacy rows.
UPDATE admins
SET role = 'admin'
WHERE role IS NULL OR role NOT IN ('owner', 'admin');

-- Ensure there can be at most one active owner.
CREATE UNIQUE INDEX IF NOT EXISTS uq_admins_single_active_owner
    ON admins (role)
    WHERE role = 'owner' AND status = 'active';

CREATE TABLE IF NOT EXISTS admin_secret_codes (
    id UUID PRIMARY KEY,
    code_hash TEXT NOT NULL UNIQUE,
    target_phone VARCHAR(20) NOT NULL,
    target_name VARCHAR(200),
    created_by_admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    consumed_by_admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_secret_codes_target_phone_created_at
    ON admin_secret_codes(target_phone, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_secret_codes_active
    ON admin_secret_codes(expires_at)
    WHERE consumed_at IS NULL;

-- Migration bootstrap owner. Change this seeded phone/name in production if needed.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM admins
        WHERE role = 'owner' AND status = 'active'
    ) THEN
        INSERT INTO admins (id, phone, name, status, role)
        VALUES (
            '11111111-1111-1111-1111-111111111111',
            '9999999999',
            'Temple Owner',
            'active',
            'owner'
        )
        ON CONFLICT (phone) DO UPDATE
        SET role = 'owner', status = 'active', updated_at = NOW();
    END IF;
END $$;
