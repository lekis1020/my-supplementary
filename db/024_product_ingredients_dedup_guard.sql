-- ============================================================================
-- 024_product_ingredients_dedup_guard.sql
-- 목적:
--   1) product_ingredients 내 (product_id, ingredient_id) 중복을 정리
--   2) 동일 중복이 재발하지 않도록 UNIQUE 인덱스를 추가
-- ============================================================================

BEGIN;

WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY product_id, ingredient_id
            ORDER BY
                CASE
                    WHEN ingredient_role = 'active' THEN 3
                    WHEN ingredient_role = 'supporting' THEN 2
                    WHEN ingredient_role = 'capsule' THEN 1
                    ELSE 0
                END DESC,
                CASE WHEN amount_per_serving IS NOT NULL THEN 1 ELSE 0 END DESC,
                CASE WHEN daily_amount IS NOT NULL THEN 1 ELSE 0 END DESC,
                LENGTH(COALESCE(raw_label_name, '')) DESC,
                updated_at DESC,
                id DESC
        ) AS rn
    FROM product_ingredients
)
DELETE FROM product_ingredients pi
USING ranked r
WHERE pi.id = r.id
  AND r.rn > 1;

COMMIT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_ingredients_product_ingredient_unique
    ON product_ingredients (product_id, ingredient_id);

-- 검증: 0이어야 정상
SELECT count(*)::int AS duplicate_groups
FROM (
    SELECT product_id, ingredient_id
    FROM product_ingredients
    GROUP BY product_id, ingredient_id
    HAVING count(*) > 1
) d;
