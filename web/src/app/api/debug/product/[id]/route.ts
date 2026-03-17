import { NextResponse } from 'next/server';
import { createClient } from "@/lib/supabase/server";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
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
  const analysis = ingredients.reduce((acc: any, curr: any) => {
    const key = curr.ingredient_id || curr.raw_label_name;
    if (!acc[key]) acc[key] = [];
    acc[key].push(curr);
    return acc;
  }, {});

  const duplicates = Object.entries(analysis)
    .filter(([_, items]: [any, any]) => items.length > 1)
    .map(([key, items]: [any, any]) => ({
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
