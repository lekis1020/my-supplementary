-- ============================================================================
-- Claim normalization extension
-- Adds canonical claim structure and preserves raw claim expressions
-- ============================================================================

-- 0. Code table for predicate type
INSERT INTO code_tables (table_code, table_name_ko, table_name_en, description)
VALUES (
  'claim_predicate_type',
  '기능성 서술 유형',
  'Claim Predicate Type',
  'supports, required_for, risk_reduction 등 기능성 문장의 서술 유형'
)
ON CONFLICT (table_code) DO NOTHING;

INSERT INTO code_values (code_table_id, code, label_ko, label_en, sort_order)
SELECT ct.id, v.code, v.label_ko, v.label_en, v.sort_order
FROM code_tables ct,
(VALUES
  ('supports', '도움 계열', 'Support', 1),
  ('required_for', '필요 계열', 'Required For', 2),
  ('risk_reduction', '위험 감소', 'Risk Reduction', 3)
) AS v(code, label_ko, label_en, sort_order)
WHERE ct.table_code = 'claim_predicate_type'
ON CONFLICT (code_table_id, code) DO NOTHING;

-- 1. claims 확장
ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS claim_key VARCHAR(150),
  ADD COLUMN IF NOT EXISTS canonical_claim_ko VARCHAR(255),
  ADD COLUMN IF NOT EXISTS canonical_claim_en VARCHAR(255),
  ADD COLUMN IF NOT EXISTS claim_subject_ko VARCHAR(255),
  ADD COLUMN IF NOT EXISTS claim_subject_en VARCHAR(255),
  ADD COLUMN IF NOT EXISTS predicate_type VARCHAR(50),
  ADD COLUMN IF NOT EXISTS source_language VARCHAR(10) NOT NULL DEFAULT 'ko';

CREATE UNIQUE INDEX IF NOT EXISTS uq_claims_claim_key
  ON claims (claim_key)
  WHERE claim_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_claims_claim_key
  ON claims (claim_key);

CREATE INDEX IF NOT EXISTS idx_claims_predicate_type
  ON claims (predicate_type);

CREATE INDEX IF NOT EXISTS idx_claims_claim_subject_ko
  ON claims (claim_subject_ko);

COMMENT ON COLUMN claims.claim_key IS '언어 중립 canonical key. 예: skin_moisturizing_support';
COMMENT ON COLUMN claims.canonical_claim_ko IS '정규화된 국문 문구. 예: 피부 보습에 도움을 줄 수 있음';
COMMENT ON COLUMN claims.canonical_claim_en IS '정규화된 영문 문구. 예: May help support skin hydration';
COMMENT ON COLUMN claims.claim_subject_ko IS '기능성 주제. 예: 피부 보습';
COMMENT ON COLUMN claims.claim_subject_en IS '기능성 주제 영문. 예: skin hydration';
COMMENT ON COLUMN claims.predicate_type IS 'supports, required_for, risk_reduction 중 하나';
COMMENT ON COLUMN claims.source_language IS 'canonical 생성 기준이 된 주언어';

-- 기존 seeded claims를 하위호환 가능하게 초기화
UPDATE claims
SET
  claim_key = COALESCE(claim_key, claim_code),
  canonical_claim_ko = COALESCE(canonical_claim_ko, claim_name_ko),
  canonical_claim_en = COALESCE(canonical_claim_en, claim_name_en),
  predicate_type = COALESCE(predicate_type, 'supports'),
  source_language = COALESCE(source_language, 'ko')
WHERE claim_key IS NULL
   OR canonical_claim_ko IS NULL
   OR predicate_type IS NULL;

-- 2. ingredient_claims 확장
ALTER TABLE ingredient_claims
  ADD COLUMN IF NOT EXISTS raw_claim_text TEXT,
  ADD COLUMN IF NOT EXISTS raw_claim_language VARCHAR(10) NOT NULL DEFAULT 'ko',
  ADD COLUMN IF NOT EXISTS recognition_no VARCHAR(100),
  ADD COLUMN IF NOT EXISTS evidence_grade_text VARCHAR(100),
  ADD COLUMN IF NOT EXISTS claim_scope_note TEXT,
  ADD COLUMN IF NOT EXISTS source_dataset VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_ingredient_claims_recognition_no
  ON ingredient_claims (recognition_no);

CREATE INDEX IF NOT EXISTS idx_ingredient_claims_source_dataset
  ON ingredient_claims (source_dataset);

COMMENT ON COLUMN ingredient_claims.raw_claim_text IS '원문 claim 문구. 정제 전 문자열을 그대로 보존';
COMMENT ON COLUMN ingredient_claims.raw_claim_language IS '원문 claim 언어. ko/en 등';
COMMENT ON COLUMN ingredient_claims.recognition_no IS '기능성원료 인정번호 또는 제품/공전 기반 식별번호';
COMMENT ON COLUMN ingredient_claims.evidence_grade_text IS '원문 등급 표기. 예: 생리활성기능 2등급';
COMMENT ON COLUMN ingredient_claims.claim_scope_note IS '번호, 각주, 문구 범위 등 부가 메타';
COMMENT ON COLUMN ingredient_claims.source_dataset IS 'foodsafety-i2710, foodsafety-i0040 등 원 출처 데이터셋';
