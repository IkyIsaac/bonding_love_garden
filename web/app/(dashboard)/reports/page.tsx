import { Wallet, CalendarRange, Activity, CalendarClock } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import StatTile from "@/components/ui/stat-tile";
import DataTable from "@/components/ui/data-table";

/**
 * Aggregation done in JS on the server component rather than a Postgres
 * view/RPC, unlike the developer guide's stated preference (SQL beats a
 * round-trip for pure aggregation) — a deliberate first-pass shortcut given
 * how small the data volume is right now, not a reversal of that principle.
 * Worth moving to a real view/RPC once there's enough order volume for it
 * to matter.
 */
export default async function ReportsPage() {
  const supabase = await createClient();

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(startOfToday);
  startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());

  const [{ data: paidOrders }, { data: planItems }, { data: accessPlans }, { data: sessions }, { data: catalogItems }] =
    await Promise.all([
      supabase.from("orders").select("id, total_amount, created_at").eq("status", "paid"),
      supabase.from("order_items").select("reference_id, quantity, line_total").eq("item_type", "access_plan"),
      supabase.from("access_plans").select("id, name"),
      supabase.from("sessions").select("id, catalog_item_id, started_at"),
      supabase.from("catalog_items").select("id, name"),
    ]);

  const revenueToday = (paidOrders ?? [])
    .filter((o) => new Date(o.created_at) >= startOfToday)
    .reduce((sum, o) => sum + o.total_amount, 0);
  const revenueThisWeek = (paidOrders ?? [])
    .filter((o) => new Date(o.created_at) >= startOfWeek)
    .reduce((sum, o) => sum + o.total_amount, 0);

  const sessionsToday = (sessions ?? []).filter((s) => new Date(s.started_at) >= startOfToday).length;
  const sessionsThisWeek = (sessions ?? []).filter((s) => new Date(s.started_at) >= startOfWeek).length;

  const planNameById = new Map((accessPlans ?? []).map((p) => [p.id, p.name]));
  const planSales = new Map<string, { name: string; quantity: number; revenue: number }>();
  for (const item of planItems ?? []) {
    if (!item.reference_id) continue;
    const name = planNameById.get(item.reference_id) ?? "Unknown plan";
    const existing = planSales.get(item.reference_id) ?? { name, quantity: 0, revenue: 0 };
    existing.quantity += item.quantity;
    existing.revenue += item.line_total;
    planSales.set(item.reference_id, existing);
  }
  const topPlans = [...planSales.values()].sort((a, b) => b.revenue - a.revenue).slice(0, 5);
  const maxPlanRevenue = Math.max(1, ...topPlans.map((p) => p.revenue));

  const catalogNameById = new Map((catalogItems ?? []).map((c) => [c.id, c.name]));
  const gameCounts = new Map<string, number>();
  for (const s of sessions ?? []) {
    if (!s.catalog_item_id) continue;
    gameCounts.set(s.catalog_item_id, (gameCounts.get(s.catalog_item_id) ?? 0) + 1);
  }
  const popularGames = [...gameCounts.entries()]
    .map(([id, count]) => ({ name: catalogNameById.get(id) ?? "Unknown", count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);
  const maxGameCount = Math.max(1, ...popularGames.map((g) => g.count));

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Reports</h1>
        <p className="text-sm text-muted-foreground">Revenue, attendance, and popularity, computed from live order/session data.</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatTile icon={Wallet} label="Revenue today" value={revenueToday.toLocaleString()} sublabel="TZS" />
        <StatTile icon={CalendarRange} label="Revenue this week" value={revenueThisWeek.toLocaleString()} sublabel="TZS" />
        <StatTile icon={Activity} label="Sessions today" value={String(sessionsToday)} />
        <StatTile icon={CalendarClock} label="Sessions this week" value={String(sessionsThisWeek)} />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Top Plans by Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={[
              {
                header: "Plan",
                render: (r) => (
                  <div className="flex flex-col gap-1 min-w-40">
                    <span>{r.name}</span>
                    <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden">
                      <div
                        className="h-full rounded-full bg-primary"
                        style={{ width: `${(r.revenue / maxPlanRevenue) * 100}%` }}
                      />
                    </div>
                  </div>
                ),
              },
              { header: "Sold", render: (r) => String(r.quantity) },
              { header: "Revenue", render: (r) => r.revenue.toLocaleString() },
            ]}
            rows={topPlans.map((p, i) => ({ id: String(i), ...p }))}
            emptyMessage="No plan sales yet."
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Most Popular Games</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={[
              {
                header: "Game",
                render: (r) => (
                  <div className="flex flex-col gap-1 min-w-40">
                    <span>{r.name}</span>
                    <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden">
                      <div
                        className="h-full rounded-full bg-accent"
                        style={{ width: `${(r.count / maxGameCount) * 100}%` }}
                      />
                    </div>
                  </div>
                ),
              },
              { header: "Sessions", render: (r) => String(r.count) },
            ]}
            rows={popularGames.map((g, i) => ({ id: String(i), ...g }))}
            emptyMessage="No sessions recorded yet."
          />
        </CardContent>
      </Card>
    </div>
  );
}
