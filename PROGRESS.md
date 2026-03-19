# PROGRESS.md

프로젝트 진행 경과 기록. 멀티 AI 에이전트(Claude, Codex, Gemini) + 사용자 협업으로 진행.

## 에이전트별 역할

| 에이전트 | Git Author | 커밋 수 | 주요 역할 |
|----------|-----------|---------|-----------|
| **Claude** (claude.ai/code) | `Claude` | 17 | 기획, 아키텍처 설계, DDL, MVP 스캐폴딩, Vercel 배포 수정 |
| **Gemini** (OpenClaw) | `OpenClaw Backup` | 33 | 데이터 적재, UI 기능 구현, 파이프라인 스크립트, 근거 데이터 확충 |
| **Codex** | `Silverlining` (PR merge) | 4 (PR) | 비타민 B1 regex 수정, benefit hexagon 레이아웃, 타이핑 수정 |
| **사용자** | `lekis1020` / `Silverlining` | 7+9 | PR 리뷰/머지, 수동 수정, UX 개선, 카테고리 분리 |

### 브랜치 전략
- `main` (= `claude/supplement-comparison-planner-p1ZMf`): 메인 개발 브랜치
- `OpenClaw-Backup/update-data-base`: Gemini 작업 브랜치 → PR로 main에 머지
- `codex/*`: Codex 작업 브랜치 → PR로 main에 머지

---

## 타임라인

### Day 1 — 2026-03-12: 기획 + MVP 스캐폴딩 (Claude)

Claude가 프로젝트 전체를 0에서 구축. 14커밋, 하루 만에 기획부터 동작하는 웹앱까지 완성.

**기획 (Phase 0)**
- `PLAN.md` 작성: 프로젝트 계획서 전면 개정 (데이터 플랫폼 설계 철학)
- 핵심 의사결정 6건 확정:
  - MVP 범위: 원료 20종 + 제품 30~50개 + 라벨 포함
  - 검수 강도: 정식 (L1→L2→L3)
  - 국가: KR+US 우선
  - 서비스: 공개 (SEO 필수)
  - ORM: 하이브리드 (Supabase Client + Drizzle)
- 수집/갱신 계층 설계 (critic 3회 반복 검토 후 합의)
- Phase 0 기획 문서 5종 작성 (`docs/PRD.md`, `docs/source-catalog.md`, `docs/canonical-dictionary.md`, `docs/review-process.md`, `docs/operations-policy.md`)

**데이터베이스**
- PostgreSQL DDL 전체본 작성 (`db/001_schema.sql`, 28+ 테이블)
- RLS 정책 (`db/002_rls_policies.sql`)
- Drizzle ORM 스키마 (`db/drizzle/schema/`)
- 시드 데이터 (`db/003_seed_data.sql`)
- Connector Interface Spec (`docs/connector-interface-spec.md`)
- 통합 마이그레이션 파일 (`db/RUN_THIS_ONLY.sql`)

**웹앱 (Phase 1 MVP-Core)**
- Next.js 16 + React 19 + Tailwind CSS 4 프로젝트 초기화
- Supabase SSR 클라이언트 (서버/브라우저)
- 원료 목록/상세, 제품 목록/상세, 비교, 검색, 면책 페이지
- Supabase CLI 설정
- Vercel 배포 수정 (prerender 에러, 환경변수 등)

---

### Day 2~3 — 2026-03-13~14: 배포 안정화 + Design Lab (Claude + Gemini)

**Claude**
- Vercel 배포 이슈 수정 (vercel.json root directory, Badge variant prop)
- PR #1, #3 (배포 수정)

**Gemini (OpenClaw)**
- 대규모 시드 데이터 추가 + 데이터 수집 계획 작성
- Design Lab 페이지 구현 (제품 카드 UI 반복 5회)
- 정부 API 환경변수 문서화

---

### Day 4 — 2026-03-16: 데이터 확충 (Gemini)

**Gemini (OpenClaw)**
- PubMed 근거 데이터 시드 (`db/009_seed_evidence.sql`, 154KB)
- 출처/검색 인덱스/US 라벨/스테이징 테이블 추가
- KR 정부 API raw backfill 스크립트 작성 (`web/scripts/backfill_kr_gov_raw.mjs`)
- KR API 테스트/정규화/임포트 스크립트 6종 (`scripts/`)

---

### Day 5 — 2026-03-17: 대규모 기능 개발 (40커밋, 전 에이전트 협업)

프로젝트 역사상 가장 활발한 날. Gemini가 핵심 기능과 데이터를, Codex가 세부 수정을, 사용자가 통합 조정.

**Gemini (OpenClaw) — 주도**
- 근거 데이터 enrichment 2단계 (정량 데이터, claim 매핑, claim 정규화)
- KR 정부 데이터 임포트 스크립트 완성 (claims, dosage, labels, safety)
- 제품 카드 UI 적용 + 확장 쿼리
- 제품 페이지네이션
- 원료 카테고리 네비게이션
- 프로바이오틱스 균주 수준 서브 원료 데이터
- DB 중복 정리 마이그레이션 (products, ingredients, intra-product)
- 원료 상세: 연구 근거 섹션 추가
- 비교 결과 가독성 개선
- 원료별 제품 필터링
- Benefit Hexagon 시각화 (요약, 레이아웃, side-by-side)
- 제품 상세 side-by-side 레이아웃
- 근거 누락 데이터 완전 보충 (20종 전체 원료 커버)
- 비타민 서브그룹 분리

**Codex — PR 기반**
- PR #9: Benefit hexagon 레이아웃 정제 + 근거 상세 표시
- PR #11: 비타민 B1 서브그룹 regex 수정 + benefit profile 타이핑 수정

**사용자 (lekis1020)**
- PR 머지 (PR #4~#11)
- 중복 비타민 서브그룹 헬퍼 제거
- 결합 원료 카테고리 분리

---

### Day 6 — 2026-03-18: UX 폴리싱 (사용자)

**사용자 (lekis1020) — 직접 수정**
- 미완성/대기 데이터 제품 표시 개선
- 홈페이지 + 검색 UX 개선
- 원료 근거/페이지네이션 개선
- 제품 상세 → 비교 액션 추가

---

### Day 7 — 2026-03-19: 프로젝트 문서화 (Claude)

**Claude**
- `CLAUDE.md` 작성 (Claude Code 가이드)
- `PROGRESS.md` 작성 (본 문서)

---

## 현재 상태 (2026-03-19)

### 완료된 항목 (Phase 0 + Phase 1 MVP-Core)

**기획**
- [x] PLAN.md 프로젝트 계획서 (900줄+)
- [x] PRD, Source Catalog, Canonical Dictionary, Connector Interface Spec
- [x] Review Process, Operations Policy, Data Collection Plan
- [x] Claim Normalization Spec, KR API Endpoints 문서

**데이터베이스**
- [x] DDL 28+ 테이블 (`db/001_schema.sql`)
- [x] RLS 정책 (`db/002_rls_policies.sql`)
- [x] Drizzle ORM 스키마 9개 모듈
- [x] 시드 데이터: 원료 20종, 제품 35+, 논문 50+
- [x] 근거 데이터 enrichment (정량 데이터, claim 매핑) — 20종 전체 커버
- [x] US 라벨 데이터 (`db/011_seed_us_labels.sql`)
- [x] 스테이징 테이블 (`db/012_staging_tables.sql`)
- [x] DB 중복 정리 마이그레이션 4종
- [x] 통합 마이그레이션 (`db/RUN_THIS_ONLY.sql`, 175KB)

**웹앱**
- [x] 랜딩 페이지 (히어로, 기능 카드, 신뢰 배너)
- [x] 원료 목록/상세 (카테고리 필터, 서브그룹 분리)
- [x] 제품 목록/상세 (페이지네이션, 원료 조성, 라벨 정보)
- [x] 제품 비교 (최대 4개, side-by-side)
- [x] 통합 검색 (pg_tsvector)
- [x] Design Lab (제품 카드 UI 실험)
- [x] Benefit Hexagon 시각화
- [x] 의료 면책 조항
- [x] 404 페이지

**데이터 파이프라인**
- [x] KR 정부 API backfill 스크립트
- [x] KR 데이터 임포트 6종 (core, claims, dosage, labels, safety, staging)
- [x] PubMed 근거 수집 스크립트 (Python v1, v2)
- [x] KR 원료 매핑/정규화/분류 스크립트 4종

**인프라**
- [x] Vercel 배포 (Production)
- [x] Supabase 프로젝트 연동
- [x] ESLint 설정 (Next.js core-web-vitals + TypeScript)

### 미완료 항목 (향후 작업)

**Phase 1.5: MVP-Pipeline (수집 자동화)**
- [ ] 브라우저 에이전트 프레임워크 (Playwright + Modal)
- [ ] 라벨 파싱 파이프라인 (HTML/PDF → label_snapshots)
- [ ] Confidence-based publishing 로직
- [ ] Raw-first 파이프라인 완성 (원문 → R2 저장 → 파싱 → 신뢰도 평가)

**Phase 1.5: MVP-Review (정식 검수)**
- [ ] /admin 라우트 (Supabase Auth 기반)
- [ ] L1 자동 검수 규칙 엔진
- [ ] L2 과학 검수 UI
- [ ] L3 규제 검수 UI
- [ ] 검수 흐름: L1→L2→L3→is_published=TRUE
- [ ] Raw 문서 보기, diff viewer, 승인/반려

**Phase 2: 자동화 + 갱신**
- [ ] collection_jobs / collection_runs 자동화
- [ ] 변경 감지 (metadata → checksum → semantic diff)
- [ ] DSLD/DailyMed 수집기
- [ ] openFDA adverse event 연동
- [ ] 동의어 사전 자동 매핑

**Phase 3+**
- [ ] 내 영양제함 (복용 목록 + 합산 분석)
- [ ] 과다 복용 경고 시스템
- [ ] 상호작용 조회
- [ ] Typesense 검색 엔진 전환
- [ ] SEO 최적화 (sitemap, structured data)

---

## 통계

| 항목 | 수치 |
|------|------|
| 총 커밋 수 | 70 |
| 개발 기간 | 7일 (2026-03-12 ~ 03-19) |
| SQL 마이그레이션 | 20+ 파일 |
| 데이터 파이프라인 스크립트 | 13개 (web/scripts 7 + scripts 6) |
| 문서 | 8개 (docs/) |
| PR 수 | 11 |
| 웹 페이지 | 10개 라우트 |
| DB 테이블 | 28+ |
| 시드 원료 | 20종 |
| 시드 제품 | 35+ |
| 시드 논문 | 50+ |
