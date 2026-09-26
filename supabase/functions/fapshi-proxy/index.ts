// Server-side proxy for Fapshi payment calls. The real merchant
// FAPSHI_API_USER/FAPSHI_API_KEY only ever live here (Supabase Edge
// Function secrets) — never in the Flutter client, which previously sent
// them in plaintext headers from the device. Supabase's function gateway
// rejects requests with a missing/invalid user JWT before this code runs
// (verify_jwt = true in config.toml).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const FAPSHI_API_USER = Deno.env.get("FAPSHI_API_USER") ?? "";
const FAPSHI_API_KEY = Deno.env.get("FAPSHI_API_KEY") ?? "";
const FAPSHI_ENV = (Deno.env.get("FAPSHI_ENV") ?? "sandbox").toLowerCase();

// Used only to reconcile a confirmed payment server-side (see the
// "payment-status" case below) — never exposed to the client.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const BASE_URL =
  FAPSHI_ENV === "production" || FAPSHI_ENV === "prod" || FAPSHI_ENV === "live"
    ? "https://live.fapshi.com"
    : "https://sandbox.fapshi.com";

type Action = "direct-pay" | "initiate-pay" | "payment-status";

interface RequestBody {
  action: Action;
  amount?: number;
  phone?: string;
  email?: string;
  externalId?: string;
  message?: string;
  userId?: string;
  transId?: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!FAPSHI_API_USER || !FAPSHI_API_KEY) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: Fapshi credentials not set" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const fapshiHeaders = {
    "Content-Type": "application/json",
    apiuser: FAPSHI_API_USER,
    apikey: FAPSHI_API_KEY,
  };

  let upstream: Response;

  switch (body.action) {
    case "direct-pay":
      upstream = await fetch(`${BASE_URL}/direct-pay`, {
        method: "POST",
        headers: fapshiHeaders,
        body: JSON.stringify({
          amount: body.amount,
          phone: body.phone,
          email: body.email,
          externalId: body.externalId,
          message: body.message,
        }),
      });
      break;

    case "initiate-pay":
      upstream = await fetch(`${BASE_URL}/initiate-pay`, {
        method: "POST",
        headers: fapshiHeaders,
        body: JSON.stringify({
          amount: body.amount,
          phone: body.phone,
          email: body.email,
          externalId: body.externalId,
          message: body.message,
          userId: body.userId,
        }),
      });
      break;

    case "payment-status": {
      if (!body.transId) {
        return new Response(JSON.stringify({ error: "Missing 'transId'" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const statusUpstream = await fetch(`${BASE_URL}/payment-status/${body.transId}`, {
        method: "GET",
        headers: fapshiHeaders,
      });
      const rawText = await statusUpstream.text();

      // Reconcile server-side: if Fapshi itself confirms this transId as
      // SUCCESSFUL, flip the matching payment_transactions row to 'success'
      // here (via the service-role client, bypassing RLS) so that status is
      // never reachable through a forged client REST write. See
      // complete_payment_transaction in supabase/migrations/ — it fails
      // closed (no-ops/raises) on a missing row or amount mismatch, so a
      // failure here never blocks returning Fapshi's raw response below.
      if (statusUpstream.ok && SUPABASE_URL && SERVICE_ROLE_KEY) {
        try {
          const data = JSON.parse(rawText);
          if (
            typeof data?.status === "string" &&
            data.status.toUpperCase() === "SUCCESSFUL" &&
            typeof data?.amount === "number"
          ) {
            const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
            const { error } = await admin.rpc("complete_payment_transaction", {
              p_fapshi_trans_id: body.transId,
              p_amount: data.amount,
            });
            if (error) {
              console.error("complete_payment_transaction failed:", error.message);
            }
          }
        } catch (e) {
          console.error("payment-status reconciliation error:", e);
        }
      }

      return new Response(rawText, {
        status: statusUpstream.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    default:
      return new Response(JSON.stringify({ error: `Unknown action: ${body.action}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
  }

  const responseText = await upstream.text();
  return new Response(responseText, {
    status: upstream.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
