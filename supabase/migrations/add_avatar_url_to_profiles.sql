-- Add avatar_url column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Create avatars storage bucket if it doesn't exist
-- This ensures the 'avatars' bucket is available for profile pictures
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for avatars
-- 1. Allow public access to view avatars
CREATE POLICY "Public Avatar Access" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- 2. Allow authenticated users to upload their own avatar
-- We use a simple policy here; in production you might want to restrict by path (e.g., bucket_id/auth.uid()) or filename
CREATE POLICY "Authenticated User Upload Avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- 3. Allow users to update their own avatar
CREATE POLICY "Users Update Own Avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid() = (storage.foldername(name))[1]::uuid);
