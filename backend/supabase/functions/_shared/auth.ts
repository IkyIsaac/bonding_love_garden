import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError } from "./http-error.ts";
import { createUserClient } from "./supabase-clients.ts";

export type Role = "customer" | "cashier" | "attendant" | "supervisor" | "admin";
export type ApprovalStatus = "pending" | "approved" | "rejected" | "suspended";
export type Channel = "customer_app" | "staff_app" | "web_admin";

const STAFF_ROLES: Role[] = ["cashier", "attendant", "supervisor", "admin"];

export interface CallerProfile {
  id: string;
  role: Role;
  approvalStatus: ApprovalStatus;
}

/** Resolves who's calling from the request's own JWT. Throws 401 on anything invalid. */
export async function resolveCaller(
  authHeader: string | null,
  admin: SupabaseClient,
): Promise<CallerProfile> {
  if (!authHeader) throw new HttpError(401, "Missing Authorization header");

  const userClient = createUserClient(authHeader);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    throw new HttpError(401, "Invalid or expired session");
  }

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("id, role, approval_status")
    .eq("id", userData.user.id)
    .single();
  if (profileError || !profile) {
    throw new HttpError(401, "No profile found for this account");
  }

  return {
    id: profile.id,
    role: profile.role as Role,
    approvalStatus: profile.approval_status as ApprovalStatus,
  };
}

export function assertApproved(caller: CallerProfile) {
  if (caller.approvalStatus !== "approved") {
    throw new HttpError(403, "Account is not approved to transact yet");
  }
}

export function isStaffRole(role: Role): boolean {
  return STAFF_ROLES.includes(role);
}

/**
 * customer_app: family is always the caller's own — never client-supplied.
 * staff_app / web_admin: caller must be staff/admin, family is supplied
 * explicitly (they're acting on behalf of a customer) and must exist.
 */
export async function resolveFamilyId(
  caller: CallerProfile,
  channel: Channel,
  requestedFamilyId: string | undefined,
  admin: SupabaseClient,
): Promise<string> {
  if (channel === "staff_app" || channel === "web_admin") {
    if (!isStaffRole(caller.role)) {
      throw new HttpError(403, `channel '${channel}' requires a staff or admin account`);
    }
    if (!requestedFamilyId) {
      throw new HttpError(400, "familyId is required for staff_app/web_admin channels");
    }
    const { data: family, error } = await admin
      .from("families")
      .select("id")
      .eq("id", requestedFamilyId)
      .single();
    if (error || !family) throw new HttpError(404, "familyId not found");
    return family.id;
  }

  // customer_app
  if (caller.role !== "customer") {
    throw new HttpError(403, "channel 'customer_app' requires a customer account");
  }
  const { data: family, error } = await admin
    .from("families")
    .select("id")
    .eq("owner_profile_id", caller.id)
    .single();
  if (error || !family) {
    // Every profile gets a families row on signup (handle_new_user trigger) — this should never happen.
    throw new HttpError(500, "No family record found for this account");
  }
  return family.id;
}
