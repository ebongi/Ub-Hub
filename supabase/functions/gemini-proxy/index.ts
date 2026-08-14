// Server-side proxy for Gemini calls. The real GEMINI_API_KEY only ever
// lives here (Supabase Edge Function secret), never in the Flutter client.
// Supabase's function gateway rejects requests with a missing/invalid user
// JWT before this code even runs (verify_jwt = true in config.toml), so an
// authenticated app user is the only caller that reaches this point.
import { corsHeaders } from "../_shared/cors.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const DEFAULT_MODEL = "gemini-2.5-flash-lite";

interface Part {
  text?: string;
  inlineData?: { mimeType: string; data: string };
}

interface HistoryTurn {
  role: "user" | "model";
  parts: Part[];
}

interface RequestBody {
  model?: string;
  systemInstruction?: string;
  history?: HistoryTurn[];
  message: string;
  attachments?: { mimeType: string; data: string }[];
  stream?: boolean;
}

function buildContents(body: RequestBody) {
  const userParts: Part[] = [{ text: body.message }];
  for (const att of body.attachments ?? []) {
    userParts.push({ inlineData: { mimeType: att.mimeType, data: att.data } });
  }
  return [...(body.history ?? []), { role: "user", parts: userParts }];
}

function extractText(candidate: unknown): string {
  const parts = (candidate as any)?.content?.parts;
  if (!Array.isArray(parts)) return "";
  return parts
    .map((p: Part) => p.text ?? "")
    .join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!GEMINI_API_KEY) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: GEMINI_API_KEY not set" }),
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

  if (!body.message) {
    return new Response(JSON.stringify({ error: "Missing 'message'" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const model = body.model || DEFAULT_MODEL;
  const contents = buildContents(body);
  const payload: Record<string, unknown> = { contents };
  if (body.systemInstruction) {
    payload.systemInstruction = { parts: [{ text: body.systemInstruction }] };
  }

  const stream = body.stream ?? true;
  const method = stream ? "streamGenerateContent" : "generateContent";
  const query = stream ? "alt=sse&key=" : "key=";
  const upstreamUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:${method}?${query}${GEMINI_API_KEY}`;

  const upstream = await fetch(upstreamUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!upstream.ok) {
    const errText = await upstream.text();
    return new Response(JSON.stringify({ error: `Gemini API error: ${errText}` }), {
      status: upstream.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!stream) {
    const data = await upstream.json();
    const text = extractText(data.candidates?.[0]);
    return new Response(JSON.stringify({ text }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Re-frame upstream SSE ("data: {...}" lines) as newline-delimited JSON
  // text deltas ({"text":"..."}\n) — simpler, unambiguous framing for the
  // Dart client to read with a line splitter, independent of exactly how
  // TCP/HTTP2 chooses to chunk the bytes.
  const reader = upstream.body!.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  let buffer = "";

  const outStream = new ReadableStream({
    async pull(controller) {
      const { done, value } = await reader.read();
      if (done) {
        controller.close();
        return;
      }
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith("data:")) continue;
        const jsonStr = trimmed.slice(5).trim();
        if (!jsonStr) continue;
        try {
          const parsed = JSON.parse(jsonStr);
          const text = extractText(parsed.candidates?.[0]);
          if (text) {
            controller.enqueue(encoder.encode(JSON.stringify({ text }) + "\n"));
          }
        } catch {
          // Ignore malformed/partial SSE lines — best-effort streaming.
        }
      }
    },
  });

  return new Response(outStream, {
    headers: { ...corsHeaders, "Content-Type": "application/x-ndjson" },
  });
});
