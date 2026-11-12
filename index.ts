// Deploy with Supabase CLI. Set OPENAI_API_KEY as a server-side secret; never expose it in config.js.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS" };
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const auth = req.headers.get("Authorization");
  if (!auth) return Response.json({ error: "Autenticazione richiesta" }, { status: 401, headers: cors });
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) return Response.json({ error: "Sessione non valida" }, { status: 401, headers: cors });
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return Response.json({ error: "Configura OPENAI_API_KEY nei secrets Supabase" }, { status: 503, headers: cors });
  try {
    const { image } = await req.json();
    if (typeof image !== "string" || !image.startsWith("data:image/")) return Response.json({ error: "Immagine non valida" }, { status: 400, headers: cors });
    const response = await fetch("https://api.openai.com/v1/responses", { method: "POST", headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" }, body: JSON.stringify({ model: "gpt-4.1-mini", input: [{ role: "user", content: [{ type: "input_text", text: "Leggi l'etichetta del vino. Estrai solo informazioni visibili o chiaramente deducibili. Non inventare. Rispondi con JSON: name (nome cuvée/vino), producer, vintage (stringa), appellation, region, grapes, notes (eventuali dubbi). Se un dato non è leggibile usa stringa vuota." }, { type: "input_image", image_url: image }] }], text: { format: { type: "json_object" } } }) });
    const result = await response.json();
    if (!response.ok) return Response.json({ error: result.error?.message || "Errore del servizio AI" }, { status: 502, headers: cors });
    const output = result.output?.flatMap((x: any) => x.content || []).find((x: any) => x.type === "output_text")?.text;
    if (!output) return Response.json({ error: "Nessun testo restituito" }, { status: 502, headers: cors });
    return Response.json({ wine: JSON.parse(output) }, { headers: cors });
  } catch (e) { return Response.json({ error: String(e) }, { status: 400, headers: cors }); }
});
