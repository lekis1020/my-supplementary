# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NutriCompare (내 영양제 비교) — a supplement comparison platform that lets consumers compare nutritional supplements using trusted regulatory and scientific evidence data. Korean-language primary UI with bilingual data (KR/US).

## Commands

### Web App (run from `web/`)
```bash
npm run dev          # Start dev server (Next.js) at localhost:3000
npm run build        # Production build
npm run lint         # ESLint
```

### KR Government Data Pipeline (run from `web/`)
```bash
npm run gov:smoke:kr              # Test KR government API connectivity
npm run gov:backfill:kr           # Fetch raw data from KR gov APIs
npm run gov:import-staging:kr     # Load raw data into staging tables
npm run gov:import-core:kr        # Normalize ingredients & products into main tables
npm run gov:import-claims:kr      # Import functional claims
npm run gov:import-dosage:kr      # Import dosage guidelines
npm run gov:import-labels:kr      # Import label snapshots
npm run gov:import-safety:kr      # Import safety warnings
```

### Database
- **Schema DDL**: `db/001_schema.sql` (28+ tables, canonical source of truth)
- **All-in-one migration**: `db/RUN_THIS_ONLY.sql` (consolidated: schema + seeds + enrichments)
- **RLS policies**: `db/002_rls_policies.sql`
- **Drizzle config**: `db/drizzle/drizzle.config.ts` (schema at `db/drizzle/schema/`)

## Architecture

### Hybrid ORM Strategy (critical design decision)
- **Consumer-facing pages** use `@supabase/ssr` (server/client) with RLS enforcing `is_published = TRUE` automatically
  - `web/src/lib/supabase/server.ts` — Server Component Supabase client
  - `web/src/lib/supabase/client.ts` — Browser Supabase client
- **Admin/pipeline operations** use Drizzle ORM with `service_role` key (bypasses RLS)
- Never mix these: consumer pages must go through Supabase Client to respect RLS

### Data Model
Everything connects through `ingredient_id` as the central axis. Key relationships:
- `ingredients` → `ingredient_claims` → `claims` (functional health claims)
- `ingredients` → `safety_items` / `ingredient_drug_interactions`
- `ingredients` → `product_ingredients` → `products` → `label_snapshots`
- `ingredients` → `evidence_studies` → `evidence_outcomes`
- `sources` → `source_links` (polymorphic, connects any entity to its data source)

### Regulatory vs Scientific Data Separation
The platform must always visually separate:
1. **Regulator-approved claims** (`is_regulator_approved = true`, `approval_country_code`) — shown with official badge
2. **Academic research findings** — shown with evidence grade (A-I)
3. **Non-permitted expressions** — never displayed as health claims

This separation is a legal compliance requirement, not a UI preference.

### Data Collection Pipeline (4-layer)
```
Source Access → Orchestration → Normalization → Publishing
(connectors)   (jobs/runs)     (raw→parsed)    (review→publish)
```
- Raw-first: always preserve original data in `raw_documents` before parsing
- Confidence-based publishing: ≥0.95 auto-publish, 0.70-0.95 conditional, <0.70 manual review
- 3-level review chain: L1 (auto QA) → L2 (scientific) → L3 (regulatory)

### Path Aliases
`@/*` maps to `web/src/*` (configured in `tsconfig.json`)

### App Router Pages
- `/` — Landing with search, ingredient dictionary, product comparison CTAs
- `/ingredients` — Ingredient list with category filter
- `/ingredients/[slug]` — Ingredient detail (claims, safety, dosage, evidence)
- `/ingredients/category/[category]` — Category-filtered ingredient list
- `/products` — Product list
- `/products/[id]` — Product detail (label info, ingredient composition)
- `/compare` — Side-by-side product comparison (max 4)
- `/search` — Unified search (pg_tsvector)
- `/design-lab` — UI experimentation page
- `/disclaimer` — Medical disclaimer (legally required on all deployments)

### Environment Variables
Required in `web/.env.local` (see `web/.env.local.example`):
- `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` — Supabase project
- `SUPABASE_SERVICE_ROLE_KEY` — server-side only, for admin/pipeline
- `DATABASE_URL` — Drizzle migrations/seeds
- `FOODSAFETY_KOREA_API_KEY` / `DATA_GO_KR_SERVICE_KEY_*` — KR gov API (optional, for data pipeline)

## Key Conventions

- **Language**: UI text is Korean. Code (variables, comments in source) is English. Data has bilingual fields (`*_ko`, `*_en`).
- **Ingredient naming**: 3-name principle — `display_name` (UI), `canonical_name` (matching), `form` (bioavailability/evidence linking).
- **Soft delete**: External data is never hard-deleted. Use status: `active` / `inactive` / `superseded` / `source_missing`.
- **SQL migrations**: Numbered sequentially (`001_`, `002_`, ...). Drizzle schema in `db/drizzle/schema/` mirrors the SQL DDL.
- **Seed data files**: `003`-`020` contain ingredient, product, evidence, and label seed data. `RUN_THIS_ONLY.sql` consolidates everything.
