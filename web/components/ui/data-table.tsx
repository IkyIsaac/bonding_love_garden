export interface Column<T> {
  header: string;
  render: (row: T) => React.ReactNode;
  className?: string;
}

export default function DataTable<T extends { id: string }>({
  columns,
  rows,
  emptyMessage = "Nothing here yet.",
}: {
  columns: Column<T>[];
  rows: T[];
  emptyMessage?: string;
}) {
  if (rows.length === 0) {
    return <p className="text-sm text-on-surface-variant py-8 text-center">{emptyMessage}</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-outline-variant text-left text-on-surface-variant">
            {columns.map((col) => (
              <th key={col.header} className="py-2 pr-4 font-medium whitespace-nowrap">
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id} className="border-b border-outline-variant last:border-0">
              {columns.map((col) => (
                <td key={col.header} className={`py-3 pr-4 ${col.className ?? ""}`}>
                  {col.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
