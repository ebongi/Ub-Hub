-- `friend_requests` predates this migration folder — it (and its RLS
-- policies) was created directly in the Supabase dashboard, so its current
-- policy set isn't tracked anywhere in this repo. FriendsService.dart trusts
-- RLS alone for authorization on the sensitive paths:
--   * respondToRequest() updates a request by `id` only, never checking that
--     the caller is its receiver_id — if the UPDATE policy were ever as
--     permissive as messages' old "Anyone can view messages" USING (true)
--     policy was, any authenticated user could accept/decline a friend
--     request that isn't theirs.
--   * removeFriend() deletes by sender/receiver match, relying on DELETE
--     policy to prevent deleting someone else's friendship.
-- Rather than guess at (and DROP POLICY IF EXISTS by name) whatever already
-- exists, drop every existing policy on the table and recreate a known-good
-- set, so this migration converges to the intended state regardless of what
-- was there before.

DO $$
DECLARE
  pol RECORD;
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'friend_requests') THEN
    FOR pol IN
      SELECT policyname FROM pg_policies
      WHERE schemaname = 'public' AND tablename = 'friend_requests'
    LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON friend_requests', pol.policyname);
    END LOOP;

    ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

    -- Either side of the request can see it (matches the assumption already
    -- relied on by add_friend_requests_to_realtime_publication.sql).
    CREATE POLICY "Participants can view their friend requests" ON friend_requests
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

    -- You can only ever send a request as yourself.
    CREATE POLICY "Users can send friend requests as themselves" ON friend_requests
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

    -- Only the receiver may accept/decline — the sender can't flip their own
    -- pending request to 'accepted'.
    CREATE POLICY "Only the receiver can respond to a request" ON friend_requests
    FOR UPDATE USING (auth.uid() = receiver_id) WITH CHECK (auth.uid() = receiver_id);

    -- Either side may remove the relationship (unfriend, or cancel a
    -- request they sent/received).
    CREATE POLICY "Participants can delete their friend request" ON friend_requests
    FOR DELETE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
  END IF;
END $$;
