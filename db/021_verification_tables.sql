-- ============================================================================
-- 데이터 무결성 검증 테이블
-- 목적:
--   - 파이프라인 3계층(Source API ↔ raw_documents ↔ staging ↔ core) 교차검증
--   - 전수조사 및 샘플링 결과 이력 관리
--   - 불일치 상세 기록 및 해결 추적
-- 전제: 001_schema.sql 이후 실행
-- ============================================================================

-- ============================================================================
-- 1. 검증 실행 이력
-- ============================================================================

CREATE TABLE IF NOT EXISTS verification_runs (
    id BIGSERIAL PRIMARY KEY,

    run_mode VARCHAR(20) NOT NULL,
    -- 'full' | 'sample'

    layers_checked VARCHAR(20) NOT NULL,
    -- '1,2,3' | '2,3' | '1' 등

    sample_size INTEGER,
    -- full 모드에서는 NULL

    total_checked INTEGER NOT NULL DEFAULT 0,
    total_passed INTEGER NOT NULL DEFAULT 0,
    total_warnings INTEGER NOT NULL DEFAULT 0,
    total_failures INTEGER NOT NULL DEFAULT 0,

    summary JSONB,
    -- 레이어별/테이블별 상세 통계

    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMP,
    triggered_by VARCHAR(100) DEFAULT 'manual'
    -- 'manual' | 'cron' | 'post_import'
);

COMMENT ON TABLE verification_runs IS '데이터 무결성 검증 실행 이력. 전수조사/샘플링 결과.';

CREATE INDEX IF NOT EXISTS idx_verification_runs_started
    ON verification_runs (started_at DESC);


-- ============================================================================
-- 2. 불일치 상세 기록
-- ============================================================================

CREATE TABLE IF NOT EXISTS verification_discrepancies (
    id BIGSERIAL PRIMARY KEY,
    verification_run_id BIGINT NOT NULL REFERENCES verification_runs(id) ON DELETE CASCADE,

    layer INTEGER NOT NULL,
    -- 1: API ↔ raw, 2: raw ↔ staging, 3: staging ↔ core

    check_name VARCHAR(100) NOT NULL,
    -- 'product_count', 'product_field_mismatch', 'missing_in_core' 등

    entity_type VARCHAR(50) NOT NULL,
    -- 'product', 'ingredient', 'product_ingredient'

    entity_external_id VARCHAR(255),
    -- API 측 식별자 (report_no 등)

    entity_db_id BIGINT,
    -- DB 측 ID

    discrepancy_type VARCHAR(50) NOT NULL,
    -- 'field_mismatch', 'missing_in_db', 'missing_in_source',
    -- 'count_mismatch', 'checksum_mismatch'

    field_name VARCHAR(255),
    source_value TEXT,
    db_value TEXT,

    severity VARCHAR(20) DEFAULT 'medium',
    -- 'low', 'medium', 'high', 'critical'

    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    resolution_note TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE verification_discrepancies IS '검증 불일치 상세 기록. severity별 해결 추적.';

CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_run
    ON verification_discrepancies (verification_run_id);

CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_unresolved
    ON verification_discrepancies (is_resolved, severity)
    WHERE is_resolved = FALSE;

CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_entity
    ON verification_discrepancies (entity_type, entity_external_id);
