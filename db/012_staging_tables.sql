-- ============================================================================
-- KR 정부 데이터 staging 테이블
-- 목적:
--   - tmp/kr-gov-clean/staging/*.jsonl 적재용 중간 테이블
--   - 본 테이블(products, ingredients, product_ingredients)와 분리
--   - 정제/검수/재매핑 후 본 테이블로 promote
-- 작성일: 2026-03-16
-- 전제: 001_schema.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- 1. 제품 staging
-- ============================================================================

CREATE TABLE IF NOT EXISTS staging_products_kr (
    id BIGSERIAL PRIMARY KEY,

    report_no VARCHAR(255) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255),
    manufacturer_name VARCHAR(255),
    distributor_name VARCHAR(255),
    country_code VARCHAR(10) DEFAULT 'KR',
    product_type VARCHAR(100),
    approval_or_report_no VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    product_name_source VARCHAR(100),
    product_name_resolution VARCHAR(100),
    is_ingredient_like_product BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,

    source_datasets JSONB NOT NULL DEFAULT '[]'::jsonb,
    functionality_items JSONB NOT NULL DEFAULT '[]'::jsonb,

    directions_text TEXT,
    warning_text TEXT,
    storage_text TEXT,
    standards_text TEXT,
    shape_name VARCHAR(255),
    formulation_method TEXT,
    packaging_materials_text TEXT,
    shelf_life_text VARCHAR(255),

    report_date VARCHAR(20),
    last_updated_at VARCHAR(20),
    registration_date VARCHAR(20),

    raw_primary_material_name TEXT,
    raw_individual_material_name TEXT,

    staging_ingredient_rows INTEGER NOT NULL DEFAULT 0,
    staging_canonical_ingredient_count INTEGER NOT NULL DEFAULT 0,
    active_ingredient_rows INTEGER NOT NULL DEFAULT 0,
    supporting_ingredient_rows INTEGER NOT NULL DEFAULT 0,
    capsule_ingredient_rows INTEGER NOT NULL DEFAULT 0,
    max_ingredient_confidence NUMERIC(5,2),

    import_batch VARCHAR(100),
    imported_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_staging_products_kr_report_no UNIQUE (report_no)
);

CREATE INDEX IF NOT EXISTS idx_staging_products_kr_name
    ON staging_products_kr (product_name);

CREATE INDEX IF NOT EXISTS idx_staging_products_kr_manufacturer
    ON staging_products_kr (manufacturer_name);

CREATE INDEX IF NOT EXISTS idx_staging_products_kr_status
    ON staging_products_kr (status);


-- ============================================================================
-- 2. 원료 staging
-- ============================================================================

CREATE TABLE IF NOT EXISTS staging_ingredients_kr (
    id BIGSERIAL PRIMARY KEY,

    canonical_name_ko VARCHAR(255) NOT NULL,
    canonical_name_en VARCHAR(255),
    display_name VARCHAR(255),
    scientific_name VARCHAR(255),
    slug VARCHAR(255),
    ingredient_type VARCHAR(50),
    origin_type VARCHAR(50),

    form_description TEXT,
    standardization_info TEXT,
    description TEXT,

    aliases JSONB NOT NULL DEFAULT '[]'::jsonb,
    source_datasets JSONB NOT NULL DEFAULT '[]'::jsonb,
    functionality_items JSONB NOT NULL DEFAULT '[]'::jsonb,
    warning_texts JSONB NOT NULL DEFAULT '[]'::jsonb,
    dosage_guidelines JSONB NOT NULL DEFAULT '[]'::jsonb,
    recognition_nos JSONB NOT NULL DEFAULT '[]'::jsonb,
    health_item_group_codes JSONB NOT NULL DEFAULT '[]'::jsonb,
    health_item_group_names JSONB NOT NULL DEFAULT '[]'::jsonb,

    mapped_product_count INTEGER NOT NULL DEFAULT 0,
    mapped_mention_rows INTEGER NOT NULL DEFAULT 0,
    active_mention_rows INTEGER NOT NULL DEFAULT 0,
    supporting_mention_rows INTEGER NOT NULL DEFAULT 0,
    capsule_mention_rows INTEGER NOT NULL DEFAULT 0,
    max_mapped_confidence NUMERIC(5,2),
    source_record_count INTEGER NOT NULL DEFAULT 0,

    import_batch VARCHAR(100),
    imported_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_staging_ingredients_kr_name UNIQUE (canonical_name_ko)
);

CREATE INDEX IF NOT EXISTS idx_staging_ingredients_kr_slug
    ON staging_ingredients_kr (slug);

CREATE INDEX IF NOT EXISTS idx_staging_ingredients_kr_type
    ON staging_ingredients_kr (ingredient_type);

CREATE INDEX IF NOT EXISTS idx_staging_ingredients_kr_mapped_product_count
    ON staging_ingredients_kr (mapped_product_count DESC);


-- ============================================================================
-- 3. 제품-원료 연결 staging
-- ============================================================================

CREATE TABLE IF NOT EXISTS staging_product_ingredients_kr (
    id BIGSERIAL PRIMARY KEY,

    report_no VARCHAR(255) NOT NULL,
    product_name VARCHAR(255),
    manufacturer_name VARCHAR(255),

    canonical_name_ko VARCHAR(255) NOT NULL,
    canonical_slug VARCHAR(255),
    raw_label_name TEXT NOT NULL,
    amount_per_serving NUMERIC(12,4),
    amount_unit VARCHAR(50),
    daily_amount NUMERIC(12,4),
    daily_amount_unit VARCHAR(50),
    amount_source VARCHAR(100),

    source_datasets JSONB NOT NULL DEFAULT '[]'::jsonb,
    source_kinds JSONB NOT NULL DEFAULT '[]'::jsonb,
    raw_ingredient_roles JSONB NOT NULL DEFAULT '[]'::jsonb,

    proposed_ingredient_role VARCHAR(50) NOT NULL,
    min_order_hint INTEGER,
    max_confidence NUMERIC(5,2),

    matched_variants JSONB NOT NULL DEFAULT '[]'::jsonb,
    match_strategies JSONB NOT NULL DEFAULT '[]'::jsonb,
    promotion_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,

    import_batch VARCHAR(100),
    imported_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_staging_product_ingredients_kr_row
        UNIQUE (report_no, canonical_name_ko, raw_label_name, proposed_ingredient_role)
);

CREATE INDEX IF NOT EXISTS idx_staging_product_ingredients_kr_report_no
    ON staging_product_ingredients_kr (report_no);

CREATE INDEX IF NOT EXISTS idx_staging_product_ingredients_kr_canonical_name
    ON staging_product_ingredients_kr (canonical_name_ko);

CREATE INDEX IF NOT EXISTS idx_staging_product_ingredients_kr_canonical_slug
    ON staging_product_ingredients_kr (canonical_slug);

CREATE INDEX IF NOT EXISTS idx_staging_product_ingredients_kr_role
    ON staging_product_ingredients_kr (proposed_ingredient_role);

CREATE INDEX IF NOT EXISTS idx_staging_product_ingredients_kr_confidence
    ON staging_product_ingredients_kr (max_confidence DESC);


-- ============================================================================
-- 4. 규제 기준 staging
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


-- ============================================================================
-- 5. 코멘트
-- ============================================================================

COMMENT ON TABLE staging_products_kr IS
'KR 정부 데이터 기반 제품 staging. products 본 테이블 적재 전 중간 저장소.';

COMMENT ON TABLE staging_ingredients_kr IS
'KR 정부 데이터 기반 원료 staging. ingredients 본 테이블 적재 전 중간 저장소.';

COMMENT ON TABLE staging_product_ingredients_kr IS
'KR 정부 데이터 기반 제품-원료 연결 staging. product_ingredients 본 테이블 적재 전 중간 저장소.';

COMMENT ON TABLE staging_regulatory_standards_kr IS
'KR 정부 데이터 기반 규격 기준 staging. I0960 규격 항목(예: 비타민 B6 최소/최대 표시량) 보존용.';
