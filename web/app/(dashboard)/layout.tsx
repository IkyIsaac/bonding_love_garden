import Link from "next/link";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/staff", label: "Staff Management" },
  { href: "/plans", label: "Plan Builder" },
  { href: "/discounts", label: "Discount Rules" },
  { href: "/packages", label: "Packages" },
  { href: "/wristbands", label: "Wristbands" },
  { href: "/sessions", label: "Active Sessions" },
  { href: "/reports", label: "Reports" },
  { href: "/audit-log", label: "Audit Log" },
  { href: "/settings", label: "Settings" },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen">
      <aside className="w-60 shrink-0 border-r border-neutral-200 dark:border-neutral-800 p-4">
        <div className="font-semibold mb-6">Admin Dashboard</div>
        <nav className="flex flex-col gap-1">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-md px-3 py-2 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-900"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </aside>
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
