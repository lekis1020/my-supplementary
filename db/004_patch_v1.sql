-- ============================================================================
-- 패치 v1: 누락 컬럼 추가 + RLS 수정
-- 실행 순서: 001 → 이 파일(004) → 002 (RLS) → 003 (시드)
-- ============================================================================

-- 1. products 테이블에 is_published 컬럼 추가
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN products.is_published IS '공개 여부. false면 관리자만 볼 수 있음.';
