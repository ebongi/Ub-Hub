-- Add the Computer Science courses that appear on the CST Form B sheets
-- (Level 200 and 300) but were missing from the courses table.
-- Idempotent: re-running will not duplicate courses.

DO $$
DECLARE
  dept_id uuid;
BEGIN
  SELECT id INTO dept_id
  FROM departments
  WHERE name = 'Computer Science'
  LIMIT 1;

  IF dept_id IS NULL THEN
    RAISE EXCEPTION 'Department "Computer Science" not found.';
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, v.level
  FROM (VALUES
    ('CSC216', 'Information Systems',                '200'),
    ('CSC305', 'Object Oriented Programming in C++', '300'),
    ('CSC310', 'Database Design',                    '300'),
    ('CSC314', 'Operating Systems',                  '300')
  ) AS v(code, name, level)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );
END $$;
