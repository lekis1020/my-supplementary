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
  claimNameKo: varchar("claim_name_ko", { length: 255 }).notNull(),
  claimNameEn: varchar("claim_name_en", { length: 255 }),
  claimCategory: varchar("claim_category", { length: 100 }).notNull(),
  claimScope: varchar("claim_scope", { length: 50 }).notNull(),
  description: text(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

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
    allowedExpression: text("allowed_expression"),
    prohibitedExpression: text("prohibited_expression"),
    sourcePriority: integer("source_priority").default(100),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    unique().on(t.ingredientId, t.claimId, t.approvalCountryCode),
    index("idx_ingredient_claims_ingredient_id").on(t.ingredientId),
    index("idx_ingredient_claims_claim_id").on(t.claimId),
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
