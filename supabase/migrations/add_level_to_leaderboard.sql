-- Adds each student's academic level (profiles.level, e.g. "300 Level") to
-- the leaderboard RPCs' output, so the Global tab can show it (useful there
-- since entries span every level; redundant on the Level-scoped tab where
-- everyone already shares the caller's level).
--
-- Postgres won't let CREATE OR REPLACE FUNCTION change a function's return
-- column list, so both functions are dropped and recreated. Drop the
-- dependent one (get_my_leaderboard_position, which selects * from
-- get_leaderboard) first.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

DROP FUNCTION IF EXISTS public.get_my_leaderboard_position(TEXT);
DROP FUNCTION IF EXISTS public.get_leaderboard(TEXT, INT, INT);

CREATE FUNCTION public.get_leaderboard(p_scope TEXT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
  user_id UUID,
  name TEXT,
  avatar_url TEXT,
  level TEXT,
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
    SELECT p.id AS pool_id, p.name AS pool_name, p.avatar_url AS pool_avatar_url,
           p.level AS pool_level, p.total_points AS pool_total_points
    FROM profiles p
    WHERE p_scope = 'global'
       OR (p_scope = 'level' AND p.level IS NOT DISTINCT FROM v_level)
  ),
  now_ranked AS (
    SELECT pool_id, pool_name, pool_avatar_url, pool_level, pool_total_points,
           RANK() OVER (ORDER BY pool_total_points DESC) AS rnk
    FROM pool
  ),
  past_points AS (
    SELECT pl_pool.pool_id AS pp_id,
           pl_pool.pool_total_points - COALESCE(SUM(pl.points) FILTER (WHERE pl.created_at >= v_yesterday), 0) AS points_yesterday
    FROM pool pl_pool
    LEFT JOIN points_ledger pl ON pl.user_id = pl_pool.pool_id
    GROUP BY pl_pool.pool_id, pl_pool.pool_total_points
  ),
  past_ranked AS (
    SELECT pp_id, RANK() OVER (ORDER BY points_yesterday DESC) AS rnk
    FROM past_points
  )
  SELECT n.pool_id, n.pool_name, n.pool_avatar_url, n.pool_level, n.pool_total_points, n.rnk,
         CASE
           WHEN pr.rnk IS NULL OR pr.rnk = n.rnk THEN 'flat'
           WHEN pr.rnk > n.rnk THEN 'up'
           ELSE 'down'
         END
  FROM now_ranked n
  LEFT JOIN past_ranked pr ON pr.pp_id = n.pool_id
  ORDER BY n.rnk, n.pool_name
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, INT, INT) TO authenticated;

CREATE FUNCTION public.get_my_leaderboard_position(p_scope TEXT)
RETURNS TABLE (
  user_id UUID,
  name TEXT,
  avatar_url TEXT,
  level TEXT,
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
