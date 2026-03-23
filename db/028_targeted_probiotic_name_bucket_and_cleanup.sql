-- ============================================================================
-- 028_targeted_probiotic_name_bucket_and_cleanup.sql
-- 목적:
--   사용자 리포트로 확인된 '프로바이오틱스/유산균' 표기 이슈 ID를
--   버킷으로 분류하고, 고신뢰 케이스만 안전하게 canonical 정리한다.
--
-- 설계 원칙:
--   - 고신뢰(strain 확실)만 UPDATE
--   - 저신뢰(브랜드/복합물/발효물)는 분류만 하고 자동 변경하지 않음
--   - 변경 전 이름은 ingredient_synonyms에 보존
-- ============================================================================

BEGIN;

-- 0) 대상 ID 버킷 정의 (수동 리뷰 기반)
WITH target_rows AS (
  SELECT *
  FROM (
    VALUES
      (714, 'strain_complex',   NULL::text,                       false, NULL::text),
      (745, 'brand_like',       NULL::text,                       false, NULL::text),
      (746, 'strain_high',      'Weissella cibaria CMU',          true,  'probiotics'),
      (31,  'complex_formula',  NULL::text,                       false, NULL::text),
      (52,  'fermented_material', NULL::text,                     false, NULL::text),
      (57,  'fermented_material', NULL::text,                     false, NULL::text),
      (97,  'fermented_material', NULL::text,                     false, NULL::text),
      (116, 'fermented_material', NULL::text,                     false, NULL::text),
      (172, 'complex_formula',  NULL::text,                       false, NULL::text),
      (441, 'fermented_material', NULL::text,                     false, NULL::text),
      (442, 'fermented_material', NULL::text,                     false, NULL::text),
      (443, 'fermented_material', NULL::text,                     false, NULL::text),
      (444, 'fermented_material', NULL::text,                     false, NULL::text),
      (445, 'fermented_material', NULL::text,                     false, NULL::text),
      (446, 'generic_probiotic', NULL::text,                      false, NULL::text),
      (580, 'complex_formula',  NULL::text,                       false, NULL::text),
      (581, 'generic_probiotic', NULL::text,                      false, NULL::text),
      (582, 'brand_or_code',    NULL::text,                       false, NULL::text),
      (583, 'brand_or_code',    NULL::text,                       false, NULL::text)
  ) AS t(id, bucket, normalized_name, should_update_name, parent_slug)
),
high_confidence AS (
  SELECT
    i.id,
    i.canonical_name_ko AS old_name,
    tr.normalized_name,
    p.id AS parent_id
  FROM target_rows tr
  JOIN ingredients i ON i.id = tr.id
  LEFT JOIN ingredients p ON p.slug = tr.parent_slug
  WHERE tr.should_update_name = true
    AND tr.normalized_name IS NOT NULL
    AND tr.normalized_name <> ''
    AND tr.normalized_name <> i.canonical_name_ko
    AND NOT EXISTS (
      SELECT 1
      FROM ingredients i2
      WHERE i2.id <> i.id
        AND LOWER(TRIM(i2.canonical_name_ko)) = LOWER(TRIM(tr.normalized_name))
    )
),
upsert_synonym AS (
  INSERT INTO ingredient_synonyms (
    ingredient_id, synonym, language_code, synonym_type, is_preferred
  )
  SELECT
    hc.id, hc.old_name, 'ko', 'common', false
  FROM high_confidence hc
  WHERE NOT EXISTS (
    SELECT 1
    FROM ingredient_synonyms s
    WHERE s.ingredient_id = hc.id
      AND s.synonym = hc.old_name
  )
  RETURNING ingredient_id
)
UPDATE ingredients i
SET
  canonical_name_ko = hc.normalized_name,
  parent_ingredient_id = COALESCE(hc.parent_id, i.parent_ingredient_id),
  updated_at = NOW()
FROM high_confidence hc
WHERE i.id = hc.id;

COMMIT;

-- ============================================================================
-- 검증/리뷰 출력
-- ============================================================================

-- 1) 대상 ID 분류 결과
WITH target_rows AS (
  SELECT *
  FROM (
    VALUES
      (714, 'strain_complex'),
      (745, 'brand_like'),
      (746, 'strain_high'),
      (31,  'complex_formula'),
      (52,  'fermented_material'),
      (57,  'fermented_material'),
      (97,  'fermented_material'),
      (116, 'fermented_material'),
      (172, 'complex_formula'),
      (441, 'fermented_material'),
      (442, 'fermented_material'),
      (443, 'fermented_material'),
      (444, 'fermented_material'),
      (445, 'fermented_material'),
      (446, 'generic_probiotic'),
      (580, 'complex_formula'),
      (581, 'generic_probiotic'),
      (582, 'brand_or_code'),
      (583, 'brand_or_code')
  ) AS t(id, bucket)
)
SELECT
  tr.bucket,
  i.id,
  i.canonical_name_ko,
  i.slug,
  i.ingredient_type,
  i.parent_ingredient_id
FROM target_rows tr
JOIN ingredients i ON i.id = tr.id
ORDER BY tr.bucket, i.id;

-- 2) 자동 미정리(수동 리뷰 필요) 항목
WITH target_rows AS (
  SELECT *
  FROM (
    VALUES
      (714, 'strain_complex', false),
      (745, 'brand_like', false),
      (746, 'strain_high', true),
      (31,  'complex_formula', false),
      (52,  'fermented_material', false),
      (57,  'fermented_material', false),
      (97,  'fermented_material', false),
      (116, 'fermented_material', false),
      (172, 'complex_formula', false),
      (441, 'fermented_material', false),
      (442, 'fermented_material', false),
      (443, 'fermented_material', false),
      (444, 'fermented_material', false),
      (445, 'fermented_material', false),
      (446, 'generic_probiotic', false),
      (580, 'complex_formula', false),
      (581, 'generic_probiotic', false),
      (582, 'brand_or_code', false),
      (583, 'brand_or_code', false)
  ) AS t(id, bucket, auto_updated)
)
SELECT
  tr.bucket,
  i.id,
  i.canonical_name_ko,
  i.parent_ingredient_id
FROM target_rows tr
JOIN ingredients i ON i.id = tr.id
WHERE tr.auto_updated = false
ORDER BY tr.bucket, i.id;

