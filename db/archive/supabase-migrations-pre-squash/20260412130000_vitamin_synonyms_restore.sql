-- ============================================================================
-- 030 / 20260412130000 — 기존 비타민 8종 동의어 복원 + 비타민 D 용량 검증
-- 대상: vitamin-a, c, d, e, b6, b12, folate, biotin
-- ============================================================================

-- ============================================================================
-- SECTION 1 — 동의어 복원 (ingredient_synonyms)
-- ============================================================================

INSERT INTO ingredient_synonyms (ingredient_id, synonym, language_code, synonym_type, is_preferred) VALUES
-- 비타민 D ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민D',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민디',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민 D3',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '비타민D3',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Vitamin D3',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Cholecalciferol',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Ergocalciferol',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'Vit D',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), 'D3',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '콜레칼시페롤',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-d'), '에르고칼시페롤',    'ko', 'scientific',   false),

-- 비타민 C ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '비타민C',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '비타민씨',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '아스코르브산',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '아스코르빈산',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'Ascorbic Acid',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'Vit C',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), 'L-Ascorbic Acid',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-c'), '칼슘아스코르베이트','ko', 'common',       false),

-- 비타민 B12 ───────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'B12',               'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '비타민B12',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '코발라민',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '시아노코발라민',    'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), '메틸코발라민',      'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Cyanocobalamin',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Methylcobalamin',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'Cobalamin',         'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'), 'MeCbl',             'en', 'abbreviation', false),

-- 비타민 B6 ────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), 'B6',                   'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), '비타민B6',             'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), '비타민 비6',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), '피리독신',             'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), '피리독신염산염',       'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), 'Pyridoxine',           'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), 'Pyridoxine HCl',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), 'Pyridoxal-5-Phosphate','en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'), 'P-5-P',                'en', 'abbreviation', false),

-- 엽산 (Folate / Vitamin B9) ───────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='folate'), '비타민B9',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), '비타민 B9',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Vitamin B9',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='folate'), 'B9',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Folate',            'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Folic Acid',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), '폴산',              'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), '폴리닌산',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), '5-MTHF',            'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='folate'), 'L-Methylfolate',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='folate'), 'Methylfolate',      'en', 'scientific',   false),

-- 비오틴 (Biotin / Vitamin B7 / H) ─────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민H',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민 H',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민B7',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), '비타민 B7',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'Vitamin B7',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'Vitamin H',         'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'B7',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='biotin'), 'D-Biotin',          'en', 'scientific',   false),

-- 비타민 A ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '비타민A',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Vit A',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '레티놀',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '베타카로틴',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '베타-카로틴',       'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '레티닐아세테이트',  'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '레티닐팔미테이트',  'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Retinol',           'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Beta-Carotene',     'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Retinyl Acetate',   'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'Retinyl Palmitate', 'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), 'RAE',               'en', 'abbreviation', false),

-- 비타민 E ─────────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '비타민E',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Vit E',             'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '토코페롤',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '알파토코페롤',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'd-알파토코페롤',    'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '혼합토코페롤',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '토코트리에놀',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Tocopherol',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Alpha-Tocopherol',  'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Mixed Tocopherols', 'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'Tocotrienol',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-e'), 'α-TE',              'en', 'abbreviation', false)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 2 — 비타민 D 한국 RDA 재확인 UPDATE (029에서 적용했으나 멱등성 확보)
--   KR 2020 DRI: 성인 400 IU / 65세+ 600 IU / UL 4,000 IU
-- ============================================================================

UPDATE dosage_guidelines
SET dose_min = 400, dose_max = 4000, dose_unit = 'IU',
    recommendation_type = 'RDA',
    notes = 'KR 2020 DRI 권장섭취량 10 μg (=400 IU), 상한섭취량 UL 100 μg (=4,000 IU). 결핍 시 보충 의사 상담'
WHERE ingredient_id = (SELECT id FROM ingredients WHERE slug='vitamin-d')
  AND population_group = '성인 (19~64세)';

UPDATE dosage_guidelines
SET dose_min = 600, dose_max = 4000, dose_unit = 'IU',
    recommendation_type = 'RDA',
    notes = 'KR 2020 DRI 65세 이상 권장섭취량 15 μg (=600 IU), UL 4,000 IU. 일조량 부족 시 상향 고려'
WHERE ingredient_id = (SELECT id FROM ingredients WHERE slug='vitamin-d')
  AND population_group = '65세 이상';

-- ============================================================================
-- SECTION 3 — 검증 쿼리 (주석 처리)
-- ============================================================================

-- 동의어 카운트 재확인
-- SELECT i.slug, i.canonical_name_ko,
--        (SELECT COUNT(*) FROM ingredient_synonyms WHERE ingredient_id=i.id) AS syn_n
-- FROM ingredients i
-- WHERE i.slug IN ('vitamin-a','vitamin-b1','vitamin-b2','vitamin-b3','vitamin-b5',
--                  'vitamin-b6','vitamin-b12','vitamin-c','vitamin-d','vitamin-e',
--                  'vitamin-k','folate','biotin')
-- ORDER BY i.slug;

-- 비타민 D dosage 확인
-- SELECT population_group, dose_min, dose_max, dose_unit, notes
-- FROM dosage_guidelines
-- WHERE ingredient_id=(SELECT id FROM ingredients WHERE slug='vitamin-d');
