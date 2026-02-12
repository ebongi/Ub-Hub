-- Add sender_avatar_url column to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS sender_avatar_url TEXT;
