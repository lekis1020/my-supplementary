-- 023_evidence_gap_views.sql
--
-- 목적:
--   원료 효능 근거 공백(논문/출처/클레임 매핑 미충족)을 한 번에 조회하는 뷰 제공
--
-- 사용 예시:
--   SELECT * FROM ingredient_evidence_gaps ORDER BY gap_level, risk_score DESC;

BEGIN;

DROP VIEW IF EXISTS ingredient_evidence_gaps;
DROP VIEW IF EXISTS ingredient_evidence_coverage;

CREATE VIEW ingredient_evidence_coverage AS
WITH claim_summary AS (
  SELECT
    ic.ingredient_id,
    COUNT(*)::int AS claim_count,
    COALESCE(
      jsonb_agg(DISTINCT c.claim_name_ko) FILTER (WHERE c.claim_name_ko IS NOT NULL),
      '[]'::jsonb
    ) AS claim_names
  FROM ingredient_claims ic
  LEFT JOIN claims c ON c.id = ic.claim_id
  GROUP BY ic.ingredient_id
),
evidence_summary AS (
  SELECT
    es.ingredient_id,
    COUNT(DISTINCT es.id) FILTER (WHERE es.included_in_summary = TRUE)::int AS summary_study_count,
    COUNT(DISTINCT eo.claim_id) FILTER (
      WHERE es.included_in_summary = TRUE AND eo.claim_id IS NOT NULL
    )::int AS covered_claim_count
  FROM evidence_studies es
  LEFT JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
  GROUP BY es.ingredient_id
),
missing_claims AS (
  SELECT
    ic.ingredient_id,
    COUNT(*)::int AS missing_claim_count,
    COALESCE(
      jsonb_agg(DISTINCT c.claim_name_ko) FILTER (WHERE c.claim_name_ko IS NOT NULL),
      '[]'::jsonb
    ) AS missing_claim_names
  FROM ingredient_claims ic
  LEFT JOIN claims c ON c.id = ic.claim_id
  WHERE NOT EXISTS (
    SELECT 1
    FROM evidence_studies es
    JOIN evidence_outcomes eo ON eo.evidence_study_id = es.id
    WHERE es.ingredient_id = ic.ingredient_id
      AND es.included_in_summary = TRUE
      AND eo.claim_id = ic.claim_id
  )
  GROUP BY ic.ingredient_id
),
ingredient_source_summary AS (
  SELECT
    entity_id AS ingredient_id,
    COUNT(*)::int AS ingredient_source_count
  FROM source_links
  WHERE entity_type = 'ingredient'
  GROUP BY entity_id
),
evidence_source_summary AS (
  SELECT
    es.ingredient_id,
    COUNT(DISTINCT sl.id)::int AS evidence_source_count
  FROM evidence_studies es
  LEFT JOIN source_links sl
    ON sl.entity_type = 'evidence_study'
    AND sl.entity_id = es.id
  WHERE es.included_in_summary = TRUE
  GROUP BY es.ingredient_id
)
SELECT
  i.id,
  i.canonical_name_ko,
  i.slug,
  i.ingredient_type,
  COALESCE(cs.claim_count, 0) AS claim_count,
  COALESCE(es.summary_study_count, 0) AS summary_study_count,
  COALESCE(es.covered_claim_count, 0) AS covered_claim_count,
  COALESCE(mc.missing_claim_count, 0) AS missing_claim_count,
  COALESCE(iss.ingredient_source_count, 0) AS ingredient_source_count,
  COALESCE(ess.evidence_source_count, 0) AS evidence_source_count,
  COALESCE(cs.claim_names, '[]'::jsonb) AS claim_names,
  COALESCE(mc.missing_claim_names, '[]'::jsonb) AS missing_claim_names,
  CASE
    WHEN COALESCE(cs.claim_count, 0) > 0 AND COALESCE(es.summary_study_count, 0) = 0 THEN 'critical'
    WHEN COALESCE(mc.missing_claim_count, 0) > 0 THEN 'high'
    WHEN COALESCE(iss.ingredient_source_count, 0) = 0 OR COALESCE(ess.evidence_source_count, 0) = 0 THEN 'medium'
    ELSE 'low'
  END AS gap_level,
  (
    CASE WHEN COALESCE(es.summary_study_count, 0) = 0 THEN 100 ELSE 0 END
    + COALESCE(mc.missing_claim_count, 0) * 10
    + CASE WHEN COALESCE(iss.ingredient_source_count, 0) = 0 THEN 5 ELSE 0 END
    + CASE WHEN COALESCE(ess.evidence_source_count, 0) = 0 THEN 5 ELSE 0 END
  )::int AS risk_score
FROM ingredients i
LEFT JOIN claim_summary cs ON cs.ingredient_id = i.id
LEFT JOIN evidence_summary es ON es.ingredient_id = i.id
LEFT JOIN missing_claims mc ON mc.ingredient_id = i.id
LEFT JOIN ingredient_source_summary iss ON iss.ingredient_id = i.id
LEFT JOIN evidence_source_summary ess ON ess.ingredient_id = i.id
WHERE i.is_published = TRUE;

CREATE VIEW ingredient_evidence_gaps AS
SELECT *
FROM ingredient_evidence_coverage
WHERE claim_count > 0
  AND (
    summary_study_count = 0
    OR missing_claim_count > 0
    OR ingredient_source_count = 0
    OR evidence_source_count = 0
  );

COMMIT;
