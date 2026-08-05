"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * "Active / expiring soon / expired" is a function of now() vs
 * planned_end_at — a purely time-based transition with no row change at
 * all, so Realtime alone can't catch it (Realtime only fires on actual
 * postgres writes). This does both: a plain interval re-triggers the server
 * component (recomputes session_live_status fresh) to catch time-based
 * transitions, and a Realtime subscription on the underlying `sessions`
 * table (Realtime can't target a view directly) triggers an immediate
 * refresh on any real change (new session, extend, end) instead of waiting
 * for the next tick. Deliberately doesn't duplicate the view's status logic
 * in JS — router.refresh() re-runs the same server-side query every time,
 * so there's exactly one place that logic lives.
 */
export default function SessionsAutoRefresh() {
  const router = useRouter();

  useEffect(() => {
    const supabase = createClient();

    const interval = setInterval(() => router.refresh(), 15000);

    const channel = supabase
      .channel("sessions-changes")
      .on("postgres_changes", { event: "*", schema: "public", table: "sessions" }, () => router.refresh())
      .subscribe();

    return () => {
      clearInterval(interval);
      supabase.removeChannel(channel);
    };
  }, [router]);

  return null;
}
