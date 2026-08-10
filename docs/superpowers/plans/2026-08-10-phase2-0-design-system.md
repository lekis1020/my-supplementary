# Phase 2-0: 웜 커머스 디자인 시스템 구축 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 선셋 앰버 팔레트 토큰, Pretendard 폰트, 재구축된 UI 프리미티브(Badge/Card/신규 4종)로 디자인 시스템 기반을 만든다 — 페이지 마이그레이션은 하지 않는다(Phase 2-2+ 담당).

**Architecture:** Tailwind 4 `@theme` 토큰을 `globals.css`에 선언하고, `components/ui/`의 프리미티브가 토큰만 참조한다. 규제/근거/주의 색은 팔레트 독립 예약 토큰. 기존 페이지는 이 플랜에서 수정하지 않으며, 전역 폰트·배경 변경 외에는 기존 화면에 영향이 없어야 한다(기존 Badge/Card 호출부는 className 오버라이드를 그대로 사용하므로 동작 유지).

**Tech Stack:** Next.js 16 (App Router), Tailwind CSS 4 (`@theme`), next/font/local + pretendard(npm), vitest.

## Global Constraints

- 브랜치: `feat/design-system` (design/warm-commerce-redesign에서 분기, 이미 체크아웃됨). main/design 브랜치 직접 커밋 금지.
- 커밋: conventional commits + 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. 스테이징은 항상 명시적 경로 — **`git add -A` 금지**.
- 각 태스크 종료 시 `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build` 통과 (Task 7은 test/lint 포함 전체 게이트).
- UI 문자열 한국어, 코드·주석 영어.
- 페이지 파일(`web/src/app/**`) 수정 금지 — 예외: `layout.tsx`(폰트), `design-lab/system/page.tsx`(신규 쇼케이스).
- 규제 분리 요건: `--color-regulatory*` 토큰과 `RegulatoryBadge`는 블루 고정, 팔레트 변경과 무관.
- 환경: 셸 `cd`가 zoxide를 경유하므로 단일 복합 명령(`cd /path && cmd`) 사용. `npm run build`는 수 분 소요가 정상.

---

### Task 1: Pretendard 폰트 도입

**Files:**
- Modify: `web/package.json` (pretendard 의존성)
- Modify: `web/src/app/layout.tsx`
- Modify: `web/src/app/globals.css` (font-sans 변수 연결)

**Interfaces:**
- Produces: CSS 변수 `--font-pretendard`, Tailwind `font-sans`가 Pretendard를 가리킴. 이후 태스크·페이지는 별도 폰트 설정 불필요.

- [ ] **Step 1: 패키지 설치**

```bash
cd /Users/napler/projects/my-supple/web && npm install pretendard
```

- [ ] **Step 2: layout.tsx에 next/font/local 연결**

`web/src/app/layout.tsx` 상단에 추가하고 `<html>`에 변수 클래스를 부여:

```tsx
import localFont from "next/font/local";

const pretendard = localFont({
  src: "../../node_modules/pretendard/dist/web/variable/woff2/PretendardVariable.woff2",
  display: "swap",
  weight: "45 920",
  variable: "--font-pretendard",
});
```

`<html lang="ko">` → `<html lang="ko" className={pretendard.variable}>`

- [ ] **Step 3: globals.css의 폰트 변수 교체**

기존 `@theme inline` 블록의

```css
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
```

를 다음으로 교체 (geist 참조 제거):

```css
  --font-sans: var(--font-pretendard), ui-sans-serif, system-ui, "Apple SD Gothic Neo",
    "Malgun Gothic", sans-serif;
```

`body`에 `font-family: var(--font-sans);` 가 적용되도록 기존 body 규칙에 한 줄 추가.

- [ ] **Step 4: 검증**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공. 빌드 출력에 폰트 최적화 에러 없음. `grep -rn "geist" web/src` → 출력 없음.

- [ ] **Step 5: Commit**

```bash
git add web/package.json web/package-lock.json web/src/app/layout.tsx web/src/app/globals.css
git commit -m "feat: adopt Pretendard variable font via next/font

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 디자인 토큰 선언 (컬러·그림자)

**Files:**
- Modify: `web/src/app/globals.css`

**Interfaces:**
- Produces: Tailwind 유틸리티 — `bg-brand`, `bg-brand-soft`, `bg-brand-bg`, `bg-canvas`, `bg-surface`, `text-ink`, `text-ink-muted`, `text-ink-faint`, `text-regulatory`, `bg-regulatory-bg`, `text-danger`, `bg-danger-bg`, `bg-evidence-{a,b,c,d,i}-bg`/`text-evidence-{a,b,c,d,i}`, `shadow-card`, `shadow-card-hover`. 이후 모든 프리미티브·페이지가 이 이름만 사용.

- [ ] **Step 1: @theme 토큰 블록 추가**

`globals.css`의 기존 `@theme inline` 블록 아래에 추가:

```css
@theme {
  /* Warm commerce — sunset amber palette */
  --color-brand: #f97316;
  --color-brand-soft: #fdba74;
  --color-brand-bg: #fff7ed;
  --color-canvas: #fffbf5;
  --color-surface: #ffffff;
  --color-ink: #292524;
  --color-ink-muted: #78716c;
  --color-ink-faint: #a8a29e;

  /* Compliance-reserved tokens — regulatory/evidence colors are legally
     separated from the brand palette and must not follow palette changes */
  --color-regulatory: #1d4ed8;
  --color-regulatory-bg: #eff6ff;
  --color-danger: #dc2626;
  --color-danger-bg: #fef2f2;
  --color-evidence-a: #047857;
  --color-evidence-a-bg: #ecfdf5;
  --color-evidence-b: #4d7c0f;
  --color-evidence-b-bg: #f7fee7;
  --color-evidence-c: #b45309;
  --color-evidence-c-bg: #fffbeb;
  --color-evidence-d: #c2410c;
  --color-evidence-d-bg: #fff7ed;
  --color-evidence-i: #57534e;
  --color-evidence-i-bg: #f5f5f4;

  --shadow-card: 0 4px 14px rgba(120, 80, 20, 0.08);
  --shadow-card-hover: 0 8px 24px rgba(120, 80, 20, 0.12);
}
```

- [ ] **Step 2: 배경·텍스트 기본값을 토큰으로 전환**

`:root`의 `--background: #ffffff;` → `--background: #fffbf5;`, `--foreground: #171717;` → `--foreground: #292524;` (body는 기존 매핑을 통해 크림 캔버스/웜 잉크가 됨).

- [ ] **Step 3: 검증**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공. 이어서 토큰이 실제 유틸리티로 생성되는지 확인: 쇼케이스 전이므로 `.next` 산출물 grep 대신 Task 6에서 시각 확인 (여기서는 빌드 성공이면 통과).

- [ ] **Step 4: Commit**

```bash
git add web/src/app/globals.css
git commit -m "feat: add warm-commerce design tokens (amber palette, compliance colors)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Badge 재구축 + 도메인 배지

**Files:**
- Modify: `web/src/components/ui/badge.tsx`
- Create: `web/src/components/ui/domain-badges.tsx`

**Interfaces:**
- Consumes: Task 2 토큰
- Produces:
  - `Badge({ children, className, variant })` — `variant?: "neutral" | "tag" | "promo" | "outline"`; **variant 미지정 시 색상 클래스를 추가하지 않아** 기존 호출부(className으로 색 지정)와 100% 호환.
  - `RegulatoryBadge({ countryCode? })`, `EvidenceGradeBadge({ grade })`, `SeverityBadge({ level, label? })`
  - 순수 함수(테스트 대상): `badgeVariantClasses(variant)`, `evidenceGradeClasses(grade)`, `severityClasses(level)`

- [ ] **Step 1: badge.tsx 교체**

```tsx
import { cn } from "@/lib/utils";

export type BadgeVariant = "neutral" | "tag" | "promo" | "outline";

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  neutral: "bg-stone-100 text-stone-600",
  tag: "bg-stone-100 text-stone-600",
  promo: "bg-brand-bg text-orange-700",
  outline: "border border-stone-200 text-ink-muted",
};

export function badgeVariantClasses(variant?: BadgeVariant): string {
  return variant ? VARIANT_CLASSES[variant] : "";
}

interface BadgeProps {
  children: React.ReactNode;
  className?: string;
  variant?: BadgeVariant;
}

export function Badge({ children, className, variant }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        badgeVariantClasses(variant),
        className
      )}
    >
      {children}
    </span>
  );
}
```

- [ ] **Step 2: domain-badges.tsx 생성**

```tsx
import { ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";

// Compliance rule: regulator-approved claims render ONLY through this badge —
// blue + official icon + square-ish corners, visually distinct from evidence
// badges regardless of brand palette. Do not restyle per page.
export function RegulatoryBadge({
  countryCode,
  className,
}: {
  countryCode?: string | null;
  className?: string;
}) {
  const label = countryCode === "US" ? "FDA 인정" : "식약처 인정";
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-md border border-blue-200 bg-regulatory-bg px-2 py-0.5 text-xs font-bold text-regulatory",
        className
      )}
    >
      <ShieldCheck className="h-3 w-3" aria-hidden />
      {label}
    </span>
  );
}

export type EvidenceGrade = "A" | "B" | "C" | "D" | "I";

const EVIDENCE_CLASSES: Record<EvidenceGrade, string> = {
  A: "bg-evidence-a-bg text-evidence-a",
  B: "bg-evidence-b-bg text-evidence-b",
  C: "bg-evidence-c-bg text-evidence-c",
  D: "bg-evidence-d-bg text-evidence-d",
  I: "bg-evidence-i-bg text-evidence-i",
};

export function evidenceGradeClasses(grade: string | null | undefined): string {
  const key = (grade ?? "").toUpperCase() as EvidenceGrade;
  return EVIDENCE_CLASSES[key] ?? EVIDENCE_CLASSES.I;
}

export function EvidenceGradeBadge({
  grade,
  className,
}: {
  grade: string | null | undefined;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
        evidenceGradeClasses(grade),
        className
      )}
    >
      근거 {(grade ?? "I").toUpperCase()}
    </span>
  );
}

export type SeverityLevel = "high" | "medium" | "low";

const SEVERITY_CLASSES: Record<SeverityLevel, string> = {
  high: "bg-danger-bg text-danger",
  medium: "bg-evidence-c-bg text-evidence-c",
  low: "bg-stone-100 text-stone-600",
};

const SEVERITY_LABELS: Record<SeverityLevel, string> = {
  high: "주의 높음",
  medium: "주의",
  low: "참고",
};

export function severityClasses(level: string | null | undefined): string {
  return SEVERITY_CLASSES[(level ?? "low") as SeverityLevel] ?? SEVERITY_CLASSES.low;
}

export function SeverityBadge({
  level,
  label,
  className,
}: {
  level: string | null | undefined;
  label?: string;
  className?: string;
}) {
  const key = (level ?? "low") as SeverityLevel;
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
        severityClasses(level),
        className
      )}
    >
      {label ?? SEVERITY_LABELS[key] ?? SEVERITY_LABELS.low}
    </span>
  );
}
```

- [ ] **Step 3: 검증**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공 (기존 Badge 호출부는 variant 미사용이므로 영향 없음 — `grep -rn "variant=" web/src --include="*.tsx" | grep -i badge`로 기존 사용 0건 확인).

- [ ] **Step 4: Commit**

```bash
git add web/src/components/ui/badge.tsx web/src/components/ui/domain-badges.tsx
git commit -m "feat: rebuild Badge with variants; add compliance domain badges

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Card 재정의 (tone/padding variant)

**Files:**
- Modify: `web/src/components/ui/card.tsx`

**Interfaces:**
- Consumes: Task 2 토큰
- Produces: `Card({ children, className, tone, padding })` — `tone?: "surface" | "highlight"` (기본 surface), `padding?: "none" | "sm" | "md"` (기본 md=p-6). CardHeader/CardTitle/CardContent 시그니처 불변(텍스트 색만 stone 토큰화).

- [ ] **Step 1: card.tsx 교체**

```tsx
import { cn } from "@/lib/utils";

type CardTone = "surface" | "highlight";
type CardPadding = "none" | "sm" | "md";

const TONE_CLASSES: Record<CardTone, string> = {
  surface: "border border-stone-200 bg-surface shadow-card",
  highlight: "border border-orange-100 bg-gradient-to-br from-brand-bg to-surface shadow-card",
};

const PADDING_CLASSES: Record<CardPadding, string> = {
  none: "",
  sm: "p-4",
  md: "p-6",
};

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export function Card({
  children,
  className,
  tone = "surface",
  padding = "md",
}: CardProps & { tone?: CardTone; padding?: CardPadding }) {
  return (
    <div className={cn("rounded-2xl", TONE_CLASSES[tone], PADDING_CLASSES[padding], className)}>
      {children}
    </div>
  );
}

export function CardHeader({ children, className }: CardProps) {
  return <div className={cn("mb-4", className)}>{children}</div>;
}

export function CardTitle({ children, className }: CardProps) {
  return (
    <h3 className={cn("text-lg font-semibold text-ink", className)}>{children}</h3>
  );
}

export function CardContent({ children, className }: CardProps) {
  return <div className={cn(className)}>{children}</div>;
}
```

- [ ] **Step 2: 검증**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공. 기존 호출부는 className 오버라이드(rounded-2xl/p-5 등)를 이미 쓰므로 cn 병합상 뒤쪽 className이 우선 — 화면 회귀 최소. (rounded-lg→2xl 기본 변경은 의도된 파운데이션 변경.)

- [ ] **Step 3: Commit**

```bash
git add web/src/components/ui/card.tsx
git commit -m "feat: Card tone/padding variants on design tokens

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: 신규 프리미티브 4종

**Files:**
- Create: `web/src/components/ui/cta-button.tsx`
- Create: `web/src/components/ui/summary-stat.tsx`
- Create: `web/src/components/ui/collapsible-section.tsx`
- Create: `web/src/components/ui/section-header.tsx`

**Interfaces:**
- Consumes: Task 2 토큰, Task 3 Badge
- Produces (이후 페이지 태스크가 사용):
  - `CTAButton({ children, href?, onClick?, variant?, className? })` — `variant?: "primary" | "outline"`; href 있으면 next/link, 없으면 button. 서버 컴포넌트 호환(onClick 미사용 시).
  - `SummaryStat({ value, label, accent? })` — `accent?: "brand" | "regulatory" | "danger"`
  - `CollapsibleSection({ title, count?, defaultOpen?, children })` — 네이티브 `<details>/<summary>` 기반, JS 없음
  - `SectionHeader({ icon?, title, count?, description? })`

- [ ] **Step 1: cta-button.tsx**

```tsx
import Link from "next/link";
import { cn } from "@/lib/utils";

type CTAVariant = "primary" | "outline";

const CTA_CLASSES: Record<CTAVariant, string> = {
  primary: "bg-brand text-white hover:bg-orange-600 shadow-card",
  outline: "border border-stone-300 text-ink hover:border-brand hover:text-orange-700 bg-surface",
};

interface CTAButtonProps {
  children: React.ReactNode;
  href?: string;
  onClick?: () => void;
  variant?: CTAVariant;
  className?: string;
}

export function CTAButton({
  children,
  href,
  onClick,
  variant = "primary",
  className,
}: CTAButtonProps) {
  const classes = cn(
    "inline-flex items-center justify-center gap-1.5 rounded-xl px-4 py-2.5 text-sm font-bold transition-colors",
    CTA_CLASSES[variant],
    className
  );
  if (href) {
    return (
      <Link href={href} className={classes}>
        {children}
      </Link>
    );
  }
  return (
    <button type="button" onClick={onClick} className={classes}>
      {children}
    </button>
  );
}
```

- [ ] **Step 2: summary-stat.tsx**

```tsx
import { cn } from "@/lib/utils";

type StatAccent = "brand" | "regulatory" | "danger";

const ACCENT_CLASSES: Record<StatAccent, string> = {
  brand: "text-orange-600",
  regulatory: "text-regulatory",
  danger: "text-danger",
};

export function SummaryStat({
  value,
  label,
  accent = "brand",
  className,
}: {
  value: React.ReactNode;
  label: string;
  accent?: StatAccent;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-xl bg-surface px-3 py-2.5 text-center shadow-card",
        className
      )}
    >
      <div className={cn("text-xl font-extrabold leading-tight", ACCENT_CLASSES[accent])}>
        {value}
      </div>
      <div className="mt-0.5 text-xs text-ink-muted">{label}</div>
    </div>
  );
}
```

- [ ] **Step 3: collapsible-section.tsx**

```tsx
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

// Server-component-safe accordion: native <details>, zero client JS.
export function CollapsibleSection({
  title,
  count,
  defaultOpen = false,
  children,
  className,
}: {
  title: string;
  count?: number;
  defaultOpen?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <details
      open={defaultOpen}
      className={cn(
        "group rounded-2xl border border-stone-200 bg-surface shadow-card",
        className
      )}
    >
      <summary className="flex cursor-pointer list-none items-center justify-between gap-2 px-5 py-4 [&::-webkit-details-marker]:hidden">
        <span className="flex items-center gap-2 text-base font-bold text-ink">
          {title}
          {typeof count === "number" && <Badge variant="tag">{count}</Badge>}
        </span>
        <ChevronDown
          className="h-4 w-4 text-ink-faint transition-transform group-open:rotate-180"
          aria-hidden
        />
      </summary>
      <div className="border-t border-stone-100 px-5 py-4">{children}</div>
    </details>
  );
}
```

- [ ] **Step 4: section-header.tsx**

```tsx
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

export function SectionHeader({
  icon,
  title,
  count,
  description,
  className,
}: {
  icon?: React.ReactNode;
  title: string;
  count?: number;
  description?: string;
  className?: string;
}) {
  return (
    <div className={cn("mb-4", className)}>
      <div className="flex items-center gap-2">
        {icon && <span className="text-orange-500">{icon}</span>}
        <h2 className="text-lg font-bold text-ink">{title}</h2>
        {typeof count === "number" && <Badge variant="tag">{count}</Badge>}
      </div>
      {description && <p className="mt-1 text-sm text-ink-muted">{description}</p>}
    </div>
  );
}
```

- [ ] **Step 5: 검증 & Commit**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공

```bash
git add web/src/components/ui/cta-button.tsx web/src/components/ui/summary-stat.tsx web/src/components/ui/collapsible-section.tsx web/src/components/ui/section-header.tsx
git commit -m "feat: add CTAButton, SummaryStat, CollapsibleSection, SectionHeader primitives

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: 디자인 시스템 쇼케이스 페이지

**Files:**
- Create: `web/src/app/design-lab/system/page.tsx`

**Interfaces:**
- Consumes: Task 2–5 전부
- Produces: `/design-lab/system` — 토큰 스와치·전 프리미티브 렌더 페이지 (시각 검증·스크린샷 용도, 서버 컴포넌트, DB 접근 없음)

- [ ] **Step 1: 페이지 작성**

서버 컴포넌트로, 다음 섹션을 렌더: (1) 컬러 스와치 그리드 — brand/canvas/ink/regulatory/danger/evidence a–i 각각 `bg-*` 클래스로 칠한 사각형 + 토큰 이름 라벨, (2) Badge 4 variant + RegulatoryBadge(KR/US) + EvidenceGradeBadge(A–I 5종) + SeverityBadge(3종), (3) Card tone 2종 × padding 3종 샘플, (4) CTAButton 2 variant(href/버튼), (5) SummaryStat 3 accent, (6) CollapsibleSection(open/closed) + SectionHeader(아이콘 포함). 각 섹션 제목은 SectionHeader를 직접 사용해 독푸딩. 페이지 제목: "디자인 시스템 — 웜 커머스". `export const metadata = { title: "디자인 시스템" }`.

구현 세부는 위 프리미티브 시그니처를 그대로 사용 (자유도 허용 — 단, 외부 데이터/클라이언트 컴포넌트 금지).

- [ ] **Step 2: 검증**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build`
Expected: 성공, 빌드 라우트 목록에 `○ /design-lab/system` 존재

- [ ] **Step 3: Commit**

```bash
git add web/src/app/design-lab/system
git commit -m "feat: design system showcase page at /design-lab/system

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: 단위 테스트 + 최종 게이트

**Files:**
- Create: `web/src/components/ui/design-system.test.ts`

- [ ] **Step 1: 실패하는 테스트 작성 (TDD-lite — 순수 함수 대상)**

```ts
import { describe, expect, it } from "vitest";
import { badgeVariantClasses } from "@/components/ui/badge";
import {
  evidenceGradeClasses,
  severityClasses,
} from "@/components/ui/domain-badges";

describe("badgeVariantClasses", () => {
  it("returns empty string when variant is omitted (backward compat)", () => {
    expect(badgeVariantClasses(undefined)).toBe("");
  });
  it("maps promo to brand tokens", () => {
    expect(badgeVariantClasses("promo")).toContain("bg-brand-bg");
  });
});

describe("evidenceGradeClasses", () => {
  it("maps grade A to evidence-a tokens", () => {
    expect(evidenceGradeClasses("A")).toContain("evidence-a");
  });
  it("is case-insensitive", () => {
    expect(evidenceGradeClasses("a")).toBe(evidenceGradeClasses("A"));
  });
  it("falls back to I for unknown grades", () => {
    expect(evidenceGradeClasses("Z")).toBe(evidenceGradeClasses("I"));
    expect(evidenceGradeClasses(null)).toBe(evidenceGradeClasses("I"));
  });
});

describe("severityClasses", () => {
  it("maps high to danger tokens", () => {
    expect(severityClasses("high")).toContain("danger");
  });
  it("falls back to low for unknown/null", () => {
    expect(severityClasses(null)).toBe(severityClasses("low"));
    expect(severityClasses("weird")).toBe(severityClasses("low"));
  });
});
```

주의: vitest include 패턴은 `src/**/*.test.ts`이므로 파일 위치·확장자 준수. `.tsx` import가 섞이므로 vitest가 TSX 처리 실패 시 최소 설정 수정은 허용(예: include에 변화 없음, esbuild가 기본 처리).

- [ ] **Step 2: 테스트 실행**

Run: `cd /Users/napler/projects/my-supple/web && npm test`
Expected: 새 테스트 포함 전부 PASS (기존 5개 + 신규 7개)

- [ ] **Step 3: 전체 게이트**

Run: `cd /Users/napler/projects/my-supple/web && npx tsc --noEmit && npm run build && npm run lint`
Expected: tsc 0 에러, 빌드 성공, lint 0 에러(기존 경고 6건 허용)

- [ ] **Step 4: Commit**

```bash
git add web/src/components/ui/design-system.test.ts
git commit -m "test: unit tests for badge variant and compliance color maps

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
