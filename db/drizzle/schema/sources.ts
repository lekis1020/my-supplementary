import {
  pgTable,
  bigserial,
  varchar,
  text,
  timestamp,
  index,
  check,
} from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";

// ============================================================================
// 15. 출처 관리 (Sources)
// ============================================================================

export const sources = pgTable(
  "sources",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceName: varchar("source_name", { length: 255 }).notNull(),
    sourceType: varchar("source_type", { length: 50 }).notNull(),
    organizationName: varchar("organization_name", { length: 255 }),
    sourceUrl: text("source_url"),
    countryCode: varchar("country_code", { length: 10 }),
    trustLevel: varchar("trust_level", { length: 20 }),
    accessMethod: varchar("access_method", { length: 50 }),
    notes: text(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [index("idx_sources_type").on(t.sourceType)]
);

// ============================================================================
// 16. 출처 연결 (Source Links — Polymorphic)
// ============================================================================

export const sourceLinks = pgTable(
  "source_links",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceId: bigserial("source_id", { mode: "number" })
      .notNull()
      .references(() => sources.id, { onDelete: "cascade" }),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    entityId: bigserial("entity_id", { mode: "number" }).notNull(),
    sourceReference: text("source_reference"),
    sourceExcerpt: text("source_excerpt"),
    retrievedAt: timestamp("retrieved_at"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_source_links_entity").on(t.entityType, t.entityId),
    index("idx_source_links_source_id").on(t.sourceId),
    check(
      "chk_source_links_entity_type",
      sql`entity_type IN (
        'ingredient', 'claim', 'safety_item', 'product',
        'label_snapshot', 'evidence_study', 'dosage_guideline',
        'ingredient_drug_interaction', 'regulatory_status'
      )`
    ),
  ]
);

// -- Relations --

export const sourcesRelations = relations(sources, ({ many }) => ({
  sourceLinks: many(sourceLinks),
}));

export const sourceLinksRelations = relations(sourceLinks, ({ one }) => ({
  source: one(sources, {
    fields: [sourceLinks.sourceId],
    references: [sources.id],
  }),
}));
