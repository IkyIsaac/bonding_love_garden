import { createClient } from "@/lib/supabase/server";
import StaffSection from "./staff-section";

export default async function StaffPage() {
  const supabase = await createClient();
  const { data: staff } = await supabase
    .from("profiles")
    .select("id, phone, full_name, role, approval_status, created_at")
    .neq("role", "customer")
    .order("created_at", { ascending: false });

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Staff Management</h1>
      <p className="text-sm text-on-surface-variant mb-6">Cashiers, attendants, supervisors, and admins.</p>
      <StaffSection staff={staff ?? []} />
    </div>
  );
}
