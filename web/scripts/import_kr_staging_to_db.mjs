#!/usr/bin/env node

import { createReadStream, existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import postgres from "postgres";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");

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
    only: "all",
    dryRun: false,
    truncate: false,
    batchSize: 500,
    importBatch: `kr-stage-${new Date().toISOString().replace(/[:.]/g, "-")}`,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }

    if (token === "--truncate") {
      args.truncate = true;
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

    if (token.startsWith("--import-batch=")) {
      args.importBatch = token.split("=")[1];
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl && !args.dryRun) {
  console.error("Missing DATABASE_URL");
  process.exit(1);
}

const inputDir = path.join(rootDir, "tmp", "kr-gov-clean", "staging");

const datasets = [
  {
    key: "products",
    filePath: path.join(inputDir, "products.staging.jsonl"),
    tableName: "staging_products_kr",
    conflictColumns: ["report_no"],
    jsonColumns: ["source_datasets", "functionality_items"],
    columns: [
      "report_no",
      "product_name",
      "brand_name",
      "manufacturer_name",
      "distributor_name",
      "country_code",
      "product_type",
      "approval_or_report_no",
      "status",
      "product_name_source",
      "product_name_resolution",
      "is_ingredient_like_product",
      "is_published",
      "source_datasets",
      "functionality_items",
      "directions_text",
      "warning_text",
      "storage_text",
      "standards_text",
      "shape_name",
      "formulation_method",
      "packaging_materials_text",
      "shelf_life_text",
      "report_date",
      "last_updated_at",
      "registration_date",
      "raw_primary_material_name",
      "raw_individual_material_name",
      "staging_ingredient_rows",
      "staging_canonical_ingredient_count",
      "active_ingredient_rows",
      "supporting_ingredient_rows",
      "capsule_ingredient_rows",
      "max_ingredient_confidence",
      "import_batch",
    ],
    mapRow(row) {
      return {
        report_no: row.reportNo,
        product_name: row.productName,
        brand_name: row.brandName,
        manufacturer_name: row.manufacturerName,
        distributor_name: row.distributorName,
        country_code: row.countryCode,
        product_type: row.productType,
        approval_or_report_no: row.approvalOrReportNo,
        status: row.status,
        product_name_source: row.productNameSource,
        product_name_resolution: row.productNameResolution,
        is_ingredient_like_product: row.isIngredientLikeProduct ?? false,
        is_published: row.isPublished ?? true,
        source_datasets: row.sourceDatasets ?? [],
        functionality_items: row.functionalityItems ?? [],
        directions_text: row.directionsText,
        warning_text: row.warningText,
        storage_text: row.storageText,
        standards_text: row.standardsText,
        shape_name: row.shapeName,
        formulation_method: row.formulationMethod,
        packaging_materials_text: row.packagingMaterialsText,
        shelf_life_text: row.shelfLifeText,
        report_date: row.reportDate,
        last_updated_at: row.lastUpdatedAt,
        registration_date: row.registrationDate,
        raw_primary_material_name: row.rawPrimaryMaterialName,
        raw_individual_material_name: row.rawIndividualMaterialName,
        staging_ingredient_rows: row.stagingIngredientRows ?? 0,
        staging_canonical_ingredient_count:
          row.stagingCanonicalIngredientCount ?? 0,
        active_ingredient_rows: row.activeIngredientRows ?? 0,
        supporting_ingredient_rows: row.supportingIngredientRows ?? 0,
        capsule_ingredient_rows: row.capsuleIngredientRows ?? 0,
        max_ingredient_confidence: row.maxIngredientConfidence,
      };
    },
  },
  {
    key: "ingredients",
    filePath: path.join(inputDir, "ingredients.staging.jsonl"),
    tableName: "staging_ingredients_kr",
    conflictColumns: ["canonical_name_ko"],
    jsonColumns: [
      "aliases",
      "source_datasets",
      "functionality_items",
      "warning_texts",
      "dosage_guidelines",
      "recognition_nos",
      "health_item_group_codes",
      "health_item_group_names",
    ],
    columns: [
      "canonical_name_ko",
      "canonical_name_en",
      "display_name",
      "scientific_name",
      "slug",
      "ingredient_type",
      "origin_type",
      "form_description",
      "standardization_info",
      "description",
      "aliases",
      "source_datasets",
      "functionality_items",
      "warning_texts",
      "dosage_guidelines",
      "recognition_nos",
      "health_item_group_codes",
      "health_item_group_names",
      "mapped_product_count",
      "mapped_mention_rows",
      "active_mention_rows",
      "supporting_mention_rows",
      "capsule_mention_rows",
      "max_mapped_confidence",
      "source_record_count",
      "import_batch",
    ],
    mapRow(row) {
      return {
        canonical_name_ko: row.canonicalNameKo,
        canonical_name_en: row.canonicalNameEn,
        display_name: row.displayName,
        scientific_name: row.scientificName,
        slug: row.slug,
        ingredient_type: row.ingredientType,
        origin_type: row.originType,
        form_description: row.formDescription,
        standardization_info: row.standardizationInfo,
        description: row.description,
        aliases: row.aliases ?? [],
        source_datasets: row.sourceDatasets ?? [],
        functionality_items: row.functionalityItems ?? [],
        warning_texts: row.warningTexts ?? [],
        dosage_guidelines: row.dosageGuidelines ?? [],
        recognition_nos: row.recognitionNos ?? [],
        health_item_group_codes: row.healthItemGroupCodes ?? [],
        health_item_group_names: row.healthItemGroupNames ?? [],
        mapped_product_count: row.mappedProductCount ?? 0,
        mapped_mention_rows: row.mappedMentionRows ?? 0,
        active_mention_rows: row.activeMentionRows ?? 0,
        supporting_mention_rows: row.supportingMentionRows ?? 0,
        capsule_mention_rows: row.capsuleMentionRows ?? 0,
        max_mapped_confidence: row.maxMappedConfidence,
        source_record_count: row.sourceRecordCount ?? 0,
      };
    },
  },
  {
    key: "product_ingredients",
    filePath: path.join(inputDir, "product_ingredients.staging.jsonl"),
    tableName: "staging_product_ingredients_kr",
    conflictColumns: [
      "report_no",
      "canonical_name_ko",
      "raw_label_name",
      "proposed_ingredient_role",
    ],
    jsonColumns: [
      "source_datasets",
      "source_kinds",
      "raw_ingredient_roles",
      "matched_variants",
      "match_strategies",
      "promotion_reasons",
    ],
    columns: [
      "report_no",
      "product_name",
      "manufacturer_name",
      "canonical_name_ko",
      "canonical_slug",
      "raw_label_name",
      "source_datasets",
      "source_kinds",
      "raw_ingredient_roles",
      "proposed_ingredient_role",
      "min_order_hint",
      "max_confidence",
      "matched_variants",
      "match_strategies",
      "promotion_reasons",
      "import_batch",
    ],
    mapRow(row) {
      return {
        report_no: row.reportNo,
        product_name: row.productName,
        manufacturer_name: row.manufacturerName,
        canonical_name_ko: row.canonicalNameKo,
        canonical_slug: row.canonicalSlug,
        raw_label_name: row.rawLabelName,
        source_datasets: row.sourceDatasets ?? [],
        source_kinds: row.sourceKinds ?? [],
        raw_ingredient_roles: row.rawIngredientRoles ?? [],
        proposed_ingredient_role: row.proposedIngredientRole,
        min_order_hint: row.minOrderHint,
        max_confidence: row.maxConfidence,
        matched_variants: row.matchedVariants ?? [],
        match_strategies: row.matchStrategies ?? [],
        promotion_reasons: row.promotionReasons ?? [],
      };
    },
  },
];

const selectedDatasets =
  args.only === "all"
    ? datasets
    : datasets.filter((dataset) => dataset.key === args.only);

if (selectedDatasets.length === 0) {
  console.error(`Unknown dataset selector: ${args.only}`);
  process.exit(1);
}

for (const dataset of selectedDatasets) {
  if (!existsSync(dataset.filePath)) {
    console.error(`Missing input file: ${dataset.filePath}`);
    process.exit(1);
  }
}

async function* readRows(filePath) {
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

function toInsertTuple(dataset, row, importBatch) {
  const mapped = dataset.mapRow(row);
  mapped.import_batch = importBatch;

  return dataset.columns.map((column) => mapped[column] ?? null);
}

async function upsertBatch(sql, dataset, rows, importBatch) {
  const tuples = rows.map((row) => toInsertTuple(dataset, row, importBatch));
  const insertColumns = dataset.columns.join(", ");
  const conflictColumns = dataset.conflictColumns.join(", ");
  const updateAssignments = dataset.columns
    .filter((column) => !dataset.conflictColumns.includes(column))
    .map((column) => `${column} = EXCLUDED.${column}`);
  updateAssignments.push("updated_at = NOW()");

  const params = [];
  let paramIndex = 1;
  const valuesSql = tuples
    .map((tuple) => {
      const placeholders = tuple.map((value, columnIndex) => {
        const column = dataset.columns[columnIndex];
        const isJson = dataset.jsonColumns.includes(column);
        params.push(isJson && value != null ? JSON.stringify(value) : value);
        const placeholder = `$${paramIndex}`;
        paramIndex += 1;
        return isJson ? `${placeholder}::jsonb` : placeholder;
      });
      return `(${placeholders.join(", ")})`;
    })
    .join(", ");

  const query = `
    INSERT INTO ${dataset.tableName} (${insertColumns})
    VALUES ${valuesSql}
    ON CONFLICT (${conflictColumns})
    DO UPDATE SET ${updateAssignments.join(", ")}
  `;

  await sql.unsafe(query, params);
}

async function truncateTable(sql, tableName) {
  await sql.unsafe(`TRUNCATE TABLE ${tableName}`);
}

async function importDataset(sql, dataset, options) {
  let totalRows = 0;
  const rows = [];

  for await (const row of readRows(dataset.filePath)) {
    rows.push(row);
    totalRows += 1;
  }

  if (options.dryRun) {
    console.log(
      `${dataset.key} rows=${totalRows} mode=dry-run importBatch=${options.importBatch}`,
    );
    return { key: dataset.key, totalRows };
  }

  if (options.truncate) {
    await truncateTable(sql, dataset.tableName);
  }

  for (const batch of chunk(rows, options.batchSize)) {
    await upsertBatch(sql, dataset, batch, options.importBatch);
  }

  console.log(
    `${dataset.key} rows=${totalRows} imported batchSize=${options.batchSize} importBatch=${options.importBatch}`,
  );
  return { key: dataset.key, totalRows };
}

async function main() {
  const sql = args.dryRun
    ? null
    : postgres(databaseUrl, {
        max: 1,
        idle_timeout: 5,
        connect_timeout: 30,
      });

  try {
    for (const dataset of selectedDatasets) {
      await importDataset(sql, dataset, args);
    }
  } finally {
    if (sql) {
      await sql.end();
    }
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
