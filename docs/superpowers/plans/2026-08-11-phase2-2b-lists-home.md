# Phase 2-2b: 정합성 후속 + 홈·목록 페이지 리디자인 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) 2-2a 최종 리뷰가 지정한 패밀리 페이지 정합성 묶음 + error 경계를 처리하고, (2) 홈·성분 목록·카테고리·제품 목록 4개 페이지를 웜 커머스 디자인 시스템으로 마이그레이션한다.

**Architecture:** 2-2a에서 확립한 패턴 반복 — 공용 카드 컴포넌트(`IngredientCard` 신설, `EnhancedProductCard` 재스타일)를 만들고 페이지는 토큰·프리미티브로 재조립. 데이터 로직 변경은 Task 1의 정합성 수정에 한정.

**Tech Stack:** Next.js 16 App Router, Phase 2-0 디자인 시스템, tailwind-merge된 `cn()`, vitest.

## Global Constraints

- 브랜치: `feat/redesign-lists-home` (main에서 분기, 체크아웃됨). main 직접 커밋 금지.
- 커밋: conventional commits + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 명시적 경로 스테이징 — **`git add -A` 금지**.
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build` 통과 (Task 5는 test/lint 포함).
- 소비자 페이지 RLS 클라이언트 유지; 쿼리 필터·정렬 의미 불변 (Task 1의 명시된 select 확장 제외).
- 규제/근거/주의 표시는 도메인 배지 전용 (RegulatoryBadge는 `is_regulator_approved===true`에서만 — 2-2a 확립 규칙).
- slate/gray → stone/ink 토큰; 신규 raw hex 금지; UI 문자열 한국어.
- 환경: 셸 `cd`가 zoxide 경유 — 단일 복합 명령. build 수 분 정상. `[slug]`/`[category]` 경로는 따옴표 필수.

---

### Task 1: 패밀리 정합성 묶음 + error 경계 + 사문 정리

**Files:**
- Modify: `web/src/lib/data/ingredient-detail.ts`
- Modify: `web/src/components/ingredient/ingredient-hero.tsx` + `web/src/app/ingredients/[slug]/page.tsx` (countryCode prop 전달)
- Create: `web/src/app/error.tsx`
- Modify: `web/src/lib/utils.ts` (getSeverityColor 삭제)
- Modify(필요 시): `web/src/lib/data/ingredient-detail.test.ts` (summary 로직 테스트 추가)

- [ ] **Step 1: 패밀리 병합 select에 승인 필드 추가**
`ingredient-detail.ts`의 관련 클레임 쿼리(relatedClaims, 좁은 select) 컬럼 목록에 `is_regulator_approved, approval_country_code`를 추가한다. `claims-section.tsx`의 `in`-narrowing 게이트는 필드가 생기면 자동으로 균주 페이지에서도 검증 승인 배지를 렌더한다(코드 변경 불필요 — 확인만). 데이터 의미: select 확장만, 필터·정렬 불변.
- [ ] **Step 2: summary 정합성**
  - `topEvidenceGrade`: 병합된 클레임 집합(mergedIngredientClaims) 기준으로 계산 (evidence_grade는 양쪽 branch에 존재). A>B>C>D>I 규칙 유지.
  - `approvedClaimCount`: **자기 클레임 기준 유지** (2-2a 판정 — 형제 승인으로 부풀리지 않음). Step 1 이후에도 이 원칙 불변.
  - `cautionCount`: `+ vitaminSideEffectInfos.length` (안전 섹션 카운트 배지와 일치).
- [ ] **Step 3: 히어로 배지 countryCode**
자기 승인 클레임들의 `approval_country_code`가 전부 동일하면 그 값을, 혼재/부재면 `undefined`를 `IngredientHero`에 새 prop `approvalCountryCode`로 전달 → `<RegulatoryBadge countryCode={approvalCountryCode} />`.
- [ ] **Step 4: `web/src/app/error.tsx` 생성** (Next 규약상 클라이언트 컴포넌트):

```tsx
"use client";

import { CTAButton } from "@/components/ui/cta-button";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="mx-auto flex max-w-xl flex-col items-center gap-4 px-4 py-24 text-center">
      <h2 className="text-xl font-bold text-ink">일시적인 오류가 발생했습니다</h2>
      <p className="text-sm text-ink-muted">
        데이터를 불러오는 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.
      </p>
      {error.digest && (
        <p className="text-xs text-ink-faint">오류 코드: {error.digest}</p>
      )}
      <CTAButton onClick={reset}>다시 시도</CTAButton>
    </div>
  );
}
```

- [ ] **Step 5: utils.ts에서 `getSeverityColor` 삭제** (참조 0건 재확인 grep 후).
- [ ] **Step 6: 테스트 보강** — summary 계산이 순수 함수로 분리 가능하면 `computeSummary` 형태로 추출해 테스트 3개(최고등급 병합 기준, 승인수 자기 기준, 주의수 비타민 포함) 추가. 분리가 과도하면 생략하고 사유 기록.
- [ ] **Step 7: 게이트** tsc+build → Commit `git add web/src/lib web/src/components/ingredient "web/src/app/ingredients/[slug]" web/src/app/error.tsx`:
  `fix: family-page summary coherence, error boundary, dead helper removal`

---

### Task 2: 공용 IngredientCard + 성분 목록·카테고리 페이지

**Files:**
- Create: `web/src/components/ingredient/ingredient-card.tsx`
- Modify: `web/src/app/ingredients/page.tsx`, `web/src/app/ingredients/category/[category]/page.tsx`

**Interfaces:**
- `IngredientCard({ ingredient })` — `Pick<IngredientRow, "id" | "slug" | "canonical_name_ko" | "canonical_name_en" | "ingredient_type" | "description">` 파생(실사용 필드는 페이지 select 확인 후 확정). `Card` 기반, 이름 `text-ink font-bold`, 타입 `Badge variant="tag"`, 설명 2줄 클램프 `text-ink-muted`, hover `hover:border-brand hover:shadow-card-hover`. `/ingredients/[slug]` 링크.

- [ ] **Step 1:** 두 목록 페이지의 인라인 성분 카드 마크업을 `IngredientCard`로 통일. 카테고리 필터 칩·서브그룹 헤더는 stone/ink 토큰 + `Badge`/`SectionHeader`로 재스타일. 기존 그룹핑 로직(groupIngredients 등)·쿼리·에러 처리(기존 ErrorState) 불변.
- [ ] **Step 2:** 게이트 tsc+build → Commit `git add web/src/components/ingredient web/src/app/ingredients`:
  `feat: shared IngredientCard; ingredient list pages on design system`

---

### Task 3: 제품 목록 페이지 + EnhancedProductCard 재스타일

**Files:**
- Modify: `web/src/components/product/product-card.tsx` (EnhancedProductCard)
- Modify: `web/src/app/products/page.tsx`
- Modify(해당 시): `web/src/components/ui/pagination.tsx` (토큰화만)

- [ ] **Step 1:** `EnhancedProductCard`를 웜 커머스로 재스타일 — `Card` 기반(rounded-2xl·shadow-card), emerald 액센트 → brand(앰버) 액센트, slate → stone/ink. 기존 props 계약(`Pick<ProductRow, ...> & { tags?: string[] }`) 불변. 제품 목록 페이지의 페이지네이션·필터 UI 토큰화. 쿼리·정렬 불변.
- [ ] **Step 2:** 게이트 tsc+build → Commit `git add web/src/components/product web/src/components/ui/pagination.tsx web/src/app/products`:
  `feat: product list and card on design system`

---

### Task 4: 홈 페이지 리디자인

**Files:**
- Modify: `web/src/app/page.tsx` (233줄)

- [ ] **Step 1:** 홈을 웜 커머스로 재조립 — 히어로(검색 CTA 중심, `bg-canvas` 위 `Card tone="highlight"` 또는 그라데이션 배너), 카테고리 진입 카드(`Card` + 아이콘 + `Badge variant="tag"`), 주요 CTA는 `CTAButton`. 기존 검색 폼 액션·링크 구조·데이터 쿼리 불변(있다면). 카피 변경 최소화(기존 문구 유지).
- [ ] **Step 2:** 게이트 tsc+build → Commit `git add web/src/app/page.tsx`:
  `feat: home page on warm commerce design system`

---

### Task 5: 전체 게이트 + 회귀 확인

- [ ] **Step 1:** `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint`
  Expected: 테스트 전부 통과(23 + Task 1 신규), tsc 0, 빌드 성공(전 라우트), lint 0 에러.
- [ ] **Step 2:** 토큰 위반 감사: `grep -rn "slate-\|gray-" web/src/app/page.tsx web/src/app/ingredients/page.tsx "web/src/app/ingredients/category/[category]" web/src/app/products/page.tsx web/src/components/ingredient/ingredient-card.tsx web/src/components/product/product-card.tsx` → 출력 없음 (예외 발견 시 사유 기록).
- [ ] **Step 3:** 잔여 구 색상 헬퍼 사용처 기록: `grep -rn "getEvidenceGradeColor\|getStudyDesignColor" web/src | grep -v node_modules` (probiotic 비교 컴포넌트 등 잔존 예상 — 삭제 금지, 다음 마이그레이션 대상 목록만 레포트에 기록).
- [ ] **Step 4:** 커밋 없음(검증 전용). 실패 시 원인 수정 후 재실행.
