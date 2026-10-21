-- Also discovered while verifying the messages/notifications policy cleanup
-- (20260926130000): an `on_friend_request_created` trigger on
-- friend_requests calls notify_new_friend_request(), a SECURITY DEFINER
-- function that inserts a generic "Someone sent you a friend request!"
-- notification row. Neither the trigger nor the function is referenced
-- anywhere in this repo (app code, edge functions, or a tracked migration)
-- — it was created directly against the live database.
--
-- FriendsService.sendFriendRequest() (lib/services/friends_service.dart)
-- already inserts its own, personalized notification client-side
-- ("<name> sent you a friend request."). With this trigger also firing on
-- every insert, every friend request produces two notification rows for the
-- receiver. Drop the trigger and its function — the client-driven
-- notification (now correctly reachable cross-department via
-- 20260926130000's "Users can notify friends and pending contacts" policy)
-- is the single source of truth going forward.
--
-- This also resolves a `supabase db advisors` finding: the function was
-- SECURITY DEFINER with EXECUTE still granted to `anon`/`authenticated`,
-- making it directly callable via PostgREST RPC (it would have errored
-- there since it relies on trigger-only `NEW`, but granting EXECUTE on a
-- trigger function to public-facing roles is unnecessary exposure either
-- way).

DROP TRIGGER IF EXISTS on_friend_request_created ON friend_requests;
DROP FUNCTION IF EXISTS public.notify_new_friend_request();
