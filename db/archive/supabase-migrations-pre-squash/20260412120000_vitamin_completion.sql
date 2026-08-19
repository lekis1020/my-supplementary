-- ============================================================================
-- 029_vitamin_completion.sql
-- 비타민 카테고리 데이터 완성 마이그레이션
--
-- 우선순위 1: 누락된 필수 비타민 5종 추가 (B1, B2, B3, B5, K)
-- 우선순위 2: 비타민 D 한국 식약처 기준(2020 DRI)으로 RDA/UL 수정
-- 우선순위 3: 비타민 E 한국 UL 병기, B6 신경계/호모시스테인 클레임 보강
--
-- 사전 조건: 003_seed_data.sql, 005_seed_supplementary.sql 적용 완료
-- ============================================================================

-- ============================================================================
-- SECTION 1 — 신규 Claims (필수 비타민을 위한 기능성 코드)
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('NERVOUS_SYSTEM',     '정상적인 신경계 기능에 도움',   'Nervous System Function',  'cognitive',      'approved_kr', '신경계의 정상 기능에 필요'),
('HOMOCYSTEINE',       '호모시스테인 대사에 도움',      'Homocysteine Metabolism',  'cardiovascular', 'approved_kr', '호모시스테인의 정상적인 대사에 필요'),
('BLOOD_COAGULATION',  '정상적인 혈액 응고에 도움',     'Blood Coagulation',        'blood',          'approved_kr', '정상적인 혈액 응고에 필요'),
('MUCOUS_MEMBRANE',    '점막 건강 유지에 도움',         'Mucous Membrane Health',   'skin_hair',      'approved_kr', '점막을 정상으로 유지하는 데 필요'),
('PSYCHOLOGICAL',      '정상적인 정신 기능 유지에 도움', 'Psychological Function',   'cognitive',      'approved_kr', '정상적인 정신 기능 유지에 필요')
ON CONFLICT (claim_code) DO UPDATE SET
  claim_name_ko = EXCLUDED.claim_name_ko,
  description   = EXCLUDED.description;

-- ============================================================================
-- SECTION 2 — 신규 비타민 원료 5종 (B1, B2, B3, B5, K)
-- ============================================================================

-- 2-A. 기존 slug=NULL 행(KR 정부 임포트 유래) slug 부여 및 메타데이터 보강
UPDATE ingredients SET
  slug='vitamin-b1',
  canonical_name_en=COALESCE(canonical_name_en,'Vitamin B1'),
  display_name=COALESCE(display_name,'비타민 B1'),
  scientific_name=COALESCE(scientific_name,'Thiamine'),
  description=COALESCE(description,'탄수화물 대사와 신경계 기능에 필수적인 수용성 비타민. 결핍 시 각기병(beriberi), 베르니케 뇌병증.'),
  origin_type=COALESCE(origin_type,'synthetic'),
  form_description=COALESCE(form_description,'티아민 질산염, 티아민 염산염, 벤포티아민'),
  ingredient_type='vitamin', is_active=true, is_published=true
WHERE canonical_name_ko='비타민 B1' AND (slug IS NULL OR slug='vitamin-b1');

UPDATE ingredients SET
  slug='vitamin-b2',
  canonical_name_en=COALESCE(canonical_name_en,'Vitamin B2'),
  display_name=COALESCE(display_name,'비타민 B2'),
  scientific_name=COALESCE(scientific_name,'Riboflavin'),
  description=COALESCE(description,'에너지 대사와 점막·피부 건강에 관여하는 수용성 비타민. FAD/FMN의 전구체로 세포 호흡에 필수.'),
  origin_type=COALESCE(origin_type,'synthetic'),
  form_description=COALESCE(form_description,'리보플라빈, 리보플라빈 5-인산(R5P)'),
  ingredient_type='vitamin', is_active=true, is_published=true
WHERE canonical_name_ko='비타민 B2' AND (slug IS NULL OR slug='vitamin-b2');

UPDATE ingredients SET
  slug='vitamin-b6',
  canonical_name_en=COALESCE(canonical_name_en,'Vitamin B6'),
  display_name=COALESCE(display_name,'비타민 B6'),
  scientific_name=COALESCE(scientific_name,'Pyridoxine'),
  description=COALESCE(description,'단백질·아미노산 대사, 신경전달물질 합성, 호모시스테인 대사에 필요한 수용성 비타민.'),
  origin_type=COALESCE(origin_type,'synthetic'),
  form_description=COALESCE(form_description,'피리독신염산염, 피리독살-5-인산(P-5-P)'),
  ingredient_type='vitamin', is_active=true, is_published=true
WHERE canonical_name_ko='비타민 B6' AND (slug IS NULL OR slug='vitamin-b6');

UPDATE ingredients SET
  slug='vitamin-k',
  canonical_name_en=COALESCE(canonical_name_en,'Vitamin K'),
  display_name=COALESCE(display_name,'비타민 K'),
  scientific_name=COALESCE(scientific_name,'Phylloquinone / Menaquinone'),
  description=COALESCE(description,'혈액 응고 인자(II, VII, IX, X) 감마-카르복실화 및 뼈 기질 단백질 오스테오칼신 활성화에 필요한 지용성 비타민.'),
  origin_type=COALESCE(origin_type,'natural'),
  form_description=COALESCE(form_description,'K1 필로퀴논(녹황색 채소), K2 메나퀴논 MK-4 / MK-7(발효식품·낫토)'),
  standardization_info=COALESCE(standardization_info,'K1 vs K2 (MK-4 단기, MK-7 반감기 長)'),
  ingredient_type='vitamin', is_active=true, is_published=true
WHERE canonical_name_ko='비타민 K' AND (slug IS NULL OR slug='vitamin-k');

-- 2-B. biotin 카테고리 수정 (ingredient_type='other' → 'vitamin')
UPDATE ingredients SET ingredient_type='vitamin' WHERE slug='biotin' AND ingredient_type<>'vitamin';

-- 2-C. DB에 없는 B3, B5만 신규 추가
INSERT INTO ingredients
  (canonical_name_ko, canonical_name_en, display_name, scientific_name, slug, ingredient_type,
   description, origin_type, form_description, standardization_info, is_active, is_published)
VALUES
('비타민 B1',  'Vitamin B1',  '비타민 B1',  'Thiamine',            'vitamin-b1',  'vitamin',
 '탄수화물 대사와 신경계 기능에 필수적인 수용성 비타민. 결핍 시 각기병(beriberi), 베르니케 뇌병증.',
 'synthetic', '티아민 질산염, 티아민 염산염, 벤포티아민', NULL, true, true),

('비타민 B2',  'Vitamin B2',  '비타민 B2',  'Riboflavin',          'vitamin-b2',  'vitamin',
 '에너지 대사와 점막·피부 건강에 관여하는 수용성 비타민. FAD/FMN의 전구체로 세포 호흡에 필수.',
 'synthetic', '리보플라빈, 리보플라빈 5-인산(R5P)', NULL, true, true),

('비타민 B3',  'Vitamin B3',  '비타민 B3',  'Niacin',              'vitamin-b3',  'vitamin',
 '에너지 대사와 DNA 복구에 관여하는 수용성 비타민. 니코틴산(niacin)과 니코틴아미드(niacinamide) 두 형태. 고용량 니코틴산은 혈중 지질 조절에 사용.',
 'synthetic', '니코틴산(나이아신), 니코틴아미드(나이아신아미드), 이노시톨 헥사니코티네이트', '1mg NE = 60mg 트립토판에서 내인성 합성', true, true),

('비타민 B5',  'Vitamin B5',  '비타민 B5',  'Pantothenic acid',    'vitamin-b5',  'vitamin',
 'CoA(조효소 A) 전구체로 지방·탄수화물·단백질 대사 전반에 관여하는 수용성 비타민. 널리 분포하여 결핍 드묾.',
 'synthetic', '판토텐산 칼슘, 덱스판테놀(프로비타민)', NULL, true, true),

('비타민 K',   'Vitamin K',   '비타민 K',   'Phylloquinone / Menaquinone', 'vitamin-k', 'vitamin',
 '혈액 응고 인자(II, VII, IX, X) 감마-카르복실화 및 뼈 기질 단백질 오스테오칼신 활성화에 필요한 지용성 비타민.',
 'natural',   'K1 필로퀴논(녹황색 채소), K2 메나퀴논 MK-4 / MK-7(발효식품·낫토)', 'K1 vs K2 (MK-4 단기, MK-7 반감기 長)', true, true)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 3 — 동의어 (ingredient_synonyms)
-- ============================================================================

INSERT INTO ingredient_synonyms (ingredient_id, synonym, language_code, synonym_type, is_preferred) VALUES
-- 비타민 B1 ─ Thiamine
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), '티아민',              'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), '비타민B1',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), '비타민 비1',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'Thiamine',            'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'Thiamin',             'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'Thiamine HCl',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'Thiamine Mononitrate','en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'Benfotiamine',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), 'B1',                  'en', 'abbreviation', false),

-- 비타민 B2 ─ Riboflavin
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), '리보플라빈',          'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), '비타민B2',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), '비타민 비2',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), 'Riboflavin',          'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), 'Riboflavin-5-Phosphate','en','scientific',  false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), 'R5P',                 'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), 'B2',                  'en', 'abbreviation', false),

-- 비타민 B3 ─ Niacin
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '나이아신',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '니아신',              'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '니코틴산',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '니코틴아미드',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '나이아신아미드',      'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '비타민B3',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'Niacin',              'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'Niacinamide',         'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'Nicotinic Acid',      'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'Nicotinamide',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'NE',                  'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), 'B3',                  'en', 'abbreviation', false),

-- 비타민 B5 ─ Pantothenic acid
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), '판토텐산',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), '판토텐산칼슘',        'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), '덱스판테놀',          'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), '비타민B5',            'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), 'Pantothenic Acid',    'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), 'Calcium Pantothenate','en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), 'Dexpanthenol',        'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), 'Panthenol',           'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), 'B5',                  'en', 'abbreviation', false),

-- 비타민 K
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '비타민K',             'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '비타민 케이',         'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '필로퀴논',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '메나퀴논',            'ko', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '비타민 K1',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '비타민 K2',           'ko', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Vitamin K1',          'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Vitamin K2',          'en', 'common',       false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Phylloquinone',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Phytonadione',        'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Menaquinone',         'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Menaquinone-4',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Menaquinone-7',       'en', 'scientific',   false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'MK-4',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'MK-7',                'en', 'abbreviation', false),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), 'Vit K',               'en', 'abbreviation', false)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 4 — 원료-기능성 연결 (ingredient_claims)
--   - 한국 식약처 건강기능식품 공전(2024) 고시형 원료 기준 기능성 문구
-- ============================================================================

INSERT INTO ingredient_claims
  (ingredient_id, claim_id, evidence_grade, evidence_summary,
   is_regulator_approved, approval_country_code, allowed_expression)
VALUES
-- 비타민 B1 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b1'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'A', '탄수화물 대사 보조효소(TPP)로서 ATP 생성에 필수', true, 'KR',
 '탄수화물과 에너지 대사에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'),
 (SELECT id FROM claims WHERE claim_code='NERVOUS_SYSTEM'),
 'A', '신경전달 및 말초 신경 기능 유지에 필수',         true, 'KR',
 '신경계의 정상 기능에 필요'),

-- 비타민 B2 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b2'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'A', 'FAD/FMN 보조인자로 세포 호흡 및 에너지 생성 필수', true, 'KR',
 '체내 에너지 생성에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'),
 (SELECT id FROM claims WHERE claim_code='MUCOUS_MEMBRANE'),
 'A', '점막 세포 재생 및 각막·구강 점막 유지',              true, 'KR',
 '점막을 정상으로 유지하는 데 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'),
 (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),
 'B', 'GSH reductase 보조인자로 산화 스트레스 완충',         true, 'KR',
 '유해산소로부터 세포를 보호하는데 필요'),

-- 비타민 B3 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b3'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'A', 'NAD/NADP 전구체로 세포 에너지 대사 및 DNA 복구 필수', true, 'KR',
 '체내 에너지 생성에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'),
 (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
 'B', '니코틴아미드의 피부장벽·광노화 방어 임상 연구',         true, 'KR',
 '피부 건강에 도움을 줄 수 있음'),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'),
 (SELECT id FROM claims WHERE claim_code='BLOOD_LIPID'),
 'B', '고용량 니코틴산의 혈중 지질(LDL↓, HDL↑) 조절 메타분석', false, NULL, NULL),

-- 비타민 B5 ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b5'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'A', 'CoA 전구체로 지방·탄수화물·단백질 대사에 필수',          true, 'KR',
 '지방, 탄수화물, 단백질 대사와 에너지 생성에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b5'),
 (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
 'C', '덱스판테놀의 피부 재생·보습 임상 연구',                   false, NULL, NULL),

-- 비타민 K ──────────────────────────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-k'),
 (SELECT id FROM claims WHERE claim_code='BLOOD_COAGULATION'),
 'A', '응고인자 II/VII/IX/X 감마-카르복실화에 필수',              true, 'KR',
 '정상적인 혈액 응고에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-k'),
 (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),
 'B', '오스테오칼신 활성화로 골밀도·골절 위험 메타분석',          true, 'KR',
 '뼈의 형성과 유지에 필요'),

-- 비타민 B6 보강 (우선순위 3) ──────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b6'),
 (SELECT id FROM claims WHERE claim_code='NERVOUS_SYSTEM'),
 'A', '신경전달물질(세로토닌, GABA 등) 합성 보조효소',          true, 'KR',
 '신경계의 정상 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'),
 (SELECT id FROM claims WHERE claim_code='HOMOCYSTEINE'),
 'A', '호모시스테인 → 시스타치오닌 전환(CBS) 보조효소',          true, 'KR',
 '호모시스테인의 정상적인 대사에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b6'),
 (SELECT id FROM claims WHERE claim_code='PSYCHOLOGICAL'),
 'B', 'PMS 증상·우울 지표 개선 소규모 임상',                      true, 'KR',
 '정상적인 정신 기능 유지에 필요'),

-- B12·엽산 호모시스테인 보강 ───────────────────────────────────────────
((SELECT id FROM ingredients WHERE slug='vitamin-b12'),
 (SELECT id FROM claims WHERE claim_code='HOMOCYSTEINE'),
 'A', '메티오닌 신타제 보조인자, 호모시스테인 재메틸화',          true, 'KR',
 '호모시스테인의 정상적인 대사에 필요'),
((SELECT id FROM ingredients WHERE slug='vitamin-b12'),
 (SELECT id FROM claims WHERE claim_code='NERVOUS_SYSTEM'),
 'A', '미엘린 합성에 필수, 결핍 시 아급성 연합 척수변성',         true, 'KR',
 '신경계의 정상 기능에 필요'),
((SELECT id FROM ingredients WHERE slug='folate'),
 (SELECT id FROM claims WHERE claim_code='HOMOCYSTEINE'),
 'A', '5-MTHF가 B12와 함께 호모시스테인 재메틸화 주도',            true, 'KR',
 '호모시스테인의 정상적인 대사에 필요')

ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO UPDATE SET
  evidence_grade    = EXCLUDED.evidence_grade,
  evidence_summary  = EXCLUDED.evidence_summary,
  allowed_expression= EXCLUDED.allowed_expression,
  updated_at        = NOW();

-- ============================================================================
-- SECTION 5 — 안전성 (safety_items)
-- ============================================================================

INSERT INTO safety_items
  (ingredient_id, safety_type, title, description,
   severity_level, evidence_level, frequency_text, applies_to_population, management_advice)
VALUES
-- 비타민 B3 (니코틴산 홍조, 간독성)
((SELECT id FROM ingredients WHERE slug='vitamin-b3'),
 'adverse_effect', '니코틴산 홍조(flushing)',
 '니코틴산 고용량(≥30 mg) 복용 후 얼굴·목 화끈거림, 가려움. 니코틴아미드는 드묾.',
 'mild', 'rct', 'common', '성인',
 '식후 복용, 서방형 제형 선택, 아스피린 선투여 고려'),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'),
 'overdose', '니코틴산 간독성',
 '고용량(1~3 g/일) 장기 복용 시 간기능 이상, AST/ALT 상승, 드물게 황달.',
 'serious', 'observational', 'uncommon', '성인',
 '고지혈증 치료용 고용량은 의사 감독 하에 복용, LFT 정기 검사'),

-- 비타민 B5 (안전)
((SELECT id FROM ingredients WHERE slug='vitamin-b5'),
 'adverse_effect', '고용량 설사',
 '10 g/일 이상 초고용량에서 삼투성 설사 보고. 일반 보충량에서는 드묾.',
 'mild', 'case_report', 'rare', '성인',
 '일반 보충량(5~10 mg) 내에서 안전'),

-- 비타민 K (와파린 상호작용 — 중요)
((SELECT id FROM ingredients WHERE slug='vitamin-k'),
 'drug_interaction', '와파린(쿠마딘) 길항',
 '비타민 K는 와파린의 항응고 효과를 감소시킴. 고용량·급격한 섭취 변화 시 INR 불안정.',
 'critical', 'guideline', 'common', '와파린 복용자',
 '와파린 복용자는 비타민 K 보충·섭취량을 일정하게 유지, 시작·중단 전 주치의 상담 필수'),
((SELECT id FROM ingredients WHERE slug='vitamin-k'),
 'precaution', '신생아 출혈성 질환 예방',
 '신생아는 비타민 K 저장량이 낮아 출생 시 1회 근주가 표준. 경구형은 용량 주의.',
 'moderate', 'guideline', 'common', '신생아',
 '표준 근주 프로토콜 준수'),

-- 비타민 B1 / B2 (일반적으로 안전, 경고 최소)
((SELECT id FROM ingredients WHERE slug='vitamin-b2'),
 'lab_interference', '소변 황색 착색',
 '리보플라빈 대사물로 소변이 밝은 노란색-주황색으로 착색. 무해하나 소변 검사 시 간섭 가능.',
 'mild', 'label', 'common', '성인 일반',
 '정상 현상, 검사 전 고지')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 6 — 용량 가이드라인 (한국 식약처 2020 한국인 영양소 섭취기준 기준)
-- ============================================================================

INSERT INTO dosage_guidelines
  (ingredient_id, population_group, indication_context,
   dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes)
VALUES
-- 비타민 B1 (RDA 남 1.2 / 여 1.1 mg, UL 없음)
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), '성인 남성', '일반 건강',
  1.2, 100, 'mg', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 남성 권장섭취량 1.2 mg. UL 없음. 보충제 상업 용량 대개 1.5~100 mg'),
((SELECT id FROM ingredients WHERE slug='vitamin-b1'), '성인 여성', '일반 건강',
  1.1, 100, 'mg', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 여성 권장섭취량 1.1 mg. UL 없음'),

-- 비타민 B2 (RDA 남 1.5 / 여 1.2 mg, UL 없음)
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), '성인 남성', '일반 건강',
  1.5, 40, 'mg', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 남성 권장섭취량 1.5 mg. UL 없음'),
((SELECT id FROM ingredients WHERE slug='vitamin-b2'), '성인 여성', '일반 건강',
  1.2, 40, 'mg', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 여성 권장섭취량 1.2 mg'),

-- 비타민 B3 (RDA 남 16 / 여 14 mg NE, UL 35 mg 니코틴산 기준)
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '성인 남성', '일반 건강',
  16, 35, 'mg NE', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 남성 16 mg NE. UL 니코틴산 35 mg / 니코틴아미드 1000 mg'),
((SELECT id FROM ingredients WHERE slug='vitamin-b3'), '성인 여성', '일반 건강',
  14, 35, 'mg NE', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 여성 14 mg NE'),

-- 비타민 B5 (AI 5 mg, UL 없음)
((SELECT id FROM ingredients WHERE slug='vitamin-b5'), '성인', '일반 건강',
  5, 200, 'mg', '1일 1회', 'oral', 'AI',
  'KR 2020 DRI 충분섭취량 5 mg. UL 없음. 일반 보충 5~10 mg'),

-- 비타민 K (AI 남 75 / 여 65 mcg, UL 없음)
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '성인 남성', '일반 건강',
  75, 1000, 'mcg', '1일 1회', 'oral', 'AI',
  'KR 2020 DRI 충분섭취량 75 μg. UL 없음. MK-7 형태 골건강 보충은 45~180 μg 임상 사용'),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '성인 여성', '일반 건강',
  65, 1000, 'mcg', '1일 1회', 'oral', 'AI',
  'KR 2020 DRI 충분섭취량 65 μg'),
((SELECT id FROM ingredients WHERE slug='vitamin-k'), '와파린 복용자', '일정 섭취 유지',
  0, 120, 'mcg', '1일 1회', 'oral', 'label_dose',
  '일정 섭취량 유지가 핵심. 급격한 변화 금지, 주치의 상담 필수')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 7 — 우선순위 2: 비타민 D 한국 기준으로 재정렬 (2020 DRI)
--   기존: 성인 600~2000 IU, 65세+ 800~4000 IU  (이는 미국 IOM/Endocrine 기준)
--   한국 DRI: 성인 10 μg (=400 IU), 65세+ 15 μg (=600 IU), UL 100 μg (=4000 IU)
-- ============================================================================

UPDATE dosage_guidelines
SET
  dose_min  = 400,
  dose_max  = 4000,
  dose_unit = 'IU',
  notes     = 'KR 2020 DRI 권장섭취량 10 μg (=400 IU), 상한섭취량 UL 100 μg (=4,000 IU). 결핍 시 보충 의사 상담'
WHERE ingredient_id = (SELECT id FROM ingredients WHERE slug='vitamin-d')
  AND population_group = '성인 (19~64세)';

UPDATE dosage_guidelines
SET
  dose_min  = 600,
  dose_max  = 4000,
  dose_unit = 'IU',
  notes     = 'KR 2020 DRI 65세 이상 권장섭취량 15 μg (=600 IU), UL 4,000 IU. 일조량 부족 시 상향 고려'
WHERE ingredient_id = (SELECT id FROM ingredients WHERE slug='vitamin-d')
  AND population_group = '65세 이상';

-- ============================================================================
-- SECTION 8 — 우선순위 3: 비타민 E 한국 UL 추가, 비타민 A 용량 보완
--   한국 DRI 비타민 E: AI 12 mg α-TE, UL 540 mg α-TE (미국 UL 1,000 mg 대비 낮음)
--   한국 DRI 비타민 A: 남 RDA 800 / 여 650 μg RAE, UL 3,000 μg RAE
-- ============================================================================

INSERT INTO dosage_guidelines
  (ingredient_id, population_group, indication_context,
   dose_min, dose_max, dose_unit, frequency_text, route, recommendation_type, notes)
VALUES
((SELECT id FROM ingredients WHERE slug='vitamin-e'), '성인', '일반 건강',
  12, 540, 'mg α-TE', '1일 1회', 'oral', 'AI',
  'KR 2020 DRI 충분섭취량 12 mg α-TE. UL 540 mg α-TE (≈ 800 IU d-α-토코페롤). 미국 UL 1,000 mg보다 엄격'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '성인 남성', '일반 건강',
  800, 3000, 'mcg RAE', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 남성 RDA 800 μg RAE, UL 3,000 μg RAE (레티놀 기준)'),
((SELECT id FROM ingredients WHERE slug='vitamin-a'), '성인 여성', '일반 건강',
  650, 3000, 'mcg RAE', '1일 1회', 'oral', 'RDA',
  'KR 2020 DRI 여성 RDA 650 μg RAE')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 9 — 검증 쿼리 (실행 후 결과 확인용)
-- ============================================================================

-- 비타민 카테고리 원료 수
-- SELECT COUNT(*) AS vitamin_count FROM ingredients WHERE ingredient_type='vitamin' AND is_active=true;
-- 예상: 13 (기존 8 + 신규 5)

-- 각 비타민별 claims / safety / dosage 개수
-- SELECT i.slug, i.canonical_name_ko,
--        (SELECT COUNT(*) FROM ingredient_claims    WHERE ingredient_id=i.id) AS claims_n,
--        (SELECT COUNT(*) FROM safety_items         WHERE ingredient_id=i.id) AS safety_n,
--        (SELECT COUNT(*) FROM dosage_guidelines    WHERE ingredient_id=i.id) AS dosage_n
-- FROM ingredients i WHERE i.ingredient_type='vitamin' ORDER BY i.slug;
