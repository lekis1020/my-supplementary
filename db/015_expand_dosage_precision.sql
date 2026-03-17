-- ============================================================================
-- Expand dosage precision for large CFU-scale values
-- ============================================================================

ALTER TABLE dosage_guidelines
  ALTER COLUMN dose_min TYPE NUMERIC(18,4),
  ALTER COLUMN dose_max TYPE NUMERIC(18,4);
