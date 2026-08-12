import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { HighlightMatch } from "@/components/ui/highlight";
import { SectionHeader } from "@/components/ui/section-header";
import type { IngredientSearchResult } from "@/lib/search/ingredient-ranking";

export function IngredientResultSection({
  title,
  description,
  results,
  query,
}: {
  title: string;
  description: string;
  results: IngredientSearchResult[];
  query: string;
}) {
  if (results.length === 0) return null;

  return (
    <section>
      <div className="mb-4 flex items-center justify-between gap-3">
        <SectionHeader title={title} description={description} className="mb-0" />
        <Badge variant="tag">{results.length.toLocaleString()}개</Badge>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        {results.map((result) => (
          <Link
            key={result.id}
            href={result.href}
            className="rounded-2xl border border-stone-200 bg-surface p-5 transition-colors hover:border-brand hover:bg-brand-bg/40"
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="font-semibold text-ink">
                  <HighlightMatch text={result.title} query={query} />
                </p>
                {result.subtitle && (
                  <p className="mt-1 text-sm text-ink-muted">
                    <HighlightMatch text={result.subtitle} query={query} />
                  </p>
                )}
              </div>
              <Badge variant="tag">{result.badge}</Badge>
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
}
