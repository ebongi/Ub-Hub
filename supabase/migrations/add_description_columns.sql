-- Add description support to institutions and courses.

ALTER TABLE institutions ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS description TEXT;
