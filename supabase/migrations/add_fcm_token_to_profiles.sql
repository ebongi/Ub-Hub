-- Add fcm_token column to profiles for Firebase Cloud Messaging push notifications.
-- This token is saved by the Flutter app on every launch (NotificationService._saveTokenToSupabase)
-- and is used by the send-push-notification Edge Function to deliver background pushes.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index speeds up the IN-lookup the Edge Function performs when fetching tokens
-- for a batch of recipient user IDs.
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token
  ON profiles (fcm_token)
  WHERE fcm_token IS NOT NULL;

-- Allow the owner to update their own fcm_token (needed by the Flutter client
-- which calls the update through the anon/authenticated Supabase client).
-- The existing RLS on profiles already allows users to update their own row,
-- so no new policy is strictly needed — but document the intent here.
COMMENT ON COLUMN profiles.fcm_token IS
  'Firebase Cloud Messaging device token. Saved on app launch, used to send push notifications to background/terminated devices.';
