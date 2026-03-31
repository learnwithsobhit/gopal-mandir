-- Convert existing date-based daily_upasana_items to title-based (single current row per title).

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'daily_upasana_items'
          AND column_name = 'for_date'
    ) THEN
        -- Keep latest row per title by updated_at then id.
        DELETE FROM daily_upasana_items d
        USING (
            SELECT id
            FROM (
                SELECT
                    id,
                    ROW_NUMBER() OVER (
                        PARTITION BY title
                        ORDER BY updated_at DESC, id DESC
                    ) AS rn
                FROM daily_upasana_items
            ) x
            WHERE x.rn > 1
        ) dup
        WHERE d.id = dup.id;

        ALTER TABLE daily_upasana_items
            DROP CONSTRAINT IF EXISTS daily_upasana_items_for_date_title_key;

        ALTER TABLE daily_upasana_items
            DROP COLUMN IF EXISTS for_date;
    END IF;
END $$;

ALTER TABLE daily_upasana_items
    ADD CONSTRAINT daily_upasana_items_title_key UNIQUE (title);

