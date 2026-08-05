"use client";

import { useMemo, useState } from "react";
import { Search } from "lucide-react";
import { revokeWristband } from "./actions";
import { Card, CardAction, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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
      <CardHeader>
        <CardTitle>All Wristbands</CardTitle>
        <CardAction>
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search by name or wristband #"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-64 pl-8"
            />
          </div>
        </CardAction>
      </CardHeader>
      <CardContent>
        <DataTable columns={columns} rows={filtered} emptyMessage="No wristbands issued yet." />
      </CardContent>
    </Card>
  );
}
