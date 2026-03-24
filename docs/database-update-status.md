# 데이터베이스 업데이트 현황 점검

기준: 저장소 SQL 스크립트 기준 정적 점검 (실DB 접속 없이 파일 기반 확인)

## 1) 적용 기준 스크립트 체인

현재 저장소에서 확인되는 업데이트 흐름은 아래 2가지 중 하나입니다.

1. 분할 실행
   - `db/001_schema.sql`
   - `db/004_patch_v1.sql`
   - `db/002_rls_policies.sql`
   - `db/003_seed_data.sql`
   - `db/005_seed_supplementary.sql`
   - `db/008_seed_products_additional.sql`

2. 일괄 실행
   - `db/RUN_THIS_ONLY.sql` (001이 이미 실행된 상태 가정)

## 2) 업데이트 핵심 내용

- 스키마 기준 버전은 `001_schema.sql` 상단 주석 기준 `2.0.0`입니다.
- 패치 `004`에서 `products.is_published` 컬럼이 추가됩니다.
- `002` 및 `RUN_THIS_ONLY`에서 RLS 정책과 `is_admin`, `is_reviewer` 함수가 정의됩니다.
- `003`은 MVP 초기 시드, `005`는 보충 시드(신규 원료 5종 포함), `008`은 추가 제품 시드 확장입니다.

## 3) 현재 상태 해석 (저장소 기준)

- 최신 업데이트 파일은 `008_seed_products_additional.sql`까지 존재합니다.
- 스키마/정책/시드가 "마이그레이션 도구 기반 추적"이 아니라 SQL 파일 실행 순서에 의존합니다.
- 따라서 실제 환경 업데이트 상태를 확정하려면 DB에서 직접 검증 쿼리를 실행해야 합니다.

## 4) 실DB 즉시 점검 SQL

아래 쿼리를 Supabase SQL Editor에서 실행하면 현재 적용 여부를 빠르게 판별할 수 있습니다.

```sql
-- A. 패치 컬럼 적용 여부
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'products'
  AND column_name = 'is_published';

-- B. RLS 활성화 여부(핵심 테이블)
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'ingredients','ingredient_synonyms','claims','ingredient_claims','safety_items',
    'dosage_guidelines','products','product_ingredients','label_snapshots'
  )
ORDER BY tablename;

-- C. 정책 생성 여부(일부)
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('ingredients','products','review_tasks','raw_documents')
ORDER BY tablename, policyname;

-- D. 시드 적재량 점검
SELECT 'ingredients' AS table_name, COUNT(*)::bigint AS cnt FROM ingredients
UNION ALL
SELECT 'products', COUNT(*)::bigint FROM products
UNION ALL
SELECT 'claims', COUNT(*)::bigint FROM claims
UNION ALL
SELECT 'ingredient_claims', COUNT(*)::bigint FROM ingredient_claims
UNION ALL
SELECT 'product_ingredients', COUNT(*)::bigint FROM product_ingredients
ORDER BY table_name;

-- E. 보충 시드(005) 핵심 slug 존재 확인
SELECT slug
FROM ingredients
WHERE slug IN ('red-ginseng','msm','garcinia','collagen','creatine')
ORDER BY slug;

-- F. 추가 시드(008) 시그니처 점검
-- Expectation: 6 slugs and 35 products should exist after 008.
SELECT
  COUNT(*) FILTER (WHERE slug IN ('red-ginseng','collagen','creatine','garcinia','msm','zeaxanthin')) AS slug_hits,
  COUNT(*) AS total_ingredients
FROM ingredients;

SELECT
  COUNT(*) FILTER (
    WHERE product_name IN (
      '정관장 홍삼정 에브리타임',
      '뉴트리코어 MSM 플러스',
      'Doctor''s Best Magnesium Glycinate 400mg',
      'NOW Vitamin D3 5000 IU'
    )
  ) AS signature_product_hits,
  COUNT(*) AS total_products
FROM products;
```

판단 가이드:
- `E` 결과가 5개면 `005` 핵심 시드 반영 가능성이 높습니다.
- `F.slug_hits = 6`이고 `F.signature_product_hits = 4`이면 `008` 핵심 시그니처 반영 가능성이 높습니다.
- 최종 확정은 실제 카운트(`total_products`, `product_ingredients`)를 환경별 베이스라인과 비교해 판별하세요.

## 5) 운영 리스크 / 개선 제안

- 현재 구조는 실행 이력 테이블이 없어 "어느 환경에 어디까지 반영됐는지"를 자동 추적하기 어렵습니다.
- 권장:
  1. `supabase migration` 또는 drizzle migration 기반으로 버전드 마이그레이션 전환
  2. 배포 파이프라인에서 마이그레이션 적용 + 검증 쿼리 자동 실행
  3. 시드 데이터는 초기 시드/증분 시드를 분리하고 idempotent 정책 명문화
