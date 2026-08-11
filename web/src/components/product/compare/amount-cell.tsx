import { Badge } from "@/components/ui/badge";
import { cn, getIngredientRoleLabel } from "@/lib/utils";
import type { ComparisonCell, IngredientComparisonRow } from "@/lib/compare/compare-math";

export function AmountCell({
  cell,
  row,
  highlighted,
}: {
  cell: ComparisonCell;
  row: IngredientComparisonRow;
  highlighted?: boolean;
}) {
  if (!cell.ingredient) {
    return <div className="py-3 text-center text-sm text-stone-300">—</div>;
  }

  const amount = cell.amount;
  const isComparable =
    row.isComparable &&
    amount?.normalizedValue !== null &&
    row.maxComparableValue !== null &&
    row.maxComparableValue > 0;
  const comparableAmountValue = isComparable ? amount?.normalizedValue ?? null : null;
  const ratio =
    comparableAmountValue !== null && row.maxComparableValue !== null
      ? Math.max(8, (comparableAmountValue / row.maxComparableValue) * 100)
      : 0;
  const isMax = comparableAmountValue !== null && comparableAmountValue === row.maxComparableValue;

  return (
    <div
      className={cn(
        "rounded-xl border px-3 py-3",
        highlighted ? "border-orange-200 bg-surface" : "border-stone-200 bg-stone-50/60",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="text-sm font-semibold text-ink">
            {amount?.displayText ?? "함량 정보 없음"}
          </div>
          <div className="mt-1 text-[11px] text-ink-faint">
            {getIngredientRoleLabel(cell.ingredient.ingredient_role)}
          </div>
        </div>
        {isMax && (
          <Badge variant="promo" className="text-[11px]">
            최대
          </Badge>
        )}
      </div>

      {isComparable ? (
        <div className="mt-3">
          <div className="h-2 rounded-full bg-stone-200">
            <div
              className="h-2 rounded-full bg-brand transition-all"
              style={{ width: `${Math.min(ratio, 100)}%` }}
            />
          </div>
        </div>
      ) : (
        <div className="mt-3 text-[11px] text-ink-faint">
          {row.productCount >= 2 ? "상대 비교 없음" : "단독 포함"}
        </div>
      )}
    </div>
  );
}
