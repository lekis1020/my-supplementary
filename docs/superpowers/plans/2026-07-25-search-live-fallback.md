# /search 실시간 판매확인 폴백 UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/search`에서 판매확인 제품 결과가 5건 미만일 때 네이버 쇼핑 실시간 검색 결과를 정보 카드 섹션으로 표시한다.

**Architecture:** 성분 상세 페이지의 `LiveRelatedProducts` 클라이언트 컴포넌트를 범용 `LiveSearchFallback`으로 일반화(쿼리·임계값·문구를 props로)하고, 성분 상세와 `/search` 양쪽에서 사용한다. 백엔드는 기존 `/api/products/live-search`를 그대로 쓴다.

**Tech Stack:** Next.js App Router (서버 컴포넌트 + 클라이언트 컴포넌트), Tailwind CSS, 기존 live-search API.

**Spec:** `docs/superpowers/specs/2026-07-25-search-live-fallback-design.md`

## Global Constraints

- UI 텍스트는 한국어, 코드(변수·주석)는 영어 (프로젝트 컨벤션).
- 법적 준수: 실시간 결과 카드에는 건강 기능 표방 문구·성분 매칭 정보를 절대 표시하지 않는다.
- 실시간 카드는 클릭 불가능한 순수 정보 카드 — 썸네일(있으면) + 제품명 + 브랜드만. 가격(lprice)·몰 이름(mallName)·외부 구매 링크 표시 금지.
- 출처 표기는 섹션 수준 안내 문구("네이버 쇼핑 검색 결과")로만 한다.
- 새 의존성 추가 금지. 이 저장소에는 단위 테스트 프레임워크가 없다 — 검증은 `npm run lint` + `npm run build` + dev 서버 런타임 확인으로 한다 (모든 npm 명령은 `web/`에서 실행).
- 소비자 페이지 DB 접근은 기존대로 `@supabase/ssr` 클라이언트 경유 (변경 없음).

---

### Task 1: LiveSearchFallback 범용 컴포넌트로 교체

`LiveRelatedProducts`를 일반화한 `LiveSearchFallback`으로 대체하고, 유일한 기존 사용처(성분 상세 페이지)를 마이그레이션한 뒤 구 파일을 삭제한다. 카드에서 가격·몰·외부 링크를 제거해 정보 카드로 바꾼다.

**Files:**
- Create: `web/src/components/product/live-search-fallback.tsx`
- Modify: `web/src/app/ingredients/[slug]/page.tsx:26` (import), `:1124-1127` (사용부)
- Delete: `web/src/components/product/live-related-products.tsx`

**Interfaces:**
- Consumes: `GET /api/products/live-search?q=<검색어>` — 응답 `{ live?: Array<{ title, link, image, lprice, mallName, brand }> }` (기존 API, 변경 없음)
- Produces: `LiveSearchFallback({ query: string; initialCount: number; threshold: number; description?: string })` — named export. `initialCount < threshold && query.length >= 2`일 때만 fetch. Task 2가 이 시그니처를 사용한다.

- [ ] **Step 1: 새 컴포넌트 파일 작성**

`web/src/components/product/live-search-fallback.tsx` 생성 (전체 내용):

```tsx
"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";

/**
 * 판매확인 제품이 부족한 페이지의 실시간 검색 폴백.
 *
 * initialCount < threshold일 때 /api/products/live-search를 호출해
 * "실시간 검색 결과"로 구분 표시. 성분 상세·통합 검색 페이지에서 공용.
 *
 * 법적 준수: 실시간 결과에는 건강 기능 표방 문구를 절대 표시하지 않는다.
 * 카드는 클릭 불가능한 정보 카드 — 제품명/브랜드만 노출하고 가격·몰·구매
 * 링크는 표시하지 않는다. 출처는 섹션 안내 문구로만 표기.
 */

const MAX_DISPLAY = 6;

interface LiveItem {
  title: string;
  link: string;
  image: string | null;
  lprice: number | null;
  mallName: string | null;
  brand: string | null;
}

interface LiveSearchPayload {
  live?: LiveItem[];
}

export function LiveSearchFallback({
  query,
  initialCount,
  threshold,
  description = "네이버 쇼핑 검색 결과로, 아직 성분 검증이 완료되지 않은 제품입니다.",
}: {
  query: string;
  initialCount: number;
  threshold: number;
  description?: string;
}) {
  const shouldFetch = initialCount < threshold && query.length >= 2;

  const [items, setItems] = useState<LiveItem[] | null>(null);
  const [loading, setLoading] = useState(shouldFetch);

  useEffect(() => {
    if (!shouldFetch) return;

    let cancelled = false;

    fetch(`/api/products/live-search?q=${encodeURIComponent(query)}`)
      .then((res) => (res.ok ? res.json() : null))
      .then((payload: LiveSearchPayload | null) => {
        if (cancelled) return;
        setItems((payload?.live ?? []).slice(0, MAX_DISPLAY));
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [shouldFetch, query]);

  if (!shouldFetch) return null;

  if (loading) {
    return (
      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <div
            key={i}
            className="h-24 animate-pulse rounded-2xl border border-slate-100 bg-slate-50"
          />
        ))}
      </div>
    );
  }

  if (!items || items.length === 0) return null;

  return (
    <div className="mt-6">
      <div className="mb-3 flex items-center gap-2">
        <Badge className="bg-sky-50 text-sky-700">실시간 검색 결과</Badge>
        <p className="text-xs text-slate-400">{description}</p>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((item) => (
          <div
            key={item.link}
            className="flex gap-3 rounded-2xl border border-slate-200 bg-white p-3"
          >
            {item.image && (
              <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-xl border border-slate-100 bg-white">
                <Image
                  src={item.image}
                  alt={item.title}
                  fill
                  sizes="64px"
                  className="object-contain"
                  unoptimized
                />
              </div>
            )}
            <div className="min-w-0">
              <p className="line-clamp-2 text-sm font-semibold text-slate-800">
                {item.title}
              </p>
              {item.brand && (
                <p className="mt-1 text-xs text-slate-500">{item.brand}</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

주의: `link`는 카드 `key`와 API 응답 타입 유지용으로만 쓰고 렌더링하지 않는다. `lprice`/`mallName`도 타입에는 남기되(API 응답 형태) 렌더링하지 않는다.

- [ ] **Step 2: 성분 상세 페이지 마이그레이션**

`web/src/app/ingredients/[slug]/page.tsx`의 26행 import를 교체:

```tsx
// 변경 전
import { LiveRelatedProducts } from "@/components/product/live-related-products";
// 변경 후
import { LiveSearchFallback } from "@/components/product/live-search-fallback";
```

1124-1127행 사용부를 교체 (기존 `MIN_VERIFIED = 3` 동작 유지):

```tsx
// 변경 전
<LiveRelatedProducts
  ingredientName={displayIngredientName}
  initialCount={verifiedProducts.length}
/>
// 변경 후
<LiveSearchFallback
  query={displayIngredientName}
  initialCount={verifiedProducts.length}
  threshold={3}
/>
```

- [ ] **Step 3: 구 컴포넌트 삭제**

```bash
rm web/src/components/product/live-related-products.tsx
```

- [ ] **Step 4: 잔여 참조 없음 확인 + lint/build**

```bash
grep -rn "live-related-products\|LiveRelatedProducts" web/src
```
Expected: 출력 없음 (exit code 1).

```bash
cd web && npm run lint && npm run build
```
Expected: lint 에러 0건, build 성공 (`✓ Compiled successfully`).

- [ ] **Step 5: Commit**

```bash
git add web/src/components/product/live-search-fallback.tsx web/src/app/ingredients/\[slug\]/page.tsx
git rm web/src/components/product/live-related-products.tsx
git commit -m "Generalize live-search fallback into reusable info-card component

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: /search 페이지에 실시간 폴백 연결

**Files:**
- Modify: `web/src/app/search/page.tsx` (import 추가, 제품 결과 섹션 아래 렌더)

**Interfaces:**
- Consumes: Task 1의 `LiveSearchFallback({ query, initialCount, threshold, description? })`
- Produces: 없음 (말단 UI)

- [ ] **Step 1: import 추가**

`web/src/app/search/page.tsx` 상단 import 블록(8행 `SearchCombobox` import 아래)에 추가:

```tsx
import { LiveSearchFallback } from "@/components/product/live-search-fallback";
```

- [ ] **Step 2: 판매확인 결과 수 계산 + 렌더 연결**

`SearchPage` 컴포넌트에서 `pageLinks` 계산(412행 부근) 다음에 추가:

```tsx
const verifiedProductCount = productResults.filter(
  (product) => product.saleVerified,
).length;
```

`{query && (...)}` 블록 안, 제품 결과 `<section>`이 닫힌 직후(`</section>` 다음, `space-y-10` div가 닫히기 전)에 추가 — 결과 0건으로 EmptyState가 표시될 때도 렌더된다:

```tsx
<LiveSearchFallback
  query={query}
  initialCount={verifiedProductCount}
  threshold={5}
/>
```

- [ ] **Step 3: lint/build**

```bash
cd web && npm run lint && npm run build
```
Expected: lint 에러 0건, build 성공.

- [ ] **Step 4: Commit**

```bash
git add web/src/app/search/page.tsx
git commit -m "Show live-search fallback section on /search for sparse results

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: 런타임 검증

**Files:** 변경 없음 (검증만)

**Interfaces:**
- Consumes: Task 1·2 결과물, dev 서버(`npm run dev`, localhost:3000)

- [ ] **Step 1: dev 서버 기동**

```bash
cd web && npm run dev
```
Expected: `✓ Ready` 후 localhost:3000 응답.

- [ ] **Step 2: API 폴백 동작 확인**

판매확인 결과가 빈약한 검색어로 API 직접 호출:

```bash
curl -s "http://localhost:3000/api/products/live-search?q=콜라겐젤리" | head -c 600
```
Expected: JSON 응답에 `"live":[...]` 배열 (Naver 키 설정 시) 또는 `"live":[]` + `"liveFetched":false` (키 미설정/예산 소진 시). 오류 아님.

- [ ] **Step 3: /search 페이지 확인 (브라우저)**

- `http://localhost:3000/search?q=콜라겐젤리` 등 판매확인 결과 5건 미만 검색어 → "실시간 검색 결과" 섹션 표시, 카드에 제품명/브랜드만 있고 가격·몰·링크 없음(클릭 불가) 확인.
- `http://localhost:3000/search?q=마그네슘` (결과 풍부) → 실시간 섹션 미표시 확인.

- [ ] **Step 4: 성분 상세 회귀 확인 (브라우저)**

판매확인 관련 제품이 3건 미만인 성분 상세 페이지에서 폴백 섹션이 기존처럼 표시되되, 카드가 정보 카드(링크·가격·몰 없음)로 바뀐 것 확인.

- [ ] **Step 5: dev 서버 종료**

기동한 dev 서버 프로세스를 종료한다.
