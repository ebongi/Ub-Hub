-- Discovered while verifying 20260926120001/20260926120003 against the live
-- project: `messages` and `notifications` each carried extra RLS policies
-- that were never captured anywhere in this migrations folder (created out
-- of band, presumably straight in the Studio UI, before this repo started
-- tracking migrations). Postgres OR's all matching permissive policies
-- together, so these silently coexisted with — and completely defeated —
-- every fix applied via a tracked migration:
--   * messages SELECT "Allow authenticated users to read messages"
--     (qual: true) — let anyone read every DM, regardless of
--     restrict_messages_select_to_participants.sql.
--   * messages INSERT "Allow authenticated users to insert messages"
--     (with_check: auth.uid() = sender_id, no room check) — let anyone write
--     into any DM room, regardless of
--     20260926120001_restrict_messages_insert_to_participants.sql.
--   * notifications INSERT "Allow authenticated users to create
--     notifications" (with_check: auth.role() = 'authenticated') — let any
--     authenticated user create a notification row for *any* user_id with
--     arbitrary title/body, a phishing/spoofing vector, regardless of every
--     other notifications INSERT policy.
--   * A couple of harmless exact-duplicate policies too (e.g. a second
--     "own notifications" policy, a regex-based DM-room policy equivalent to
--     the tracked one).
--
-- friend_requests already got this same "drop everything, recreate the
-- intended set" treatment in harden_friend_requests_policies.sql for the
-- same reason. Do the same here for messages and notifications so both
-- tables converge to a known set regardless of whatever untracked policies
-- already existed.

DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'messages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON messages', pol.policyname);
  END LOOP;

  ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "Users can view global and their own DM messages" ON messages
  FOR SELECT USING (
    room_id = 'global'
    OR (
      left(room_id, 3) = 'dm_'
      AND auth.uid()::text = ANY (string_to_array(substring(room_id from 4), '_'))
    )
  );

  CREATE POLICY "Users can send messages as themselves, only to their own DMs" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = sender_id
    AND (
      left(room_id, 3) <> 'dm_'
      OR auth.uid()::text = ANY (string_to_array(substring(room_id from 4), '_'))
    )
  );
END $$;

DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'notifications'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON notifications', pol.policyname);
  END LOOP;

  ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "Users can manage their own notifications" ON notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

  CREATE POLICY "Admins can create notifications for anyone" ON notifications
  FOR INSERT WITH CHECK (is_admin());

  -- Restores add_department_notification_policy.sql's intent, which turns
  -- out to never have actually been applied to this database (it's absent
  -- from the live policy list entirely).
  CREATE POLICY "Users can notify their own department" ON notifications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles sender
      WHERE sender.id = auth.uid()
        AND sender.department IS NOT NULL
        AND sender.department = (
          SELECT recipient.department FROM profiles recipient
          WHERE recipient.id = notifications.user_id
        )
    )
  );

  CREATE POLICY "Users can notify friends and pending contacts" ON notifications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM friend_requests fr
      WHERE (fr.sender_id = auth.uid() AND fr.receiver_id = notifications.user_id)
         OR (fr.receiver_id = auth.uid() AND fr.sender_id = notifications.user_id)
    )
  );
END $$;
