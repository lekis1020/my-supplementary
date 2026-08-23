-- ============================================================================
-- 035_scraping_infrastructure.sql — Track B 라벨 데이터 스크레이핑 인프라
--
-- 3개 테이블 추가:
--   - product_images:  다중 소스 제품 이미지 (Naver / iHerb / 제조사 / user_scan)
--   - product_aliases: 소스별 제품명 variations (카메라 Vision 매처 보강용)
--   - scrape_jobs:     야간 배치 작업 큐 (재시도·백오프 지원)
--
-- pg_trgm 확장으로 product_aliases 퍼지 매칭 가능.
-- ============================================================================

-- pg_trgm 확장 (이미 활성화돼 있을 수 있음)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================================
-- product_images: 다중 소스 제품 이미지 (Cloudflare R2 미러링)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_images (
  id              BIGSERIAL PRIMARY KEY,
  product_id      BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  source          VARCHAR(40) NOT NULL,
  -- 'naver' | 'iherb' | 'manufacturer' | 'user_scan' | 'mfds_api'
  source_url      TEXT,                -- 원본 URL (출처 표기용)

  r2_key          TEXT,                -- Cloudflare R2 오브젝트 키
  r2_public_url   TEXT,                -- 공개 CDN URL

  image_hash      CHAR(64),            -- sha256; 동일 이미지 중복 방지
  mime_type       VARCHAR(50),
  width           INTEGER,
  height          INTEGER,
  size_bytes      INTEGER,

  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  removed_at      TIMESTAMPTZ,         -- 저작권 제거 요청 수신 시 즉시 기록

  captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (product_id, image_hash)
);

COMMENT ON TABLE product_images IS
  '제품당 다중 소스 이미지. Cloudflare R2에 미러링된 사본. removed_at 설정 시 서빙 차단.';

CREATE INDEX IF NOT EXISTS idx_product_images_product
  ON product_images(product_id)
  WHERE removed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_product_images_primary
  ON product_images(product_id)
  WHERE is_primary = TRUE AND removed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_product_images_source
  ON product_images(source);

-- 제품당 is_primary=TRUE 하나만 허용 (partial unique)
CREATE UNIQUE INDEX IF NOT EXISTS uq_product_images_one_primary
  ON product_images(product_id)
  WHERE is_primary = TRUE AND removed_at IS NULL;

-- ============================================================================
-- product_aliases: 제품명 variations (매장별 표기, 영문, OCR 관측 등)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_aliases (
  id              BIGSERIAL PRIMARY KEY,
  product_id      BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  alias           TEXT NOT NULL,
  alias_type      VARCHAR(30) NOT NULL,
  -- 'naver_display' | 'iherb_en' | 'iherb_ko' | 'brand_alt'
  -- | 'ocr_observed' | 'vision_extracted'

  language_code   VARCHAR(5) DEFAULT 'ko',
  source          VARCHAR(40),              -- 상세 출처 (예: 'naver_shopping_api')
  confidence      NUMERIC(3,2),             -- 0.00 ~ 1.00 (자동 추출 시 신뢰도)

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (product_id, alias, alias_type)
);

COMMENT ON TABLE product_aliases IS
  '제품명 variations. Vision 추출 텍스트와 다르게 표기된 경우 매칭 성공률 향상에 사용.';

CREATE INDEX IF NOT EXISTS idx_product_aliases_product
  ON product_aliases(product_id);

-- 퍼지 매칭용 GIN 인덱스 (pg_trgm)
CREATE INDEX IF NOT EXISTS idx_product_aliases_alias_trgm
  ON product_aliases USING GIN (alias gin_trgm_ops);

-- ============================================================================
-- scrape_jobs: 스크레이핑 작업 큐
-- ============================================================================

CREATE TABLE IF NOT EXISTS scrape_jobs (
  id              BIGSERIAL PRIMARY KEY,

  target_type     VARCHAR(30) NOT NULL,     -- 'product' | 'brand' | 'query'
  target_id       BIGINT NOT NULL,          -- products.id 또는 brand_id 등
  target_query    TEXT,                     -- target_type='query'일 때 검색어

  source          VARCHAR(40) NOT NULL,     -- 'naver' | 'iherb' | 'manufacturer'

  status          VARCHAR(20) NOT NULL DEFAULT 'pending',
  -- 'pending' | 'running' | 'done' | 'failed' | 'skipped'

  attempts        INTEGER NOT NULL DEFAULT 0,
  last_error      TEXT,

  scheduled_for   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,

  result_summary  JSONB,                    -- 수집 통계 (이미지 수, alias 수 등)

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (target_type, target_id, source)
);

COMMENT ON TABLE scrape_jobs IS
  '스크레이핑 배치 작업 큐. 재시도·백오프·재진입(idempotent) 지원. 야간 cron 소비.';

CREATE INDEX IF NOT EXISTS idx_scrape_jobs_pending
  ON scrape_jobs(scheduled_for)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_scrape_jobs_status
  ON scrape_jobs(status, scheduled_for);

CREATE INDEX IF NOT EXISTS idx_scrape_jobs_source
  ON scrape_jobs(source, status);

-- ============================================================================
-- RLS — 모든 테이블 service_role 전용 write, anon read는 product_images / aliases만 허용
-- ============================================================================

ALTER TABLE product_images   ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_aliases  ENABLE ROW LEVEL SECURITY;
ALTER TABLE scrape_jobs      ENABLE ROW LEVEL SECURITY;

-- product_images: 공개 SELECT (removed_at IS NULL), write는 service_role
CREATE POLICY "product_images_public_read"
  ON product_images FOR SELECT
  TO anon, authenticated
  USING (removed_at IS NULL);

CREATE POLICY "product_images_service_role_all"
  ON product_images FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- product_aliases: 공개 SELECT, write는 service_role
CREATE POLICY "product_aliases_public_read"
  ON product_aliases FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "product_aliases_service_role_all"
  ON product_aliases FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- scrape_jobs: service_role 전용 (내부 운영 테이블)
CREATE POLICY "scrape_jobs_service_role_all"
  ON scrape_jobs FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================================
-- updated_at 자동 갱신 트리거
-- ============================================================================

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_product_images_updated   ON product_images;
CREATE TRIGGER trg_product_images_updated   BEFORE UPDATE ON product_images
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_product_aliases_updated  ON product_aliases;
CREATE TRIGGER trg_product_aliases_updated  BEFORE UPDATE ON product_aliases
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_scrape_jobs_updated      ON scrape_jobs;
CREATE TRIGGER trg_scrape_jobs_updated      BEFORE UPDATE ON scrape_jobs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 검증 (주석 처리)
-- SELECT tablename FROM pg_tables
-- WHERE tablename IN ('product_images','product_aliases','scrape_jobs');
--
-- SELECT schemaname, tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('product_images','product_aliases','scrape_jobs','scan_events');
