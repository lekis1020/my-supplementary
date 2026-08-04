# 유산균 균주별 효능 비교 페이지 — 설계 문서

- **작성일**: 2026-08-04
- **상태**: 승인됨 (설계 확정, 구현 계획 대기)
- **범위**: 신규 페이지 `/probiotics` — 유산균 균주별 효능 비교 (효능 우선 뷰)

## 1. 배경 · 목적

유산균(프로바이오틱스)은 다른 원료와 달리 **균주(strain) 단위로 유효 효과가 크게 다르다**. 소비자는 대개 목적(장 건강, 면역, 체지방 등)을 갖고 접근하지만, 기존 원료 상세 페이지(`ingredients/[slug]`)는 부모/자식 균주 근거를 하나의 평면 리스트로 병합해 보여줄 뿐, **"어떤 균주가 어떤 효능에 강한지"를 나란히 비교하는 뷰가 없다.**

이 작업은 **새 데이터 수집이 아니라, 이미 존재하는 균주×효능×근거등급 데이터를 효능 우선 비교 뷰로 재조립**하는 것이다.

## 2. 기존 자산 (이미 갖춰진 것)

- `ingredients` 테이블에 `probiotics` 부모 원료 아래 **개별 균주 14종**이 `parent_ingredient_id`로 연결되어 존재 (LGG, BB-12, NCFM, BB536, HN001, HN019, 시로타, DSM 17938, LP299v, R0052, R0175, BNR17, S. thermophilus, BGN4). 정의: `db/016_probiotic_strains.sql`.
- 각 균주에 `ingredient_claims` 매핑 존재: `evidence_grade`(A~C), `evidence_summary`, `is_regulator_approved`, `approval_country_code`, `allowed_expression`, `claims`(claim_code) 연결.
- claim 축(claim_code): `GUT_HEALTH`, `IMMUNE_FUNCTION`, `MENTAL_HEALTH`, `WEIGHT_MANAGEMENT`.
- 균주별 `evidence_studies`, `source_links`, `product_ingredients` 연결도 존재.
- 부모 미연결 균주 보강 마이그레이션: `db/026_backfill_probiotic_parent_mapping.sql`.

## 3. 설계 결정 (확정)

### 3.1 진입 관점: 효능(증상) 우선
효능을 먼저 고르면, 그 효능에 강한 균주들이 근거 순으로 나열된다. 소비자 실제 사용 패턴에 부합.

### 3.2 배치: 신규 전용 페이지 `/probiotics`
- 서버 컴포넌트. 기존 `ingredients/[slug]`와 동일한 `@supabase/ssr` + RLS(`is_published = TRUE` 자동 적용) 패턴.
- 진입 동선: 랜딩(`/`)과 `/ingredients/probiotics` 상세에 "균주별 효능 비교" 진입 카드/버튼 추가.

### 3.3 화면 구조
```
유산균, 균주에 따라 효과가 다릅니다   [설명 한 줄 + 등급/배지 범례]

[ 장건강 ] [ 면역 ] [ 정신건강 ] [ 체지방 ]   ← 효능 탭(pill)
                                              (균주 보유한 효능만 노출)
─────────────────────────────────────────────
장건강  (기본 선택 · 균주 수 최다)

┌ LGG (L. rhamnosus GG) ────────── [근거 A] [식약처 인정] ┐
│  AAD 예방 ESPGHAN 권장, 급성설사 1일 단축, 300+ RCT      │
│  허용표현: 유익균 증식 및 유해균 억제에 도움             │
│  권장 1~100억 CFU/일                                      │
└──────────────────────────────────────────────────────────┘
...
```

- **효능 축 4종**: 장건강(GUT_HEALTH)·면역(IMMUNE_FUNCTION)·정신건강(MENTAL_HEALTH)·체지방(WEIGHT_MANAGEMENT). **실제 균주 claim이 존재하는 축만 렌더** (0건 축은 탭 미노출).
- **기본 선택 탭**: 균주 수가 가장 많은 축(현재 데이터상 장건강).

### 3.4 균주 행 구성 (표시 요소)
각 행에 세 요소 노출 (모두 기존 컬럼, 신규 수집 없음):
1. **근거등급 + 식약처 인정 배지** — `evidence_grade` + `is_regulator_approved`.
2. **한 줄 근거 요약 + 허용표현** — `evidence_summary` + `allowed_expression`.
3. **권장 CFU 용량** — `form_description` / `standardization_info`에서 CFU 문자열.

- **균주명은 상세페이지(`/ingredients/[slug]`) 링크**로 (기본 네비게이션). 행별 제품 링크는 이번 범위 밖.

### 3.5 정렬 (효능 탭 내부)
① 식약처 인정 우선 → ② 근거등급 A > B > C → ③ 균주명(가나다).
목적: 위→아래로 읽으면 "이 효능에 가장 강한 균주" 순.

### 3.6 조합 전용 균주 처리
`L. helveticus R0052` + `B. longum R0175`는 단독이 아닌 **조합으로만 유효**(정신건강). 두 개의 개별 행 대신 **하나의 묶음 행 "L. helveticus R0052 + B. longum R0175 (사이코바이오틱스 조합)"**으로 표기해 "각각 단독으로 작동한다"는 오해를 방지한다. 임상적 정확성상 필수.

## 4. 법적 컴플라이언스 (필수)

CLAUDE.md의 "규제 vs 학술 데이터 분리"는 UI 선호가 아니라 법적 요구사항.
- **식약처 인정(규제)** 배지와 **근거등급(학술)** 표기를 시각적으로 명확히 분리.
- **허용표현(`allowed_expression`)은 식약처 인정 항목에만** 노출.
- 상단에 "근거등급 / 식약처 인정" 읽는 법 범례 1줄.
- 하단에 의료 면책 조항 — 기존 페이지의 면책 블록 컴포넌트/마크업 재사용.
- 비허용 표현은 건강 클레임으로 표시하지 않음.

## 5. 데이터 흐름 · 컴포넌트

### 5.1 데이터 fetch (서버 페이지 `/probiotics/page.tsx`)
1. `probiotics` 루트 id 조회.
2. `ingredients`에서 `parent_ingredient_id = 루트` (+ 루트 자신) 균주 목록 조회 (`is_published = true`).
3. `ingredient_claims` + `claims`를 균주 id 집합으로 조회, claim_code별로 그룹핑.
4. 4개 효능 축으로 재구성 → 각 축 내 균주 배열을 3.5 정렬 규칙으로 정렬.
5. 조합 균주(R0052/R0175)는 정신건강 축에서 병합 처리.
6. 결과를 클라이언트 컴포넌트에 prop으로 전달.

### 5.2 컴포넌트 경계
- **`web/src/app/probiotics/page.tsx`** (서버): 데이터 fetch + 정렬/그룹핑 + 정적 헤더/범례/면책. 클라이언트 컴포넌트에 구조화된 데이터 전달.
- **`StrainBenefitComparison`** (클라이언트, `web/src/components/probiotic/`): 효능 탭 전환 상태 관리 + 선택된 축의 균주 행 렌더.
- **재사용**: `getEvidenceGradeColor`, `getClaimScopeLabel`(필요 시), `Card`/`CardHeader`/`Badge`, `normalizeProbioticStrainNameForDisplay`.

### 5.3 조합/정렬 로직 위치
정렬·그룹핑·조합 병합은 **서버 페이지에서 순수 함수로** 수행(테스트 용이). 클라이언트 컴포넌트는 표시만.

## 6. 범위 밖 (YAGNI)

- 균주 직접 선택형 대조(/compare 방식) — 안 함.
- 균주×효능 전치 매트릭스 뷰 — 안 함.
- 행별 제품 링크 — 안 함(균주명 상세 링크만).
- 새 DB 컬럼/마이그레이션 — 없음(기존 데이터만 사용).

## 7. 테스트 · 검증

- 정렬 순수 함수 단위 테스트: 식약처 인정 우선 → 등급 → 이름 순 확인.
- 조합 병합 함수 단위 테스트: R0052/R0175가 정신건강에서 단일 행으로 병합.
- 축 필터: claim 0건 축은 탭 미노출 확인.
- `npm run build` / `npm run lint` 통과.
- 실제 페이지 렌더: 식약처 인정 배지와 근거등급이 시각적으로 분리, 허용표현이 인정 항목에만 노출, 면책 조항 존재.

## 8. 진입 동선 (부수 변경)

- `/ingredients/probiotics` 상세: "균주별 효능 비교 보기" 카드/버튼 → `/probiotics`.
- 랜딩(`/`): 유산균 비교 진입 카드 (선택, 기존 랜딩 구성에 맞춰).
