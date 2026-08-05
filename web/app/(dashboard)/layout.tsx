import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "./sign-out-button";

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

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name, role")
    .eq("id", user.id)
    .single();

  if (!profile || profile.role !== "admin") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-surface p-8">
        <div className="text-center max-w-sm">
          <h1 className="font-heading text-xl font-bold text-on-surface mb-2">Not authorized</h1>
          <p className="text-on-surface-variant mb-6">
            This account doesn&apos;t have admin access to the dashboard.
          </p>
          <SignOutButton />
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <aside className="w-64 shrink-0 border-r border-outline-variant bg-white p-6 flex flex-col">
        <div className="font-heading font-bold text-lg text-primary mb-8">Admin Dashboard</div>
        <nav className="flex flex-col gap-1 flex-1">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <div className="border-t border-outline-variant pt-4 mt-4 flex flex-col gap-1">
          <p className="text-sm font-medium text-on-surface truncate">{profile.full_name || "Admin"}</p>
          <SignOutButton />
        </div>
      </aside>
      <main className="flex-1 bg-surface p-8 overflow-y-auto">{children}</main>
    </div>
  );
}
