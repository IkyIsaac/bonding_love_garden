# Bonding Love Garden — Play Park Management Platform

Reusable play park / family entertainment venue management platform: a Flutter mobile app (Customer + Staff experiences), a Next.js web admin dashboard, and a Supabase backend (Postgres, Auth, Realtime, Storage, Edge Functions).

- **Spec:** [`docs/Bonding_Love_Garden_Project_Brief.md`](docs/Bonding_Love_Garden_Project_Brief.md)
- **Architecture, schema, RLS, Edge Functions, build order:** [`docs/ARCHITECTURE_PLAN.md`](docs/ARCHITECTURE_PLAN.md)
- **UI design reference (Stitch mockups + design system):** [`docs/design/`](docs/design/)

## Layout

```
backend/   Supabase project — migrations, Edge Functions, seed data
web/       Next.js admin dashboard (owner/manager)
mobile/    Flutter app — Customer (primary) + Staff (assisted) experiences
docs/      Spec, architecture plan, design mockups
```

## Getting started

**Backend**
```
cd backend
npm install
npm run supabase:start   # requires Docker
```

**Web**
```
cd web
pnpm install
cp .env.example .env.local   # fill in local Supabase URL/anon key
pnpm dev
```

**Mobile**
```
cd mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Principles

- **Single-tenant per deployment.** One Supabase project per venue. Reuse/white-labeling = fork + redeploy with new config data, not a shared multi-tenant database. See the top of `ARCHITECTURE_PLAN.md`.
- **No hardcoded branding, games, or pricing.** All of it is data in `venue_settings`, `catalog_items`, `access_plans`, `entry_fee_config`, `discount_rules` — configured by the venue owner through the admin dashboard.
- **Payments are pluggable.** Providers are rows in `payment_providers`, not an enum. Selcom, Snippe, and Payguard each implement the same `PaymentProvider` interface in `backend/supabase/functions/_shared/payments/`.
