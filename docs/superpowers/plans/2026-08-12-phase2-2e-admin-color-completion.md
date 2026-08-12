# Phase 2-2e: 브랜드 오렌지 통일 + 잔여 색 소거 + admin 마이그레이션 (Phase 2 완결) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사용자 확정 사항(로고·내비 활성색 **오렌지 통일**)을 반영해 그린 계열을 소거하고, slate/gray 잔여 14파일을 토큰화하며, 마지막 페이지인 admin data-health를 마이그레이션한다. 완료 시 Phase 2의 "하드코딩 색상 제거" 기준이 design-lab 제외 전역에서 성립한다.

**Architecture:** 시맨틱 success 토큰을 신설해 상태 삼색(정상/주의/위험)의 구분을 복원하고, 브랜드 그린은 전부 오렌지 계열로, 중립 회색은 stone/ink로. admin은 스펙 §4 규칙(토큰·프리미티브 상속만, 밀도 유지) + 가벼운 데이터 함수 추출.

**Tech Stack:** Next.js 16, Phase 2-0 디자인 시스템, vitest.

## Global Constraints

- 브랜치: `feat/redesign-admin-cleanup` (main f1744cd에서 분기, 체크아웃됨). main 직접 커밋 금지.
- 커밋: conventional + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 명시적 경로 스테이징(스윕 태스크는 `git status` 확인 후 `git add web/src` 허용).
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build` 통과 (Task 4는 lint 포함).
- 색상 전용 변경 — 로직·카피·레이아웃 불변 (admin의 명시된 함수 추출 제외). 규제/근거/주의는 도메인 배지 전용. 신규 raw hex는 globals.css 토큰 정의부에서만 허용.
- `design-lab/page.tsx` 제외 유지(레거시 목업). `translate` 문자열의 "slate" 오탐은 감사에서 제외 처리.
- 사용자 확정: 로고 텍스트·내비/모바일 활성색 → orange-700 계열. 브랜드 그린 전면 폐지.
- 환경: 셸 `cd` zoxide 경유 — 단일 복합 명령. `[slug]`/`[category]`/`[id]` 경로 따옴표 필수.

## 색상 매핑 규칙

- 브랜드 그린(로고 `text-green-600`, 내비 hover/활성, footer, not-found 링크, probiotics/products 액센트) → `text-orange-700` / hover `hover:text-orange-700` / bg 필요 시 `bg-brand-bg`
- **success 시맨틱**(admin '정상' 상태, claims-section 허용 표현 박스 등 "긍정 확인" 의미) → 신설 토큰 `--color-success` `#15803d` / `--color-success-bg` `#f0fdf4` (globals.css `@theme`에 추가; 상태 삼색 = success 그린 / 주의 amber / 위험 danger 레드로 구분 복원)
- strain-benefit-comparison 탭 필(active `border-green-600 bg-green-600 text-white`) → 카테고리 칩과 동일한 오렌지 패턴(`border-orange-700 bg-orange-700 text-white`)
- slate/gray → stone/ink 표준 매핑(text-gray-900→text-ink, 500→ink-muted, 400→ink-faint, border/bg는 stone 등가)
- benefit-hexagon의 raw `rgb()`/`rgba()` SVG 색 → globals.css에 차트용 CSS 변수(`--chart-*`) 정의 후 `var(--chart-*)` 참조 (색값 자체는 동일 유지 — 시각 무변화)

---

### Task 1: success 토큰 신설 + 그린 스윕 (7파일)

**Files:**
- Modify: `web/src/app/globals.css` (`--color-success`, `--color-success-bg` 추가)
- Modify: `web/src/components/layout/header.tsx`(로고 27, 내비 37/39/127), `footer.tsx`, `web/src/app/not-found.tsx`, `web/src/app/products/[id]/page.tsx`, `web/src/app/probiotics/page.tsx`, `web/src/components/probiotic/strain-benefit-comparison.tsx`(탭 필·hover), `web/src/components/ingredient/claims-section.tsx`(허용 표현 박스 → success 토큰)

- [ ] **Step 1:** 토큰 추가 → 매핑 규칙대로 7파일 스윕. "긍정 확인" 의미(허용 표현 등)는 success, 브랜드/액션 의미는 오렌지 — 파일별 판단을 레포트에 기록
- [ ] **Step 2:** 감사 `grep -rn "green-" web/src --include="*.tsx" | grep -v design-lab` → 출력 없음
- [ ] **Step 3:** 게이트 → Commit `git add web/src`(status 확인 후):
  `refactor: unify brand accent to orange; add success token for status semantics`

---

### Task 2: slate/gray 잔여 스윕 (admin 제외 전 파일)

**Files:**
- Modify: Task 3이 다루는 `admin/data-health`를 **제외한** slate/gray 잔여 전부 — `app/page.tsx`, `not-found.tsx`, `products/[id]/page.tsx`, `disclaimer/page.tsx`, `probiotics/page.tsx`, `ui/state-message.tsx`, `ui/skeleton.tsx`, `layout/footer.tsx`, `layout/header.tsx`, `ingredient/ingredient-category-card.tsx`, `benefit/benefit-hexagon.tsx`(+발견분)

- [ ] **Step 1:** 표준 매핑으로 스윕(색상 전용). state-message/skeleton 같은 공용 프리미티브는 전 사용처에 영향 — 시각 등가(gray↔stone은 근접 색조) 확인 메모
- [ ] **Step 2:** benefit-hexagon raw rgb → `--chart-*` CSS 변수화(동일 색값, globals.css 정의)
- [ ] **Step 3:** 감사 `grep -rn "slate-\|gray-" web/src --include="*.tsx" | grep -v design-lab | grep -v "translate"` → 출력 없음
- [ ] **Step 4:** 게이트 → Commit `git add web/src`(status 확인 후):
  `refactor: tokenize remaining slate/gray surfaces; chart colors via CSS vars`

---

### Task 3: admin data-health 마이그레이션

**Files:**
- Create: `web/src/lib/admin/data-health.ts` — 페이지의 데이터 함수(getX() 류)와 config 맵(테이블 목록·라벨·임계값 등)을 이동. **Drizzle adminDb 사용 유지**(admin은 service_role 규칙 — RLS 클라이언트로 바꾸지 말 것)
- Modify: `web/src/app/admin/data-health/page.tsx` (558줄 → 데이터·설정 추출 후 표시 전용, 목표 ≤300줄) — stone/ink 토큰 + 상태 삼색(success/amber/danger 토큰), 밀도 높은 테이블 레이아웃 유지(장식 최소 — 스펙 §4 admin 규칙). Card/Badge 프리미티브는 자연스러운 곳만

- [ ] **Step 1:** 데이터 함수·config 추출(동작 불변, 시그니처 그대로) → 페이지 rewire
- [ ] **Step 2:** UI 토큰화 — '정상'=success, '주의'=amber, '위험/실패'=danger로 삼색 구분 복원(2-2d 리뷰 지적 해소). font-mono 사용처는 유지(Tailwind 기본 mono 스택 — 별도 토큰 불필요 판단, 레포트에 기록)
- [ ] **Step 3:** 게이트 → Commit `git add web/src/lib/admin web/src/app/admin`:
  `feat: admin data-health on design tokens with extracted data layer`

---

### Task 4: 전체 게이트 + Phase 2 색상 완결 감사

- [ ] **Step 1:** `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint` — 전부 통과
- [ ] **Step 2:** 최종 감사(전부 출력 없음이어야 함, design-lab·translate 오탐 제외):
  - `grep -rn "green-\|emerald\|slate-\|gray-" web/src --include="*.tsx" | grep -v design-lab | grep -v translate`
  - `grep -rnE "#[0-9a-fA-F]{3,8}|rgb\(" web/src/components web/src/app --include="*.tsx" | grep -v design-lab` (히트 시 사유 기록 — 토큰 정의 참조 제외)
- [ ] **Step 3:** `wc -l web/src/app/admin/data-health/page.tsx` 기록
- [ ] **Step 4:** 커밋 없음(검증 전용). 결과를 "Phase 2 색상 완결" 선언 근거로 레포트에 정리
