-- Long-form "About temple" copy for the public app (admin-editable).

ALTER TABLE temple_info
  ADD COLUMN IF NOT EXISTS about_content TEXT NOT NULL DEFAULT '';
