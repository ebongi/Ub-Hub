-- Fixes a bug in get_leaderboard() from create_points_and_leaderboard.sql:
-- RETURNS TABLE's output columns (user_id, name, avatar_url, total_points,
-- rank, trend) become PL/pgSQL variables in scope for the whole function
-- body, so the CTEs' bare `name`/`avatar_url`/`total_points` column
-- references collided with those variables — Postgres refused to run the
-- query at all ("column reference \"name\" is ambiguous"), which is why
-- the leaderboard screen showed "Couldn't load the leaderboard" for every
-- scope. Fix: give every CTE column a name that can't collide with an
-- OUT-parameter name, and qualify every reference.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

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
    SELECT p.id AS pool_id, p.name AS pool_name, p.avatar_url AS pool_avatar_url, p.total_points AS pool_total_points
    FROM profiles p
    WHERE p_scope = 'global'
       OR (p_scope = 'level' AND p.level IS NOT DISTINCT FROM v_level)
  ),
  now_ranked AS (
    SELECT pool_id, pool_name, pool_avatar_url, pool_total_points,
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
  SELECT n.pool_id, n.pool_name, n.pool_avatar_url, n.pool_total_points, n.rnk,
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
