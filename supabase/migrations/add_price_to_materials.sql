-- Add price column to course_materials table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='course_materials' AND column_name='price') THEN
        ALTER TABLE course_materials ADD COLUMN price NUMERIC DEFAULT 0;
    END IF;
END $$;

-- Relax constraint to allow materials without course or department (e.g. general marketplace items)
ALTER TABLE course_materials DROP CONSTRAINT IF EXISTS course_or_department_required;

-- Add comment for clarity
COMMENT ON COLUMN course_materials.price IS 'Price of the material in XAF. 0 means institution default fees apply or free if specified.';
