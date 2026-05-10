-- Migrations to support Admin User Management and secure roles

-- 1. Helper function is already defined in comprehensive_rls_policies.sql, 
-- but we ensure it exists and is up to date.
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

-- 2. Update Profiles RLS Policies
-- We need to ensure that:
--   a) Users can update their own data BUT NOT their own role.
--   b) Admins can update any user's role.

-- First, drop existing update policies
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile or Admin can update all" ON profiles;

-- Policy: Users can update their own profile (excluding role change)
-- Note: RLS doesn't easily restrict specific columns, so we use a trigger for that below.
-- For now, we allow update if it's the owner OR an admin.
CREATE POLICY "Users can update own profile or Admin can update all" 
ON profiles 
FOR UPDATE 
USING (auth.uid() = id OR is_admin())
WITH CHECK (auth.uid() = id OR is_admin());

-- 3. Security Trigger to prevent non-admins from changing roles
CREATE OR REPLACE FUNCTION public.handle_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If role is being changed and the performing user is NOT an admin
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT is_admin() THEN
    -- Keep the old role
    NEW.role := OLD.role;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_update ON profiles;
CREATE TRIGGER on_profile_update
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_profile_update();

-- 4. Ensure Admin can search all profiles (already allowed by "Public profiles are viewable by everyone")
-- But we can add a more explicit one if privacy levels change later.

-- 5. Notifications Table Policies
-- Allow users to see their own notifications and Admins to create notifications for others.
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
    ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
    
    -- standard policy: users see their own
    DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
    CREATE POLICY "Users can view own notifications" ON notifications 
    FOR SELECT USING (auth.uid() = user_id);

    -- Allow authenticated users to create notifications for themselves (default behavior)
    DROP POLICY IF EXISTS "Users can create own notifications" ON notifications;
    CREATE POLICY "Users can create own notifications" ON notifications 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

    -- NEW: Allow Admins to create notifications for any user
    DROP POLICY IF EXISTS "Admins can create notifications for anyone" ON notifications;
    CREATE POLICY "Admins can create notifications for anyone" ON notifications 
    FOR INSERT WITH CHECK (is_admin());
  END IF;
END $$;
