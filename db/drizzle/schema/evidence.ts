import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  integer,
  numeric,
  uniqueIndex,
  index,
} from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";
import { ingredients } from "./ingredients";
import { claims } from "./claims";

// ============================================================================
// 12. 근거 문헌 (Evidence Studies)
// ============================================================================

export const evidenceStudies = pgTable(
  "evidence_studies",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    sourceType: varchar("source_type", { length: 50 }).notNull(),
    title: text().notNull(),
    abstractText: text("abstract_text"),
    authors: text(),
    journalName: varchar("journal_name", { length: 255 }),
    publicationYear: integer("publication_year"),
    publicationDate: timestamp("publication_date"),
    pmid: varchar({ length: 50 }),
    doi: varchar({ length: 255 }),
    externalUrl: text("external_url"),
    studyDesign: varchar("study_design", { length: 100 }),
    populationText: text("population_text"),
    sampleSize: integer("sample_size"),
    comparatorText: text("comparator_text"),
    durationText: varchar("duration_text", { length: 255 }),
    riskOfBias: varchar("risk_of_bias", { length: 50 }),
    overallRelevanceScore: numeric("overall_relevance_score", {
      precision: 5,
      scale: 2,
    }),
    screeningStatus: varchar("screening_status", { length: 50 }).default(
      "pending"
    ),
    includedInSummary: boolean("included_in_summary").notNull().default(false),
    duplicateGroupKey: varchar("duplicate_group_key", { length: 255 }),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    uniqueIndex("idx_evidence_studies_pmid")
      .on(t.pmid)
      .where(sql`pmid IS NOT NULL`),
    uniqueIndex("idx_evidence_studies_doi")
      .on(t.doi)
      .where(sql`doi IS NOT NULL`),
    index("idx_evidence_studies_ingredient_id").on(t.ingredientId),
    index("idx_evidence_studies_screening").on(t.screeningStatus),
  ]
);

// ============================================================================
// 13. 근거 결과지표 (Evidence Outcomes)
// ============================================================================

export const evidenceOutcomes = pgTable(
  "evidence_outcomes",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    evidenceStudyId: bigserial("evidence_study_id", { mode: "number" })
      .notNull()
      .references(() => evidenceStudies.id, { onDelete: "cascade" }),
    claimId: bigserial("claim_id", { mode: "number" }).references(
      () => claims.id
    ),
    outcomeName: varchar("outcome_name", { length: 255 }).notNull(),
    outcomeType: varchar("outcome_type", { length: 100 }),
    effectDirection: varchar("effect_direction", { length: 20 }),
    effectSizeText: text("effect_size_text"),
    pValueText: varchar("p_value_text", { length: 100 }),
    confidenceIntervalText: varchar("confidence_interval_text", {
      length: 255,
    }),
    conclusionSummary: text("conclusion_summary"),
    adverseEventSummary: text("adverse_event_summary"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_evidence_outcomes_study_id").on(t.evidenceStudyId),
    index("idx_evidence_outcomes_claim_id").on(t.claimId),
  ]
);

// ============================================================================
// 14. 근거 등급 변경 이력 (Evidence Grade History)
// ============================================================================

export const evidenceGradeHistory = pgTable(
  "evidence_grade_history",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    ingredientId: bigserial("ingredient_id", { mode: "number" })
      .notNull()
      .references(() => ingredients.id, { onDelete: "cascade" }),
    claimId: bigserial("claim_id", { mode: "number" })
      .notNull()
      .references(() => claims.id, { onDelete: "cascade" }),
    oldGrade: varchar("old_grade", { length: 10 }),
    newGrade: varchar("new_grade", { length: 10 }),
    changeReason: text("change_reason"),
    changedBy: varchar("changed_by", { length: 255 }),
    changedAt: timestamp("changed_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_evidence_grade_history_ingredient").on(t.ingredientId),
    index("idx_evidence_grade_history_claim").on(t.claimId),
  ]
);

// -- Relations --

export const evidenceStudiesRelations = relations(
  evidenceStudies,
  ({ one, many }) => ({
    ingredient: one(ingredients, {
      fields: [evidenceStudies.ingredientId],
      references: [ingredients.id],
    }),
    outcomes: many(evidenceOutcomes),
  })
);

export const evidenceOutcomesRelations = relations(
  evidenceOutcomes,
  ({ one }) => ({
    study: one(evidenceStudies, {
      fields: [evidenceOutcomes.evidenceStudyId],
      references: [evidenceStudies.id],
    }),
    claim: one(claims, {
      fields: [evidenceOutcomes.claimId],
      references: [claims.id],
    }),
  })
);

export const evidenceGradeHistoryRelations = relations(
  evidenceGradeHistory,
  ({ one }) => ({
    ingredient: one(ingredients, {
      fields: [evidenceGradeHistory.ingredientId],
      references: [ingredients.id],
    }),
    claim: one(claims, {
      fields: [evidenceGradeHistory.claimId],
      references: [claims.id],
    }),
  })
);
