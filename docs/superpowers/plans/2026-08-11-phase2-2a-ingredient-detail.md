# Phase 2-2a: 성분 상세 페이지 재편 (구조 분해 + 웜 커머스 적용) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `web/src/app/ingredients/[slug]/page.tsx`(1,157줄)를 데이터 계층 + 섹션 컴포넌트로 분해하면서 확정된 디자인(히어로+요약 대시보드, CollapsibleSection, 도메인 배지)을 적용한다. 최종 페이지 셸 ≤200줄.

**Architecture:** 데이터는 `lib/data/ingredient-detail.ts`(+`ingredient-family.ts`)의 `getIngredientDetail(slug)` 한 함수로 모으고(쿼리 병렬화·에러 throw), JSX는 `components/ingredient/*` 섹션 컴포넌트로 이동하며 이동 시점에 새 디자인 시스템으로 재스타일한다. 태스크마다 페이지가 빌드·렌더 가능해야 한다(점진 교체).

**Tech Stack:** Next.js 16 App Router(서버 컴포넌트), Supabase RLS 클라이언트(`@/lib/supabase/server`), Phase 2-0 디자인 시스템(`@/components/ui/*`), vitest.

## Global Constraints

- 브랜치: `feat/redesign-ingredient-detail` (main에서 분기, 체크아웃됨). main 직접 커밋 금지.
- 커밋: conventional commits + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 스테이징은 명시적 경로 — **`git add -A` 금지**.
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build` 통과 (Task 6은 test/lint 포함).
- 소비자 페이지 RLS 규칙: 모든 쿼리는 `@/lib/supabase/server`의 `createClient()` 경유. service_role 금지.
- **규제/근거 시각 분리(법적 요건)**: 식약처 인정은 `<RegulatoryBadge>`, 학술 근거는 `<EvidenceGradeBadge>`, 주의는 `<SeverityBadge>`로만 표시. utils.ts의 구 색상 함수(getEvidenceGradeColor/getSeverityColor/승인 배지 인라인 마크업)는 이 페이지에서 제거 대상.
- 데이터 의미 불변: 쿼리 필터·정렬·병합·폴백(실시간 검색) 로직의 동작을 바꾸지 않는다. 병렬화·에러 처리 개선만 허용.
- 색상: slate/gray → stone·ink 토큰(text-ink, text-ink-muted, border-stone-*, bg-surface/bg-canvas). 원색 하드코딩 신규 추가 금지(도메인 배지 내부 제외).
- `dynamic = "force-dynamic"` 유지 (캐싱은 별도 phase).
- 환경: 셸 `cd`가 zoxide 경유 — 단일 복합 명령 사용. build는 수 분 정상. 대상 파일 경로에 `[slug]` 대괄호가 있으므로 셸에서 반드시 따옴표로 감쌀 것.

## 현재 페이지 구조 (이동 지도, 2026-08-11 기준 1,157줄)

- L36–88 헬퍼: `getClaimMeta`/`getSourceMeta`(동일 구현 2벌), `dedupeSourceLinks`, `getStudyPriority`
- L90–114 `generateMetadata`
- L116–420 데이터: 기본 성분 조회(~136), 7-way `Promise.all`(154), 프로바이오틱/프로폴리스 패밀리 해석(~235–330), 관련 claims/evidence 병합(331+), 소스링크 3연속 쿼리(375–395)
- JSX: Breadcrumb 423 · Header 440 · 개요 Card 493 · 기능성/효능 542 · 연구 근거 607 · 근거없음 안내 789 · 출처 816(+`SourceLinkBlock` 정의 1090) · 안전성 861 · 약물 상호작용 918 · 권장 용량 954 · 판매중 관련 제품 1001(실시간 폴백 1050) · 면책 1075

---

### Task 1: 데이터 계층 추출 — `lib/data/ingredient-detail.ts` + `ingredient-family.ts`

**Files:**
- Create: `web/src/lib/data/ingredient-family.ts` (페이지 L235–330의 패밀리 해석 로직 이동)
- Create: `web/src/lib/data/ingredient-detail.ts` (L116–420의 나머지 데이터 로직 + L36–88 헬퍼 이동)
- Modify: `web/src/app/ingredients/[slug]/page.tsx` (데이터 부분을 새 lib 호출로 교체 — JSX는 이 태스크에서 무변경)

**Interfaces (Produces — 이후 태스크가 사용):**

```ts
// ingredient-family.ts
export interface FamilyResolution {
  relatedIngredientIds: number[];   // 패밀리 루트+형제 (자신 제외 여부 포함해 기존 로직 그대로)
  familyRootId: number | null;
}
export async function resolveIngredientFamily(
  supabase: SupabaseClient<Database>,
  ingredient: { id: number; slug: string; ingredient_type: string | null; parent_ingredient_id: number | null }
): Promise<FamilyResolution>;

// ingredient-detail.ts
export async function getIngredientDetail(slug: string): Promise<IngredientDetail | null>;
// null = not found (페이지가 notFound() 호출). 쿼리 에러는 throw.
export interface IngredientDetail {
  ingredient: /* 기존 base select 추론 타입 */;
  claims: MergedClaim[];            // 기존 mergedIngredientClaims 결과
  evidenceStudies: MergedStudy[];   // 기존 mergedEvidenceStudies + getStudyPriority 정렬
  safetyItems: ...; drugInteractions: ...; dosageGuidelines: ...;
  products: ...; verifiedProducts: ...; verifiedProductCount: number;
  sourceLinks: { ingredient: SourceLink[]; claim: SourceLink[]; evidence: SourceLink[] };
  summary: { topEvidenceGrade: string | null; approvedClaimCount: number; cautionCount: number };
}
export { getClaimMeta, dedupeSourceLinks, getStudyPriority }; // 테스트용 재export
```

구체 타입은 기존 페이지의 추론/QueryData 타입을 그대로 옮긴다(수동 인터페이스 재작성 금지).

- [ ] **Step 1:** 두 lib 파일 생성, 페이지의 데이터 코드·헬퍼를 이동. 개선 2건 필수 적용:
  - (a) 소스링크 3연속 쿼리(L375–395) → `entity_type`을 `.in()`으로 묶은 **1개 쿼리** 후 JS에서 3분류 (`entity_id` 필터는 타입별로 다르므로 `.or()` 3절 또는 기존 3쿼리를 `Promise.all`로 병렬화 — 단일화가 필터 의미를 바꾸면 병렬화만 택할 것)
  - (b) 모든 쿼리 결과의 `error`를 검사해 `throw new Error(\`ingredient-detail: ${context}: ${error.message}\`)` (F19)
  - (c) `summary` 3종 계산: topEvidenceGrade = claims/evidence의 최고 등급(A>B>C>D>I), approvedClaimCount = `is_regulator_approved` true인 claims 수, cautionCount = safetyItems + drugInteractions 수
- [ ] **Step 2:** 페이지의 L36–420을 `const detail = await getIngredientDetail(slug); if (!detail) notFound();` + 구조 분해로 교체. JSX가 참조하던 변수명을 detail 필드로 연결(변수명 유지용 로컬 구조 분해 허용). `generateMetadata`는 페이지에 남기되 base select 부분만 lib의 소형 함수 재사용 가능(선택).
- [ ] **Step 3:** 검증 — `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`. 페이지 육안 동등성은 Task 6에서 일괄.
- [ ] **Step 4:** Commit — `git add web/src/lib/data "web/src/app/ingredients/[slug]"` 후:
  `refactor: extract ingredient detail data layer with parallel queries and error propagation`

---

### Task 2: 히어로 + 요약 대시보드 — `components/ingredient/ingredient-hero.tsx`

**Files:**
- Create: `web/src/components/ingredient/ingredient-hero.tsx`
- Modify: `web/src/app/ingredients/[slug]/page.tsx` (Breadcrumb·Header·개요 Card JSX를 컴포넌트 호출로 교체)

**Interfaces:**
- Consumes: Task 1의 `IngredientDetail["ingredient" | "summary"]`, 디자인 시스템(`SummaryStat`, `RegulatoryBadge`, `Badge`, `Card tone="highlight"`)
- Produces: `IngredientHero({ ingredient, summary, hasApprovedClaim })` — 서버 컴포넌트

- [ ] **Step 1:** 기존 Breadcrumb(423)·Header(440–492)·개요 Card(493–541) 내용을 이동·재스타일:
  - 히어로: `Card tone="highlight"` 안에 성분명(text-2xl font-extrabold text-ink) + 타입/카테고리 `Badge variant="tag"` + 승인 효능 존재 시 `<RegulatoryBadge>` 1개
  - 요약 대시보드: `grid grid-cols-3 gap-3`에 `<SummaryStat value={summary.topEvidenceGrade ?? "—"} label="최고 근거등급" accent="brand" />`, `<SummaryStat value={approvedClaimCount} label="인정 효능" accent="regulatory" />`, `<SummaryStat value={cautionCount} label="주의사항" accent="danger" />`
  - 개요(설명 텍스트·학명·동의어)는 히어로 카드 하단에 text-sm text-ink-muted로 통합
  - Breadcrumb은 기존 링크 구조 유지, 색만 ink-faint/ink 토큰화
- [ ] **Step 2:** 검증 tsc+build → Commit `git add web/src/components/ingredient "web/src/app/ingredients/[slug]"`:
  `feat: ingredient hero with summary dashboard (warm commerce)`

---

### Task 3: 효능·근거 섹션 — `claims-section.tsx` + `evidence-section.tsx`

**Files:**
- Create: `web/src/components/ingredient/claims-section.tsx` (기존 542–606)
- Create: `web/src/components/ingredient/evidence-section.tsx` (기존 607–788 + 근거없음 안내 789–814)
- Modify: `web/src/app/ingredients/[slug]/page.tsx`

**Interfaces:**
- `ClaimsSection({ claims })` — `<CollapsibleSection title="기능성 · 효능" count={claims.length} defaultOpen>` 래핑. 각 클레임: 승인이면 `<RegulatoryBadge countryCode={...}>`, 등급은 `<EvidenceGradeBadge grade={...}>`. **비인정 표현은 기존 로직 그대로 효능으로 표시 금지.**
- `EvidenceSection({ studies })` — `<CollapsibleSection title="연구 근거" count={studies.length}>`(기본 접힘). 연구 카드 배지 행의 등급 표시는 `<EvidenceGradeBadge>`, 연구설계 라벨은 `Badge variant="outline"`. 근거 0건일 때 기존 안내 문구 블록 유지.
- 두 컴포넌트 모두 서버 컴포넌트, 데이터 가공 없이 표시만(가공은 Task 1 lib 소관).

- [ ] **Step 1:** JSX 이동 + 재스타일 (utils의 getEvidenceGradeColor·인라인 승인 배지 마크업 사용처를 도메인 배지로 대체; slate→stone/ink)
- [ ] **Step 2:** 검증 tsc+build → Commit: `feat: claims and evidence sections on design system`

---

### Task 4: 안전성 클러스터 + 출처 — `safety-section.tsx`, `dosage-section.tsx`, `sources-section.tsx`

**Files:**
- Create: `web/src/components/ingredient/safety-section.tsx` (안전성 861–917 + 약물 상호작용 918–953 통합, 소제목 2개)
- Create: `web/src/components/ingredient/dosage-section.tsx` (권장 용량 954–1000)
- Create: `web/src/components/ingredient/sources-section.tsx` (출처 816–860 + `SourceLinkBlock` 1090–끝 이동)
- Modify: `web/src/app/ingredients/[slug]/page.tsx`

**Interfaces:**
- `SafetySection({ safetyItems, drugInteractions })` — `<CollapsibleSection title="안전성 · 상호작용" count={safetyItems.length + drugInteractions.length}>`(접힘). 심각도는 `<SeverityBadge level={...}>`(DB 어휘 mild/moderate/severe/critical 그대로 전달 — utils의 getSeverityColor 제거).
- `DosageSection({ dosageGuidelines })` — `<CollapsibleSection title="권장 용량">`(접힘). 표 마크업 유지, 토큰화만.
- `SourcesSection({ sourceLinks })` — `<CollapsibleSection title="근거 출처 · 업데이트 현황">`(접힘). `SourceLinkBlock` 제네릭을 이 파일 내부로 이동.

- [ ] **Step 1:** JSX 이동 + 재스타일 → 검증 tsc+build
- [ ] **Step 2:** Commit: `feat: safety, dosage, sources sections on design system`

---

### Task 5: 제품 섹션 + 페이지 셸 완성

**Files:**
- Create: `web/src/components/ingredient/related-products-section.tsx` (판매중 관련 제품 1001–1074, 실시간 폴백 `<LiveSearchFallback>` 포함)
- Modify: `web/src/app/ingredients/[slug]/page.tsx` (최종 셸)

**Interfaces:**
- `RelatedProductsSection({ verifiedProducts, verifiedProductCount, ingredientNameKo, isProbiotic })` — `<CollapsibleSection title="판매중인 관련 제품" count={verifiedProductCount} defaultOpen>` (구매 전환 섹션이므로 기본 펼침). 제품 카드에 `<CTAButton variant="outline" href={...}>` 적용. 실시간 폴백 조건·props는 기존 그대로.

- [ ] **Step 1:** 컴포넌트 이동 + 재스타일
- [ ] **Step 2:** 페이지 셸 정리 — 최종 형태: `generateMetadata` + `IngredientDetailPage`(detail 로드 → Hero → ClaimsSection → EvidenceSection → SafetySection → DosageSection → SourcesSection → RelatedProductsSection → 면책 링크 카드). 면책 블록(1075–1088)은 셸에 인라인 유지(소형). `/probiotics` 링크 배너 등 잔여 소형 블록도 셸에 유지. **파일 전체 ≤200줄 확인**: `wc -l` 출력 기록.
- [ ] **Step 3:** 검증 tsc+build → Commit: `refactor: ingredient detail page as thin shell over sections`

---

### Task 6: 테스트 + 전체 게이트 + 시각 확인

**Files:**
- Create: `web/src/lib/data/ingredient-detail.test.ts`

- [ ] **Step 1:** 순수 함수 테스트 작성 (Task 1이 재export한 함수 대상):

```ts
import { describe, expect, it } from "vitest";
import { dedupeSourceLinks, getStudyPriority, getClaimMeta } from "@/lib/data/ingredient-detail";

describe("getStudyPriority", () => {
  it("ranks meta-analysis highest and unknown lowest", () => {
    expect(getStudyPriority("meta-analysis")).toBeLessThan(getStudyPriority("rct"));
    expect(getStudyPriority(null)).toBeGreaterThan(getStudyPriority("rct"));
  });
});
describe("getClaimMeta", () => {
  it("unwraps array to first element and passes object through", () => {
    expect(getClaimMeta([{ a: 1 }, { a: 2 }])).toEqual({ a: 1 });
    expect(getClaimMeta({ a: 1 })).toEqual({ a: 1 });
    expect(getClaimMeta(null)).toBeNull();
  });
});
describe("dedupeSourceLinks", () => {
  it("dedupes by url keeping first occurrence", () => {
    const links = [
      { source_url: "https://x/1", retrieved_at: "2026-01-02" },
      { source_url: "https://x/1", retrieved_at: "2026-01-01" },
      { source_url: "https://x/2", retrieved_at: "2026-01-01" },
    ];
    expect(dedupeSourceLinks(links as never[])).toHaveLength(2);
  });
});
```

주의: 위 기대값은 **기존 구현의 실제 동작 기준으로 조정**하라 — 예: getStudyPriority가 낮을수록 우선인지 높을수록 우선인지, dedupe 키가 url인지 (url, title) 조합인지 구현을 읽고 단언을 맞출 것. 구현을 테스트에 맞추지 말 것.

- [ ] **Step 2:** 전체 게이트 — `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint`
  Expected: 테스트 전부 통과(기존 14 + 신규), tsc 0, 빌드 성공, lint 0 에러
- [ ] **Step 3:** utils.ts의 `getEvidenceGradeColor`/`getSeverityColor`가 이 페이지에서 미사용인지 확인: `grep -rn "getEvidenceGradeColor\|getSeverityColor" web/src/app/ingredients` → 출력 없음. (다른 페이지 사용처는 그대로 둠 — 각 페이지 마이그레이션 때 제거.)
- [ ] **Step 4:** Commit: `test: unit tests for ingredient detail data helpers`
- [ ] **Step 5 (보고용):** dev 서버 시각 확인은 컨트롤러/사용자 몫으로 보고서에 명시 — 확인 경로: `/ingredients/omega-3` 등 대표 성분 1–2개.
