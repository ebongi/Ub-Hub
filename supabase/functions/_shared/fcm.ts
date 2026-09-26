// Shared FCM v1 helpers, used by any edge function that sends push
// notifications (send-push-notification, send-study-reminder). Extracted
// from send-push-notification/index.ts so there is exactly one
// implementation of the Firebase service-account OAuth2 dance.

/** Build a short-lived OAuth2 access token from a Firebase service account. */
export async function getFCMAccessToken(): Promise<string> {
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
export async function sendFCMMessage(
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
