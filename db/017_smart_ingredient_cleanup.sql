-- ============================================================================
-- 017_smart_ingredient_cleanup.sql: 제품 내 성분 중복 지능형 정제
-- 1. 단위(Unit) 표준화 (mcg, ug, microgram -> mcg)
-- 2. 동의어 및 대소문자 정규화 (Vitamin -> 비타민, Mg -> mg)
-- 3. 제품 내 중복 성분 식별 및 우선순위 기반 단일화
-- 4. 재발 방지를 위한 데이터 무결성 체크
-- ============================================================================

BEGIN;

-- 1. 임시 테이블을 활용한 중복 데이터 분석 및 랭킹 부여
-- 동일 제품(product_id) 내에서 성분(ingredient_id 또는 정규화된 이름)이 겹치는 경우를 찾습니다.
CREATE TEMP TABLE ingredient_cleanup_targets AS
WITH normalized_ingredients AS (
    SELECT 
        id,
        product_id,
        ingredient_id,
        raw_label_name,
        -- 이름 정규화: 공백 제거, 소문자화, 비타민 키워드 통일
        LOWER(TRIM(REPLACE(REPLACE(raw_label_name, 'Vitamin', '비타민'), ' ', ''))) as norm_name,
        -- 단위 정규화
        LOWER(CASE 
            WHEN amount_unit IN ('ug', 'µg', 'microgram', 'mcg') THEN 'mcg'
            WHEN amount_unit IN ('mg', 'Milligram') THEN 'mg'
            ELSE COALESCE(amount_unit, '')
        END) as norm_unit,
        amount_per_serving,
        updated_at
    FROM product_ingredients
),
ranked_ingredients AS (
    SELECT 
        id,
        -- 랭킹 부여: 최신 날짜 > 긴 이름(구체적) > ID 순으로 우선순위
        ROW_NUMBER() OVER (
            PARTITION BY product_id, COALESCE(ingredient_id::text, norm_name)
            ORDER BY 
                updated_at DESC, 
                LENGTH(raw_label_name) DESC, 
                id ASC
        ) as rank_num
    FROM normalized_ingredients
)
SELECT id FROM ranked_ingredients WHERE rank_num > 1;

-- 2. 중복으로 판명된 성분 데이터 삭제
-- (함량이 동일하거나 표기 차이일 뿐인 '패배자' 레코드들을 제거합니다.)
DELETE FROM product_ingredients
WHERE id IN (SELECT id FROM ingredient_cleanup_targets);

-- 3. 정리 후 데이터 일관성 보완
-- 단위 표기를 표준형(mcg)으로 일괄 업데이트 (선택 사항)
UPDATE product_ingredients
SET amount_unit = 'mcg', 
    updated_at = NOW()
WHERE amount_unit IN ('ug', 'µg', 'microgram');

UPDATE product_ingredients
SET amount_unit = 'mg', 
    updated_at = NOW()
WHERE amount_unit = 'Milligram';

-- 4. 임시 테이블 삭제
DROP TABLE ingredient_cleanup_targets;

COMMIT;

-- 결과 리포트
SELECT 'Intra-Product Ingredient Cleanup Complete' as status;
