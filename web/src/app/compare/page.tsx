import { createClient } from "@/lib/supabase/server";
import { CompareWorkbench, type Product } from "@/components/product/compare-workbench";

// The full published-products list backing the compare picker changes
// whenever the KR/US gov pipeline publishes/unpublishes products, and this
// page has no other cache-invalidation path — keep it per-request fresh,
// matching /products/page.tsx's own force-dynamic choice.
export const dynamic = "force-dynamic";

const PRODUCTS_BATCH_SIZE = 1000;

// Mirrors the browser batch-fetch this page used to delegate to
// CompareWorkbench: same columns, same is_published filter, same `id`
// ordering, same 1,000-row range loop (full-table semantics preserved).
async function fetchAllPublishedProducts(): Promise<Product[]> {
  const supabase = await createClient();
  const products: Product[] = [];

  for (let offset = 0; ; offset += PRODUCTS_BATCH_SIZE) {
    const { data, error } = await supabase
      .from("products")
      .select("id, product_name, manufacturer_name, country_code")
      .eq("is_published", true)
      .order("id")
      .range(offset, offset + PRODUCTS_BATCH_SIZE - 1);

    if (error) {
      throw new Error(`compare 페이지 products 목록 조회 실패: ${error.message}`);
    }

    const rows = data ?? [];
    if (rows.length === 0) {
      break;
    }

    products.push(...rows);

    if (rows.length < PRODUCTS_BATCH_SIZE) {
      break;
    }
  }

  return products;
}

export default async function ComparePage() {
  const initialProducts = await fetchAllPublishedProducts();

  return <CompareWorkbench initialProducts={initialProducts} />;
}
