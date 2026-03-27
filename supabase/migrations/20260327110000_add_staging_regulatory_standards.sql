-- ============================================================================
-- Add staging table for KR regulatory standards (I0960)
-- ============================================================================

CREATE TABLE IF NOT EXISTS staging_regulatory_standards_kr (
    id BIGSERIAL PRIMARY KEY,

    source_dataset VARCHAR(100) NOT NULL,
    product_code VARCHAR(100),
    test_name_ko VARCHAR(255) NOT NULL,
    min_value VARCHAR(100),
    max_value VARCHAR(100),
    unit VARCHAR(50),
    valid_start_date VARCHAR(20),
    valid_end_date VARCHAR(20),
    source_text TEXT,
    injury_flag VARCHAR(20),

    import_batch VARCHAR(100),
    imported_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_staging_regulatory_standards_kr_row
        UNIQUE (source_dataset, product_code, test_name_ko, valid_start_date, valid_end_date)
);

CREATE INDEX IF NOT EXISTS idx_staging_regulatory_standards_kr_product_code
    ON staging_regulatory_standards_kr (product_code);

CREATE INDEX IF NOT EXISTS idx_staging_regulatory_standards_kr_test_name
    ON staging_regulatory_standards_kr (test_name_ko);

COMMENT ON TABLE staging_regulatory_standards_kr IS
'KR government regulatory standards staging for I0960 (e.g., vitamin content spec rows).';
