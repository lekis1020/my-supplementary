-- ============================================================================
-- Claim normalization extension
-- Adds canonical claim structure and preserves raw claim expressions
-- ============================================================================

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
