#!/usr/bin/env node

import { createReadStream, existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import { execFileSync } from "node:child_process";
import { createClient } from "@supabase/supabase-js";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");
const supabaseTempDir = path.join(rootDir, "supabase", ".temp");

const envCandidates = [
  path.join(webDir, ".env.local"),
  path.join(rootDir, ".env.local"),
  path.join(webDir, ".env"),
  path.join(rootDir, ".env"),
];

function parseEnvFile(filePath) {
  const values = {};
  const content = readFileSync(filePath, "utf8");

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[key] = value;
  }

  return values;
}

for (const envPath of envCandidates) {
  if (!existsSync(envPath)) {
    continue;
  }

  const values = parseEnvFile(envPath);
  for (const [key, value] of Object.entries(values)) {
    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

function parseArgs(argv) {
  const args = {
    dryRun: false,
    only: "all",
    batchSize: 1000,
    publish: true,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }

    if (token.startsWith("--only=")) {
      args.only = token.split("=")[1];
      continue;
    }

    if (token.startsWith("--batch-size=")) {
      args.batchSize = Number(token.split("=")[1]);
      continue;
    }

    if (token === "--unpublished") {
      args.publish = false;
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));

const supplementalIngredients = [
  {
    canonicalNameKo: "콜라겐",
    canonicalNameEn: "Collagen",
    displayName: "콜라겐",
    scientificName: null,
    slug: "collagen",
    ingredientType: "amino_acid",
    description: "어류, 돈피, 우피 등에서 유래하는 콜라겐 및 콜라겐 펩타이드 계열 원료의 대표 canonical 항목.",
    originType: "natural",
    formDescription: "피쉬 콜라겐, 콜라겐 펩타이드, 저분자 콜라겐",
    standardizationInfo: null,
  },
  {
    canonicalNameKo: "가르시니아",
    canonicalNameEn: "Garcinia cambogia extract",
    displayName: "가르시니아",
    scientificName: "Garcinia cambogia",
    slug: "garcinia",
    ingredientType: "herbal",
    description: "가르시니아캄보지아 열매 껍질 추출물 계열 원료의 대표 canonical 항목.",
    originType: "natural",
    formDescription: "가르시니아캄보지아 껍질추출물, HCA 함유 추출물",
    standardizationInfo: "총 (-)-HCA 기준 관리",
  },
];

function readTempValue(filename) {
  const filePath = path.join(supabaseTempDir, filename);
  if (!existsSync(filePath)) {
    return null;
  }

  return readFileSync(filePath, "utf8").trim() || null;
}

function resolveProjectRef() {
  return process.env.SUPABASE_PROJECT_REF ?? readTempValue("project-ref");
}

function resolveSupabaseUrl(projectRef) {
  const envUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL;

  if (envUrl && !envUrl.includes("placeholder.supabase.co")) {
    return envUrl;
  }

  return projectRef ? `https://${projectRef}.supabase.co` : envUrl ?? null;
}

function resolveServiceRoleKey(projectRef) {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY;
  }

  if (!projectRef) {
    return null;
  }

  const output = execFileSync(
    "supabase",
    ["projects", "api-keys", "list", "--project-ref", projectRef, "--output", "json"],
    {
      cwd: rootDir,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    },
  );

  const keys = JSON.parse(output);
  const serviceRole = keys.find((item) => item.id === "service_role");
  return serviceRole?.api_key ?? null;
}

async function* readJsonl(filePath) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lineReader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  for await (const line of lineReader) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }

    yield JSON.parse(trimmed);
  }
}

function chunk(array, size) {
  const output = [];
  for (let index = 0; index < array.length; index += size) {
    output.push(array.slice(index, index + size));
  }
  return output;
}

function mapIngredientRow(row) {
  return {
    canonical_name_ko: row.canonicalNameKo,
    canonical_name_en: row.canonicalNameEn,
    display_name: row.displayName,
    scientific_name: row.scientificName,
    slug: row.slug,
    ingredient_type: row.ingredientType ?? "other",
    description: row.description,
    origin_type: row.originType,
    form_description: row.formDescription,
    standardization_info: row.standardizationInfo,
    is_active: true,
    is_published: args.publish,
  };
}

function mapProductRow(row) {
  return {
    product_name: row.productName,
    brand_name: row.brandName,
    manufacturer_name: row.manufacturerName,
    distributor_name: row.distributorName,
    country_code: row.countryCode,
    product_type: row.productType,
    approval_or_report_no: row.approvalOrReportNo ?? row.reportNo,
    status: row.status ?? "active",
    official_url: null,
    barcode: null,
    marketplace_category: null,
    product_image_url: null,
    is_published: args.publish,
  };
}

function mapProductIngredientRow(row, productId, ingredientId) {
  return {
    product_id: productId,
    ingredient_id: ingredientId,
    amount_per_serving: null,
    amount_unit: null,
    daily_amount: null,
    daily_amount_unit: null,
    ingredient_role: row.proposedIngredientRole,
    raw_label_name: row.rawLabelName,
    is_standardized: false,
    standardization_text: null,
  };
}

async function readAllRows(filePath) {
  const rows = [];
  for await (const row of readJsonl(filePath)) {
    rows.push(row);
  }
  return rows;
}

async function fetchExistingIngredientNames(supabase, batchSize) {
  const names = new Set();
  let from = 0;

  while (true) {
    const to = from + batchSize - 1;
    const { data, error } = await supabase
      .from("ingredients")
      .select("canonical_name_ko")
      .order("id", { ascending: true })
      .range(from, to);

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    for (const row of data) {
      if (row.canonical_name_ko) {
        names.add(row.canonical_name_ko);
      }
    }

    if (data.length < batchSize) {
      break;
    }

    from += batchSize;
  }

  return names;
}

async function deleteAllProducts(supabase) {
  const { error } = await supabase.from("products").delete().gt("id", 0);
  if (error) {
    throw error;
  }
}

async function deleteAllProductIngredients(supabase) {
  const { error } = await supabase
    .from("product_ingredients")
    .delete()
    .gt("id", 0);

  if (error) {
    throw error;
  }
}

async function upsertIngredients(supabase, rows, batchSize) {
  const mergedRows = [...rows];
  const existing = new Set(rows.map((row) => row.canonicalNameKo));

  for (const supplemental of supplementalIngredients) {
    if (!existing.has(supplemental.canonicalNameKo)) {
      mergedRows.push(supplemental);
    }
  }

  const existingNames = await fetchExistingIngredientNames(supabase, batchSize);
  const slugRows = mergedRows.filter((row) => row.slug);
  const nameOnlyRows = mergedRows.filter(
    (row) => !row.slug && !existingNames.has(row.canonicalNameKo),
  );
  let processed = 0;

  for (const batch of chunk(slugRows, batchSize)) {
    const payload = batch.map(mapIngredientRow);
    const { error } = await supabase
      .from("ingredients")
      .upsert(payload, { onConflict: "slug", ignoreDuplicates: false });

    if (error) {
      throw error;
    }

    processed += batch.length;
    console.log(`ingredients upserted ${processed}/${slugRows.length + nameOnlyRows.length}`);
  }

  for (const batch of chunk(nameOnlyRows, batchSize)) {
    const payload = batch.map(mapIngredientRow);
    const { error } = await supabase.from("ingredients").insert(payload);

    if (error) {
      throw error;
    }

    processed += batch.length;
    console.log(`ingredients upserted ${processed}/${slugRows.length + nameOnlyRows.length}`);
  }
}

async function fetchIngredientMap(supabase) {
  const ingredientMap = new Map();

  const { data, error } = await supabase
    .from("ingredients")
    .select("id, slug, canonical_name_ko")
    .order("id", { ascending: true });

  if (error) {
    throw error;
  }

  for (const row of data ?? []) {
    if (row.slug) {
      ingredientMap.set(`slug:${row.slug}`, row.id);
    }
    if (row.canonical_name_ko) {
      ingredientMap.set(`name:${row.canonical_name_ko}`, row.id);
    }
  }

  return ingredientMap;
}

async function fetchProductMap(supabase, batchSize) {
  const productMap = new Map();
  let from = 0;

  while (true) {
    const to = from + batchSize - 1;
    const { data, error } = await supabase
      .from("products")
      .select("id, approval_or_report_no")
      .not("approval_or_report_no", "is", null)
      .order("id", { ascending: true })
      .range(from, to);

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    for (const row of data) {
      productMap.set(row.approval_or_report_no, row.id);
    }

    if (data.length < batchSize) {
      break;
    }

    from += batchSize;
  }

  return productMap;
}

async function insertProducts(supabase, rows, batchSize) {
  let processed = 0;
  const productMap = new Map();

  for (const batch of chunk(rows, batchSize)) {
    const payload = batch.map(mapProductRow);
    const { data, error } = await supabase
      .from("products")
      .insert(payload)
      .select("id, approval_or_report_no");

    if (error) {
      throw error;
    }

    for (const row of data ?? []) {
      productMap.set(row.approval_or_report_no, row.id);
    }

    processed += batch.length;
    console.log(`products inserted ${processed}/${rows.length}`);
  }

  return productMap;
}

async function insertProductIngredients(
  supabase,
  rows,
  productMap,
  ingredientMap,
  batchSize,
) {
  let processed = 0;
  let inserted = 0;
  let skipped = 0;

  for (const batch of chunk(rows, batchSize)) {
    const payload = [];

    for (const row of batch) {
      const productId = productMap.get(row.reportNo);
      const ingredientId =
        ingredientMap.get(`slug:${row.canonicalSlug}`) ??
        ingredientMap.get(`name:${row.canonicalNameKo}`);

      if (!productId || !ingredientId) {
        skipped += 1;
        continue;
      }

      payload.push(mapProductIngredientRow(row, productId, ingredientId));
    }

    if (payload.length > 0) {
      const { error } = await supabase.from("product_ingredients").insert(payload);
      if (error) {
        throw error;
      }
      inserted += payload.length;
    }

    processed += batch.length;
    console.log(
      `product_ingredients processed ${processed}/${rows.length} inserted=${inserted} skipped=${skipped}`,
    );
  }

  return { inserted, skipped };
}

async function countRows(supabase, tableName) {
  const { count, error } = await supabase
    .from(tableName)
    .select("id", { count: "exact", head: true });

  if (error) {
    throw error;
  }

  return count ?? 0;
}

async function main() {
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef);

  if (!supabaseUrl) {
    throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL or linked project ref");
  }

  if (!serviceRoleKey) {
    throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY and could not resolve via Supabase CLI");
  }

  const inputDir = path.join(rootDir, "tmp", "kr-gov-clean", "staging");
  const productsPath = path.join(inputDir, "products.staging.jsonl");
  const ingredientsPath = path.join(inputDir, "ingredients.staging.jsonl");
  const productIngredientsPath = path.join(
    inputDir,
    "product_ingredients.staging.jsonl",
  );

  const selected = new Set(
    args.only === "all" ? ["ingredients", "products", "product_ingredients"] : [args.only],
  );

  for (const filePath of [productsPath, ingredientsPath, productIngredientsPath]) {
    if (!existsSync(filePath)) {
      throw new Error(`Missing input file: ${filePath}`);
    }
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ingredientsRows = selected.has("ingredients") || selected.has("product_ingredients")
    ? await readAllRows(ingredientsPath)
    : [];
  const productRows = selected.has("products") || selected.has("product_ingredients")
    ? await readAllRows(productsPath)
    : [];
  const productIngredientRows = selected.has("product_ingredients")
    ? await readAllRows(productIngredientsPath)
    : [];

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          projectRef,
          supabaseUrl,
          selected: Array.from(selected),
          counts: {
            ingredients: ingredientsRows.length,
            products: productRows.length,
            product_ingredients: productIngredientRows.length,
          },
          publish: args.publish,
          batchSize: args.batchSize,
        },
        null,
        2,
      ),
    );
    return;
  }

  let ingredientMap = new Map();
  let productMap = new Map();

  if (selected.has("ingredients")) {
    await upsertIngredients(supabase, ingredientsRows, args.batchSize);
  }

  if (selected.has("ingredients") || selected.has("product_ingredients")) {
    ingredientMap = await fetchIngredientMap(supabase);
    console.log(`ingredient ids resolved ${ingredientMap.size}`);
  }

  if (selected.has("products")) {
    await deleteAllProducts(supabase);
    console.log("products deleted");
    productMap = await insertProducts(supabase, productRows, args.batchSize);
  } else if (selected.has("product_ingredients")) {
    productMap = await fetchProductMap(supabase, args.batchSize);
    console.log(`product ids resolved ${productMap.size}`);
  }

  if (selected.has("product_ingredients")) {
    if (!selected.has("products")) {
      await deleteAllProductIngredients(supabase);
      console.log("product_ingredients deleted");
    }

    const result = await insertProductIngredients(
      supabase,
      productIngredientRows,
      productMap,
      ingredientMap,
      args.batchSize,
    );
    console.log(`product_ingredients inserted=${result.inserted} skipped=${result.skipped}`);
  }

  const counts = {
    ingredients: await countRows(supabase, "ingredients"),
    products: await countRows(supabase, "products"),
    product_ingredients: await countRows(supabase, "product_ingredients"),
  };

  console.log(JSON.stringify({ projectRef, counts }, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
