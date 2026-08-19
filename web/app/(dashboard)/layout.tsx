import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { Separator } from "@/components/ui/separator";
import NavMenu from "./nav-menu";
import UserMenu from "./user-menu";
import NotAuthorizedActions from "./not-authorized-actions";

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
      <div className="flex min-h-screen items-center justify-center bg-background p-8">
        <div className="text-center max-w-sm">
          <h1 className="font-heading text-xl font-bold text-foreground mb-2">Not authorized</h1>
          <p className="text-muted-foreground mb-6">
            This account doesn&apos;t have admin access to the dashboard.
          </p>
          <NotAuthorizedActions />
        </div>
      </div>
    );
  }

  return (
    <SidebarProvider>
      <Sidebar collapsible="icon">
        <SidebarHeader className="p-4">
          <div className="flex items-center gap-2 px-1 font-heading font-bold text-lg leading-tight">
            <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground text-sm">
              BL
            </span>
            <span className="truncate group-data-[collapsible=icon]:hidden">Bonding Love Garden</span>
          </div>
        </SidebarHeader>
        <SidebarContent className="px-2">
          <NavMenu />
        </SidebarContent>
        <SidebarFooter>
          <UserMenu name={profile.full_name || "Admin"} />
        </SidebarFooter>
      </Sidebar>
      <SidebarInset className="min-w-0">
        <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border px-4">
          <SidebarTrigger />
          <Separator orientation="vertical" className="h-5" />
          <span className="font-heading font-semibold text-foreground">Admin Dashboard</span>
        </header>
        <main className="min-w-0 flex-1 bg-background p-6 md:p-8 overflow-y-auto">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
