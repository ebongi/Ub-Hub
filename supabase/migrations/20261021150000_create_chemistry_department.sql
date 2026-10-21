-- Creates the Chemistry department and seeds its BSc (level 200/300/400)
-- courses from the Faculty of Science's published course list
-- (https://fs.ubuea2.cm, Department of Chemistry, retrieved 2026-10-21): 43
-- courses. That list also includes the Chemical Process Technology (CPT),
-- Materials Science (MTS) and Pharmaceutical Chemistry (PCH) minor courses the
-- department teaches. Not included: the MSc (6xx) and PhD (7xx) courses, and
-- the three placeholder seminar codes CHMXX1-3, which have no level.
--
-- Titles are as published; PCH361 ("Chemistry of Medicina") appears truncated
-- on the source site, and CHM442/CHM445 share the title "Biological Organic
-- Chemistry".
--
-- Like the Mathematics/Physics seed, the department takes school_id and
-- admin_id from "Computer Science" and has no image (default UB logo).
-- Idempotent: re-running will not duplicate the department or its courses.

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

  SELECT id INTO dept_id FROM departments WHERE name = 'Chemistry' LIMIT 1;
  IF dept_id IS NULL THEN
    INSERT INTO departments (name, description, school_id, admin_id)
    VALUES ('Chemistry',
            'The Department of Chemistry teaches the central science: how matter is built, how it changes, and how to put that to work. You study general, organic, inorganic, physical and analytical chemistry, with hands-on lab training, and can branch into chemical process technology, materials science and pharmaceutical chemistry. Graduates go into secondary teaching, medical and agricultural fields, industry and postgraduate research. The department offers a BSc in Chemistry, six minors, an MSc in Chemistry, an MSc in Industrial Chemistry and a PhD.',
            v_school_id, v_admin_id)
    RETURNING id INTO dept_id;
  END IF;

  INSERT INTO courses (course_code, name, department_id, level)
  SELECT v.code, v.name, dept_id, v.level
  FROM (VALUES
    ('CHM201', 'General Chemistry', '200'),
    ('CHM234', 'Physical Chemistry', '200'),
    ('CHM242', 'Principles of Organic Chemistry', '200'),
    ('CHM244', 'General Organic Chemistry', '200'),
    ('CHM312', 'Analytical Methods in Chemistry', '300'),
    ('CHM314', 'Analytical and Instrumental Methods', '300'),
    ('CHM316', 'Spectrometric and Spectroscopic Methods', '300'),
    ('CHM325', 'Inorganic Chemistry', '300'),
    ('CHM328', 'Coordination Chemistry', '300'),
    ('CHM335', 'Symmetry and Group Theory in Chemistry', '300'),
    ('CHM343', 'Chemistry of Organic Compounds', '300'),
    ('CHM402', 'Chemistry and the Environment', '400'),
    ('CHM414', 'Methods of Instrumental Analysis', '400'),
    ('CHM416', 'Structural Analysis of Compounds', '400'),
    ('CHM424', 'Transition Metal Chemistry', '400'),
    ('CHM425', 'Inorganic Synthesis and Solid State Chemistry', '400'),
    ('CHM431', 'Chemical Kinetics', '400'),
    ('CHM433', 'Quantum Chemistry', '400'),
    ('CHM436', 'Photochemistry', '400'),
    ('CHM438', 'Chemical Thermodynamics', '400'),
    ('CHM441', 'Organic Synthesis and Reaction Mechanisms', '400'),
    ('CHM442', 'Biological Organic Chemistry', '400'),
    ('CHM445', 'Biological Organic Chemistry', '400'),
    ('CHM498', 'Integrated Practical Training and Research Project in Chemistry', '400'),
    ('CPT275', 'Process Analysis', '200'),
    ('CPT276', 'Transfer Processes', '200'),
    ('CPT375', 'Unit Operations', '300'),
    ('CPT376', 'Processes and Equipment Design', '300'),
    ('CPT475', 'Chemical Manufacturing Processes', '400'),
    ('CPT476', 'Process Safety & Project Evaluation', '400'),
    ('MTS257', 'Introduction to Materials Science', '200'),
    ('MTS258', 'Chemical Metallurgy', '200'),
    ('MTS357', 'Corrosion Science and Engineering', '300'),
    ('MTS358', 'Technology of Organic Based Materials', '300'),
    ('MTS457', 'Ceramic and Composite Materials', '400'),
    ('MTS458', 'Selection and Recycling of Materials', '400'),
    ('PCH261', 'Introduction to Chemical Toxicology', '200'),
    ('PCH262', 'Principles of Drug Action and Design', '200'),
    ('PCH361', 'Chemistry of Medicina', '300'),
    ('PCH362', 'Therapeutic Agents', '300'),
    ('PCH461', 'Pharmacokinetics and Drug Metabolism', '400'),
    ('PCH462', 'Introduction to Pharmacy and Pharmaceutical Technology', '400'),
    ('PCH464', 'Internship and Seminar in Pharmaceutical Chemistry', '400')
  ) AS v(code, name, level)
  WHERE NOT EXISTS (
    SELECT 1 FROM courses c
    WHERE c.department_id = dept_id AND c.course_code = v.code
  );
END $$;
