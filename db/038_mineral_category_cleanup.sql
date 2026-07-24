-- ============================================================================
-- 038: 미네랄 카테고리 정비
-- (1) slug + 영문명 추가 (구리, 망간, 몰리브덴, 요오드, 칼륨, 크롬)
-- (2) 신규 미네랄 추가 (인/phosphorus, 불소/fluoride)
-- (3) 게르마늄효모 비활성화 (제품매핑 0, 표준 미네랄 아님)
-- (4) 철분 동의어 중복 제거 (4건 → 1건)
-- ============================================================================

-- ── 1. slug + 영문명 추가 ─────────────────────────────────────────────────
UPDATE ingredients SET slug = 'copper',     canonical_name_en = 'Copper',     display_name = '구리'     WHERE id = 59;
UPDATE ingredients SET slug = 'manganese',  canonical_name_en = 'Manganese',  display_name = '망간'     WHERE id = 185;
UPDATE ingredients SET slug = 'molybdenum', canonical_name_en = 'Molybdenum', display_name = '몰리브덴'  WHERE id = 196;
UPDATE ingredients SET slug = 'iodine',     canonical_name_en = 'Iodine',     display_name = '요오드'   WHERE id = 433;
UPDATE ingredients SET slug = 'potassium',  canonical_name_en = 'Potassium',  display_name = '칼륨'     WHERE id = 520;
UPDATE ingredients SET slug = 'chromium',   canonical_name_en = 'Chromium',   display_name = '크롬'     WHERE id = 534;

-- ── 2. 신규 미네랄 ───────────────────────────────────────────────────────
INSERT INTO ingredients (canonical_name_ko, canonical_name_en, display_name, slug, ingredient_type, is_active, is_published)
VALUES
  ('인', 'Phosphorus', '인', 'phosphorus', 'mineral', TRUE, TRUE),
  ('불소', 'Fluoride', '불소', 'fluoride', 'mineral', TRUE, TRUE)
ON CONFLICT (slug) DO NOTHING;

-- ── 3. 게르마늄효모 비활성화 ──────────────────────────────────────────────
-- 제품매핑 0건, 표준 미네랄 보충제가 아닌 식약처 임포트 노이즈
UPDATE ingredients SET is_active = FALSE, is_published = FALSE WHERE id = 46;

-- ── 4. 철분 동의어 중복 제거 (id 210 유지, 211/212/346 삭제) ──────────────
DELETE FROM ingredient_synonyms WHERE id IN (211, 212, 346);
