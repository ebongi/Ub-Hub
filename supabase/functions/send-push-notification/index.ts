import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// ---------------------------------------------------------------------------
// FCM helpers
// ---------------------------------------------------------------------------

/** Build a short-lived OAuth2 access token from a Firebase service account. */
async function getFCMAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!serviceAccountJson) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON secret not set");
  const sa = JSON.parse(serviceAccountJson);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const signingInput = `${b64url(header)}.${b64url(claim)}`;

  // Import RSA private key from PEM. The service-account JSON's private_key can
  // reach us with real newlines (JSON.parse) or literal "\n" escape sequences
  // (how it's usually stored as a secret), plus possible \r / stray spaces.
  // Un-escape, drop the PEM header/footer, then keep only the base64 alphabet
  // so atob() never sees a stray character.
  const pemBody = sa.private_key
    .replace(/\\n/g, "\n")
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/[^A-Za-z0-9+/=]/g, "");
  const der = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  const encodedSig = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signingInput}.${encodedSig}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await res.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get FCM token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

/** Send a single FCM push via HTTP v1 API. Returns false on unrecoverable errors. */
async function sendFCMMessage(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  accessToken: string,
  projectId: string,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          // Data-only: the Flutter client renders every notification itself
          // (foreground onMessage / background isolate handler), so there is
          // exactly one notification and never an OS auto-display racing it.
          // title / body / type travel inside `data` (the caller has already
          // coerced every value to a string, as FCM requires).
          data: { ...data, title, body },
          android: { priority: "high" },
          apns: {
            headers: { "apns-priority": "10" },
            // iOS can't render a data-only message on its own; keep an alert
            // block so iOS still shows something once its Firebase project /
            // APNs key are configured.
            payload: {
              aps: { alert: { title, body }, sound: "default", badge: 1 },
            },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    // UNREGISTERED / INVALID_ARGUMENT → token is stale, not a real failure
    const errCode = err?.error?.details?.[0]?.errorCode ?? "";
    if (errCode === "UNREGISTERED" || errCode === "INVALID_ARGUMENT") {
      console.warn(`Stale FCM token (${errCode}), skipping.`);
      return false;
    }
    console.error("FCM send error:", JSON.stringify(err));
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Supabase recipient resolution helpers
// ---------------------------------------------------------------------------

type SupabaseClientType = ReturnType<typeof createClient>;

/** Return user IDs for a given room, excluding the sender. */
async function resolveRoomRecipients(
  supabase: SupabaseClientType,
  roomId: string,
  excludeUserId?: string,
): Promise<string[]> {
  // DM rooms are handled client-side; skip here.
  if (roomId.startsWith("dm_")) return [];

  let ids: string[] = [];

  if (roomId === "global") {
    // Scope global room to the sender's institution so we don't blast every user.
    let institutionId: string | null = null;
    if (excludeUserId) {
      const { data: sender } = await supabase
        .from("profiles")
        .select("institution_id")
        .eq("id", excludeUserId)
        .maybeSingle();
      institutionId = sender?.institution_id ?? null;
    }

    const query = supabase.from("profiles").select("id");
    const { data: rows } = institutionId
      ? await query.eq("institution_id", institutionId)
      : await query;
    ids = (rows ?? []).map((r: { id: string }) => r.id);
  } else {
    // Treat roomId as a department UUID
    const { data: dept } = await supabase
      .from("departments")
      .select("name")
      .eq("id", roomId)
      .maybeSingle();

    if (dept?.name) {
      const { data: rows } = await supabase
        .from("profiles")
        .select("id")
        .eq("department", dept.name);
      ids = (rows ?? []).map((r: { id: string }) => r.id);
    }
  }

  return excludeUserId ? ids.filter((id) => id !== excludeUserId) : ids;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Handle CORS pre-flight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "facultyofscienceapp-neo";

    const supabase = createClient(supabaseUrl, serviceKey);

    const body = await req.json();
    const {
      room_id,
      recipient_ids,
      exclude_user_id,
      title,
      body: messageBody,
      type = "system",
      data = {},
      insert_notification = false,
    } = body as {
      room_id?: string;
      recipient_ids?: string[];
      exclude_user_id?: string;
      title: string;
      body: string;
      type?: string;
      data?: Record<string, unknown>;
      insert_notification?: boolean;
    };

    // 1. Resolve the list of recipient user IDs
    let resolvedIds: string[] = recipient_ids ?? [];

    if (room_id) {
      const roomIds = await resolveRoomRecipients(supabase, room_id, exclude_user_id);
      // Merge: explicit ids + room-resolved ids (deduplicated)
      resolvedIds = [...new Set([...resolvedIds, ...roomIds])];
    } else if (exclude_user_id) {
      resolvedIds = resolvedIds.filter((id) => id !== exclude_user_id);
    }

    if (resolvedIds.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, total_recipients: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Optionally insert notification DB rows so they appear in the in-app list
    if (insert_notification) {
      const rows = resolvedIds.map((userId) => ({
        user_id: userId,
        title,
        body: messageBody,
        type,
        is_read: false,
        created_at: new Date().toISOString(),
        ...(Object.keys(data).length > 0 ? { data } : {}),
      }));
      await supabase.from("notifications").insert(rows);
    }

    // 3. Fetch FCM tokens for all recipients
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, fcm_token")
      .in("id", resolvedIds)
      .not("fcm_token", "is", null);

    const tokens: string[] = (profiles ?? [])
      .map((p: { id: string; fcm_token: string | null }) => p.fcm_token!)
      .filter(Boolean);

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, total_recipients: resolvedIds.length, note: "No FCM tokens found" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 4. Get FCM access token (single OAuth2 round-trip for the whole batch)
    const accessToken = await getFCMAccessToken();

    // 5. Send in parallel batches of 100
    const BATCH_SIZE = 100;
    let sent = 0;

    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const results = await Promise.allSettled(
        batch.map((token) =>
          sendFCMMessage(
            token,
            title,
            messageBody,
            // Ensure all values are strings for FCM data payload; carry `type`
            // through so the client can route the tap (_handleNotificationTap).
            {
              ...Object.fromEntries(
                Object.entries(data).map(([k, v]) => [k, String(v)]),
              ),
              type: String(type),
            },
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
      JSON.stringify({ sent, total_recipients: resolvedIds.length, tokens_found: tokens.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("send-push-notification error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
