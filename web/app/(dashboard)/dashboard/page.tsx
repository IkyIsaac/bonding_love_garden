import { createClient } from "@/lib/supabase/server";
import StatTile from "@/components/ui/stat-tile";
import Card from "@/components/ui/card";

export default async function DashboardPage() {
  const supabase = await createClient();

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const sevenDaysOut = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  const [{ data: liveSessions }, { data: paidOrdersToday }, { data: expiringSoon }, { data: planSalesToday }] =
    await Promise.all([
      supabase.from("session_live_status").select("status").in("status", ["active", "expiring_soon"]),
      supabase.from("orders").select("total_amount").eq("status", "paid").gte("created_at", startOfToday.toISOString()),
      supabase
        .from("subscriptions")
        .select("id")
        .eq("status", "active")
        .gte("ends_at", now.toISOString())
        .lte("ends_at", sevenDaysOut.toISOString()),
      supabase
        .from("order_items")
        .select("quantity")
        .eq("item_type", "access_plan")
        .gte("created_at", startOfToday.toISOString()),
    ]);

  const revenueToday = (paidOrdersToday ?? []).reduce((sum, o) => sum + o.total_amount, 0);
  const plansSoldToday = (planSalesToday ?? []).reduce((sum, i) => sum + i.quantity, 0);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Dashboard</h1>
        <p className="text-sm text-on-surface-variant">Today at a glance.</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatTile label="Guests in park now" value={String((liveSessions ?? []).length)} sublabel="active + expiring soon" />
        <StatTile label="Revenue today" value={revenueToday.toLocaleString()} />
        <StatTile label="Plans sold today" value={String(plansSoldToday)} />
        <StatTile label="Memberships expiring within 7 days" value={String((expiringSoon ?? []).length)} />
      </div>

      <Card>
        <p className="text-sm text-on-surface-variant">
          For breakdowns — top plans, popular games, revenue trends — see{" "}
          <a href="/reports" className="text-primary underline">Reports</a>. For live per-guest session details, see{" "}
          <a href="/sessions" className="text-primary underline">Active Sessions</a>.
        </p>
      </Card>
    </div>
  );
}
