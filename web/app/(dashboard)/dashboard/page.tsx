import Link from "next/link";
import { Users, Wallet, ShoppingBag, CalendarClock, ArrowRight } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import StatTile from "@/components/ui/stat-tile";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

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
        <h1 className="font-heading text-2xl font-bold text-foreground mb-1">Dashboard</h1>
        <p className="text-sm text-muted-foreground">Today at a glance.</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatTile
          icon={Users}
          label="Guests in park now"
          value={String((liveSessions ?? []).length)}
          sublabel="active + expiring soon"
        />
        <StatTile icon={Wallet} label="Revenue today" value={revenueToday.toLocaleString()} sublabel="TZS" />
        <StatTile icon={ShoppingBag} label="Plans sold today" value={String(plansSoldToday)} />
        <StatTile
          icon={CalendarClock}
          label="Memberships expiring soon"
          value={String((expiringSoon ?? []).length)}
          sublabel="within 7 days"
        />
      </div>

      <Card>
        <CardContent className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <p className="text-sm text-muted-foreground">
            For revenue trends, top plans and popular games, see Reports. For live per-guest session details, see
            Active Sessions.
          </p>
          <div className="flex gap-2 shrink-0">
            <Button variant="outline" size="sm" render={<Link href="/reports" />}>
              Reports <ArrowRight />
            </Button>
            <Button variant="outline" size="sm" render={<Link href="/sessions" />}>
              Active Sessions <ArrowRight />
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
