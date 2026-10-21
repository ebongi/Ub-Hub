-- Seed the university-wide mandatory courses ("Special University
-- Requirements", status UC, 2 credits each) under a "General Studies"
-- department.
--
-- Prerequisite: create the department first (admin > Add Department) with the
-- exact name "General Studies".
-- These are taken every semester by students of every department, so no
-- semester is set. Level is 100 to match the course codes.
-- Idempotent: re-running will not duplicate courses.

DO $$
DECLARE
  dept_id uuid;
BEGIN
  SELECT id INTO dept_id
  FROM departments
  WHERE name = 'General Studies'
  LIMIT 1;

  IF dept_id IS NULL THEN
    RAISE EXCEPTION 'Department "General Studies" not found. Create it first.';
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, '100'
  FROM (VALUES
    ('ICT100', 'Computer for Business'),
    ('LAW100', 'Legal Aspects of Business'),
    ('ENT100', 'Entrepreneurship'),
    ('ENG100', 'Use of English'),
    ('FRE100', 'Functional French'),
    ('SPT100', 'Sports'),
    ('CVE100', 'Civics and Ethics')
  ) AS v(code, name)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );
END $$;
