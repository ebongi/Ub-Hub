-- The previous SELECT policy on `messages` allowed any authenticated user to
-- read every row, including private DM rows between two other users. Scope
-- it to global-chat rows plus DM rows the requesting user is actually a
-- participant in. Relies on FriendsService.dmRoomId always producing
-- 'dm_<sortedUidA>_<sortedUidB>' from two Supabase UUIDs, which never
-- contain '_', so the split is unambiguous.

DROP POLICY IF EXISTS "Anyone can view messages" ON messages;

CREATE POLICY "Users can view global and their own DM messages" ON messages
FOR SELECT
USING (
  room_id = 'global'
  OR (
    left(room_id, 3) = 'dm_'
    AND auth.uid()::text = ANY (string_to_array(substring(room_id from 4), '_'))
  )
);
