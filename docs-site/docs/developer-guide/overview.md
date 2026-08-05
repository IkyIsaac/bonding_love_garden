---
sidebar_position: 1
---

# Developer Guide

Bonding Love Garden is a reusable play park management platform: a Flutter mobile app (Customer + Staff experiences), a Next.js web admin dashboard, and a Supabase backend (Postgres, Auth, Realtime, Storage, Edge Functions).

This guide explains **how** each part was built and why. For what the platform does and how to use it, see the [User Guide](../user-guide/overview.md). For the original functional spec and the full architecture plan (schema, RLS design, Edge Function responsibilities, build order), see `docs/Bonding_Love_Garden_Project_Brief.md` and `docs/ARCHITECTURE_PLAN.md` in the repo root — this site is a narrative companion to those, not a replacement.

## Repo layout

```
backend/    Supabase project — migrations, Edge Functions, seed data
web/        Next.js admin dashboard (owner/manager)
mobile/     Flutter app — Customer (primary) + Staff (assisted) experiences
docs-site/  This documentation site (Docusaurus)
docs/       Spec, architecture plan, design mockups
PROGRESS.md Living build tracker — what's done, what's next
```

A monorepo, not separate repos — most changes here are cross-cutting (a schema change touches a migration, an Edge Function, and a UI page in the same sitting), so one PR beats coordinating three.

## Core design principles carried through every layer

- **Single-tenant per deployment.** One Supabase project = one venue. "Reusable" means fork + redeploy with new config data, not a shared multi-tenant database.
- **No hardcoded branding, games, or pricing.** All of it lives in `venue_settings`, `catalog_items`, `access_plans`, `entry_fee_config`, `discount_rules` — owner-configured through the admin dashboard, never baked into code.
- **Payments are pluggable.** Selcom, Snippe, and Payguard are rows in `payment_providers`, not an enum, each implementing the same `PaymentProvider` interface.
- **RLS is the real authorization boundary**, not application-level checks alone. Financial write paths (orders, payments, wristbands) deliberately have *no* client-writable RLS policy at all — only the service role (used by Edge Functions) and admin can write them.

## Where to go next

- [Database Schema](./database-schema.md) — tables, RLS strategy, the bugs that were caught by testing rather than review
- [Edge Functions](./edge-functions.md) — what each function does and why
- [Web Admin](./web-admin.md) — auth pattern and the config CRUD pages
