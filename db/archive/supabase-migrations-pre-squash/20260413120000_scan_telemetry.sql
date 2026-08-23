-- ============================================================================
-- 034_scan_telemetry.sql — 카메라 스캔 텔레메트리
--
-- Track A (카메라 제품 인식) 지원 테이블.
-- 개인정보 완전 미수집: IP / session 관련 컬럼 없음. 이미지 blob 저장하지 않고
-- sha256 해시만 기록하여 중복 스캔 감지·품질 분석에만 활용.
-- ============================================================================

CREATE TABLE IF NOT EXISTS scan_events (
  id                  BIGSERIAL PRIMARY KEY,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  tier_hit            VARCHAR(20) NOT NULL
                      CHECK (tier_hit IN ('barcode','vision','miss')),
  -- barcode: 바코드 매칭 성공
  -- vision:  Vision API 폴백 매칭 성공
  -- miss:    어느 티어에서도 매칭 실패

  detected_barcode    VARCHAR(14),              -- EAN-13 / UPC 최대 14자
  extracted_name      TEXT,                     -- Vision이 추출한 제품명
  matched_product_id  BIGINT REFERENCES products(id) ON DELETE SET NULL,
  match_confidence    NUMERIC(5,4),             -- 0.0000 ~ 1.0000
  image_sha256        CHAR(64),                 -- 이미지 내용 해시 (중복 감지용)
  latency_ms          INTEGER,
  model_used          VARCHAR(40)               -- 'gemini-2.0-flash-exp' | 'claude-haiku-4-5' 등
);

COMMENT ON TABLE scan_events IS
  '카메라 스캔 이벤트 텔레메트리. 품질/비용/히트율 모니터링과 스크레이핑 피드백 루프 소스. IP·세션 등 개인정보 미저장.';

CREATE INDEX IF NOT EXISTS idx_scan_events_created
  ON scan_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_scan_events_barcode
  ON scan_events(detected_barcode)
  WHERE detected_barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_scan_events_matched
  ON scan_events(matched_product_id)
  WHERE matched_product_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_scan_events_miss
  ON scan_events(created_at DESC)
  WHERE matched_product_id IS NULL;

-- RLS: service_role만 모든 작업 가능. anon/authenticated는 접근 불가.
ALTER TABLE scan_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "scan_events_service_role_all"
  ON scan_events
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- anon / authenticated는 명시적 정책 없음 → 자동 거부

-- ============================================================================
-- 집계 뷰 — 주간 품질 모니터링
-- ============================================================================

CREATE OR REPLACE VIEW scan_events_weekly AS
SELECT
  DATE_TRUNC('day', created_at) AS day,
  tier_hit,
  COUNT(*) AS n,
  AVG(match_confidence) FILTER (WHERE matched_product_id IS NOT NULL) AS avg_conf,
  AVG(latency_ms) AS avg_ms,
  COUNT(*) FILTER (WHERE matched_product_id IS NULL)::numeric
    / NULLIF(COUNT(*), 0) AS miss_rate
FROM scan_events
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', created_at), tier_hit
ORDER BY day DESC, tier_hit;

COMMENT ON VIEW scan_events_weekly IS
  '주간 스캔 품질 집계. tier_hit별 건수/평균 신뢰도/평균 지연/미스율.';

-- 검증 쿼리 (주석 처리)
-- SELECT * FROM scan_events_weekly;
-- SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c
-- WHERE c.conrelid = 'scan_events'::regclass;
