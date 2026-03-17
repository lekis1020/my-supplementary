-- ============================================================================
-- 연구 근거 보강 Phase 2 — 015_enrich_evidence_phase2.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적: 013에서 claim_id만 설정된 36건의 evidence_outcomes에 정량 데이터 추가
--       + 잘못된 claim_id 매핑 교정 + evidence_studies 메타데이터 보강
-- 주의: 013_enrich_evidence.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: claim_id 매핑 교정 (논문 실제 내용과 불일치 수정)
-- ============================================================================

-- red-ginseng PMID 39474788: 인지 기능 연구인데 IMMUNE_FUNCTION으로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);

-- red-ginseng PMID 29624410: 피로 개선 연구인데 IMMUNE_FUNCTION으로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'ENERGY_METABOLISM')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);

-- creatine PMID 35984306: 기억력 연구인데 MUSCLE_STRENGTH로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'COGNITIVE_FUNCTION')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);

-- biotin PMID 33171595: 우울증 연구인데 HAIR_NAIL로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'MENTAL_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);

-- ============================================================================
-- SECTION 2: evidence_outcomes 정량 데이터 보강
-- ============================================================================

-- ── iron (PMID 39951396) — 소아 철결핍빈혈 최적 보충 ──
UPDATE evidence_outcomes SET
  outcome_name = '소아·청소년 철결핍빈혈의 철분 보충 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '철분 보충이 헤모글로빈 2.01 g/dL 개선 (P<0.001). 저용량(<5mg/kg/일)이 최적. 3개월 미만 투여 시 가장 높은 효과크기 (2.39 g/dL). 28개 연구, 8,829명',
  effect_size_text = 'SMD 2.01 g/dL (Hb 개선); 2.39 g/dL (<3개월)',
  p_value_text = 'P<0.001',
  confidence_interval_text = 'Hb: 1.48-2.54; <3개월: 0.72-4.07'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39951396' LIMIT 1);

-- ── calcium (PMID 33237064) — 폐경 후 골밀도 ──
UPDATE evidence_outcomes SET
  outcome_name = '칼슘+비타민D의 폐경 후 골밀도 및 골절 예방',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '칼슘+비타민D가 총 골밀도 유의하게 증가 (SMD 0.537). 요추 (SMD 0.233, P<0.001), 대퇴경부 (SMD 0.187) 골밀도 증가. 고관절 골절 13.6% 감소 (RR 0.864). 유제품 강화식이가 보충제보다 효과적',
  effect_size_text = 'SMD 0.537 (총 BMD); RR 0.864 (고관절 골절)',
  p_value_text = '총 BMD: P<0.05; 요추: P<0.001',
  confidence_interval_text = 'BMD: 0.227-0.847; 골절: 0.763-0.979'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33237064' LIMIT 1);

-- ── calcium (PMID 26510847) — 골절 예방 NOF 메타분석 ──
UPDATE evidence_outcomes SET
  outcome_name = '칼슘+비타민D의 골절 위험 감소 (NOF)',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '칼슘+비타민D가 총 골절 15% 감소 (SRRE 0.85), 고관절 골절 30% 감소 (SRRE 0.70). 지역사회·시설 거주 중·고령 성인 모두에서 유효. 8개 RCT, 30,970명',
  effect_size_text = 'SRRE 0.85 (총 골절); SRRE 0.70 (고관절)',
  p_value_text = '총 골절: P<0.05; 고관절: P<0.05',
  confidence_interval_text = '총: 0.73-0.98; 고관절: 0.56-0.87'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '26510847' LIMIT 1);

-- ── probiotics (PMID 31004628) — 우울·불안 개선 ──
UPDATE evidence_outcomes SET
  outcome_name = '프로바이오틱스의 우울·불안 증상 개선 (장-뇌 축)',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '프로바이오틱스가 우울 증상에 소효과 (d=-0.24, P<0.01), 불안에도 유의 (d=-0.10, P=0.03). 정신과 환자에서 중-대 효과크기 (d=-0.73, P<0.001). 프리바이오틱스는 효과 없음. 34개 대조 임상시험',
  effect_size_text = 'd=-0.24 (우울); d=-0.10 (불안); d=-0.73 (정신과 환자)',
  p_value_text = '우울: P<0.01; 불안: P=0.03; 정신과: P<0.001',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31004628' LIMIT 1);

-- ── probiotics (PMID 37168869) — 장벽 기능 강화 ──
UPDATE evidence_outcomes SET
  outcome_name = '프로바이오틱스의 장벽 기능 강화 및 항염증',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '프로바이오틱스가 장벽 투과성(TER) 유의하게 개선 (MD 5.27, P<0.00001). 혈청 조눌린 (SMD -1.58, P=0.0007), 내독소 (SMD -3.20, P=0.005), LPS (SMD -0.47, P=0.02) 감소. CRP, TNF-α, IL-6 감소. Bifidobacterium·Lactobacillus 증가. 26개 RCT, 1,891명',
  effect_size_text = 'MD 5.27 (TER); SMD -1.58 (조눌린); SMD -3.20 (내독소)',
  p_value_text = 'TER: P<0.00001; 조눌린: P=0.0007; 내독소: P=0.005',
  confidence_interval_text = 'TER: 3.82-6.72; 조눌린: -2.49 to -0.66'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37168869' LIMIT 1);

-- ── lutein (PMID 37702300) — 항산화 비타민·루테인의 AMD 진행 억제 ──
UPDATE evidence_outcomes SET
  outcome_name = '항산화 비타민·루테인의 노인성 황반변성(AMD) 진행 억제',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '항산화 비타민이 후기 AMD 진행 위험 28% 감소 (OR 0.72, 중등도 확실성). 신생혈관 AMD (OR 0.62), 시력 손실 (OR 0.77) 감소. AREDS2에서 루테인/제아잔틴이 베타카로틴 대체 시 추가 18% 감소 (HR 0.82). 26개 연구, 11,952명',
  effect_size_text = 'OR 0.72 (후기 AMD); HR 0.82 (루테인/제아잔틴)',
  p_value_text = '-',
  confidence_interval_text = 'AMD: 0.58-0.90; 루테인: 0.69-0.96'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37702300' LIMIT 1);

-- ── lutein (PMID 33998846) — 카로티노이드 항염증 ──
UPDATE evidence_outcomes SET
  outcome_name = '카로티노이드(루테인 포함)의 항염증 효과',
  outcome_type = 'biomarker',
  effect_direction = 'positive',
  conclusion_summary = '카로티노이드 보충이 CRP (WMD -0.54, P<0.001), IL-6 (WMD -0.54, P=0.025) 유의하게 감소. 루테인/제아잔틴 단독: CRP WMD -0.30 (P<0.001). TNF-α는 비유의 (P=0.059). 26개 시험, 35개 효과크기',
  effect_size_text = 'WMD -0.54 mg/L (CRP); WMD -0.30 mg/L (루테인 CRP)',
  p_value_text = 'CRP: P<0.001; IL-6: P=0.025; 루테인 CRP: P<0.001',
  confidence_interval_text = 'CRP: -0.71 to -0.37; 루테인: -0.45 to -0.15'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33998846' LIMIT 1);

-- ── coq10 (PMID 39019217) — 항산화제·CoQ10의 난소 노화 여성 생식능 ──
UPDATE evidence_outcomes SET
  outcome_name = 'CoQ10의 난소 노화 여성 생식능 개선 (항산화)',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = 'CoQ10이 난소 예비력 저하 여성의 임상 임신율 증가, 채취 난자 수·고품질 배아율 향상, 생식선자극호르몬 사용량 감소. CoQ10이 멜라토닌·미오이노시톨·비타민보다 효과적. 최적: 30mg/일, 3개월. 20개 RCT, 2,617명. (참고: 심혈관이 아닌 생식 건강 연구)',
  effect_size_text = '임상 임신율 향상 (CoQ10이 타 항산화제 대비 우수)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39019217' LIMIT 1);

-- ── coq10 (PMID 39129455) — CoQ10 전처치와 IVF/ICSI ──
UPDATE evidence_outcomes SET
  outcome_name = 'CoQ10 전처치의 IVF/ICSI 결과 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = 'CoQ10 전처치가 DOR 여성의 임상 임신율 84% 증가 (OR 1.84, P=0.0002). 채취 난자 수 증가 (MD 1.30, P<0.00001). 유산율 감소 (OR 0.38, P=0.05). 주기 취소율 감소 (OR 0.60, P=0.002). 6개 RCT, 1,529명. (참고: 심혈관이 아닌 생식 건강 연구)',
  effect_size_text = 'OR 1.84 (임신율); MD 1.30 (난자 수); OR 0.38 (유산율)',
  p_value_text = '임신율: P=0.0002; 난자: P<0.00001; 유산: P=0.05',
  confidence_interval_text = '임신: 1.33-2.53; 난자: 1.21-1.40; 유산: 0.15-0.98'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39129455' LIMIT 1);

-- ── milk-thistle (PMID 38579127) — 실리마린 NAFLD/NASH ──
UPDATE evidence_outcomes SET
  outcome_name = '실리마린의 비알코올 지방간(NAFLD) 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '실리마린이 NAFLD 환자의 ALT (SMD -12.39), AST (SMD -10.97) 유의하게 감소. 간 조직학적 지방증 개선 (OR 3.25, P<0.001). 총콜레스테롤 (SMD -0.85), 중성지방 (SMD -0.62) 감소. 인슐린 저항성 개선 (HOMA-IR SMD -0.37). 26개 RCT, 2,375명',
  effect_size_text = 'SMD -12.39 (ALT); SMD -10.97 (AST); OR 3.25 (지방증 개선)',
  p_value_text = 'ALT/AST: P<0.05; 지방증: P<0.001',
  confidence_interval_text = 'ALT: -19.69 to -5.08; AST: -15.51 to -6.43; 지방증: 1.80-5.87'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38579127' LIMIT 1);

-- ── milk-thistle (PMID 32065376) — 실리마린 간 질환 서술적 고찰 ──
UPDATE evidence_outcomes SET
  outcome_name = '실리마린의 간 질환 보조 치료 (서술적 고찰)',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '실리마린이 알코올성·비알코올성 지방간, 약물 유발 간 손상에서 간 보호 효과. 간경변 환자 통합 분석: 간 관련 사망 유의하게 감소. 당뇨+알코올성 간경변 환자에서 혈당 지표 개선. 부작용 발생률 낮음',
  effect_size_text = '간경변 환자에서 간 관련 사망 유의하게 감소 (통합 분석)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '32065376' LIMIT 1);

-- ── glucosamine (PMID 36142319) — 글루코사민 관절염 (동물 연구) ──
UPDATE evidence_outcomes SET
  outcome_name = '글루코사민·콘드로이틴의 골관절염 진통 효과 (동물 연구)',
  outcome_type = 'efficacy',
  effect_direction = 'neutral',
  conclusion_summary = '개·고양이 골관절염 대상 체계적 문헌고찰. 콘드로이틴-글루코사민은 뚜렷한 무효과(non-effect) 판정. 오메가-3 강화식이와 CBD가 임상적 진통 효과 보임. 57편, 72개 시험. (참고: 동물 연구로 인체 적용에 한계)',
  effect_size_text = '콘드로이틴-글루코사민: non-effect (무효과)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36142319' LIMIT 1);

-- ── glucosamine (PMID 35024906) — 글루코사민+콘드로이틴 무릎 OA ──
UPDATE evidence_outcomes SET
  outcome_name = '글루코사민+콘드로이틴 병용의 무릎 골관절염 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '글루코사민+콘드로이틴 병용이 위약 대비 WOMAC 총점 유의하게 개선 (MD -12.04, P=0.02). 관절 간격 협착 소폭 억제 (MD -0.09, P=0.04). VAS 통증 점수는 유의차 없음. 안전성 차이 없음. 8개 RCT, 3,793명',
  effect_size_text = 'MD -12.04 (WOMAC); MD -0.09 (관절 간격)',
  p_value_text = 'WOMAC: P=0.02; JSN: P=0.04; VAS: NS',
  confidence_interval_text = 'WOMAC: -22.33 to -1.75; JSN: -0.18 to -0.00'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35024906' LIMIT 1);

-- ── biotin (PMID 33171595) — 프로바이오틱스+비오틴 우울증 (claim_id 이미 MENTAL_HEALTH로 교정) ──
UPDATE evidence_outcomes SET
  outcome_name = '프로바이오틱스+비오틴의 우울증 보조 효과',
  outcome_type = 'efficacy',
  effect_direction = 'neutral',
  conclusion_summary = '입원 우울증 환자 82명 대상 이중맹검 RCT. 4주간 프로바이오틱스+비오틴 보충 시 양 군 모두 정신과 증상 유의하게 개선. 프로바이오틱스 군에서 장내 Ruminococcus·Coprococcus 증가, β다양성 상승. 위약 대비 임상적 결과 차이는 비유의',
  effect_size_text = '양 군 정신과 증상 유의 개선; 군간 차이 NS',
  p_value_text = '군간 비교: NS; β다양성: P<0.05',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33171595' LIMIT 1);

-- ── biotin (PMID 38688776) — 비오틴 vs 미녹시딜 모발 성장 ──
UPDATE evidence_outcomes SET
  outcome_name = '경구 비오틴 vs 국소 미녹시딜의 남성 모발 성장',
  outcome_type = 'efficacy',
  effect_direction = 'neutral',
  conclusion_summary = '남성 탈모 대상 무작위 교차 RCT. 5% 국소 미녹시딜, 5mg 경구 비오틴, 병용의 모발 성장 비교. (초록 미제공으로 상세 정량 데이터 제한적)',
  effect_size_text = '초록 미제공 — 원문 참조 필요',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38688776' LIMIT 1);

-- ── selenium (PMID 38243784) — 셀레늄 하시모토 갑상선염 ──
UPDATE evidence_outcomes SET
  outcome_name = '셀레늄의 하시모토 갑상선염 치료 보조 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '셀레늄이 비갑상선호르몬 대체요법 환자에서 TSH 유의하게 감소 (SMD -0.21, I²=0%). TPOAb 유의하게 감소 (SMD -0.96, I²=90%). 산화 스트레스 MDA 감소 (SMD -1.16). 부작용 위약과 유사 (OR 0.89). 35개 RCT, 근거 확실성 중등도',
  effect_size_text = 'SMD -0.21 (TSH); SMD -0.96 (TPOAb); SMD -1.16 (MDA)',
  p_value_text = 'TSH: P<0.05; TPOAb: P<0.05; MDA: P<0.05',
  confidence_interval_text = 'TSH: -0.43 to -0.02; TPOAb: -1.36 to -0.56; MDA: -2.29 to -0.02'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38243784' LIMIT 1);

-- ── selenium (PMID 39698034) — 보충제 비교 네트워크 메타분석 ──
UPDATE evidence_outcomes SET
  outcome_name = '하시모토 갑상선염 보충제 비교 (셀레늄 우위)',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '셀레늄이 6개월 투여 시 TPOAb (SMD -2.44) 및 TgAb (SMD -2.76) 유의하게 감소. 비타민D 단독, 미오이노시톨 단독, 셀레늄+미오이노시톨 병용은 모두 유의한 감소 실패. 셀레늄을 HT 표준치료 보조로 권장. 10개 사례대조 연구',
  effect_size_text = 'SMD -2.44 (TPOAb); SMD -2.76 (TgAb)',
  p_value_text = 'TPOAb: P<0.05; TgAb: P<0.05',
  confidence_interval_text = 'TPOAb: -4.19 to -0.69; TgAb: -4.50 to -1.02'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39698034' LIMIT 1);

-- ── vitamin-a (PMID 35294044) — 소아 사망률·이환율 예방 (코크란) ──
UPDATE evidence_outcomes SET
  outcome_name = '비타민A 보충의 소아 사망률·이환율 예방',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '비타민A가 소아 전체 사망률 12% 감소 (RR 0.88, 고확실성 근거). 설사 사망 12% 감소 (RR 0.88, 고확실성). 홍역 사망에는 유의한 효과 없음 (RR 0.88, 저확실성). 47개 연구, ~1,223,856명 소아 대상',
  effect_size_text = 'RR 0.88 (전체 사망); RR 0.88 (설사 사망)',
  p_value_text = '전체 사망: P<0.05; 설사: P<0.05',
  confidence_interval_text = '전체: 0.83-0.93; 설사: 0.79-0.98'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35294044' LIMIT 1);

-- ── vitamin-a (PMID 8426449) — 비타민A 보충과 소아 사망 (1993) ──
UPDATE evidence_outcomes SET
  outcome_name = '비타민A 보충과 소아 사망률 감소',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '비타민A가 홍역 입원 환자 사망률 61% 감소 (OR 0.39, P=0.0004). 지역사회 기반 보충 시 전체 사망률 30% 감소 (OR 0.70, P=0.001). 개도국 아동에게 비타민A 보충 권장. 12개 대조 시험',
  effect_size_text = 'OR 0.39 (홍역 입원); OR 0.70 (지역사회)',
  p_value_text = '홍역: P=0.0004; 지역사회: P=0.001',
  confidence_interval_text = '홍역: 0.22-0.66; 지역사회: 0.56-0.87'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '8426449' LIMIT 1);

-- ── vitamin-e (PMID 15537682) — 고용량 비타민E 사망률 증가 ──
UPDATE evidence_outcomes SET
  outcome_name = '고용량 비타민E(≥400IU/일)의 전체 사망률 증가 위험',
  outcome_type = 'safety',
  effect_direction = 'negative',
  conclusion_summary = '고용량 비타민E(≥400 IU/일)가 전체 사망률 위험 증가 (+39/만 명, P=0.035). 150 IU/일 초과 시 용량-반응 관계로 위험 증가. 저용량은 유의한 효과 없음 (-16/만 명, NS). 11개 고용량 시험 중 9개에서 사망 위험 증가. 19개 시험, 135,967명',
  effect_size_text = '+39/만 명 (≥400 IU/일); -16/만 명 (저용량, NS)',
  p_value_text = '고용량: P=0.035; 저용량: P>0.2',
  confidence_interval_text = '고용량: 3-74/만 명; 저용량: -41 to 10/만 명'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '15537682' LIMIT 1);

-- ── vitamin-e (PMID 37698992) — 비타민E와 뇌졸중 ──
UPDATE evidence_outcomes SET
  outcome_name = '비타민E 보충과 뇌졸중 위험 (혼합 결과)',
  outcome_type = 'safety',
  effect_direction = 'neutral',
  conclusion_summary = '비타민E 단독은 뇌졸중 감소 효과 없음. 타 항산화제 병용 시 허혈성 뇌졸중 감소 (RR 0.91, P=0.02), 그러나 출혈성 뇌졸중 증가 (RR 1.22, P=0.04). 이익과 위해가 상쇄되어 뇌졸중 예방에 비추천. 16개 RCT, 용량 33-800 IU',
  effect_size_text = 'RR 0.91 (허혈성, 병용 시); RR 1.22 (출혈성, 병용 시)',
  p_value_text = '허혈성: P=0.02; 출혈성: P=0.04',
  confidence_interval_text = '허혈성: 0.84-0.99; 출혈성: 1.0-1.48'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '37698992' LIMIT 1);

-- ── curcumin (PMID 35935936) — 관절염 증상·염증 개선 ──
UPDATE evidence_outcomes SET
  outcome_name = '커큐민의 관절염 증상 및 염증 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '5종 관절염(강직척추염, 류마티스, 골관절염, JIA, 통풍) 환자 대상. 커큐민 120-1500mg, 4-36주 투여 시 염증 수치 및 통증 수준 개선. 안전성 확인. 그러나 RCT의 질과 수가 제한적. 29개 RCT, 2,396명',
  effect_size_text = '염증·통증 개선 (정량 통합 효과크기 미제공)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35935936' LIMIT 1);

-- ── curcumin (PMID 36804260) — 항산화·항염증 GRADE 평가 ──
UPDATE evidence_outcomes SET
  outcome_name = '커큐민/강황의 항산화·항염증 효과 (GRADE)',
  outcome_type = 'biomarker',
  effect_direction = 'positive',
  conclusion_summary = '커큐민이 CRP (WMD -0.58), TNF-α (WMD -3.48), IL-6 (WMD -1.31) 유의하게 감소. 총항산화능(TAC) 증가 (WMD 0.21), MDA 감소 (WMD -0.33), SOD 활성 증가 (WMD 20.51). IL-1β는 비유의. 66개 RCT',
  effect_size_text = 'WMD -0.58 mg/L (CRP); WMD -3.48 pg/mL (TNF-α); WMD -1.31 pg/mL (IL-6)',
  p_value_text = 'CRP/TNF-α/IL-6: P<0.05; IL-1β: NS',
  confidence_interval_text = 'CRP: -0.74 to -0.41; TNF-α: -4.38 to -2.58; IL-6: -1.58 to -0.67'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36804260' LIMIT 1);

-- ── melatonin (PMID 33417003) — 수면 질 개선 ──
UPDATE evidence_outcomes SET
  outcome_name = '멜라토닌의 수면 질(PSQI) 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '멜라토닌이 수면 질(PSQI) 유의하게 개선 (WMD -1.24, P<0.001). 호흡기 질환 (WMD -2.20), 대사 장애 (WMD -2.74), 수면 장애 (WMD -0.67)에서 효과적. 정신 질환·신경퇴행성 질환에서는 비유의. 23개 RCT, I²=80.7%',
  effect_size_text = 'WMD -1.24 (PSQI 총점); WMD -2.74 (대사 장애)',
  p_value_text = 'PSQI: P<0.001; 호흡기: P<0.001; 대사: P<0.001',
  confidence_interval_text = 'PSQI: -1.77 to -0.71; 대사: -3.48 to -2.00'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33417003' LIMIT 1);

-- ── melatonin (PMID 35843245) — 불면증 약물 네트워크 메타분석 ──
UPDATE evidence_outcomes SET
  outcome_name = '멜라토닌의 불면증 약물 대비 효과 (네트워크 메타분석)',
  outcome_type = 'efficacy',
  effect_direction = 'neutral',
  conclusion_summary = '30종 약물 네트워크 메타분석 (154개 RCT, 44,089명). 벤조디아제핀·에스조피클론·졸피뎀·조피클론이 멜라토닌보다 유의하게 효과적 (SMD 0.27-0.71). 멜라토닌은 위약 대비 소폭 효과. 장기 치료에서는 에스조피클론·렘보렉산트만 유효. 멜라토닌은 부작용 측면에서 유리',
  effect_size_text = 'SMD 0.36-0.83 (벤조·졸피뎀 등 vs 위약); 멜라토닌 < 이들 약물 (SMD 0.27-0.71 차이)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35843245' LIMIT 1);

-- ── red-ginseng (PMID 39474788) — 인삼 기억력 개선 (claim_id 이미 COGNITIVE_FUNCTION으로 교정) ──
UPDATE evidence_outcomes SET
  outcome_name = '인삼의 기억력 개선 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '인삼이 기억력 유의하게 개선 (SMD 0.19, P<0.05). 고용량 시 더 효과적 (SMD 0.33, P<0.05). 전반적 인지 기능 (SMD 0.06, NS), 주의력 (SMD 0.06, NS), 집행 기능 (SMD -0.03, NS)에는 유의한 효과 없음. 15개 RCT, 671명',
  effect_size_text = 'SMD 0.19 (기억력); SMD 0.33 (고용량 기억력)',
  p_value_text = '기억력: P<0.05; 인지/주의력/집행: NS',
  confidence_interval_text = '기억력: 0.02-0.36; 고용량: 0.04-0.61'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39474788' LIMIT 1);

-- ── red-ginseng (PMID 29624410) — 인삼 피로 개선 (claim_id 이미 ENERGY_METABOLISM으로 교정) ──
UPDATE evidence_outcomes SET
  outcome_name = '인삼(Panax)의 피로 개선 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '아시아·미국 인삼 모두 만성 질환 환자의 피로에 대한 잠재적 치료 효과. 부작용 위험 낮음. 10개 연구에서 중등도 유효성 근거. 방법론적으로 더 강력한 연구와 다양한 표본 필요. 체계적 문헌고찰',
  effect_size_text = '10개 연구에서 중등도(modest) 유효성 근거',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29624410' LIMIT 1);

-- ── MSM (PMID 29018060) — 관절 보조식품 체계적 고찰 ──
UPDATE evidence_outcomes SET
  outcome_name = 'MSM(메틸설포닐메탄) 등 관절 보조식품의 골관절염 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '20종 보조식품 69개 RCT 분석. MSM은 통증에 통계적으로 유의하나 임상적 중요성 불분명. 콜라겐 가수분해물·커큐민·보스웰리아 등 7종이 단기 통증에 대효과(ES>0.80). 글루코사민·콘드로이틴은 소효과 또는 비유효. 장기 효과는 보조식품 전반에서 미확인',
  effect_size_text = 'MSM: 통증 감소 유의하나 임상적 중요성 불확실; ES>0.80 (콜라겐·커큐민 등 7종, 단기)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '29018060' LIMIT 1);

-- ── MSM (PMID 35545381) — 잘못된 논문 (HIV PrEP, MSM 보조식품 아님) ──
UPDATE evidence_outcomes SET
  outcome_name = '(데이터 오류) HIV PrEP 연구 — MSM(메틸설포닐메탄)과 무관',
  outcome_type = 'efficacy',
  effect_direction = 'neutral',
  conclusion_summary = '주의: 이 논문은 HIV 경구 노출 전 예방(PrEP)에 대한 메타분석으로, MSM(메틸설포닐메탄) 보조식품과 무관. 검색 시 MSM(men who have sex with men) 약어와 혼동된 것으로 추정. 데이터 교체 필요',
  effect_size_text = '해당 없음 (논문 주제 불일치)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35545381' LIMIT 1);

-- ── garcinia (PMID 38151892) — 가르시니아 지질 프로필 ──
UPDATE evidence_outcomes SET
  outcome_name = '가르시니아 캄보지아(HCA)의 혈중 지질 개선',
  outcome_type = 'biomarker',
  effect_direction = 'positive',
  conclusion_summary = '가르시니아가 총콜레스테롤 (WMD -6.76 mg/dL, P=0.032), 중성지방 (WMD -24.21 mg/dL, P<0.001) 유의하게 감소. HDL-C 증가 (WMD +2.95 mg/dL, P<0.001). LDL-C는 비유의. 8주 이상 투여 시 효과 뚜렷. 14개 시험, 623명',
  effect_size_text = 'WMD -6.76 mg/dL (TC); WMD -24.21 mg/dL (TG); WMD +2.95 (HDL)',
  p_value_text = 'TC: P=0.032; TG: P<0.001; HDL: P<0.001; LDL: NS',
  confidence_interval_text = 'TC: -12.39 to -0.59; TG: -37.84 to -10.58; HDL: 2.01-3.89'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38151892' LIMIT 1);

-- ── garcinia (PMID 38876392) — 가르시니아 렙틴 ──
UPDATE evidence_outcomes SET
  outcome_name = '가르시니아 캄보지아의 혈청 렙틴 감소',
  outcome_type = 'biomarker',
  effect_direction = 'positive',
  conclusion_summary = '가르시니아가 혈청 렙틴 유의하게 감소 (WMD -5.01 ng/mL, P=0.02). 50명 이상 표본에서 더 효과적 (WMD -3.63, P<0.001). 30세 이상에서 효과 뚜렷 (WMD -7.43, P<0.001). 이질성 높음 (I²=93.5%). 8개 시험, 330명',
  effect_size_text = 'WMD -5.01 ng/mL (렙틴)',
  p_value_text = 'P=0.02; ≥50명: P<0.001; ≥30세: P<0.001',
  confidence_interval_text = '-9.22 to -0.80; ≥50명: -5.51 to -1.76'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '38876392' LIMIT 1);

-- ── collagen (PMID 33742704) — 콜라겐 피부 노화 개선 ──
UPDATE evidence_outcomes SET
  outcome_name = '가수분해 콜라겐의 피부 노화 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '가수분해 콜라겐 경구 보충이 위약 대비 피부 수분, 탄력, 주름 유의하게 개선. 90일 이상 섭취 시 피부 노화 감소에 효과적. 19개 RCT, 1,125명 (95% 여성, 20-70세)',
  effect_size_text = '피부 수분·탄력·주름 유의 개선 (통합 효과크기 유의)',
  p_value_text = '수분/탄력/주름: P<0.05',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '33742704' LIMIT 1);

-- ── collagen (PMID 34491424) — 콜라겐 관절·체성분·근회복 ──
UPDATE evidence_outcomes SET
  outcome_name = '콜라겐 펩타이드의 관절 통증 감소 및 체성분 개선',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '콜라겐 펩타이드 보충이 관절 기능 개선·관절 통증 감소에 가장 유익. 체성분·근력 회복에도 일부 개선. 콜라겐 합성율 15g/일에서 상승, 그러나 동등 질소 고품질 단백질 대비 근단백질 합성(MPS) 차이는 미미. 15개 RCT, 주로 운동선수·노인 대상',
  effect_size_text = '관절 기능·통증: 유의 개선; MPS: 고품질 단백질 대비 NS',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '34491424' LIMIT 1);

-- ── creatine (PMID 31375416) — 크레아틴 신장 안전성 ──
UPDATE evidence_outcomes SET
  outcome_name = '크레아틴 보충의 신장 기능 안전성',
  outcome_type = 'safety',
  effect_direction = 'positive',
  conclusion_summary = '크레아틴 보충이 혈청 크레아티닌 (SMD 0.48, P=0.001) 및 혈장 요소 (SMD 1.10, P=0.004) 수치를 유의하게 변화시키지 않음. 연구된 용량·기간에서 신장 손상을 유발하지 않음. 15개 연구(6개 메타분석 포함)',
  effect_size_text = 'SMD 0.48 (크레아티닌, NS 수준); SMD 1.10 (요소, NS 수준)',
  p_value_text = '크레아티닌: P=0.001; 요소: P=0.004 (정상 범위 내)',
  confidence_interval_text = '크레아티닌: 0.24-0.73; 요소: 0.34-1.85'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '31375416' LIMIT 1);

-- ── creatine (PMID 35984306) — 크레아틴 기억력 개선 (claim_id 이미 COGNITIVE_FUNCTION으로 교정) ──
UPDATE evidence_outcomes SET
  outcome_name = '크레아틴 보충의 기억력 개선 효과',
  outcome_type = 'efficacy',
  effect_direction = 'positive',
  conclusion_summary = '크레아틴 보충이 기억력 유의하게 개선 (SMD 0.29, P=0.02). 고령자(66-76세)에서 대효과 (SMD 0.88, P=0.009), 젊은 층(11-31세)에서는 효과 없음 (SMD 0.03, NS). 용량 2.2-20g/일, 기간 5일-24주. 8개 RCT',
  effect_size_text = 'SMD 0.29 (전체 기억력); SMD 0.88 (고령자)',
  p_value_text = '전체: P=0.02; 고령자: P=0.009; 젊은 층: P=0.72',
  confidence_interval_text = '전체: 0.04-0.53; 고령자: 0.22-1.55; 젊은 층: -0.14 to 0.20'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '35984306' LIMIT 1);

-- ── folate (PMID 36321557) — 누락 필드 보강 ──
UPDATE evidence_outcomes SET
  effect_size_text = '엽산 400μg/일 보충 권고 유지 (코크란 고찰)',
  p_value_text = '-',
  confidence_interval_text = '-'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '36321557' LIMIT 1)
  AND effect_size_text IS NULL;

-- ── folate (PMID 39145520) — 누락 필드 보강 ──
UPDATE evidence_outcomes SET
  p_value_text = '빈혈: P<0.05; 저체중아: P<0.05'
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39145520' LIMIT 1)
  AND p_value_text IS NULL;


-- ============================================================================
-- SECTION 3: evidence_studies 메타데이터 보강 (sample_size, population, duration)
-- ============================================================================

-- iron
UPDATE evidence_studies SET
  sample_size = 8829,
  population_text = '소아·청소년 IDA 환자 (28개 연구, 16개국)',
  duration_text = '≥30일 (최적: <3개월 또는 >6개월)'
WHERE pmid = '39951396';

-- calcium
UPDATE evidence_studies SET
  population_text = '폐경 후 여성',
  duration_text = '연구별 상이'
WHERE pmid = '33237064';

UPDATE evidence_studies SET
  sample_size = 30970,
  population_text = '지역사회·시설 거주 중·고령 성인 (8개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '26510847';

-- probiotics
UPDATE evidence_studies SET
  population_text = '지역사회·임상/의료·정신과 환자 (34개 대조 시험)',
  duration_text = '연구별 상이'
WHERE pmid = '31004628';

UPDATE evidence_studies SET
  sample_size = 1891,
  population_text = '다양한 질환 성인 (26개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '37168869';

-- lutein
UPDATE evidence_studies SET
  sample_size = 11952,
  population_text = 'AMD 환자 65-75세 (26개 연구, 56% 여성)',
  duration_text = '약 1년 (AREDS/AREDS2 포함)'
WHERE pmid = '37702300';

UPDATE evidence_studies SET
  population_text = '다양한 질환 성인 (26개 시험, 35개 효과크기)',
  duration_text = '연구별 상이'
WHERE pmid = '33998846';

-- coq10
UPDATE evidence_studies SET
  sample_size = 2617,
  population_text = '난소 노화 여성 (20개 RCT)',
  duration_text = '최적: IVF 전 3개월'
WHERE pmid = '39019217';

UPDATE evidence_studies SET
  sample_size = 1529,
  population_text = 'DOR(난소예비력저하) 여성 IVF/ICSI (6개 RCT)',
  duration_text = 'IVF/ICSI 주기 전'
WHERE pmid = '39129455';

-- milk-thistle
UPDATE evidence_studies SET
  sample_size = 2375,
  population_text = 'NAFLD/NASH 환자 (26개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '38579127';

UPDATE evidence_studies SET
  population_text = '간 질환 환자 (서술적 고찰)',
  duration_text = '연구별 상이'
WHERE pmid = '32065376';

-- glucosamine
UPDATE evidence_studies SET
  population_text = '골관절염 개·고양이 (57편, 72개 시험)',
  duration_text = '연구별 상이'
WHERE pmid = '36142319';

UPDATE evidence_studies SET
  sample_size = 3793,
  population_text = '무릎 골관절염 환자 (8개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '35024906';

-- biotin
UPDATE evidence_studies SET
  sample_size = 82,
  population_text = '입원 주요우울장애 환자 (RCT)',
  duration_text = '28일'
WHERE pmid = '33171595';

UPDATE evidence_studies SET
  population_text = '남성 탈모 환자 (교차 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '38688776';

-- selenium
UPDATE evidence_studies SET
  sample_size = 2358,
  population_text = '하시모토 갑상선염 환자 (35개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '38243784';

UPDATE evidence_studies SET
  population_text = '하시모토 갑상선염 갑상선기능정상 환자 (10개 연구)',
  duration_text = '6개월'
WHERE pmid = '39698034';

-- vitamin-a
UPDATE evidence_studies SET
  sample_size = 1223856,
  population_text = '6개월-5세 소아 (47개 연구, 19개국)',
  duration_text = '약 1년'
WHERE pmid = '35294044';

UPDATE evidence_studies SET
  population_text = '개도국 소아 (12개 대조 시험)',
  duration_text = '연구별 상이'
WHERE pmid = '8426449';

-- vitamin-e
UPDATE evidence_studies SET
  sample_size = 135967,
  population_text = '만성 질환 성인 (19개 RCT)',
  duration_text = '연구별 상이 (중앙값 400 IU/일)'
WHERE pmid = '15537682';

UPDATE evidence_studies SET
  population_text = '심혈관 위험도 다양한 성인 (16개 RCT)',
  duration_text = '6개월-9.4년'
WHERE pmid = '37698992';

-- curcumin
UPDATE evidence_studies SET
  sample_size = 2396,
  population_text = '5종 관절염 환자 (29개 RCT)',
  duration_text = '4-36주'
WHERE pmid = '35935936';

UPDATE evidence_studies SET
  population_text = '다양한 질환 성인 (66개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '36804260';

-- melatonin
UPDATE evidence_studies SET
  population_text = '다양한 질환 성인 (23개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '33417003';

UPDATE evidence_studies SET
  sample_size = 44089,
  population_text = '불면증 장애 성인 ≥18세 (154개 RCT, 30종 약물)',
  duration_text = '급성 및 장기 치료'
WHERE pmid = '35843245';

-- red-ginseng
UPDATE evidence_studies SET
  sample_size = 671,
  population_text = '건강인·인지장애·조현병·알츠하이머 환자 (15개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '39474788';

UPDATE evidence_studies SET
  population_text = '만성 질환 피로 환자 (10개 연구)',
  duration_text = '연구별 상이'
WHERE pmid = '29624410';

-- MSM
UPDATE evidence_studies SET
  population_text = '손·고관절·무릎 골관절염 환자 (69개 RCT, 20종 보조식품)',
  duration_text = '단기·중기·장기'
WHERE pmid = '29018060';

UPDATE evidence_studies SET
  population_text = '(데이터 오류: HIV PrEP 연구 — MSM 보조식품 무관)',
  duration_text = '-'
WHERE pmid = '35545381';

-- garcinia
UPDATE evidence_studies SET
  sample_size = 623,
  population_text = '성인 (14개 시험)',
  duration_text = '8주 이상 시 효과 뚜렷'
WHERE pmid = '38151892';

UPDATE evidence_studies SET
  sample_size = 330,
  population_text = '성인 (8개 시험)',
  duration_text = '연구별 상이'
WHERE pmid = '38876392';

-- collagen
UPDATE evidence_studies SET
  sample_size = 1125,
  population_text = '20-70세 성인 (95% 여성, 19개 RCT)',
  duration_text = '90일 이상 권장'
WHERE pmid = '33742704';

UPDATE evidence_studies SET
  population_text = '운동선수·노인·폐경전 여성 (15개 RCT)',
  duration_text = '연구별 상이'
WHERE pmid = '34491424';

-- creatine
UPDATE evidence_studies SET
  population_text = '건강 성인 (15개 연구, 6개 메타분석)',
  duration_text = '연구별 상이'
WHERE pmid = '31375416';

UPDATE evidence_studies SET
  population_text = '건강인 11-76세 (8개 RCT)',
  duration_text = '5일-24주'
WHERE pmid = '35984306';


-- ============================================================================
-- SECTION 4: 누락된 ingredient_claims 추가 (논문 기반 신규 매핑)
-- ============================================================================

-- red-ginseng → 인지 기능 (PMID 39474788 기반)
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression)
VALUES (
  (SELECT id FROM ingredients WHERE slug='red-ginseng'),
  (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
  'C', '인삼이 기억력 소폭 개선 (SMD 0.19); 전반적 인지·주의력에는 효과 제한적', false, NULL, NULL
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- creatine → 인지 기능 (PMID 35984306 기반)
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression)
VALUES (
  (SELECT id FROM ingredients WHERE slug='creatine'),
  (SELECT id FROM claims WHERE claim_code='COGNITIVE_FUNCTION'),
  'B', '크레아틴 보충이 기억력 개선 (SMD 0.29); 특히 고령자(66-76세)에서 대효과 (SMD 0.88)', false, NULL, NULL
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;


-- ============================================================================
-- SECTION 5: 검증 쿼리
-- ============================================================================

SELECT '=== Phase 2 보강 결과 ===' AS section;

SELECT 'outcomes_total' AS metric, count(*) AS value FROM evidence_outcomes
UNION ALL
SELECT 'outcomes_with_claim', count(*) FROM evidence_outcomes WHERE claim_id IS NOT NULL
UNION ALL
SELECT 'outcomes_without_claim', count(*) FROM evidence_outcomes WHERE claim_id IS NULL
UNION ALL
SELECT 'outcomes_with_effect_size', count(*) FROM evidence_outcomes WHERE effect_size_text IS NOT NULL
UNION ALL
SELECT 'outcomes_with_conclusion', count(*) FROM evidence_outcomes WHERE conclusion_summary IS NOT NULL
UNION ALL
SELECT 'studies_with_sample_size', count(*) FROM evidence_studies WHERE sample_size IS NOT NULL
UNION ALL
SELECT 'studies_with_population', count(*) FROM evidence_studies WHERE population_text IS NOT NULL;

-- 원료별 연결 현황
SELECT
  i.canonical_name_ko AS ingredient,
  count(DISTINCT ic.claim_id) AS claim_count,
  count(DISTINCT eo.id) AS outcome_count,
  count(DISTINCT CASE WHEN eo.effect_size_text IS NOT NULL THEN eo.id END) AS outcomes_with_data,
  string_agg(DISTINCT c.claim_code, ', ' ORDER BY c.claim_code) AS claims
FROM ingredients i
LEFT JOIN ingredient_claims ic ON ic.ingredient_id = i.id
LEFT JOIN claims c ON c.id = ic.claim_id
LEFT JOIN evidence_studies es ON es.ingredient_id = i.id
LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
WHERE i.is_active = true
GROUP BY i.id, i.canonical_name_ko
ORDER BY claim_count DESC;

-- 데이터 오류 플래그
SELECT '=== 데이터 오류 확인 ===' AS section;
SELECT es.pmid, i.slug AS ingredient, eo.outcome_name
FROM evidence_outcomes eo
JOIN evidence_studies es ON es.id = eo.evidence_study_id
JOIN ingredients i ON i.id = es.ingredient_id
WHERE eo.outcome_name LIKE '%(데이터 오류)%';
