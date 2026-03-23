-- ============================================================================
-- 025_product_ingredients_duplicate_report.sql
-- 목적:
--   product_ingredients 중복 현황을 운영 점검용으로 빠르게 확인
-- 기준:
--   동일 product_id + ingredient_id 조합이 2건 이상이면 중복으로 판단
-- ============================================================================

-- 1) 전체 요약: 중복 그룹 수 + 중복으로 초과된 행 수
WITH grouped AS (
    SELECT
        product_id,
        ingredient_id,
        COUNT(*) AS row_count
    FROM product_ingredients
    GROUP BY product_id, ingredient_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*)::int AS duplicate_groups,
    COALESCE(SUM(row_count - 1), 0)::int AS duplicate_rows_excess
FROM grouped;


-- 2) 제품별 Top N (중복 그룹이 많은 제품)
WITH grouped AS (
    SELECT
        product_id,
        ingredient_id,
        COUNT(*) AS row_count
    FROM product_ingredients
    GROUP BY product_id, ingredient_id
    HAVING COUNT(*) > 1
),
per_product AS (
    SELECT
        product_id,
        COUNT(*) AS duplicate_groups,
        SUM(row_count - 1) AS duplicate_rows_excess
    FROM grouped
    GROUP BY product_id
)
SELECT
    pp.product_id,
    p.approval_or_report_no,
    p.product_name,
    p.manufacturer_name,
    pp.duplicate_groups::int,
    pp.duplicate_rows_excess::int
FROM per_product pp
LEFT JOIN products p ON p.id = pp.product_id
ORDER BY pp.duplicate_groups DESC, pp.duplicate_rows_excess DESC, pp.product_id
LIMIT 50;


-- 3) 상세 점검: 중복 쌍별 실제 레코드 확인
-- 필요 시 아래 WHERE 절의 p.approval_or_report_no 값을 특정 제품 번호로 바꿔 사용
SELECT
    p.approval_or_report_no,
    p.product_name,
    pi.product_id,
    pi.ingredient_id,
    i.canonical_name_ko AS ingredient_name_ko,
    pi.id AS product_ingredient_id,
    pi.ingredient_role,
    pi.amount_per_serving,
    pi.amount_unit,
    pi.daily_amount,
    pi.daily_amount_unit,
    pi.raw_label_name,
    pi.updated_at
FROM product_ingredients pi
JOIN products p ON p.id = pi.product_id
JOIN ingredients i ON i.id = pi.ingredient_id
JOIN (
    SELECT product_id, ingredient_id
    FROM product_ingredients
    GROUP BY product_id, ingredient_id
    HAVING COUNT(*) > 1
) d
    ON d.product_id = pi.product_id
   AND d.ingredient_id = pi.ingredient_id
-- WHERE p.approval_or_report_no = '원하는-신고번호'
ORDER BY
    p.approval_or_report_no NULLS LAST,
    pi.product_id,
    pi.ingredient_id,
    pi.updated_at DESC,
    pi.id DESC;


-- 4) 안전 확인: 정리/가드 적용 후 반드시 0이어야 정상
SELECT count(*)::int AS remaining_duplicate_groups
FROM (
    SELECT product_id, ingredient_id
    FROM product_ingredients
    GROUP BY product_id, ingredient_id
    HAVING COUNT(*) > 1
) d;
