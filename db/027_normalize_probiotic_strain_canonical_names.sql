-- ============================================================================
-- 027_normalize_probiotic_strain_canonical_names.sql
-- 목적:
--   프로바이오틱스 균주형 원료의 canonical_name_ko에서
--   일반 카테고리 접미어(예: "... 프로바이오틱스", "... 유산균")를 제거해
--   검색/분류 오탐을 줄인다.
--
-- 원칙:
--   1) parent root(slug='probiotics')는 변경하지 않는다.
--   2) 균주 패턴이 확인되는 probiotic 원료만 대상으로 한다.
--   3) 기존 canonical_name_ko는 ingredient_synonyms에 보존한다.
--   4) 이름 충돌 가능성이 있는 항목은 자동 변경에서 제외한다.
-- ============================================================================

BEGIN;

WITH candidates AS (
  SELECT
    i.id,
    i.canonical_name_ko AS old_name,
    TRIM(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(i.canonical_name_ko, '\s*의\s*프로바이오틱스\s*복합물$', '', 'i'),
            '\s*프로바이오틱스\s*복합물$',
            '',
            'i'
          ),
          '\s*(프로바이오틱스|프로바이오틱|유산균)$',
          '',
          'i'
        ),
        '\s*probiotics?$',
        '',
        'i'
      )
    ) AS normalized_name
  FROM ingredients i
  WHERE i.ingredient_type = 'probiotic'
    AND COALESCE(i.slug, '') <> 'probiotics'
    AND i.canonical_name_ko ~* '(프로바이오틱스|프로바이오틱|유산균|probiotics?)'
    AND (
      i.canonical_name_ko ~* '(lactobacillus|lacticaseibacillus|lactiplantibacillus|limosilactobacillus|bifidobacterium|bacillus|saccharomyces|streptococcus|enterococcus)\s+[a-z][a-z-]+'
      OR i.canonical_name_ko ~* '\m[LBSE]\.\s*[a-z][a-z-]+'
      OR i.canonical_name_ko ~* '\m[A-Z]{1,6}[- ]?[0-9]{1,5}[A-Z0-9-]*\M'
      OR i.canonical_name_ko ~ '(플란타룸|플란타럼|람노서스|카제이|카세이|파라카세이|애시도필루스|가세리|로이테리|살리바리우스|헬베티쿠스|락티스|비피덤|브레베|롱검|인판티스|코아귤란스)'
    )
),
safe_targets AS (
  SELECT c.*
  FROM candidates c
  WHERE c.normalized_name IS NOT NULL
    AND c.normalized_name <> ''
    AND c.normalized_name <> c.old_name
    AND NOT EXISTS (
      SELECT 1
      FROM ingredients i2
      WHERE i2.id <> c.id
        AND i2.ingredient_type = 'probiotic'
        AND LOWER(TRIM(i2.canonical_name_ko)) = LOWER(TRIM(c.normalized_name))
    )
),
synonym_upsert AS (
  INSERT INTO ingredient_synonyms (
    ingredient_id,
    synonym,
    language_code,
    synonym_type,
    is_preferred
  )
  SELECT
    st.id,
    st.old_name,
    'ko',
    'common',
    false
  FROM safe_targets st
  WHERE NOT EXISTS (
    SELECT 1
    FROM ingredient_synonyms s
    WHERE s.ingredient_id = st.id
      AND s.synonym = st.old_name
  )
  RETURNING ingredient_id
)
UPDATE ingredients i
SET
  canonical_name_ko = st.normalized_name,
  updated_at = NOW()
FROM safe_targets st
WHERE i.id = st.id;

COMMIT;

-- ============================================================================
-- 검증 쿼리
-- ============================================================================

-- 1) 여전히 generic 접미어가 남아있는 균주형 프로바이오틱스
SELECT
  COUNT(*)::int AS remaining_probiotic_suffix_on_strain_names
FROM ingredients i
WHERE i.ingredient_type = 'probiotic'
  AND COALESCE(i.slug, '') <> 'probiotics'
  AND i.canonical_name_ko ~* '(프로바이오틱스|프로바이오틱|유산균|probiotics?)'
  AND (
    i.canonical_name_ko ~* '(lactobacillus|lacticaseibacillus|lactiplantibacillus|limosilactobacillus|bifidobacterium|bacillus|saccharomyces|streptococcus|enterococcus)\s+[a-z][a-z-]+'
    OR i.canonical_name_ko ~* '\m[LBSE]\.\s*[a-z][a-z-]+'
    OR i.canonical_name_ko ~* '\m[A-Z]{1,6}[- ]?[0-9]{1,5}[A-Z0-9-]*\M'
    OR i.canonical_name_ko ~ '(플란타룸|플란타럼|람노서스|카제이|카세이|파라카세이|애시도필루스|가세리|로이테리|살리바리우스|헬베티쿠스|락티스|비피덤|브레베|롱검|인판티스|코아귤란스)'
  );

-- 2) 점검용 샘플: suffix 포함 이름 30개
SELECT
  i.id,
  i.canonical_name_ko,
  i.slug,
  i.parent_ingredient_id
FROM ingredients i
WHERE i.ingredient_type = 'probiotic'
  AND COALESCE(i.slug, '') <> 'probiotics'
  AND i.canonical_name_ko ~* '(프로바이오틱스|프로바이오틱|유산균|probiotics?)'
ORDER BY i.canonical_name_ko
LIMIT 30;

