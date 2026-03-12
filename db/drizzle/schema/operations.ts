import {
  pgTable,
  bigserial,
  varchar,
  text,
  boolean,
  timestamp,
  jsonb,
  index,
} from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";

// ============================================================================
// 17. 검수 워크플로우 (Review Tasks)
// ============================================================================

export const reviewTasks = pgTable(
  "review_tasks",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    entityId: bigserial("entity_id", { mode: "number" }).notNull(),
    taskType: varchar("task_type", { length: 50 }).notNull(),
    reviewLevel: varchar("review_level", { length: 10 })
      .notNull()
      .default("L1"),
    status: varchar({ length: 50 }).notNull().default("pending"),
    priority: varchar({ length: 20 }).default("normal"),
    assignedTo: varchar("assigned_to", { length: 255 }),
    assignedRole: varchar("assigned_role", { length: 50 }),
    reviewerComment: text("reviewer_comment"),
    rejectionReason: text("rejection_reason"),
    parentTaskId: bigserial("parent_task_id", {
      mode: "number",
    }).references((): any => reviewTasks.id),
    autoCheckPassed: boolean("auto_check_passed"),
    autoCheckDetails: jsonb("auto_check_details"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
    reviewedAt: timestamp("reviewed_at"),
    dueAt: timestamp("due_at"),
  },
  (t) => [
    index("idx_review_tasks_entity").on(t.entityType, t.entityId),
    index("idx_review_tasks_status").on(t.status),
    index("idx_review_tasks_level").on(t.reviewLevel, t.status),
    index("idx_review_tasks_assigned").on(t.assignedTo, t.status),
    index("idx_review_tasks_due").on(t.dueAt),
    index("idx_review_tasks_parent").on(t.parentTaskId),
  ]
);

// ============================================================================
// 18. 변경 이력 (Revision Histories)
// ============================================================================

export const revisionHistories = pgTable(
  "revision_histories",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    entityId: bigserial("entity_id", { mode: "number" }).notNull(),
    fieldName: varchar("field_name", { length: 255 }),
    oldValue: text("old_value"),
    newValue: text("new_value"),
    changeType: varchar("change_type", { length: 50 }),
    changedBy: varchar("changed_by", { length: 255 }),
    changeReason: text("change_reason"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_revision_histories_entity").on(t.entityType, t.entityId),
    index("idx_revision_histories_created").on(t.createdAt),
  ]
);

// ============================================================================
// 19. 검색 최적화 (Ingredient Search Documents)
// ============================================================================

export const ingredientSearchDocuments = pgTable("ingredient_search_documents", {
  ingredientId: bigserial("ingredient_id", { mode: "number" }).primaryKey(),
  searchText: text("search_text").notNull(),
  // search_vector는 tsvector 타입 — Drizzle에서 직접 지원하지 않으므로
  // SQL migration에서 관리. 여기서는 생략.
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

// -- Relations --

export const reviewTasksRelations = relations(
  reviewTasks,
  ({ one, many }) => ({
    parentTask: one(reviewTasks, {
      fields: [reviewTasks.parentTaskId],
      references: [reviewTasks.id],
      relationName: "parentChild",
    }),
    childTasks: many(reviewTasks, { relationName: "parentChild" }),
  })
);
