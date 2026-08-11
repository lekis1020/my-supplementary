// Hero region for `/ingredients/[slug]`: breadcrumb, identity header, the
// evidence/approval/caution summary dashboard, and overview text — plus the
// two identity-adjacent navigation blocks that used to render immediately
// below it (probiotics comparison banner, propolis family card). Moved out
// of `web/src/app/ingredients/[slug]/page.tsx` (former Breadcrumb/Header +
// the first `<Card>` block after it) as part of the warm-commerce redesign.
import Link from "next/link";
import { ArrowLeft, Pill } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { RegulatoryBadge } from "@/components/ui/domain-badges";
import { SummaryStat } from "@/components/ui/summary-stat";
import { getIngredientCategoryLabel, getIngredientTypeLabel, type IngredientCategory } from "@/lib/utils";

interface IngredientHeroProps {
  ingredient: {
    id: number;
    canonical_name_ko: string;
    canonical_name_en: string | null;
    scientific_name: string | null;
    description: string | null;
    form_description: string | null;
    standardization_info: string | null;
    ingredient_type: string;
  };
  category: IngredientCategory;
  displayIngredientName: string;
  summary: {
    topEvidenceGrade: string | null;
    approvedClaimCount: number;
    cautionCount: number;
  };
  hasApprovedClaim: boolean;
  approvalCountryCode?: string;
  isProbiotic: boolean;
  propolisFamilyRoot: { id: number; canonical_name_ko: string } | null;
  propolisFamilyChildren: Array<{ id: number; canonical_name_ko: string }>;
}

export function IngredientHero({
  ingredient,
  category,
  displayIngredientName,
  summary,
  hasApprovedClaim,
  approvalCountryCode,
  isProbiotic,
  propolisFamilyRoot,
  propolisFamilyChildren,
}: IngredientHeroProps) {
  return (
    <>
      {/* Breadcrumb */}
      <div className="mb-6 flex flex-wrap items-center gap-2 text-sm text-ink-faint">
        <Link href="/ingredients" className="inline-flex items-center gap-1 hover:text-ink">
          <ArrowLeft className="h-4 w-4" />
          원료 사전
        </Link>
        <span>/</span>
        <Link href={`/ingredients/category/${category}`} className="hover:text-ink">
          {getIngredientCategoryLabel(category)}
        </Link>
        <span>/</span>
        <span className="font-medium text-ink">{displayIngredientName}</span>
      </div>

      {/* Hero: identity + 요약 대시보드 + 개요 */}
      <Card tone="highlight" className="mb-8">
        <div className="flex flex-wrap items-center gap-3">
          <h1 className="text-2xl font-extrabold text-ink">{displayIngredientName}</h1>
          <Badge variant="tag">{getIngredientTypeLabel(ingredient.ingredient_type)}</Badge>
          {hasApprovedClaim && <RegulatoryBadge countryCode={approvalCountryCode} />}
        </div>

        <div className="mt-4 grid grid-cols-3 gap-3">
          <SummaryStat value={summary.topEvidenceGrade ?? "—"} label="최고 근거등급" accent="brand" />
          <SummaryStat value={summary.approvedClaimCount} label="인정 효능" accent="regulatory" />
          <SummaryStat value={summary.cautionCount} label="주의사항" accent="danger" />
        </div>

        <div className="mt-4 space-y-1 text-sm text-ink-muted">
          {displayIngredientName !== ingredient.canonical_name_ko && (
            <p>원료 표기: {ingredient.canonical_name_ko}</p>
          )}
          {ingredient.canonical_name_en && <p>{ingredient.canonical_name_en}</p>}
          {ingredient.scientific_name && <p className="italic">{ingredient.scientific_name}</p>}
          {ingredient.description && <p>{ingredient.description}</p>}
          {ingredient.form_description && (
            <p>
              <strong className="text-ink">주요 형태:</strong> {ingredient.form_description}
            </p>
          )}
          {ingredient.standardization_info && (
            <p>
              <strong className="text-ink">표준화:</strong> {ingredient.standardization_info}
            </p>
          )}
        </div>
      </Card>

      {isProbiotic && (
        <Link
          href="/probiotics"
          className="mb-8 flex items-center justify-between rounded-2xl border border-emerald-200 bg-emerald-50/60 p-4 transition-colors hover:bg-emerald-50"
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

      {propolisFamilyRoot && propolisFamilyChildren.length > 0 && (
        <Card className="mb-8">
          <CardHeader>
            <CardTitle>
              <span className="flex items-center gap-2">
                <Pill className="h-5 w-5 text-emerald-600" />
                프로폴리스추출물 하위 카테고리
              </span>
            </CardTitle>
            <p className="mt-1 text-sm text-ink-muted">
              프로폴리스 관련 복합 표기를 한 곳에서 탐색할 수 있도록 연결했습니다.
            </p>
          </CardHeader>
          <CardContent>
            <div className="mb-3 flex flex-wrap gap-2">
              <Badge className="bg-emerald-50 text-emerald-700">상위 카테고리</Badge>
              <Link
                href={`/ingredients/${propolisFamilyRoot.id}`}
                className="text-sm font-semibold text-emerald-700 hover:underline"
              >
                {propolisFamilyRoot.canonical_name_ko}
              </Link>
            </div>
            <div className="flex flex-wrap gap-2">
              {propolisFamilyChildren.map((child) => (
                <Link
                  key={child.id}
                  href={`/ingredients/${child.id}`}
                  className={[
                    "rounded-full border px-3 py-1.5 text-sm transition-colors",
                    child.id === ingredient.id
                      ? "border-emerald-600 bg-emerald-600 text-white"
                      : "border-stone-200 bg-stone-50 text-ink-muted hover:border-emerald-200 hover:text-emerald-700",
                  ].join(" ")}
                >
                  {child.canonical_name_ko}
                </Link>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </>
  );
}
