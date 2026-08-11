import { Badge } from "@/components/ui/badge";
import { formatProductName } from "@/lib/utils";
import type { ProbioticStrainGroup } from "@/lib/compare/compare-math";
import type { Product } from "../compare-workbench";

// NOTE on grid unification: this table's structure (scroll wrapper, header
// row, grid-template-columns row layout) superficially resembles
// ComparisonSection's, but the actual cell content diverges enough that a
// shared `comparison-table.tsx` would need render-prop slots for nearly every
// cell (row label: plain text here vs a linked ingredient name with 3
// conditional badges there; per-product cell: inline present/absent badge
// here vs the bar-chart AmountCell there; header cell: bare product name here
// vs name+manufacturer+focus-highlight there). Forcing a shared component
// would trade two straightforward ~90-line files for one generic component
// with more prop surface than markup it saves, so the tables stay separate.
export function ProbioticStrainSection({
  group,
  selectedProducts,
}: {
  group: ProbioticStrainGroup;
  selectedProducts: Product[];
}) {
  return (
    <section>
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <h3 className="text-lg font-bold text-ink">{group.subgroup}</h3>
        <Badge variant="tag">{group.rows.length.toLocaleString()}개</Badge>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-stone-200 bg-surface shadow-card">
        <div className="min-w-[760px]">
          <div
            className="grid gap-0 border-b border-stone-200 bg-stone-50"
            style={{
              gridTemplateColumns: `minmax(240px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
            }}
          >
            <div className="px-4 py-3 text-sm font-semibold text-ink-muted">균주</div>
            {selectedProducts.map((product) => (
              <div
                key={product.id}
                className="border-l border-stone-200 px-4 py-3 text-xs font-semibold text-ink"
              >
                {formatProductName(product.product_name)}
              </div>
            ))}
          </div>

          <div className="divide-y divide-stone-100">
            {group.rows.map((row) => (
              <div
                key={row.key}
                className="grid gap-0"
                style={{
                  gridTemplateColumns: `minmax(240px, 1.1fr) repeat(${selectedProducts.length}, minmax(160px, 1fr))`,
                }}
              >
                <div className="px-4 py-4">
                  <p className="font-semibold text-ink">{row.label}</p>
                  <p className="mt-1 text-xs text-ink-faint">
                    {row.productCount >= 2 ? `공통 ${row.productCount}개 제품` : "단일 제품 표기"}
                  </p>
                </div>

                {row.cells.map((cell) => (
                  <div key={`${row.key}-${cell.productId}`} className="border-l border-stone-100 px-4 py-4">
                    {cell.present ? (
                      <div className="space-y-2">
                        <Badge variant="promo" className="text-[11px]">
                          표기됨
                        </Badge>
                        {cell.amountTexts.length > 0 && (
                          <p className="text-xs font-medium text-ink">{cell.amountTexts[0]}</p>
                        )}
                        {cell.rawLabels.length > 0 && (
                          <p className="line-clamp-2 text-[11px] text-ink-faint">{cell.rawLabels[0]}</p>
                        )}
                      </div>
                    ) : (
                      <div className="py-2 text-center text-sm text-stone-300">—</div>
                    )}
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
