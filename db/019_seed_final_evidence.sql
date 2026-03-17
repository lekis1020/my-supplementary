-- ============================================================================
-- 마지막 5개 성분 근거 논문 추가 — 019_seed_final_evidence.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: 근거 논문이 없던 마지막 5개 성분(콜라겐, 가르시니아, 크레아틴, 홍삼, MSM) 보강
-- 주의: 018_seed_missing_evidence.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: 신규 claim 추가
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('WEIGHT_MANAGEMENT', '체중 관리에 도움', 'Weight Management', 'metabolic', 'studied', '체중 감소, 식욕 억제, 체지방 감소 관련 연구'),
('EXERCISE_PERFORMANCE', '운동 수행능력 향상', 'Exercise Performance', 'musculoskeletal', 'studied', '운동 능력, 근력, 근비대, 운동 퍼포먼스 관련 연구'),
('FATIGUE_RECOVERY', '피로 회복에 도움', 'Fatigue Recovery', 'general_wellness', 'studied', '피로 개선, 활력 증진, 에너지 수준 관련 연구')
ON CONFLICT (claim_code) DO NOTHING;

-- ============================================================================
-- SECTION 2: ingredient_claims 연결
-- ============================================================================

-- 콜라겐 → SKIN_HEALTH
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='collagen'),
  (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
  'B', '콜라겐 펩타이드 경구 보충이 피부 탄력 및 수분 유의 개선. 체계적 문헌고찰 및 메타분석', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 콜라겐 → COLLAGEN_SYNTHESIS
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='collagen'),
  (SELECT id FROM claims WHERE claim_code='COLLAGEN_SYNTHESIS'),
  'B', '가수분해 콜라겐이 내인성 콜라겐 합성 촉진에 기여. 피부 노화 지표 유의 개선', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 가르시니아 → WEIGHT_MANAGEMENT
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='garcinia'),
  (SELECT id FROM claims WHERE claim_code='WEIGHT_MANAGEMENT'),
  'C', '가르시니아 캄보지아(HCA)의 체중 감소 효과 메타분석에서 소규모 효과 관찰. 근거 수준 제한적', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 크레아틴 → EXERCISE_PERFORMANCE
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  (SELECT id FROM claims WHERE claim_code='EXERCISE_PERFORMANCE'),
  'A', '크레아틴 보충이 근력, 근비대, 운동 수행능력을 유의하게 향상시킴. 다수의 메타분석에서 일관된 결과', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- 홍삼 → FATIGUE_RECOVERY
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  (SELECT id FROM claims WHERE claim_code='FATIGUE_RECOVERY'),
  'B', '인삼/홍삼 보충이 피로 관련 증상 유의 개선. 2개 메타분석에서 질병 관련 및 일반 피로 모두에서 효과 확인', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- MSM → JOINT_HEALTH
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved)
VALUES (
  (SELECT id FROM ingredients WHERE slug='msm'),
  (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
  'B', 'MSM(메틸설포닐메탄)이 무릎 골관절염 통증 감소 및 관절 기능 개선. 메타분석 및 RCT 근거', false
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- ============================================================================
-- SECTION 3: 콜라겐 근거 논문 (PMID 33742704)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='collagen'),
  'pubmed',
  'Effects of hydrolyzed collagen supplementation on skin aging: a systematic review and meta-analysis.',
  '가수분해 콜라겐 경구 보충이 피부 노화에 미치는 효과를 분석한 체계적 문헌고찰 및 메타분석. 19개 RCT(1,125명)에서 콜라겐 보충이 피부 수분, 탄력, 주름을 유의하게 개선.',
  'de Miranda RB, Weimer P, Rossi RC',
  'International Journal of Dermatology',
  2021, '33742704', '10.1111/ijd.15518',
  'https://pubmed.ncbi.nlm.nih.gov/33742704/',
  'meta_analysis',
  1125, '건강 성인 (19개 RCT, 1,125명)', '4-24주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33742704' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
  '콜라겐 보충의 피부 노화 개선 효과',
  'efficacy', 'positive',
  '가수분해 콜라겐 보충이 피부 탄력(통합 효과 유의), 수분(SMD 개선), 주름(유의한 감소) 모두 개선',
  '피부 탄력, 수분, 주름 모두 유의한 개선',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='33742704' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='COLLAGEN_SYNTHESIS'),
  '경구 콜라겐의 콜라겐 합성 촉진',
  'biomarker', 'positive',
  '콜라겐 펩타이드 경구 보충이 진피 콜라겐 밀도 증가 및 프로콜라겐 합성 촉진에 기여',
  '진피 콜라겐 밀도 증가',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 4: 가르시니아 근거 논문 (PMID 31984610)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='garcinia'),
  'pubmed',
  'Effectiveness of herbal medicines for weight loss: A systematic review and meta-analysis of randomized controlled trials.',
  '가르시니아 캄보지아 포함 약용식물의 체중 감소 효과를 분석한 체계적 문헌고찰 및 메타분석. 가르시니아(HCA)는 소규모 체중 감소 효과를 보였으나 근거 수준은 낮음.',
  'Maunder A, Bessell E, Lauche R',
  'Diabetes, Obesity and Metabolism',
  2020, '31984610', '10.1111/dom.13973',
  'https://pubmed.ncbi.nlm.nih.gov/31984610/',
  'meta_analysis',
  '과체중/비만 성인 (RCT)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='31984610' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='WEIGHT_MANAGEMENT'),
  '가르시니아의 체중 감소 효과',
  'efficacy', 'positive',
  '가르시니아 캄보지아(HCA)가 소규모 체중 감소 효과를 보임. 그러나 효과 크기가 작고 연구 질이 제한적',
  '소규모 체중 감소 (임상적 유의성 제한적)',
  'P<0.05 (일부 연구)',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 5: 크레아틴 근거 논문 2건
-- ============================================================================

-- 5a. PMID 37432300 — 근비대 메타분석
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  'pubmed',
  'The Effects of Creatine Supplementation Combined with Resistance Training on Regional Measures of Muscle Hypertrophy: A Systematic Review with Meta-Analysis.',
  '크레아틴 보충 + 저항 운동이 부위별 근비대에 미치는 효과를 분석한 메타분석. 크레아틴이 상체 및 하체 제지방량을 유의하게 증가시킴.',
  'Burke R, Piñero A, Coleman M, Mohan A, Sapber M, Fahmi R, Joy JM, Moon JR, Schoenfeld BJ, De Souza EO',
  'Nutrients',
  2023, '37432300', '10.3390/nu15092116',
  'https://pubmed.ncbi.nlm.nih.gov/37432300/',
  'meta_analysis',
  '저항 운동 성인 (RCT)', '4주 이상',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37432300' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='EXERCISE_PERFORMANCE'),
  '크레아틴의 근비대 촉진 효과',
  'efficacy', 'positive',
  '크레아틴 보충이 저항 운동과 결합 시 상체(ES 0.38) 및 하체(ES 0.28) 제지방량을 유의하게 증가',
  'ES 0.38 (상체); ES 0.28 (하체)',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- 5b. PMID 30935142 — 운동 수행능력 메타분석
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  'pubmed',
  'Effects of Creatine Supplementation on Athletic Performance in Soccer Players: A Systematic Review and Meta-Analysis.',
  '축구 선수에서 크레아틴 보충의 운동 수행능력 효과를 분석한 메타분석. 크레아틴이 반복 스프린트, 점프 높이, 제지방량을 유의하게 향상.',
  'Mielgo-Ayuso J, Calleja-Gonzalez J, Marqués-Jiménez D, Caballero-García A, Córdova A, Fernández-Lázaro D',
  'Nutrients',
  2019, '30935142', '10.3390/nu11040757',
  'https://pubmed.ncbi.nlm.nih.gov/30935142/',
  'meta_analysis',
  '축구 선수 (RCT)', '1-8주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='30935142' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='EXERCISE_PERFORMANCE'),
  '크레아틴의 운동 수행능력 향상',
  'efficacy', 'positive',
  '크레아틴 보충이 축구 선수의 반복 스프린트 능력, 수직 점프 높이, 제지방량을 유의하게 향상시킴',
  '반복 스프린트, 점프, 제지방량 유의 향상',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 6: 홍삼 근거 논문 2건
-- ============================================================================

-- 6a. PMID 36730693 — 피로 관리 메타분석
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  'pubmed',
  'Ginseng and Ginseng Herbal Formulas for Symptomatic Management of Fatigue: A Systematic Review and Meta-Analysis.',
  '인삼 및 인삼 복합 처방의 피로 증상 관리 효과를 분석한 체계적 문헌고찰 및 메타분석. 인삼이 피로 증상 유의하게 개선.',
  'Li X, Guo W, Huang L, Choi H, Wang X, Liu P, Lee B',
  'Journal of Integrative and Complementary Medicine',
  2023, '36730693', '10.1089/jicm.2022.0532',
  'https://pubmed.ncbi.nlm.nih.gov/36730693/',
  'meta_analysis',
  '피로 증상 성인 (RCT)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='36730693' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='FATIGUE_RECOVERY'),
  '인삼의 피로 증상 개선 효과',
  'efficacy', 'positive',
  '인삼 보충이 피로 관련 증상을 유의하게 개선. 특히 만성 피로 및 질병 관련 피로에서 효과적',
  '피로 점수 유의 개선',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- 6b. PMID 35776997 — 질병 관련 피로 메타분석
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  'pubmed',
  'Efficacy of ginseng supplements on disease-related fatigue: A systematic review and meta-analysis.',
  '인삼 보충의 질병 관련 피로 개선 효과를 분석한 메타분석. 10개 RCT(868명) 분석 결과 인삼이 질병 관련 피로를 유의하게 개선 (SMD -0.34).',
  'Zhu J, Chen S, Wu Z, Wang J, Guo J',
  'Medicine',
  2022, '35776997', '10.1097/MD.0000000000029767',
  'https://pubmed.ncbi.nlm.nih.gov/35776997/',
  'meta_analysis',
  868, '질병 관련 피로 환자 (10개 RCT, 868명)', '4-12주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35776997' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='FATIGUE_RECOVERY'),
  '인삼의 질병 관련 피로 감소',
  'efficacy', 'positive',
  '인삼 보충이 질병 관련 피로를 유의하게 감소 (SMD -0.34, 95% CI: -0.53 to -0.14)',
  'SMD -0.34',
  'P=0.0006',
  '-0.53 to -0.14'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 7: MSM 근거 논문 2건
-- ============================================================================

-- 7a. PMID 19474240 — 골관절염 메타분석
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='msm'),
  'pubmed',
  'Meta-analysis of the related nutritional supplements dimethyl sulfoxide and methylsulfonylmethane in the treatment of osteoarthritis of the knee.',
  'DMSO/MSM의 무릎 골관절염 치료 효과 메타분석. MSM이 통증 및 신체 기능 개선에 유의한 효과.',
  'Brien S, Prescott P, Lewith G',
  'Evidence-Based Complementary and Alternative Medicine',
  2011, '19474240', '10.1093/ecam/nep045',
  'https://pubmed.ncbi.nlm.nih.gov/19474240/',
  'meta_analysis',
  '무릎 골관절염 환자 (RCT)', '12주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='19474240' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
  'MSM의 골관절염 통증 감소 효과',
  'efficacy', 'positive',
  'MSM이 무릎 골관절염 환자의 통증 감소(ES 1.0-1.5)와 신체 기능 개선에 유의한 효과',
  'ES 1.0-1.5 (통증 감소)',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- 7b. PMID 37447322 — 무릎 통증 RCT
INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='msm'),
  'pubmed',
  'Methylsulfonylmethane Improves Knee Quality of Life in Participants with Mild Knee Pain: A Randomized, Double-Blind, Placebo-Controlled Trial.',
  '경미한 무릎 통증 참가자에서 MSM의 무릎 관련 삶의 질 개선 효과를 평가한 이중맹검 RCT. MSM 3g/일 12주 투여 시 JKOM 점수 유의 개선.',
  'Toguchi A, Noguchi N, Kanno T, Yamada A',
  'Nutrients',
  2023, '37447322', '10.3390/nu15132995',
  'https://pubmed.ncbi.nlm.nih.gov/37447322/',
  'rct',
  100, '경미한 무릎 통증 성인 100명', '12주',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='37447322' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
  'MSM의 무릎 관련 삶의 질 개선',
  'efficacy', 'positive',
  'MSM 3g/일 12주 보충이 무릎 관련 삶의 질(JKOM) 점수를 위약 대비 유의하게 개선',
  'JKOM 점수 유의 개선',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 검증 쿼리
-- ============================================================================

SELECT '=== 최종 5개 성분 근거 추가 결과 ===' AS section;

-- 추가된 논문 확인
SELECT 'new_studies' AS check_item, count(*) AS cnt
FROM evidence_studies
WHERE pmid IN ('33742704','31984610','37432300','30935142','36730693','35776997','19474240','37447322');

-- 전체 포함 논문 수
SELECT 'total_included' AS check_item, count(*) AS cnt
FROM evidence_studies WHERE included_in_summary = true;

-- 근거 없는 성분 확인
SELECT 'no_evidence' AS check_item, i.canonical_name_ko, i.slug
FROM ingredients i
LEFT JOIN evidence_studies es ON es.ingredient_id = i.id AND es.included_in_summary = true
WHERE i.is_active = true
  AND i.slug IS NOT NULL
  AND i.parent_ingredient_id IS NULL
  AND es.id IS NULL;
