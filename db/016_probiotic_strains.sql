-- ============================================================================
-- 프로바이오틱스 균주 세분화 — 016_probiotic_strains.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: 프로바이오틱스를 균주 단위로 세분화하여 제품별 균주 구성 비교 가능하게
-- 설계: parent_ingredient_id를 활용한 상위-하위 원료 계층 구조
-- 주의: 015_enrich_evidence_phase2.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: 프로바이오틱스 균주 하위 원료 등록 (14종)
-- ============================================================================
-- 기존 probiotics 원료를 부모로 두고, 균주별 하위 원료를 생성
-- scientific_name: 최신 분류학명, display_name: 소비자 친숙 표기

INSERT INTO ingredients (
  canonical_name_ko, canonical_name_en, display_name, scientific_name, slug,
  ingredient_type, parent_ingredient_id, description, origin_type,
  form_description, standardization_info, is_active, is_published
) VALUES

-- 1. LGG — 세계에서 가장 많이 연구된 단일 균주
('락토바실러스 람노서스 GG', 'Lactobacillus rhamnosus GG', 'L. rhamnosus GG (LGG)',
 'Lacticaseibacillus rhamnosus GG', 'lactobacillus-rhamnosus-gg',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '세계에서 가장 많이 연구된 프로바이오틱스 균주. 300+ 인체 RCT. 항생제 관련 설사(AAD) 예방에 ESPGHAN 권장.',
 'natural', 'LGG (ATCC 53103)', '1~100억 CFU/일', true, true),

-- 2. BB-12 — 세계 최다 문헌 비피도박테리움
('비피도박테리움 아니말리스 BB-12', 'Bifidobacterium animalis subsp. lactis BB-12', 'B. lactis BB-12',
 'Bifidobacterium animalis subsp. lactis BB-12', 'bifidobacterium-lactis-bb12',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '300+ 학술 논문. 장내 미생물 균형, 배변 빈도 개선, 면역 지원. Chr. Hansen 독점 균주.',
 'natural', 'BB-12 (DSM 15954)', '10~300억 CFU/일', true, true),

-- 3. L. acidophilus NCFM — 가장 널리 사용되는 애시도필루스 균주
('락토바실러스 애시도필루스 NCFM', 'Lactobacillus acidophilus NCFM', 'L. acidophilus NCFM',
 'Lactobacillus acidophilus NCFM', 'lactobacillus-acidophilus-ncfm',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '45+ 임상시험. IBS 팽만감 73% 개선. 급성 설사 기간 단축. DuPont/IFF Danisco 유래.',
 'natural', 'NCFM', '10~100억 CFU/일', true, true),

-- 4. B. longum BB536 — 영유아~성인 다목적
('비피도박테리움 롱검 BB536', 'Bifidobacterium longum BB536', 'B. longum BB536',
 'Bifidobacterium longum subsp. longum BB536', 'bifidobacterium-longum-bb536',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '280+ 연구. 장내 균형, 면역 조절, 알레르기 완화. 1969년 건강 영아에서 분리. Morinaga 독점. FOSHU 인정(1996), FDA GRAS(2009).',
 'natural', 'BB536', '10~100억 CFU/일', true, true),

-- 5. L. rhamnosus HN001 — 면역·질건강·정신건강
('락토바실러스 람노서스 HN001', 'Lactobacillus rhamnosus HN001', 'L. rhamnosus HN001',
 'Lacticaseibacillus rhamnosus HN001', 'lactobacillus-rhamnosus-hn001',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '면역 강화, 질 건강, 불안 감소, 유아 아토피 예방. Fonterra/IFF 유래.',
 'natural', 'HN001', '10~60억 CFU/일', true, true),

-- 6. B. animalis subsp. lactis HN019 — 면역·장 통과 시간
('비피도박테리움 아니말리스 HN019', 'Bifidobacterium animalis subsp. lactis HN019', 'B. lactis HN019',
 'Bifidobacterium animalis subsp. lactis HN019', 'bifidobacterium-lactis-hn019',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 'NK세포·IFN-α 활성화로 면역 강화. 장 통과 시간 개선, 변비 완화. Fonterra 유래.',
 'natural', 'HN019 (Howaru Bifido)', '10~90억 CFU/일', true, true),

-- 7. L. casei Shirota — 야쿠르트 균주 (1930년 발견)
('락토바실러스 카제이 시로타', 'Lactobacillus casei Shirota', 'L. casei Shirota',
 'Lacticaseibacillus paracasei Shirota', 'lactobacillus-casei-shirota',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '500+ 연구. 1930년 시로타 미노루 박사 발견. 장내 균총 개선, NK세포 활성, 스트레스 관련 장 건강. 40개국 이상 판매.',
 'natural', 'Shirota', '65~1000억 CFU/일', true, true),

-- 8. L. reuteri DSM 17938 — 영아 산통 전문
('락토바실러스 로이테리 DSM 17938', 'Lactobacillus reuteri DSM 17938', 'L. reuteri DSM 17938',
 'Limosilactobacillus reuteri DSM 17938', 'lactobacillus-reuteri-dsm17938',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '영아 산통 예방/치료, 급성 설사 단축, 위 운동성 개선. BioGaia 독점. 연구 균주 중 최저 유효 CFU.',
 'natural', 'DSM 17938 (ATCC 55730 유래)', '1~10억 CFU/일', true, true),

-- 9. L. plantarum 299v — IBS·C. difficile 전문
('락토플란티바실러스 플란타룸 299v', 'Lactiplantibacillus plantarum 299v', 'L. plantarum 299v',
 'Lactiplantibacillus plantarum 299v', 'lactobacillus-plantarum-299v',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 'IBS 복통에 EFSA Level 2 근거. C. difficile 설사 예방. FDA GRAS (Notice 685). Probi AB 독점.',
 'natural', '299v (DSM 9843)', '100~200억 CFU/일', true, true),

-- 10. L. helveticus R0052 — 장-뇌 축 사이코바이오틱스
('락토바실러스 헬베티쿠스 R0052', 'Lactobacillus helveticus R0052', 'L. helveticus R0052',
 'Lactobacillus helveticus R0052', 'lactobacillus-helveticus-r0052',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '불안·스트레스 완화, GABA 생성 촉진. B. longum R0175와 조합 시 우울증 보조 치료에 WFSBP/CANMAT 잠정 권장.',
 'natural', 'R0052 (Lallemand)', '30~60억 CFU/일 (R0175 병용)', true, true),

-- 11. B. longum R0175 — 사이코바이오틱스 파트너
('비피도박테리움 롱검 R0175', 'Bifidobacterium longum R0175', 'B. longum R0175',
 'Bifidobacterium longum R0175', 'bifidobacterium-longum-r0175',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '우울증 보조, 불안 완화, BDNF 혈중 농도 증가. L. helveticus R0052와 조합 전용. Lallemand 독점.',
 'natural', 'R0175 (Lallemand)', '30~60억 CFU/일 (R0052 병용)', true, true),

-- 12. L. gasseri BNR17 — 한국 개발 체지방 감소 균주
('락토바실러스 가세리 BNR17', 'Lactobacillus gasseri BNR17', 'L. gasseri BNR17',
 'Lactobacillus gasseri BNR17', 'lactobacillus-gasseri-bnr17',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '모유에서 분리된 한국 개발 균주. 식약처 최초 체지방 감소 인정 프로바이오틱스. 허리/엉덩이 둘레 감소 RCT 확인.',
 'natural', 'BNR17 (AceBiome)', '10~100억 CFU/일', true, true),

-- 13. S. thermophilus — 유당 분해·다균주 베이스
('스트렙토코커스 써모필루스', 'Streptococcus thermophilus', 'S. thermophilus',
 'Streptococcus thermophilus', 'streptococcus-thermophilus',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '유당 분해 지원(유당불내증 완화). 식약처 19종 포함. 한국 멀티균주 제품 대부분에 포함. EFSA 유당 소화 인정.',
 'natural', '다양한 균주', '10~100억 CFU/일', true, true),

-- 14. B. bifidum BGN4 — 한국 연구 IBS·아토피 균주
('비피도박테리움 비피덤 BGN4', 'Bifidobacterium bifidum BGN4', 'B. bifidum BGN4',
 'Bifidobacterium bifidum BGN4', 'bifidobacterium-bifidum-bgn4',
 'probiotic', (SELECT id FROM ingredients WHERE slug = 'probiotics'),
 '한국 연구 균주. IBS 증상 완화, 아토피 피부염 개선, 면역 균형. B. lactis AD011, L. acidophilus AD031과 조합 연구.',
 'natural', 'BGN4', '10~50억 CFU/일', true, true)

ON CONFLICT (slug) DO NOTHING;


-- ============================================================================
-- SECTION 2: 균주별 동의어 등록
-- ============================================================================

INSERT INTO ingredient_synonyms (ingredient_id, synonym, language_code, synonym_type, is_preferred) VALUES
-- LGG
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'), 'LGG', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'), 'Lacticaseibacillus rhamnosus GG', 'en', 'scientific', false),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'), 'ATCC 53103', 'en', 'scientific', false),

-- BB-12
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'), 'BB-12', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'), 'B. lactis BB-12', 'en', 'common', false),
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'), 'DSM 15954', 'en', 'scientific', false),

-- NCFM
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-acidophilus-ncfm'), 'NCFM', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-acidophilus-ncfm'), 'L. acidophilus NCFM', 'en', 'common', false),

-- BB536
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-bb536'), 'BB536', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-bb536'), 'B. longum BB536', 'en', 'common', false),

-- HN001
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-hn001'), 'HN001', 'en', 'abbreviation', true),

-- HN019
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-hn019'), 'HN019', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-hn019'), 'Howaru Bifido', 'en', 'brand_like', false),

-- Shirota
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-casei-shirota'), '시로타균', 'ko', 'common', false),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-casei-shirota'), 'Shirota', 'en', 'common', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-casei-shirota'), '야쿠르트균', 'ko', 'common', false),

-- DSM 17938
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-reuteri-dsm17938'), 'DSM 17938', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-reuteri-dsm17938'), 'BioGaia Protectis', 'en', 'brand_like', false),

-- LP299v
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-plantarum-299v'), 'LP299v', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-plantarum-299v'), 'DSM 9843', 'en', 'scientific', false),

-- R0052
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-helveticus-r0052'), 'R0052', 'en', 'abbreviation', true),

-- R0175
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-r0175'), 'R0175', 'en', 'abbreviation', true),

-- BNR17
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-gasseri-bnr17'), 'BNR17', 'en', 'abbreviation', true),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-gasseri-bnr17'), 'BNRThin', 'en', 'brand_like', false),
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-gasseri-bnr17'), '가세리균', 'ko', 'common', false),

-- S. thermophilus
((SELECT id FROM ingredients WHERE slug = 'streptococcus-thermophilus'), '써모필루스', 'ko', 'common', false),

-- BGN4
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-bifidum-bgn4'), 'BGN4', 'en', 'abbreviation', true)

ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 3: 균주별 기능성(claims) 매핑
-- ============================================================================

INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES

-- LGG → 장건강 (A등급)
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'A', 'AAD 예방에 ESPGHAN 권장. 급성 설사 기간 1일 단축. 300+ RCT', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- LGG → 면역
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', '소아 호흡기 감염 빈도 감소. sIgA 분비 증가', false, NULL, NULL),

-- BB-12 → 장건강
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'A', '배변 빈도·장내 균총 개선에 다수 RCT 근거. 300+ 문헌', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- BB-12 → 면역
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', 'sIgA 증가, AAD 예방 보조', false, NULL, NULL),

-- NCFM → 장건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-acidophilus-ncfm'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', 'IBS 팽만감 73% 개선 (RCT). 급성 설사 기간 단축', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- BB536 → 장건강
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-bb536'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'A', 'IBS 복통 완화, 장내 균형 개선. 280+ 연구', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- BB536 → 면역
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-bb536'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', '면역 조절, 알레르기(꽃가루) 증상 완화, 소아 호흡기 감염 기간 단축', false, NULL, NULL),

-- HN001 → 면역
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-hn001'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', 'NK세포 활성 증가, 유아 아토피 예방', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- HN019 → 면역
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-hn019'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', 'NK세포, IFN-α 활성 증가. 고령자 면역 강화', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- HN019 → 장건강
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-hn019'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', '장 통과 시간 개선, 변비 완화', false, NULL, NULL),

-- Shirota → 장건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-casei-shirota'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'A', '장내 균총 개선, 변비/설사 완화. 500+ 연구', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- Shirota → 면역
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-casei-shirota'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'B', 'NK세포 활성 증가, 스트레스 관련 장 건강 유지', false, NULL, NULL),

-- DSM 17938 → 장건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-reuteri-dsm17938'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', '영아 산통 울음 시간 50% 감소. 급성 설사 기간 단축. H. pylori 보조', false, NULL, NULL),

-- LP299v → 장건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-plantarum-299v'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', 'IBS 복통에 EFSA Level 2 근거. C. difficile 설사 예방', false, NULL, NULL),

-- R0052 → 정신건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-helveticus-r0052'),
 (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH'),
 'B', 'R0175와 조합 시 불안·스트레스 완화. GABA 생성 촉진. WFSBP/CANMAT 잠정 권장', false, NULL, NULL),

-- R0175 → 정신건강
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-r0175'),
 (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH'),
 'B', 'R0052와 조합 시 우울증 보조. BDNF 증가. WFSBP/CANMAT 잠정 권장', false, NULL, NULL),

-- BNR17 → 체중관리
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-gasseri-bnr17'),
 (SELECT id FROM claims WHERE claim_code = 'WEIGHT_MANAGEMENT'),
 'B', '식약처 최초 체지방 감소 인정 균주. 허리/엉덩이 둘레 감소 RCT', true, 'KR', '체지방 감소에 도움'),

-- BNR17 → 장건강
((SELECT id FROM ingredients WHERE slug = 'lactobacillus-gasseri-bnr17'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'C', '장내 균총 개선 보조', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- S. thermophilus → 장건강
((SELECT id FROM ingredients WHERE slug = 'streptococcus-thermophilus'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', '유당 분해 지원 (EFSA 인정). 장내 유익균 지원', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- BGN4 → 장건강
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-bifidum-bgn4'),
 (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH'),
 'B', 'IBS 증상 완화, 장내 유해균 억제', true, 'KR', '유익균 증식 및 유해균 억제에 도움'),

-- BGN4 → 면역
((SELECT id FROM ingredients WHERE slug = 'bifidobacterium-bifidum-bgn4'),
 (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
 'C', '아토피 피부염 개선, 면역 균형 지원', false, NULL, NULL)

ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;


-- ============================================================================
-- SECTION 4: 제품별 균주 구성 등록 (product_ingredients)
-- ============================================================================
-- 기존 제품의 프로바이오틱스 row는 유지하고 (총 CFU), 균주별 상세를 추가

-- Culturelle Daily Probiotic → LGG 단일 균주
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name)
VALUES (
  (SELECT id FROM products WHERE product_name = 'Culturelle Daily Probiotic'),
  (SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'),
  100, '억 CFU', 'active', 'Lactobacillus rhamnosus GG (LGG) 10 Billion CFU'
) ON CONFLICT DO NOTHING;

-- 한미양행 프로바이오틱스 19종 — 주요 균주
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'lactobacillus-acidophilus-ncfm'),
 NULL, '억 CFU', 'active', 'Lactobacillus acidophilus'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'bifidobacterium-longum-bb536'),
 NULL, '억 CFU', 'active', 'Bifidobacterium longum'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-gg'),
 NULL, '억 CFU', 'active', 'Lactobacillus rhamnosus'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'),
 NULL, '억 CFU', 'active', 'Bifidobacterium animalis subsp. lactis'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'streptococcus-thermophilus'),
 NULL, '억 CFU', 'active', 'Streptococcus thermophilus'),
((SELECT id FROM products WHERE product_name LIKE '한미양행%'),
 (SELECT id FROM ingredients WHERE slug = 'bifidobacterium-bifidum-bgn4'),
 NULL, '억 CFU', 'active', 'Bifidobacterium bifidum')
ON CONFLICT DO NOTHING;

-- 세노비스 프로바이오틱스 — 주요 균주
INSERT INTO product_ingredients (product_id, ingredient_id, amount_per_serving, amount_unit, ingredient_role, raw_label_name) VALUES
((SELECT id FROM products WHERE product_name LIKE '세노비스%'),
 (SELECT id FROM ingredients WHERE slug = 'lactobacillus-rhamnosus-hn001'),
 NULL, '억 CFU', 'active', 'Lactobacillus rhamnosus HN001'),
((SELECT id FROM products WHERE product_name LIKE '세노비스%'),
 (SELECT id FROM ingredients WHERE slug = 'bifidobacterium-lactis-bb12'),
 NULL, '억 CFU', 'active', 'Bifidobacterium animalis subsp. lactis BB-12')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 5: 검증 쿼리
-- ============================================================================

SELECT '=== 프로바이오틱스 균주 세분화 결과 ===' AS section;

-- 균주 수
SELECT 'probiotic_strains' AS metric, count(*) AS value
FROM ingredients
WHERE parent_ingredient_id = (SELECT id FROM ingredients WHERE slug = 'probiotics');

-- 균주별 기능성 매핑
SELECT
  i.canonical_name_ko AS strain,
  i.slug,
  count(DISTINCT ic.claim_id) AS claim_count,
  string_agg(DISTINCT c.claim_code, ', ' ORDER BY c.claim_code) AS claims
FROM ingredients i
JOIN ingredient_claims ic ON ic.ingredient_id = i.id
JOIN claims c ON c.id = ic.claim_id
WHERE i.parent_ingredient_id = (SELECT id FROM ingredients WHERE slug = 'probiotics')
GROUP BY i.id, i.canonical_name_ko, i.slug
ORDER BY claim_count DESC;

-- 제품별 균주 구성
SELECT
  p.product_name,
  count(*) AS strain_count,
  string_agg(i.display_name, ', ' ORDER BY i.display_name) AS strains
FROM product_ingredients pi
JOIN products p ON p.id = pi.product_id
JOIN ingredients i ON i.id = pi.ingredient_id
WHERE i.parent_ingredient_id = (SELECT id FROM ingredients WHERE slug = 'probiotics')
GROUP BY p.id, p.product_name
ORDER BY strain_count DESC;
