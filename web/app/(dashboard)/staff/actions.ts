"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface FormState {
  error?: string;
  success?: boolean;
}

const STAFF_ROLES = ["cashier", "attendant", "supervisor", "admin"] as const;
const APPROVAL_STATUSES = ["pending", "approved", "rejected", "suspended"] as const;

/**
 * Creating a new staff account requires creating a real auth.users row,
 * which only the GoTrue admin API (service role) can do — not reachable via
 * a normal RLS-respecting client call. Delegates to the admin-create-staff
 * Edge Function, passing the caller's own session token so the function can
 * verify admin role itself (same auth pattern as every other Edge
 * Function) — this app has no service-role client of its own.
 */
export async function createStaff(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { error: "Not authenticated" };

  const phone = String(formData.get("phone") ?? "").trim();
  const fullName = String(formData.get("fullName") ?? "").trim();
  const role = String(formData.get("role") ?? "");

  if (!phone) return { error: "Phone is required" };
  if (!fullName) return { error: "Full name is required" };
  if (!STAFF_ROLES.includes(role as (typeof STAFF_ROLES)[number])) return { error: "Invalid role" };

  const res = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/admin-create-staff`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ phone, fullName, role }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    return { error: body.error ?? `Failed to create staff account (${res.status})` };
  }

  revalidatePath("/staff");
  return { success: true };
}

/**
 * Editing an existing staff member's role/approval status DOESN'T need the
 * Edge Function — admin already has direct RLS UPDATE rights on profiles
 * (prevent_profile_privilege_escalation only blocks non-admins from
 * changing these fields, admin is explicitly exempt).
 */
export async function updateStaff(_prev: FormState, formData: FormData): Promise<FormState> {
  const supabase = await createClient();

  const id = String(formData.get("id") ?? "");
  const role = String(formData.get("role") ?? "");
  const approvalStatus = String(formData.get("approvalStatus") ?? "");

  if (!id) return { error: "Missing id" };
  if (!STAFF_ROLES.includes(role as (typeof STAFF_ROLES)[number])) return { error: "Invalid role" };
  if (!APPROVAL_STATUSES.includes(approvalStatus as (typeof APPROVAL_STATUSES)[number])) {
    return { error: "Invalid approval status" };
  }

  const { error } = await supabase
    .from("profiles")
    .update({ role, approval_status: approvalStatus })
    .eq("id", id);
  if (error) return { error: error.message };

  revalidatePath("/staff");
  return { success: true };
}
