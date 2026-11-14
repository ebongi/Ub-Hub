-- Seed the CST-owned courses (Level 200 and 300) for the
-- "Curriculum Studies and Teaching" department.
--
-- Prerequisite: create the department first (admin > Add Department) with the
-- exact name "Curriculum Studies and Teaching". Cross-department courses
-- (CSC*, EFA*, EPY*) are intentionally NOT included here.
-- Idempotent: re-running will not duplicate courses.

DO $$
DECLARE
  dept_id uuid;
BEGIN
  SELECT id INTO dept_id
  FROM departments
  WHERE name = 'Curriculum Studies and Teaching'
  LIMIT 1;

  IF dept_id IS NULL THEN
    RAISE EXCEPTION 'Department "Curriculum Studies and Teaching" not found. Create it first.';
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, v.level
  FROM (VALUES
    -- Level 200
    ('CST203', 'Introduction to Curriculum Studies',                '200'),
    ('CST205', 'Principles and Practice of Teaching',               '200'),
    ('CST202', 'General Pedagogy',                                  '200'),
    -- Level 300
    ('CST305', 'Introduction to Educational Technology',            '300'),
    ('CST315', 'Introduction to Research Methods in Education',     '300'),
    ('CST317', 'Subject Methods',                                   '300'),
    ('CST304', 'Curriculum Development Process',                    '300'),
    ('CST306', 'Teaching Practice I',                               '300'),
    ('CST318', 'Introduction to Statistical Methods in Education',  '300')
  ) AS v(code, name, level)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );
END $$;
