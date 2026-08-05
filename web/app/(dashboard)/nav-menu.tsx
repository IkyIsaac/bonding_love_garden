"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Layers,
  Percent,
  Package,
  QrCode,
  Activity,
  BarChart3,
  ScrollText,
  Settings,
  type LucideIcon,
} from "lucide-react";
import { SidebarMenu, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar";

const NAV_ITEMS: { href: string; label: string; icon: LucideIcon }[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/staff", label: "Staff Management", icon: Users },
  { href: "/plans", label: "Plan Builder", icon: Layers },
  { href: "/discounts", label: "Discount Rules", icon: Percent },
  { href: "/packages", label: "Packages", icon: Package },
  { href: "/wristbands", label: "Wristbands", icon: QrCode },
  { href: "/sessions", label: "Active Sessions", icon: Activity },
  { href: "/reports", label: "Reports", icon: BarChart3 },
  { href: "/audit-log", label: "Audit Log", icon: ScrollText },
  { href: "/settings", label: "Settings", icon: Settings },
];

export default function NavMenu() {
  const pathname = usePathname();

  return (
    <SidebarMenu>
      {NAV_ITEMS.map((item) => {
        const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
        return (
          <SidebarMenuItem key={item.href}>
            <SidebarMenuButton isActive={active} tooltip={item.label} render={<Link href={item.href} />}>
              <item.icon />
              <span>{item.label}</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        );
      })}
    </SidebarMenu>
  );
}
