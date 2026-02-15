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
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- ==========================================
-- 3. Academic Content (Read-only for public, Write for Admin)
-- ==========================================

-- Departments
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view departments" ON departments;
CREATE POLICY "Anyone can view departments" ON departments FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage departments" ON departments;
CREATE POLICY "Admins can manage departments" ON departments FOR ALL USING (is_admin());

-- Courses
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view courses" ON courses;
CREATE POLICY "Anyone can view courses" ON courses FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
CREATE POLICY "Admins can manage courses" ON courses FOR ALL USING (is_admin());

-- Campus Locations
ALTER TABLE campus_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view locations" ON campus_locations;
CREATE POLICY "Anyone can view locations" ON campus_locations FOR SELECT USING (true);

-- University News
ALTER TABLE university_news ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view news" ON university_news;
CREATE POLICY "Anyone can view news" ON university_news FOR SELECT USING (true);

-- ==========================================
-- 4. Personal Student Data (Private to Owner)
-- ==========================================

-- Exams
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own exams" ON exams;
CREATE POLICY "Users can manage own exams" ON exams
  FOR ALL USING (auth.uid() = user_id);

-- Tasks
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own tasks" ON tasks;
CREATE POLICY "Users can manage own tasks" ON tasks
  FOR ALL USING (auth.uid() = user_id);

-- Grades
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own grades" ON grades;
CREATE POLICY "Users can manage own grades" ON grades
  FOR ALL USING (auth.uid() = user_id);

-- Payment Transactions
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own transactions" ON payment_transactions;
CREATE POLICY "Users can view own transactions" ON payment_transactions
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can initiate transactions" ON payment_transactions;
CREATE POLICY "Users can initiate transactions" ON payment_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- 5. Social & Community
-- ==========================================

-- Messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view messages" ON messages;
CREATE POLICY "Anyone can view messages" ON messages FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can send messages" ON messages;
CREATE POLICY "Authenticated users can send messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = sender_id);

-- Course Materials
-- (Note: Re-applying here to ensure consistency)
ALTER TABLE course_materials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
CREATE POLICY "Anyone can view materials" ON course_materials FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can upload" ON course_materials;
CREATE POLICY "Authenticated users can upload" ON course_materials 
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Owners can manage materials" ON course_materials;
CREATE POLICY "Owners can manage materials" ON course_materials
  FOR ALL USING (auth.uid() = uploader_id OR is_admin());

-- ==========================================
-- 6. Storage Security
-- ==========================================

-- Course Materials Storage
INSERT INTO storage.buckets (id, name, public) VALUES ('course_materials', 'course_materials', true) ON CONFLICT (id) DO NOTHING;
DROP POLICY IF EXISTS "Authenticated users can upload materials" ON storage.objects;
CREATE POLICY "Authenticated users can upload materials" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'course_materials' AND auth.role() = 'authenticated');
