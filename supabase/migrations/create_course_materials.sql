-- 1. Create course_materials table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    material_category TEXT NOT NULL DEFAULT 'regular',
    is_past_question BOOLEAN NOT NULL DEFAULT FALSE,
    is_answer BOOLEAN NOT NULL DEFAULT FALSE,
    linked_material_id UUID REFERENCES course_materials(id) ON DELETE SET NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure either course_id or department_id is provided
    CONSTRAINT course_or_department_required CHECK (course_id IS NOT NULL OR department_id IS NOT NULL)
);

-- 2. Add uploader_id column if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='course_materials' AND column_name='uploader_id') THEN
        ALTER TABLE course_materials ADD COLUMN uploader_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 3. Enable RLS
ALTER TABLE course_materials ENABLE ROW LEVEL SECURITY;

-- 4. Policies (Idempotent)
DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
CREATE POLICY "Anyone can view materials" ON course_materials FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Authenticated users can upload materials" ON course_materials;
CREATE POLICY "Authenticated users can upload materials" ON course_materials FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update their own materials" ON course_materials;
CREATE POLICY "Users can update their own materials" ON course_materials FOR UPDATE USING (auth.uid() = uploader_id);

DROP POLICY IF EXISTS "Users can delete their own materials" ON course_materials;
CREATE POLICY "Users can delete their own materials" ON course_materials FOR DELETE USING (auth.uid() = uploader_id);
