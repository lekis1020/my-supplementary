# GEMINI.md - My Supplementary (영양제/건강기능식품 비교 분석 플랫폼)

## Project Overview
**My Supplementary** is a comprehensive platform for comparing dietary supplements based on scientific evidence, regulatory data, and safety information. It aims to provide reliable, data-driven insights for consumers, experts, and operators.

### Key Technologies
- **Frontend**: Next.js 16 (App Router), React 19, Tailwind CSS 4, Lucide React.
- **Backend**: Supabase (PostgreSQL, Auth, Row Level Security).
- **ORM**: 
  - **Drizzle ORM**: Used for Admin UI, data collection scripts, and complex migrations (bypasses RLS).
  - **Supabase Client**: Used for consumer-facing frontend pages (respects RLS).
- **Data Pipeline**: Python (PubMed fetching), Node.js (KR Gov API normalization/import), Playwright (Label scraping).
- **Infrastructure**: Vercel (Hosting), Cloudflare R2 (Raw document storage).

### Architecture
- **Ingredient-Centric**: The database is centered around `ingredients`, connecting to `claims`, `safety_items`, `evidence_studies`, and `products`.
- **Hybrid Data Layer**:
  - `is_published = TRUE` is enforced via Supabase RLS for public access.
  - Admin/Pipeline operations use the `service_role` key to manage unpublished data and complex joins.
- **Raw-First Pipeline**: Data is first stored in `raw_documents` (HTML/PDF/JSON) before being parsed into structured tables.

---

## Directory Structure
- `web/`: Next.js web application.
  - `src/app/`: App Router pages (ingredients, products, compare, search).
  - `src/components/`: Shared UI components.
  - `src/lib/`: Supabase client and utility functions.
  - `scripts/`: Data import scripts for KR government data.
- `db/`: Database migrations and schema.
  - `drizzle/schema/`: TypeScript definitions of the database schema.
  - `RUN_THIS_ONLY.sql`: Consolidated script for full DB initialization.
- `scripts/`: Data collection scripts (Python-based PubMed fetchers, etc.).
- `docs/`: Technical and product documentation (PRD, Claim Normalization, etc.).
- `supabase/`: Supabase configuration and remote schema migrations.

---

## Building and Running

### Prerequisites
- Node.js 20+
- Supabase Project (or local CLI)
- Python 3.9+ (for evidence fetching)

### 1. Database Setup
Execute the consolidated migration in the Supabase SQL Editor:
- File: `db/RUN_THIS_ONLY.sql`

### 2. Web Application
```bash
cd web
npm install
npm run dev
```

### 3. Data Pipeline (KR Gov Data)
```bash
cd web
npm run gov:backfill:kr      # Fetch raw API data
npm run gov:import-staging:kr # Load into staging tables
npm run gov:import-core:kr    # Normalize into core tables
```

### 4. Evidence Fetching (PubMed)
```bash
python3 scripts/fetch_pubmed_evidence_v2.py
# Generates db/009_seed_evidence.sql
```

---

## Development Conventions

### Coding Standards
- **Strict Typing**: Use TypeScript for all web and schema definitions.
- **UI Components**: Prefer `Tailwind CSS 4` and functional components in `web/src/components`.
- **Naming**: 
  - `ingredients.slug`: URL-friendly identifier.
  - `canonical_name`: System-wide standard name.

### Data Integrity
- **Source Tracing**: All data entries must link to a `source_id` via `source_links`.
- **RLS Awareness**: Always verify `is_published` status when building public-facing features.
- **Three-Level Review**: Data flows from L1 (Auto) -> L2 (Expert Review) -> L3 (Final Approval).

### Testing & Validation
- Use `web/npm run lint` for frontend checks.
- Use `npm run gov:smoke:kr` (mapped to `scripts/test_korean_gov_apis.mjs`) to verify KR Gov API connectivity.
- **Validation Mandate**: Any schema change must be reflected in `db/drizzle/schema/` and documented in `db/`.

---

## Key Files for Reference
- `PLAN.md`: Comprehensive project roadmap and technical strategy.
- `db/001_schema.sql`: Core database structure (28+ tables).
- `docs/PRD.md`: Product Requirements Document.
- `docs/claim-normalization.md`: Detailed specification for decomposing regulatory claims.
