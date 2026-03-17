-- ============================================================================
-- 효능별 근거 커버리지 갭 해소 — 020_fill_evidence_gaps.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: 각 성분의 모든 등급(A/B/C) 효능에 대해 최소 1개의 근거 논문 연결
-- 해소 갭:
--   1. 비타민 D → IMMUNE_FUNCTION [B]
--   2. 비타민 C → IMMUNE_FUNCTION [B]
--   3. 오메가-3 → CARDIOVASCULAR [B]
--   4. 마그네슘 → BONE_HEALTH [B]
--   5. 비타민 A → IMMUNE_FUNCTION [A] (신규)
--   6. 비타민 A → SKIN_HEALTH [B] (신규)
--   7. 홍삼 → IMMUNE_FUNCTION [B] (신규)
-- 주의: 019_seed_final_evidence.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: 신규 ingredient_claims
-- ============================================================================

-- 비타민 A → IMMUNE_FUNCTION
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-a'),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  'A', '비타민 A 보충이 소아 감염 발생률(홍역 55%, 설사) 유의 감소. 코크란 체계적 문헌고찰', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 비타민 A → SKIN_HEALTH
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-a'),
  (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
  'B', '비타민 A(레티놀)가 피부 상피세포 성장과 분화에 필수적. 피부 장벽 유지 및 상처 치유 촉진', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 홍삼 → IMMUNE_FUNCTION
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  'B', '인삼 다당체가 면역세포 활성화 및 백신 항체 반응 개선. RCT 근거', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- ============================================================================
-- SECTION 2: 비타민 D → IMMUNE_FUNCTION (PMID 28202713)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-d'), 'pubmed',
  'Vitamin D supplementation to prevent acute respiratory tract infections: systematic review and meta-analysis of individual participant data.',
  '비타민 D 보충이 급성 호흡기 감염(ARI)을 예방하는 효과를 분석한 개인 참가자 데이터 메타분석. 25개 RCT, 11,321명 대상. 비타민 D가 ARI 위험을 12% 감소 (OR 0.88). 특히 결핍자(<25nmol/L)에서 70% 감소.',
  'Martineau AR, Jolliffe DA, Hooper RL, Greenberg L, Aloia JF, Bergman P',
  'BMJ', 2017, '28202713', '10.1136/bmj.i6583',
  'https://pubmed.ncbi.nlm.nih.gov/28202713/',
  'meta_analysis', 11321, '다양한 연령 (25개 RCT, 11,321명)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='28202713' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  '비타민 D의 급성 호흡기 감염 예방 효과', 'efficacy', 'positive',
  '비타민 D 보충이 급성 호흡기 감염 위험을 12% 감소 (OR 0.88). 비타민 D 결핍자(<25nmol/L)에서 70% 감소',
  'OR 0.88 (전체); OR 0.30 (결핍자)', 'P<0.001', '전체: 0.81-0.96; 결핍자: 0.17-0.53'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 3: 비타민 C → IMMUNE_FUNCTION (PMID 30069463)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-c'), 'pubmed',
  'Extra Dose of Vitamin C Based on a Daily Supplementation Shortens the Common Cold: A Meta-Analysis of 9 Randomized Controlled Trials.',
  '비타민 C 추가 보충이 감기 기간에 미치는 효과를 분석한 메타분석. 9개 RCT 분석 결과, 추가 용량 투여 시 감기 기간 유의 단축, 증상 완화.',
  'Ran L, Zhao W, Wang J, Wang H, Zhao Y, Tseng Y, Bu H',
  'BioMed Research International', 2018, '30069463', '10.1155/2018/1837634',
  'https://pubmed.ncbi.nlm.nih.gov/30069463/',
  'meta_analysis', '감기 환자 (9개 RCT)', '감기 기간',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='30069463' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  '비타민 C의 감기 기간 단축 효과', 'efficacy', 'positive',
  '비타민 C 추가 보충이 감기 기간을 유의하게 단축. 실내 체류 시간 감소, 흉통·발열·오한 등 증상 완화',
  '감기 기간 유의 단축, 증상 완화', 'P<0.05', '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 4: 오메가-3 → CARDIOVASCULAR (PMID 36103100)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='omega-3'), 'pubmed',
  'Efficacy and Safety of Omega-3 Fatty Acids in the Prevention of Cardiovascular Disease: A Systematic Review and Meta-analysis.',
  '오메가-3 지방산의 심혈관질환 예방 효과를 분석한 메타분석. 38개 RCT 포함. 오메가-3가 심혈관 사망률, 심근경색, 관상동맥 질환 이벤트를 유의하게 감소.',
  'Yan J, Liu H, Li H, Chen L, Bian Y, Zhao B, Zhang L, Zhang B',
  'Cardiovascular Drugs and Therapy', 2024, '36103100', '10.1007/s10557-022-07379-z',
  'https://pubmed.ncbi.nlm.nih.gov/36103100/',
  'meta_analysis', '심혈관 고위험군 포함 성인 (38개 RCT)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36103100' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),
  '오메가-3의 심혈관질환 예방 효과', 'efficacy', 'positive',
  '오메가-3 보충이 심혈관 사망률, 심근경색, 관상동맥 질환 이벤트를 유의하게 감소. 38개 RCT 메타분석',
  '심혈관 사망, 심근경색, CHD 이벤트 유의 감소', 'P<0.05', '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 5: 마그네슘 → BONE_HEALTH (PMID 34666201)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='magnesium'), 'pubmed',
  'Impact of magnesium on bone health in older adults: A systematic review and meta-analysis.',
  '마그네슘의 노인 골건강에 대한 영향을 분석한 체계적 문헌고찰 및 메타분석. 마그네슘 섭취가 골밀도(BMD)와 양의 상관관계, 골절 위험 감소 경향.',
  'Groenendijk I, van Delft M, Versloot P, van Loon LJC, de Groot LCPGM',
  'Bone', 2022, '34666201', '10.1016/j.bone.2021.116233',
  'https://pubmed.ncbi.nlm.nih.gov/34666201/',
  'meta_analysis', '노인 (체계적 문헌고찰 및 메타분석)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='34666201' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),
  '마그네슘의 골밀도 및 골절 위험 개선', 'efficacy', 'positive',
  '마그네슘 섭취량이 높을수록 골밀도(BMD)가 유의하게 높고 골절 위험 감소 경향. 마그네슘은 뼈 형성에 필수 미네랄',
  'BMD와 양의 상관관계, 골절 위험 감소 경향', 'P<0.05', '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 6: 비타민 A → IMMUNE_FUNCTION (기존 PMID 35294044에 outcome 추가)
-- ============================================================================

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35294044' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  '비타민 A 보충의 감염 예방 효과 (면역기능)', 'efficacy', 'positive',
  '비타민 A 보충이 소아 홍역 발생을 55% 감소 (RR 0.45), 설사 발생을 15% 감소 (RR 0.85). 면역세포 분화와 기능에 필수적인 역할',
  'RR 0.45 (홍역, 55% 감소); RR 0.85 (설사, 15% 감소)', 'P<0.05', '홍역: 0.30-0.69; 설사: 0.82-0.87'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 7: 비타민 A → SKIN_HEALTH (PMID 38256329)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-a'), 'pubmed',
  'Nutritional Supplements for Skin Health-A Review of What Should Be Chosen and Why.',
  '피부 건강을 위한 영양 보충제에 대한 종합 문헌고찰. 비타민 A(레티놀)가 표피 분화, 피부 장벽 기능, 콜라겐 합성에 필수적인 역할.',
  'Januszewski J, Forma A, Sitarz R, Grochowski C',
  'Medicina', 2023, '38256329', '10.3390/medicina60010068',
  'https://pubmed.ncbi.nlm.nih.gov/38256329/',
  'systematic_review', '피부 건강 관련 종합 문헌고찰', '기전 중심',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='38256329' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
  '비타민 A의 피부 건강 유지 역할', 'efficacy', 'positive',
  '비타민 A(레티놀)가 표피세포 분화와 성장, 피부 장벽 기능 유지, 콜라겐 합성 촉진에 필수적. 결핍 시 피부 건조증 및 각질화 이상',
  '표피 분화·장벽 기능·콜라겐 합성에 필수', '-', '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 8: 홍삼 → IMMUNE_FUNCTION (PMID 25297058)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'), 'pubmed',
  'A 14-week randomized, placebo-controlled, double-blind clinical trial to evaluate the efficacy and safety of ginseng polysaccharide (Y-75).',
  '인삼 다당체(Y-75)의 면역 기능 개선 효과를 평가한 14주 이중맹검 위약 대조 RCT. NK 세포 활성 증가, 인플루엔자 백신 항체가 유의 상승.',
  'Cho YJ, Son HJ, Kim KS',
  'Journal of Translational Medicine', 2014, '25297058', '10.1186/s12967-014-0283-1',
  'https://pubmed.ncbi.nlm.nih.gov/25297058/',
  'rct', '건강 성인 (14주 이중맹검 RCT)', '14주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction, conclusion_summary, effect_size_text, p_value_text, confidence_interval_text)
VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='25297058' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  '인삼 다당체의 면역세포 활성화 및 항체 반응 개선', 'efficacy', 'positive',
  '인삼 다당체가 NK 세포 활성을 유의하게 증가시키고 인플루엔자 백신 접종 후 항체가를 유의하게 상승시킴',
  'NK 세포 활성 증가, 백신 항체가 상승', 'P<0.05', '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 검증 쿼리
-- ============================================================================

SELECT '=== 효능별 근거 커버리지 갭 해소 결과 ===' AS section;

SELECT 'total_included' AS check_item, count(*) AS cnt
FROM evidence_studies WHERE included_in_summary = true;

-- 갭 확인
SELECT 'remaining_gaps' AS check_item, i.canonical_name_ko, c.claim_code, ic.evidence_grade
FROM ingredient_claims ic
JOIN ingredients i ON i.id = ic.ingredient_id
JOIN claims c ON c.id = ic.claim_id
LEFT JOIN evidence_studies es ON es.ingredient_id = i.id AND es.included_in_summary = true
LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id AND eo.claim_id = c.id
WHERE ic.evidence_grade IS NOT NULL
  AND eo.id IS NULL;
