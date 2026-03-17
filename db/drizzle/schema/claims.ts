import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  integer,
  unique,
  index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { ingredients } from "./ingredients";

// ============================================================================
// 3. 기능성/효능 (Claims)
// ============================================================================

export const claims = pgTable("claims", {
  id: bigserial({ mode: "number" }).primaryKey(),
  claimCode: varchar("claim_code", { length: 100 }).unique(),
  claimKey: varchar("claim_key", { length: 150 }).unique(),
  claimNameKo: varchar("claim_name_ko", { length: 255 }).notNull(),
  claimNameEn: varchar("claim_name_en", { length: 255 }),
  canonicalClaimKo: varchar("canonical_claim_ko", { length: 255 }),
  canonicalClaimEn: varchar("canonical_claim_en", { length: 255 }),
  claimSubjectKo: varchar("claim_subject_ko", { length: 255 }),
  claimSubjectEn: varchar("claim_subject_en", { length: 255 }),
  predicateType: varchar("predicate_type", { length: 50 }),
  claimCategory: varchar("claim_category", { length: 100 }).notNull(),
  claimScope: varchar("claim_scope", { length: 50 }).notNull(),
  sourceLanguage: varchar("source_language", { length: 10 }).default("ko"),
  description: text(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
}, (t) => [
  index("idx_claims_claim_key").on(t.claimKey),
  index("idx_claims_predicate_type").on(t.predicateType),
  index("idx_claims_claim_subject_ko").on(t.claimSubjectKo),
]);

// ============================================================================
// 4. 원료-기능성 연결 (Ingredient Claims, M:N)
// ============================================================================

export const ingredientClaims = pgTable(
  "ingredient_claims",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    claimId: bigserial("claim_id", { mode: "number" })
      .notNull()
      .references(() => claims.id, { onDelete: "cascade" }),
    evidenceGrade: varchar("evidence_grade", { length: 10 }),
    evidenceSummary: text("evidence_summary"),
    isRegulatorApproved: boolean("is_regulator_approved")
      .notNull()
      .default(false),
    approvalCountryCode: varchar("approval_country_code", { length: 10 }),
    rawClaimText: text("raw_claim_text"),
    rawClaimLanguage: varchar("raw_claim_language", { length: 10 }).default("ko"),
    allowedExpression: text("allowed_expression"),
    prohibitedExpression: text("prohibited_expression"),
    recognitionNo: varchar("recognition_no", { length: 100 }),
    evidenceGradeText: varchar("evidence_grade_text", { length: 100 }),
    claimScopeNote: text("claim_scope_note"),
    sourceDataset: varchar("source_dataset", { length: 100 }),
    sourcePriority: integer("source_priority").default(100),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique().on(t.ingredientId, t.claimId, t.approvalCountryCode),
    index("idx_ingredient_claims_ingredient_id").on(t.ingredientId),
    index("idx_ingredient_claims_claim_id").on(t.claimId),
    index("idx_ingredient_claims_recognition_no").on(t.recognitionNo),
    index("idx_ingredient_claims_source_dataset").on(t.sourceDataset),
  ]
);

// -- Relations --

export const claimsRelations = relations(claims, ({ many }) => ({
  ingredientClaims: many(ingredientClaims),
}));

export const ingredientClaimsRelations = relations(
  ingredientClaims,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [ingredientClaims.ingredientId],
      references: [ingredients.id],
    }),
    claim: one(claims, {
      fields: [ingredientClaims.claimId],
      references: [claims.id],
    }),
  })
);
