import Card from "./card";

export default function StatTile({
  label,
  value,
  sublabel,
}: {
  label: string;
  value: string;
  sublabel?: string;
}) {
  return (
    <Card className="flex flex-col gap-1">
      <span className="text-sm text-on-surface-variant">{label}</span>
      <span className="font-heading text-3xl font-bold text-on-surface">{value}</span>
      {sublabel && <span className="text-xs text-on-surface-variant">{sublabel}</span>}
    </Card>
  );
}
