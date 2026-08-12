"use client";

import { useState } from "react";
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { EvidenceGradeBadge, RegulatoryBadge } from "@/components/ui/domain-badges";
import type { BenefitGroup, StrainRow } from "@/lib/probiotic-comparison";

function StrainRowCard({ row }: { row: StrainRow }) {
  return (
    <div className="rounded-lg border border-stone-100 bg-stone-50 p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          {row.href ? (
            <Link href={row.href} className="font-medium text-ink hover:text-orange-700">
              {row.strainName}
            </Link>
          ) : (
            <p className="font-medium text-ink">{row.strainName}</p>
          )}
          {row.scientificName && (
            <p className="text-xs italic text-ink-faint">{row.scientificName}</p>
          )}
        </div>
        <div className="flex flex-shrink-0 flex-wrap justify-end gap-1.5">
          {row.evidenceGrade && <EvidenceGradeBadge grade={row.evidenceGrade} />}
          {row.isRegulatorApproved && <RegulatoryBadge countryCode="KR" />}
          {row.isCombination && (
            <Badge className="bg-violet-50 text-violet-700">조합 전용</Badge>
          )}
        </div>
      </div>
      {row.evidenceSummary && (
        <p className="mt-2 text-sm text-ink-muted">{row.evidenceSummary}</p>
      )}
      {row.isRegulatorApproved && row.allowedExpression && (
        <p className="mt-2 inline-block rounded bg-success-bg px-2 py-1 text-xs text-success">
          허용 표현: {row.allowedExpression}
        </p>
      )}
      {row.cfuText && (
        <p className="mt-2 text-xs text-ink-muted">권장 {row.cfuText}</p>
      )}
    </div>
  );
}

export function StrainBenefitComparison({ groups }: { groups: BenefitGroup[] }) {
  const [activeCode, setActiveCode] = useState(groups[0]?.claimCode ?? "");
  const activeGroup = groups.find((g) => g.claimCode === activeCode) ?? groups[0];

  if (!activeGroup) {
    return (
      <p className="rounded-lg border border-dashed border-stone-200 bg-stone-50 p-4 text-sm text-ink-muted">
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
                ? "border-orange-700 bg-orange-700 text-white"
                : "border-stone-200 bg-white text-ink-muted hover:border-orange-200 hover:text-orange-700",
            ].join(" ")}
          >
            {group.label}
          </button>
        ))}
      </div>

      {activeGroup.claimNameKo && (
        <p className="mb-3 text-sm text-ink-muted">
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
