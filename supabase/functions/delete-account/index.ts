// Deletes the calling user's own account and owned data. Requires the
// service role key (bypasses RLS, and is the only way to remove a row
// from auth.users) — that key must never reach the Flutter client, so
// this whole operation has to live server-side. The caller's identity is
// derived from their own verified JWT, never from a user id in the
// request body, so a user can only ever delete their own account.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Tables keyed by a user_id column. auth.admin.deleteUser() below only
// cascades automatically for tables with an ON DELETE CASCADE foreign key
// to auth.users(id) — confirmed for bot_knowledge and payment_transactions
// in supabase/migrations/, but the full schema isn't all in tracked
// migrations, so this list is explicit best-effort cleanup rather than
// relying purely on assumed cascade behavior. Add a table here if another
// user-owned one turns up.
const USER_OWNED_TABLES: { table: string; column: string }[] = [
  { table: "tasks", column: "user_id" },
  { table: "grades", column: "user_id" },
  { table: "exams", column: "user_id" },
  { table: "payment_transactions", column: "user_id" },
  { table: "bot_knowledge", column: "user_id" },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return new Response(JSON.stringify({ error: "Invalid or expired session" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const uid = userData.user.id;

  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  for (const { table, column } of USER_OWNED_TABLES) {
    const { error } = await adminClient.from(table).delete().eq(column, uid);
    if (error) {
      // Best-effort: a cleanup failure on one table shouldn't block
      // removing the account itself.
      console.error(`Failed to clean up ${table} for ${uid}:`, error.message);
    }
  }

  await adminClient.from("profiles").delete().eq("id", uid);

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(uid);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
