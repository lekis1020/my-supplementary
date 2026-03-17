-- ============================================================================
-- 연구 근거 보강 — 013_enrich_evidence.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: Phase 1 — outcome↔claim 연결, 근거 등급, 정량 데이터, 누락 기능성 추가
-- 주의: 009_seed_evidence.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: 신규 claims (기존 18종 → 23종)
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('COGNITIVE_FUNCTION', '인지 기능 개선에 도움',       'Cognitive Function',    'brain',          'studied',     '인지 기능 유지 및 치매 위험 감소 연구'),
('BLOOD_SUGAR',        '혈당 조절에 도움',            'Blood Sugar Regulation','metabolic',      'studied',     '혈당 조절 및 당뇨 위험 감소 연구'),
('MUSCLE_STRENGTH',    '근력 및 운동 수행에 도움',    'Muscle & Exercise',     'musculoskeletal','studied',     '근력 향상 및 운동 수행 능력 연구'),
('WEIGHT_MANAGEMENT',  '체중 조절에 도움',            'Weight Management',     'metabolic',      'studied',     '체중 및 체지방 감소 연구'),
('MENTAL_HEALTH',      '정신 건강에 도움',            'Mental Health',         'brain',          'studied',     '우울·불안 등 정신 건강 관련 연구')
ON CONFLICT (claim_code) DO NOTHING;

-- ============================================================================
-- SECTION 2: 누락된 ingredient_claims 추가 (기존 28건 → 44건)
-- ============================================================================

INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression) VALUES
-- vitamin-d → 혈당 조절
((SELECT id FROM ingredients WHERE slug='vitamin-d'),
 (SELECT id FROM claims WHERE claim_code='BLOOD_SUGAR'),
 'B', '전당뇨 환자 대상 메타분석: 당뇨 발생 위험 15% 감소 (HR 0.85)', false, NULL, NULL),

-- vitamin-b12 → 인지 기능
((SELECT id FROM ingredients WHERE slug='vitamin-b12'),
 (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
 'C', 'B12 단독 효과 제한적; B군 비타민 복합 보충 시 인지 저하 완화 가능성', false, NULL, NULL),

-- omega-3 → 인지 기능
((SELECT id FROM ingredients WHERE slug='omega-3'),
 (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
 'B', 'DHA 섭취가 인지 저하 위험 ~20% 감소; 장기 보충 시 AD 위험 64% 감소', false, NULL, NULL),

-- magnesium → 수면
((SELECT id FROM ingredients WHERE slug='magnesium'),
 (SELECT id FROM claims WHERE claim_code='SLEEP_AID'),
 'B', '노인 불면증 대상: 수면 잠복기 17분 단축 (P=0.0006). 근거 질 낮음', false, NULL, NULL),

-- magnesium → 근력
((SELECT id FROM ingredients WHERE slug='magnesium'),
 (SELECT id FROM claims WHERE claim_code='MUSCLE_STRENGTH'),
 'C', '운동선수·건강인에서 유의한 효과 없음. 결핍 노인에서만 유익', false, NULL, NULL),

-- creatine → 근력 (핵심 기능성)
((SELECT id FROM ingredients WHERE slug='creatine'),
 (SELECT id FROM claims WHERE claim_code='MUSCLE_STRENGTH'),
 'A', '다수 메타분석에서 고강도 운동 시 근력·파워 출력 향상 확인', false, NULL, NULL),

-- collagen → 피부 건강
((SELECT id FROM ingredients WHERE slug='collagen'),
 (SELECT id FROM claims WHERE claim_code='SKIN_HEALTH'),
 'B', '콜라겐 펩타이드 보충이 피부 탄력·수분 개선에 기여', false, NULL, NULL),

-- collagen → 관절 건강
((SELECT id FROM ingredients WHERE slug='collagen'),
 (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
 'C', '관절 통증 감소에 소폭 기여; 대규모 근거 부족', false, NULL, NULL),

-- red-ginseng → 면역
((SELECT id FROM ingredients WHERE slug='red-ginseng'),
 (SELECT id FROM claims WHERE claim_code='IMMUNE_FUNCTION'),
 'B', '홍삼이 면역 세포(NK 세포 등) 활성화에 기여', true, 'KR', '면역력 증진에 도움'),

-- red-ginseng → 피로
((SELECT id FROM ingredients WHERE slug='red-ginseng'),
 (SELECT id FROM claims WHERE claim_code='ENERGY_METABOLISM'),
 'B', '홍삼의 항피로 효과 다수 임상 확인', true, 'KR', '피로 개선에 도움'),

-- MSM → 관절
((SELECT id FROM ingredients WHERE slug='msm'),
 (SELECT id FROM claims WHERE claim_code='JOINT_HEALTH'),
 'C', '골관절염 통증 감소에 소폭 기여; 근거 규모 제한적', false, NULL, NULL),

-- garcinia → 체중
((SELECT id FROM ingredients WHERE slug='garcinia'),
 (SELECT id FROM claims WHERE claim_code='WEIGHT_MANAGEMENT'),
 'D', 'HCA의 체중 감소 효과가 소규모이며 임상적 유의성 논란', false, NULL, NULL),

-- coq10 → 심혈관
((SELECT id FROM ingredients WHERE slug='coq10'),
 (SELECT id FROM claims WHERE claim_code='CARDIOVASCULAR'),
 'B', 'CoQ10이 심부전 환자의 운동 능력·증상 개선에 기여', false, NULL, NULL),

-- zinc → 정신 건강 (우울증 보조)
((SELECT id FROM ingredients WHERE slug='zinc'),
 (SELECT id FROM claims WHERE claim_code='MENTAL_HEALTH'),
 'B', 'WFSBP/CANMAT 가이드라인: 보조적 아연이 단극성 우울증에 잠정 권장(++)', false, NULL, NULL)

-- vitamin-c → 항산화 이미 있으므로 스킵
-- selenium → 이미 2건 있으므로 스킵
-- 기존 데이터와 충돌 방지
ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- ============================================================================
-- SECTION 3: evidence_outcomes 보강 — claim_id 매핑 + 정량 데이터 + 설명 교정
-- ============================================================================

-- ── vitamin-d (PMID 31405892) ──
-- 원래: '골밀도 및 골절 위험' → 실제: 사망률·암 사망 메타분석
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '전체 사망률 및 암 사망 위험',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '비타민 D 보충이 전체 사망률에 유의한 효과 없으나 (RR 0.98), 암 사망 위험을 16% 감소 (RR 0.84). 비타민 D3가 D2보다 우수한 경향',
  effect_size_text = 'RR 0.98 (전체 사망), RR 0.84 (암 사망)',
  p_value_text = '전체 사망: NS; 암 사망: P<0.05',
  confidence_interval_text = '전체: 0.95-1.02; 암: 0.74-0.95'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31405892' LIMIT 1);

-- ── vitamin-d (PMID 36745886) ──
-- 원래: '골밀도 및 골절 위험' → 실제: 전당뇨 → 당뇨 예방
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'BLOOD_SUGAR'),
  outcome_name = '전당뇨 환자의 당뇨 발생 위험 감소',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '비타민 D가 전당뇨 환자의 당뇨 발생 위험을 15% 감소 (HR 0.85). 혈중 25(OH)D ≥125nmol/L 도달 시 76% 감소. 정상 혈당 복귀 30% 증가',
  effect_size_text = 'HR 0.85 (당뇨 발생); ARR 3.3% (3년)',
  p_value_text = 'P<0.05',
  confidence_interval_text = 'HR: 0.75-0.96; ARR: 0.6%-6.0%'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36745886' LIMIT 1);

-- ── vitamin-c (PMID 34967304) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '호흡기 감염 기간 단축',
  conclusion_summary = '비타민 C가 호흡기 감염 발생에는 유의한 효과 없으나 (RR 0.94, P=0.09), 감염 기간을 유의하게 단축 (SMD -0.36, P=0.01)',
  effect_size_text = 'RR 0.94 (발생); SMD -0.36 (기간)',
  p_value_text = '발생: P=0.09 (NS); 기간: P=0.01',
  confidence_interval_text = '발생: 0.87-1.01; 기간: -0.62 to -0.09'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34967304' LIMIT 1);

-- ── vitamin-c (PMID 37682265) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = 'COVID-19 환자 염증 반응 완화',
  conclusion_summary = '고용량 비타민 C가 COVID-19 환자의 페리틴·림프구 수치 개선 및 질병 악화 억제 (OR 0.344, P=0.025)',
  effect_size_text = 'SMD 0.376 (림프구); OR 0.344 (악화 억제)',
  p_value_text = '림프구: P=0.001; 악화: P=0.025; ICU: P=0.004',
  confidence_interval_text = '림프구: 0.153-0.599; 악화: 0.135-0.873'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37682265' LIMIT 1);

-- ── vitamin-b12 (PMID 33809274) ──
-- 원래: '혈중 B12 수치 및 빈혈 개선' → 실제: 인지·우울 효과 없음
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '인지 기능 및 우울 증상 (효과 제한적)',
  effect_direction = 'neutral',
  conclusion_summary = 'B12 단독 또는 B복합 보충이 인지 기능·우울 증상에 유의한 효과 없음. 신경 장애 없는 대상에서 보충 효과 제한적 (16 RCTs, 6,276명)',
  effect_size_text = '인지·우울 전 영역 NS',
  p_value_text = 'NS (모든 하위 분석)',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33809274' LIMIT 1);

-- ── vitamin-b12 (PMID 34432056) ──
-- 원래: '혈중 B12 수치 및 빈혈 개선' → 실제: B군 비타민과 인지 저하
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '인지 저하 및 치매 예방 (B군 비타민)',
  effect_direction = 'positive',
  conclusion_summary = 'B군 비타민이 MMSE 점수 저하를 완화 (MD 0.14). 12개월 이상 비치매 대상에서 유효. 엽산 결핍·고호모시스테인이 치매 위험 증가와 연관. B12 단독보다 엽산 역할이 큼',
  effect_size_text = 'MD 0.14 (MMSE)',
  p_value_text = '-',
  confidence_interval_text = '0.04-0.23'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34432056' LIMIT 1);

-- ── folate (PMID 36321557) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'NEURAL_TUBE'),
  outcome_name = '엽산·말라리아 감수성 (항말라리아제 병용)',
  conclusion_summary = '말라리아 유행 지역에서 엽산 보충과 항말라리아제(SP) 병용에 대한 코크란 체계적 문헌고찰. 임산부 엽산 400μg/일 권고 유지'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36321557' LIMIT 1);

-- ── folate (PMID 39145520) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION'),
  outcome_name = '임산부 빈혈 예방 (철분+엽산)',
  conclusion_summary = '임산부 철분 보충이 빈혈 유의하게 감소 (RR 0.30). 저체중아 출산 감소 (RR 0.84). 57개 시험, 48,971명. 철+엽산 병용 평가 포함',
  effect_size_text = 'RR 0.30 (빈혈); RR 0.84 (저체중아)',
  p_value_text = '-',
  confidence_interval_text = '빈혈: 0.20-0.47; 저체중아: 0.72-0.99'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39145520' LIMIT 1);

-- ── omega-3 (PMID 37028557) ──
-- 원래: '혈중 중성지방 감소' → 실제: 인지 저하·치매 예방
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION'),
  outcome_name = '오메가-3와 인지 기능 저하·치매 예방',
  conclusion_summary = 'DHA 섭취가 인지 저하 위험 ~20% 감소 (RR 0.82, P=0.001). 장기 보충 시 AD 위험 64% 감소 (HR 0.36, P=0.004). DHA 0.1g/일 증가당 8-9.9% 위험 감소',
  effect_size_text = 'HR 0.36 (AD, 장기 보충); RR 0.82 (DHA 인지 저하)',
  p_value_text = 'AD: P=0.004; DHA: P=0.001; 용량반응: P<0.0005',
  confidence_interval_text = 'AD: 0.18-0.72; DHA: I²=63.6%'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37028557' LIMIT 1);

-- ── omega-3 (PMID 32114706) ──
-- 원래: '혈중 중성지방 감소' → 실제: 심혈관 질환 예방 (코크란)
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR'),
  outcome_name = '오메가-3와 심혈관 질환 예방',
  conclusion_summary = '86개 RCT (162,796명). 전체 사망률에 미미한 효과 (RR 0.97, 고확실성). 관상동맥 사건 소폭 감소 (RR 0.91, NNT 167). 뇌졸중·부정맥에 효과 없음',
  effect_size_text = 'RR 0.97 (전체 사망); RR 0.91 (CHD 사건)',
  p_value_text = '-',
  confidence_interval_text = '사망: 0.93-1.01; CHD: 0.85-0.97'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32114706' LIMIT 1);

-- ── magnesium (PMID 33865376) ──
-- 원래: '혈압 감소 효과' → 실제: 노인 불면증·수면 잠복기
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID'),
  outcome_name = '마그네슘과 노인 불면증 (수면 잠복기)',
  conclusion_summary = '마그네슘 보충이 수면 잠복기를 17.36분 단축 (P=0.0006). 총 수면시간 16분 증가 (비유의). 3개 RCT, 151명. 근거 질 낮음-매우 낮음',
  effect_size_text = '-17.36분 (수면 잠복기); +16.06분 (총 수면시간, NS)',
  p_value_text = '잠복기: P=0.0006; 수면시간: NS',
  confidence_interval_text = '잠복기: -27.27 to -7.44'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33865376' LIMIT 1);

-- ── magnesium (PMID 29637897) ──
-- 원래: '혈압 감소 효과' → 실제: 근육 기능
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH'),
  outcome_name = '마그네슘과 근육 기능',
  conclusion_summary = '운동선수·건강인에서 유의한 근력 개선 없음 (WMD 0.87, NS). 마그네슘 결핍 노인·알코올 중독자에서 유익. 14개 RCT, 542명',
  effect_size_text = 'WMD 0.87 (등속 최대 토크, NS); WMD 3.28 (근파워, NS)',
  p_value_text = 'NS (운동선수/건강인); 노인/결핍군에서 유의',
  confidence_interval_text = '토크: -1.43 to 3.18; 파워: -14.94 to 21.50'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29637897' LIMIT 1);

-- ── zinc (PMID 35311615) ──
-- 원래: '감기 증상 완화' → 실제: 정신 건강 가이드라인
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH'),
  outcome_name = '아연과 정신 건강 (WFSBP/CANMAT 가이드라인)',
  conclusion_summary = '31개국 전문가 31인 참여 임상 가이드라인. 보조적 아연이 단극성 우울증에 잠정 권장(++). 오메가-3(+++), 프로바이오틱스(++), 비타민D(+)도 우울증에 지지됨',
  effect_size_text = '권장 등급: ++ (Provisionally Recommended)',
  p_value_text = 'Grade A evidence (메타분석/2+ RCTs 기반)',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35311615' LIMIT 1);

-- ── zinc (PMID 39683510) ──
-- 원래: '감기 증상 완화' → 실제: 생리통 완화
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION'),
  outcome_name = '아연과 생리통(월경통) 완화',
  conclusion_summary = '아연 보충이 일차성 월경통의 통증 강도를 유의하게 감소 (Hedges g=-1.541, P<0.001). 8주 이상 복용 시 효과 증대. 7mg/일 원소 아연으로도 유의한 효과. 6개 RCT, 739명',
  effect_size_text = 'Hedges g = -1.541 (통증 강도)',
  p_value_text = 'P<0.001; 기간: P=0.003; 용량: P=0.005',
  confidence_interval_text = '-2.268 to -0.814'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39683510' LIMIT 1);

-- ── iron (PMID 36728680) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION'),
  outcome_name = '비스글리시네이트 철분의 헤모글로빈 개선',
  conclusion_summary = '비스글리시네이트 철분이 다른 철분 제제 대비 임산부 헤모글로빈 더 높이 증가 (SMD 0.54, P<0.01) 및 위장 부작용 감소 (IRR 0.36, P<0.01). 17개 RCT',
  effect_size_text = 'SMD 0.54 g/dL (Hb, 임산부)',
  p_value_text = 'Hb: P<0.01; 부작용: P<0.01',
  confidence_interval_text = 'Hb: 0.15-0.94; 부작용 IRR: 0.17-0.76'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36728680' LIMIT 1);

-- ── iron (PMID 39951396) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'RBC_FORMATION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39951396' LIMIT 1);

-- ── calcium (PMID 33237064) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'BONE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33237064' LIMIT 1);

-- ── calcium (PMID 26510847) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'BONE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '26510847' LIMIT 1);

-- ── probiotics (PMID 31004628) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31004628' LIMIT 1);

-- ── probiotics (PMID 37168869) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'GUT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37168869' LIMIT 1);

-- ── lutein (PMID 37702300) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37702300' LIMIT 1);

-- ── lutein (PMID 33998846) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33998846' LIMIT 1);

-- ── coq10 (PMID 39019217) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39019217' LIMIT 1);

-- ── coq10 (PMID 39129455) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'CARDIOVASCULAR')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39129455' LIMIT 1);

-- ── milk-thistle (PMID 38579127) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'LIVER_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38579127' LIMIT 1);

-- ── milk-thistle (PMID 32065376) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'LIVER_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32065376' LIMIT 1);

-- ── glucosamine (PMID 36142319) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36142319' LIMIT 1);

-- ── glucosamine (PMID 35024906) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35024906' LIMIT 1);

-- ── biotin (PMID 33171595) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'HAIR_NAIL')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);

-- ── biotin (PMID 38688776) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'HAIR_NAIL')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38688776' LIMIT 1);

-- ── selenium (PMID 38243784) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'THYROID_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38243784' LIMIT 1);

-- ── selenium (PMID 39698034) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'THYROID_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39698034' LIMIT 1);

-- ── vitamin-a (PMID 35294044) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35294044' LIMIT 1);

-- ── vitamin-a (PMID 8426449) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'EYE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '8426449' LIMIT 1);

-- ── vitamin-e (PMID 15537682) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTIOXIDANT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '15537682' LIMIT 1);

-- ── vitamin-e (PMID 37698992) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTIOXIDANT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37698992' LIMIT 1);

-- ── curcumin (PMID 35935936) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTI_INFLAMMATORY')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35935936' LIMIT 1);

-- ── curcumin (PMID 36804260) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'ANTI_INFLAMMATORY')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36804260' LIMIT 1);

-- ── melatonin (PMID 33417003) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33417003' LIMIT 1);

-- ── melatonin (PMID 35843245) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SLEEP_AID')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35843245' LIMIT 1);

-- ── red-ginseng (PMID 39474788) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);

-- ── red-ginseng (PMID 29624410) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'IMMUNE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);

-- ── MSM (PMID 29018060) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29018060' LIMIT 1);

-- ── MSM (PMID 35545381) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'JOINT_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35545381' LIMIT 1);

-- ── garcinia (PMID 38151892) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'WEIGHT_MANAGEMENT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38151892' LIMIT 1);

-- ── garcinia (PMID 38876392) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'WEIGHT_MANAGEMENT')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38876392' LIMIT 1);

-- ── collagen (PMID 33742704) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SKIN_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33742704' LIMIT 1);

-- ── collagen (PMID 34491424) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'SKIN_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34491424' LIMIT 1);

-- ── creatine (PMID 31375416) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31375416' LIMIT 1);

-- ── creatine (PMID 35984306) ──
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MUSCLE_STRENGTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);


-- ============================================================================
-- SECTION 4: evidence_studies 메타데이터 보강 (sample_size, population, duration)
-- ============================================================================

-- vitamin-d
UPDATE evidence_studies SET
  sample_size = 75454,
  population_text = '성인 (52개 RCT 통합)',
  duration_text = 'RCT 통합 (기간 다양)'
WHERE pmid = '31405892';

UPDATE evidence_studies SET
  sample_size = NULL, -- 3개 RCT (참가자 수 미명시)
  population_text = '전당뇨 성인',
  duration_text = '3년 추적'
WHERE pmid = '36745886';

-- vitamin-c
UPDATE evidence_studies SET
  sample_size = NULL, -- 10 studies
  population_text = '성인',
  duration_text = '연구 기간 다양'
WHERE pmid = '34967304';

UPDATE evidence_studies SET
  sample_size = 2334,
  population_text = 'COVID-19 환자 (7 RCT + 7 후향적 연구)',
  duration_text = '입원 기간'
WHERE pmid = '37682265';

-- vitamin-b12
UPDATE evidence_studies SET
  sample_size = 6276,
  population_text = '신경 장애 없는 성인 (16 RCTs)',
  duration_text = '연구 기간 다양'
WHERE pmid = '33809274';

UPDATE evidence_studies SET
  sample_size = 46175,
  population_text = '성인 (25 RCTs, 20 코호트, 50 횡단면)',
  duration_text = '>12개월 (유효 기간)'
WHERE pmid = '34432056';

-- omega-3
UPDATE evidence_studies SET
  sample_size = 103651,
  population_text = '비치매 성인 (평균 73세)',
  duration_text = '6년 추적 (ADNI 코호트)'
WHERE pmid = '37028557';

UPDATE evidence_studies SET
  sample_size = 162796,
  population_text = '심혈관 위험도 다양한 성인 (86 RCTs)',
  duration_text = '12-88개월'
WHERE pmid = '32114706';

-- magnesium
UPDATE evidence_studies SET
  sample_size = 151,
  population_text = '불면증 있는 노인 (3 RCTs)',
  duration_text = '연구별 상이'
WHERE pmid = '33865376';

UPDATE evidence_studies SET
  sample_size = 542,
  population_text = '운동선수 215명, 비훈련 건강인 95명, 노인/알코올 중독자 232명 (14 RCTs)',
  duration_text = '연구별 상이'
WHERE pmid = '29637897';

-- zinc
UPDATE evidence_studies SET
  population_text = '정신 질환 환자 (31개국 전문가 31인 가이드라인)',
  duration_text = '2019-2021 (가이드라인 개발 기간)'
WHERE pmid = '35311615';

UPDATE evidence_studies SET
  sample_size = 739,
  population_text = '일차성 월경통 여성 (6 RCTs)',
  duration_text = '≥8주 복용 시 효과 증대'
WHERE pmid = '39683510';

-- iron
UPDATE evidence_studies SET
  population_text = '임산부 및 아동 (17 RCTs: 임산부 9, 아동 4)',
  duration_text = '4-20주'
WHERE pmid = '36728680';

-- folate
UPDATE evidence_studies SET
  sample_size = 48971,
  population_text = '임산부 (57개 시험)',
  duration_text = '임신 기간'
WHERE pmid = '39145520';


-- ============================================================================
-- SECTION 5: 검증 쿼리
-- ============================================================================

SELECT '=== Phase 1 보강 결과 ===' AS section;

SELECT 'claims' AS entity, count(*) AS total_count FROM claims
UNION ALL
SELECT 'ingredient_claims', count(*) FROM ingredient_claims
UNION ALL
SELECT 'outcomes_with_claim', count(*) FROM evidence_outcomes WHERE claim_id IS NOT NULL
UNION ALL
SELECT 'outcomes_without_claim', count(*) FROM evidence_outcomes WHERE claim_id IS NULL
UNION ALL
SELECT 'outcomes_with_effect_size', count(*) FROM evidence_outcomes WHERE effect_size_text IS NOT NULL
UNION ALL
SELECT 'studies_with_sample_size', count(*) FROM evidence_studies WHERE sample_size IS NOT NULL
UNION ALL
SELECT 'studies_with_population', count(*) FROM evidence_studies WHERE population_text IS NOT NULL;

-- 원료별 claim 연결 현황
SELECT
  i.canonical_name_ko AS ingredient,
  count(DISTINCT ic.claim_id) AS claim_count,
  count(DISTINCT eo.id) AS outcome_count,
  string_agg(DISTINCT c.claim_code, ', ' ORDER BY c.claim_code) AS claims
FROM ingredients i
LEFT JOIN ingredient_claims ic ON ic.ingredient_id = i.id
LEFT JOIN claims c ON c.id = ic.claim_id
LEFT JOIN evidence_studies es ON es.ingredient_id = i.id
LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
WHERE i.is_active = true
GROUP BY i.id, i.canonical_name_ko
ORDER BY claim_count DESC;
