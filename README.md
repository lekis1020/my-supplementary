# My Supplementary

> 영양제/건강기능식품 비교 분석 플랫폼

소비자가 영양제의 원료별 기능성, 과학적 근거, 부작용, 제품 비교를 **신뢰할 수 있는 데이터**로 확인할 수 있는 공개 웹 서비스입니다.

## Key Features

- **원료 중심 구조** — 20종 핵심 원료(비타민 D, 오메가3, 프로바이오틱스 등)에 대한 기능성, 근거 등급, 안전성 정보
- **과학적 근거 기반** — 50+ PubMed 논문의 정량 데이터(효과크기, p-value, 신뢰구간) 수록
- **규제 데이터 연동** — 한국 식약처 + 미국 DSLD/DailyMed 라벨 데이터
- **제품 비교** — 30~50개 제품의 성분 함량, 근거 수준, 가격 대비 함량 비교
- **3단계 검수** — L1(자동) → L2(전문 리뷰어) → L3(최종 승인) 검수 후 게시

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Next.js 16, React 19, Tailwind CSS 4 |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| ORM | Drizzle ORM + Supabase Client (hybrid) |
| Deploy | Vercel + Supabase + Cloudflare R2 |

## Project Structure

```
.
├── db/                         # SQL migrations & seed data
│   ├── 001_schema.sql          # Core DDL (28+ tables)
│   ├── 003_seed_data.sql       # Initial seed (ingredients, claims)
│   ├── 005~011_seed_*.sql      # Supplementary data, products, evidence, labels
│   ├── 013~015_enrich_*.sql    # Evidence enrichment & claim normalization
│   ├── RUN_THIS_ONLY.sql       # All-in-one consolidated migration
│   └── drizzle/                # Drizzle ORM schema definitions
├── web/                        # Next.js web application
│   ├── src/
│   │   ├── app/                # App Router pages
│   │   │   ├── ingredients/    # 원료 목록 & 상세 (/ingredients/[slug])
│   │   │   ├── products/       # 제품 목록 & 상세 (/products/[id])
│   │   │   ├── compare/        # 제품 비교 (최대 4개)
│   │   │   ├── search/         # 통합 검색
│   │   │   ├── design-lab/     # UI 실험 페이지
│   │   │   └── disclaimer/     # 의료 면책 조항
│   │   ├── components/         # UI components (layout, product, ui)
│   │   └── lib/                # Supabase client, types
│   └── scripts/                # Data import scripts (KR gov API)
├── docs/                       # Project documentation
│   ├── PRD.md                  # Product Requirements Document
│   ├── claim-normalization.md  # Claim decomposition spec
│   ├── korean-api-endpoints.md # KR government API reference
│   └── ...
└── supabase/                   # Supabase config & migrations
```

## Database Schema

원료(ingredient) 중심의 관계형 설계. 28개 이상의 테이블:

```
ingredients ─┬─ ingredient_claims ── claims
             ├─ safety_items
             ├─ dosage_guidelines
             ├─ ingredient_drug_interactions
             ├─ evidence_studies ── evidence_outcomes
             └─ product_ingredients ── products ── label_snapshots

sources ── source_links (모든 엔티티에 출처 연결)
source_connectors ── collection_jobs ── collection_runs ── raw_documents
```

## Getting Started

### Prerequisites

- Node.js 20+
- Supabase project (or local via `supabase start`)

### 1. Database Setup

Supabase SQL Editor에서 실행:

```sql
-- 스키마 생성 (최초 1회)
-- db/001_schema.sql 실행

-- 시드 데이터 + 모든 마이그레이션 (한 번에)
-- db/RUN_THIS_ONLY.sql 실행
```

### 2. Web App Setup

```bash
cd web
cp .env.local.example .env.local
# .env.local에 Supabase 키 설정

npm install
npm run dev
```

[http://localhost:3000](http://localhost:3000) 에서 확인.

### Environment Variables

```bash
# Required
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=

# Optional — KR government API
FOODSAFETY_KOREA_API_KEY=
DATA_GO_KR_SERVICE_KEY_ENCODED=
DATA_GO_KR_SERVICE_KEY_DECODED=
```

## Data Pipeline

### KR Government Data Import

한국 정부 API(식약처, 공공데이터포털)에서 건강기능식품 데이터를 수집하여 DB에 적재합니다.

```bash
# 1. Raw API 데이터 수집
npm run gov:backfill:kr

# 2. Staging 테이블에 적재
npm run gov:import-staging:kr

# 3. Main 테이블에 정규화 적재
npm run gov:import-core:kr       # 원료·제품
npm run gov:import-claims:kr     # 기능성·인정 문구
npm run gov:import-dosage:kr     # 용량 가이드라인
npm run gov:import-labels:kr     # 라벨 스냅샷
npm run gov:import-safety:kr     # 안전성 경고
```

### Evidence Data

50건의 PubMed 체계적 문헌고찰/메타분석 논문에서 추출한 정량 근거 데이터:

- 효과크기 (RR, OR, SMD, WMD, HR 등)
- 통계적 유의성 (p-value)
- 신뢰구간 (95% CI)
- 연구 메타데이터 (표본 크기, 대상군, 연구 기간)

## Documentation

| Document | Description |
|----------|-------------|
| [PRD](docs/PRD.md) | Product Requirements Document |
| [Claim Normalization](docs/claim-normalization.md) | 기능성 분해 및 정규화 스펙 |
| [KR API Endpoints](docs/korean-api-endpoints.md) | 한국 정부 API 매핑 |
| [Data Collection Plan](docs/data-collection-plan.md) | 데이터 수집 전략 |
| [Operations Policy](docs/operations-policy.md) | 운영 정책 |
| [Review Process](docs/review-process.md) | 검수 프로세스 |

## MVP Scope

**20종 원료**: 비타민 D, 마그네슘, 오메가3, 프로바이오틱스, 철, 칼슘, 아연, 홍삼, 밀크시슬, 루테인, 코엔자임Q10, 비오틴, 엽산, 비타민 B12, 글루코사민, MSM, 가르시니아, 콜라겐, 크레아틴, 멜라토닌

**23종 기능성 클레임**: 면역, 골건강, 수면, 심혈관, 항산화, 항염증, 장건강, 눈건강, 관절건강, 간건강, 갑상선, 인지기능, 혈당조절, 근력, 체중관리, 정신건강 등

**35+ 제품**, **50+ 논문**, **한국+미국 라벨 데이터**

## Disclaimer

이 서비스는 의학적 조언을 제공하지 않습니다. 모든 정보는 교육 목적이며, 건강 관련 결정은 반드시 의료 전문가와 상담하시기 바랍니다.

## License

Private
