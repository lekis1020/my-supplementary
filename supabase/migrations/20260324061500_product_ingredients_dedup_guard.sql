-- Prevent duplicate rows in product_ingredients by (product_id, ingredient_id)
-- 1) clean existing duplicates
-- 2) add UNIQUE guard index

BEGIN;

WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY product_id, ingredient_id
      ORDER BY
        CASE
          WHEN ingredient_role = 'active' THEN 3
          WHEN ingredient_role = 'supporting' THEN 2
          WHEN ingredient_role = 'capsule' THEN 1
          ELSE 0
        END DESC,
        CASE WHEN amount_per_serving IS NOT NULL THEN 1 ELSE 0 END DESC,
        CASE WHEN daily_amount IS NOT NULL THEN 1 ELSE 0 END DESC,
        LENGTH(COALESCE(raw_label_name, '')) DESC,
        updated_at DESC,
        id DESC
    ) AS rn
  FROM public.product_ingredients
)
DELETE FROM public.product_ingredients pi
USING ranked r
WHERE pi.id = r.id
  AND r.rn > 1;

COMMIT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_ingredients_product_ingredient_unique
  ON public.product_ingredients (product_id, ingredient_id);

