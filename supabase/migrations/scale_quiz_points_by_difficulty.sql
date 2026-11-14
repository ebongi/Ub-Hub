-- Quiz points previously came from score_percentage alone, so a perfect
-- score on an easy quiz earned exactly as much as a perfect score on an
-- advanced one — QuestionDifficulty (lib/services/ai_service.dart: low /
-- intermediate / advanced) was chosen at quiz-generation time but never
-- reached the points system. Now the client passes 'difficulty' through
-- in award_points()'s metadata (see quiz_view_screen.dart /
-- pdf_viewer_screen.dart) and it scales both the per-point value and the
-- per-quiz cap: low = 0.7x (max 70), intermediate = 1.0x (max 100,
-- unchanged from before), advanced = 1.5x (max 150) — so choosing a
-- harder quiz is a genuine points incentive, not just a harder challenge
-- for the same reward, while an easy quiz is worth a bit less even at a
-- perfect score.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

CREATE OR REPLACE FUNCTION public.award_points(p_event_type TEXT, p_metadata JSONB DEFAULT '{}'::jsonb)
RETURNS INT AS $$
DECLARE
  v_points INT;
  v_daily_cap INT;
  v_today_count INT;
  v_today_start TIMESTAMPTZ := date_trunc('day', now());
  v_quiz_multiplier NUMERIC;
  v_quiz_cap INT;
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
