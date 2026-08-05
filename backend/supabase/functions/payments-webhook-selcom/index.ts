import { createAdminClient } from "../_shared/supabase-clients.ts";
import { corsHeaders, errorResponse } from "../_shared/cors.ts";
import { handleProviderWebhook } from "../_shared/payments/handle-webhook.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);
  return await handleProviderWebhook(createAdminClient(), "selcom", req);
});
