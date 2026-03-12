# 영양제·건강기능식품 비교 분석 플랫폼 — 프로젝트 계획서

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | 내 영양제 비교 (My Supplement Compare) |
| **목적** | 비의료인이 영양제·건강기능식품을 쉽게 비교·선택할 수 있도록 돕고, 무분별한 복용으로 인한 부작용을 예방한다 |
| **대상 사용자** | 소비자(일반인), 전문가(약사·영양사), 운영자(내부) |
| **핵심 가치** | 정확성 · 비교 용이성 · 부작용 경고 · 접근성 · 근거 투명성 |
| **설계 철학** | "콘텐츠 사이트"가 아닌 **데이터 플랫폼**으로 설계. **원료(성분) 중심 DB**로 시작하여 제품·근거·안전성을 연결한다 |

> **한국 건강기능식품의 특수성**: 의약품처럼 질병 치료·예방 효능을 표방하는 것이 아니라, "인체의 구조 및 기능" 관점에서 정상 기능 유지·개선 범위의 기능성을 다룬다. 데이터 모델과 화면 문구도 이 틀에 맞춘다.

---

## 2. 목표 정의 (3계층)

### 2.1 소비자용 조회
- 성분별 효능·효과
- 부작용, 주의군, 상호작용
- 권장 섭취량 범위
- 제품 라벨/함량 비교

### 2.2 전문가용 근거 요약
- 인체연구, 메타분석, 가이드라인 기반 근거 수준
- 근거가 있는 적응 영역과 없는 영역 분리
- **국내 인정 기능성**과 **해외 연구 결과** 분리 표시

### 2.3 운영용 내부 데이터 자산
- 규제 데이터
- 제품/라벨 데이터
- 논문 근거 데이터
- 이상사례/안전성 데이터
- 원료 동의어 사전

---

## 3. 데이터베이스 스키마

> 상세 DDL: [`db/001_schema.sql`](db/001_schema.sql)

### 설계 원칙
1. **`ingredient_id` 중심 연결** — 모든 데이터의 중심축
2. **국내 규제 문구와 학술 근거 분리** — `ingredient_claims.is_regulator_approved` + `approval_country_code`
3. **모든 데이터에 출처와 갱신일** — `sources` + `source_links` 테이블
4. **ENUM 대신 코드 테이블** — `code_tables` + `code_values` (운영 확장성)
5. **변경 이력 보존** — `revision_histories` + `evidence_grade_history`
6. **Raw-first 수집** — 원문 보존 후 파싱 (재처리 가능)
7. **Confidence-based publishing** — 자동 추출 결과를 신뢰도 기반으로 게시/검수 분기

### ERD 개요

```
┌─────────────────────────────────────────────────────────────┐
│ 서비스 DB (MVP-Core)                                        │
│                                                             │
│ ingredients ─────────── ingredient_synonyms                 │
│      │                                                      │
│      ├── ingredient_claims ────────── claims                │
│      ├── safety_items                                       │
│      ├── ingredient_drug_interactions                       │
│      ├── dosage_guidelines                                  │
│      ├── regulatory_statuses                                │
│      ├── product_ingredients ──────── products ── label_snapshots │
│      └── evidence_studies ─────────── evidence_outcomes     │
│                                            └──── claims (FK)│
│                                                             │
│ sources ──── source_links (polymorphic)                     │
│ code_tables ──── code_values                                │
│ review_tasks / revision_histories / evidence_grade_history  │
│ ingredient_search_documents (GIN index)                     │
└─────────────────────────────────────────────────────────────┘
                           ▲ 데이터 공급
┌─────────────────────────────────────────────────────────────┐
│ 수집/갱신 계층                                              │
│                                                             │
│ sources ──1:N── source_connectors                           │
│                      │                                      │
│  MVP-Pipeline:       ├── raw_documents ── extraction_results│
│                      │                                      │
│  Phase 2:            ├── collection_jobs ── collection_runs │
│                      ├── refresh_policies                   │
│                      └── entity_refresh_states              │
└─────────────────────────────────────────────────────────────┘
```

### 서비스 DB 테이블 (MVP-Core: 10개 + 지원 4개)

| # | 테이블 | 설명 | 주요 관계 |
|---|--------|------|-----------|
| 1 | `ingredients` | 원료 마스터 | 자기참조(`parent_ingredient_id`), 모든 테이블의 중심 |
| 2 | `ingredient_synonyms` | 동의어/이명 | ingredients 1:N |
| 3 | `claims` | 기능성/효능 표현 | `claim_scope`로 허용/금지 구분 |
| 4 | `ingredient_claims` | 원료↔기능성 M:N | 국가별 허용 여부 분리 (`approval_country_code`) |
| 5 | `safety_items` | 부작용/금기/경고 통합 | `evidence_level`로 3계층 분류 |
| 6 | `dosage_guidelines` | 용량 가이드라인 | 집단/적응증/권장유형별 분리 |
| 7 | `products` | 제품 마스터 | barcode, image_url 포함 |
| 8 | `product_ingredients` | 제품↔원료 M:N | `raw_label_name` 보존 (정규화 추적) |
| 9 | `evidence_studies` | 논문/근거 문서 | `screening_status`로 검수 추적 |
| 10 | `evidence_outcomes` | 논문 결과지표 | 1논문 N결과 (피로+수면 동시 평가 등) |
| + | `sources` | 출처 중앙관리 | 신뢰등급(`trust_level`) 포함 |
| + | `source_links` | 출처↔엔티티 연결 | Polymorphic (체크 제약으로 보완) |
| + | `code_tables` / `code_values` | ENUM 대체 코드 테이블 | 규칙 변경 시 migration 불필요 |
| + | `ingredient_search_documents` | 검색 최적화 | PostgreSQL GIN 인덱스 |

### 수집/갱신 계층 테이블

#### MVP-Pipeline (3개) — 수동/스크립트 수집 지원
| 테이블 | 설명 |
|--------|------|
| `source_connectors` | 소스별 기술 접근 설정. `sources` 1:N `source_connectors` |
| `raw_documents` | 원문 보존 (Raw-first). 대용량은 object storage, 소형만 PG |
| `extraction_results` | 구조화 추출 결과 + `schema_version`으로 JSONB 검증 + `confidence_score` |

#### Phase 2 (4개) — 자동화/스케줄링
| 테이블 | 설명 |
|--------|------|
| `collection_jobs` | 수집 작업 정의 (full_sync, incremental, targeted, backfill) |
| `collection_runs` | 실행 로그 (job 1:N run) |
| `refresh_policies` | 갱신 주기 정책 (Airflow가 동적으로 읽어 스케줄 생성) |
| `entity_refresh_states` | 엔티티별 갱신 상태 (targeted refresh 우선순위 결정) |

### 추가 운영 테이블
| 테이블 | 설명 |
|--------|------|
| `ingredient_drug_interactions` | 약물 상호작용 (safety_items과 별도 분리) |
| `regulatory_statuses` | 국가별 규제 상태 |
| `label_snapshots` | 제품 라벨 버전 관리 (`raw_label_text` 보존) |
| `evidence_grade_history` | 근거 등급 변경 이력 |
| `review_tasks` | L1/L2/L3 검수 워크플로우 |
| `revision_histories` | 모든 변경 이력 |

### 부작용 3계층 — `safety_items.evidence_level` 매핑
| 계층 | evidence_level 값 | 출처 | 신뢰도 |
|------|-------------------|------|--------|
| **1층: 확정적** | `label`, `guideline` | 규제기관 라벨/공식 경고, 재평가 문서 | 최고 |
| **2층: 문헌** | `rct`, `observational`, `case_report` | RCT/체계적 문헌고찰, 증례 보고 | 높음 |
| **3층: 신호** | `spontaneous_report` | 자발보고 DB (발생빈도 아닌 신호) | 참고 |

### 수집 전략 원칙
1. **API 우선** — 공식 API가 있으면 API 사용 (안정적, 구조화, 유지보수 저비용)
2. **브라우저 에이전트 보완** — API 불완전 시 hybrid, API 없으면 browser_agent 단독
3. **Raw-first** — 운영 DB에 바로 쓰지 않고, 항상 `raw_documents`에 원문 보존 후 파싱
4. **Parser versioning** — `extraction_results.extraction_version`으로 파서 버전 관리
5. **Confidence-based publishing** — 0.95+: 자동반영, 0.70~0.95: 조건부, <0.70: 검수대기
6. **Soft delete** — 외부 소스에서 사라진 데이터는 삭제하지 않고 상태값(inactive/superseded) 관리

### 변경 감지 방식 (혼합 권장)
1. **1차: Metadata** — `updated_at`, `last-modified` 헤더
2. **2차: Checksum** — `raw_documents.checksum` (SHA-256) 비교
3. **3차: Semantic diff** — 주요 필드(경고문, 함량, 허용표현) 의미 비교
4. 차이 발견 시 update + `review_tasks` 생성

### 엔티티별 권장 갱신 주기
| 엔티티 | 기본 주기 | 비고 |
|--------|-----------|------|
| 원료 마스터 | 월 1회 | 변경 적은 항목은 분기 1회 |
| 기능성/규제 정보 | 주 1회 목록 확인 | 변경 감지 시 상세 즉시 수집 |
| 제품/라벨 (인기) | 주 1회 | 일반 제품은 월 1회 |
| 논문 근거 | 주 1~일 1회 | 고우선순위 원료: 일 1회 |
| 부작용/안전성 공지 | 주 1회 | 중요 채널은 일 1회 |
| PDF/고시문 | 목록 일 1회 | 신규 발견 시 상세 즉시 수집 |

---

## 5. 표준화 체계

> **이 프로젝트가 실패하는 가장 흔한 이유는 이름 표준화 실패**

### 반드시 정해야 할 것
| 항목 | 예시 |
|------|------|
| 한글 표준명 | 비타민 D3 |
| 영문 표준명 | Vitamin D3 |
| 학명 | Cholecalciferol |
| 염/에스터/추출물 형태 구분 | 산화마그네슘 vs 구연산마그네슘 |
| 복합원료 분리 규칙 | 멀티비타민 → 개별 성분으로 분해 |
| 프로바이오틱스 균주 수준 | Lactobacillus rhamnosus GG |
| 단위 표준화 | mg, mcg, IU, CFU, mg GAE 등 |

### 이름 3분리 원칙
```
표시명 (display_name)    → 화면에 보여주는 이름
표준명 (canonical_name)  → 시스템 내부 매칭용
원료형태 (form)          → 흡수율·근거 연결의 핵심
```

---

## 6. 근거 평가 프레임워크

### 근거 등급 체계
| 등급 | 정의 |
|------|------|
| **A** | 다수의 고품질 메타분석/가이드라인/일관된 RCT |
| **B** | RCT 존재하나 규모 제한 또는 결과 불일치 |
| **C** | 관찰연구 또는 소규모 인체연구 위주 |
| **D** | 전임상/기전연구 위주 |
| **I** | 근거 불충분 (Insufficient) |

### 화면 필수 분리 표시
```
┌─────────────────────────────────────────────────┐
│ 🏛️ 국내 허용 기능성                              │
│   "뼈의 형성과 유지에 필요"                        │
├─────────────────────────────────────────────────┤
│ 📚 학술 문헌상 연구된 영역                         │
│   면역 조절 (근거 B), 근력 유지 (근거 C)            │
├─────────────────────────────────────────────────┤
│ ⚠️ 근거는 있으나 규제상 허용되지 않는 표현           │
│   (해당 내용은 국내 기능성 인정 범위 밖입니다)        │
└─────────────────────────────────────────────────┘
```
> 이 분리를 안 하면 규제 리스크가 커진다.

---

## 7. 1차 데이터 소스 우선순위

### 국내 소스
| 순위 | 소스 | 용도 |
|------|------|------|
| 1 | **식품안전나라** 건강기능식품 기능별 정보 | 기능성 분류, 원료, 제품 연결 |
| 2 | **식품안전나라** 데이터활용서비스 / Open API | 품목제조 신고사항 현황 등 |
| 3 | **공공데이터포털** 건강기능식품 영양DB | 원료 DB |
| 4 | **MFDS** 고시/가이드/재평가 공시 | 인정 기준, 재평가 결과, 문구 변경 이력 |

### 해외 소스
| 순위 | 소스 | 용도 |
|------|------|------|
| 1 | **NIH ODS / DSLD** | 미국 보충제 라벨 데이터 |
| 2 | **PubMed** (E-utilities) | 임상근거 수집 핵심, 자동화 가능 |
| 3 | **DailyMed** | 구조화 라벨 데이터 |
| 4 | **openFDA** adverse event API | 안전신호 보조자료 (자발보고) |
| 5 | **USDA FoodData Central** | 영양성분 기반 일반 식품 데이터 연동 |

---

## 8. 데이터 수집/갱신 아키텍처 (4계층)

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ 1. 소스 접근  │ →  │ 2. 오케스트   │ →  │ 3. 정규화/   │ →  │ 4. 발행/     │
│    계층       │    │    레이션     │    │    매핑       │    │    갱신       │
│              │    │              │    │              │    │              │
│ API Connector│    │ 스케줄 관리   │    │ raw → parsed │    │ insert/update│
│ Browser Agent│    │ 실패 재시도   │    │ canonical    │    │ 버전 스냅샷   │
│ Hybrid       │    │ rate limit   │    │ mapping      │    │ 검수 큐      │
│              │    │ 변경 감지    │    │ 신뢰도 부여   │    │ 검색 인덱스   │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
     source_          collection_         raw_documents       운영 DB 반영
     connectors       jobs/runs           extraction_results  review_tasks
                                                              revision_histories
```

### 소스 접근 전략
| 전략 | 설명 | 예시 |
|------|------|------|
| `api` | 공식 Open API | PubMed E-utilities, 식품안전나라 API |
| `browser_agent` | 공개 페이지 탐색·추출 | 제품 상세페이지, PDF 게시판 |
| `hybrid` | 목록은 API, 상세는 브라우저 (또는 반대) | 식품안전나라 (API+상세페이지) |
| `file_import` | 파일 일괄 가져오기 | CSV/Excel 수동 입력 |

### 데이터 흐름 예시

**제품 라벨 갱신:**
1. `collection_jobs`: "제품 라벨 주간 갱신" 등록
2. 브라우저 에이전트가 제품 상세페이지 방문
3. HTML/PDF → `raw_documents`에 원문 보존
4. 파서 → `extraction_results`에 구조화 결과 저장
5. 이전 `label_snapshots`와 diff 비교
6. 변경 있으면 새 `label_snapshots` + `product_ingredients` 갱신
7. `revision_histories` 기록 + 변경 크면 `review_tasks` 생성

**논문 업데이트:**
1. PubMed API 검색 실행
2. 신규 PMID → `raw_documents`에 JSON 저장
3. 파서 → `evidence_studies` + `evidence_outcomes` 생성
4. 관련 claim 자동 연결 후보 생성
5. 근거등급 변화 가능 시 `review_tasks` 전송

---

## 9. 기술 스택 · 배포 환경

### 배포 환경 (Vercel + Supabase)

| 영역 | 서비스 | 비용 (월) | 비고 |
|------|--------|-----------|------|
| **웹앱** | Vercel (Hobby → Pro) | $0~20 | Next.js 최적, SSG/ISR, 한국 Edge(ICN) |
| **DB** | Supabase Free → Pro | $0~25 | PostgreSQL 관리형, REST API 내장, 도쿄 리전 |
| **파일 저장** | Cloudflare R2 | $0 (10GB 무료) | raw_documents PDF/HTML, egress 무료 |
| **브라우저 에이전트** | Modal / 로컬 실행 | 사용량 기반 | Playwright headless, 앱 서버와 분리 |
| **스케줄러** | Vercel Cron → GitHub Actions | $0 | Phase 2에서 확장 |
| **검색** | Supabase pg_tsvector → Typesense | $0~25 | Phase 4에서 전용 엔진 도입 |
| **모니터링** | Vercel Analytics + Supabase Dashboard | $0 | 필요 시 Sentry 추가 |

### 환경 분리

| 환경 | 웹앱 | DB | 용도 |
|------|------|----|------|
| **dev** | Vercel Preview | Supabase 별도 프로젝트 (Free) | 개발·테스트 |
| **staging** | Vercel Preview Branch | Supabase staging 스키마 | 검수·통합 테스트 |
| **production** | Vercel Production | Supabase Pro | 서비스 운영 |

### 기술 스택

| 영역 | 기술 | 선정 이유 |
|------|------|-----------|
| **프론트엔드** | Next.js + TypeScript | SSG/ISR, SEO, Vercel 네이티브 |
| **스타일링** | Tailwind CSS | 빠른 반응형 UI 개발 |
| **DB ORM** | Prisma 또는 Drizzle | Supabase PostgreSQL 연동, 타입 안전 |
| **차트** | Recharts | React 네이티브 시각화 |
| **수집 엔진** | Python (FastAPI + Playwright) | 논문·라벨 파싱, 브라우저 에이전트 |
| **수집 저장소** | Cloudflare R2 (S3 호환) | 원천 데이터(PDF/HTML/스크린샷) 보관 |
| **관리자 CMS** | Next.js 내부 라우트 (/admin) | 검수 워크플로우, Supabase Auth 연동 |

### Phase별 인프라 비용 추정

| 단계 | 월 비용 | 구성 |
|------|---------|------|
| **Phase 0~1** (MVP) | **$0~20** | Vercel Hobby + Supabase Free + R2 Free |
| **Phase 2** (자동화) | **$25~50** | Vercel Pro + Supabase Pro + Modal 수집 |
| **Phase 3** (개인화) | **$50~100** | + Sentry + 검색 강화 |
| **Phase 4** (고도화) | **$100~200** | + Typesense Cloud + Worker 확장 |

---

## 10. 페이지 구조

### 소비자용
```
/                              → 메인 (검색, 목적별 바로가기)
/ingredients                   → 원료(성분) 전체 목록 (카테고리 필터)
/ingredients/[id]              → 원료 상세
                                  ├─ 기능성 요약
                                  ├─ 근거 수준 (A~I)
                                  ├─ 국내 허용 기능성 vs 학술 연구 분리 표시
                                  ├─ 부작용/상호작용
                                  ├─ 관련 제품 리스트
                                  └─ 참고문헌
/products                      → 제품 목록 (필터·정렬)
/products/[id]                 → 제품 상세 (라벨 정보, 원료 조성)
/compare                       → 비교 도구 (최대 4개 제품)
/my-supplements                → 내 영양제함 (복용 목록 + 합산 분석 + 중복/과다 경고)
/guide/interactions            → 상호작용 조회
/guide/cautions                → 특수 집단별 주의사항
/disclaimer                    → 의료 면책 조항
```

### 전문가용 (Phase 3+)
```
/evidence/[ingredient_id]     → 근거 요약 (논문 목록, PICO, 효과 크기)
/safety/[ingredient_id]       → 안전성 상세 (3계층 부작용, 약물상호작용)
```

---

## 11. UI/UX 핵심 원칙

1. **경고는 눈에 띄게**: 과다복용·상호작용 경고는 빨간색 배너로 즉시 표시
2. **쉬운 언어**: 전문 용어 사용 시 툴팁으로 쉬운 설명 제공
3. **모바일 우선**: 대부분의 사용자가 모바일로 접근할 것을 가정
4. **의료 면책**: 모든 페이지 하단에 "이 정보는 의료 조언이 아닙니다" 명시
5. **출처 투명성**: 모든 정보에 출처·갱신일 표기
6. **규제 표현 분리**: 국내 허용 기능성 / 학술 연구 / 비허용 표현을 시각적으로 명확히 분리
7. **자발보고 주의 표시**: 이상사례 데이터에는 "보고 신호이며 발생빈도가 아님" 명시

---

## 12. 품질관리 체계 (정식 검수)

> **검수 강도: 정식** — L1→L2→L3 순차 통과 후에만 서비스에 게시

### 정식 검수 흐름
```
수집/입력 → L1 자동 검수 → L2 과학 검수 → L3 규제 검수 → 게시 (is_published=TRUE)
                │                │                │
                ├─ 실패 → QA 수동검토  ├─ 반려 → 수정 요청    ├─ 반려 → 수정 요청
                └─ 통과 → L2 자동생성  └─ 승인 → L3 자동생성  └─ 승인 → 게시
```

### 검수 레벨
| 레벨 | 담당 | 내용 | SLA | 자동화 |
|------|------|------|-----|--------|
| **L1 데이터** | 자동 + QA | 필드 누락, 단위 오류, 중복 탐지, 포맷 검증 | 즉시~1일 | `auto_check_passed` 자동 판정 |
| **L2 과학** | 의학/약학 감수 | 논문 해석 정확성, 근거 등급 적합성, 부작용 검증 | 3~5일 | L1 통과 시 자동 생성 |
| **L3 규제** | RA 자문 | 허용 표현 준수, 과대광고 소지 탐지, 면책 문구 확인 | 5~7일 | L2 승인 시 자동 생성 |

### review_tasks 체인 구조
- L1 task → `parent_task_id = NULL`
- L2 task → `parent_task_id = L1 task id`
- L3 task → `parent_task_id = L2 task id`
- 어느 레벨에서든 반려 시 원점(수정 요청)으로 돌아감

### L1 자동 검증 규칙
- 동일 성분인데 단위가 비정상적으로 큰 값 탐지
- 같은 PMID 중복 수집 차단
- 금지 표현 사전 기반 자동 탐지
- 제품 라벨 개정 시 변경점 비교
- `confidence_score < 0.70` → 자동 실패, QA 수동 확인
- 필수 필드 누락 검사 (엔티티별 규칙)

### L2/L3 에스컬레이션 규칙
- 근거 등급 변경 시 → L2 필수 (자동 스킵 불가)
- 허용 기능성 문구 변경 시 → L3 필수
- 부작용/경고 신규 추가 시 → L2 + L3 모두 필수
- **라벨 변경 감지 시** → L1→L2→L3 전체 재검수

### 변경 이력 관리
모든 원료 페이지에 표시:
- 마지막 검토일
- 마지막 데이터 동기화일
- 근거 갱신 이력
- MFDS 재평가 반영 여부

---

## 13. 법률·표현 리스크 관리

### 화면 표현 필수 분리
| 구분 | 표시 방법 |
|------|-----------|
| **건강기능식품 기능성 정보** | 식약처 인정 뱃지 + 허용 문구 그대로 표시 |
| **일반 영양정보** | 학술 근거 등급과 함께 표시 |
| **질병 치료/예방 오해 가능 표현** | 절대 사용 금지, 자동 탐지 |

### 필수 면책 정책
- 이 정보는 의료행위 대체가 아님
- 질환 치료 목적 복용은 전문가 상담 필요
- 임산부, 수유부, 소아, 고령자, 기저질환자, 항응고제/면역억제제 복용자는 별도 주의
- 제품 효과는 원료 근거와 동일하지 않을 수 있음
- 복합제품은 개별 성분 근거를 단순 합산할 수 없음

---

## 14. MVP 범위

> **확정된 의사결정 (2026-03-12)**
> 1. MVP에 **원료 + 제품** 모두 포함
> 2. **제품 라벨** 1차에 포함 → 브라우저 에이전트 Phase 1부터 필요
> 3. 검수 강도: **정식 (L1→L2→L3 순차 검수)** → 정식 검수 프로세스 구축

### 1차 원료군 (20종)
비타민 D · 마그네슘 · 오메가3 · 프로바이오틱스 · 철 · 칼슘 · 아연 · 홍삼 · 밀크시슬 · 루테인 · 코엔자임Q10 · 비오틴 · 엽산 · 비타민 B12 · 글루코사민 · MSM · 가르시니아 · 콜라겐 · 크레아틴 · 멜라토닌

### 1차 제품 대상
- 위 20종 원료의 **인기 제품 30~50개** (단일성분 위주, 복합제 소수 포함)
- 제품 기본 정보 + 원료 조성 + 라벨 스냅샷 (원문 보존)

### MVP 3단계 구조

**MVP-Core** (서비스 DB + 정적 데이터, 5~8주)
- 서비스 DB 전체 테이블 (MVP-Core 10개 + 지원 4개 + 운영 6개)
- 원료 상세 페이지 (기능성 요약, 근거 수준, 부작용, 국내 허용 기능성, 참고문헌)
- **제품 목록/상세 페이지** (라벨 정보, 원료 조성)
- **제품 비교 도구** (최대 4개 나란히)
- 원료 목록/검색/필터
- 의료 면책 조항

**MVP-Pipeline** (수집 기반, 8~12주)
- `source_connectors` + `raw_documents` + `extraction_results` 3개 테이블 추가
- API 커넥터 프레임워크 (PubMed, 식품안전나라)
- **브라우저 에이전트 프레임워크** (제품 상세페이지, 라벨 PDF — Phase 1부터 필수)
- Raw-first 수집 + Confidence-based publishing
- **라벨 파싱 파이프라인** (HTML/PDF → label_snapshots → product_ingredients)

**MVP-Review** (정식 검수 체계, 10~14주)
- **L1 데이터 검수**: 자동 규칙 (필드 누락, 단위 오류, 중복 탐지)
- **L2 과학 검수**: 전문가 (논문 해석 정확성, 근거 등급 적합성)
- **L3 규제 검수**: RA 자문 (허용 표현 준수, 과대광고 소지 탐지)
- admin UI: raw 문서 보기, diff viewer, 승인/반려/반송, 이력 추적
- 검수 미통과 데이터는 서비스에 노출되지 않음 (`is_published = FALSE`)

### MVP에서 제외
- 개인 맞춤 추천 엔진
- 후기 분석
- AI 챗봇 추천
- 복잡한 복합제 자동 해석 (소수 복합제는 수동 매핑)
- 내 영양제함 (Phase 3)
- 자동 스케줄링 (Phase 2: `collection_jobs`, `refresh_policies` 등)

---

## 15. 실행 계획

### 15.1 1순위 — 바로 해야 하는 일

#### A. PRD 확정

> **확정 사항 (2026-03-12)**
> - MVP 원료 20종 + 제품 30~50개 + 제품 라벨 포함
> - 검수 강도: 정식 (L1→L2→L3)

미확정 항목 (추가 결정 필요):
- 국가 범위 (한국 우선 / 미국 데이터 병행 여부)
- 부작용/상호작용 노출 수준 (일반 사용자 / 전문가 분리 여부)
- 공개 서비스 / 내부 운영도구 여부

산출물:
- [ ] MVP PRD 1부
- [ ] 사용자 시나리오 5~10개 (원료 조회, 제품 비교, 라벨 확인, 부작용 조회 포함)
- [ ] 화면 목록 (와이어프레임)

#### B. 데이터 소스 인벤토리
"어디서 어떤 방식으로 데이터를 가져올 수 있는지"가 이 프로젝트의 핵심.

소스별 정리 항목:
- 소스명, 데이터 유형, 접근 방식 (API / browser_agent / hybrid)
- 인증 필요 여부, robots.txt/이용약관 검토
- 갱신 빈도, 데이터 신뢰도, 파싱 난이도

산출물:
- [ ] source catalog 시트
- [ ] 소스 우선순위 표
- [ ] API/브라우저 전략 매핑표

#### C. Canonical Dictionary 설계
가장 먼저 만들어야 하는 핵심 자산. 이 작업이 늦으면 데이터가 뒤엉킨다.

포함 항목:
- 원료 표준명 (한글/영문), 동의어, 제형/염형/추출물 구분
- claim 표준명, safety type 표준명
- 단위 표준화 규칙

산출물:
- [ ] ingredient dictionary v1
- [ ] claim taxonomy v1
- [ ] safety taxonomy v1
- [ ] unit normalization rules v1

#### D. 수집 우선순위 정의
모든 소스를 한 번에 붙이면 실패한다. 순서:
1. 규제/기능성 원료 데이터
2. 논문 검색 API
3. 제품 라벨/제품 정보
4. 안전성/부작용
5. 고급 상호작용/재평가 문서

### 15.2 2순위 — 기반 구축

#### E. 시스템 아키텍처 설계서
확정할 컴포넌트:
- 수집 계층, raw storage, parser layer, canonical mapping layer
- 운영 DB, 검색 인덱스, admin review UI
- public API, scheduler, monitoring

산출물:
- [ ] architecture diagram (Vercel + Supabase + R2 + 수집 Worker)
- [ ] service boundary 정의
- [ ] 컴포넌트별 책임 정의

#### F. DB DDL 확정
DDL v2.0.0 초안 완료 상태. 추가 확정 사항:
- [ ] code_values 초기 시드 데이터 확정
- [ ] partition 정책 (raw_documents, collection_runs)
- [ ] Supabase Row Level Security (RLS) 정책
- [ ] migration 전략 (Prisma/Drizzle migrate vs raw SQL)
- [ ] soft delete 정책 (active/inactive/superseded/source_missing)

#### G. 수집 프레임워크 설계
브라우저 에이전트와 API 수집기를 공통 인터페이스로 운영.

결정할 것:
- [ ] connector interface spec
- [ ] collection job spec
- [ ] retry policy / rate limit 기본값
- [ ] raw document → extraction 파이프라인 정의
- [ ] confidence score 기준 (0.95+ 자동, 0.70~0.95 조건부, <0.70 검수)
- [ ] manual review trigger 기준

#### H. 관리자 검수 도구 범위
자동 수집만으로는 운영 불가. 필요 기능:
- raw 문서 보기, 추출 결과 비교, 이전 버전 diff
- 승인/반려, source trace 확인
- 재수집 실행, 파서 오류 확인

### 15.3 3순위 — 서비스 구축

#### I. API 설계

소비자용 API:
- 원료 검색/상세, claim 목록, safety 목록
- 관련 제품, 참고문헌, 갱신일 조회

운영용 API:
- 재수집 요청, 검수 큐 조회, diff 조회, source lineage 조회

#### J. 검색 설계

필요 기능:
- 동의어 검색, 오탈자 허용
- 원료/제품/claim 혼합 검색
- 제형별 필터, 경고 포함 결과 우선 노출

Phase 1~2: Supabase `pg_tsvector` + `ingredient_search_documents`
Phase 4: Typesense Cloud 전용 엔진 전환

#### K. 배포·운영 정책 수립

문서화 필수 항목:
- [ ] staging/production 분리 정책
- [ ] 배포 승인·롤백 절차
- [ ] 데이터 백업 정책 (Supabase PITR)
- [ ] 장애 대응 정책
- [ ] scraper 차단 대응 정책

---

## 16. 개발 로드맵 (6개월)

### Phase 0: 기획 고정 (0~4주)
- [x] ~~MVP 범위 확정~~ → 원료+제품+라벨 포함, 정식 검수
- [ ] PRD 확정 (국가 범위, 노출 수준, 공개/내부 여부)
- [ ] 사용자 시나리오 5~10개 작성 (원료 조회, 제품 비교, 라벨 확인, 부작용 조회)
- [ ] source catalog + 우선순위 표 작성
- [ ] canonical dictionary v1 (ingredient/claim/safety/unit)
- [ ] 수집 우선순위 정의 (제품 라벨 소스 포함)
- [ ] 규제 문구 정책 확정
- [ ] 정식 검수 프로세스 설계 (L1→L2→L3 흐름, 역할, SLA)
- [ ] 운영 정책 초안 (배포/백업/롤백/장애대응)

### Phase 1: MVP-Core — 원료+제품+라벨 (5~10주)
**인프라**
- [ ] Vercel 프로젝트 생성 + Supabase 프로젝트 생성 (도쿄 리전)
- [ ] Next.js + TypeScript + Tailwind 프로젝트 초기화
- [ ] Supabase에 DDL 적용 (전체 테이블: Core + 운영 + 수집 계층)
- [ ] Cloudflare R2 버킷 생성 (raw documents용)
- [ ] 환경 분리 (dev/staging/production)
- [ ] Supabase Auth 설정 (admin 계정)

**데이터**
- [ ] 1차 원료 20종 수동 데이터 입력 (Supabase Dashboard + seed SQL)
- [ ] **인기 제품 30~50개 데이터 입력** (제품 기본 정보 + 원료 조성)
- [ ] **제품 라벨 스냅샷 초기 적재** (수동 또는 반자동)
- [ ] code_values 초기 시드 적재
- [ ] sources 시드 데이터 적재

**서비스**
- [ ] 원료 목록/상세 페이지 구현
- [ ] **제품 목록/상세 페이지 구현** (라벨 정보, 원료 조성)
- [ ] **제품 비교 도구** (최대 4개 나란히 비교)
- [ ] **성분 중복 경고 로직**
- [ ] 기본 검색 기능 (pg_tsvector)
- [ ] 의료 면책 조항 페이지
- [ ] **Vercel Production 배포 → 가치 검증**

### Phase 1.5: MVP-Pipeline — 수집+라벨 파싱 (11~14주)
**수집 인프라**
- [ ] `source_connectors` + `raw_documents` + `extraction_results` 테이블 적용
- [ ] connector interface 구현 (Python)
- [ ] API 커넥터: 식품안전나라/공공데이터 API 연동
- [ ] API 커넥터: PubMed E-utilities 수집기 개발
- [ ] **브라우저 에이전트 프레임워크** (Playwright, Modal — Phase 1부터 필수)
- [ ] **라벨 파싱 파이프라인** (HTML/PDF → raw_documents → extraction_results → label_snapshots)
- [ ] Raw-first 파이프라인: 원문 → R2 저장 → 파싱 → 신뢰도 평가
- [ ] Confidence-based publishing 로직 구현

**정식 검수 체계 (MVP-Review)**
- [ ] /admin 라우트 구현 (Supabase Auth, 역할 기반)
- [ ] **L1 자동 검수**: 필드 누락, 단위 오류, 중복 탐지 규칙 엔진
- [ ] **L2 과학 검수 UI**: 논문 해석 확인, 근거 등급 검토, 전문가 할당
- [ ] **L3 규제 검수 UI**: 허용 표현 검토, 금지 표현 자동 탐지, RA 자문 연결
- [ ] **검수 흐름**: L1 자동통과 → L2 전문가 승인 → L3 규제 승인 → `is_published = TRUE`
- [ ] raw 문서 보기, 추출 결과 비교, 이전 버전 diff
- [ ] 승인/반려/반송 + 반려 사유 기록
- [ ] 검수 SLA 대시보드 (적체 현황, 평균 처리 시간)

### Phase 2: 자동화 + 갱신 (15~20주)
**수집 자동화**
- [ ] `collection_jobs` + `collection_runs` 테이블 적용
- [ ] `refresh_policies` + `entity_refresh_states` 테이블 적용
- [ ] Vercel Cron / GitHub Actions 스케줄러 연동
- [ ] 변경 감지 로직 (metadata → checksum → semantic diff → review_tasks)
- [ ] **라벨 변경 자동 감지** (제품 페이지 checksum diff → 재수집 → L1→L2→L3)
- [ ] DSLD/DailyMed 수집기 추가
- [ ] 안전성 소스 1개 연결 (openFDA adverse event)

**정규화/매핑**
- [ ] 동의어 사전 구축 + 자동 매핑
- [ ] 단위 변환 로직 구현
- [ ] 원료-기능성/원료-논문 연결 정제

**검수 고도화**
- [ ] 검수 통계 리포트 (주간/월간)
- [ ] 금지 표현 사전 자동 탐지 고도화
- [ ] 근거 등급 변경 시 L2→L3 자동 에스컬레이션
- [ ] 대량 검수 일괄 처리 (batch approve/reject)

### Phase 3: 근거 평가 + 개인화 (21~24주)
- [ ] 논문 스크리닝 기준 수립
- [ ] 근거 등급 규칙 구현 (자동 산정 → L2 확인)
- [ ] 관리자 검수 UI 고도화 (재수집 관리, job monitoring)
- [ ] 내 영양제함 기능 (localStorage → Supabase Auth 연동)
- [ ] 총 영양소 합산 대시보드
- [ ] 과다 복용 경고 시스템
- [ ] 상호작용 조회 기능

### Phase 4: 고도화 + 품질 개선 (25~28주)
- [ ] Typesense Cloud 검색 엔진 전환 (동의어/오탈자/혼합검색)
- [ ] 재평가 문서 반영 자동화 (event-driven refresh)
- [ ] targeted refresh (인기 원료/제품 우선 갱신)
- [ ] 데이터 확장 (원료 50종+, 제품 100개+)
- [ ] SEO 최적화 (sitemap, structured data, OG tags)
- [ ] PWA 지원
- [ ] Sentry 에러 트래킹 도입
- [ ] 운영 모니터링 강화 (job success rate, stale data alert, 검수 SLA)

---

## 17. 인력 구성

> **정식 검수(L1→L2→L3) 선택으로 인해 최소 팀에서도 감수/RA 인력이 필수**

### 최소 팀 (MVP 가능)
| 역할 | 인원 | 비고 |
|------|------|------|
| PM/PO | 1 | 전체 일정·품질 관리, PRD 작성 |
| 백엔드 | 1 | API, Supabase, 수집 파이프라인 |
| 프론트엔드 | 1 | Next.js 웹 UI + admin UI |
| 데이터 엔지니어 | 1 | 수집·정규화·매핑, 브라우저 에이전트, 라벨 파서 |
| **의학/약학 감수** | **1~2** | **L2 과학 검수 담당 (필수)** |
| **규제(RA) 자문** | **1** | **L3 규제 검수 담당 (필수)** |
| QA/운영 | 0.5~1 | L1 자동 검수 규칙 관리, 수집 모니터링 |

### 권장 팀 (운영까지 안정적)
| 역할 | 인원 | 비고 |
|------|------|------|
| PM | 1 | 검수 SLA 관리 포함 |
| 백엔드 | 1~2 | API + 수집 엔진 + 검수 API 분리 |
| 프론트엔드 | 1 | 소비자 UI + admin/검수 UI |
| 데이터 엔지니어 | 1~2 | 수집기 + 라벨 파서 + 정규화/매핑 |
| DevOps | 0.5~1 | CI/CD, 모니터링, 스케줄러 |
| **의료/약학 감수** | **2** | **L2 과학 검수 상시 운영** |
| **규제/RA** | **1** | **L3 규제 검수 + 금지표현 사전 관리** |
| 콘텐츠/운영 | 1 | 원료 페이지 작성, 검수 큐 운영 |
| QA | 1 | 자동 검증 규칙 개선, 검수 품질 감사 |

### 정식 검수 인력 운영 기준
| 검수 레벨 | 담당 | SLA 목표 | 처리량 |
|-----------|------|----------|--------|
| L1 데이터 | 자동 + QA | 즉시~1일 | 전수 자동, 예외만 수동 |
| L2 과학 | 의학/약학 감수 | 3~5일 | 신규/변경 건 전수 |
| L3 규제 | RA 자문 | 5~7일 | L2 통과 건 전수 |

> **정식 검수를 선택했으므로 L2/L3 인력 없이는 서비스 오픈 불가. 최소 감수 1명 + RA 1명 확보가 전제 조건.**

---

## 18. 운영 정책

### 반복되는 운영 작업
서비스 오픈 후 "한 번 만들고 끝"이 아니라 계속 손이 간다:
- 사이트 구조 변경으로 selector 깨짐 → 파서 수정
- PDF/API 응답 포맷 변경 → 커넥터 수정
- 원료명 매핑 실패 → canonical dictionary 갱신
- 논문 claim 연결 오류 → 검수 큐 처리
- 제품 라벨 개정 diff 검토 → 승인/반려
- stale data 정리 → 주기적 정합성 점검
- 검색 품질 튜닝 → 동의어/가중치 조정

### 모니터링 항목
| 항목 | 임계값 | 알림 |
|------|--------|------|
| 수집 job 성공률 | < 90% | 즉시 |
| 특정 소스 미갱신 | > staleness_days | 일간 |
| review_tasks 적체 | > 50건 | 주간 |
| DB storage | > 80% | 즉시 |
| API 응답 지연 | p95 > 500ms | 즉시 |
| 파서 실패율 | > 10% | 즉시 |

### 백업 정책
- **Supabase**: PITR (Point-in-Time Recovery) 활성화 (Pro 플랜)
- **R2**: lifecycle rule 설정 (raw_documents 1년 보관, 이후 cold storage)
- **코드**: GitHub, Vercel 자동 배포

### Soft Delete 정책
외부 소스에서 사라진 데이터는 즉시 삭제하지 않음:
- `active` → 정상 운영
- `inactive` → 비활성 (소스에서 미발견)
- `superseded` → 새 버전으로 대체됨
- `source_missing` → 소스 자체가 사라짐

---

## 19. 예산 구조

### 비용 구분

**초기 구축 (CAPEX)**
- 설계, 개발, DDL/아키텍처
- 수집기·관리자 도구 구축
- 초기 데이터 적재 (canonical dictionary, seed data)
- 의학/약학 감수, 규제 자문
- QA/보안 점검

**월간 운영 (OPEX)**
- 클라우드 인프라 (Vercel + Supabase + R2)
- 유지보수 개발 (파서 수정, 소스 추가)
- 데이터 검수 (의료 감수, 규제 검토)
- 모니터링/로그/백업

### 인프라 비용 (Vercel + Supabase 기준)

| 단계 | 월 인프라비 | 주요 항목 |
|------|-------------|-----------|
| MVP (Phase 0~1) | **$0~20** | Vercel Hobby + Supabase Free + R2 Free |
| 성장기 (Phase 2~3) | **$50~100** | Vercel Pro($20) + Supabase Pro($25) + Modal + Sentry |
| 안정기 (Phase 4+) | **$100~200** | + Typesense($25) + Worker 확장 + 모니터링 강화 |

> 진짜 비용은 인프라보다 **운영 인력** — 인프라 < 인력비 구조

### 예산 기준 확정 사항 (2026-03-12)
1. **MVP 범위**: 원료 20종 + 제품 30~50개 + 라벨 포함
2. **검수 수준**: 정식 (L1→L2→L3) → 감수+RA 인력비 상시 발생
3. **브라우저 에이전트**: Phase 1부터 필요 → Modal/Worker 비용 조기 발생

### 미결정 (예산에 영향)
- **연결 소스 수**: 3개 vs 15개
- **자동화 수준**: 반자동 vs 거의 자동

---

## 20. 핵심 의사결정 로그

### 확정된 결정 (2026-03-12)

| # | 결정 사항 | 결과 | 영향 |
|---|-----------|------|------|
| 1 | MVP 범위 | **원료 + 제품** | Phase 1에 제품 목록/상세/비교 포함 |
| 2 | 제품 라벨 | **1차에 포함** | 브라우저 에이전트 Phase 1부터, 라벨 파싱 파이프라인 필수 |
| 3 | 검수 강도 | **정식 (L1→L2→L3)** | 감수+RA 인력 필수, admin UI Phase 1.5, 로드맵 2주 연장 |

### 미결정 사항 (추가 확정 필요)

| # | 결정 사항 | 선택지 | 의존 |
|---|-----------|--------|------|
| 4 | 국가 범위 | 한국만 / 한국+미국 | source catalog, 데이터 양, 번역 |
| 5 | 사용자 노출 수준 | 일반만 / 일반+전문가 분리 | 화면 구조, 정보 깊이 |
| 6 | 공개 서비스 여부 | 공개 / 내부 운영도구 / 하이브리드 | 인증, SEO, 법률 |
| 7 | ORM 선택 | Prisma / Drizzle / raw SQL | 개발 속도, Supabase 호환 |

---

## 21. 핵심 설계 원칙 7가지

1. **제품보다 원료를 중심으로 설계** — `ingredient_id`가 모든 것의 중심축
2. **국내 규제 문구와 학술 근거를 분리** — 규제 리스크 차단
3. **자발보고 부작용은 신호로만 표시** — 발생빈도로 오해 방지
4. **모든 값에 출처와 갱신일을 남김** — 신뢰성 확보
5. **자동화 + 전문가 검수 혼합 체계** — 확장성과 정확성 동시 확보
6. **Raw-first 수집** — 운영 DB에 바로 쓰지 않고, 항상 원문 보존 후 파싱 (재처리 가능)
7. **Confidence-based publishing** — 자동 추출 결과를 신뢰도 기반으로 게시/검수 분기

---

## 다음 단계 (즉시 실행)

### 이번 주
- [ ] PRD 작성 (미결정 사항 4~7번 포함)
- [ ] source catalog 작성 (소스명/접근방식/인증/갱신빈도/파싱난이도)
  - **제품 라벨 소스 반드시 포함** (어떤 사이트에서 라벨을 긁을지)
- [ ] canonical dictionary 초안 (ingredient/claim/safety 표준명)
- [ ] 정식 검수 프로세스 설계 (L1→L2→L3 흐름도, 역할 정의, SLA)
- [ ] 운영 정책 초안 (배포/백업/롤백)

### 다음 주
- [ ] DDL v3 확정 (review_tasks 강화 + Supabase RLS)
- [ ] connector interface spec 작성 (라벨 파싱 포함)
- [ ] **감수 인력(L2) + RA 인력(L3) 확보 착수** ← 정식 검수의 전제 조건
- [ ] Vercel + Supabase 프로젝트 생성
- [ ] 인력/역할 분담표 작성

### 그 다음
- [ ] Next.js 프로젝트 초기화 + TypeScript 타입 정의
- [ ] Supabase에 DDL 적용 + seed data 적재
- [ ] 원료 20종 + 제품 30~50개 초기 데이터 입력
- [ ] 원료 목록/상세 + **제품 목록/상세/비교** 페이지 구현
- [ ] admin review UI wireframe (L1→L2→L3 흐름)
- [ ] 브라우저 에이전트 PoC (제품 라벨 1개 사이트)
