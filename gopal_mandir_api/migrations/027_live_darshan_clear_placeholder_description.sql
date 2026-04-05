-- Remove legacy seed placeholder so the app shows localized default copy when not live.

UPDATE live_darshan
SET description = ''
WHERE TRIM(description) = 'Live darshan stream link (update via admin)';
