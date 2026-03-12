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
import { relations } from "drizzle-orm";
import { sources } from "./sources";

// ============================================================================
// 22. 소스 커넥터 (Source Connectors)
// ============================================================================

export const sourceConnectors = pgTable(
  "source_connectors",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceId: bigserial("source_id", { mode: "number" })
      .notNull()
      .references(() => sources.id, { onDelete: "cascade" }),
    connectorName: varchar("connector_name", { length: 255 }).notNull(),
    sourceCategory: varchar("source_category", { length: 100 }).notNull(),
    baseUrl: text("base_url"),
    accessStrategy: varchar("access_strategy", { length: 50 }).notNull(),
    authType: varchar("auth_type", { length: 50 }).default("none"),
    isActive: boolean("is_active").notNull().default(true),
    rateLimitPerMinute: integer("rate_limit_per_minute"),
    retryPolicy: jsonb("retry_policy"),
    parserConfig: jsonb("parser_config"),
    schedulePolicy: jsonb("schedule_policy"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_source_connectors_source_id").on(t.sourceId),
    index("idx_source_connectors_strategy").on(t.accessStrategy),
  ]
);

// ============================================================================
// 23. 수집 작업 정의 (Collection Jobs)
// ============================================================================

export const collectionJobs = pgTable(
  "collection_jobs",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceConnectorId: bigserial("source_connector_id", { mode: "number" })
      .notNull()
      .references(() => sourceConnectors.id),
    jobType: varchar("job_type", { length: 50 }).notNull(),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    jobName: varchar("job_name", { length: 255 }).notNull(),
    queryPayload: jsonb("query_payload"),
    priority: varchar({ length: 20 }).default("normal"),
    status: varchar({ length: 50 }).notNull().default("pending"),
    scheduledAt: timestamp("scheduled_at"),
    startedAt: timestamp("started_at"),
    finishedAt: timestamp("finished_at"),
    retryCount: integer("retry_count").notNull().default(0),
    errorMessage: text("error_message"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_collection_jobs_connector").on(t.sourceConnectorId),
    index("idx_collection_jobs_status").on(t.status),
    index("idx_collection_jobs_scheduled").on(t.scheduledAt),
  ]
);

// ============================================================================
// 24. 수집 실행 로그 (Collection Runs)
// ============================================================================

export const collectionRuns = pgTable(
  "collection_runs",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    collectionJobId: bigserial("collection_job_id", { mode: "number" })
      .notNull()
      .references(() => collectionJobs.id, { onDelete: "cascade" }),
    runStatus: varchar("run_status", { length: 50 }).notNull(),
    recordsFetched: integer("records_fetched").default(0),
    recordsCreated: integer("records_created").default(0),
    recordsUpdated: integer("records_updated").default(0),
    recordsUnchanged: integer("records_unchanged").default(0),
    recordsFailed: integer("records_failed").default(0),
    startedAt: timestamp("started_at").notNull().defaultNow(),
    finishedAt: timestamp("finished_at"),
    executionLog: text("execution_log"),
    errorDetails: jsonb("error_details"),
  },
  (t) => [
    index("idx_collection_runs_job").on(t.collectionJobId),
    index("idx_collection_runs_status").on(t.runStatus),
  ]
);

// ============================================================================
// 25. 원문 저장소 (Raw Documents)
// ============================================================================

export const rawDocuments = pgTable(
  "raw_documents",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    sourceConnectorId: bigserial("source_connector_id", { mode: "number" })
      .notNull()
      .references(() => sourceConnectors.id),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    entityExternalId: varchar("entity_external_id", { length: 255 }),
    sourceUrl: text("source_url"),
    contentType: varchar("content_type", { length: 100 }),
    rawText: text("raw_text"),
    rawJson: jsonb("raw_json"),
    filePath: text("file_path"),
    screenshotPath: text("screenshot_path"),
    htmlSnapshotPath: text("html_snapshot_path"),
    checksum: varchar({ length: 128 }),
    fetchedAt: timestamp("fetched_at").notNull().defaultNow(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_raw_documents_connector").on(t.sourceConnectorId),
    index("idx_raw_documents_entity").on(t.entityType, t.entityExternalId),
    index("idx_raw_documents_checksum").on(t.checksum),
    index("idx_raw_documents_fetched").on(t.fetchedAt),
  ]
);

// ============================================================================
// 26. 추출 결과 (Extraction Results)
// ============================================================================

export const extractionResults = pgTable(
  "extraction_results",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    rawDocumentId: bigserial("raw_document_id", { mode: "number" })
      .notNull()
      .references(() => rawDocuments.id, { onDelete: "cascade" }),
    extractionVersion: varchar("extraction_version", { length: 50 }).notNull(),
    schemaVersion: varchar("schema_version", { length: 50 }).notNull(),
    extractionMethod: varchar("extraction_method", { length: 50 }).notNull(),
    extractedFields: jsonb("extracted_fields").notNull(),
    confidenceScore: numeric("confidence_score", { precision: 5, scale: 2 }),
    needsReview: boolean("needs_review").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_extraction_results_raw_doc").on(t.rawDocumentId),
    index("idx_extraction_results_needs_review").on(t.needsReview),
    index("idx_extraction_results_confidence").on(t.confidenceScore),
  ]
);

// ============================================================================
// 27. 갱신 정책 (Refresh Policies)
// ============================================================================

export const refreshPolicies = pgTable(
  "refresh_policies",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    sourceConnectorId: bigserial("source_connector_id", {
      mode: "number",
    }).references(() => sourceConnectors.id),
    refreshMode: varchar("refresh_mode", { length: 50 }).notNull(),
    fullSyncCron: varchar("full_sync_cron", { length: 100 }),
    incrementalSyncCron: varchar("incremental_sync_cron", { length: 100 }),
    stalenessDays: integer("staleness_days"),
    changeDetectionMethod: varchar("change_detection_method", { length: 50 }),
    isActive: boolean("is_active").notNull().default(true),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    index("idx_refresh_policies_entity").on(t.entityType),
    index("idx_refresh_policies_connector").on(t.sourceConnectorId),
  ]
);

// ============================================================================
// 28. 엔티티 갱신 상태 (Entity Refresh States)
// ============================================================================

export const entityRefreshStates = pgTable(
  "entity_refresh_states",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    entityType: varchar("entity_type", { length: 50 }).notNull(),
    entityId: bigserial("entity_id", { mode: "number" }).notNull(),
    sourceConnectorId: bigserial("source_connector_id", {
      mode: "number",
    }).references(() => sourceConnectors.id),
    externalId: varchar("external_id", { length: 255 }),
    lastFetchedAt: timestamp("last_fetched_at"),
    lastChangedAt: timestamp("last_changed_at"),
    lastChecksum: varchar("last_checksum", { length: 128 }),
    lastRefreshStatus: varchar("last_refresh_status", { length: 50 }),
    nextScheduledRefreshAt: timestamp("next_scheduled_refresh_at"),
    refreshPriority: varchar("refresh_priority", { length: 20 }).default(
      "normal"
    ),
  },
  (t) => [
    unique().on(t.entityType, t.entityId, t.sourceConnectorId),
    index("idx_refresh_states_next").on(t.nextScheduledRefreshAt),
    index("idx_refresh_states_status").on(t.lastRefreshStatus),
    index("idx_refresh_states_entity").on(t.entityType, t.entityId),
  ]
);

// -- Relations --

export const sourceConnectorsRelations = relations(
  sourceConnectors,
  ({ one, many }) => ({
    source: one(sources, {
      fields: [sourceConnectors.sourceId],
      references: [sources.id],
    }),
    collectionJobs: many(collectionJobs),
    rawDocuments: many(rawDocuments),
    refreshPolicies: many(refreshPolicies),
    entityRefreshStates: many(entityRefreshStates),
  })
);

export const collectionJobsRelations = relations(
  collectionJobs,
  ({ one, many }) => ({
    sourceConnector: one(sourceConnectors, {
      fields: [collectionJobs.sourceConnectorId],
      references: [sourceConnectors.id],
    }),
    runs: many(collectionRuns),
  })
);

export const collectionRunsRelations = relations(
  collectionRuns,
  ({ one }) => ({
    job: one(collectionJobs, {
      fields: [collectionRuns.collectionJobId],
      references: [collectionJobs.id],
    }),
  })
);

export const rawDocumentsRelations = relations(
  rawDocuments,
  ({ one, many }) => ({
    sourceConnector: one(sourceConnectors, {
      fields: [rawDocuments.sourceConnectorId],
      references: [sourceConnectors.id],
    }),
    extractionResults: many(extractionResults),
  })
);

export const extractionResultsRelations = relations(
  extractionResults,
  ({ one }) => ({
    rawDocument: one(rawDocuments, {
      fields: [extractionResults.rawDocumentId],
      references: [rawDocuments.id],
    }),
  })
);

export const refreshPoliciesRelations = relations(
  refreshPolicies,
  ({ one }) => ({
    sourceConnector: one(sourceConnectors, {
      fields: [refreshPolicies.sourceConnectorId],
      references: [sourceConnectors.id],
    }),
  })
);

export const entityRefreshStatesRelations = relations(
  entityRefreshStates,
  ({ one }) => ({
    sourceConnector: one(sourceConnectors, {
      fields: [entityRefreshStates.sourceConnectorId],
      references: [sourceConnectors.id],
    }),
  })
);
