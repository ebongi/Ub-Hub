-- Add role and upgraded_at to profiles table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'viewer';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='upgraded_at') THEN
        ALTER TABLE profiles ADD COLUMN upgraded_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Add check constraint for roles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('viewer', 'contributor', 'admin'));

-- Create index on role for faster filtering
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

COMMENT ON COLUMN profiles.role IS 'User role for access control: viewer, contributor, or admin';
