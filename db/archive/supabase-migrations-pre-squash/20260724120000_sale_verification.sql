-- ============================================================================
-- 041_sale_verification.sql — 판매 확인 모델 + 성분 보강 큐
--
-- 배경: products 44K건은 식약처 품목제조신고 기반이라 실제 유통되지 않는
-- 제품이 다수. 소비자 페이지는 "판매 확인된 제품"만 기본 노출하도록 전환.
--
-- 1) products에 판매 확인 컬럼 3종 추가
-- 2) 기존 스크레이핑 성과(Naver 매칭 done, 제조사 이미지)로 소급 백필
-- 3) product_enrichment_queue: 실시간 검색으로 신규 유입된 제품의
--    성분 구성(product_ingredients)을 식약처 staging 데이터와 매칭하는 큐
--
-- 소프트 삭제 원칙 유지 — 미확인 제품 데이터는 삭제하지 않음.
-- ============================================================================

-- ============================================================================
-- 1. products 판매 확인 컬럼
-- ============================================================================

ALTER TABLE products ADD COLUMN IF NOT EXISTS sale_verified_at TIMESTAMPTZ;
ALTER TABLE products ADD COLUMN IF NOT EXISTS sale_channel VARCHAR(50);
-- 'naver' | 'manufacturer' | 'cafe24' | 'live_search'
ALTER TABLE products ADD COLUMN IF NOT EXISTS sale_url TEXT;

COMMENT ON COLUMN products.sale_verified_at IS
  '실제 판매 확인 시점. NULL이면 신고 정보만 있고 유통 미확인. 소비자 목록/성분 페이지 기본 필터.';
COMMENT ON COLUMN products.sale_channel IS
  '판매 확인 채널: naver | manufacturer | cafe24 | live_search';
COMMENT ON COLUMN products.sale_url IS '구매 페이지 URL (Naver 상품 링크 또는 공식몰).';

CREATE INDEX IF NOT EXISTS idx_products_sale_verified
  ON products (sale_verified_at DESC)
  WHERE sale_verified_at IS NOT NULL;

-- ============================================================================
-- 2. 소급 백필
-- ============================================================================

-- 2-1. Naver 매칭 성공분: scrape_jobs done + link 보유
UPDATE products p
SET
  sale_verified_at = COALESCE(sj.completed_at, sj.updated_at, NOW()),
  sale_channel     = 'naver',
  sale_url         = sj.result_summary->>'link'
FROM scrape_jobs sj
WHERE sj.target_type = 'product'
  AND sj.target_id = p.id
  AND sj.source = 'naver'
  AND sj.status = 'done'
  AND sj.result_summary->>'link' IS NOT NULL
  AND p.sale_verified_at IS NULL;

-- 2-2. 제조사/공식몰 이미지 확보분 (ckdhc, cafe24 등): 공식 판매처 존재
UPDATE products p
SET
  sale_verified_at = sub.first_captured,
  sale_channel     = 'manufacturer',
  sale_url         = p.official_url
FROM (
  SELECT product_id, MIN(captured_at) AS first_captured
  FROM product_images
  WHERE source IN ('manufacturer', 'manufacturer_label')
    AND removed_at IS NULL
  GROUP BY product_id
) sub
WHERE sub.product_id = p.id
  AND p.sale_verified_at IS NULL;

-- ============================================================================
-- 3. product_enrichment_queue — 성분 보강 큐
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_enrichment_queue (
  id                 BIGSERIAL PRIMARY KEY,
  product_id         BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  status             VARCHAR(20) NOT NULL DEFAULT 'pending',
  -- 'pending' | 'matched' | 'failed' | 'manual'
  matched_report_no  VARCHAR(255),      -- 매칭 성공 시 식약처 품목보고번호
  attempts           INTEGER NOT NULL DEFAULT 0,
  last_error         TEXT,

  source             VARCHAR(40),       -- 큐 등록 출처 (예: 'live_search')
  payload            JSONB,             -- 등록 시점 부가정보 (Naver title, mall 등)

  scheduled_for      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at       TIMESTAMPTZ,

  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (product_id)
);

COMMENT ON TABLE product_enrichment_queue IS
  '실시간 검색으로 유입된 제품의 성분 구성 보강 큐. 식약처 staging 데이터와 매칭해 product_ingredients 생성. 배치 소비.';

CREATE INDEX IF NOT EXISTS idx_product_enrichment_queue_pending
  ON product_enrichment_queue (scheduled_for)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_product_enrichment_queue_status
  ON product_enrichment_queue (status, scheduled_for);

-- RLS: 내부 운영 테이블 — service_role 전용
ALTER TABLE product_enrichment_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_enrichment_queue_service_role_all" ON product_enrichment_queue;
CREATE POLICY "product_enrichment_queue_service_role_all"
  ON product_enrichment_queue FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- updated_at 자동 갱신 (set_updated_at은 035에서 생성됨)
DROP TRIGGER IF EXISTS trg_product_enrichment_queue_updated ON product_enrichment_queue;
CREATE TRIGGER trg_product_enrichment_queue_updated
  BEFORE UPDATE ON product_enrichment_queue
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 검증 (주석 처리)
-- ============================================================================
-- SELECT sale_channel, COUNT(*) FROM products
-- WHERE sale_verified_at IS NOT NULL GROUP BY sale_channel;
--
-- SELECT COUNT(*) FROM product_enrichment_queue;
