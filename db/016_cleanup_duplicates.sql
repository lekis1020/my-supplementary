-- ============================================================================
-- 016_cleanup_duplicates.sql: 데이터베이스 중복 정화 및 무결성 강화
-- 1. 중복 원료(Ingredients) 통합
-- 2. 중복 제품(Products) 통합 및 관계 재설정
-- 3. 제품 내 중복 성분(Product Ingredients) 합산 및 정리
-- 4. 재발 방지를 위한 UNIQUE 제약 조건 추가
-- ============================================================================

BEGIN;

-- 1. 중복 원료(Ingredients) 통합
-- 이름이 같은 원료 중 가장 먼저 생성된 ID(MIN)를 유지하고 나머지를 통합합니다.
CREATE TEMP TABLE tmp_ingredient_mapping AS
SELECT 
    canonical_name_ko,
    MIN(id) as keep_id,
    ARRAY_AGG(id) as all_ids
FROM ingredients
GROUP BY canonical_name_ko
HAVING COUNT(*) > 1;

-- 중복된 원료를 참조하던 제품-원료 연결 데이터를 메인 ID로 업데이트
UPDATE product_ingredients pi
SET ingredient_id = m.keep_id
FROM tmp_ingredient_mapping m
WHERE pi.ingredient_id = ANY(m.all_ids)
  AND pi.ingredient_id != m.keep_id;

-- 중복된 원료 행 삭제
DELETE FROM ingredients
WHERE id IN (
    SELECT unnest(all_ids) FROM tmp_ingredient_mapping
)
AND id NOT IN (
    SELECT keep_id FROM tmp_ingredient_mapping
);

DROP TABLE tmp_ingredient_mapping;


-- 2. 중복 제품(Products) 통합
-- 이름, 브랜드, 품목제조번호가 같은 제품을 식별합니다.
CREATE TEMP TABLE tmp_product_mapping AS
SELECT 
    product_name,
    brand_name,
    approval_or_report_no,
    MIN(id) as keep_id,
    ARRAY_AGG(id) as all_ids
FROM products
GROUP BY product_name, brand_name, approval_or_report_no
HAVING COUNT(*) > 1;

-- 중복 제품에 연결된 성분 정보를 메인 제품 ID로 이동
UPDATE product_ingredients pi
SET product_id = m.keep_id
FROM tmp_product_mapping m
WHERE pi.product_id = ANY(m.all_ids)
  AND pi.product_id != m.keep_id;

-- 중복 제품에 연결된 라벨 스냅샷 정보를 메인 제품 ID로 이동
UPDATE label_snapshots ls
SET product_id = m.keep_id
FROM tmp_product_mapping m
WHERE ls.product_id = ANY(m.all_ids)
  AND ls.product_id != m.keep_id;

-- 중복 제품 행 삭제
DELETE FROM products
WHERE id IN (
    SELECT unnest(all_ids) FROM tmp_product_mapping
)
AND id NOT IN (
    SELECT keep_id FROM tmp_product_mapping
);

DROP TABLE tmp_product_mapping;


-- 3. 제품 내 중복 성분(Product Ingredients) 정리
-- 동일 제품 안에 동일 성분 ID가 중복된 경우, 가장 최근 업데이트된 하나만 남깁니다.
-- (참고: 함량 합산이 필요할 경우 SUM 로직으로 변경 가능)
DELETE FROM product_ingredients pi
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY product_id, ingredient_id, raw_label_name 
                   ORDER BY updated_at DESC, id DESC
               ) as row_num
        FROM product_ingredients
    ) t
    WHERE t.row_num > 1
);


-- 4. 재발 방지를 위한 UNIQUE 제약 조건 추가
-- 데이터가 깨끗해진 상태에서 인덱스를 생성하여 앞으로의 중복을 원천 차단합니다.

-- 원료 이름 중복 방지
CREATE UNIQUE INDEX IF NOT EXISTS idx_ingredients_name_unique ON ingredients (canonical_name_ko);

-- 제품 중복 방지 (이름 + 브랜드 + 품목제조번호 조합)
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_unique_identity 
ON products (product_name, brand_name, COALESCE(approval_or_report_no, 'N/A'));

-- 제품 내 성분 중복 방지 (제품 ID + 원료 ID + 라벨 표기명 조합)
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_ingredients_unique 
ON product_ingredients (product_id, ingredient_id, COALESCE(raw_label_name, 'N/A'));

COMMIT;

-- 결과 확인
SELECT 'Cleanup Complete' as status;
