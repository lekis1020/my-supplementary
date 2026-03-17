This is the web app for the supplement comparison project.

## Environment

Create `web/.env.local` from `web/.env.local.example`.

Required variables:

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
FOODSAFETY_KOREA_API_KEY=
DATA_GO_KR_SERVICE_KEY_ENCODED=
DATA_GO_KR_SERVICE_KEY_DECODED=
```

Notes:

- `NEXT_PUBLIC_*` values are exposed to the browser. Keep API keys out of this prefix.
- `FOODSAFETY_KOREA_API_KEY` is for `foodsafetykorea.go.kr` Open API calls.
- `DATA_GO_KR_SERVICE_KEY_ENCODED` and `DATA_GO_KR_SERVICE_KEY_DECODED` are for `data.go.kr` Open API calls. Some clients or sample URLs expect the encoded key, while server-side code often works better with the decoded key.
- Government API keys should be used only in server-side code, route handlers, scripts, or background jobs.

Smoke test:

```bash
node scripts/test_korean_gov_apis.mjs
```

Reference docs:

- `docs/korean-api-endpoints.md` maps each approved portal item to the real endpoint used by the project.

Backfill raw KR government data:

```bash
npm run gov:backfill:kr
```

Useful options:

```bash
npm run gov:backfill:kr -- --dry-run --limit-pages=1
npm run gov:backfill:kr -- --service=foodsafety-i0030 --out-dir=tmp/kr-gov
```

This script writes record-level API responses into `raw_documents` and updates
`source_connectors`, `collection_jobs`, and `collection_runs`. It requires
`DATABASE_URL` unless you use `--dry-run` or `--out-dir`.

Import KR staging JSONL into database:

```bash
npm run gov:import-staging:kr
```

Useful options:

```bash
npm run gov:import-staging:kr -- --dry-run
npm run gov:import-staging:kr -- --only=products --truncate
npm run gov:import-staging:kr -- --batch-size=1000 --import-batch=kr-stage-v1
```

Before running the importer, apply [012_staging_tables.sql](/Users/napler/.superset/worktrees/my-supplementary/OpenClaw-Backup/update-data-base/db/012_staging_tables.sql).

Import KR core entities directly into hosted Supabase main tables:

```bash
npm run gov:import-core:kr
```

Useful options:

```bash
npm run gov:import-core:kr -- --dry-run
npm run gov:import-core:kr -- --batch-size=500
npm run gov:import-core:kr -- --unpublished
```

This importer uses `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
If `SUPABASE_SERVICE_ROLE_KEY` is not set, it will try to resolve the linked
project's service role key via the `supabase` CLI.

Import KR claims and ingredient-claim links into hosted Supabase:

```bash
npm run gov:import-claims:kr
```

Useful options:

```bash
npm run gov:import-claims:kr -- --dry-run
npm run gov:import-claims:kr -- --batch-size=250
```

This importer expects the claim normalization migration to be applied first.

Import KR dosage guidelines into hosted Supabase:

```bash
npm run gov:import-dosage:kr
```

Useful options:

```bash
npm run gov:import-dosage:kr -- --dry-run
npm run gov:import-dosage:kr -- --batch-size=250
```

This importer reads KR ingredient profiles and writes normalized daily intake
guidelines into `dosage_guidelines`.

Import KR product label text snapshots into hosted Supabase:

```bash
npm run gov:import-labels:kr
```

Useful options:

```bash
npm run gov:import-labels:kr -- --dry-run
npm run gov:import-labels:kr -- --batch-size=250
```

This importer writes one current `label_snapshots` row per product when
directions, warnings, storage text, or standards text are available.

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
