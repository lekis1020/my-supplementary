-- ============================================================================
-- KR 정부 데이터 staging 테이블 복원 (3종)
--
-- 배경: 2026-08-23 감독 하 실행 준비 중, 원격 DB에 staging 테이블이
-- staging_regulatory_standards_kr 1개만 존재함을 확인 (베이스라인 덤프와 일치).
-- import_kr_staging_to_db.mjs가 대상으로 하는 나머지 3개를 복원한다.
-- DDL 출처: db/012_staging_tables.sql (동결 아카이브, 참조 전용) —
-- 현행 스크립트의 컬럼 목록·ON CONFLICT 대상과 1:1 대조 완료.
-- staging_regulatory_standards_kr은 이미 존재하므로 이 마이그레이션에서 제외.
--
-- RLS: ensure_rls 이벤트 트리거가 자동 활성화하지만 명시적으로도 선언.
-- 정책 없음 = anon/authenticated 차단, 파이프라인(service_role)은 RLS 우회.
-- ============================================================================

-- ============================================================================
-- 1. 제품 staging
-- ============================================================================

CREATE TABLE staging_products_kr (
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

CREATE INDEX idx_staging_products_kr_name
    ON staging_products_kr (product_name);

CREATE INDEX idx_staging_products_kr_manufacturer
    ON staging_products_kr (manufacturer_name);

CREATE INDEX idx_staging_products_kr_status
    ON staging_products_kr (status);

ALTER TABLE staging_products_kr ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. 원료 staging
-- ============================================================================

CREATE TABLE staging_ingredients_kr (
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

CREATE INDEX idx_staging_ingredients_kr_slug
    ON staging_ingredients_kr (slug);

CREATE INDEX idx_staging_ingredients_kr_type
    ON staging_ingredients_kr (ingredient_type);

CREATE INDEX idx_staging_ingredients_kr_mapped_product_count
    ON staging_ingredients_kr (mapped_product_count DESC);

ALTER TABLE staging_ingredients_kr ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. 제품-원료 연결 staging
-- ============================================================================

CREATE TABLE staging_product_ingredients_kr (
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

CREATE INDEX idx_staging_product_ingredients_kr_report_no
    ON staging_product_ingredients_kr (report_no);

CREATE INDEX idx_staging_product_ingredients_kr_canonical_name
    ON staging_product_ingredients_kr (canonical_name_ko);

CREATE INDEX idx_staging_product_ingredients_kr_canonical_slug
    ON staging_product_ingredients_kr (canonical_slug);

CREATE INDEX idx_staging_product_ingredients_kr_role
    ON staging_product_ingredients_kr (proposed_ingredient_role);

CREATE INDEX idx_staging_product_ingredients_kr_confidence
    ON staging_product_ingredients_kr (max_confidence DESC);

ALTER TABLE staging_product_ingredients_kr ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. 코멘트
-- ============================================================================

COMMENT ON TABLE staging_products_kr IS
'KR 정부 데이터 기반 제품 staging. products 본 테이블 적재 전 중간 저장소.';

COMMENT ON TABLE staging_ingredients_kr IS
'KR 정부 데이터 기반 원료 staging. ingredients 본 테이블 적재 전 중간 저장소.';

COMMENT ON TABLE staging_product_ingredients_kr IS
'KR 정부 데이터 기반 제품-원료 연결 staging. product_ingredients 본 테이블 적재 전 중간 저장소.';
