import {
  pgTable,
  bigserial,
  varchar,
  text,
  integer,
  boolean,
  timestamp,
  unique,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// ============================================================================
// 0. 코드 테이블 (ENUM 대체)
// ============================================================================

export const codeTables = pgTable("code_tables", {
  id: bigserial({ mode: "number" }).primaryKey(),
  tableCode: varchar("table_code", { length: 100 }).notNull().unique(),
  tableNameKo: varchar("table_name_ko", { length: 255 }).notNull(),
  tableNameEn: varchar("table_name_en", { length: 255 }),
  description: text(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const codeValues = pgTable(
  "code_values",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    codeTableId: bigserial("code_table_id", { mode: "number" })
      .notNull()
      .references(() => codeTables.id, { onDelete: "cascade" }),
    code: varchar({ length: 100 }).notNull(),
    labelKo: varchar("label_ko", { length: 255 }).notNull(),
    labelEn: varchar("label_en", { length: 255 }),
    sortOrder: integer("sort_order").default(0),
    isActive: boolean("is_active").notNull().default(true),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [unique().on(t.codeTableId, t.code)]
);

// -- Relations --

export const codeTablesRelations = relations(codeTables, ({ many }) => ({
  values: many(codeValues),
}));

export const codeValuesRelations = relations(codeValues, ({ one }) => ({
  codeTable: one(codeTables, {
    fields: [codeValues.codeTableId],
    references: [codeTables.id],
  }),
}));
