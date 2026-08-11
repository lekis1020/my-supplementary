import { NextResponse } from 'next/server';
import { createClient } from "@/lib/supabase/server";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const { id } = await params;
  const supabase = await createClient();

  const { data: ingredients, error } = await supabase
    .from("product_ingredients")
    .select(`
      id,
      ingredient_id,
      raw_label_name,
      amount_per_serving,
      amount_unit,
      updated_at,
      ingredients (
        id,
        canonical_name_ko,
        canonical_name_en
      )
    `)
    .eq("product_id", Number(id))
    .order("id");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // 중복 분석 로직 추가
  type IngredientRow = (typeof ingredients)[number];

  const analysis = ingredients.reduce<Record<string, IngredientRow[]>>((acc, curr) => {
    const key = String(curr.ingredient_id ?? curr.raw_label_name);
    if (!acc[key]) acc[key] = [];
    acc[key].push(curr);
    return acc;
  }, {});

  const duplicates = Object.entries(analysis)
    .filter(([, items]) => items.length > 1)
    .map(([key, items]) => ({
      key,
      count: items.length,
      items
    }));

  return NextResponse.json({ 
    productId: id,
    totalCount: ingredients.length,
    duplicateGroups: duplicates,
    allIngredients: ingredients 
  });
}
