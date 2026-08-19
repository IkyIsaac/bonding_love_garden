"use client";

import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";

/**
 * A plain `<a href="/login">` looked right but never worked: the session
 * middleware (lib/supabase/middleware.ts) redirects *any* authenticated
 * user away from /login back to /dashboard, regardless of role — it only
 * checks "is there a session", the admin check happens here in the layout.
 * So a signed-in-but-non-admin account (e.g. a cashier trying the web
 * dashboard) bounced forever between this page and /login. The actual fix
 * is signing out first, same as the sidebar's own UserMenu does, so the
 * middleware sees no session and actually lets /login render.
 */
export default function NotAuthorizedActions() {
  const router = useRouter();
  const supabase = createClient();

  async function backToLogin() {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <Button variant="outline" onClick={backToLogin}>
      Back to login
    </Button>
  );
}
