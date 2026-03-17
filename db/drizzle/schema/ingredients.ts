import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  integer,
  numeric,
  index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// ============================================================================
// 1. 원료 (Ingredients)
// ============================================================================

export const ingredients = pgTable(
  "ingredients",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    canonicalNameKo: varchar("canonical_name_ko", { length: 255 }).notNull(),
    canonicalNameEn: varchar("canonical_name_en", { length: 255 }),
    displayName: varchar("display_name", { length: 255 }),
    scientificName: varchar("scientific_name", { length: 255 }),
    slug: varchar({ length: 255 }).unique(),
    ingredientType: varchar("ingredient_type", { length: 50 }).notNull(),
    parentIngredientId: bigserial("parent_ingredient_id", {
      mode: "number",
    }).references((): any => ingredients.id),
    description: text(),
    originType: varchar("origin_type", { length: 50 }),
    formDescription: text("form_description"),
    standardizationInfo: text("standardization_info"),
    isActive: boolean("is_active").notNull().default(true),
    isPublished: boolean("is_published").notNull().default(false),
    lastReviewedAt: timestamp("last_reviewed_at"),
    lastSyncedAt: timestamp("last_synced_at"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_ingredients_name_ko").on(t.canonicalNameKo),
    index("idx_ingredients_name_en").on(t.canonicalNameEn),
    index("idx_ingredients_slug").on(t.slug),
    index("idx_ingredients_parent").on(t.parentIngredientId),
    index("idx_ingredients_type").on(t.ingredientType),
  ]
);

// ============================================================================
// 2. 원료 동의어 (Ingredient Synonyms)
// ============================================================================

export const ingredientSynonyms = pgTable(
  "ingredient_synonyms",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    synonym: varchar({ length: 255 }).notNull(),
    languageCode: varchar("language_code", { length: 10 }).default("ko"),
    synonymType: varchar("synonym_type", { length: 50 }).notNull(),
    isPreferred: boolean("is_preferred").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_ingredient_synonyms_synonym").on(t.synonym),
    index("idx_ingredient_synonyms_ingredient_id").on(t.ingredientId),
  ]
);

// ============================================================================
// 5. 국가별 규제 상태 (Regulatory Statuses)
// ============================================================================

export const regulatoryStatuses = pgTable(
  "regulatory_statuses",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    countryCode: varchar("country_code", { length: 10 }).notNull(),
    regulatoryCategory: varchar("regulatory_category", {
      length: 100,
    }).notNull(),
    status: varchar({ length: 50 }).notNull(),
    authorityName: varchar("authority_name", { length: 255 }),
    referenceNumber: varchar("reference_number", { length: 255 }),
    referenceUrl: text("reference_url"),
    notes: text(),
    effectiveDate: timestamp("effective_date"),
    expiryDate: timestamp("expiry_date"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_regulatory_statuses_ingredient_id").on(t.ingredientId),
    index("idx_regulatory_statuses_country").on(t.countryCode),
  ]
);

// ============================================================================
// 6. 안전성 (Safety Items)
// ============================================================================

export const safetyItems = pgTable(
  "safety_items",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    safetyType: varchar("safety_type", { length: 50 }).notNull(),
    title: varchar({ length: 255 }).notNull(),
    description: text().notNull(),
    severityLevel: varchar("severity_level", { length: 20 }),
    evidenceLevel: varchar("evidence_level", { length: 20 }),
    frequencyText: varchar("frequency_text", { length: 100 }),
    appliesToPopulation: text("applies_to_population"),
    managementAdvice: text("management_advice"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_safety_items_ingredient_id").on(t.ingredientId),
    index("idx_safety_items_type").on(t.safetyType),
  ]
);

// ============================================================================
// 7. 약물 상호작용 (Ingredient Drug Interactions)
// ============================================================================

export const ingredientDrugInteractions = pgTable(
  "ingredient_drug_interactions",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    drugName: varchar("drug_name", { length: 255 }).notNull(),
    drugClass: varchar("drug_class", { length: 255 }),
    interactionMechanism: text("interaction_mechanism"),
    clinicalEffect: text("clinical_effect"),
    severityLevel: varchar("severity_level", { length: 20 }),
    recommendation: text(),
    evidenceLevel: varchar("evidence_level", { length: 20 }),
    sourceId: bigserial("source_id", { mode: "number" }),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_drug_interactions_ingredient_id").on(t.ingredientId),
    index("idx_drug_interactions_drug_name").on(t.drugName),
  ]
);

// ============================================================================
// 8. 용량 가이드라인 (Dosage Guidelines)
// ============================================================================

export const dosageGuidelines = pgTable(
  "dosage_guidelines",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    populationGroup: varchar("population_group", { length: 100 }).notNull(),
    indicationContext: varchar("indication_context", { length: 255 }),
    doseMin: numeric("dose_min", { precision: 18, scale: 4 }),
    doseMax: numeric("dose_max", { precision: 18, scale: 4 }),
    doseUnit: varchar("dose_unit", { length: 50 }),
    frequencyText: varchar("frequency_text", { length: 100 }),
    route: varchar({ length: 50 }).default("oral"),
    recommendationType: varchar("recommendation_type", { length: 50 }),
    notes: text(),
    sourceId: bigserial("source_id", { mode: "number" }),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [index("idx_dosage_guidelines_ingredient_id").on(t.ingredientId)]
);

// -- Relations --

export const ingredientsRelations = relations(ingredients, ({ one, many }) => ({
  parent: one(ingredients, {
    fields: [ingredients.parentIngredientId],
    references: [ingredients.id],
    relationName: "parentChild",
  }),
  children: many(ingredients, { relationName: "parentChild" }),
  synonyms: many(ingredientSynonyms),
  safetyItems: many(safetyItems),
  drugInteractions: many(ingredientDrugInteractions),
  dosageGuidelines: many(dosageGuidelines),
  regulatoryStatuses: many(regulatoryStatuses),
}));

export const ingredientSynonymsRelations = relations(
  ingredientSynonyms,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [ingredientSynonyms.ingredientId],
      references: [ingredients.id],
    }),
  })
);

export const regulatoryStatusesRelations = relations(
  regulatoryStatuses,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [regulatoryStatuses.ingredientId],
      references: [ingredients.id],
    }),
  })
);

export const safetyItemsRelations = relations(safetyItems, ({ one }) => ({
  ingredient: one(ingredients, {
    fields: [safetyItems.ingredientId],
    references: [ingredients.id],
  }),
}));

export const ingredientDrugInteractionsRelations = relations(
  ingredientDrugInteractions,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [ingredientDrugInteractions.ingredientId],
      references: [ingredients.id],
    }),
  })
);

export const dosageGuidelinesRelations = relations(
  dosageGuidelines,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [dosageGuidelines.ingredientId],
      references: [ingredients.id],
    }),
  })
);
