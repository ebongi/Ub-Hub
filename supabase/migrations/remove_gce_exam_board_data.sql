-- Undo add_gce_exam_support_columns.sql / seed_gce_exam_data.sql / add_year_to_materials.sql:
-- the GCE exam-board feature (both UI and backend) has been removed from the app.

-- 1. Clear institution_id on any profile currently pointing at a GCE
--    institution (profiles.institution_id has an FK to institutions, so
--    the institutions can't be deleted while referenced). The app already
--    handles a null institution_id gracefully — affected users just see
--    no institution selected and can pick one again.
UPDATE profiles
SET institution_id = NULL
WHERE institution_id IN (
  SELECT id FROM institutions WHERE type = 'exam_board'
);

-- 2. Delete any course materials filed under GCE departments/courses.
DELETE FROM course_materials
WHERE department_id IN (
  SELECT d.id FROM departments d
  JOIN institutions i ON i.id::text = d.school_id
  WHERE i.type = 'exam_board'
);

-- 3. Delete the GCE "papers" (courses).
DELETE FROM courses
WHERE department_id IN (
  SELECT d.id FROM departments d
  JOIN institutions i ON i.id::text = d.school_id
  WHERE i.type = 'exam_board'
);

-- 4. Delete the GCE "subjects" (departments).
DELETE FROM departments
WHERE school_id IN (
  SELECT id::text FROM institutions WHERE type = 'exam_board'
);

-- 5. Delete the GCE Ordinary/Advanced Level institutions themselves.
DELETE FROM institutions WHERE type = 'exam_board';

-- 6. Drop the now-unused exam_year column (only ever populated by the GCE upload flow).
ALTER TABLE course_materials DROP COLUMN IF EXISTS exam_year;

-- 7. Drop the now-unused institution type column (its only non-default value was 'exam_board').
ALTER TABLE institutions DROP COLUMN IF EXISTS type;
