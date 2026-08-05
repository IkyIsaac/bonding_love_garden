import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Untyped deliberately: Edge Functions deploy independently of web/, and
// syncing a generated Database type into two places is more sync overhead
// than it's worth here. Each function defines explicit interfaces for the
// rows it actually reads/writes instead.

/**
 * Bypasses RLS entirely — the trusted write path for financial tables
 * (orders/order_items/etc. have no non-admin RLS write policy at all, per
 * docs/ARCHITECTURE_PLAN.md §3.4-§3.8). Never expose this client's queries
 * to unvalidated request input.
 */
export function createAdminClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Scoped to the calling user's own JWT — RLS applies normally. Used only to
 * resolve who is calling (auth.getUser()); actual reads/writes for this
 * function go through the admin client above once the caller is validated.
 */
export function createUserClient(authHeader: string): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authHeader } },
  });
}
