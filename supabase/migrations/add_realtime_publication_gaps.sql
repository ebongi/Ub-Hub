-- ==========================================================================
-- Realtime — several tables' `.stream()` subscriptions in the Flutter client
-- (DatabaseService: tasks, exams, departments, courses, course_materials,
-- marketplace_listings, bot_knowledge) were never added to the
-- supabase_realtime publication. supabase_flutter's `.stream()` does an
-- initial REST fetch and then subscribes to realtime postgres_changes; with
-- the table missing from the publication, inserts/updates/deletes never
-- reach the client, and the UI only shows fresh data after the widget is
-- torn down and rebuilt (e.g. navigating away and back). This mirrors the
-- fix already applied to flashcard_decks/news_posts/news_comments/news_likes
-- in create_flashcards.sql and create_news_posts.sql.
--
-- Note: `grades` is deliberately omitted — no such table exists in the
-- database yet (the grade-tracking feature's table was never created), so
-- ALTER PUBLICATION ... ADD TABLE grades errors out. That's a separate,
-- pre-existing bug, not a realtime-publication gap.
-- ==========================================================================

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE exams;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE departments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE courses;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE course_materials;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE marketplace_listings;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE bot_knowledge;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
