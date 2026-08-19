-- ============================================================================
-- 20260412140000 — 비타민 D 용량 가이드라인 KR 2020 DRI 정합 수정
-- 기존 KR 규제 임포트 행('일반 성인', regulatory_daily_intake, mg 단위)을 삭제하고
-- 표준 RDA/AI 4개 인구집단 행을 재삽입.
--
-- 주의: Supabase SQL Editor에서 BEGIN/COMMIT 블록이 의도대로 커밋되지 않는 경우가 있어
-- 개별 문장으로 작성한다.
-- ============================================================================

-- 기존 비타민 D dosage 행 전부 삭제
DELETE FROM dosage_guidelines
WHERE ingredient_id=(SELECT id FROM ingredients WHERE slug='vitamin-d');

-- KR 2020 DRI 기준 4개 인구집단 행 삽입
INSERT INTO dosage_guidelines
  (ingredient_id, population_group, indication_context,
   dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes)
VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '성인 (19~64세)', '일반 건강',
  400, 4000, 'IU', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 권장섭취량 10 μg (=400 IU), UL 100 μg (=4,000 IU)'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '65세 이상', '일반 건강',
  600, 4000, 'IU', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 65세 이상 권장섭취량 15 μg (=600 IU), UL 4,000 IU'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '임산부', '태아 뼈 건강',
  400, 4000, 'IU', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 임산부 권장섭취량 10 μg (=400 IU)'),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '영아 (0~12개월)', '구루병 예방',
  400, 1000, 'IU', '1일 1회', 'oral', 'AI',
  'KR 2020 DRI 영아 충분섭취량 200~400 IU, UL 1,000 IU');

-- 검증 쿼리
-- SELECT population_group, dose_min, dose_max, dose_unit, recommendation_type, notes
-- FROM dosage_guidelines
-- WHERE ingredient_id=(SELECT id FROM ingredients WHERE slug='vitamin-d')
-- ORDER BY population_group;
