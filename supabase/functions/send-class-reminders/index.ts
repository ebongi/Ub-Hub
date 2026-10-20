import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { isServiceRoleCaller } from "../_shared/auth.ts";
import { getFCMAccessToken, sendFCMMessage } from "../_shared/fcm.ts";

// Class reminders as FCM pushes. Invoked every minute by pg_cron (see
// supabase/migrations/20261020120000_schedule_class_reminders.sql): finds the
// classes that start exactly LEAD_MINUTES from now and pushes one message per
// student, however many of their chosen classes start then or overlap.

const LEAD_MINUTES = 15;
// Timetable times are campus wall-clock (UTC+1 all year, no DST).
const TIME_ZONE = "Africa/Douala";
// Lab/practical blocks that run most of the day coexist with lectures, so
// they never count as "overlapping" (same rule as TimetableCatalog.clashes).
const ALL_DAY_MINUTES = 10 * 60;

interface Slot {
  course_code: string;
  start: number;
  end: number;
  hall: string | null;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

/** Campus ISO weekday (1 = Mon) and minute-of-day for [date]. */
function campusClock(date: Date): { weekday: number; minutes: number } {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: TIME_ZONE,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type: string) => parts.find((p) => p.type === type)!.value;
  const weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    .indexOf(get("weekday")) + 1;
  return { weekday, minutes: Number(get("hour")) * 60 + Number(get("minute")) };
}

const toMinutes = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
const fmt = (m: number) =>
  `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;

/** Every row of a query, past PostgREST's default 1000-row page. */
async function fetchAll<T>(
  page: (from: number, to: number) => PromiseLike<{ data: T[] | null; error: unknown }>,
): Promise<T[]> {
  const size = 1000;
  const rows: T[] = [];
  for (let from = 0;; from += size) {
    const { data, error } = await page(from, from + size - 1);
    if (error) throw error;
    rows.push(...(data ?? []));
    if (!data || data.length < size) return rows;
  }
}

/** One push for everything this student has starting at [target]. */
function buildMessage(
  starting: Slot[],
  ongoing: Slot[],
): { title: string; body: string } {
  const byCourse = new Map<string, Slot[]>();
  for (const s of starting) {
    byCourse.set(s.course_code, [...(byCourse.get(s.course_code) ?? []), s]);
  }
  const codes = [...byCourse.keys()];

  const title = codes.length === 1
    ? `${codes[0]} starts in ${LEAD_MINUTES} min`
    : `${codes.join(" & ")} start in ${LEAD_MINUTES} min`;

  const lines = codes.map((code) => {
    const slots = byCourse.get(code)!;
    const halls = [...new Set(slots.map((s) => s.hall).filter(Boolean))];
    return `${code} · ${fmt(slots[0].start)}–${fmt(slots[0].end)}` +
      (halls.length ? ` · ${halls.join(" / ")}` : "");
  });
  if (codes.length > 1) lines.push("These classes clash — pick which to attend.");

  const stillOn = [...new Set(ongoing.map((s) => s.course_code))]
    .filter((c) => !byCourse.has(c));
  if (stillOn.length) {
    const until = Math.max(
      ...ongoing.filter((s) => !byCourse.has(s.course_code)).map((s) => s.end),
    );
    lines.push(`${stillOn.join(", ")} is still in session until ${fmt(until)}.`);
  }
  return { title, body: lines.join("\n") };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (!isServiceRoleCaller(req.headers.get("Authorization"))) {
    return json({ error: "Forbidden" }, 403);
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "facultyofscienceapp-neo";

    // The minute a class must start in for its reminder to go out now. Using
    // Date arithmetic first means a 23:50 class correctly reminds at 23:35
    // and a 00:05 class at 23:50 the previous evening.
    const target = campusClock(new Date(Date.now() + LEAD_MINUTES * 60_000));

    const { data: dayRows, error: dayErr } = await supabase
      .from("timetable_classes")
      .select("course_code, start_time, end_time, hall")
      .eq("day_of_week", target.weekday);
    if (dayErr) throw dayErr;

    const slotsByCode = new Map<string, Slot[]>();
    for (const r of dayRows ?? []) {
      const slot: Slot = {
        course_code: r.course_code,
        start: toMinutes(r.start_time),
        end: toMinutes(r.end_time),
        hall: r.hall,
      };
      slotsByCode.set(r.course_code, [...(slotsByCode.get(r.course_code) ?? []), slot]);
    }
    const startingCodes = [...slotsByCode.entries()]
      .filter(([, slots]) => slots.some((s) => s.start === target.minutes))
      .map(([code]) => code);
    if (startingCodes.length === 0) return json({ sent: 0, recipients: 0 });

    // Everyone who chose a course starting now, then ALL of their courses
    // that day (needed to spot what's still in session).
    const starters = await fetchAll<{ user_id: string }>((from, to) =>
      supabase.from("user_timetable_courses").select("user_id")
        .in("course_code", startingCodes).order("user_id").range(from, to)
    );
    const userIds = [...new Set(starters.map((r) => r.user_id))];
    if (userIds.length === 0) return json({ sent: 0, recipients: 0 });

    const tokenByUser = new Map<string, string>();
    const coursesByUser = new Map<string, string[]>();
    for (let i = 0; i < userIds.length; i += 200) {
      const chunk = userIds.slice(i, i + 200);
      const { data: profiles, error } = await supabase
        .from("profiles").select("id, fcm_token").in("id", chunk)
        .not("fcm_token", "is", null);
      if (error) throw error;
      for (const p of profiles ?? []) tokenByUser.set(p.id, p.fcm_token);

      const chosen = await fetchAll<{ user_id: string; course_code: string }>(
        (from, to) =>
          supabase.from("user_timetable_courses").select("user_id, course_code")
            .in("user_id", chunk).order("user_id").order("course_code")
            .range(from, to),
      );
      for (const c of chosen) {
        coursesByUser.set(c.user_id, [...(coursesByUser.get(c.user_id) ?? []), c.course_code]);
      }
    }

    const accessToken = await getFCMAccessToken();
    const pushes: Promise<boolean>[] = [];
    for (const [userId, token] of tokenByUser) {
      const slots = (coursesByUser.get(userId) ?? []).flatMap(
        (code) => slotsByCode.get(code) ?? [],
      );
      const starting = slots.filter((s) => s.start === target.minutes);
      if (starting.length === 0) continue;
      const ongoing = slots.filter((s) =>
        s.start < target.minutes && s.end > target.minutes &&
        s.end - s.start < ALL_DAY_MINUTES
      );
      const { title, body } = buildMessage(starting, ongoing);
      pushes.push(
        sendFCMMessage(token, title, body, { type: "class_reminder" }, accessToken, projectId),
      );
    }

    const results = await Promise.allSettled(pushes);
    const sent = results.filter((r) => r.status === "fulfilled" && r.value).length;
    return json({ sent, recipients: pushes.length });
  } catch (error) {
    console.error("send-class-reminders error:", error);
    return json({ error: (error as Error)?.message ?? String(error) }, 500);
  }
});
