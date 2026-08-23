import {
  pgTable,
  bigserial,
  bigint,
  varchar,
  text,
  boolean,
  timestamp,
  integer,
  numeric,
  jsonb,
  char,
  unique,
  uniqueIndex,
  index,
  check,
} from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";
import { products } from "./products";

// ============================================================================
// 스크레이핑 / 카메라 스캔 / 보강 큐 (Scraping, Scan Telemetry, Enrichment Queue)
// baseline 원격 스키마의 product_aliases / product_enrichment_queue /
// product_images / scan_events / scrape_jobs 를 담는다. 하나의 서브시스템으로
// 묶어 이 파일에 배치.
// ============================================================================

// -- 제품명 variations (Vision 추출 텍스트 매칭 보조) --

export const productAliases = pgTable(
  "product_aliases",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productId: bigint("product_id", { mode: "number" })
      .notNull()
      .references(() => products.id, { onDelete: "cascade" }),
    alias: text().notNull(),
    aliasType: varchar("alias_type", { length: 30 }).notNull(),
    languageCode: varchar("language_code", { length: 5 }).default("ko"),
    source: varchar({ length: 40 }),
    confidence: numeric({ precision: 3, scale: 2 }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [
    unique().on(t.productId, t.alias, t.aliasType),
    index("idx_product_aliases_product").on(t.productId),
    // idx_product_aliases_alias_trgm (GIN, pg_trgm ops) — Drizzle에서 직접
    // 지원하지 않으므로 baseline SQL에서 관리. 여기서는 생략.
  ]
);

// -- 실시간 검색 유입 제품의 성분 구성 보강 큐 --

export const productEnrichmentQueue = pgTable(
  "product_enrichment_queue",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productId: bigint("product_id", { mode: "number" })
      .notNull()
      .unique()
      .references(() => products.id, { onDelete: "cascade" }),
    status: varchar({ length: 20 }).notNull().default("pending"),
    matchedReportNo: varchar("matched_report_no", { length: 255 }),
    attempts: integer().notNull().default(0),
    lastError: text("last_error"),
    source: varchar({ length: 40 }),
    payload: jsonb(),
    scheduledFor: timestamp("scheduled_for", { withTimezone: true })
      .notNull()
      .defaultNow(),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [
    index("idx_product_enrichment_queue_status").on(t.status, t.scheduledFor),
    index("idx_product_enrichment_queue_pending")
      .on(t.scheduledFor)
      .where(sql`status = 'pending'`),
  ]
);

// -- 제품당 다중 소스 이미지 (Cloudflare R2 미러) --

export const productImages = pgTable(
  "product_images",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    productId: bigint("product_id", { mode: "number" })
      .notNull()
      .references(() => products.id, { onDelete: "cascade" }),
    source: varchar({ length: 40 }).notNull(),
    sourceUrl: text("source_url"),
    r2Key: text("r2_key"),
    r2PublicUrl: text("r2_public_url"),
    imageHash: char("image_hash", { length: 64 }),
    mimeType: varchar("mime_type", { length: 50 }),
    width: integer(),
    height: integer(),
    sizeBytes: integer("size_bytes"),
    isPrimary: boolean("is_primary").notNull().default(false),
    removedAt: timestamp("removed_at", { withTimezone: true }),
    capturedAt: timestamp("captured_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [
    unique().on(t.productId, t.imageHash),
    index("idx_product_images_source").on(t.source),
    index("idx_product_images_product")
      .on(t.productId)
      .where(sql`removed_at IS NULL`),
    index("idx_product_images_primary")
      .on(t.productId)
      .where(sql`is_primary = true AND removed_at IS NULL`),
    uniqueIndex("uq_product_images_one_primary")
      .on(t.productId)
      .where(sql`is_primary = true AND removed_at IS NULL`),
  ]
);

// -- 카메라 스캔 이벤트 텔레메트리 (품질/비용/히트율 모니터링) --

export const scanEvents = pgTable(
  "scan_events",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    tierHit: varchar("tier_hit", { length: 20 }).notNull(),
    detectedBarcode: varchar("detected_barcode", { length: 14 }),
    extractedName: text("extracted_name"),
    matchedProductId: bigint("matched_product_id", {
      mode: "number",
    }).references(() => products.id, { onDelete: "set null" }),
    matchConfidence: numeric("match_confidence", { precision: 5, scale: 4 }),
    imageSha256: char("image_sha256", { length: 64 }),
    latencyMs: integer("latency_ms"),
    modelUsed: varchar("model_used", { length: 40 }),
  },
  (t) => [
    check(
      "scan_events_tier_hit_check",
      sql`tier_hit IN ('barcode', 'vision', 'miss')`
    ),
    // idx_scan_events_created / idx_scan_events_miss는 baseline에서
    // created_at DESC로 정렬된다 — Drizzle 인덱스는 컬럼만 표현.
    index("idx_scan_events_created").on(t.createdAt),
    index("idx_scan_events_barcode")
      .on(t.detectedBarcode)
      .where(sql`detected_barcode IS NOT NULL`),
    index("idx_scan_events_matched")
      .on(t.matchedProductId)
      .where(sql`matched_product_id IS NOT NULL`),
    index("idx_scan_events_miss")
      .on(t.createdAt)
      .where(sql`matched_product_id IS NULL`),
  ]
);

// -- 스크레이핑 배치 작업 큐 (재시도/백오프/idempotent, 야간 cron 소비) --

export const scrapeJobs = pgTable(
  "scrape_jobs",
  {
    id: bigserial({ mode: "number" }).primaryKey(),
    targetType: varchar("target_type", { length: 30 }).notNull(),
    // target_id는 target_type에 따라 대상 엔티티가 달라지는 다형(polymorphic)
    // 참조 — FK 없음.
    targetId: bigint("target_id", { mode: "number" }).notNull(),
    targetQuery: text("target_query"),
    source: varchar({ length: 40 }).notNull(),
    status: varchar({ length: 20 }).notNull().default("pending"),
    attempts: integer().notNull().default(0),
    lastError: text("last_error"),
    scheduledFor: timestamp("scheduled_for", { withTimezone: true })
      .notNull()
      .defaultNow(),
    startedAt: timestamp("started_at", { withTimezone: true }),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    resultSummary: jsonb("result_summary"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [
    unique().on(t.targetType, t.targetId, t.source),
    index("idx_scrape_jobs_status").on(t.status, t.scheduledFor),
    index("idx_scrape_jobs_source").on(t.source, t.status),
    index("idx_scrape_jobs_pending")
      .on(t.scheduledFor)
      .where(sql`status = 'pending'`),
  ]
);

// -- KR 정부 규제 기준 staging (I0960) --
// 기존 staging 전용 파일이 없어(collection.ts 등에 staging_* 테이블 없음)
// 스크레이핑/큐 서브시스템 파일에 함께 배치.

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

// -- Relations --

export const productAliasesRelations = relations(
  productAliases,
  ({ one }) => ({
    product: one(products, {
      fields: [productAliases.productId],
      references: [products.id],
    }),
  })
);

export const productEnrichmentQueueRelations = relations(
  productEnrichmentQueue,
  ({ one }) => ({
    product: one(products, {
      fields: [productEnrichmentQueue.productId],
      references: [products.id],
    }),
  })
);

export const productImagesRelations = relations(productImages, ({ one }) => ({
  product: one(products, {
    fields: [productImages.productId],
    references: [products.id],
  }),
}));

export const scanEventsRelations = relations(scanEvents, ({ one }) => ({
  matchedProduct: one(products, {
    fields: [scanEvents.matchedProductId],
    references: [products.id],
  }),
}));
