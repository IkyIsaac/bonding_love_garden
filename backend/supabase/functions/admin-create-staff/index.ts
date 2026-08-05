import { createAdminClient } from "../_shared/supabase-clients.ts";
import { resolveCaller, type Role } from "../_shared/auth.ts";
import { corsHeaders, errorResponse, jsonResponse } from "../_shared/cors.ts";
import { HttpError } from "../_shared/http-error.ts";

/**
 * The one privileged operation the web admin's Staff Management page needs
 * that can't go through a normal RLS-respecting client call: creating a new
 * auth.users row requires the GoTrue admin API (service role), which is
 * only reachable server-side. Editing an EXISTING staff member's role/
 * approval_status doesn't need this — admin already has direct RLS UPDATE
 * rights on profiles for that (see prevent_profile_privilege_escalation,
 * which only blocks non-admins).
 *
 * role is set via app_metadata (trusted, service-role-only), never
 * user_metadata — same reasoning as handle_new_user itself: app_metadata
 * can't be forged by a client-side signup call.
 */

const STAFF_ROLES: Role[] = ["cashier", "attendant", "supervisor", "admin"];

interface CreateStaffRequest {
  phone: string;
  fullName: string;
  role: Role;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const admin = createAdminClient();

  try {
    const body = await parseRequest(req);
    const caller = await resolveCaller(req.headers.get("Authorization"), admin);
    if (caller.role !== "admin") {
      throw new HttpError(403, "Only an admin can create staff accounts");
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      phone: body.phone,
      phone_confirm: true,
      app_metadata: { role: body.role },
      user_metadata: { full_name: body.fullName },
    });
    if (createError || !created.user) {
      throw new HttpError(400, `Failed to create account: ${createError?.message ?? "unknown error"}`);
    }

    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id, phone, full_name, role, approval_status")
      .eq("id", created.user.id)
      .single();
    if (profileError || !profile) {
      throw new HttpError(500, "Account created but profile lookup failed — check handle_new_user");
    }

    await admin.from("audit_log").insert({
      actor_profile_id: caller.id,
      action_type: "staff_created",
      target_type: "profile",
      target_id: profile.id,
      details: `Created ${body.role} account for ${body.fullName} (${body.phone})`,
      status: "success",
    });

    return jsonResponse({ profile }, 201);
  } catch (err) {
    if (err instanceof HttpError) return errorResponse(err.message, err.status);
    console.error("admin-create-staff unhandled error:", err);
    return errorResponse("Internal error", 500);
  }
});

async function parseRequest(req: Request): Promise<CreateStaffRequest> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new HttpError(400, "Invalid JSON body");
  }
  if (typeof body !== "object" || body === null) {
    throw new HttpError(400, "Request body must be an object");
  }
  const b = body as Record<string, unknown>;

  if (typeof b.phone !== "string" || !/^\+\d{7,15}$/.test(b.phone)) {
    throw new HttpError(400, "phone must be in E.164 format, e.g. +255700000000");
  }
  if (typeof b.fullName !== "string" || b.fullName.trim().length === 0) {
    throw new HttpError(400, "fullName is required");
  }
  if (typeof b.role !== "string" || !STAFF_ROLES.includes(b.role as Role)) {
    throw new HttpError(400, `role must be one of ${STAFF_ROLES.join(", ")}`);
  }

  return { phone: b.phone, fullName: b.fullName.trim(), role: b.role as Role };
}
