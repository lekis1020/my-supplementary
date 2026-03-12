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

## 9. 기술 스택 (운영 아키텍처)

### MVP 단계 (Phase 1~2)
| 영역 | 기술 | 선정 이유 |
|------|------|-----------|
| **프론트엔드** | Next.js + TypeScript | SSG/ISR, SEO 최적화 |
| **스타일링** | Tailwind CSS | 빠른 반응형 UI 개발 |
| **데이터** | JSON 파일 (정적) → PostgreSQL 전환 예정 | Git 관리 가능, MVP에 적합 |
| **차트** | Recharts | React 네이티브 시각화 |
| **배포** | Vercel | Next.js 최적 호스팅 |

### 확장 단계 (Phase 3~4)
| 영역 | 기술 | 선정 이유 |
|------|------|-----------|
| **운영 DB** | PostgreSQL | 관계형 데이터 모델에 최적 |
| **검색 엔진** | OpenSearch / Elasticsearch | 원료명·동의어·기능성 검색 품질 |
| **배치/ETL** | Airflow 또는 Prefect | 데이터 수집 자동화 |
| **파싱** | Python | 논문·라벨 파싱 |
| **백엔드 API** | FastAPI 또는 Node.js | 데이터 조회 API |
| **수집 저장소** | Object Storage (S3 등) | 원천 데이터 보관 |
| **관리자 CMS** | 내부 검수 도구 별도 구축 | 전문가 검수 워크플로우 |

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

## 12. 품질관리 체계

### 검수 레벨
| 레벨 | 대상 | 내용 |
|------|------|------|
| **L1 데이터 검수** | 자동 | 필드 누락, 단위 오류, 중복 탐지 |
| **L2 과학 검수** | 전문가 | 논문 해석 정확성, 근거 등급 적합성 |
| **L3 규제 검수** | RA 자문 | 허용 표현 준수, 과대광고 소지 탐지 |

### 자동 검증 규칙
- 동일 성분인데 단위가 비정상적으로 큰 값 탐지
- 같은 PMID 중복 수집 차단
- 금지 표현 사전 기반 자동 탐지
- 제품 라벨 개정 시 변경점 비교
- 근거 등급 변경 시 사람 승인 필수

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

### 1차 원료군 (20종)
비타민 D · 마그네슘 · 오메가3 · 프로바이오틱스 · 철 · 칼슘 · 아연 · 홍삼 · 밀크시슬 · 루테인 · 코엔자임Q10 · 비오틴 · 엽산 · 비타민 B12 · 글루코사민 · MSM · 가르시니아 · 콜라겐 · 크레아틴 · 멜라토닌

### MVP 2단계 구조

**MVP-Core** (가치 검증, 4주 내)
- 서비스 DB 10개 테이블 + 지원 4개 (수동 큐레이션)
- 원료 상세 페이지 (기능성 요약, 근거 수준, 부작용, 국내 허용 기능성, 참고문헌)
- 원료 목록/검색/필터
- 관련 제품 리스트
- 의료 면책 조항

**MVP-Pipeline** (수집 기반, Core 이후 4주)
- `source_connectors` + `raw_documents` + `extraction_results` 3개 테이블 추가
- API 커넥터 프레임워크 (PubMed, 식품안전나라)
- 브라우저 에이전트 프레임워크 (제품 상세페이지)
- Raw-first 수집 + Confidence-based publishing

### MVP에서 제외
- 개인 맞춤 추천 엔진
- 후기 분석
- AI 챗봇 추천
- 복잡한 복합제 자동 해석
- 자동 스케줄링 (Phase 2: `collection_jobs`, `refresh_policies` 등)

---

## 15. 개발 로드맵 (6개월)

### Phase 0: 기획 (0~4주)
- [ ] 데이터 범위 확정 (1차 원료 20종)
- [ ] 규제 문구 정책 확정
- [ ] 데이터 사전 작성
- [ ] 원료 표준명 체계 설계
- [ ] 단위 표준화 규칙 정의
- [ ] 소스별 접근 전략 확정 (api / browser_agent / hybrid)

### Phase 1: MVP-Core + MVP-Pipeline (5~10주)
**서비스 기반 (5~8주)**
- [ ] Next.js + TypeScript + Tailwind 프로젝트 초기화
- [ ] PostgreSQL DDL 적용 (MVP-Core 10개 + 지원 4개 테이블)
- [ ] 1차 원료 20종 수동 데이터 입력
- [ ] 원료 목록/상세 페이지 구현
- [ ] 기본 검색 기능
- [ ] 의료 면책 조항 페이지

**수집 기반 (8~10주)**
- [ ] `source_connectors` + `raw_documents` + `extraction_results` 테이블 적용
- [ ] API 커넥터 프레임워크 구축
- [ ] 식품안전나라/공공데이터 API 연동
- [ ] PubMed E-utilities 수집기 개발
- [ ] Raw-first 수집 파이프라인 (원문 보존 → 파싱 → 신뢰도 평가)

### Phase 2: 자동화 + 제품 비교 (11~16주)
**수집 자동화**
- [ ] `collection_jobs` + `collection_runs` 테이블 적용
- [ ] `refresh_policies` + `entity_refresh_states` 테이블 적용
- [ ] Airflow/Prefect 연동 (refresh_policies 동적 스케줄)
- [ ] 변경 감지 로직 (checksum → semantic diff → review_tasks)
- [ ] DSLD/DailyMed 수집기 개발
- [ ] 브라우저 에이전트 프레임워크 구축

**정규화/매핑**
- [ ] 동의어 사전 구축
- [ ] 단위 변환 로직 구현
- [ ] 원료-기능성 연결 정제
- [ ] 원료-논문 연결 정제

**제품 기능**
- [ ] 제품 데이터 입력 (인기 제품 30~50개)
- [ ] 제품 목록/상세 페이지
- [ ] 제품 비교 도구 (나란히 비교)
- [ ] 성분 중복 경고 로직

### Phase 3: 근거 평가 + 개인화 (17~20주)
- [ ] 논문 스크리닝 기준 수립
- [ ] 근거 등급 규칙 구현
- [ ] 관리자 검수 UI (review_tasks 기반)
- [ ] 내 영양제함 기능 (localStorage)
- [ ] 총 영양소 합산 대시보드
- [ ] 과다 복용 경고 시스템
- [ ] 상호작용 조회 기능

### Phase 4: 고도화 + 품질 개선 (21~24주)
- [ ] OpenSearch 검색 엔진 도입
- [ ] 재평가 문서 반영 자동화 (event-driven refresh)
- [ ] 안전성 정보 강화 (openFDA 연동)
- [ ] targeted refresh (인기 원료 우선 갱신)
- [ ] 데이터 확장 (원료 50종+, 제품 100개+)
- [ ] SEO 최적화
- [ ] PWA 지원

---

## 16. 인력 구성

### 최소 팀
| 역할 | 인원 | 비고 |
|------|------|------|
| PM | 1 | 전체 일정·품질 관리 |
| 백엔드 | 1 | API, ETL, DB |
| 프론트엔드 | 1 | Next.js 웹 UI |
| 데이터 엔지니어 | 1 | 수집·정규화·매핑 |
| 의학/약학 감수 | 1~2 | 근거 평가, 부작용 검증 |
| 규제(RA) 자문 | 1 | 허용 표현 검토 |
| 콘텐츠 에디터 | 1 | 원료 페이지 작성 |

> **의료감수 없이 가면 정확도보다도 표현 리스크가 먼저 터진다.**

---

## 17. 핵심 설계 원칙 7가지

1. **제품보다 원료를 중심으로 설계** — `ingredient_id`가 모든 것의 중심축
2. **국내 규제 문구와 학술 근거를 분리** — 규제 리스크 차단
3. **자발보고 부작용은 신호로만 표시** — 발생빈도로 오해 방지
4. **모든 값에 출처와 갱신일을 남김** — 신뢰성 확보
5. **자동화 + 전문가 검수 혼합 체계** — 확장성과 정확성 동시 확보
6. **Raw-first 수집** — 운영 DB에 바로 쓰지 않고, 항상 원문 보존 후 파싱 (재처리 가능)
7. **Confidence-based publishing** — 자동 추출 결과를 신뢰도 기반으로 게시/검수 분기

---

## 다음 단계

이 계획이 확정되면 다음 순서로 진행:
1. Next.js 프로젝트 초기화 + TypeScript 타입 정의
2. PostgreSQL DDL 적용 (MVP-Core)
3. 1차 원료 20종 데이터 구축 시작
4. 원료 목록/상세 페이지 구현
