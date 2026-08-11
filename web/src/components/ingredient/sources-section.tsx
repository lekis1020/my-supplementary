// 근거 출처 · 업데이트 현황 섹션 for `/ingredients/[slug]`. Moved out of
// `web/src/app/ingredients/[slug]/page.tsx` (former 출처 Card block, plus the
// module-level `SourceLinkBlock` generic that rendered inside it) as part of
// the warm-commerce redesign. Server component, display-only — source link
// fetch stays in `@/lib/data/ingredient-detail`.
import { ExternalLink } from "lucide-react";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { getClaimMeta, type IngredientDetail } from "@/lib/data/ingredient-detail";

interface SourcesSectionProps {
  sourceLinks: IngredientDetail["sourceLinks"];
  hasEvidenceGap: boolean;
  claimsMissingDirectEvidence: IngredientDetail["claimsMissingDirectEvidence"];
}

export function SourcesSection({
  sourceLinks: { ingredient, claim, evidence },
  hasEvidenceGap,
  claimsMissingDirectEvidence,
}: SourcesSectionProps) {
  return (
    <CollapsibleSection title="근거 출처 · 업데이트 현황">
      <p className="text-sm text-ink-muted">
        원료·기능성·논문 출처를 한 곳에서 확인할 수 있습니다.
      </p>
      <div className="mt-4 space-y-5">
        {hasEvidenceGap && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
            <p className="text-sm font-semibold text-amber-900">
              일부 효능 항목은 근거 문헌 업데이트가 필요합니다.
            </p>
            {claimsMissingDirectEvidence.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-2">
                {claimsMissingDirectEvidence.slice(0, 8).map((claimName) => (
                  <span
                    key={claimName}
                    className="rounded-full border border-amber-200 bg-white px-3 py-1 text-xs font-medium text-amber-800"
                  >
                    {claimName}
                  </span>
                ))}
                {claimsMissingDirectEvidence.length > 8 && (
                  <span className="rounded-full border border-amber-200 bg-white px-3 py-1 text-xs font-medium text-amber-800">
                    외 {claimsMissingDirectEvidence.length - 8}개
                  </span>
                )}
              </div>
            )}
          </div>
        )}

        <SourceLinkBlock title="원료/규제 출처" links={ingredient} />
        <SourceLinkBlock title="기능성 클레임 출처" links={claim} />
        <SourceLinkBlock title="연구 논문 출처" links={evidence} />
      </div>
    </CollapsibleSection>
  );
}

function SourceLinkBlock<
  T extends {
    id: number;
    entity_type: string;
    entity_id: number;
    source_reference: string | null;
    source_excerpt: string | null;
    retrieved_at: string | null;
    sources?: { source_name: string; organization_name: string | null; source_url: string | null } | Array<{ source_name: string; organization_name: string | null; source_url: string | null }> | null;
  },
>({ title, links }: { title: string; links: T[] }) {
  return (
    <section>
      <p className="mb-2 text-sm font-semibold text-ink">{title}</p>

      {links.length === 0 ? (
        <p className="rounded-lg border border-dashed border-stone-200 bg-stone-50 px-3 py-2 text-xs text-ink-faint">
          연결된 출처가 아직 없습니다.
        </p>
      ) : (
        <div className="space-y-2">
          {links.slice(0, 8).map((link) => {
            const source = getClaimMeta(link.sources);
            const href = link.source_reference || source?.source_url || null;
            const retrievedDate = link.retrieved_at
              ? new Date(link.retrieved_at).toLocaleDateString("ko-KR")
              : null;

            return (
              <div key={`${link.id}-${link.entity_type}-${link.entity_id}`} className="rounded-lg border border-stone-200 bg-surface p-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-sm font-semibold text-ink">
                    {source?.source_name ?? "출처"}
                  </span>
                  {source?.organization_name && (
                    <span className="text-xs text-ink-faint">· {source.organization_name}</span>
                  )}
                  {retrievedDate && (
                    <span className="text-xs text-ink-faint">· 수집일 {retrievedDate}</span>
                  )}
                </div>

                {href && (
                  <a
                    href={href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-1 inline-flex items-center gap-1 text-xs font-medium text-indigo-700 hover:underline"
                  >
                    출처 링크 보기
                    <ExternalLink className="h-3.5 w-3.5" />
                  </a>
                )}

                {link.source_excerpt && (
                  <p className="mt-1 text-xs text-ink-faint">{link.source_excerpt}</p>
                )}
              </div>
            );
          })}
          {links.length > 8 && (
            <p className="text-xs text-ink-faint">외 {links.length - 8}건의 출처가 더 있습니다.</p>
          )}
        </div>
      )}
    </section>
  );
}
