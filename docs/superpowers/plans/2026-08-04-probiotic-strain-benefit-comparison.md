# 유산균 균주별 효능 비교 페이지 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 신규 `/probiotics` 페이지에서 유산균 균주를 효능(장건강·면역·정신건강·체지방)별로 근거 순으로 나란히 비교하는 뷰를 제공한다.

**Architecture:** 순수 정렬·그룹핑·조합병합 로직을 `web/src/lib/probiotic-comparison.ts`에 분리(vitest로 TDD)하고, 서버 컴포넌트 `web/src/app/probiotics/page.tsx`가 Supabase(SSR+RLS)로 기존 균주×claim 데이터를 fetch해 그 순수 함수로 가공한 뒤, 클라이언트 컴포넌트 `StrainBenefitComparison`이 효능 탭 전환 UI를 렌더한다. 새 DB 수집·마이그레이션 없음.

**Tech Stack:** Next.js App Router(서버/클라이언트 컴포넌트), `@supabase/ssr`, TypeScript, Tailwind, 기존 `Card`/`Badge` UI, vitest(신규 devDependency).

## Global Constraints

- 소비자 페이지는 반드시 `@supabase/ssr`(`@/lib/supabase/server`의 `createClient`) 경유 — RLS가 `is_published = TRUE`를 자동 적용. Drizzle/service_role 사용 금지.
- **규제 vs 학술 데이터 분리는 법적 요구사항**: 식약처 인정(`is_regulator_approved`) 배지와 근거등급(`evidence_grade`) 표기를 시각적으로 분리. `allowed_expression`은 `is_regulator_approved = true` 항목에만 노출.
- 의료 면책 조항을 페이지 하단에 노출(기존 `ingredients/[slug]` 면책 마크업과 동일 문구).
- UI 텍스트는 한국어, 코드 식별자·주석은 영어.
- 경로 별칭 `@/*` → `web/src/*`.
- 새 DB 컬럼/마이그레이션 없음. 기존 컬럼만 사용.
- 효능 축 4종과 claim_code 매핑(확정):
  - `GUT_HEALTH` = 장건강, `IMMUNE_FUNCTION` = 면역, `MENTAL_HEALTH` = 정신건강, `WEIGHT_MANAGEMENT` = 체지방
- 균주 데이터 컬럼 위치(확정): CFU 용량 = `standardization_info`(예: `'1~100억 CFU/일'`), 균주 코드 = `form_description`(예: `'LGG (ATCC 53103)'`), 짧은 표기 = `display_name`(예: `'L. rhamnosus GG (LGG)'`).
- 조합 전용 균주(확정): slug `lactobacillus-helveticus-r0052` + `bifidobacterium-longum-r0175`는 `MENTAL_HEALTH` 축에서 단일 조합 행으로 병합.

---

## File Structure

- **Create** `web/src/lib/probiotic-comparison.ts` — 순수 타입 + `buildBenefitGroups()`(그룹핑·정렬·조합병합). React/DB 의존 없음.
- **Create** `web/src/lib/probiotic-comparison.test.ts` — vitest 단위 테스트.
- **Create** `web/vitest.config.ts` — vitest 설정.
- **Create** `web/src/components/probiotic/strain-benefit-comparison.tsx` — 클라이언트 컴포넌트(효능 탭 + 행 렌더).
- **Create** `web/src/app/probiotics/page.tsx` — 서버 컴포넌트(데이터 fetch + 조립 + 헤더/범례/면책).
- **Modify** `web/package.json` — `test` 스크립트 + `vitest` devDependency.
- **Modify** `web/src/app/ingredients/[slug]/page.tsx` — probiotics 계열 페이지에 `/probiotics` 진입 링크 추가.

---

## Task 1: 순수 비교 로직 모듈 + vitest

**Files:**
- Create: `web/vitest.config.ts`
- Create: `web/src/lib/probiotic-comparison.ts`
- Test: `web/src/lib/probiotic-comparison.test.ts`
- Modify: `web/package.json`

**Interfaces:**
- Produces:
  - `PROBIOTIC_BENEFIT_AXES: ReadonlyArray<{ claimCode: string; label: string }>`
  - `interface StrainClaimInput { ingredientId: number; slug: string | null; strainName: string; scientificName: string | null; cfuText: string | null; claimCode: string; claimNameKo: string | null; evidenceGrade: string | null; evidenceSummary: string | null; allowedExpression: string | null; isRegulatorApproved: boolean; }`
  - `interface StrainRow { key: string; strainName: string; scientificName: string | null; href: string | null; cfuText: string | null; evidenceGrade: string | null; evidenceSummary: string | null; allowedExpression: string | null; isRegulatorApproved: boolean; isCombination: boolean; }`
  - `interface BenefitGroup { claimCode: string; label: string; claimNameKo: string | null; rows: StrainRow[]; }`
  - `function buildBenefitGroups(inputs: StrainClaimInput[]): BenefitGroup[]` — 반환 그룹은 `PROBIOTIC_BENEFIT_AXES` 순서, rows 0건 축은 제외.

- [ ] **Step 1: vitest 설치**

Run (in `web/`): `npm install -D vitest`
Expected: `vitest`가 `devDependencies`에 추가되고 설치 성공.

- [ ] **Step 2: package.json에 test 스크립트 추가**

`web/package.json`의 `scripts`에 아래 줄 추가:

```json
"test": "vitest run",
```

- [ ] **Step 3: vitest 설정 파일 작성**

Create `web/vitest.config.ts`:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
```

- [ ] **Step 4: 실패하는 테스트 작성**

Create `web/src/lib/probiotic-comparison.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { buildBenefitGroups, type StrainClaimInput } from "./probiotic-comparison";

function input(overrides: Partial<StrainClaimInput>): StrainClaimInput {
  return {
    ingredientId: 1,
    slug: "s",
    strainName: "S",
    scientificName: null,
    cfuText: null,
    claimCode: "GUT_HEALTH",
    claimNameKo: "장 건강에 도움",
    evidenceGrade: "B",
    evidenceSummary: null,
    allowedExpression: null,
    isRegulatorApproved: false,
    ...overrides,
  };
}

describe("buildBenefitGroups", () => {
  it("returns axes in fixed order and drops empty axes", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 1, slug: "a", strainName: "A", claimCode: "IMMUNE_FUNCTION" }),
      input({ ingredientId: 2, slug: "b", strainName: "B", claimCode: "GUT_HEALTH" }),
    ]);
    expect(groups.map((g) => g.claimCode)).toEqual(["GUT_HEALTH", "IMMUNE_FUNCTION"]);
  });

  it("sorts regulator-approved first, then grade A>B>C, then name", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 1, slug: "z", strainName: "지", evidenceGrade: "A", isRegulatorApproved: false }),
      input({ ingredientId: 2, slug: "x", strainName: "가", evidenceGrade: "C", isRegulatorApproved: true }),
      input({ ingredientId: 3, slug: "y", strainName: "나", evidenceGrade: "A", isRegulatorApproved: true }),
    ]);
    const gut = groups.find((g) => g.claimCode === "GUT_HEALTH")!;
    expect(gut.rows.map((r) => r.strainName)).toEqual(["나", "가", "지"]);
  });

  it("merges R0052 + R0175 into a single combination row under MENTAL_HEALTH", () => {
    const groups = buildBenefitGroups([
      input({ ingredientId: 10, slug: "lactobacillus-helveticus-r0052", strainName: "R0052", claimCode: "MENTAL_HEALTH", evidenceGrade: "B" }),
      input({ ingredientId: 11, slug: "bifidobacterium-longum-r0175", strainName: "R0175", claimCode: "MENTAL_HEALTH", evidenceGrade: "B" }),
    ]);
    const mental = groups.find((g) => g.claimCode === "MENTAL_HEALTH")!;
    expect(mental.rows).toHaveLength(1);
    expect(mental.rows[0].isCombination).toBe(true);
    expect(mental.rows[0].href).toBeNull();
    expect(mental.rows[0].strainName).toContain("R0052");
    expect(mental.rows[0].strainName).toContain("R0175");
  });

  it("builds href from slug for normal strains", () => {
    const groups = buildBenefitGroups([input({ slug: "lactobacillus-rhamnosus-gg" })]);
    expect(groups[0].rows[0].href).toBe("/ingredients/lactobacillus-rhamnosus-gg");
    expect(groups[0].rows[0].isCombination).toBe(false);
  });
});
```

- [ ] **Step 5: 테스트 실패 확인**

Run (in `web/`): `npm test`
Expected: FAIL — `buildBenefitGroups` / 모듈 미존재로 import 에러.

- [ ] **Step 6: 구현 작성**

Create `web/src/lib/probiotic-comparison.ts`:

```ts
// Pure grouping/sorting/merge logic for the probiotic strain comparison page.
// No React or DB dependencies — unit-tested in isolation.

export const PROBIOTIC_BENEFIT_AXES: ReadonlyArray<{ claimCode: string; label: string }> = [
  { claimCode: "GUT_HEALTH", label: "장건강" },
  { claimCode: "IMMUNE_FUNCTION", label: "면역" },
  { claimCode: "MENTAL_HEALTH", label: "정신건강" },
  { claimCode: "WEIGHT_MANAGEMENT", label: "체지방" },
];

const COMBINATION_SLUGS = [
  "lactobacillus-helveticus-r0052",
  "bifidobacterium-longum-r0175",
];
const COMBINATION_CLAIM_CODE = "MENTAL_HEALTH";
const COMBINATION_KEY = "combo-r0052-r0175";
const COMBINATION_NAME = "L. helveticus R0052 + B. longum R0175 (사이코바이오틱스 조합)";

export interface StrainClaimInput {
  ingredientId: number;
  slug: string | null;
  strainName: string;
  scientificName: string | null;
  cfuText: string | null;
  claimCode: string;
  claimNameKo: string | null;
  evidenceGrade: string | null;
  evidenceSummary: string | null;
  allowedExpression: string | null;
  isRegulatorApproved: boolean;
}

export interface StrainRow {
  key: string;
  strainName: string;
  scientificName: string | null;
  href: string | null;
  cfuText: string | null;
  evidenceGrade: string | null;
  evidenceSummary: string | null;
  allowedExpression: string | null;
  isRegulatorApproved: boolean;
  isCombination: boolean;
}

export interface BenefitGroup {
  claimCode: string;
  label: string;
  claimNameKo: string | null;
  rows: StrainRow[];
}

function gradeRank(grade: string | null): number {
  switch (grade) {
    case "A": return 0;
    case "B": return 1;
    case "C": return 2;
    case "D": return 3;
    case "F": return 4;
    default: return 5;
  }
}

function toRow(input: StrainClaimInput): StrainRow {
  return {
    key: input.slug ?? String(input.ingredientId),
    strainName: input.strainName,
    scientificName: input.scientificName,
    href: input.slug ? `/ingredients/${input.slug}` : null,
    cfuText: input.cfuText,
    evidenceGrade: input.evidenceGrade,
    evidenceSummary: input.evidenceSummary,
    allowedExpression: input.allowedExpression,
    isRegulatorApproved: input.isRegulatorApproved,
    isCombination: false,
  };
}

function mergeCombination(inputs: StrainClaimInput[]): StrainRow {
  // Prefer the strongest grade and any regulator approval / non-empty text across the pair.
  const sorted = [...inputs].sort((a, b) => gradeRank(a.evidenceGrade) - gradeRank(b.evidenceGrade));
  const best = sorted[0];
  return {
    key: COMBINATION_KEY,
    strainName: COMBINATION_NAME,
    scientificName: null,
    href: null,
    cfuText: best.cfuText,
    evidenceGrade: best.evidenceGrade,
    evidenceSummary: best.evidenceSummary,
    allowedExpression: inputs.find((i) => i.allowedExpression)?.allowedExpression ?? null,
    isRegulatorApproved: inputs.some((i) => i.isRegulatorApproved),
    isCombination: true,
  };
}

function sortRows(rows: StrainRow[]): StrainRow[] {
  return [...rows].sort((a, b) => {
    if (a.isRegulatorApproved !== b.isRegulatorApproved) {
      return a.isRegulatorApproved ? -1 : 1;
    }
    const gradeDiff = gradeRank(a.evidenceGrade) - gradeRank(b.evidenceGrade);
    if (gradeDiff !== 0) return gradeDiff;
    return a.strainName.localeCompare(b.strainName, "ko");
  });
}

export function buildBenefitGroups(inputs: StrainClaimInput[]): BenefitGroup[] {
  return PROBIOTIC_BENEFIT_AXES.map((axis) => {
    const axisInputs = inputs.filter((i) => i.claimCode === axis.claimCode);

    const comboInputs = axisInputs.filter(
      (i) => axis.claimCode === COMBINATION_CLAIM_CODE && i.slug != null && COMBINATION_SLUGS.includes(i.slug),
    );
    const normalInputs = axisInputs.filter((i) => !comboInputs.includes(i));

    const rows: StrainRow[] = normalInputs.map(toRow);
    if (comboInputs.length > 0) {
      rows.push(mergeCombination(comboInputs));
    }

    const claimNameKo = axisInputs.find((i) => i.claimNameKo)?.claimNameKo ?? null;

    return {
      claimCode: axis.claimCode,
      label: axis.label,
      claimNameKo,
      rows: sortRows(rows),
    };
  }).filter((group) => group.rows.length > 0);
}
```

- [ ] **Step 7: 테스트 통과 확인**

Run (in `web/`): `npm test`
Expected: PASS — 5개 테스트 모두 통과.

- [ ] **Step 8: 커밋**

```bash
git add web/package.json web/package-lock.json web/vitest.config.ts web/src/lib/probiotic-comparison.ts web/src/lib/probiotic-comparison.test.ts
git commit -m "feat: add probiotic strain benefit comparison logic with vitest"
```

---

## Task 2: 클라이언트 비교 컴포넌트

**Files:**
- Create: `web/src/components/probiotic/strain-benefit-comparison.tsx`

**Interfaces:**
- Consumes: `BenefitGroup`, `StrainRow` (Task 1), `getEvidenceGradeColor` (`@/lib/utils`), `Card`/`CardContent`/`Badge` (`@/components/ui/*`).
- Produces: `export function StrainBenefitComparison({ groups }: { groups: BenefitGroup[] }): JSX.Element` — 클라이언트 컴포넌트, 효능 탭 상태 관리.

- [ ] **Step 1: 컴포넌트 작성**

Create `web/src/components/probiotic/strain-benefit-comparison.tsx`:

```tsx
"use client";

import { useState } from "react";
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { getEvidenceGradeColor } from "@/lib/utils";
import type { BenefitGroup, StrainRow } from "@/lib/probiotic-comparison";

function StrainRowCard({ row }: { row: StrainRow }) {
  return (
    <div className="rounded-lg border border-gray-100 bg-gray-50 p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          {row.href ? (
            <Link href={row.href} className="font-medium text-gray-900 hover:text-green-700">
              {row.strainName}
            </Link>
          ) : (
            <p className="font-medium text-gray-900">{row.strainName}</p>
          )}
          {row.scientificName && (
            <p className="text-xs italic text-gray-400">{row.scientificName}</p>
          )}
        </div>
        <div className="flex flex-shrink-0 flex-wrap justify-end gap-1.5">
          {row.evidenceGrade && (
            <Badge className={getEvidenceGradeColor(row.evidenceGrade)}>
              근거 {row.evidenceGrade}
            </Badge>
          )}
          {row.isRegulatorApproved && (
            <Badge className="bg-emerald-600 text-white">식약처 인정</Badge>
          )}
          {row.isCombination && (
            <Badge className="bg-violet-50 text-violet-700">조합 전용</Badge>
          )}
        </div>
      </div>
      {row.evidenceSummary && (
        <p className="mt-2 text-sm text-gray-600">{row.evidenceSummary}</p>
      )}
      {row.isRegulatorApproved && row.allowedExpression && (
        <p className="mt-2 inline-block rounded bg-green-50 px-2 py-1 text-xs text-green-700">
          허용 표현: {row.allowedExpression}
        </p>
      )}
      {row.cfuText && (
        <p className="mt-2 text-xs text-gray-500">권장 {row.cfuText}</p>
      )}
    </div>
  );
}

export function StrainBenefitComparison({ groups }: { groups: BenefitGroup[] }) {
  const [activeCode, setActiveCode] = useState(groups[0]?.claimCode ?? "");
  const activeGroup = groups.find((g) => g.claimCode === activeCode) ?? groups[0];

  if (!activeGroup) {
    return (
      <p className="rounded-lg border border-dashed border-gray-200 bg-gray-50 p-4 text-sm text-gray-500">
        비교할 균주 데이터가 아직 없습니다.
      </p>
    );
  }

  return (
    <div>
      <div className="mb-4 flex flex-wrap gap-2">
        {groups.map((group) => (
          <button
            key={group.claimCode}
            type="button"
            onClick={() => setActiveCode(group.claimCode)}
            className={[
              "rounded-full border px-4 py-1.5 text-sm font-medium transition-colors",
              group.claimCode === activeGroup.claimCode
                ? "border-green-600 bg-green-600 text-white"
                : "border-gray-200 bg-white text-gray-600 hover:border-green-200 hover:text-green-700",
            ].join(" ")}
          >
            {group.label}
          </button>
        ))}
      </div>

      {activeGroup.claimNameKo && (
        <p className="mb-3 text-sm text-gray-500">
          {activeGroup.claimNameKo} — 식약처 인정 · 근거등급 순으로 정렬했습니다.
        </p>
      )}

      <div className="space-y-3">
        {activeGroup.rows.map((row) => (
          <StrainRowCard key={row.key} row={row} />
        ))}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: 타입체크/린트 통과 확인**

Run (in `web/`): `npx tsc --noEmit && npm run lint`
Expected: 에러 없음. (참고: `@/components/ui/badge`, `@/lib/utils`는 기존 파일.)

- [ ] **Step 3: 커밋**

```bash
git add web/src/components/probiotic/strain-benefit-comparison.tsx
git commit -m "feat: add StrainBenefitComparison client component"
```

---

## Task 3: 서버 페이지 `/probiotics`

**Files:**
- Create: `web/src/app/probiotics/page.tsx`

**Interfaces:**
- Consumes: `createClient` (`@/lib/supabase/server`), `buildBenefitGroups` + `PROBIOTIC_BENEFIT_AXES` + `StrainClaimInput` (Task 1), `StrainBenefitComparison` (Task 2), `Card`/`CardHeader`/`CardTitle`/`CardContent` (`@/components/ui/card`), `normalizeProbioticStrainNameForDisplay` (`@/lib/utils`).
- Produces: default-export async React Server Component; route `/probiotics`.

- [ ] **Step 1: 페이지 작성**

Create `web/src/app/probiotics/page.tsx`:

```tsx
import Link from "next/link";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { normalizeProbioticStrainNameForDisplay } from "@/lib/utils";
import { StrainBenefitComparison } from "@/components/probiotic/strain-benefit-comparison";
import {
  buildBenefitGroups,
  PROBIOTIC_BENEFIT_AXES,
  type StrainClaimInput,
} from "@/lib/probiotic-comparison";
import { FlaskConical } from "lucide-react";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "유산균 균주별 효능 비교",
  description:
    "유산균은 균주에 따라 유효 효과가 다릅니다. 장건강·면역·정신건강·체지방 효능별로 균주를 근거등급과 함께 비교하세요.",
};

const AXIS_CODES = PROBIOTIC_BENEFIT_AXES.map((axis) => axis.claimCode);

interface ClaimJoin {
  claim_code: string | null;
  claim_name_ko: string | null;
}

interface StrainClaimRow {
  ingredient_id: number;
  evidence_grade: string | null;
  evidence_summary: string | null;
  allowed_expression: string | null;
  is_regulator_approved: boolean | null;
  claims: ClaimJoin | ClaimJoin[] | null;
}

function firstClaim(input: ClaimJoin | ClaimJoin[] | null): ClaimJoin | null {
  return Array.isArray(input) ? input[0] ?? null : input ?? null;
}

export default async function ProbioticsComparePage() {
  const supabase = await createClient();

  const { data: root } = await supabase
    .from("ingredients")
    .select("id")
    .eq("slug", "probiotics")
    .eq("is_published", true)
    .maybeSingle();

  const strains = root
    ? (
        await supabase
          .from("ingredients")
          .select("id, slug, canonical_name_ko, display_name, scientific_name, standardization_info")
          .eq("parent_ingredient_id", root.id)
          .eq("is_published", true)
      ).data ?? []
    : [];

  const strainMeta = new Map(strains.map((s) => [s.id, s]));

  const claimRows = strains.length
    ? ((
        await supabase
          .from("ingredient_claims")
          .select("ingredient_id, evidence_grade, evidence_summary, allowed_expression, is_regulator_approved, claims(claim_code, claim_name_ko)")
          .in("ingredient_id", Array.from(strainMeta.keys()))
      ).data ?? [])
    : [];

  const inputs: StrainClaimInput[] = (claimRows as StrainClaimRow[])
    .map((row) => {
      const claim = firstClaim(row.claims);
      const meta = strainMeta.get(row.ingredient_id);
      if (!claim?.claim_code || !meta) return null;
      if (!AXIS_CODES.includes(claim.claim_code)) return null;
      return {
        ingredientId: row.ingredient_id,
        slug: meta.slug,
        strainName:
          meta.display_name ?? normalizeProbioticStrainNameForDisplay(meta.canonical_name_ko),
        scientificName: meta.scientific_name,
        cfuText: meta.standardization_info,
        claimCode: claim.claim_code,
        claimNameKo: claim.claim_name_ko,
        evidenceGrade: row.evidence_grade,
        evidenceSummary: row.evidence_summary,
        allowedExpression: row.allowed_expression,
        isRegulatorApproved: row.is_regulator_approved === true,
      } satisfies StrainClaimInput;
    })
    .filter((v): v is StrainClaimInput => v !== null);

  const groups = buildBenefitGroups(inputs);

  return (
    <div className="mx-auto max-w-4xl px-4 py-12">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">유산균, 균주에 따라 효과가 다릅니다</h1>
        <p className="mt-3 text-gray-600">
          같은 &ldquo;유산균&rdquo;이라도 균주(strain)마다 입증된 효능과 근거 수준이 다릅니다.
          효능을 먼저 고르면, 그 효능에 강한 균주가 근거 순으로 나열됩니다.
        </p>
        {/* 범례: 규제 vs 학술 분리(법적 요구) */}
        <div className="mt-4 flex flex-wrap gap-x-6 gap-y-2 rounded-xl border border-gray-100 bg-gray-50 p-4 text-xs text-gray-600">
          <span><strong className="text-emerald-700">식약처 인정</strong> — 규제기관이 기능성을 인정한 균주</span>
          <span><strong className="text-gray-700">근거 A~C</strong> — 학술 연구의 근거 수준(A가 가장 강함)</span>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>
            <span className="flex items-center gap-2">
              <FlaskConical className="h-5 w-5 text-green-600" />
              균주별 효능 비교
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {groups.length > 0 ? (
            <StrainBenefitComparison groups={groups} />
          ) : (
            <p className="rounded-lg border border-dashed border-gray-200 bg-gray-50 p-4 text-sm text-gray-500">
              비교할 균주 데이터가 아직 준비되지 않았습니다.
            </p>
          )}
        </CardContent>
      </Card>

      {/* 의료 면책 조항 (법적 필수) */}
      <div className="mt-12 rounded-lg border border-yellow-200 bg-yellow-50 p-4 text-xs text-yellow-800">
        <p className="font-medium">의료 면책 조항</p>
        <p className="mt-1">
          본 정보는 의학적 조언이 아닙니다. 건강 관련 결정은 반드시 의료 전문가와 상담하세요.{" "}
          <Link href="/disclaimer" className="underline">
            자세히 보기
          </Link>
        </p>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: 타입체크 통과 확인**

Run (in `web/`): `npx tsc --noEmit`
Expected: 에러 없음. (`display_name` 컬럼이 select 결과 타입에 없다는 에러가 나면, 해당 select 결과를 명시적 인터페이스로 캐스팅하거나 `.select("...")` 문자열에 컬럼이 포함되어 있는지 확인.)

- [ ] **Step 3: 프로덕션 빌드로 페이지 컴파일 확인**

Run (in `web/`): `npm run build`
Expected: 빌드 성공, `/probiotics` 라우트가 빌드 출력에 나타남.

- [ ] **Step 4: 커밋**

```bash
git add web/src/app/probiotics/page.tsx
git commit -m "feat: add /probiotics strain benefit comparison page"
```

---

## Task 4: 진입 링크 추가

**Files:**
- Modify: `web/src/app/ingredients/[slug]/page.tsx`

**Interfaces:**
- Consumes: 기존 페이지의 `isProbiotic` 불리언(파일 내 이미 계산됨), `Link`(이미 import됨), `Card`/`CardHeader`/`CardTitle`/`CardContent`(이미 import됨).

- [ ] **Step 1: probiotics 계열 페이지에 진입 카드 추가**

`web/src/app/ingredients/[slug]/page.tsx`에서, `<div className="space-y-8">` 바로 다음(프로폴리스 카드 블록 위 또는 `BenefitHexagon` 위)에 아래 블록을 추가한다. 조건 `isProbiotic`는 파일 내 이미 정의되어 있다:

```tsx
        {isProbiotic && (
          <Link
            href="/probiotics"
            className="flex items-center justify-between rounded-2xl border border-emerald-200 bg-emerald-50/60 p-4 transition-colors hover:bg-emerald-50"
          >
            <div>
              <p className="font-semibold text-emerald-900">유산균 균주별 효능 비교 보기</p>
              <p className="mt-0.5 text-sm text-emerald-700">
                장건강·면역·정신건강·체지방 효능별로 균주를 근거등급과 함께 비교합니다.
              </p>
            </div>
            <span className="text-sm font-semibold text-emerald-700">비교 →</span>
          </Link>
        )}
```

- [ ] **Step 2: 타입체크/린트/빌드 확인**

Run (in `web/`): `npx tsc --noEmit && npm run lint && npm run build`
Expected: 에러 없음, 빌드 성공.

- [ ] **Step 3: 커밋**

```bash
git add web/src/app/ingredients/[slug]/page.tsx
git commit -m "feat: link to /probiotics from probiotic ingredient pages"
```

---

## Task 5: 통합 검증

**Files:** (없음 — 검증만)

- [ ] **Step 1: 전체 테스트·타입·린트·빌드**

Run (in `web/`): `npm test && npx tsc --noEmit && npm run lint && npm run build`
Expected: 모두 통과.

- [ ] **Step 2: 개발 서버로 실제 렌더 검증**

Run (in `web/`): `npm run dev` 후 `http://localhost:3000/probiotics` 접속.
확인 항목(수동):
- 효능 탭(장건강·면역·정신건강·체지방)이 데이터 있는 축만 노출되고 탭 전환이 동작한다.
- 각 축에서 **식약처 인정 균주가 위**, 그다음 근거등급 A>B>C 순으로 정렬된다.
- 식약처 인정 배지(emerald)와 근거등급 배지가 시각적으로 구분된다.
- `허용 표현:`은 식약처 인정 행에만 나타난다.
- 정신건강 축에 **R0052+R0175 조합 행이 하나**로 나오고 `조합 전용` 배지가 붙으며 균주명 링크가 없다.
- 각 균주명(조합 제외)은 `/ingredients/[slug]`로 이동한다.
- 권장 CFU가 표시된다.
- 페이지 하단에 의료 면책 조항이 있다.
- `/ingredients/probiotics`(및 임의 균주 페이지)에 `/probiotics` 진입 카드가 보인다.

- [ ] **Step 3: 최종 확인(정리)**

`.playwright-mcp/` 등 미추적 산출물이 커밋에 포함되지 않았는지 `git status`로 확인.
```

---

## Self-Review

**Spec coverage (spec 각 절 → task 매핑):**
- §3.1 효능 우선 → Task 1 축 구조 + Task 2 탭.
- §3.2 신규 `/probiotics` 페이지 → Task 3.
- §3.3 화면 구조/탭/기본선택/0건 축 미노출 → Task 1 `buildBenefitGroups`(빈 축 제거) + Task 2 `groups[0]` 기본선택.
- §3.4 행 3요소(등급+배지 / 요약+허용표현 / CFU) → Task 2 `StrainRowCard`.
- §3.5 정렬(식약처→등급→이름) → Task 1 `sortRows` + Task 1 Step 4 테스트.
- §3.6 조합 균주 병합 → Task 1 `mergeCombination` + 테스트.
- §4 컴플라이언스(규제/학술 분리, 허용표현 조건, 범례, 면책) → Task 2(조건부 허용표현·배지 분리) + Task 3(범례·면책).
- §5 데이터흐름/컴포넌트 경계 → Task 1(순수)·Task 2(클라)·Task 3(서버 fetch).
- §6 범위밖(YAGNI) → 어떤 task도 /compare·전치매트릭스·행별 제품링크·마이그레이션을 추가하지 않음.
- §7 테스트 → Task 1(vitest) + Task 5(빌드/린트/수동).
- §8 진입동선 → Task 4. (랜딩 카드는 spec에서 "선택"이라 이번 계획에서는 균주 상세 진입만 필수로 포함; 랜딩은 범위에서 제외해 단순화.)

**Placeholder scan:** "TODO/TBD/적절히 처리" 없음. 모든 코드 스텝에 실제 코드 포함. 통과.

**Type consistency:** `StrainClaimInput`/`StrainRow`/`BenefitGroup` 필드명이 Task 1 정의 ↔ Task 2/3 사용 간 일치(`claimCode`, `evidenceGrade`, `isRegulatorApproved`, `isCombination`, `cfuText`, `href`, `strainName`). `buildBenefitGroups`/`PROBIOTIC_BENEFIT_AXES` 이름 일관. 통과.
