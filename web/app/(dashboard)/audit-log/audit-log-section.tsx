"use client";

import { useMemo, useState } from "react";
import Card from "@/components/ui/card";
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
      <div className="flex items-center justify-between mb-4 gap-4 flex-wrap">
        <h2 className="font-heading font-bold text-on-surface">Audit Log</h2>
        <div className="flex gap-2">
          <select
            value={actionType}
            onChange={(e) => setActionType(e.target.value)}
            className="rounded-lg border border-outline-variant px-3 py-2 text-sm focus:border-primary focus:outline-none"
          >
            {actionTypes.map((t) => (
              <option key={t} value={t}>{t === "all" ? "All actions" : t.replace(/_/g, " ")}</option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Search staff, details, location…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-64 rounded-lg border border-outline-variant px-3 py-2 text-sm focus:border-primary focus:outline-none"
          />
        </div>
      </div>
      <DataTable columns={columns} rows={filtered} emptyMessage="No audit log entries yet." />
      <p className="text-xs text-on-surface-variant mt-3">
        Showing {filtered.length} of {entries.length} — insert-only, written exclusively by Edge Functions using the service role. Not even admin can edit these via the API.
      </p>
    </Card>
  );
}
