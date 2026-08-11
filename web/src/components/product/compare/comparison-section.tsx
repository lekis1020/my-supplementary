import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { SectionHeader } from "@/components/ui/section-header";
import { cn, formatProductName } from "@/lib/utils";
import type { IngredientComparisonRow } from "@/lib/compare/compare-math";
import type { Product } from "../compare-workbench";
import { AmountCell } from "./amount-cell";
import { EmptySection } from "./empty-section";

export function ComparisonSection({
  title,
  description,
  icon,
  rows,
  selectedProducts,
  emptyMessage,
  focusProductId,
}: {
  title: string;
  description: string;
  icon?: React.ReactNode;
  rows: IngredientComparisonRow[];
  selectedProducts: Product[];
  emptyMessage?: string;
  focusProductId?: number;
}) {
  return (
    <section>
      <SectionHeader icon={icon} title={title} count={rows.length} description={description} />

      {rows.length === 0 ? (
        <EmptySection message={emptyMessage || "표시할 항목이 없습니다."} />
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-stone-200 bg-surface shadow-card">
          <div className="min-w-[860px]">
            <div
              className="grid gap-0 border-b border-stone-200 bg-stone-50"
              style={{
                gridTemplateColumns: `minmax(220px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
              }}
            >
              <div className="px-4 py-4 text-sm font-semibold text-ink-muted">원료</div>
              {selectedProducts.map((product) => (
                <div
                  key={product.id}
                  className={cn(
                    "border-l border-stone-200 px-4 py-4 text-sm",
                    focusProductId === product.id ? "bg-brand-bg" : "",
                  )}
                >
                  <div className="font-semibold text-ink">{formatProductName(product.product_name)}</div>
                  <div className="mt-1 text-xs text-ink-faint">
                    {product.manufacturer_name || "제조사 정보 없음"}
                  </div>
                </div>
              ))}
            </div>

            <div className="divide-y divide-stone-100">
              {rows.map((row) => (
                <div
                  key={row.ingredientId}
                  className="grid gap-0"
                  style={{
                    gridTemplateColumns: `minmax(220px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
                  }}
                >
                  <div className="px-4 py-4">
                    <Link
                      href={row.ingredientHref}
                      className="font-semibold text-orange-700 hover:underline"
                    >
                      {row.ingredientName}
                    </Link>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {row.duplicate && (
                        <Badge className="bg-amber-100 text-[11px] text-amber-800">중복</Badge>
                      )}
                      {row.isComparable && row.compareLabel && (
                        <Badge variant="promo" className="text-[11px]">
                          동일 기준 비교 · {row.compareLabel}
                        </Badge>
                      )}
                      {!row.isComparable && row.productCount >= 2 && (
                        <Badge variant="neutral" className="text-[11px]">
                          단위 상이 또는 표기 부족
                        </Badge>
                      )}
                    </div>
                  </div>

                  {row.cells.map((cell) => (
                    <div
                      key={`${row.ingredientId}-${cell.productId}`}
                      className={cn(
                        "border-l border-stone-100 px-4 py-4",
                        focusProductId === cell.productId ? "bg-brand-bg/60" : "",
                      )}
                    >
                      <AmountCell
                        cell={cell}
                        row={row}
                        highlighted={focusProductId === cell.productId}
                      />
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
