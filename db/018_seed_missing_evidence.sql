-- ============================================================================
-- 누락 근거 논문 추가 — 018_seed_missing_evidence.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: Grade A/B 핵심 효능에 대한 직접 근거 논문이 없던 8건 보강
-- 주의: 017_fix_evidence_mappings.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- 1. 비타민 D → BONE_HEALTH (PMID 41470812)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-d'),
  'pubmed',
  'Effects of Combined Exercise and Calcium/Vitamin D Supplementation on Bone Mineral Density in Postmenopausal Women: A Systematic Review and Meta-Analysis.',
  '폐경 후 여성에서 운동+칼슘/비타민D 보충이 골밀도(BMD)에 미치는 효과를 분석한 체계적 문헌고찰 및 메타분석. 13개 RCT를 포함하여 요추 BMD (SMD 0.31), 대퇴경부 BMD (SMD 0.47) 유의한 증가 확인. 6개월 이내 개입에서 더 큰 효과.',
  'Bai J, Huang W, Yan R',
  'Nutrients',
  2025, '41470812', '10.3390/nu17243866',
  'https://pubmed.ncbi.nlm.nih.gov/41470812/',
  'meta_analysis',
  NULL, '폐경 후 여성 (13개 RCT)', '6개월 이내 시 효과 극대',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='41470812' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='BONE_HEALTH'),
  '폐경 후 여성의 골밀도 증가 (운동+칼슘/비타민D)',
  'efficacy', 'positive',
  '운동+칼슘/비타민D 보충이 폐경 후 여성의 요추 BMD (SMD 0.31)와 대퇴경부 BMD (SMD 0.47) 유의하게 증가. 전신진동 운동 병용 시 가장 일관된 효과. 보충제 단독보다 운동 병행이 효과적',
  'SMD 0.31 (요추); SMD 0.47 (대퇴경부)',
  'P<0.05',
  '요추: 0.06-0.55; 대퇴경부: 0.09-0.84'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. 비타민 C → ANTIOXIDANT (PMID 32162041)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-c'),
  'pubmed',
  'Effects of vitamin C on oxidative stress, inflammation, muscle soreness, and strength following acute exercise: meta-analyses of randomized clinical trials.',
  '비타민 C 보충이 운동 후 산화 스트레스, 염증, 근육통, 근력에 미치는 효과를 분석한 메타분석. 18개 RCT, 313명 대상. 지질 과산화 유의 감소 (SMD -0.488), IL-6 2시간 후 유의 감소 (SMD -0.764).',
  'Righi NC, Schuch FB, De Nardi AT',
  'European journal of nutrition',
  2020, '32162041', '10.1007/s00394-020-02215-2',
  'https://pubmed.ncbi.nlm.nih.gov/32162041/',
  'meta_analysis',
  313, '건강 성인 (18개 RCT)', '급성 운동 전후',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='32162041' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='ANTIOXIDANT'),
  '비타민 C의 산화 스트레스 감소 효과',
  'biomarker', 'positive',
  '비타민 C가 운동 유발 지질 과산화를 유의하게 감소 (SMD -0.488). IL-6도 운동 2시간 후 유의 감소 (SMD -0.764). 항산화 기능으로 세포 보호에 기여',
  'SMD -0.488 (지질 과산화); SMD -0.764 (IL-6)',
  '지질과산화: P<0.05; IL-6: P<0.05',
  '지질과산화: -0.888 to -0.088; IL-6: -1.279 to -0.248'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. 오메가-3 → BLOOD_LIPID (PMID 41156531)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='omega-3'),
  'pubmed',
  'Marine-Based Omega-3 Fatty Acids and Metabolic Syndrome: A Systematic Review and Meta-Analysis of Randomized Controlled Trials.',
  '해양성 오메가-3 지방산의 대사증후군 개선 효과를 분석한 체계적 문헌고찰 및 메타분석. 21개 RCT, 약 1,950명 대상. 고용량(>2,000mg/일) 오메가-3가 중성지방을 장기 -56.78mg/dL, 단기 -50.87mg/dL 유의하게 감소.',
  'Basirat A, Merino-Torres JF',
  'Nutrients',
  2025, '41156531', '10.3390/nu17203279',
  'https://pubmed.ncbi.nlm.nih.gov/41156531/',
  'meta_analysis',
  1950, '대사증후군 성인 (21개 RCT)', '단기 및 장기',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='41156531' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='BLOOD_LIPID'),
  '오메가-3의 혈중 중성지방 감소 효과',
  'efficacy', 'positive',
  '고용량 해양성 오메가-3(>2,000mg/일)가 중성지방을 장기 -56.78mg/dL, 단기 -50.87mg/dL 유의하게 감소. 대사증후군 관리를 위한 식이 전략으로 권장',
  '-56.78 mg/dL (장기); -50.87 mg/dL (단기)',
  'P<0.05',
  '장기: ±3.44; 단기: ±3.04'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. 마그네슘 → ENERGY_METABOLISM (PMID 34836329)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='magnesium'),
  'pubmed',
  'Oral Magnesium Supplementation for Treating Glucose Metabolism Parameters in People with or at Risk of Diabetes.',
  '마그네슘 경구 보충이 당뇨 환자 및 고위험군의 포도당 대사 지표에 미치는 효과를 분석한 체계적 문헌고찰 및 메타분석. 이중맹검 RCT만 포함. 마그네슘 보충이 공복혈당 감소, 내당능 개선, 인슐린 민감성 향상. 마그네슘은 해당과정·ATP 합성 등 300+ 효소의 필수 보조인자.',
  'Veronese N, Dominguez LJ, Pizzol D',
  'Nutrients',
  2021, '34836329', '10.3390/nu13114074',
  'https://pubmed.ncbi.nlm.nih.gov/34836329/',
  'meta_analysis',
  '당뇨 환자 및 고위험 성인 (이중맹검 RCT)', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='34836329' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
  '마그네슘의 포도당 대사 개선 (에너지 대사 보조인자)',
  'efficacy', 'positive',
  '마그네슘 보충이 당뇨 환자의 공복혈당 감소, 고위험군의 내당능 개선, 인슐린 민감성 향상. 마그네슘은 해당과정 및 ATP 합성 등 300+ 효소의 필수 보조인자로 에너지 대사에 직접 관여',
  '공복혈당 감소, 인슐린 민감성 개선 (정량치 원문 참조)',
  'P<0.05',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. 아연 → IMMUNE_FUNCTION (PMID 23775705)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  sample_size, population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='zinc'),
  'pubmed',
  'Zinc for the common cold.',
  '아연 보충의 감기 치료 및 예방 효과를 분석한 코크란 체계적 문헌고찰. 18개 시험(치료 16, 예방 2), 1,781명 대상. 아연이 감기 기간을 평균 1.03일 단축 (MD -1.03, P<0.05). 예방적 복용 시 감기 발생률 36% 감소 (IRR 0.64). 증상 발현 24시간 이내 ≥75mg/일 아연 로젠지 권장.',
  'Singh M, Das RR',
  'The Cochrane database of systematic reviews',
  2013, '23775705', '10.1002/14651858.CD001364.pub4',
  'https://pubmed.ncbi.nlm.nih.gov/23775705/',
  'meta_analysis',
  1781, '감기 환자 및 건강 성인 (18개 시험)', '감기 기간',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='23775705' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
  '아연의 감기 기간 단축 및 발생률 감소',
  'efficacy', 'positive',
  '아연이 감기 기간을 평균 1.03일 단축. 예방적 복용 시 감기 발생률 36% 감소 (IRR 0.64). 증상 발현 24시간 이내 ≥75mg/일 아연 로젠지 사용 시 효과적. 코크란 체계적 문헌고찰',
  'MD -1.03일 (기간); IRR 0.64 (발생률)',
  '기간: P<0.05; 발생률: P<0.05',
  '기간: -1.72 to -0.34; 발생률: 0.47-0.88'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. 비타민 B12 → RBC_FORMATION (PMID 39964959)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-b12'),
  'pubmed',
  'Comparison of Efficacy and Safety of Parenteral vs Oral Route of Vitamin B12 Supplementation for the Treatment of Vitamin B12 Deficiency Anemia in Children.',
  '소아 비타민 B12 결핍 빈혈에서 비경구 vs 경구 B12 보충의 효능·안전성 비교 체계적 문헌고찰. 6,467편 스크리닝 후 1개 적격 RCT 포함. 비경구 투여가 B12 수치 더 높이 회복 (653 vs 506 pg/mL). 헤모글로빈 개선이 비경구에서 유의하게 우수 (P=0.001). B12가 적혈구 형성에 직접 필수적임을 확인.',
  'Sachdeva M, Purohit A, Malik M',
  'Nutrition reviews',
  2025, '39964959', '10.1093/nutrit/nuae227',
  'https://pubmed.ncbi.nlm.nih.gov/39964959/',
  'systematic_review',
  '소아 B12 결핍 빈혈 환자', '연구별 상이',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='39964959' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='RBC_FORMATION'),
  '비타민 B12 보충의 결핍 빈혈 교정',
  'efficacy', 'positive',
  'B12 보충이 결핍 빈혈을 교정하며 헤모글로빈 수치 유의 개선 (P=0.001). 비경구 투여가 경구보다 B12 수치 더 높이 회복 (653 vs 506 pg/mL). B12는 적혈구 성숙 과정에 필수적인 보조인자',
  'B12: 653 vs 506 pg/mL (비경구 vs 경구)',
  'Hb 개선: P=0.001',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. 비타민 C → COLLAGEN_SYNTHESIS (PMID 40317316)
-- ============================================================================

INSERT INTO evidence_studies (
  ingredient_id, source_type, title, abstract_text, authors, journal_name,
  publication_year, pmid, doi, external_url, study_design,
  population_text, duration_text,
  screening_status, included_in_summary
) VALUES (
  (SELECT id FROM ingredients WHERE slug='vitamin-c'),
  'pubmed',
  'Functional and molecular insights in topical wound healing by ascorbic acid.',
  '아스코르브산(비타민 C)의 콜라겐 합성 촉진 및 상처 치유 기전에 대한 종합 문헌고찰. 아스코르브산이 프롤린·리신 잔기의 수산화를 직접 촉매하여 콜라겐 합성에 필수적. 항산화 방어, 재상피화, 혈관신생 촉진. 콜라겐 의존적 조직 복구에서 우수한 생체적합성과 효능.',
  'Jha B, Majie A, Roy K',
  'Naunyn-Schmiedeberg''s archives of pharmacology',
  2025, '40317316', '10.1007/s00210-025-04180-1',
  'https://pubmed.ncbi.nlm.nih.gov/40317316/',
  'systematic_review',
  '상처 치유 모델 (종합 문헌고찰)', '기전 중심',
  'included', true
) ON CONFLICT DO NOTHING;

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='40317316' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='COLLAGEN_SYNTHESIS'),
  '아스코르브산의 콜라겐 합성 촉진 기전',
  'efficacy', 'positive',
  '아스코르브산은 프롤릴·리실 하이드록실라아제의 필수 보조인자로 콜라겐 합성에 직접 관여. 결핍 시 괴혈병(콜라겐 결합조직 붕괴) 발생. 항산화 작용으로 세포 보호, 재상피화·혈관신생 촉진. 콜라겐 의존적 조직 복구에 필수적',
  '프롤린/리신 수산화 촉매 (기전적 필수 보조인자)',
  '-',
  '-'
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. 비타민 A → EYE_HEALTH: 기존 PMID 35294044에 야맹증 결과 추가
-- (이미 DB에 존재하지만 outcome이 사망률 중심 → 야맹증 outcome 추가)
-- ============================================================================

INSERT INTO evidence_outcomes (
  evidence_study_id, claim_id, outcome_name, outcome_type, effect_direction,
  conclusion_summary, effect_size_text, p_value_text, confidence_interval_text
) VALUES (
  (SELECT id FROM evidence_studies WHERE pmid='35294044' LIMIT 1),
  (SELECT id FROM claims WHERE claim_code='EYE_HEALTH'),
  '비타민 A 보충의 야맹증 예방 효과',
  'efficacy', 'positive',
  '비타민 A 보충이 소아 야맹증을 68% 감소 (RR 0.32, 중등도 확실성 근거). 홍역 발생도 55% 감소 (RR 0.45). 47개 연구, ~1,223,856명 소아 대상 코크란 체계적 문헌고찰',
  'RR 0.32 (야맹증, 68% 감소); RR 0.45 (홍역)',
  '야맹증: P<0.05; 홍역: P<0.05',
  '야맹증: 0.21-0.50; 홍역: 0.30-0.69'
) ON CONFLICT DO NOTHING;


-- ============================================================================
-- 검증 쿼리
-- ============================================================================

SELECT '=== 누락 근거 추가 결과 ===' AS section;

-- 추가된 논문 확인
SELECT 'new_studies' AS check_item, count(*) AS cnt
FROM evidence_studies
WHERE pmid IN ('41470812','32162041','41156531','34836329','23775705','39964959','40317316');

-- Grade A 효능별 논문 커버리지
SELECT
  i.canonical_name_ko AS ingredient,
  c.claim_code,
  ic.evidence_grade,
  count(DISTINCT es.id) AS study_count
FROM ingredient_claims ic
JOIN ingredients i ON i.id = ic.ingredient_id
JOIN claims c ON c.id = ic.claim_id
LEFT JOIN evidence_studies es ON es.ingredient_id = i.id AND es.included_in_summary = true
LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id AND eo.claim_id = c.id
WHERE ic.evidence_grade IN ('A', 'B')
  AND i.is_active = true
GROUP BY i.canonical_name_ko, c.claim_code, ic.evidence_grade
ORDER BY ic.evidence_grade, study_count ASC;
