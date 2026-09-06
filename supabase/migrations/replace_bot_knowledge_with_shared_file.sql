-- Replaces the per-user bot_knowledge table with a single shared knowledge
-- document in Supabase Storage that every user's Support Bot chat reads
-- identically. The old table had a real RLS gap flagged in code review:
-- the consolidated policy's USING clause (`auth.uid() = user_id OR
-- is_global = true`) governed DELETE as well as SELECT/UPDATE, so any
-- signed-in user could delete admin-curated global entries even though
-- WITH CHECK correctly restricted who could *create* them. Rather than
-- patch that policy, this migration removes the whole per-row/global
-- model in favor of what the product actually wants: one shared knowledge
-- base, not a mix of personal notes and admin-flagged global ones.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

DROP TABLE IF EXISTS bot_knowledge;

-- Public bucket (matches course_materials/department_images) — the
-- content itself is general, non-sensitive university FAQ knowledge, and
-- a public bucket means the client can read it with a plain fetch, same
-- as those other buckets.
INSERT INTO storage.buckets (id, name, public)
VALUES ('bot_knowledge', 'bot_knowledge', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Admins can upload bot knowledge" ON storage.objects;
CREATE POLICY "Admins can upload bot knowledge" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'bot_knowledge' AND is_admin());

DROP POLICY IF EXISTS "Admins can update bot knowledge" ON storage.objects;
CREATE POLICY "Admins can update bot knowledge" ON storage.objects
  FOR UPDATE USING (bucket_id = 'bot_knowledge' AND is_admin());

DROP POLICY IF EXISTS "Admins can delete bot knowledge" ON storage.objects;
CREATE POLICY "Admins can delete bot knowledge" ON storage.objects
  FOR DELETE USING (bucket_id = 'bot_knowledge' AND is_admin());
