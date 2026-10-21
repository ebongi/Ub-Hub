-- Creates the Mathematics and Physics departments and seeds their BSc
-- (level 200/300/400) courses, taken from the Faculty of Science's published
-- course lists (https://fs.ubuea2.cm, department pages, retrieved 2026-10-21):
-- Mathematics MAT201-MAT498 (38 courses), Physics PHY2xx-PHY498 plus the
-- Electronics courses ELT201-ELT498 that the Physics department teaches (46).
-- MSc (6xx) and PhD (7xx) courses are intentionally not included.
--
-- The new departments take school_id and admin_id from the existing
-- "Computer Science" department, so they sit under the same school and the
-- same admin can manage them. Department images are left NULL, so cards show
-- the default University of Buea logo.
--
-- Idempotent: re-running will not duplicate departments or courses.

DO $$
DECLARE
  v_school_id text;
  v_admin_id uuid;
  dept_id uuid;
BEGIN
  SELECT school_id, admin_id INTO v_school_id, v_admin_id
  FROM departments
  WHERE name = 'Computer Science'
  LIMIT 1;

  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'Department "Computer Science" not found; cannot copy school_id.';
  END IF;

  -- Mathematics (38 courses)
  SELECT id INTO dept_id FROM departments WHERE name = 'Mathematics' LIMIT 1;
  IF dept_id IS NULL THEN
    INSERT INTO departments (name, description, school_id, admin_id)
    VALUES ('Mathematics',
            'The Department of Mathematics gives you the tools and the way of thinking behind almost every quantitative field. From calculus and algebra to analysis, probability, differential equations and numerical methods, you learn to build rigorous arguments and to model real problems. Graduates go on to teaching, research, IT, banking and insurance, statistics and management. The department offers a BSc in Mathematics, minors in Pure Mathematics and Mathematical Statistics, an MSc and a PhD.',
            v_school_id, v_admin_id)
    RETURNING id INTO dept_id;
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, v.level
  FROM (VALUES
    ('MAT201', 'Calculus I', '200'),
    ('MAT202', 'Calculus II', '200'),
    ('MAT203', 'Abstract Algebra', '200'),
    ('MAT204', 'Linear Methods', '200'),
    ('MAT207', 'Mathematical Methods IA', '200'),
    ('MAT208', 'Mathematical Methods IIA', '200'),
    ('MAT211', 'Mathematical Methods', '200'),
    ('MAT301', 'Analysis I', '300'),
    ('MAT302', 'Analysis II', '300'),
    ('MAT303', 'Linear Algebra I', '300'),
    ('MAT304', 'Linear Algebra II', '300'),
    ('MAT305', 'Mathematical Probability I', '300'),
    ('MAT306', 'Introduction to Mathematical Statistics', '300'),
    ('MAT307', 'Introduction to Differential Equations', '300'),
    ('MAT310', 'Mathematical Methods III', '300'),
    ('MAT311', 'Analytical Mechanics', '300'),
    ('MAT312', 'Electromagnetism', '300'),
    ('MAT314', 'Analytic Geometry', '300'),
    ('MAT401', 'Analysis III', '400'),
    ('MAT402', 'General Topology', '400'),
    ('MAT403', 'Set Theory', '400'),
    ('MAT404', 'Group Theory', '400'),
    ('MAT406', 'Mathematical Probability II', '400'),
    ('MAT407', 'Complex Analysis I', '400'),
    ('MAT409', 'Ordinary Differential Equations', '400'),
    ('MAT411', 'Analytical Dynamics', '400'),
    ('MAT412', 'Hydromechanics', '400'),
    ('MAT413', 'Affine and Projective Geometry', '400'),
    ('MAT415', 'Differential Geometry', '400'),
    ('MAT416', 'Measure Theory and Integration', '400'),
    ('MAT417', 'Calculus of Variations', '400'),
    ('MAT418', 'Numerical Methods', '400'),
    ('MAT419', 'Elements of Stochastic Processes', '400'),
    ('MAT420', 'Elements of Queuing Theory', '400'),
    ('MAT421', 'Multivariate Statistics', '400'),
    ('MAT422', 'Introduction to Optimization', '400'),
    ('MAT423', 'Combinatorics and Graph Theory', '400'),
    ('MAT498', 'Research Project', '400')
  ) AS v(code, name, level)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );

  -- Physics (46 courses)
  SELECT id INTO dept_id FROM departments WHERE name = 'Physics' LIMIT 1;
  IF dept_id IS NULL THEN
    INSERT INTO departments (name, description, school_id, admin_id)
    VALUES ('Physics',
            'The Department of Physics trains physicists and applied scientists for Cameroon''s needs, with solid grounding in mechanics, electricity and magnetism, waves and optics, thermal and quantum physics, backed by practical lab work. Electronics courses (ELT) are taught here too, covering digital and analogue electronics, communication systems and signal processing. The department offers a BSc in Physics, a BSc in Applied Physics, minors in Physics and Electronics, an MSc and a PhD.',
            v_school_id, v_admin_id)
    RETURNING id INTO dept_id;
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, v.level
  FROM (VALUES
    ('PHY202', 'Mechanics I', '200'),
    ('PHY205', 'Thermodynamics and Structure of Matter', '200'),
    ('PHY207', 'Mathematical Methods for Physics I', '200'),
    ('PHY208', 'Electricity and Magnetism I', '200'),
    ('PHY211', 'Waves and Optics I', '200'),
    ('PHY212', 'General Physics', '200'),
    ('PHY215', 'Basic Concepts of Waves and Optics', '200'),
    ('PHY218', 'Principles of Electricity and Magnetism', '200'),
    ('PHY220', 'General Physics', '200'),
    ('ELT201', 'Electronic Devices', '200'),
    ('ELT204', 'Analogue Electronics and Basic Circuit Analysis', '200'),
    ('PHY301', 'Mechanics II', '300'),
    ('PHY305', 'Electricity and Magnetism II', '300'),
    ('PHY306', 'Mathematical Methods of Physics II', '300'),
    ('PHY308', 'Quantum Mechanics I', '300'),
    ('PHY311', 'General Physics IIA', '300'),
    ('PHY312', 'Thermal Physics', '300'),
    ('PHY314', 'Special Relativity', '300'),
    ('PHY317', 'Electronics I', '300'),
    ('ELT301', 'Digital Electronics', '300'),
    ('ELT302', 'Microprocessors', '300'),
    ('ELT303', 'Applied Electronics and Workshop Practice', '300'),
    ('ELT304', 'Digital Design Laboratory', '300'),
    ('ELT307', 'RF and Microwave Systems', '300'),
    ('PHY405', 'Solid State Physics', '400'),
    ('PHY406', 'Atomic and Nuclear Physics', '400'),
    ('PHY410', 'Quantum Mechanics II', '400'),
    ('PHY411', 'Electrodynamics', '400'),
    ('PHY412', 'Waves and Optics II', '400'),
    ('PHY417', 'Introduction to General Relativity and Cosmology', '400'),
    ('PHY419', 'Introduction to Geophysics', '400'),
    ('PHY420', 'Introduction to Statistical Physics and Applications', '400'),
    ('PHY422', 'Electronics II', '400'),
    ('PHY424', 'Introduction to Fluid Mechanics', '400'),
    ('PHY498', 'Physics Project', '400'),
    ('ELT401', 'Power Electronics', '400'),
    ('ELT402', 'Communication Systems', '400'),
    ('ELT403', 'Analogue Integrated Circuits', '400'),
    ('ELT404', 'Introduction to Control Systems', '400'),
    ('ELT406', 'Digital Signal Processing', '400'),
    ('ELT408', 'Introduction to Physical Design and Integrated Circuits', '400'),
    ('ELT410', 'Signal and Systems', '400'),
    ('ELT412', 'Computer Architecture and Data Networks', '400'),
    ('ELT426', 'Analogue Integrated Circuits Laboratory', '400'),
    ('ELT491', 'Professional Internship', '400'),
    ('ELT498', 'Project', '400')
  ) AS v(code, name, level)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );

END $$;
