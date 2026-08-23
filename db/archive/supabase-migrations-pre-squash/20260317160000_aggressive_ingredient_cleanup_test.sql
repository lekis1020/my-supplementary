-- ============================================================================
-- 018_aggressive_ingredient_cleanup_test.sql: 특정 제품(31526) 성분 중복 완전 제거 테스트
-- 목적: 제품 내 동일 원료(ID 기준)가 여러 번 노출되는 현상을 원천 삭제
-- 타겟: product_id = 31526
-- ============================================================================

BEGIN;

-- 1. 정규 매핑된 성분(ingredient_id 존재) 중복 제거
-- 동일 제품 내 동일 원료 ID가 있으면 무조건 하나만 남김
WITH duplicate_reg_ids AS (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY product_id, ingredient_id
                   ORDER BY updated_at DESC, LENGTH(raw_label_name) DESC, id DESC
               ) as rank_num
        FROM product_ingredients
        WHERE product_id = 31526
          AND ingredient_id IS NOT NULL
    ) t
    WHERE t.rank_num > 1
)
DELETE FROM product_ingredients
WHERE id IN (SELECT id FROM duplicate_reg_ids);


-- 2. 미매핑 성분(ingredient_id NULL) 중복 제거
-- 이름이 정규화했을 때 같으면 중복으로 간주
WITH duplicate_raw_names AS (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY product_id, LOWER(TRIM(REPLACE(raw_label_name, ' ', '')))
                   ORDER BY updated_at DESC, id DESC
               ) as rank_num
        FROM product_ingredients
        WHERE product_id = 31526
          AND ingredient_id IS NULL
    ) t
    WHERE t.rank_num > 1
)
DELETE FROM product_ingredients
WHERE id IN (SELECT id FROM duplicate_raw_names);

COMMIT;

-- 결과 확인용 쿼리 (남은 성분 수)
SELECT count(*) as remaining_count FROM product_ingredients WHERE product_id = 31526;
