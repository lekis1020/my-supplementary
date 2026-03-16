-- ============================================================================
-- 소스 보강 + 출처 연결 + 검색 인덱스 — 010_seed_sources_search.sql
-- Version: 1.0.0
-- 생성일: 2026-03-16
-- 대상: sources 3건 추가, source_links 전체 연결, ingredient_search_documents 생성
-- 실행 순서: 001 → 003 → 005 → 008 → 009 → 이 파일(010)
-- ============================================================================

-- ============================================================================
-- SECTION 1: 추가 소스 3건
-- ============================================================================

INSERT INTO sources (source_name, source_type, organization_name, source_url, country_code, trust_level, access_method, notes) VALUES
('MFDS 고시/가이드',             'regulator',      '식품의약품안전처',    'https://www.mfds.go.kr/',                          'KR', 'authoritative', 'hybrid',  '규제 고시, 인정 기준, 재평가 결과, 가이드라인 PDF. 구조화 데이터는 data.mfds.go.kr API, 상세/PDF는 브라우저 수집.'),
('USDA FoodData Central',        'government_db',  'USDA',               'https://fdc.nal.usda.gov/',                         'US', 'authoritative', 'api',     '영양성분 DB (비타민, 미네랄, 생리활성물질), 브랜드 제품, 서빙 사이즈. API Key 필요.'),
('공공데이터포털 기능성원료인정', 'government_db',  '식품의약품안전처',    'https://www.data.go.kr/data/15058359/openapi.do',   'KR', 'authoritative', 'api',     '건강기능식품 기능성 원료 인정 현황. 인정번호, 일일섭취량, 기능성 내용, 주의사항.')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 2: source_links — 엔티티-출처 연결
-- ============================================================================
-- entity_type: ingredient, claim, safety_item, product, label_snapshot,
--              evidence_study, dosage_guideline, ingredient_drug_interaction,
--              regulatory_status

-- ── 2-1. 원료 → 공공데이터포털 (KR 규제 데이터 출처) ────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
  'ingredient',
  i.id,
  'https://www.data.go.kr/data/15056760/openapi.do',
  '2026-03-12'::timestamp
FROM ingredients i
WHERE i.is_active = true;

-- ── 2-2. 원료 → 기능성원료인정 (KR 인정 현황) ──────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '공공데이터포털 기능성원료인정'),
  'ingredient',
  i.id,
  'https://www.data.go.kr/data/15058359/openapi.do',
  '2026-03-12'::timestamp
FROM ingredients i
WHERE i.is_active = true;

-- ── 2-3. 기능성(Claims) → 공공데이터포털 (인정 기능성) ──────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
  'claim',
  c.id,
  'https://www.data.go.kr/data/15056760/openapi.do',
  '2026-03-12'::timestamp
FROM claims c
WHERE c.claim_scope = 'approved_kr';

-- ── 2-4. 기능성(Claims: studied) → PubMed ──────────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = 'PubMed'),
  'claim',
  c.id,
  'https://pubmed.ncbi.nlm.nih.gov/',
  '2026-03-16'::timestamp
FROM claims c
WHERE c.claim_scope = 'studied';

-- ── 2-5. 논문(evidence_studies) → PubMed ────────────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, source_excerpt, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = 'PubMed'),
  'evidence_study',
  es.id,
  'https://pubmed.ncbi.nlm.nih.gov/' || es.pmid || '/',
  'PMID: ' || es.pmid || COALESCE(', DOI: ' || es.doi, ''),
  '2026-03-16'::timestamp
FROM evidence_studies es
WHERE es.source_type = 'pubmed'
  AND es.pmid IS NOT NULL;

-- ── 2-6. KR 제품 → 공공데이터포털 ──────────────────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
  'product',
  p.id,
  'https://www.data.go.kr/data/15056760/openapi.do',
  '2026-03-12'::timestamp
FROM products p
WHERE p.country_code = 'KR';

-- ── 2-7. KR 제품 → 식품안전나라 (보충 출처) ────────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '식품안전나라'),
  'product',
  p.id,
  'https://www.foodsafetykorea.go.kr/api/main.do',
  '2026-03-12'::timestamp
FROM products p
WHERE p.country_code = 'KR';

-- ── 2-8. US 제품 → NIH DSLD ────────────────────────────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = 'NIH DSLD'),
  'product',
  p.id,
  'https://dsld.od.nih.gov/',
  '2026-03-16'::timestamp
FROM products p
WHERE p.country_code = 'US';

-- ── 2-9. 안전성(safety_items) → PubMed (문헌 근거) ─────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = 'PubMed'),
  'safety_item',
  si.id,
  'https://pubmed.ncbi.nlm.nih.gov/',
  '2026-03-16'::timestamp
FROM safety_items si
WHERE si.evidence_level IN ('A', 'B', 'rct', 'observational');

-- ── 2-10. 안전성(safety_items: 가이드라인) → MFDS 고시/가이드 ──────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = 'MFDS 고시/가이드'),
  'safety_item',
  si.id,
  'https://www.mfds.go.kr/',
  '2026-03-16'::timestamp
FROM safety_items si
WHERE si.evidence_level = 'guideline';

-- ── 2-11. 용량 가이드라인 → 공공데이터포털 (KR RDA) ────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '공공데이터포털 건강기능식품'),
  'dosage_guideline',
  dg.id,
  'https://www.data.go.kr/data/15056760/openapi.do',
  '2026-03-12'::timestamp
FROM dosage_guidelines dg;

-- ── 2-12. 라벨 스냅샷 → 제품 라벨 (브라우저 수집) ──────────────────────────
INSERT INTO source_links (source_id, entity_type, entity_id, source_reference, retrieved_at)
SELECT
  (SELECT id FROM sources WHERE source_name = '제품 라벨 (브라우저 수집)'),
  'label_snapshot',
  ls.id,
  ls.source_name,
  '2026-03-12'::timestamp
FROM label_snapshots ls;


-- ============================================================================
-- SECTION 3: ingredient_search_documents — 전 원료 검색 인덱스
-- ============================================================================
-- search_text 구성: 원료명(KO/EN) + 학명 + 설명 + 전 동의어 + 연결된 기능성명
-- search_vector: to_tsvector('simple', search_text)  ← 다국어 혼합이므로 simple 사전 사용

INSERT INTO ingredient_search_documents (ingredient_id, search_text, search_vector, updated_at)
SELECT
  i.id,
  -- search_text 조합
  COALESCE(i.canonical_name_ko, '') || ' ' ||
  COALESCE(i.canonical_name_en, '') || ' ' ||
  COALESCE(i.display_name, '') || ' ' ||
  COALESCE(i.scientific_name, '') || ' ' ||
  COALESCE(i.description, '') || ' ' ||
  COALESCE(i.form_description, '') || ' ' ||
  -- 동의어 전체
  COALESCE(
    (SELECT string_agg(syn.synonym, ' ')
     FROM ingredient_synonyms syn
     WHERE syn.ingredient_id = i.id),
    ''
  ) || ' ' ||
  -- 연결된 기능성명
  COALESCE(
    (SELECT string_agg(c.claim_name_ko || ' ' || COALESCE(c.claim_name_en, ''), ' ')
     FROM ingredient_claims ic
     JOIN claims c ON c.id = ic.claim_id
     WHERE ic.ingredient_id = i.id),
    ''
  ) || ' ' ||
  -- 안전성 키워드
  COALESCE(
    (SELECT string_agg(si.title || ' ' || COALESCE(si.description, ''), ' ')
     FROM safety_items si
     WHERE si.ingredient_id = i.id),
    ''
  ) AS search_text,
  -- search_vector
  to_tsvector('simple',
    COALESCE(i.canonical_name_ko, '') || ' ' ||
    COALESCE(i.canonical_name_en, '') || ' ' ||
    COALESCE(i.display_name, '') || ' ' ||
    COALESCE(i.scientific_name, '') || ' ' ||
    COALESCE(i.description, '') || ' ' ||
    COALESCE(i.form_description, '') || ' ' ||
    COALESCE(
      (SELECT string_agg(syn.synonym, ' ')
       FROM ingredient_synonyms syn
       WHERE syn.ingredient_id = i.id),
      ''
    ) || ' ' ||
    COALESCE(
      (SELECT string_agg(c.claim_name_ko || ' ' || COALESCE(c.claim_name_en, ''), ' ')
       FROM ingredient_claims ic
       JOIN claims c ON c.id = ic.claim_id
       WHERE ic.ingredient_id = i.id),
      ''
    ) || ' ' ||
    COALESCE(
      (SELECT string_agg(si.title || ' ' || COALESCE(si.description, ''), ' ')
       FROM safety_items si
       WHERE si.ingredient_id = i.id),
      ''
    )
  ),
  NOW()
FROM ingredients i
WHERE i.is_active = true
ON CONFLICT (ingredient_id) DO UPDATE SET
  search_text   = EXCLUDED.search_text,
  search_vector = EXCLUDED.search_vector,
  updated_at    = NOW();


-- ============================================================================
-- 완료 확인 쿼리 (실행 후 확인용, 필요 시 주석 해제)
-- ============================================================================

-- SELECT 'sources' AS entity, COUNT(*) FROM sources
-- UNION ALL
-- SELECT 'source_links', COUNT(*) FROM source_links
-- UNION ALL
-- SELECT 'search_documents', COUNT(*) FROM ingredient_search_documents;
