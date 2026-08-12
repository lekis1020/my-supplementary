# Phase 2-2d: 검색 페이지 재편 + 색상 잔업 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) `/search`(725줄)의 랭킹 로직을 lib으로 추출·테스트하고 페이지를 분해·재스타일, (2) 페이지네이션 헬퍼 중복(products↔search) 통합, (3) emerald 잔여 색상 일괄 정리 + `strain-benefit-comparison` 마이그레이션으로 구 색상 헬퍼를 최종 삭제한다.

**Architecture:** 2-2a~c 패턴 반복 — 순수 로직은 `lib/search/`·`lib/pagination.ts`로, 결과 섹션은 `components/search/`로, 색상은 확립된 매핑(slate/gray→stone/ink, emerald/blue 액센트→앰버 계열, 규제/근거는 도메인 배지)으로.

**Tech Stack:** Next.js 16, Supabase RLS, Phase 2-0 디자인 시스템, vitest.

## Global Constraints

- 브랜치: `feat/redesign-search` (main에서 분기, 체크아웃됨). main 직접 커밋 금지.
- 커밋: conventional + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 명시적 경로 스테이징 — **`git add -A` 금지**.
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build` 통과 (Task 4는 lint 포함).
- 동작 보존: 검색 쿼리·랭킹 점수·중복 제거·페이지네이션 결과 불변(순수 이동). DB로 랭킹을 내리는 작업(pg_tsvector)은 이 플랜 범위 밖.
- 색상 매핑: slate/gray→stone/ink, emerald→앰버 계열(텍스트 액센트는 orange-700, 하이라이트는 bg-brand-bg), 규제/근거/주의는 도메인 배지 전용. 신규 raw hex 금지. UI 카피 불변.
- **의도적 제외**: `/products` 임베디드 선택기 서버 이관은 /compare TTFB 측정 결과가 패턴(전체 목록 vs 타입어헤드)을 결정하므로 보류. `web/src/app/design-lab/page.tsx`는 레거시 목업 샌드박스라 emerald 정리에서 제외(주석으로 명시).
- 환경: 셸 `cd`가 zoxide 경유 — 단일 복합 명령. `[slug]`/`[category]` 경로 따옴표 필수.

## 검색 페이지 구조 지도 (725줄, 2026-08-12 기준)

- L21-58: 상수(PAGE_SIZE, PAGINATION_VISIBLE_COUNT, PROBIOTIC_QUERY_KEYWORDS 등)
- 헬퍼: getSearchParam(59) · parsePage(66) · buildSearchHref(71) · getPaginationPages(82) · normalizeSearchToken(103) · isGenericProbioticQuery(108) · includesProbioticKeyword(115) · getIngredientMatchKind(124) · buildIngredientSearchResult(156) · getIngredientMatchScore(195)
- SearchPage(247-589): 쿼리 + 인메모리 랭킹/필터/중복제거/페이지네이션 + JSX
- IngredientResultSection(590) · ProductResultSection(642)
- 참고: `web/src/app/products/page.tsx`에 `getPaginationPages`/`parsePage`가 byte-동일 복사본으로 존재(초기 리뷰 B5 finding)

---

### Task 1: 랭킹·페이지네이션 lib 추출 (+테스트)

**Files:**
- Create: `web/src/lib/search/ingredient-ranking.ts` — normalizeSearchToken, isGenericProbioticQuery, includesProbioticKeyword, getIngredientMatchKind, buildIngredientSearchResult, getIngredientMatchScore, PROBIOTIC_QUERY_KEYWORDS 이동(그대로; 제네릭 구조 타입 유지)
- Create: `web/src/lib/pagination.ts` — getPaginationPages, parsePage 이동. **search와 products 양쪽 페이지가 이걸 import**하고 각자의 로컬 복사본 삭제 (동일성 diff로 먼저 확인 — 다르면 차이를 레포트에 기록하고 각자 유지한 채 BLOCKED 보고)
- Create: `web/src/lib/search/ingredient-ranking.test.ts` — 매치 종류(정확/부분/영문/학명), 점수 순서(구현 기준), 프로바이오틱 일반질의 판정, 토큰 정규화 엣지 6개+ (구현을 읽고 실동작 기준 단언)
- Create: `web/src/lib/pagination.test.ts` — 페이지 범위 생성(시작/중간/끝/1페이지), parsePage(음수·NaN·문자열)
- Modify: `web/src/app/search/page.tsx`, `web/src/app/products/page.tsx` (import 교체·로컬 복사 삭제)

- [ ] **Step 1:** 이동 + 양 페이지 rewire (buildSearchHref는 검색 전용이라 페이지에 남김)
- [ ] **Step 2:** 테스트 작성·실행 → 게이트
- [ ] **Step 3:** Commit `git add web/src/lib web/src/app/search web/src/app/products`:
  `refactor: extract search ranking and shared pagination libs with tests`

---

### Task 2: 검색 페이지 분해 + 재스타일

**Files:**
- Create: `web/src/components/search/ingredient-result-section.tsx`, `product-result-section.tsx` (L590~ 두 섹션 이동; props는 기존 JSX가 요구하는 대로 — 2-2 시리즈 선례상 브리프보다 넓은 props 허용)
- Modify: `web/src/app/search/page.tsx` — 섹션 교체 + 페이지 크롬(검색 헤더·필터 토글·빈 상태·페이지네이션 UI) 재스타일. 결과 카드에 근거 등급이 노출되면 `EvidenceGradeBadge`, 섹션 제목은 `SectionHeader`(카운트 카피 "{n}개" 규약 유지 — 2-2c 교훈: SectionHeader count prop은 bare number이므로 인라인 Badge로), slate/gray/emerald→토큰

- [ ] **Step 1:** 이동 + 재스타일 (검색 로직·쿼리·정렬 무변경)
- [ ] **Step 2:** 게이트 → Commit `git add web/src/components/search web/src/app/search`:
  `feat: search page on design system with extracted result sections`

---

### Task 3: emerald 일괄 정리 + strain-benefit-comparison 마이그레이션 + 구 헬퍼 삭제

**Files:**
- Modify: emerald 잔존 파일 일괄 (2026-08-12 grep 기준, design-lab/page.tsx 제외): `products/[id]/page.tsx`, `probiotics/page.tsx`, `ingredients/category/[category]/page.tsx`(필터 칩 active), `admin/data-health/page.tsx`, `layout/header.tsx`, `probiotic/strain-benefit-comparison.tsx`, `ingredient/ingredient-category-card.tsx`, `search/search-combobox.tsx`, `ingredient/ingredient-hero.tsx`(프로바이오틱 배너·프로폴리스 카드), `benefit/benefit-hexagon.tsx` (+ Task 2 이후 search/page.tsx에 잔존 시)
- Modify: `web/src/components/probiotic/strain-benefit-comparison.tsx` — emerald 정리와 함께 `getEvidenceGradeColor` 사용을 `EvidenceGradeBadge`로, `getStudyDesignColor`(사용 시)를 `Badge variant="outline"`로 교체
- Modify: `web/src/lib/utils.ts` — 교체 후 `getEvidenceGradeColor`/`getStudyDesignColor` 참조 0건 확인 뒤 **삭제** (0건이 아니면 남기고 레포트에 사용처 기록)

- [ ] **Step 1:** 매핑 규칙으로 일괄 치환 — 기계적 색상 전환만, 로직·카피 무변경. 시맨틱 판단이 필요한 곳(예: 성공/확인 의미의 emerald)은 앰버가 아니라 의미 유지가 맞는지 판단해 레포트에 기록(예: "판매 확인" 류는 brand 계열로)
- [ ] **Step 2:** `grep -rn "emerald" web/src --include="*.tsx" | grep -v design-lab` → 출력 없음
- [ ] **Step 3:** 게이트 → Commit `git add web/src`(이 태스크만 광범위 스테이징 허용 — 단 `git status`로 대상 외 파일 미포함 확인 후):
  `refactor: sweep emerald accents to warm tokens; retire legacy color helpers`

---

### Task 4: 전체 게이트 + 감사

- [ ] **Step 1:** `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint` — 전부 통과(테스트 54 + 신규)
- [ ] **Step 2:** 감사: `grep -rn "emerald\|getEvidenceGradeColor\|getStudyDesignColor\|getSeverityColor" web/src | grep -v design-lab | grep -v node_modules` → 출력 없음; `grep -rn "getPaginationPages" web/src/app | grep -v "lib/pagination"` → import 문만
- [ ] **Step 3:** `wc -l web/src/app/search/page.tsx` 기록 (목표 ≤300줄)
- [ ] **Step 4:** 커밋 없음(검증 전용)
