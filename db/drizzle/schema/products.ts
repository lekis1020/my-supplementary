import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  numeric,
  index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { ingredients } from "./ingredients";

// ============================================================================
// 9. 제품 (Products)
// ============================================================================

export const products = pgTable(
  "products",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productName: varchar("product_name", { length: 255 }).notNull(),
    brandName: varchar("brand_name", { length: 255 }),
    manufacturerName: varchar("manufacturer_name", { length: 255 }),
    distributorName: varchar("distributor_name", { length: 255 }),
    countryCode: varchar("country_code", { length: 10 }),
    productType: varchar("product_type", { length: 100 }),
    approvalOrReportNo: varchar("approval_or_report_no", { length: 255 }),
    status: varchar({ length: 50 }).default("active"),
    barcode: varchar({ length: 100 }),
    productImageUrl: text("product_image_url"),
    marketplaceCategory: varchar("marketplace_category", { length: 255 }),
    officialUrl: text("official_url"),
    isPublished: boolean("is_published").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_products_name").on(t.productName),
    index("idx_products_brand").on(t.brandName),
    index("idx_products_barcode").on(t.barcode),
  ]
);

// ============================================================================
// 10. 제품-원료 연결 (Product Ingredients, M:N)
// ============================================================================

export const productIngredients = pgTable(
  "product_ingredients",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productId: bigserial("product_id", { mode: "number" })
      .notNull()
      .references(() => products.id, { onDelete: "cascade" }),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id),
    amountPerServing: numeric("amount_per_serving", {
      precision: 12,
      scale: 4,
    }),
    amountUnit: varchar("amount_unit", { length: 50 }),
    dailyAmount: numeric("daily_amount", { precision: 12, scale: 4 }),
    dailyAmountUnit: varchar("daily_amount_unit", { length: 50 }),
    ingredientRole: varchar("ingredient_role", { length: 50 }),
    rawLabelName: varchar("raw_label_name", { length: 255 }),
    isStandardized: boolean("is_standardized").default(false),
    standardizationText: text("standardization_text"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_product_ingredients_product_id").on(t.productId),
    index("idx_product_ingredients_ingredient_id").on(t.ingredientId),
  ]
);

// ============================================================================
// 11. 라벨 스냅샷 (Label Snapshots)
// ============================================================================

export const labelSnapshots = pgTable(
  "label_snapshots",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productId: bigserial("product_id", { mode: "number" })
      .notNull()
      .references(() => products.id, { onDelete: "cascade" }),
    labelVersion: varchar("label_version", { length: 100 }),
    sourceName: varchar("source_name", { length: 255 }),
    sourceUrl: text("source_url"),
    servingSizeText: varchar("serving_size_text", { length: 255 }),
    servingsPerContainer: varchar("servings_per_container", { length: 100 }),
    warningText: text("warning_text"),
    storageText: text("storage_text"),
    directionsText: text("directions_text"),
    rawLabelText: text("raw_label_text"),
    capturedAt: timestamp("captured_at"),
    effectiveDate: timestamp("effective_date"),
    isCurrent: boolean("is_current").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_label_snapshots_product_id").on(t.productId),
    index("idx_label_snapshots_is_current").on(t.isCurrent),
  ]
);

// -- Relations --

export const productsRelations = relations(products, ({ many }) => ({
  productIngredients: many(productIngredients),
  labelSnapshots: many(labelSnapshots),
}));

export const productIngredientsRelations = relations(
  productIngredients,
  ({ one }) => ({
    product: one(products, {
      fields: [productIngredients.productId],
      references: [products.id],
    }),
    ingredient: one(ingredients, {
      fields: [productIngredients.ingredientId],
      references: [ingredients.id],
    }),
  })
);

export const labelSnapshotsRelations = relations(
  labelSnapshots,
  ({ one }) => ({
    product: one(products, {
      fields: [labelSnapshots.productId],
      references: [products.id],
    }),
  })
);
