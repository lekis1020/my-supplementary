-- ============================================================================
-- 026_backfill_probiotic_parent_mapping.sql
-- 목적:
--   프로바이오틱스 균주성 원료(자식)와 부모 원료(probiotics)의 계층 연결 보강
-- 배경:
--   일부 KR 수집 원료가 parent_ingredient_id 없이 개별 원료로 적재되어
--   균주 페이지에서 상위/연관 근거 병합이 누락되는 문제를 보완한다.
-- ============================================================================

BEGIN;

WITH probiotic_parent AS (
  SELECT id
  FROM ingredients
  WHERE slug = 'probiotics'
  LIMIT 1
)
UPDATE ingredients i
SET
  parent_ingredient_id = p.id,
  updated_at = NOW()
FROM probiotic_parent p
WHERE i.parent_ingredient_id IS NULL
  AND i.ingredient_type = 'probiotic'
  AND COALESCE(i.slug, '') <> 'probiotics'
  AND (
    i.canonical_name_ko ~* '(lactobacillus|lacticaseibacillus|lactiplantibacillus|limosilactobacillus|bifidobacterium|bacillus|saccharomyces|streptococcus|enterococcus)\s+[a-z][a-z-]+'
    OR i.canonical_name_ko ~* '\m[LBSE]\.\s*[a-z][a-z-]+'
    OR i.canonical_name_ko ~* '\m[A-Z]{1,6}[- ]?[0-9]{1,5}[A-Z0-9-]*\M'
    OR i.canonical_name_ko ~ '(플란타룸|람노서스|카제이|파라카세이|애시도필루스|가세리|로이테리|살리바리우스|헬베티쿠스|락티스|비피덤|브레베|롱검|인판티스|코아귤란스)'
    OR (
      (i.canonical_name_ko LIKE '%프로바이오틱스%' OR i.canonical_name_ko LIKE '%유산균%')
      AND i.canonical_name_ko ~ '[A-Za-z]'
    )
  );

COMMIT;

-- ============================================================================
-- 검증
-- ============================================================================

-- 1) 부모 연결된 프로바이오틱스 균주 수
SELECT
  COUNT(*)::int AS probiotic_children_with_parent
FROM ingredients
WHERE ingredient_type = 'probiotic'
  AND parent_ingredient_id = (SELECT id FROM ingredients WHERE slug = 'probiotics');

-- 2) 부모 미연결 프로바이오틱스 원료 (점검용)
SELECT
  id,
  canonical_name_ko,
  slug
FROM ingredients
WHERE ingredient_type = 'probiotic'
  AND COALESCE(slug, '') <> 'probiotics'
  AND parent_ingredient_id IS NULL
ORDER BY canonical_name_ko;
