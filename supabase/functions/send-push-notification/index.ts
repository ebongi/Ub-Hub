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
// Recipient resolution — every scope is resolved server-side from real DB
// relationships. The client never supplies a raw recipient list; it only
// says *what* it wants to notify (a room, a department, an institution,
// everyone) and the server derives *who* that means, the same way RLS
// already scopes the equivalent direct-DB-insert path
// (add_department_notification_policy.sql / admin_management_policies.sql).
// ---------------------------------------------------------------------------

type SupabaseClientType = ReturnType<typeof createClient>;

async function resolveDepartmentMemberIds(
  supabase: SupabaseClientType,
  departmentId: string,
): Promise<string[]> {
  const { data: dept } = await supabase
    .from("departments")
    .select("name")
    .eq("id", departmentId)
    .maybeSingle();
  if (!dept?.name) return [];

  const { data: rows } = await supabase
    .from("profiles")
    .select("id")
    .eq("department", dept.name);
  return (rows ?? []).map((r: { id: string }) => r.id);
}

async function resolveInstitutionMemberIds(
  supabase: SupabaseClientType,
  institutionId: string,
): Promise<string[]> {
  const { data: rows } = await supabase
    .from("profiles")
    .select("id")
    .eq("institution_id", institutionId);
  return (rows ?? []).map((r: { id: string }) => r.id);
}

async function resolveAllProfileIds(supabase: SupabaseClientType): Promise<string[]> {
  const { data: rows } = await supabase.from("profiles").select("id");
  return (rows ?? []).map((r: { id: string }) => r.id);
}

async function getCallerProfile(
  supabase: SupabaseClientType,
  callerUid: string,
): Promise<{ department: string | null; role: string | null }> {
  const { data } = await supabase
    .from("profiles")
    .select("department, role")
    .eq("id", callerUid)
    .maybeSingle();
  return { department: data?.department ?? null, role: data?.role ?? null };
}

/**
 * Resolve the recipient set for a request, authorizing it against the
 * caller's own identity along the way. Throws (caller returns 403) if the
 * caller isn't allowed to notify the requested scope.
 */
async function resolveRecipients(
  supabase: SupabaseClientType,
  callerUid: string,
  scope: string,
  scopeId?: string,
): Promise<string[]> {
  let ids: string[] = [];

  switch (scope) {
    case "room": {
      // Group / department / global chat room — open to any authenticated
      // sender, matching the existing "Authenticated users can send
      // messages" RLS on the messages table itself.
      if (!scopeId) throw new Error("scope_id (room id) is required for scope 'room'");
      if (scopeId.startsWith("dm_")) {
        throw new Error("Use scope 'dm' for direct-message rooms");
      }
      if (scopeId === "global") {
        // Scope "global" to the caller's own institution so a global-room
        // message doesn't blast every user in the database.
        const { data: profile } = await supabase
          .from("profiles")
          .select("institution_id")
          .eq("id", callerUid)
          .maybeSingle();
        const institutionId = profile?.institution_id ?? null;
        ids = institutionId
          ? await resolveInstitutionMemberIds(supabase, institutionId)
          : await resolveAllProfileIds(supabase);
      } else {
        // Every other room id is a department UUID.
        ids = await resolveDepartmentMemberIds(supabase, scopeId);
      }
      break;
    }
    case "dm": {
      if (!scopeId) throw new Error("scope_id (room id) is required for scope 'dm'");
      const parts = scopeId.split("_");
      if (parts.length !== 3 || parts[0] !== "dm") {
        throw new Error("Invalid dm room id");
      }
      const [, uidA, uidB] = parts;
      if (callerUid !== uidA && callerUid !== uidB) {
        throw new Error("Caller is not a participant of this DM room");
      }
      ids = [callerUid === uidA ? uidB : uidA];
      break;
    }
    case "department": {
      // New-content broadcasts (course/material) — mirrors "Users can
      // notify their own department": caller may only broadcast to their
      // own department.
      if (!scopeId) throw new Error("scope_id (department id) is required for scope 'department'");
      const caller = await getCallerProfile(supabase, callerUid);
      const { data: dept } = await supabase
        .from("departments")
        .select("name")
        .eq("id", scopeId)
        .maybeSingle();
      if (!dept?.name || caller.department !== dept.name) {
        throw new Error("Caller may only broadcast to their own department");
      }
      ids = await resolveDepartmentMemberIds(supabase, scopeId);
      break;
    }
    case "institution": {
      // Institution-wide broadcasts (new department created) — mirrors the
      // fact that no non-admin institution-wide notifications policy
      // exists; only admins may reach this scope.
      if (!scopeId) throw new Error("scope_id (institution id) is required for scope 'institution'");
      const caller = await getCallerProfile(supabase, callerUid);
      if (caller.role !== "admin") {
        throw new Error("Only admins may broadcast to scope 'institution'");
      }
      ids = await resolveInstitutionMemberIds(supabase, scopeId);
      break;
    }
    case "all": {
      // Everyone (new news post) — mirrors "Admins can create notifications
      // for anyone" / news_posts being admin-only.
      const caller = await getCallerProfile(supabase, callerUid);
      if (caller.role !== "admin") {
        throw new Error("Only admins may broadcast to scope 'all'");
      }
      ids = await resolveAllProfileIds(supabase);
      break;
    }
    default:
      throw new Error(`Unknown scope: ${scope}`);
  }

  return ids.filter((id) => id !== callerUid);
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
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "facultyofscienceapp-neo";

    // Authenticate the caller from their own JWT — never trust a client-
    // supplied identity. Recipient resolution below is scoped to this uid.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "Invalid or expired session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const callerUid = userData.user.id;

    // Service-role client for recipient resolution / notification rows / FCM
    // token lookups — the caller's identity has already been established
    // above, so every subsequent query is scoped by `callerUid`, not by
    // anything the request body claims.
    const supabase = createClient(supabaseUrl, serviceKey);

    const body = await req.json();
    const {
      scope,
      scope_id,
      title,
      body: messageBody,
      type = "system",
      data = {},
      insert_notification = false,
    } = body as {
      scope: "room" | "dm" | "department" | "institution" | "all";
      scope_id?: string;
      title: string;
      body: string;
      type?: string;
      data?: Record<string, unknown>;
      insert_notification?: boolean;
    };

    if (!scope) {
      return new Response(JSON.stringify({ error: "Missing scope" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Resolve (and authorize) the recipient set for this scope.
    let resolvedIds: string[];
    try {
      resolvedIds = await resolveRecipients(supabase, callerUid, scope, scope_id);
    } catch (e) {
      return new Response(JSON.stringify({ error: (e as Error).message }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
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
