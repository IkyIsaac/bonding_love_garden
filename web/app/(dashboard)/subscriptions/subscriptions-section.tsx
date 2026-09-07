"use client";

import { useMemo, useState } from "react";
import { Search } from "lucide-react";
import { cancelSubscription } from "./actions";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Badge from "@/components/ui/badge";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";

export interface SubscriptionRow {
  id: string;
  subscriberName: string;
  planName: string;
  gameIds: string[];
  gameNames: string[];
  status: string;
  startsAt: string;
  endsAt: string;
  visitsRemaining: number | null;
}

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  active: "success",
  pending_payment: "warning",
  expired: "neutral",
  cancelled: "error",
  suspended: "error",
};

export default function SubscriptionsSection({
  subscriptions,
  games,
}: {
  subscriptions: SubscriptionRow[];
  games: { id: string; name: string }[];
}) {
  const [search, setSearch] = useState("");
  const [gameId, setGameId] = useState("all");
  const [status, setStatus] = useState("all");

  const statuses = useMemo(() => ["all", ...new Set(subscriptions.map((s) => s.status))], [subscriptions]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return subscriptions.filter((s) => {
      if (gameId !== "all" && !s.gameIds.includes(gameId)) return false;
      if (status !== "all" && s.status !== status) return false;
      if (!q) return true;
      return s.subscriberName.toLowerCase().includes(q) || s.planName.toLowerCase().includes(q);
    });
  }, [subscriptions, search, gameId, status]);

  const columns: Column<SubscriptionRow>[] = [
    { header: "Subscriber", render: (r) => r.subscriberName },
    { header: "Plan", render: (r) => r.planName },
    { header: "Games included", render: (r) => (r.gameNames.length > 0 ? r.gameNames.join(", ") : "—") },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.status] ?? "neutral"}>{r.status.replace(/_/g, " ")}</Badge> },
    { header: "Starts", render: (r) => new Date(r.startsAt).toLocaleDateString() },
    { header: "Ends", render: (r) => new Date(r.endsAt).toLocaleDateString() },
    { header: "Visits left", render: (r) => (r.visitsRemaining ?? "Unlimited") },
    {
      header: "",
      className: "text-right",
      render: (r) =>
        r.status === "active" ? (
          <DeleteButton
            id={r.id}
            action={cancelSubscription}
            label="Cancel"
            confirmMessage="Cancel this subscription? The family will lose access immediately."
          />
        ) : null,
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>All Subscriptions</CardTitle>
        <CardAction className="flex gap-2">
          <Select value={gameId} onValueChange={(v) => setGameId(v ?? "all")}>
            <SelectTrigger className="w-44">
              <SelectValue>{(v: string) => (v === "all" ? "All games" : (games.find((g) => g.id === v)?.name ?? "All games"))}</SelectValue>
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All games</SelectItem>
              {games.map((g) => (
                <SelectItem key={g.id} value={g.id}>
                  {g.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={status} onValueChange={(v) => setStatus(v ?? "all")}>
            <SelectTrigger className="w-40">
              <SelectValue>{(v: string) => (v === "all" ? "All statuses" : v.replace(/_/g, " "))}</SelectValue>
            </SelectTrigger>
            <SelectContent>
              {statuses.map((s) => (
                <SelectItem key={s} value={s}>
                  {s === "all" ? "All statuses" : s.replace(/_/g, " ")}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search subscriber or plan…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-56 pl-8"
            />
          </div>
        </CardAction>
      </CardHeader>
      <CardContent>
        <DataTable columns={columns} rows={filtered} emptyMessage="No subscriptions yet." />
        <p className="text-xs text-muted-foreground mt-3">
          Showing {filtered.length} of {subscriptions.length}.
        </p>
      </CardContent>
    </Card>
  );
}
