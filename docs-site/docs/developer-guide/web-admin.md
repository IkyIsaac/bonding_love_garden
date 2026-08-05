---
sidebar_position: 4
---

# Web Admin

Next.js (App Router) + Tailwind v4, using the Botanical Play design tokens ported from `docs/design/botanical_play/DESIGN.md` — the same palette/type scale/radii as the Flutter app, defined once in `web/app/globals.css` as Tailwind v4 `@theme` variables.

## Auth

Phone OTP via Supabase Auth, matching the mobile app — there's no separate admin login mechanism. `web/middleware.ts` (well, `proxy.ts` — Next.js 16 renamed the convention) refreshes the session and redirects unauthenticated requests to `/login`. The `(dashboard)` route group's layout is a server component that additionally checks `profiles.role === 'admin'`, since middleware alone can't cheaply do that DB round-trip on every request — an authenticated-but-non-admin user sees a clear "not authorized" screen instead of dashboard content.

Local dev uses Supabase's test phone numbers (configured in `backend/supabase/config.toml`) rather than a real SMS provider — no code difference from production, just a Dashboard/config setting.

## Data access pattern

Server Components fetch data directly with the server-side Supabase client (`lib/supabase/server.ts`), respecting RLS via the request's own cookies. Mutations are Next.js Server Actions (`actions.ts` per route) — plain `async function` calls from the client, no hand-rolled API routes. Every mutation goes through the same RLS-gated path a real admin session would use; there's no service-role shortcut in the web app anywhere, unlike the Edge Functions.

## Config CRUD pages

- **Settings** (`/settings`) — single-row edit form for `venue_settings`.
- **Plan Builder** (`/plans`) — three sections on one page: entry fee (insert-only, see the schema doc's auto-close trigger), games/services (`catalog_items`), and access plans with an included-items multi-select.
- **Discounts** (`/discounts`) — rule list + editor, including the qualifying-components picker (catalog items + an "Entry Fee" sentinel option) that mirrors exactly how `discount-engine.ts` matches a cart.
- **Packages** (`/packages`) — bundle editor with per-item quantities and an availability window.

All four share a small set of primitives in `web/components/ui/` (`Button`, `Card`, `Badge`, `Modal`, `DataTable`, form fields, `DeleteButton`) rather than each page inventing its own list/form chrome.

## What's not built yet

Staff management, wristband/session monitoring, reports, and the audit log viewer — the remaining §6 modules from the architecture plan. See `PROGRESS.md` for current status.
