# Phase 2-2c: 비교 페이지 재편 (compare-workbench 분해 + 웜 커머스) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `web/src/components/product/compare-workbench.tsx`(1,140줄 클라이언트 god component)를 순수 로직 lib + 공유 훅 + 프레젠테이션 컴포넌트로 분해하고, 초기 데이터 로드를 서버로 옮기며, 웜 커머스 디자인을 적용한다.

**Architecture:** 순수 계산(단위 정규화·비교 행·균주 그룹)은 `lib/compare/*`로, localStorage 접근은 3개 컴포넌트가 공유하는 훅으로, 전체 상품 목록은 `/compare` 서버 컴포넌트가 한 번 페치해 prop으로. 워크벤치는 선택 상태 + 성분 페치만 소유하는 얇은 클라이언트 셸이 된다. 각 태스크 종료 시 빌드·기존 동작 보존.

**Tech Stack:** Next.js 16, Supabase RLS(server+browser), Phase 2-0 디자인 시스템, vitest.

## Global Constraints

- 브랜치: `feat/redesign-compare` (feat/redesign-lists-home 위 스택, 체크아웃됨). main 직접 커밋 금지.
- 커밋: conventional + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 명시적 경로 스테이징 — **`git add -A` 금지**.
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build` 통과 (Task 5는 test/lint 포함).
- **동작 보존이 최우선**: URL `?ids=` ↔ localStorage 하이드레이션 순서·정규화(normalizeCompareIds)·최대 4개 제한·비교 수학·균주 그룹핑 결과가 변하면 안 됨. 명시 허용된 변경만: 초기 상품 로드 서버화, 성분 페치 `.in()` 일괄화, eslint-disable(exhaustive-deps) 제거를 위한 effect 정리.
- 소비자 쿼리는 RLS 클라이언트만 (서버=`@/lib/supabase/server`, 브라우저=`@/lib/supabase/client`).
- slate/gray/emerald → stone/ink/앰버 토큰(재스타일 대상 파일 한정); 신규 raw hex 금지; 규제/근거/주의는 도메인 배지 전용; UI 카피 불변.
- 환경: 셸 `cd`가 zoxide 경유 — 단일 복합 명령. build 수 분 정상.

## 현재 구조 (이동 지도, compare-workbench.tsx 1,140줄)

- L30 `buildProductIngredientsQuery`(런타임+QueryData 겸용) · L108 `sortProductsByName`
- L118~604 메인 컴포넌트: useEffect 4개(165 URL/스토리지 하이드레이션, 216, 247, 255 — 그중 하나에 exhaustive-deps disable), 브라우저 1,000행 배치 상품 페치, per-product 순차 성분 페치
- 프레젠테이션: `ComparisonSection`(605) · `AmountCell`(721) · `SummaryCard`(788) · `EmptySection`(820) · `ProbioticStrainSection`(828)
- 순수 로직: `buildProbioticStrainGroups`(905) · `buildComparisonRow`(1015) · `normalizeAmount`(1061) · `parseNumericValue`(1084) · `resolveIngredientAmount`(1092) · `normalizeUnit`(1109) + 단위 계수 테이블(파일 상단 ~93–110)
- 연관 파일: `app/compare/page.tsx`(5줄 래퍼) · `compare-actions.tsx`(93) · `compare-summary.tsx`(176) · `layout/header.tsx`(190) — 셋 다 COMPARE_STORAGE_KEY localStorage 로직 자체 구현

---

### Task 1: 순수 로직 추출 — `lib/compare/units.ts` + `compare-math.ts` (+테스트)

**Files:**
- Create: `web/src/lib/compare/units.ts` — `normalizeAmount`, `parseNumericValue`, `normalizeUnit`, `resolveIngredientAmount`, 단위 계수 테이블, `NormalizedAmount` 타입 이동(그대로)
- Create: `web/src/lib/compare/compare-math.ts` — `buildComparisonRow`, `buildProbioticStrainGroups`, `sortProductsByName` 이동. 타입 의존(Product/ProductIngredient/IngredientComparisonRow 등)은 함께 이동하거나 제네릭 구조 타입으로 — 컴포넌트가 lib을 import하지, 역방향 금지
- Create: `web/src/lib/compare/units.test.ts` — normalizeUnit 환산(mg↔g↔µg, IU 등 실제 테이블 기준), parseNumericValue(콤마·범위·null), normalizeAmount 대표 케이스 5개+ (구현을 읽고 실동작 기준 단언 — 구현을 테스트에 맞추지 말 것)
- Modify: `web/src/components/product/compare-workbench.tsx` (import 교체, 이동분 삭제)

- [ ] **Step 1:** 이동 + import 교체 (동작·시그니처 불변, 코드 수정 없이 이동만)
- [ ] **Step 2:** 테스트 작성·실행 → 전체 게이트 tsc+build+`npm test`
- [ ] **Step 3:** Commit `git add web/src/lib/compare web/src/components/product/compare-workbench.tsx`:
  `refactor: extract compare units and math into lib with tests`

---

### Task 2: 공유 `useCompareStorage` 훅

**Files:**
- Create: `web/src/lib/compare/use-compare-storage.ts` — `"use client"` 훅. 계약:

```ts
export const COMPARE_STORAGE_KEY = "..."; // 기존 키 문자열 그대로 이동
export function normalizeCompareIds(input: unknown): number[]; // 기존 정규화 로직 이동 (최대 4개 등)
export function useCompareStorage(): {
  ids: number[];
  setIds: (ids: number[]) => void;   // 상태+localStorage 동기 기록
  isLoaded: boolean;                  // 최초 read 완료 여부 (SSR 하이드레이션 안전)
};
```

- Modify: `compare-workbench.tsx`, `compare-actions.tsx`, `layout/header.tsx` — 각자의 localStorage read/parse/try-catch 중복을 훅/헬퍼 호출로 교체

- [ ] **Step 1:** 세 파일의 기존 구현을 비교해 공통 의미를 훅으로 통합. 차이가 있으면(예: header는 read-only 카운트) 훅 반환값 사용 방식으로 해소 — 각 파일의 관찰 가능 동작 불변. 워크벤치의 URL `?ids=` 우선 하이드레이션 순서는 워크벤치에 남긴다(훅은 스토리지만 담당).
- [ ] **Step 2:** 게이트 tsc+build → Commit `git add web/src/lib/compare web/src/components/product web/src/components/layout/header.tsx`:
  `refactor: shared useCompareStorage hook across workbench, actions, header`

---

### Task 3: 서버 초기 로드 + 성분 일괄 페치 + effect 정리

**Files:**
- Modify: `web/src/app/compare/page.tsx` — 서버 컴포넌트로 전체 상품 목록(현재 워크벤치가 브라우저에서 1,000행 배치로 가져오는 것과 동일 컬럼·필터·정렬) 페치 후 `<CompareWorkbench initialProducts={...} />`로 전달. 에러는 throw(error.tsx 경계 활용)
- Modify: `compare-workbench.tsx` — 브라우저 전체 상품 페치 useEffect 제거(initialProducts prop 사용); per-product 순차 성분 페치를 단일 `.in("product_id", selectedIds)` 쿼리로 교체(`buildProductIngredientsQuery` 시그니처를 ids 배열로 변경 또는 새 빌더); exhaustive-deps disable 제거되도록 effect 의존성 정리

- [ ] **Step 1:** 서버 페치 이동 — 컬럼·필터·정렬 동일성 명시 확인(레포트에 before/after select 기록). missing-id 백필 로직 등 워크벤치 잔여 로직은 initialProducts 기준으로 동작 유지
- [ ] **Step 2:** 성분 페치 일괄화 — 결과를 productId별로 그룹핑해 기존 상태 구조 유지. 로딩 상태 의미 보존
- [ ] **Step 3:** `grep -n "eslint-disable" web/src/components/product/compare-workbench.tsx` → exhaustive-deps 관련 출력 없음
- [ ] **Step 4:** 게이트 tsc+build → Commit `git add web/src/app/compare web/src/components/product/compare-workbench.tsx`:
  `refactor: server-side initial products and batched ingredient fetch for compare`

---

### Task 4: 프레젠테이션 분해 + 웜 커머스 재스타일

**Files:**
- Create: `web/src/components/product/compare/comparison-section.tsx`, `amount-cell.tsx`, `summary-card.tsx`, `empty-section.tsx`, `probiotic-strain-section.tsx` — L605~904 서브컴포넌트 이동. `ComparisonSection`과 `ProbioticStrainSection`의 유사 그리드 마크업이 실제로 겹치면 공용 `comparison-table.tsx`로 통합(겹침이 표면적이면 무리하게 통합하지 말고 사유 기록)
- Modify: `compare-workbench.tsx`(이동분 삭제·import), `compare-summary.tsx`, `compare-actions.tsx`(토큰화)

- [ ] **Step 1:** 이동 + 재스타일 — slate/emerald/blue 액센트 → stone/ink/앰버 토큰, 섹션 헤더 반복 패턴은 `SectionHeader`, 근거 등급 표시가 있으면 `EvidenceGradeBadge`, 차이 강조는 앰버 하이라이트(`bg-brand-bg` 계열). 하이라이트 로직(highlighted prop 등) 의미 불변
- [ ] **Step 2:** 게이트 tsc+build → Commit `git add web/src/components/product`:
  `feat: compare sections on design system`

---

### Task 5: 전체 게이트 + 감사

- [ ] **Step 1:** `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint` — 전부 통과(테스트 26 + Task 1 신규)
- [ ] **Step 2:** `wc -l web/src/components/product/compare-workbench.tsx` 기록 (목표 ≤400줄)
- [ ] **Step 3:** 토큰 감사: `grep -rn "slate-\|gray-\|emerald" web/src/components/product web/src/app/compare | grep -v node_modules` → 출력 없음(예외 시 사유 기록)
- [ ] **Step 4:** 커밋 없음(검증 전용)
