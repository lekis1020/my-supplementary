-- ============================================================================
-- 근거 매핑 교정 — 017_fix_evidence_mappings.sql
-- Version: 1.0.0
-- 생성일: 2026-03-17
-- 목적:
--   1. 잘못된 claim_id 매핑 교정 (CoQ10 생식건강 논문 → 심혈관으로 잘못 매핑)
--   2. 데이터 오류 논문 제외 (MSM PMID 35545381 = HIV PrEP 논문)
--   3. 신규 claim 추가 (REPRODUCTIVE_HEALTH)
--   4. 누락된 Grade A/B 핵심 효능 근거 논문 추가
-- 주의: 015_enrich_evidence_phase2.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- SECTION 1: 신규 claim 추가
-- ============================================================================

INSERT INTO claims (claim_code, claim_name_ko, claim_name_en, claim_category, claim_scope, description) VALUES
('REPRODUCTIVE_HEALTH', '생식 건강에 도움', 'Reproductive Health', 'endocrine', 'studied', '난소 기능, 생식능 등 생식 건강 관련 연구')
ON CONFLICT (claim_code) DO NOTHING;

-- ============================================================================
-- SECTION 2: CoQ10 논문 claim_id 교정 (심혈관 → 생식 건강)
-- ============================================================================

-- CoQ10 PMID 39019217: 난소 노화 여성 생식능 연구인데 CARDIOVASCULAR로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'REPRODUCTIVE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39019217' LIMIT 1);

-- CoQ10 PMID 39129455: IVF/ICSI 결과 연구인데 CARDIOVASCULAR로 잘못 매핑
UPDATE evidence_outcomes SET
  claim_id = (SELECT id FROM claims WHERE claim_code = 'REPRODUCTIVE_HEALTH')
WHERE evidence_study_id = (SELECT id FROM evidence_studies WHERE pmid = '39129455' LIMIT 1);

-- CoQ10 ingredient_claims: 생식 건강 연결 추가
INSERT INTO ingredient_claims (ingredient_id, claim_id, evidence_grade, evidence_summary, is_regulator_approved, approval_country_code, allowed_expression)
VALUES (
  (SELECT id FROM ingredients WHERE slug='coq10'),
  (SELECT id FROM claims WHERE claim_code='REPRODUCTIVE_HEALTH'),
  'B', 'CoQ10이 DOR 여성의 임상 임신율 84% 증가 (OR 1.84), 채취 난자 수 증가. 2개 메타분석', false, NULL, NULL
) ON CONFLICT (ingredient_id, claim_id, approval_country_code) DO NOTHING;

-- ============================================================================
-- SECTION 3: MSM 데이터 오류 논문 제외
-- ============================================================================

-- PMID 35545381은 HIV PrEP 논문으로 MSM(메틸설포닐메탄) 보충제와 무관
UPDATE evidence_studies SET
  screening_status = 'excluded',
  included_in_summary = false
WHERE pmid = '35545381';

-- ============================================================================
-- SECTION 4: 검증 쿼리
-- ============================================================================

SELECT '=== 매핑 교정 결과 ===' AS section;

-- CoQ10 매핑 확인
SELECT 'coq10_outcomes' AS check_item,
  es.pmid, eo.outcome_name, c.claim_code
FROM evidence_outcomes eo
JOIN evidence_studies es ON es.id = eo.evidence_study_id
JOIN ingredients i ON i.id = es.ingredient_id
LEFT JOIN claims c ON c.id = eo.claim_id
WHERE i.slug = 'coq10';

-- MSM 제외 확인
SELECT 'msm_excluded' AS check_item,
  es.pmid, es.screening_status, es.included_in_summary
FROM evidence_studies es
WHERE es.pmid = '35545381';

-- 전체 포함 논문 수
SELECT 'included_studies' AS check_item, count(*) AS cnt
FROM evidence_studies WHERE included_in_summary = true;
