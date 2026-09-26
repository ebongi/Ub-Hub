-- News feature: admin-authored posts + student likes & comments.
-- Mirrors the structure of create_marketplace_listings.sql. Apply by hand in
-- the Supabase SQL editor (same as the repo's other migrations).
--
-- Relies on the is_admin() SECURITY DEFINER helper from
-- comprehensive_rls_policies.sql / admin_management_policies.sql.

-- ==========================================================================
-- 1. news_posts
-- ==========================================================================
CREATE TABLE IF NOT EXISTS news_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    author_name TEXT,                                  -- denormalized for display
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE news_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view published news" ON news_posts;
CREATE POLICY "Anyone can view published news" ON news_posts
    FOR SELECT USING (is_published OR is_admin());

DROP POLICY IF EXISTS "Admins can create news" ON news_posts;
CREATE POLICY "Admins can create news" ON news_posts
    FOR INSERT WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Admins can update news" ON news_posts;
CREATE POLICY "Admins can update news" ON news_posts
    FOR UPDATE USING (is_admin());

DROP POLICY IF EXISTS "Admins can delete news" ON news_posts;
CREATE POLICY "Admins can delete news" ON news_posts
    FOR DELETE USING (is_admin());

CREATE INDEX IF NOT EXISTS idx_news_posts_created_at ON news_posts (created_at DESC);

-- ==========================================================================
-- 2. news_comments
-- ==========================================================================
CREATE TABLE IF NOT EXISTS news_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES news_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    author_name TEXT,
    author_avatar_url TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE news_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view news comments" ON news_comments;
CREATE POLICY "Anyone can view news comments" ON news_comments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can add their own news comments" ON news_comments;
CREATE POLICY "Users can add their own news comments" ON news_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete own comments, admins delete any" ON news_comments;
CREATE POLICY "Users delete own comments, admins delete any" ON news_comments
    FOR DELETE USING (auth.uid() = user_id OR is_admin());

CREATE INDEX IF NOT EXISTS idx_news_comments_post ON news_comments (post_id, created_at);

-- ==========================================================================
-- 3. news_likes
-- ==========================================================================
CREATE TABLE IF NOT EXISTS news_likes (
    post_id UUID NOT NULL REFERENCES news_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

ALTER TABLE news_likes ENABLE ROW LEVEL SECURITY;

-- The client only ever needs to know which posts THIS user liked; the public
-- like tally is the trigger-maintained news_posts.like_count.
DROP POLICY IF EXISTS "Users can view their own news likes" ON news_likes;
CREATE POLICY "Users can view their own news likes" ON news_likes
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can add their own news likes" ON news_likes;
CREATE POLICY "Users can add their own news likes" ON news_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their own news likes" ON news_likes;
CREATE POLICY "Users can remove their own news likes" ON news_likes
    FOR DELETE USING (auth.uid() = user_id);

-- ==========================================================================
-- 4. Denormalized-counter + updated_at triggers (plpgsql, SECURITY DEFINER so
--    they can bump news_posts regardless of the acting user's RLS).
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.news_likes_count_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE news_posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE news_posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_news_likes_count ON news_likes;
CREATE TRIGGER trg_news_likes_count
  AFTER INSERT OR DELETE ON news_likes
  FOR EACH ROW EXECUTE FUNCTION public.news_likes_count_sync();

CREATE OR REPLACE FUNCTION public.news_comments_count_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE news_posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE news_posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_news_comments_count ON news_comments;
CREATE TRIGGER trg_news_comments_count
  AFTER INSERT OR DELETE ON news_comments
  FOR EACH ROW EXECUTE FUNCTION public.news_comments_count_sync();

CREATE OR REPLACE FUNCTION public.news_posts_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_news_posts_updated_at ON news_posts;
CREATE TRIGGER trg_news_posts_updated_at
  BEFORE UPDATE ON news_posts
  FOR EACH ROW EXECUTE FUNCTION public.news_posts_touch_updated_at();

-- ==========================================================================
-- 5. Realtime — needed by the Flutter client's .stream() subscriptions.
-- ==========================================================================
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE news_posts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE news_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE news_likes;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
