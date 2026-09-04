-- Add a real "completed at" timestamp to tasks so the Weekly Progress card can
-- report tasks completed *on* a given day (previously only deadline + is_done
-- were stored, so completion could only be approximated by the deadline day).

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- Best-effort backfill so historical done tasks don't all read as "missed":
-- attribute completion to the deadline day (matching the previous
-- derive-by-deadline behaviour), falling back to created_at, then now().
UPDATE tasks
SET completed_at = COALESCE(deadline, created_at, now())
WHERE is_done = true AND completed_at IS NULL;
