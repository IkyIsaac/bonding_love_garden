export default function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-xl bg-white border border-outline-variant p-6 shadow-sm ${className}`}>
      {children}
    </div>
  );
}
