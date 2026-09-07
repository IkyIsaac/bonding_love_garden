"use client";

import { useMemo, useState } from "react";
import { Search } from "lucide-react";
import { cancelReservation } from "./actions";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Badge from "@/components/ui/badge";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";

export interface ReservationRow {
  id: string;
  subscriberName: string;
  planName: string;
  gameId: string;
  gameName: string;
  slotStart: string;
  slotEnd: string;
  fee: number;
  status: string;
}

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  booked: "success",
  checked_in: "success",
  cancelled: "error",
  no_show: "warning",
};

export default function ReservationsSection({
  reservations,
  games,
}: {
  reservations: ReservationRow[];
  games: { id: string; name: string }[];
}) {
  const [search, setSearch] = useState("");
  const [gameId, setGameId] = useState("all");
  const [status, setStatus] = useState("all");

  const statuses = useMemo(() => ["all", ...new Set(reservations.map((r) => r.status))], [reservations]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return reservations.filter((r) => {
      if (gameId !== "all" && r.gameId !== gameId) return false;
      if (status !== "all" && r.status !== status) return false;
      if (!q) return true;
      return r.subscriberName.toLowerCase().includes(q) || r.planName.toLowerCase().includes(q);
    });
  }, [reservations, search, gameId, status]);

  const columns: Column<ReservationRow>[] = [
    { header: "Subscriber", render: (r) => r.subscriberName },
    { header: "Game", render: (r) => r.gameName },
    { header: "Plan", render: (r) => r.planName },
    { header: "Slot", render: (r) => `${new Date(r.slotStart).toLocaleString()} – ${new Date(r.slotEnd).toLocaleTimeString()}` },
    { header: "Fee", render: (r) => (r.fee > 0 ? r.fee.toLocaleString() : "Free") },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.status] ?? "neutral"}>{r.status.replace(/_/g, " ")}</Badge> },
    {
      header: "",
      className: "text-right",
      render: (r) =>
        r.status === "booked" ? (
          <DeleteButton
            id={r.id}
            action={cancelReservation}
            label="Cancel"
            confirmMessage="Cancel this reservation? The family will need to rebook if they still want the slot."
          />
        ) : null,
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>All Reservations</CardTitle>
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
        <DataTable columns={columns} rows={filtered} emptyMessage="No reservations booked yet." />
        <p className="text-xs text-muted-foreground mt-3">
          Showing {filtered.length} of {reservations.length}.
        </p>
      </CardContent>
    </Card>
  );
}
