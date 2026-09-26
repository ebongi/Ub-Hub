-- Points, levels & leaderboard. Apply by hand in the Supabase SQL editor
-- (same as the repo's other migrations).
--
-- Points are only ever earned through the award_points() RPC below, which
-- computes the point value itself from a fixed allow-list and enforces a
-- daily cap per event type — the client reports what happened (a score, a
-- mastered-card count) but never the point value, and points_ledger has no
-- INSERT/UPDATE/DELETE policy for `authenticated` at all, so the only way a
-- row is ever created is through this SECURITY DEFINER function. This
-- mirrors the write-lockdown approach used for payment_transactions in
-- harden_subscription_and_payment_writes.sql.

-- ==========================================================================
-- 1. points_ledger — append-only log of every awarded event.
-- ==========================================================================
CREATE TABLE IF NOT EXISTS points_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    points INTEGER NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE points_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own points ledger" ON points_ledger;
CREATE POLICY "Users can view their own points ledger" ON points_ledger
    FOR SELECT USING (auth.uid() = user_id);

-- Deliberately no INSERT/UPDATE/DELETE policy for `authenticated` — rows are
-- only ever written by award_points() (SECURITY DEFINER, runs as owner).

CREATE INDEX IF NOT EXISTS idx_points_ledger_user_event_time
    ON points_ledger (user_id, event_type, created_at DESC);

-- ==========================================================================
-- 2. profiles.total_points — denormalized running total, trigger-synced from
--    points_ledger (same pattern as news_posts.like_count/comment_count in
--    create_news_posts.sql).
-- ==========================================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_points INTEGER NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.points_ledger_total_sync()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET total_points = total_points + NEW.points WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_points_ledger_total_sync ON points_ledger;
CREATE TRIGGER trg_points_ledger_total_sync
  AFTER INSERT ON points_ledger
  FOR EACH ROW EXECUTE FUNCTION public.points_ledger_total_sync();

-- ==========================================================================
-- 3. award_points — the only way to earn points. p_metadata carries what the
--    client observed (a score, a mastered-card count); the point VALUE for
--    each event_type is always computed here, never trusted from the
--    client. Returns the points actually awarded (0 if today's cap for that
--    event_type was already hit), so the client can call this optimistically
--    right after completing an action with no cap-tracking of its own.
--
--    Note: a client could still misreport *what happened* (e.g. claim a
--    100% quiz score it didn't earn) — there is no separate quiz-attempt
--    ledger to check against. Given the stakes here (engagement points on a
--    study app, not the payment/subscription paths this repo has hardened
--    elsewhere), bounding the values and capping event frequency is judged
--    a sufficient anti-grind measure.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.award_points(p_event_type TEXT, p_metadata JSONB DEFAULT '{}'::jsonb)
RETURNS INT AS $$
DECLARE
  v_points INT;
  v_daily_cap INT;
  v_today_count INT;
  v_today_start TIMESTAMPTZ := date_trunc('day', now());
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  CASE p_event_type
    WHEN 'quiz_completed' THEN
      v_points := GREATEST(0, LEAST(100, ROUND(COALESCE((p_metadata->>'score_percentage')::NUMERIC, 0))::INT));
      v_daily_cap := 3;
    WHEN 'flashcards_studied' THEN
      v_points := LEAST(50, GREATEST(0, COALESCE((p_metadata->>'mastered_count')::INT, 0))) * 2;
      v_daily_cap := 3;
    WHEN 'task_completed' THEN
      v_points := 5;
      v_daily_cap := 10;
    WHEN 'material_uploaded' THEN
      v_points := 50;
      v_daily_cap := 5;
    WHEN 'daily_login' THEN
      v_points := 10;
      v_daily_cap := 1;
    ELSE
      RAISE EXCEPTION 'Unknown event_type: %', p_event_type;
  END CASE;

  SELECT COUNT(*) INTO v_today_count
    FROM points_ledger
   WHERE user_id = auth.uid()
     AND event_type = p_event_type
     AND created_at >= v_today_start;

  IF v_today_count >= v_daily_cap THEN
    RETURN 0;
  END IF;

  INSERT INTO points_ledger (user_id, event_type, points, metadata)
  VALUES (auth.uid(), p_event_type, v_points, p_metadata);

  RETURN v_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.award_points(TEXT, JSONB) TO authenticated;

-- ==========================================================================
-- 4. get_leaderboard — SECURITY DEFINER so it can read every profile's
--    name/avatar/total_points regardless of the caller's own RLS, but only
--    ever returns this narrow, non-sensitive column set (never full profile
--    rows). p_scope is 'level' (same academic level as the caller, e.g.
--    "300 Level" — profiles.level, the existing free-text field already
--    shown as "Current Level" on the Profile screen) or 'global' (everyone).
--
--    trend compares each user's current rank to their rank as of ~24h ago,
--    computed on the fly from points_ledger (today's total minus points
--    earned in the last 24h) — no separate snapshot table or cron job.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.get_leaderboard(p_scope TEXT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
  user_id UUID,
  name TEXT,
  avatar_url TEXT,
  total_points INT,
  rank BIGINT,
  trend TEXT
) AS $$
DECLARE
  v_level TEXT;
  v_yesterday TIMESTAMPTZ := now() - INTERVAL '1 day';
BEGIN
  IF p_scope NOT IN ('level', 'global') THEN
    RAISE EXCEPTION 'Unknown scope: %', p_scope;
  END IF;

  IF p_scope = 'level' THEN
    SELECT p.level INTO v_level FROM profiles p WHERE p.id = auth.uid();
  END IF;

  RETURN QUERY
  WITH pool AS (
    SELECT p.id, p.name, p.avatar_url, p.total_points
    FROM profiles p
    WHERE p_scope = 'global'
       OR (p_scope = 'level' AND p.level IS NOT DISTINCT FROM v_level)
  ),
  now_ranked AS (
    SELECT id, name, avatar_url, total_points,
           RANK() OVER (ORDER BY total_points DESC) AS rnk
    FROM pool
  ),
  past_points AS (
    SELECT pl_pool.id,
           pl_pool.total_points - COALESCE(SUM(pl.points) FILTER (WHERE pl.created_at >= v_yesterday), 0) AS points_yesterday
    FROM pool pl_pool
    LEFT JOIN points_ledger pl ON pl.user_id = pl_pool.id
    GROUP BY pl_pool.id, pl_pool.total_points
  ),
  past_ranked AS (
    SELECT id, RANK() OVER (ORDER BY points_yesterday DESC) AS rnk
    FROM past_points
  )
  SELECT n.id, n.name, n.avatar_url, n.total_points, n.rnk,
         CASE
           WHEN pr.rnk IS NULL OR pr.rnk = n.rnk THEN 'flat'
           WHEN pr.rnk > n.rnk THEN 'up'
           ELSE 'down'
         END
  FROM now_ranked n
  LEFT JOIN past_ranked pr ON pr.id = n.id
  ORDER BY n.rnk, n.name
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, INT, INT) TO authenticated;

-- ==========================================================================
-- 5. get_my_leaderboard_position — the caller's own row+rank, for a
--    lightweight "Your Rank" summary without fetching a whole page. Reuses
--    get_leaderboard's ranking logic rather than duplicating it.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.get_my_leaderboard_position(p_scope TEXT)
RETURNS TABLE (
  user_id UUID,
  name TEXT,
  avatar_url TEXT,
  total_points INT,
  rank BIGINT,
  trend TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.get_leaderboard(p_scope, 1000000, 0) lb
  WHERE lb.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_my_leaderboard_position(TEXT) TO authenticated;
