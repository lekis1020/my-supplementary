import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  integer,
  numeric,
  jsonb,
  unique,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

// ============================================================================
// KR 정부 데이터 staging (Staging Tables)
// tmp/kr-gov-clean/staging/*.jsonl 적재용 중간 테이블. 정제/검수/재매핑 후
// 본 테이블(products, ingredients, product_ingredients)로 promote.
// DDL: 20260823100335_restore_kr_staging_tables.sql (3종) +
// baseline의 staging_regulatory_standards_kr (20260327 유래).
// ============================================================================

// -- 제품 staging --

export const stagingProductsKr = pgTable(
  "staging_products_kr",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    reportNo: varchar("report_no", { length: 255 }).notNull(),
    productName: varchar("product_name", { length: 255 }).notNull(),
    brandName: varchar("brand_name", { length: 255 }),
    manufacturerName: varchar("manufacturer_name", { length: 255 }),
    distributorName: varchar("distributor_name", { length: 255 }),
    countryCode: varchar("country_code", { length: 10 }).default("KR"),
    productType: varchar("product_type", { length: 100 }),
    approvalOrReportNo: varchar("approval_or_report_no", { length: 255 }),
    status: varchar({ length: 50 }).default("active"),
    productNameSource: varchar("product_name_source", { length: 100 }),
    productNameResolution: varchar("product_name_resolution", { length: 100 }),
    isIngredientLikeProduct: boolean("is_ingredient_like_product")
      .notNull()
      .default(false),
    isPublished: boolean("is_published").notNull().default(true),
    sourceDatasets: jsonb("source_datasets")
      .notNull()
      .default(sql`'[]'::jsonb`),
    functionalityItems: jsonb("functionality_items")
      .notNull()
      .default(sql`'[]'::jsonb`),
    directionsText: text("directions_text"),
    warningText: text("warning_text"),
    storageText: text("storage_text"),
    standardsText: text("standards_text"),
    shapeName: varchar("shape_name", { length: 255 }),
    formulationMethod: text("formulation_method"),
    packagingMaterialsText: text("packaging_materials_text"),
    shelfLifeText: varchar("shelf_life_text", { length: 255 }),
    reportDate: varchar("report_date", { length: 20 }),
    lastUpdatedAt: varchar("last_updated_at", { length: 20 }),
    registrationDate: varchar("registration_date", { length: 20 }),
    rawPrimaryMaterialName: text("raw_primary_material_name"),
    rawIndividualMaterialName: text("raw_individual_material_name"),
    stagingIngredientRows: integer("staging_ingredient_rows")
      .notNull()
      .default(0),
    stagingCanonicalIngredientCount: integer(
      "staging_canonical_ingredient_count"
    )
      .notNull()
      .default(0),
    activeIngredientRows: integer("active_ingredient_rows")
      .notNull()
      .default(0),
    supportingIngredientRows: integer("supporting_ingredient_rows")
      .notNull()
      .default(0),
    capsuleIngredientRows: integer("capsule_ingredient_rows")
      .notNull()
      .default(0),
    maxIngredientConfidence: numeric("max_ingredient_confidence", {
      precision: 5,
      scale: 2,
    }),
    importBatch: varchar("import_batch", { length: 100 }),
    importedAt: timestamp("imported_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique("uq_staging_products_kr_report_no").on(t.reportNo),
    index("idx_staging_products_kr_name").on(t.productName),
    index("idx_staging_products_kr_manufacturer").on(t.manufacturerName),
    index("idx_staging_products_kr_status").on(t.status),
  ]
);

// -- 원료 staging --

export const stagingIngredientsKr = pgTable(
  "staging_ingredients_kr",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    canonicalNameKo: varchar("canonical_name_ko", { length: 255 }).notNull(),
    canonicalNameEn: varchar("canonical_name_en", { length: 255 }),
    displayName: varchar("display_name", { length: 255 }),
    scientificName: varchar("scientific_name", { length: 255 }),
    slug: varchar({ length: 255 }),
    ingredientType: varchar("ingredient_type", { length: 50 }),
    originType: varchar("origin_type", { length: 50 }),
    formDescription: text("form_description"),
    standardizationInfo: text("standardization_info"),
    description: text(),
    aliases: jsonb()
      .notNull()
      .default(sql`'[]'::jsonb`),
    sourceDatasets: jsonb("source_datasets")
      .notNull()
      .default(sql`'[]'::jsonb`),
    functionalityItems: jsonb("functionality_items")
      .notNull()
      .default(sql`'[]'::jsonb`),
    warningTexts: jsonb("warning_texts")
      .notNull()
      .default(sql`'[]'::jsonb`),
    dosageGuidelines: jsonb("dosage_guidelines")
      .notNull()
      .default(sql`'[]'::jsonb`),
    recognitionNos: jsonb("recognition_nos")
      .notNull()
      .default(sql`'[]'::jsonb`),
    healthItemGroupCodes: jsonb("health_item_group_codes")
      .notNull()
      .default(sql`'[]'::jsonb`),
    healthItemGroupNames: jsonb("health_item_group_names")
      .notNull()
      .default(sql`'[]'::jsonb`),
    mappedProductCount: integer("mapped_product_count").notNull().default(0),
    mappedMentionRows: integer("mapped_mention_rows").notNull().default(0),
    activeMentionRows: integer("active_mention_rows").notNull().default(0),
    supportingMentionRows: integer("supporting_mention_rows")
      .notNull()
      .default(0),
    capsuleMentionRows: integer("capsule_mention_rows").notNull().default(0),
    maxMappedConfidence: numeric("max_mapped_confidence", {
      precision: 5,
      scale: 2,
    }),
    sourceRecordCount: integer("source_record_count").notNull().default(0),
    importBatch: varchar("import_batch", { length: 100 }),
    importedAt: timestamp("imported_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique("uq_staging_ingredients_kr_name").on(t.canonicalNameKo),
    index("idx_staging_ingredients_kr_slug").on(t.slug),
    index("idx_staging_ingredients_kr_type").on(t.ingredientType),
    // idx_staging_ingredients_kr_mapped_product_count는 DDL에서 DESC 정렬 —
    // Drizzle 인덱스는 컬럼만 표현.
    index("idx_staging_ingredients_kr_mapped_product_count").on(
      t.mappedProductCount
    ),
  ]
);

// -- 제품-원료 연결 staging --

export const stagingProductIngredientsKr = pgTable(
  "staging_product_ingredients_kr",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    reportNo: varchar("report_no", { length: 255 }).notNull(),
    productName: varchar("product_name", { length: 255 }),
    manufacturerName: varchar("manufacturer_name", { length: 255 }),
    canonicalNameKo: varchar("canonical_name_ko", { length: 255 }).notNull(),
    canonicalSlug: varchar("canonical_slug", { length: 255 }),
    rawLabelName: text("raw_label_name").notNull(),
    amountPerServing: numeric("amount_per_serving", {
      precision: 12,
      scale: 4,
    }),
    amountUnit: varchar("amount_unit", { length: 50 }),
    dailyAmount: numeric("daily_amount", { precision: 12, scale: 4 }),
    dailyAmountUnit: varchar("daily_amount_unit", { length: 50 }),
    amountSource: varchar("amount_source", { length: 100 }),
    sourceDatasets: jsonb("source_datasets")
      .notNull()
      .default(sql`'[]'::jsonb`),
    sourceKinds: jsonb("source_kinds")
      .notNull()
      .default(sql`'[]'::jsonb`),
    rawIngredientRoles: jsonb("raw_ingredient_roles")
      .notNull()
      .default(sql`'[]'::jsonb`),
    proposedIngredientRole: varchar("proposed_ingredient_role", {
      length: 50,
    }).notNull(),
    minOrderHint: integer("min_order_hint"),
    maxConfidence: numeric("max_confidence", { precision: 5, scale: 2 }),
    matchedVariants: jsonb("matched_variants")
      .notNull()
      .default(sql`'[]'::jsonb`),
    matchStrategies: jsonb("match_strategies")
      .notNull()
      .default(sql`'[]'::jsonb`),
    promotionReasons: jsonb("promotion_reasons")
      .notNull()
      .default(sql`'[]'::jsonb`),
    importBatch: varchar("import_batch", { length: 100 }),
    importedAt: timestamp("imported_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique("uq_staging_product_ingredients_kr_row").on(
      t.reportNo,
      t.canonicalNameKo,
      t.rawLabelName,
      t.proposedIngredientRole
    ),
    index("idx_staging_product_ingredients_kr_report_no").on(t.reportNo),
    index("idx_staging_product_ingredients_kr_canonical_name").on(
      t.canonicalNameKo
    ),
    index("idx_staging_product_ingredients_kr_canonical_slug").on(
      t.canonicalSlug
    ),
    index("idx_staging_product_ingredients_kr_role").on(
      t.proposedIngredientRole
    ),
    // idx_staging_product_ingredients_kr_confidence는 DDL에서 DESC 정렬.
    index("idx_staging_product_ingredients_kr_confidence").on(t.maxConfidence),
  ]
);

// -- KR 정부 규제 기준 staging (I0960) --

export const stagingRegulatoryStandardsKr = pgTable(
  "staging_regulatory_standards_kr",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceDataset: varchar("source_dataset", { length: 100 }).notNull(),
    productCode: varchar("product_code", { length: 100 }),
    testNameKo: varchar("test_name_ko", { length: 255 }).notNull(),
    minValue: varchar("min_value", { length: 100 }),
    maxValue: varchar("max_value", { length: 100 }),
    unit: varchar({ length: 50 }),
    validStartDate: varchar("valid_start_date", { length: 20 }),
    validEndDate: varchar("valid_end_date", { length: 20 }),
    sourceText: text("source_text"),
    injuryFlag: varchar("injury_flag", { length: 20 }),
    importBatch: varchar("import_batch", { length: 100 }),
    importedAt: timestamp("imported_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique().on(
      t.sourceDataset,
      t.productCode,
      t.testNameKo,
      t.validStartDate,
      t.validEndDate
    ),
    index("idx_staging_regulatory_standards_kr_product_code").on(
      t.productCode
    ),
    index("idx_staging_regulatory_standards_kr_test_name").on(t.testNameKo),
  ]
);
