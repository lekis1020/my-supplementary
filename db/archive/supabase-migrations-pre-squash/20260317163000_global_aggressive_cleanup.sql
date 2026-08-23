-- ============================================================================
-- 019_global_aggressive_cleanup.sql: 전역 제품 내 성분 중복 완전 제거
-- 목적: 모든 제품에 대해 동일 원료(ID 또는 정규화된 이름 기준) 중복 노출 현상 해결
-- ============================================================================

BEGIN;

-- 1. 정규 매핑된 성분(ingredient_id 존재) 전역 중복 제거
-- 동일 제품 내 동일 원료 ID가 있으면 무조건 하나만 남김 (최신성 및 상세 정보 우선)
WITH duplicate_reg_ids AS (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY product_id, ingredient_id
                   ORDER BY updated_at DESC, LENGTH(raw_label_name) DESC, id DESC
               ) as rank_num
        FROM product_ingredients
        WHERE ingredient_id IS NOT NULL
    ) t
    WHERE t.rank_num > 1
)
DELETE FROM product_ingredients
WHERE id IN (SELECT id FROM duplicate_reg_ids);


-- 2. 미매핑 성분(ingredient_id NULL) 전역 중복 제거
-- 이름이 공백 제거 및 소문자화 후 같으면 중복으로 간주
WITH duplicate_raw_names AS (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY product_id, LOWER(TRIM(REPLACE(raw_label_name, ' ', '')))
                   ORDER BY updated_at DESC, id DESC
               ) as rank_num
        FROM product_ingredients
        WHERE ingredient_id IS NULL
    ) t
    WHERE t.rank_num > 1
)
DELETE FROM product_ingredients
WHERE id IN (SELECT id FROM duplicate_raw_names);

COMMIT;

-- 결과 리포트
SELECT 'Global Intra-Product Ingredient Cleanup Complete' as status;
