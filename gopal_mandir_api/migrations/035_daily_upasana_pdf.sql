-- Daily Upasana items can be either a text article (existing `content`) or a
-- PDF book stored in S3 (`pdf_url`). Add both columns and drop the NOT NULL on
-- `content` so PDF-only rows are valid. Application-layer validation in
-- `src/admin.rs` enforces "either text OR PDF is required".

ALTER TABLE daily_upasana_items
    ADD COLUMN IF NOT EXISTS pdf_url    TEXT,
    ADD COLUMN IF NOT EXISTS page_count INT;

ALTER TABLE daily_upasana_items
    ALTER COLUMN content DROP NOT NULL;
