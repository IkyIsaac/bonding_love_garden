"use client";

import { useMemo, useState } from "react";
import { revokeWristband } from "./actions";
import Card from "@/components/ui/card";
import Badge from "@/components/ui/badge";
import DataTable, { type Column } from "@/components/ui/data-table";
import DeleteButton from "@/components/ui/delete-button";

export interface WristbandRow {
  id: string;
  wristband_number: string;
  qr_code_value: string;
  beneficiaryName: string;
  live_status: string;
  expires_at: string;
  last_scanned_at: string | null;
}

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  active: "success",
  expired: "warning",
  revoked: "error",
};

export default function WristbandsSection({ wristbands }: { wristbands: WristbandRow[] }) {
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return wristbands;
    return wristbands.filter(
      (w) =>
        w.beneficiaryName.toLowerCase().includes(q) ||
        w.wristband_number.toLowerCase().includes(q) ||
        w.qr_code_value.toLowerCase().includes(q),
    );
  }, [wristbands, search]);

  const columns: Column<WristbandRow>[] = [
    { header: "Wristband #", render: (r) => <span className="font-mono text-xs">{r.wristband_number}</span> },
    { header: "Beneficiary", render: (r) => r.beneficiaryName },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.live_status]}>{r.live_status}</Badge> },
    { header: "Expires", render: (r) => new Date(r.expires_at).toLocaleString() },
    { header: "Last scanned", render: (r) => (r.last_scanned_at ? new Date(r.last_scanned_at).toLocaleString() : "Never") },
    {
      header: "",
      className: "text-right",
      render: (r) =>
        r.live_status !== "revoked" ? (
          <DeleteButton
            id={r.id}
            action={revokeWristband}
            label="Revoke"
            confirmMessage="Revoke this wristband? The holder will no longer be able to use it to enter."
          />
        ) : null,
    },
  ];

  return (
    <Card>
      <div className="flex items-center justify-between mb-4 gap-4">
        <h2 className="font-heading font-bold text-on-surface">All Wristbands</h2>
        <input
          type="text"
          placeholder="Search by name or wristband #"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-64 rounded-lg border border-outline-variant px-3 py-2 text-sm focus:border-primary focus:outline-none"
        />
      </div>
      <DataTable columns={columns} rows={filtered} emptyMessage="No wristbands issued yet." />
    </Card>
  );
}
