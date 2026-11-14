-- restrict_messages_select_to_participants.sql scoped SELECT on `messages` to
-- global rows plus DM rows the requester participates in, but the INSERT
-- policy from comprehensive_rls_policies.sql was never narrowed the same
-- way — it only checked `auth.uid() = sender_id`. That let any authenticated
-- user insert a row into *any* dm_<uidA>_<uidB> room (ids are deterministic
-- and the two user ids are discoverable via profile search), injecting
-- messages into a private conversation between two other, unrelated users,
-- and letting anyone DM anyone else without ever being an accepted friend
-- (a rule the app only enforced in the Flutter UI, not the database).
--
-- Gate DM rooms to their two participants, same as the SELECT policy. Global
-- chat and group rooms (department/course discussion — see
-- department_screen.dart / course_detail_screen.dart, whose room_id is a
-- plain department/course UUID) stay open to any authenticated sender,
-- unchanged from before; only room ids starting with 'dm_' get the
-- membership check. Same assumption as
-- restrict_messages_select_to_participants.sql: dmRoomId always produces
-- 'dm_<sortedUidA>_<sortedUidB>' from two Supabase UUIDs, which never
-- contain '_', so the split is unambiguous.

DROP POLICY IF EXISTS "Authenticated users can send messages" ON messages;

CREATE POLICY "Users can send messages as themselves, only to their own DMs" ON messages
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND auth.uid() = sender_id
  AND (
    left(room_id, 3) <> 'dm_'
    OR auth.uid()::text = ANY (string_to_array(substring(room_id from 4), '_'))
  )
);
