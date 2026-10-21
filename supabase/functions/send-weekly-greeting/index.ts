import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { getFCMAccessToken, sendFCMMessage } from "../_shared/fcm.ts";

// Periodic, system-triggered reminder — invoked by a pg_cron job (see
// supabase/migrations/schedule_weekly_greeting.sql), never by a
// client. Unlike send-push-notification there is no "calling user" to
// authorize a scope against: every profile gets a personalised
// in-app row and a push, every time this runs. Because of that, the only acceptable
// caller is our own cron job authenticating with the project's
// service_role key — checked explicitly below. verify_jwt is also on for
// this function (supabase/config.toml), so the gateway has already
// confirmed the bearer token is a genuinely, cryptographically
// project-signed JWT before this code runs at all; the check here narrows
// that down to specifically the service_role claim (an anon or a regular
// user's JWT would otherwise pass the gateway check too).
function isServiceRoleCaller(authHeader: string | null): boolean {
  if (!authHeader?.startsWith("Bearer ")) return false;
  const token = authHeader.slice("Bearer ".length);
  const parts = token.split(".");
  if (parts.length !== 3) return false;
  try {
    const payload = JSON.parse(
      atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    return payload.role === "service_role";
  } catch {
    return false;
  }
}

function plural(n: number, word: string): string {
  return `${n} ${word}${n === 1 ? "" : "s"}`;
}

// Personalised with the user's first name and what's actually on their plate
// this week (their own exams starting and unfinished tasks due within the
// next 7 days), falling back to a general encouragement when they have none.
function buildMessage(
  name: string | null,
  exams: number,
  tasks: number,
): { title: string; body: string } {
  const first = name?.trim().split(/\s+/)[0];
  const title = first ? `Happy new week, ${first}! 🌟` : "Happy new week! 🌟";

  const parts: string[] = [];
  if (exams > 0) parts.push(plural(exams, "exam"));
  if (tasks > 0) parts.push(plural(tasks, "task") + " due");

  const body = parts.length > 0
    ? `You have ${parts.join(" and ")} in the next 7 days. Plan your week, study well and take it one day at a time.`
    : "A fresh week, a fresh start. Set a study goal, revisit your notes and study well — you've got this.";
  return { title, body };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!isServiceRoleCaller(req.headers.get("Authorization"))) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "facultyofscienceapp-neo";
    const supabase = createClient(supabaseUrl, serviceKey);

    const now = new Date();
    const weekAhead = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const [profilesRes, examsRes, tasksRes] = await Promise.all([
      supabase.from("profiles").select("id, name, fcm_token"),
      supabase
        .from("exams")
        .select("user_id")
        .gte("start_time", now.toISOString())
        .lte("start_time", weekAhead.toISOString()),
      supabase
        .from("tasks")
        .select("user_id")
        .eq("is_done", false)
        .gte("deadline", now.toISOString())
        .lte("deadline", weekAhead.toISOString()),
    ]);
    if (profilesRes.error) throw profilesRes.error;
    if (examsRes.error) throw examsRes.error;
    if (tasksRes.error) throw tasksRes.error;

    const countBy = (rows: { user_id: string }[] | null) => {
      const m = new Map<string, number>();
      for (const r of rows ?? []) m.set(r.user_id, (m.get(r.user_id) ?? 0) + 1);
      return m;
    };
    const examCounts = countBy(examsRes.data);
    const taskCounts = countBy(tasksRes.data);

    const users = (profilesRes.data ?? []).map((p: {
      id: string;
      name: string | null;
      fcm_token: string | null;
    }) => ({
      ...p,
      ...buildMessage(p.name, examCounts.get(p.id) ?? 0, taskCounts.get(p.id) ?? 0),
    }));

    const createdAt = now.toISOString();
    const rows = users.map((u) => ({
      user_id: u.id,
      title: u.title,
      body: u.body,
      type: "system",
      is_read: false,
      created_at: createdAt,
    }));
    const ROW_BATCH = 500;
    for (let i = 0; i < rows.length; i += ROW_BATCH) {
      const { error: insertError } = await supabase
        .from("notifications")
        .insert(rows.slice(i, i + ROW_BATCH));
      if (insertError) throw insertError;
    }

    const pushable = users.filter((u) => u.fcm_token);
    let sent = 0;
    if (pushable.length > 0) {
      const accessToken = await getFCMAccessToken();
      const BATCH_SIZE = 100;
      for (let i = 0; i < pushable.length; i += BATCH_SIZE) {
        const batch = pushable.slice(i, i + BATCH_SIZE);
        const results = await Promise.allSettled(
          batch.map((u) =>
            sendFCMMessage(
              u.fcm_token!,
              u.title,
              u.body,
              { type: "system" },
              accessToken,
              projectId,
            )
          ),
        );
        sent += results.filter(
          (r) => r.status === "fulfilled" && r.value === true,
        ).length;
      }
    }

    return new Response(
      JSON.stringify({ sent, users: users.length, pushable: pushable.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("send-weekly-greeting error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
