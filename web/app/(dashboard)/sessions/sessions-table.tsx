import Badge from "@/components/ui/badge";
import DataTable, { type Column } from "@/components/ui/data-table";
import SessionActions from "./session-actions";
import SessionsAutoRefresh from "./sessions-auto-refresh";

export interface SessionRow {
  id: string;
  beneficiaryName: string;
  gameName: string | null;
  startedAt: string;
  plannedEndAt: string;
  endedAt: string | null;
  status: string;
}

const STATUS_TONE: Record<string, "neutral" | "success" | "warning" | "error"> = {
  active: "success",
  expiring_soon: "warning",
  expired: "error",
  ended: "neutral",
};

function formatRemaining(plannedEndAt: string, ended: boolean): string {
  if (ended) return "—";
  const diffMs = new Date(plannedEndAt).getTime() - Date.now();
  const sign = diffMs < 0 ? "-" : "";
  const totalMinutes = Math.floor(Math.abs(diffMs) / 60000);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${sign}${hours > 0 ? `${hours}h ` : ""}${minutes}m`;
}

export default function SessionsTable({ sessions }: { sessions: SessionRow[] }) {
  const columns: Column<SessionRow>[] = [
    { header: "Guest", render: (r) => r.beneficiaryName },
    { header: "Game", render: (r) => r.gameName ?? "—" },
    { header: "Status", render: (r) => <Badge tone={STATUS_TONE[r.status]}>{r.status.replace("_", " ")}</Badge> },
    { header: "Time remaining", render: (r) => formatRemaining(r.plannedEndAt, !!r.endedAt) },
    {
      header: "",
      className: "text-right",
      render: (r) => <SessionActions id={r.id} ended={!!r.endedAt} />,
    },
  ];

  return (
    <>
      <SessionsAutoRefresh />
      <DataTable columns={columns} rows={sessions} emptyMessage="No sessions right now." />
    </>
  );
}
