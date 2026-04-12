-- ============================================================================
-- 20260412160000 — '철'(id=510, slug=NULL) / '철분'(id=8, slug=iron) 중복 병합
--
-- KR 식약처 API 임포트로 slug=NULL인 '철' 원료가 별도 행으로 적재됨.
-- 표준 행 '철분'(slug=iron)으로 통합하고 원본 '철' 삭제.
--
-- 실행 순서 주의: Supabase SQL Editor에서 BEGIN/COMMIT이 단일 트랜잭션으로
-- 커밋되지 않는 경우가 있어 개별 문장으로 작성.
-- ============================================================================

-- 1) 철분(8)이 이미 연결된 product는 철(510) 매핑 삭제 (충돌 방지)
DELETE FROM product_ingredients
WHERE ingredient_id=510
  AND product_id IN (SELECT product_id FROM product_ingredients WHERE ingredient_id=8);

-- 2) 나머지 '철' 매핑을 '철분'으로 이전
UPDATE product_ingredients SET ingredient_id=8 WHERE ingredient_id=510;

-- 3) 동의어 '철' 추가
INSERT INTO ingredient_synonyms (ingredient_id, synonym, language_code, synonym_type, is_preferred)
VALUES (8, '철', 'ko', 'common', false)
ON CONFLICT DO NOTHING;

-- 4) 원본 삭제
DELETE FROM ingredients WHERE id=510 AND canonical_name_ko='철';

-- 검증
-- SELECT id, slug, canonical_name_ko,
--        (SELECT COUNT(*) FROM product_ingredients WHERE ingredient_id=i.id) AS usage
-- FROM ingredients i WHERE canonical_name_ko IN ('철','철분');
