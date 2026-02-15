-- Comprehensive Row Level Security (RLS) Policies for Ub-Hub

-- ==========================================
-- 1. Helper Functions for Role Management
-- ==========================================

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT (role = 'admin')
    FROM profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user is a contributor
CREATE OR REPLACE FUNCTION public.is_contributor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT (role IN ('contributor', 'admin'))
    FROM profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 2. Profiles Table
-- ==========================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'profiles') THEN
    ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
    CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
    DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
    CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
  END IF;
END $$;

-- ==========================================
-- 3. Academic Content (Read-only for public, Write for Admin)
-- ==========================================

-- Departments
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'departments') THEN
    ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view departments" ON departments;
    CREATE POLICY "Anyone can view departments" ON departments FOR SELECT USING (true);
    DROP POLICY IF EXISTS "Admins can manage departments" ON departments;
    CREATE POLICY "Admins can manage departments" ON departments FOR ALL USING (is_admin());
  END IF;
END $$;

-- Courses
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'courses') THEN
    ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view courses" ON courses;
    CREATE POLICY "Anyone can view courses" ON courses FOR SELECT USING (true);
    DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
    CREATE POLICY "Admins can manage courses" ON courses FOR ALL USING (is_admin());
  END IF;
END $$;

-- Campus Locations
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'campus_locations') THEN
    ALTER TABLE campus_locations ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view locations" ON campus_locations;
    CREATE POLICY "Anyone can view locations" ON campus_locations FOR SELECT USING (true);
  END IF;
END $$;

-- University News
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'university_news') THEN
    ALTER TABLE university_news ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view news" ON university_news;
    CREATE POLICY "Anyone can view news" ON university_news FOR SELECT USING (true);
  END IF;
END $$;

-- ==========================================
-- 4. Personal Student Data (Private to Owner)
-- ==========================================

-- Exams
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'exams') THEN
    ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can manage own exams" ON exams;
    CREATE POLICY "Users can manage own exams" ON exams FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- Tasks
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
    ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can manage own tasks" ON tasks;
    CREATE POLICY "Users can manage own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- Grades
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'grades') THEN
    ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can manage own grades" ON grades;
    CREATE POLICY "Users can manage own grades" ON grades FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- Payment Transactions
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payment_transactions') THEN
    ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can view own transactions" ON payment_transactions;
    CREATE POLICY "Users can view own transactions" ON payment_transactions FOR SELECT USING (auth.uid() = user_id);
    DROP POLICY IF EXISTS "Users can initiate transactions" ON payment_transactions;
    CREATE POLICY "Users can initiate transactions" ON payment_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==========================================
-- 5. Social & Community
-- ==========================================

-- Messages
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'messages') THEN
    ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view messages" ON messages;
    CREATE POLICY "Anyone can view messages" ON messages FOR SELECT USING (true);
    DROP POLICY IF EXISTS "Authenticated users can send messages" ON messages;
    CREATE POLICY "Authenticated users can send messages" ON messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = sender_id);
  END IF;
END $$;

-- Course Materials
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'course_materials') THEN
    ALTER TABLE course_materials ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
    CREATE POLICY "Anyone can view materials" ON course_materials FOR SELECT USING (true);
    DROP POLICY IF EXISTS "Authenticated users can upload" ON course_materials;
    CREATE POLICY "Authenticated users can upload" ON course_materials FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    DROP POLICY IF EXISTS "Owners can manage materials" ON course_materials;
    CREATE POLICY "Owners can manage materials" ON course_materials FOR ALL USING (auth.uid() = uploader_id OR is_admin());
  END IF;
END $$;

-- ==========================================
-- 6. Storage Security
-- ==========================================

-- Course Materials Storage
INSERT INTO storage.buckets (id, name, public) VALUES ('course_materials', 'course_materials', true) ON CONFLICT (id) DO NOTHING;
DROP POLICY IF EXISTS "Authenticated users can upload materials" ON storage.objects;
CREATE POLICY "Authenticated users can upload materials" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'course_materials' AND auth.role() = 'authenticated');
