-- ============================================================================
-- 20260412150000 — KR 식약처 임포트 텍스트 프리픽스 제거 + 용량 중복 정리
--
-- 1. safety_items.title / description 앞의 '(가)', '(나)' 등 공전 항목 번호 제거
-- 2. dosage_guidelines 중복 행 정리 (유니크 제약 부재로 중복 적재 가능)
-- ============================================================================

-- 1) safety_items 프리픽스 제거 (title)
UPDATE safety_items
SET title = regexp_replace(title, '^\(\s*[가-힣]\s*\)\s*', '')
WHERE title ~ '^\(\s*[가-힣]\s*\)';

-- 2) safety_items 프리픽스 제거 (description)
UPDATE safety_items
SET description = regexp_replace(description, '^\(\s*[가-힣]\s*\)\s*', '')
WHERE description ~ '^\(\s*[가-힣]\s*\)';

-- 3) dosage_guidelines 중복 제거: (ingredient_id, population_group) 당 최신 id 유지
DELETE FROM dosage_guidelines a
USING dosage_guidelines b
WHERE a.ingredient_id = b.ingredient_id
  AND a.population_group = b.population_group
  AND COALESCE(a.indication_context,'') = COALESCE(b.indication_context,'')
  AND a.id < b.id;

-- 검증
-- SELECT COUNT(*) FROM safety_items WHERE title ~ '^\(\s*[가-힣]\s*\)' OR description ~ '^\(\s*[가-힣]\s*\)';
