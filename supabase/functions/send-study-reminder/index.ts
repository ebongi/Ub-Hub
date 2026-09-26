import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { getFCMAccessToken, sendFCMMessage } from "../_shared/fcm.ts";

// Periodic, system-triggered reminder — invoked by a pg_cron job (see
// supabase/migrations/schedule_daily_study_reminder.sql), never by a
// client. Unlike send-push-notification there is no "calling user" to
// authorize a scope against: every profile with study_reminders_enabled
// set pushes, every time this runs. Because of that, the only acceptable
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

const REMINDER_TITLE = "Time to study! 📚";
const REMINDER_BODY = "Keep your streak going — jump back in for a quick study session.";

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

    const { data: profiles, error } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("study_reminders_enabled", true)
      .not("fcm_token", "is", null);

    if (error) throw error;

    const tokens: string[] = (profiles ?? [])
      .map((p: { fcm_token: string | null }) => p.fcm_token!)
      .filter(Boolean);

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, opted_in: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const accessToken = await getFCMAccessToken();

    const BATCH_SIZE = 100;
    let sent = 0;
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const results = await Promise.allSettled(
        batch.map((token) =>
          sendFCMMessage(
            token,
            REMINDER_TITLE,
            REMINDER_BODY,
            { type: "study_reminder" },
            accessToken,
            projectId,
          )
        ),
      );
      sent += results.filter(
        (r) => r.status === "fulfilled" && r.value === true,
      ).length;
    }

    return new Response(
      JSON.stringify({ sent, opted_in: tokens.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("send-study-reminder error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
