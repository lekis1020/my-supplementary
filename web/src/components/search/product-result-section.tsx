import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { HighlightMatch } from "@/components/ui/highlight";
import { getIngredientRoleLabel } from "@/lib/utils";

export interface ProductSearchResult {
  id: number;
  title: string;
  subtitle: string | null;
  href: string;
  directNameMatch: boolean;
  saleVerified: boolean;
  activeMatches: string[];
  supportingMatches: string[];
}

export function ProductResultSection({
  title,
  description,
  products,
  query,
}: {
  title: string;
  description: string;
  products: ProductSearchResult[];
  query: string;
}) {
  if (products.length === 0) return null;

  return (
    <section>
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h3 className="text-lg font-bold text-ink">{title}</h3>
          <p className="mt-1 text-sm text-ink-muted">{description}</p>
        </div>
        <Badge variant="tag">{products.length.toLocaleString()}개</Badge>
      </div>

      <div className="space-y-3">
        {products.map((product) => (
          <Link
            key={product.id}
            href={product.href}
            className="block rounded-2xl border border-stone-200 bg-surface p-5 transition-colors hover:border-brand hover:bg-brand-bg/30"
          >
            <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
              <div>
                <p className="text-lg font-semibold text-ink">
                  <HighlightMatch text={product.title} query={query} />
                </p>
                {product.subtitle && (
                  <p className="mt-1 text-sm text-ink-muted">
                    <HighlightMatch text={product.subtitle} query={query} />
                  </p>
                )}
              </div>

              <div className="flex flex-wrap gap-2">
                {product.saleVerified ? (
                  <Badge variant="promo">판매 확인</Badge>
                ) : (
                  <Badge variant="tag">식약처 신고 정보</Badge>
                )}
                {product.directNameMatch && (
                  <Badge variant="outline">제품명 일치</Badge>
                )}
                {product.activeMatches.length > 0 && (
                  <Badge variant="promo">
                    {getIngredientRoleLabel("active")} {product.activeMatches.length}개
                  </Badge>
                )}
                {product.supportingMatches.length > 0 && (
                  <Badge className="bg-amber-50 text-amber-800">
                    {getIngredientRoleLabel("supporting")} {product.supportingMatches.length}개
                  </Badge>
                )}
              </div>
            </div>

            {product.activeMatches.length > 0 && (
              <p className="mt-3 text-sm text-ink-muted">
                <span className="font-medium text-ink">주성분:</span>{" "}
                {product.activeMatches.join(", ")}
              </p>
            )}

            {product.supportingMatches.length > 0 && (
              <p className="mt-2 text-sm text-ink-faint">
                <span className="font-medium text-ink-muted">부원료:</span>{" "}
                {product.supportingMatches.join(", ")}
              </p>
            )}
          </Link>
        ))}
      </div>
    </section>
  );
}
