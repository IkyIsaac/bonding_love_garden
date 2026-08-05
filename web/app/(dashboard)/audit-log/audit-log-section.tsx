"use client";

import { useMemo, useState } from "react";
import { Search } from "lucide-react";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Badge from "@/components/ui/badge";
import DataTable, { type Column } from "@/components/ui/data-table";

export interface AuditLogRow {
  id: string;
  actorName: string;
  actionType: string;
  details: string | null;
  location: string | null;
  status: string;
  createdAt: string;
}

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  success: "success",
  verified: "success",
  failed: "error",
};

export default function AuditLogSection({ entries }: { entries: AuditLogRow[] }) {
  const [search, setSearch] = useState("");
  const [actionType, setActionType] = useState("all");

  const actionTypes = useMemo(() => ["all", ...new Set(entries.map((e) => e.actionType))], [entries]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return entries.filter((e) => {
      if (actionType !== "all" && e.actionType !== actionType) return false;
      if (!q) return true;
      return (
        e.actorName.toLowerCase().includes(q) ||
        (e.details ?? "").toLowerCase().includes(q) ||
        (e.location ?? "").toLowerCase().includes(q)
      );
    });
  }, [entries, search, actionType]);

  const columns: Column<AuditLogRow>[] = [
    { header: "Time", render: (r) => new Date(r.createdAt).toLocaleString() },
    { header: "Staff", render: (r) => r.actorName },
    { header: "Action", render: (r) => <Badge>{r.actionType.replace(/_/g, " ")}</Badge> },
    { header: "Details", render: (r) => r.details ?? "—" },
    { header: "Location", render: (r) => r.location ?? "—" },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.status] ?? "neutral"}>{r.status}</Badge> },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Audit Log</CardTitle>
        <CardAction className="flex gap-2">
          <Select value={actionType} onValueChange={(v) => setActionType(v ?? "all")}>
            <SelectTrigger className="w-40">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {actionTypes.map((t) => (
                <SelectItem key={t} value={t}>{t === "all" ? "All actions" : t.replace(/_/g, " ")}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search staff, details, location…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-64 pl-8"
            />
          </div>
        </CardAction>
      </CardHeader>
      <CardContent>
        <DataTable columns={columns} rows={filtered} emptyMessage="No audit log entries yet." />
        <p className="text-xs text-muted-foreground mt-3">
          Showing {filtered.length} of {entries.length} — insert-only, written exclusively by Edge Functions using the service role. Not even admin can edit these via the API.
        </p>
      </CardContent>
    </Card>
  );
}
