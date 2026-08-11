// 판매중인 관련 제품 섹션 for `/ingredients/[slug]`. Moved out of
// `web/src/app/ingredients/[slug]/page.tsx` (former `{/* 판매중인 관련 제품 */}`
// Card block, including the `<LiveSearchFallback>` real-time fallback
// branch) as part of the warm-commerce redesign. Server component,
// display-only — verified product fetch stays in
// `@/lib/data/ingredient-detail`. This is the purchase-conversion section,
// so the CollapsibleSection renders open by default.
import Link from "next/link";
import { ExternalLink, Pill } from "lucide-react";
import { CollapsibleSection } from "@/components/ui/collapsible-section";
import { CTAButton } from "@/components/ui/cta-button";
import { LiveSearchFallback } from "@/components/product/live-search-fallback";
import type { IngredientDetail } from "@/lib/data/ingredient-detail";

interface RelatedProductsSectionProps {
  verifiedProducts: IngredientDetail["verifiedProducts"];
  verifiedProductCount: number;
  productCount: number;
  ingredientId: number;
  ingredientNameKo: string;
}

export function RelatedProductsSection({
  verifiedProducts,
  verifiedProductCount,
  productCount,
  ingredientId,
  ingredientNameKo,
}: RelatedProductsSectionProps) {
  return (
    <CollapsibleSection title="판매중인 관련 제품" count={verifiedProductCount} defaultOpen>
      <p className="text-sm text-ink-muted">
        {verifiedProductCount > 0
          ? `실제 판매가 확인된 제품 ${verifiedProductCount.toLocaleString()}개가 이 원료를 포함하고 있습니다.`
          : "아직 판매가 확인된 관련 제품이 없어, 실시간 검색 결과로 보완합니다."}
      </p>

      {verifiedProducts.length > 0 && (
        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {verifiedProducts.map((product) => (
            <div
              key={product.id}
              className="group rounded-2xl border border-stone-200 bg-surface p-3 transition-colors hover:border-brand"
            >
              <Link href={`/products/${product.id}`} className="block">
                <div className="relative mb-3 flex h-28 items-center justify-center overflow-hidden rounded-xl border border-stone-100 bg-surface">
                  {product.product_image_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={product.product_image_url}
                      alt={product.product_name ?? ""}
                      className="h-full w-full object-contain"
                      loading="lazy"
                    />
                  ) : (
                    <Pill className="h-8 w-8 text-stone-300" />
                  )}
                </div>
                <p className="line-clamp-2 text-sm font-semibold text-ink group-hover:text-orange-700">
                  {product.product_name}
                </p>
                {product.brand_name && (
                  <p className="mt-1 text-xs text-ink-faint">{product.brand_name}</p>
                )}
              </Link>
              {product.sale_url && (
                <CTAButton
                  variant="outline"
                  href={product.sale_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-2 gap-1 px-2 py-1 text-xs"
                >
                  구매처 확인됨
                  <ExternalLink className="h-3 w-3" />
                </CTAButton>
              )}
            </div>
          ))}
        </div>
      )}

      {/* DB에 판매확인 제품이 부족하면 실시간 검색으로 폴백 */}
      <LiveSearchFallback
        query={ingredientNameKo}
        initialCount={verifiedProducts.length}
        threshold={3}
      />

      {productCount > 0 && (
        <div className="mt-6 flex flex-wrap items-center gap-3 rounded-2xl border border-stone-200 bg-stone-50 p-4">
          <p className="text-sm leading-6 text-ink-muted">
            식약처 신고 기준으로는 총 {productCount.toLocaleString()}개 제품이 이 원료를
            포함하고 있습니다.
          </p>
          <CTAButton variant="primary" href={`/products?ingredientId=${ingredientId}`}>
            제품 데이터베이스에서 보기
          </CTAButton>
        </div>
      )}
    </CollapsibleSection>
  );
}
