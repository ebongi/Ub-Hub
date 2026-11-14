-- Hardens award_points() now that points can be redeemed for paid plans
-- (redeem_points_for_plan), which gives farming them a monetary payoff.
-- Apply by hand in the Supabase SQL editor, like every other migration.
--
-- Changes vs. scale_quiz_points_by_difficulty.sql (the previous definition):
--  1. "Today" is campus time (Africa/Douala), not the database's UTC day.
--  2. task_completed only pays if the caller really has more tasks marked
--     done today (tasks.completed_at) than events already awarded today.
--  3. material_uploaded only pays if the caller has more auto-published,
--     un-moderated materials than material_uploaded events ever awarded
--     (moderated ones are paid by moderate_material() as material_approved).
--  4. A global daily ceiling (v_daily_total_cap) on points earned through
--     this function, bounding what the unverifiable client-reported events
--     (quiz score, flashcards mastered) can yield per day. Tune as needed.
--
-- Residual risk: quiz_completed / flashcards_studied still trust the
-- client-reported score / count (there is no server-side attempt record to
-- verify against); the ceiling above bounds that rather than removing it.

CREATE OR REPLACE FUNCTION public.award_points(p_event_type TEXT, p_metadata JSONB DEFAULT '{}'::jsonb)
RETURNS INT AS $$
DECLARE
  v_points INT;
  v_daily_cap INT;
  v_today_count INT;
  v_today_start TIMESTAMPTZ :=
    date_trunc('day', now() AT TIME ZONE 'Africa/Douala') AT TIME ZONE 'Africa/Douala';
  v_quiz_multiplier NUMERIC;
  v_quiz_cap INT;
  v_daily_total_cap CONSTANT INT := 300;
  v_today_total INT;
  v_verified INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  CASE p_event_type
    WHEN 'quiz_completed' THEN
      v_quiz_multiplier := CASE COALESCE(p_metadata->>'difficulty', 'intermediate')
        WHEN 'low' THEN 0.7
        WHEN 'advanced' THEN 1.5
        ELSE 1.0
      END;
      v_quiz_cap := ROUND(100 * v_quiz_multiplier)::INT;
      v_points := GREATEST(0, LEAST(v_quiz_cap,
        ROUND(COALESCE((p_metadata->>'score_percentage')::NUMERIC, 0) * v_quiz_multiplier)::INT));
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

  -- Serialize this user's awards so concurrent calls can't all pass the
  -- cap/verification checks below before any of them inserts.
  PERFORM 1 FROM profiles WHERE id = auth.uid() FOR UPDATE;

  SELECT COUNT(*) INTO v_today_count
    FROM points_ledger
   WHERE user_id = auth.uid()
     AND event_type = p_event_type
     AND created_at >= v_today_start;

  IF v_today_count >= v_daily_cap THEN
    RETURN 0;
  END IF;

  IF p_event_type = 'task_completed' THEN
    SELECT COUNT(*) INTO v_verified
      FROM tasks
     WHERE user_id = auth.uid()
       AND is_done = true
       AND completed_at >= v_today_start;
    IF v_today_count >= v_verified THEN
      RETURN 0;
    END IF;
  ELSIF p_event_type = 'material_uploaded' THEN
    SELECT COUNT(*) INTO v_verified
      FROM course_materials
     WHERE uploader_id = auth.uid()
       AND status = 'published'
       AND reviewed_by IS NULL;
    SELECT COUNT(*) INTO v_today_count
      FROM points_ledger
     WHERE user_id = auth.uid()
       AND event_type = 'material_uploaded';
    IF v_today_count >= v_verified THEN
      RETURN 0;
    END IF;
  END IF;

  SELECT COALESCE(SUM(points), 0) INTO v_today_total
    FROM points_ledger
   WHERE user_id = auth.uid()
     AND event_type IN ('quiz_completed', 'flashcards_studied', 'task_completed',
                        'material_uploaded', 'daily_login')
     AND created_at >= v_today_start;

  IF v_today_total >= v_daily_total_cap THEN
    RETURN 0;
  END IF;
  v_points := LEAST(v_points, v_daily_total_cap - v_today_total);

  INSERT INTO points_ledger (user_id, event_type, points, metadata)
  VALUES (auth.uid(), p_event_type, v_points, p_metadata);

  RETURN v_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

GRANT EXECUTE ON FUNCTION public.award_points(TEXT, JSONB) TO authenticated;
