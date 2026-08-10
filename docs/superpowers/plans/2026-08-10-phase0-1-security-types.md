# Phase 0+1: 보안 정리 + Supabase 타입 복구 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 커밋된 API 키 제거·디버그 라우트 차단·사문 스크립트 정리(Phase 0) 후, Supabase 생성 타입을 클라이언트에 연결해 전 쿼리를 타입 안전하게 만들고 수동 인터페이스/캐스트를 제거한다(Phase 1).

**Architecture:** 생성 타입은 새 파일 `web/src/lib/types/supabase.ts`에 두고 제네릭을 먼저 연결한 뒤, 페이지별로 수동 타입을 걷어내고 마지막에 구 `database.ts`를 삭제한다. 각 태스크 종료 시점에 빌드가 항상 초록이어야 한다.

**Tech Stack:** Next.js 16 (App Router), @supabase/ssr 0.9, supabase CLI(`npx supabase`), TypeScript strict, vitest.

## Global Constraints

- 브랜치: `design/warm-commerce-redesign` (이미 체크아웃됨). main 직접 커밋 금지.
- 소비자 페이지는 반드시 `@/lib/supabase/server`(RLS) 경유 — service_role 사용 금지 (CLAUDE.md 규칙).
- UI 문자열은 한국어, 코드·주석은 영어.
- 커밋 메시지는 conventional commits (`fix:`, `feat:`, `chore:`, `refactor:`) + 마지막 줄에 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- 각 태스크 종료 시 `web/`에서 `npx tsc --noEmit`과 `npm run build`가 통과해야 한다 (Task 1·2·4는 웹 코드와 무관하므로 py_compile/grep 검증으로 대체).
- 명령은 별도 표기가 없으면 저장소 루트(`/Users/napler/projects/my-supple`)에서 실행.

---

### Task 1: PubMed 사문 스크립트 정리

**Files:**
- Delete: `scripts/fetch_pubmed_evidence.py` (v1, 어디서도 참조 안 됨)
- Rename: `scripts/fetch_pubmed_evidence_v2.py` → `scripts/fetch_pubmed_evidence.py`
- Modify: `GEMINI.md:67` (참조 갱신)

**Interfaces:**
- Consumes: 없음
- Produces: 이후 Task 2가 수정할 단일 파일 `scripts/fetch_pubmed_evidence.py`

- [ ] **Step 1: v1이 참조되지 않음을 재확인**

Run: `grep -rn "fetch_pubmed_evidence" --include="*.md" --include="*.json" --include="*.mjs" --include="*.py" . | grep -v node_modules | grep -v _v2 | grep -v docs/superpowers`
Expected: 출력 없음 (v1 참조 0건). 출력이 있으면 중단하고 보고.

- [ ] **Step 2: 삭제 및 개명**

```bash
git rm scripts/fetch_pubmed_evidence.py
git mv scripts/fetch_pubmed_evidence_v2.py scripts/fetch_pubmed_evidence.py
```

- [ ] **Step 3: GEMINI.md 참조 갱신**

`GEMINI.md` 67행의 `python3 scripts/fetch_pubmed_evidence_v2.py` → `python3 scripts/fetch_pubmed_evidence.py`

- [ ] **Step 4: 컴파일 검증**

Run: `python3 -m py_compile scripts/fetch_pubmed_evidence.py && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: remove superseded pubmed script, promote v2

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: NCBI API 키 환경변수화

**Files:**
- Modify: `scripts/fetch_pubmed_evidence.py:14` (하드코딩 키 제거)
- Modify: `web/.env.local.example` (키 항목 추가)

**Interfaces:**
- Consumes: Task 1의 개명된 스크립트
- Produces: 환경변수 `NCBI_API_KEY` 규약

- [ ] **Step 1: 하드코딩 키를 환경변수 조회로 교체**

`scripts/fetch_pubmed_evidence.py` 상단 `import` 블록에 `import os` 추가(없다면), 14행을:

```python
API_KEY = os.environ.get("NCBI_API_KEY", "")
if not API_KEY:
    raise SystemExit("NCBI_API_KEY environment variable is required")
```

- [ ] **Step 2: .env.local.example에 항목 추가**

`web/.env.local.example` 마지막에:

```
# NCBI E-utilities (scripts/fetch_pubmed_evidence.py)
NCBI_API_KEY=
```

- [ ] **Step 3: 저장소 전체에서 키 문자열 소거 확인**

Run: `git grep -n "447eb2e330874c15cf15eaac1a7f6bd0a809" || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 4: 컴파일 검증**

Run: `python3 -m py_compile scripts/fetch_pubmed_evidence.py && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "fix: read NCBI API key from environment instead of source

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: 사용자 안내 (수동 조치)**

작업 보고에 반드시 포함: 기존 키 `447e…8bf2`(git 히스토리에 잔존)는 NCBI 계정 설정(https://www.ncbi.nlm.nih.gov/account/settings/)에서 **폐기·재발급**해야 하며, 새 키를 로컬 `web/.env.local`의 `NCBI_API_KEY`에 넣도록 안내.

---

### Task 3: 디버그 라우트 프로덕션 차단

**Files:**
- Modify: `web/src/app/api/debug/product/[id]/route.ts`

**Interfaces:**
- Consumes: 없음
- Produces: 없음 (동작 게이트만 추가)

- [ ] **Step 1: GET 핸들러 최상단에 가드 추가**

`route.ts`의 `const { id } = await params;` 바로 앞에:

```ts
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
```

- [ ] **Step 2: 타입·빌드 검증**

Run: `cd web && npx tsc --noEmit && npm run build`
Expected: 둘 다 성공 (경고 무방, 에러 0)

- [ ] **Step 3: Commit**

```bash
git add web/src/app/api/debug/product && git commit -m "fix: gate debug product route to non-production

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 고아 staging 스크립트 아카이브

**Files:**
- Move: `scripts/build_product_ingredients_staging.mjs` → `scripts/archive/build_product_ingredients_staging.mjs`
- Move: `scripts/build_products_ingredients_staging.mjs` → `scripts/archive/build_products_ingredients_staging.mjs`
- Create: `scripts/archive/README.md`

삭제가 아닌 이동이다 — 파이프라인 소유자의 최종 삭제 결정 전까지 보존한다.

- [ ] **Step 1: 참조 0건 재확인**

Run: `grep -rn "ingredients_staging" --include="*.json" --include="*.md" --include="*.mjs" . | grep -v node_modules | grep -v scripts/build | grep -v docs/superpowers | grep -v '\.omc'`
Expected: 출력 없음. 출력이 있으면 중단하고 보고.

- [ ] **Step 2: 아카이브 이동 + README**

```bash
mkdir -p scripts/archive
git mv scripts/build_product_ingredients_staging.mjs scripts/archive/
git mv scripts/build_products_ingredients_staging.mjs scripts/archive/
```

`scripts/archive/README.md`:

```markdown
# Archived scripts

Unreferenced scripts moved here pending owner confirmation for deletion.

- `build_product_ingredients_staging.mjs` / `build_products_ingredients_staging.mjs`:
  near-duplicate staging builders (2026-08-10 refactoring review, finding #6).
  Neither is referenced by package.json or docs. The plural variant (651 lines,
  reads ingredient_profiles + ingredient_catalog.merged) appears newer.
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore: archive orphaned staging builder scripts

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: Supabase 타입 생성

**Files:**
- Create: `web/src/lib/types/supabase.ts` (생성물 — 손으로 수정 금지)

**Interfaces:**
- Consumes: `web/.env.local`의 `DATABASE_URL`
- Produces: `Database` 타입 (`import type { Database } from "@/lib/types/supabase"`), 이후 모든 태스크가 사용. 행 타입 접근 형태: `Database["public"]["Tables"]["ingredients"]["Row"]`

- [ ] **Step 1: 타입 생성**

```bash
cd web && set -a && source .env.local && set +a \
  && npx supabase gen types typescript --db-url "$DATABASE_URL" --schema public \
  > src/lib/types/supabase.ts
```

주의: 실패 시(네트워크/CLI 버전) 에러를 그대로 보고하고 중단. 빈 파일을 커밋하지 말 것.

- [ ] **Step 2: 생성물 검증**

Run: `cd web && head -5 src/lib/types/supabase.ts && grep -c "Row:" src/lib/types/supabase.ts`
Expected: 첫 줄에 `export type Json` 계열 선언, `Row:` 카운트 ≥ 25 (28+ 테이블). `products`, `ingredients`, `claims` 문자열 존재 확인: `grep -E "products|ingredients|claims" src/lib/types/supabase.ts | head -3`

- [ ] **Step 3: 파일 헤더 주석 추가**

파일 맨 위에:

```ts
// AUTO-GENERATED by `npx supabase gen types typescript` — do not edit by hand.
// Regenerate: see docs/superpowers/plans/2026-08-10-phase0-1-security-types.md Task 5.
```

- [ ] **Step 4: 타입 검증 & Commit**

Run: `cd web && npx tsc --noEmit`
Expected: 성공 (아직 아무도 import 안 하므로 영향 없음)

```bash
git add web/src/lib/types/supabase.ts && git commit -m "feat: add generated supabase database types

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: Supabase 클라이언트에 Database 제네릭 연결

**Files:**
- Modify: `web/src/lib/supabase/server.ts`
- Modify: `web/src/lib/supabase/client.ts`
- Modify(필요 시): 제네릭 연결로 컴파일 에러가 나는 파일들 — 수동 타입과 생성 타입의 불일치 지점(예: `web/src/components/product/product-card.tsx`의 `id: string` vs DB `number`, `compare-workbench.tsx`의 `amount_per_serving` 유니온)

**Interfaces:**
- Consumes: Task 5의 `Database`
- Produces: 타입이 흐르는 `createClient()` 2종 — 이후 태스크는 쿼리 결과 추론 타입을 그대로 사용 가능

- [ ] **Step 1: server.ts에 제네릭 적용**

```ts
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/types/supabase";

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Server Component에서는 쿠키 설정 불가 — 무시
          }
        },
      },
    }
  );
}
```

- [ ] **Step 2: client.ts에 제네릭 적용**

```ts
import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "@/lib/types/supabase";

export function createClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !key) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY must be set"
    );
  }

  return createBrowserClient<Database>(url, key);
}
```

- [ ] **Step 3: 컴파일 폴아웃 확인 및 수정**

Run: `cd web && npx tsc --noEmit`

에러가 나오면 **이 태스크 안에서** 최소 수정으로 해소한다. 원칙:
- 기존 `as XyzRow[]` 캐스트는 이 태스크에서 건드리지 않는다 (Task 7–10에서 제거). 캐스트 자체가 불법이 된 경우(형태 불일치)에만 해당 수동 인터페이스의 필드 타입을 DB 실제 타입에 맞게 고친다.
- 예: `product-card.tsx`의 `id: string` → `id: number`, 사용처의 `String(id)` 등 동반 수정.
- `as unknown as` 이중 캐스트는 그대로 둔다 (Task 10에서 제거).

Expected(최종): `npx tsc --noEmit` 에러 0

- [ ] **Step 4: 빌드 & vitest**

Run: `cd web && npm run build && npm test`
Expected: 성공, 기존 테스트 통과

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: wire generated Database types into supabase clients

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: ingredients/[slug] 수동 타입 제거

**Files:**
- Modify: `web/src/app/ingredients/[slug]/page.tsx` (파일 상단의 수동 Row 인터페이스들과 `(res.data ?? []) as XyzRow[]` 캐스트 — 279–282, 287, 436–439, 474, 485, 488행 부근)

**Interfaces:**
- Consumes: Task 6의 타입 흐르는 클라이언트
- Produces: 없음 (내부 정리)

**변환 패턴 (이 태스크와 8–10 공통):**

패턴 1 — 단순 테이블 조회: 캐스트를 지우고 추론에 맡긴다.

```ts
// before
const safetyItems = (safetyRes.data ?? []) as SafetyItemRow[];
// after
const safetyItems = safetyRes.data ?? [];
```

패턴 2 — 조인 포함 조회: 이름 있는 타입이 필요하면 `QueryData`로 도출한다.

```ts
import type { QueryData } from "@supabase/supabase-js";

const claimsQuery = supabase
  .from("ingredient_claims")
  .select("*, claims(*)")
  .eq("ingredient_id", id);
type ClaimWithMeta = QueryData<typeof claimsQuery>[number];
```

패턴 3 — 수동 인터페이스 선언(`interface XyzRow { … }`)은 사용처가 전부 추론/QueryData로 대체되면 삭제한다.

- [ ] **Step 1: 파일 내 수동 인터페이스 목록화**

Run: `grep -n "^\(interface\|type\).*Row" web/src/app/ingredients/\[slug\]/page.tsx`
각 항목을 위 패턴으로 대체.

- [ ] **Step 2: `as ...Row[]` 캐스트 제거**

Run: `grep -n "as .*Row" web/src/app/ingredients/\[slug\]/page.tsx`
Expected(작업 후): 출력 없음

- [ ] **Step 3: 타입·빌드 검증**

Run: `cd web && npx tsc --noEmit && npm run build`
Expected: 에러 0. 추론 타입과 기존 코드의 불일치가 드러나면(예: null 처리 누락) 코드를 실제 타입에 맞게 수정 — 캐스트 재도입 금지.

- [ ] **Step 4: Commit**

```bash
git add web/src/app/ingredients && git commit -m "refactor: use inferred supabase types in ingredient detail page

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: products 상세·목록 수동 타입 제거

**Files:**
- Modify: `web/src/app/products/[id]/page.tsx` (143행 부근 캐스트 외)
- Modify: `web/src/app/products/page.tsx`
- Modify: `web/src/app/ingredients/category/[category]/page.tsx`, `web/src/app/ingredients/page.tsx` (같은 패턴 존재 시)

Task 7의 변환 패턴 1–3을 동일 적용.

- [ ] **Step 1: 대상 캐스트 목록화**

Run: `grep -rn "as .*Row\|interface .*Row" web/src/app/products web/src/app/ingredients/page.tsx web/src/app/ingredients/category`

- [ ] **Step 2: 패턴 적용 후 잔여 0건 확인**

Run: 동일 grep — Expected: 출력 없음

- [ ] **Step 3: 타입·빌드 검증**

Run: `cd web && npx tsc --noEmit && npm run build`
Expected: 에러 0

- [ ] **Step 4: Commit**

```bash
git add web/src/app/products web/src/app/ingredients && git commit -m "refactor: use inferred supabase types in product and list pages

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: search·probiotics 수동 타입 제거

**Files:**
- Modify: `web/src/app/search/page.tsx` (261, 313, 337–339행 부근)
- Modify: `web/src/app/probiotics/page.tsx` (73행 부근)
- Modify(해당 시): `web/src/lib/benefit-profile.ts`의 `ClaimShape` — 조인 결과 수동 모델링을 QueryData 파생으로 교체

Task 7의 변환 패턴 1–3을 동일 적용. search의 조인-배열 flatten(`Array.isArray(x) ? x[0] : x`)은 생성 타입에서 조인 카디널리티가 명시되므로 타입 확인 후 불필요해진 분기를 제거한다.

- [ ] **Step 1: 대상 목록화 → 패턴 적용**

Run: `grep -rn "as .*Row\|interface .*Row" web/src/app/search web/src/app/probiotics web/src/lib/benefit-profile.ts`
작업 후 동일 grep — Expected: 출력 없음

- [ ] **Step 2: 타입·빌드·vitest 검증**

Run: `cd web && npx tsc --noEmit && npm run build && npm test`
Expected: 전부 통과

- [ ] **Step 3: Commit**

```bash
git add web/src/app/search web/src/app/probiotics web/src/lib && git commit -m "refactor: use inferred supabase types in search and probiotics pages

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 10: API 라우트·클라이언트 컴포넌트 로컬 타입 정리

**Files:**
- Modify: `web/src/app/api/compare/summary/route.ts` (158행 `as unknown as ProductIngredientRow[]` 제거)
- Modify: `web/src/components/product/compare-workbench.tsx` (20–45행의 로컬 `Product`/`ProductIngredient` → Row 파생으로 교체)
- Modify: `web/src/components/product/product-card.tsx`, `compare-summary.tsx`, `live-search-fallback.tsx` (로컬 타입 → Row 파생)

**Interfaces:**
- Consumes: Task 5–6
- Produces: 컴포넌트 공용 타입은 Row 파생으로 통일 — 예:

```ts
import type { Database } from "@/lib/types/supabase";
type ProductRow = Database["public"]["Tables"]["products"]["Row"];
// 컴포넌트가 일부 필드만 쓰면: Pick<ProductRow, "id" | "name_ko" | "brand_ko">
```

- [ ] **Step 1: compare/summary 라우트 이중 캐스트 제거**

`((ingredients as unknown) as ProductIngredientRow[])` → 쿼리 추론 사용. 수동 `ProductIngredientRow` 선언이 불필요해지면 삭제.

- [ ] **Step 2: 컴포넌트 로컬 타입을 Row 파생으로 교체**

각 파일 상단의 수동 `type/interface Product…` 선언을 위 Produces 형태로 대체. 필드 타입이 DB와 달랐던 곳(예: `string` id)은 사용처 코드를 DB 타입 기준으로 수정.

- [ ] **Step 3: 타입·빌드·vitest 검증**

Run: `cd web && npx tsc --noEmit && npm run build && npm test`
Expected: 전부 통과

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: derive component types from generated supabase rows

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 11: 구 database.ts 삭제 + 최종 검증

**Files:**
- Delete: `web/src/lib/types/database.ts`

- [ ] **Step 1: 잔여 참조 0건 확인**

Run: `grep -rn "types/database" web/src | grep -v node_modules`
Expected: 출력 없음. 남아 있으면 해당 파일을 Task 7–10 패턴으로 마저 정리.

- [ ] **Step 2: 삭제**

```bash
git rm web/src/lib/types/database.ts
```

- [ ] **Step 3: 전체 검증**

Run: `cd web && npx tsc --noEmit && npm run build && npm test && npm run lint`
Expected: 전부 통과

- [ ] **Step 4: 저장소 전체 캐스트 잔존 감사**

Run: `grep -rn "as unknown as\|as .*Row\[\]" web/src | grep -v node_modules || echo CLEAN`
Expected: `CLEAN` (예외 발견 시 사유를 최종 보고에 기록)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: remove hand-written database types, generated types are canonical

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
