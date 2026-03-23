#!/usr/bin/env node

/**
 * verify_data_integrity.mjs
 *
 * 데이터 무결성 검증: 파이프라인 3계층 교차검증
 *   Layer 1: Source API  ↔  raw_documents
 *   Layer 2: raw_documents  ↔  staging_*_kr
 *   Layer 3: staging_*_kr  ↔  core tables
 *
 * Usage:
 *   node scripts/verify_data_integrity.mjs [options]
 *
 * Options:
 *   --mode=full|sample     검증 모드 (default: sample)
 *   --layer=1,2,3          검증 레이어 (default: 2,3)
 *   --size=N               샘플 크기 (default: 50)
 *   --dry-run              리포트만 출력, DB 저장 안함
 *   --verbose              불일치 상세 출력
 */

import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import postgres from "postgres";

// ============================================================================
// Environment
// ============================================================================

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");

const envCandidates = [
  path.join(webDir, ".env.local"),
  path.join(rootDir, ".env.local"),
  path.join(webDir, ".env"),
  path.join(rootDir, ".env"),
];

function parseEnvFile(filePath) {
  const values = {};
  const content = readFileSync(filePath, "utf8");

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const sep = line.indexOf("=");
    if (sep === -1) continue;

    const key = line.slice(0, sep).trim();
    let value = line.slice(sep + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    values[key] = value;
  }

  return values;
}

for (const envPath of envCandidates) {
  if (!existsSync(envPath)) continue;

  const values = parseEnvFile(envPath);
  for (const [key, value] of Object.entries(values)) {
    if (!process.env[key]) process.env[key] = value;
  }
}

// ============================================================================
// Args
// ============================================================================

function parseArgs(argv) {
  const args = {
    mode: "sample",
    layers: [2, 3],
    size: 50,
    dryRun: false,
    verbose: false,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }
    if (token === "--verbose") {
      args.verbose = true;
      continue;
    }
    if (token.startsWith("--mode=")) {
      args.mode = token.split("=")[1];
      continue;
    }
    if (token.startsWith("--layer=")) {
      args.layers = token.split("=")[1].split(",").map(Number);
      continue;
    }
    if (token.startsWith("--size=")) {
      args.size = Number(token.split("=")[1]);
      continue;
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));
const databaseUrl = process.env.DATABASE_URL;
const foodsafetyKey = process.env.FOODSAFETY_KOREA_API_KEY;

// ============================================================================
// Helpers
// ============================================================================

function sha256(input) {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}: ${url}`);
  return response.json();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function daysAgo(dateStr) {
  if (!dateStr) return null;
  const diff = Date.now() - new Date(dateStr).getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24));
}

function fmt(n) {
  return n != null ? n.toLocaleString() : "N/A";
}

function printHeader(title) {
  console.log(`\n${"=".repeat(64)}`);
  console.log(`  ${title}`);
  console.log(`${"=".repeat(64)}`);
}

function printSection(title) {
  console.log(`\n--- ${title} ---\n`);
}

function statusIcon(status) {
  if (status === "pass") return "OK";
  if (status === "warn") return "!!";
  return "FAIL";
}

// ============================================================================
// API Connectors (Layer 1 전용, backfill_kr_gov_raw.mjs와 동일 엔드포인트)
// ============================================================================

const apiConnectors = [
  {
    key: "I0030",
    label: "제품 카탈로그",
    entityType: "product",
    dbConnectorName: "foodsafety-kr-i0030",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I0030/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I0030?.total_count ?? 0),
        records: payload.I0030?.row ?? [],
      };
    },
    externalId(record) {
      return record.PRDLST_REPORT_NO ?? null;
    },
  },
  {
    key: "C003",
    label: "제품 원재료",
    entityType: "product_rawmaterial",
    dbConnectorName: "foodsafety-kr-c003",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/C003/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.C003?.total_count ?? 0),
        records: payload.C003?.row ?? [],
      };
    },
    externalId(record) {
      return record.PRDLST_REPORT_NO ?? null;
    },
  },
  {
    key: "I2710",
    label: "원료 기능성",
    entityType: "ingredient_claim_profile",
    dbConnectorName: "foodsafety-kr-i2710",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I2710/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I2710?.total_count ?? 0),
        records: payload.I2710?.row ?? [],
      };
    },
    externalId(record) {
      return record.PRDCT_NM ? `I2710:${record.PRDCT_NM}` : null;
    },
  },
  {
    key: "I-0040",
    label: "원료 규제 기록",
    entityType: "ingredient_regulatory_record",
    dbConnectorName: "foodsafety-kr-i-0040",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I-0040/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload["I-0040"]?.total_count ?? 0),
        records: payload["I-0040"]?.row ?? [],
      };
    },
    externalId(record) {
      return record.HF_FNCLTY_MTRAL_RCOGN_NO ?? null;
    },
  },
  {
    key: "I-0050",
    label: "원료 인정서",
    entityType: "ingredient_recognition_profile",
    dbConnectorName: "foodsafety-kr-i-0050",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I-0050/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload["I-0050"]?.total_count ?? 0),
        records: payload["I-0050"]?.row ?? [],
      };
    },
    externalId(record) {
      return record.HF_FNCLTY_MTRAL_RCOGN_NO ?? null;
    },
  },
  {
    key: "I0760",
    label: "원료 그룹",
    entityType: "ingredient_group",
    dbConnectorName: "foodsafety-kr-i0760",
    pageSize: 1000,
    sleepMs: 2200,
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I0760/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I0760?.total_count ?? 0),
        records: payload.I0760?.row ?? [],
      };
    },
    externalId(record) {
      return record.HELT_ITM_GRP_CD ?? null;
    },
  },
];

// ============================================================================
// Layer 3: Staging ↔ Core
// ============================================================================

async function layer3Counts(sql) {
  const [counts] = await sql`
    SELECT
      (SELECT count(*) FROM staging_products_kr)::int AS staging_products,
      (SELECT count(*) FROM products WHERE country_code = 'KR')::int AS core_products,
      (SELECT count(*) FROM staging_ingredients_kr)::int AS staging_ingredients,
      (SELECT count(*) FROM ingredients)::int AS core_ingredients,
      (SELECT count(*) FROM staging_product_ingredients_kr)::int AS staging_pi,
      (SELECT count(*) FROM product_ingredients)::int AS core_pi
  `;
  return counts;
}

async function layer3MissingProducts(sql, limit) {
  const missingInCore = await sql`
    SELECT sp.report_no, sp.product_name, sp.manufacturer_name
    FROM staging_products_kr sp
    LEFT JOIN products p ON sp.report_no = p.approval_or_report_no
    WHERE p.id IS NULL
    ORDER BY sp.report_no
    LIMIT ${limit}
  `;

  const missingInStaging = await sql`
    SELECT p.id, p.product_name, p.approval_or_report_no
    FROM products p
    LEFT JOIN staging_products_kr sp ON p.approval_or_report_no = sp.report_no
    WHERE sp.id IS NULL
      AND p.country_code = 'KR'
      AND p.approval_or_report_no IS NOT NULL
    ORDER BY p.id
    LIMIT ${limit}
  `;

  return { missingInCore, missingInStaging };
}

async function layer3MissingIngredients(sql, limit) {
  const missingInCore = await sql`
    SELECT si.canonical_name_ko, si.slug, si.ingredient_type
    FROM staging_ingredients_kr si
    LEFT JOIN ingredients i ON si.canonical_name_ko = i.canonical_name_ko
    WHERE i.id IS NULL
    ORDER BY si.canonical_name_ko
    LIMIT ${limit}
  `;

  const missingInStaging = await sql`
    SELECT i.id, i.canonical_name_ko, i.slug
    FROM ingredients i
    LEFT JOIN staging_ingredients_kr si ON i.canonical_name_ko = si.canonical_name_ko
    WHERE si.id IS NULL
    ORDER BY i.id
    LIMIT ${limit}
  `;

  return { missingInCore, missingInStaging };
}

async function layer3ProductFieldMismatches(sql, limit) {
  return sql`
    SELECT
      sp.report_no,
      sp.product_name AS staging_name,
      p.product_name AS core_name,
      sp.manufacturer_name AS staging_manufacturer,
      p.manufacturer_name AS core_manufacturer,
      sp.status AS staging_status,
      p.status AS core_status
    FROM staging_products_kr sp
    INNER JOIN products p ON sp.report_no = p.approval_or_report_no
    WHERE sp.product_name IS DISTINCT FROM p.product_name
       OR sp.manufacturer_name IS DISTINCT FROM p.manufacturer_name
       OR sp.status IS DISTINCT FROM p.status
    ORDER BY sp.report_no
    LIMIT ${limit}
  `;
}

async function layer3IngredientFieldMismatches(sql, limit) {
  return sql`
    SELECT
      si.canonical_name_ko,
      si.slug AS staging_slug,
      i.slug AS core_slug,
      si.ingredient_type AS staging_type,
      i.ingredient_type AS core_type,
      si.display_name AS staging_display,
      i.display_name AS core_display
    FROM staging_ingredients_kr si
    INNER JOIN ingredients i ON si.canonical_name_ko = i.canonical_name_ko
    WHERE si.slug IS DISTINCT FROM i.slug
       OR si.ingredient_type IS DISTINCT FROM i.ingredient_type
       OR si.display_name IS DISTINCT FROM i.display_name
    ORDER BY si.canonical_name_ko
    LIMIT ${limit}
  `;
}

// ============================================================================
// Layer 2: Raw Documents ↔ Staging
// ============================================================================

async function layer2Counts(sql) {
  return sql`
    SELECT
      entity_type,
      count(DISTINCT entity_external_id)::int AS unique_entities,
      count(*)::int AS total_rows,
      max(fetched_at) AS last_fetched
    FROM raw_documents
    GROUP BY entity_type
    ORDER BY entity_type
  `;
}

async function layer2MissingInStaging(sql, limit) {
  const missingProducts = await sql`
    SELECT DISTINCT rd.entity_external_id AS report_no
    FROM raw_documents rd
    LEFT JOIN staging_products_kr sp ON rd.entity_external_id = sp.report_no
    WHERE rd.entity_type = 'product'
      AND sp.id IS NULL
      AND rd.entity_external_id IS NOT NULL
    ORDER BY rd.entity_external_id
    LIMIT ${limit}
  `;

  return { missingProducts };
}

// ============================================================================
// Layer 1: Source API ↔ DB
// ============================================================================

async function layer1CountChecks(sql) {
  if (!foodsafetyKey) {
    return { error: "FOODSAFETY_KOREA_API_KEY not set" };
  }

  const results = [];

  for (const connector of apiConnectors) {
    try {
      const payload = await fetchJson(connector.buildPageUrl(1));
      const page = connector.normalizePage(payload);
      const apiTotal = page.totalCount;

      const [dbCount] = await sql`
        SELECT count(DISTINCT entity_external_id)::int AS cnt
        FROM raw_documents
        WHERE entity_type = ${connector.entityType}
          AND entity_external_id IS NOT NULL
      `;

      results.push({
        key: connector.key,
        label: connector.label,
        entityType: connector.entityType,
        apiTotal,
        dbCount: dbCount.cnt,
        diff: dbCount.cnt - apiTotal,
      });

      await sleep(connector.sleepMs);
    } catch (error) {
      results.push({
        key: connector.key,
        label: connector.label,
        entityType: connector.entityType,
        error: error.message,
      });
    }
  }

  return { results };
}

async function layer1Freshness(sql) {
  return sql`
    SELECT
      sc.connector_name,
      rd.entity_type,
      max(rd.fetched_at) AS last_fetched,
      count(DISTINCT rd.entity_external_id)::int AS unique_count
    FROM raw_documents rd
    LEFT JOIN source_connectors sc ON rd.source_connector_id = sc.id
    GROUP BY sc.connector_name, rd.entity_type
    ORDER BY max(rd.fetched_at) ASC
  `;
}

async function layer1SampleVerify(sql, sampleSize) {
  if (!foodsafetyKey) {
    return { error: "FOODSAFETY_KOREA_API_KEY not set" };
  }

  const connector = apiConnectors.find((c) => c.key === "I0030");
  if (!connector) return { error: "I0030 connector not found" };

  // 1) API total_count → totalPages 계산
  const firstPayload = await fetchJson(connector.buildPageUrl(1));
  const { totalCount } = connector.normalizePage(firstPayload);
  const totalPages = Math.ceil(totalCount / connector.pageSize) || 1;

  // 2) 랜덤 페이지 선택 (최대 3 페이지로 API 부하 제한)
  const pagesToSample = Math.min(
    Math.ceil(sampleSize / connector.pageSize),
    totalPages,
    3,
  );

  const usedPages = new Set();
  const mismatches = [];
  const matches = [];
  let checked = 0;

  for (let i = 0; i < pagesToSample && checked < sampleSize; i++) {
    let page;
    do {
      page = Math.floor(Math.random() * totalPages) + 1;
    } while (usedPages.has(page) && usedPages.size < totalPages);
    usedPages.add(page);

    if (i > 0) await sleep(connector.sleepMs);

    const payload = await fetchJson(connector.buildPageUrl(page));
    const { records } = connector.normalizePage(payload);

    // 페이지 내 랜덤 샘플 선택
    const shuffled = [...records].sort(() => Math.random() - 0.5);
    const toCheck = shuffled.slice(0, Math.min(sampleSize - checked, 20));

    const externalIds = toCheck
      .map((r) => connector.externalId(r))
      .filter(Boolean);

    if (externalIds.length === 0) continue;

    // raw_documents checksum 비교
    const storedRows = await sql`
      SELECT DISTINCT ON (entity_external_id)
        entity_external_id, checksum, raw_json
      FROM raw_documents
      WHERE entity_type = ${connector.entityType}
        AND entity_external_id = ANY(${sql.array(externalIds, "text")})
      ORDER BY entity_external_id, fetched_at DESC
    `;
    const storedMap = new Map(
      storedRows.map((r) => [r.entity_external_id, r]),
    );

    // core products 테이블 비교
    const coreProducts = await sql`
      SELECT id, approval_or_report_no, product_name, manufacturer_name
      FROM products
      WHERE approval_or_report_no = ANY(${sql.array(externalIds, "text")})
    `;
    const coreMap = new Map(
      coreProducts.map((r) => [r.approval_or_report_no, r]),
    );

    for (const record of toCheck) {
      const extId = connector.externalId(record);
      if (!extId) continue;
      checked++;

      const rawText = JSON.stringify(record);
      const currentChecksum = sha256(rawText);
      const stored = storedMap.get(extId);
      const core = coreMap.get(extId);

      const issues = [];

      // Check 1: raw_documents 존재 + checksum 일치
      if (!stored) {
        issues.push({
          field: "raw_documents",
          type: "missing_in_db",
          sourceValue: extId,
          dbValue: null,
        });
      } else if (stored.checksum !== currentChecksum) {
        issues.push({
          field: "checksum",
          type: "source_changed",
          sourceValue: `${currentChecksum.slice(0, 16)}...`,
          dbValue: `${stored.checksum.slice(0, 16)}...`,
        });
      }

      // Check 2: core products 존재 + 핵심 필드 일치
      if (!core) {
        issues.push({
          field: "products",
          type: "missing_in_db",
          sourceValue: extId,
          dbValue: null,
        });
      } else {
        const apiName = record.PRDLST_NM;
        if (apiName && apiName !== core.product_name) {
          issues.push({
            field: "product_name",
            type: "field_mismatch",
            sourceValue: apiName,
            dbValue: core.product_name,
          });
        }

        const apiManufacturer = record.BSSH_NM;
        if (apiManufacturer && apiManufacturer !== core.manufacturer_name) {
          issues.push({
            field: "manufacturer_name",
            type: "field_mismatch",
            sourceValue: apiManufacturer,
            dbValue: core.manufacturer_name,
          });
        }
      }

      if (issues.length > 0) {
        mismatches.push({ extId, productName: record.PRDLST_NM, issues });
      } else {
        matches.push(extId);
      }
    }
  }

  return {
    totalChecked: checked,
    matched: matches.length,
    mismatched: mismatches.length,
    mismatches,
    matchRate:
      checked > 0
        ? ((matches.length / checked) * 100).toFixed(1)
        : "N/A",
  };
}

// ============================================================================
// Internal Integrity Checks
// ============================================================================

async function checkIntegrity(sql) {
  const results = [];

  const [nullProductNames] = await sql`
    SELECT count(*)::int AS cnt FROM products WHERE product_name IS NULL
  `;
  results.push({
    name: "products.product_name NOT NULL",
    count: nullProductNames.cnt,
    status: nullProductNames.cnt === 0 ? "pass" : "fail",
  });

  const [nullIngredientNames] = await sql`
    SELECT count(*)::int AS cnt FROM ingredients WHERE canonical_name_ko IS NULL
  `;
  results.push({
    name: "ingredients.canonical_name_ko NOT NULL",
    count: nullIngredientNames.cnt,
    status: nullIngredientNames.cnt === 0 ? "pass" : "fail",
  });

  const [noSlug] = await sql`
    SELECT count(*)::int AS cnt
    FROM ingredients
    WHERE slug IS NULL AND is_published = true
  `;
  results.push({
    name: "published ingredients have slug",
    count: noSlug.cnt,
    status: noSlug.cnt === 0 ? "pass" : "warn",
  });

  const [orphanProducts] = await sql`
    SELECT count(*)::int AS cnt
    FROM products p
    LEFT JOIN product_ingredients pi ON p.id = pi.product_id
    WHERE pi.id IS NULL
  `;
  results.push({
    name: "products with no ingredients",
    count: orphanProducts.cnt,
    status: orphanProducts.cnt === 0 ? "pass" : "warn",
  });

  const [dupeProducts] = await sql`
    SELECT count(*)::int AS cnt FROM (
      SELECT approval_or_report_no
      FROM products
      WHERE approval_or_report_no IS NOT NULL
      GROUP BY approval_or_report_no
      HAVING count(*) > 1
    ) d
  `;
  results.push({
    name: "no duplicate products (report_no)",
    count: dupeProducts.cnt,
    status: dupeProducts.cnt === 0 ? "pass" : "fail",
  });

  const [dupeIngredients] = await sql`
    SELECT count(*)::int AS cnt FROM (
      SELECT canonical_name_ko
      FROM ingredients
      WHERE canonical_name_ko IS NOT NULL
      GROUP BY canonical_name_ko
      HAVING count(*) > 1
    ) d
  `;
  results.push({
    name: "no duplicate ingredients (canonical_name_ko)",
    count: dupeIngredients.cnt,
    status: dupeIngredients.cnt === 0 ? "pass" : "fail",
  });

  const [dupeProductIngredients] = await sql`
    SELECT count(*)::int AS cnt FROM (
      SELECT product_id, ingredient_id
      FROM product_ingredients
      GROUP BY product_id, ingredient_id
      HAVING count(*) > 1
    ) d
  `;
  results.push({
    name: "no duplicate product_ingredients (product_id, ingredient_id)",
    count: dupeProductIngredients.cnt,
    status: dupeProductIngredients.cnt === 0 ? "pass" : "fail",
  });

  return results;
}

// ============================================================================
// Persistence
// ============================================================================

async function saveVerificationRun(sql, summary, discrepancies) {
  const [run] = await sql`
    INSERT INTO verification_runs (
      run_mode, layers_checked, sample_size,
      total_checked, total_passed, total_warnings, total_failures,
      summary, started_at, finished_at
    ) VALUES (
      ${summary.mode},
      ${summary.layers.join(",")},
      ${summary.size},
      ${summary.totalChecked},
      ${summary.totalPassed},
      ${summary.totalWarnings},
      ${summary.totalFailures},
      ${sql.json(summary.details)},
      ${summary.startedAt},
      NOW()
    )
    RETURNING id
  `;

  if (discrepancies.length > 0) {
    const rows = discrepancies.map((d) => ({
      verification_run_id: run.id,
      layer: d.layer,
      check_name: d.checkName,
      entity_type: d.entityType,
      entity_external_id: d.entityExternalId ?? null,
      entity_db_id: d.entityDbId ?? null,
      discrepancy_type: d.discrepancyType,
      field_name: d.fieldName ?? null,
      source_value: d.sourceValue ?? null,
      db_value: d.dbValue ?? null,
      severity: d.severity ?? "medium",
    }));

    for (let i = 0; i < rows.length; i += 500) {
      const batch = rows.slice(i, i + 500);
      await sql`INSERT INTO verification_discrepancies ${sql(batch)}`;
    }
  }

  return run.id;
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  if (!databaseUrl) {
    console.error("ERROR: DATABASE_URL not set");
    process.exit(1);
  }

  const startedAt = new Date();
  const sql = postgres(databaseUrl, {
    max: 1,
    idle_timeout: 5,
    connect_timeout: 30,
  });

  const totals = { checked: 0, passed: 0, warnings: 0, failures: 0 };
  const details = {};
  const discrepancies = [];

  function tally(status) {
    totals.checked++;
    if (status === "pass") totals.passed++;
    else if (status === "warn") totals.warnings++;
    else totals.failures++;
  }

  try {
    printHeader("Data Integrity Verification Report");
    console.log(
      `  Mode: ${args.mode} | Sample: ${args.size} | Layers: ${args.layers.join(",")}`,
    );
    console.log(`  Date: ${startedAt.toISOString()}\n`);

    // ==========================================================
    // Layer 3: Staging ↔ Core
    // ==========================================================
    if (args.layers.includes(3)) {
      printSection("Layer 3: Staging ↔ Core");

      const counts = await layer3Counts(sql);
      const countChecks = [
        { name: "products", staging: counts.staging_products, core: counts.core_products },
        { name: "ingredients", staging: counts.staging_ingredients, core: counts.core_ingredients },
        { name: "product_ingredients", staging: counts.staging_pi, core: counts.core_pi },
      ];

      console.log("[COUNTS]");
      for (const c of countChecks) {
        const diff = c.core - c.staging;
        const diffStr = diff >= 0 ? `+${diff}` : `${diff}`;
        const status = diff === 0 ? "pass" : "warn";
        console.log(
          `  ${c.name}: staging=${fmt(c.staging)} | core=${fmt(c.core)} | diff=${diffStr}  [${statusIcon(status)}]`,
        );
        tally(status);

        if (diff !== 0) {
          discrepancies.push({
            layer: 3,
            checkName: "count_comparison",
            entityType: c.name,
            discrepancyType: "count_mismatch",
            sourceValue: String(c.staging),
            dbValue: String(c.core),
            severity: Math.abs(diff) > 100 ? "high" : "medium",
          });
        }
      }

      details.layer3Counts = countChecks;

      // Missing products
      if (counts.staging_products > 0) {
        const missing = await layer3MissingProducts(sql, args.size);

        console.log(
          `\n[MISSING IN CORE] staging에 있지만 core에 없는 제품: ${missing.missingInCore.length}건`,
        );
        for (const row of missing.missingInCore.slice(0, 10)) {
          console.log(
            `  - ${row.report_no}: ${row.product_name} (${row.manufacturer_name ?? ""})`,
          );
        }
        if (missing.missingInCore.length > 10) {
          console.log(`  ... 외 ${missing.missingInCore.length - 10}건`);
        }

        tally(missing.missingInCore.length === 0 ? "pass" : "fail");

        for (const row of missing.missingInCore) {
          discrepancies.push({
            layer: 3,
            checkName: "missing_in_core",
            entityType: "product",
            entityExternalId: row.report_no,
            discrepancyType: "missing_in_db",
            sourceValue: row.product_name,
            severity: "high",
          });
        }

        console.log(
          `\n[MISSING IN STAGING] core에만 있는 KR 제품: ${missing.missingInStaging.length}건`,
        );
        for (const row of missing.missingInStaging.slice(0, 10)) {
          console.log(
            `  - ${row.approval_or_report_no}: ${row.product_name}`,
          );
        }
        if (missing.missingInStaging.length > 10) {
          console.log(`  ... 외 ${missing.missingInStaging.length - 10}건`);
        }

        tally(missing.missingInStaging.length === 0 ? "pass" : "warn");
      }

      // Missing ingredients
      if (counts.staging_ingredients > 0) {
        const missing = await layer3MissingIngredients(sql, args.size);

        console.log(
          `\n[MISSING INGREDIENTS IN CORE] ${missing.missingInCore.length}건`,
        );
        for (const row of missing.missingInCore.slice(0, 10)) {
          console.log(
            `  - ${row.canonical_name_ko} (${row.slug ?? "no slug"})`,
          );
        }

        tally(missing.missingInCore.length === 0 ? "pass" : "warn");

        console.log(
          `\n[CORE-ONLY INGREDIENTS] staging에 없는 원료: ${missing.missingInStaging.length}건`,
        );
        for (const row of missing.missingInStaging.slice(0, 10)) {
          console.log(
            `  - ${row.canonical_name_ko} (${row.slug ?? "no slug"})`,
          );
        }

        tally(missing.missingInStaging.length === 0 ? "pass" : "warn");
      }

      // Product field mismatches
      if (counts.staging_products > 0) {
        const productMismatches = await layer3ProductFieldMismatches(
          sql,
          args.size,
        );

        console.log(
          `\n[PRODUCT FIELD MISMATCHES] ${productMismatches.length}건`,
        );
        for (const row of productMismatches.slice(0, 10)) {
          const diffs = [];
          if (row.staging_name !== row.core_name) {
            diffs.push(`name: "${row.staging_name}" → "${row.core_name}"`);
          }
          if (row.staging_manufacturer !== row.core_manufacturer) {
            diffs.push(
              `manufacturer: "${row.staging_manufacturer}" → "${row.core_manufacturer}"`,
            );
          }
          if (row.staging_status !== row.core_status) {
            diffs.push(
              `status: "${row.staging_status}" → "${row.core_status}"`,
            );
          }
          console.log(`  - ${row.report_no}: ${diffs.join(", ")}`);

          discrepancies.push({
            layer: 3,
            checkName: "product_field_mismatch",
            entityType: "product",
            entityExternalId: row.report_no,
            discrepancyType: "field_mismatch",
            fieldName: diffs.map((d) => d.split(":")[0]).join(","),
            sourceValue: row.staging_name,
            dbValue: row.core_name,
            severity: "medium",
          });
        }

        tally(productMismatches.length === 0 ? "pass" : "warn");
      }

      // Ingredient field mismatches
      if (counts.staging_ingredients > 0) {
        const ingredientMismatches = await layer3IngredientFieldMismatches(
          sql,
          args.size,
        );

        console.log(
          `\n[INGREDIENT FIELD MISMATCHES] ${ingredientMismatches.length}건`,
        );
        for (const row of ingredientMismatches.slice(0, 10)) {
          const diffs = [];
          if (row.staging_slug !== row.core_slug) {
            diffs.push(
              `slug: "${row.staging_slug}" → "${row.core_slug}"`,
            );
          }
          if (row.staging_type !== row.core_type) {
            diffs.push(
              `type: "${row.staging_type}" → "${row.core_type}"`,
            );
          }
          if (row.staging_display !== row.core_display) {
            diffs.push(
              `display: "${row.staging_display}" → "${row.core_display}"`,
            );
          }
          console.log(`  - ${row.canonical_name_ko}: ${diffs.join(", ")}`);
        }

        tally(ingredientMismatches.length === 0 ? "pass" : "warn");
      }
    }

    // ==========================================================
    // Layer 2: Raw Documents ↔ Staging
    // ==========================================================
    if (args.layers.includes(2)) {
      printSection("Layer 2: Raw Documents ↔ Staging");

      const rawCounts = await layer2Counts(sql);

      if (rawCounts.length === 0) {
        console.log(
          "  (raw_documents 테이블 비어있음 — Layer 2 건너뜀)",
        );
      } else {
        console.log("[RAW DOCUMENT COUNTS]");
        for (const row of rawCounts) {
          const age = daysAgo(row.last_fetched);
          const ageStr = age !== null ? `${age}일 전` : "N/A";
          const staleThreshold = 30;
          const status =
            age !== null && age <= staleThreshold ? "pass" : "warn";
          console.log(
            `  ${row.entity_type}: unique=${fmt(row.unique_entities)} | rows=${fmt(row.total_rows)} | fetched=${ageStr}  [${statusIcon(status)}]`,
          );
          tally(status);
        }

        const missing = await layer2MissingInStaging(sql, args.size);

        if (missing.missingProducts.length > 0) {
          console.log(
            `\n[RAW→STAGING MISSING] raw에 있지만 staging에 없는 제품: ${missing.missingProducts.length}건`,
          );
          for (const row of missing.missingProducts.slice(0, 10)) {
            console.log(`  - ${row.report_no}`);
          }
          tally("warn");
        } else {
          tally("pass");
        }
      }
    }

    // ==========================================================
    // Layer 1: Source API ↔ DB
    // ==========================================================
    if (args.layers.includes(1)) {
      printSection("Layer 1: Source API ↔ DB");

      if (!foodsafetyKey) {
        console.log(
          "  FOODSAFETY_KOREA_API_KEY 미설정 — API 검증 건너뜀",
        );
        console.log("  env 설정 후 --layer=1 로 실행하세요");
      } else {
        // Count checks
        console.log("[API COUNT CHECKS]");
        const countResults = await layer1CountChecks(sql);

        if (countResults.error) {
          console.log(`  ERROR: ${countResults.error}`);
        } else {
          for (const r of countResults.results) {
            if (r.error) {
              console.log(
                `  ${r.key} (${r.label}): ERROR - ${r.error}`,
              );
              tally("fail");
            } else {
              const diffStr = r.diff >= 0 ? `+${r.diff}` : `${r.diff}`;
              const pct =
                r.apiTotal > 0
                  ? Math.abs(r.diff / r.apiTotal) * 100
                  : 0;
              const status = pct < 1 ? "pass" : pct < 5 ? "warn" : "fail";
              console.log(
                `  ${r.key} (${r.label}): API=${fmt(r.apiTotal)} | DB=${fmt(r.dbCount)} | diff=${diffStr} (${pct.toFixed(1)}%)  [${statusIcon(status)}]`,
              );
              tally(status);

              if (status !== "pass") {
                discrepancies.push({
                  layer: 1,
                  checkName: "api_count_check",
                  entityType: r.entityType,
                  discrepancyType: "count_mismatch",
                  sourceValue: String(r.apiTotal),
                  dbValue: String(r.dbCount),
                  severity: status === "fail" ? "critical" : "high",
                });
              }
            }
          }

          details.layer1Counts = countResults.results;
        }

        // Freshness
        console.log("\n[FRESHNESS]");
        const freshness = await layer1Freshness(sql);

        if (freshness.length === 0) {
          console.log("  (raw_documents 비어있음)");
        } else {
          for (const row of freshness) {
            const age = daysAgo(row.last_fetched);
            const staleThreshold = 30;
            const status =
              age !== null && age <= staleThreshold ? "pass" : "warn";
            const dateStr =
              row.last_fetched
                ? row.last_fetched.toISOString().slice(0, 10)
                : "never";
            console.log(
              `  ${row.connector_name ?? row.entity_type}: last=${dateStr} (${age ?? "?"}일 전) count=${fmt(row.unique_count)}  [${statusIcon(status)}]`,
            );
            tally(status);
          }
        }

        // Sample verification
        console.log(
          `\n[SAMPLE SOURCE VERIFICATION] I0030 제품, ${args.size}건 샘플`,
        );
        const sampleResult = await layer1SampleVerify(sql, args.size);

        if (sampleResult.error) {
          console.log(`  ERROR: ${sampleResult.error}`);
        } else {
          console.log(`  Checked: ${sampleResult.totalChecked}건`);
          console.log(
            `  Matched: ${sampleResult.matched}건 (${sampleResult.matchRate}%)`,
          );
          console.log(`  Mismatched: ${sampleResult.mismatched}건`);

          if (sampleResult.mismatches.length > 0) {
            if (args.verbose) {
              for (const m of sampleResult.mismatches.slice(0, 20)) {
                const issueStr = m.issues
                  .map((i) => `${i.field}:${i.type}`)
                  .join(", ");
                console.log(
                  `  - ${m.extId} (${m.productName ?? "?"}): ${issueStr}`,
                );
              }
              if (sampleResult.mismatches.length > 20) {
                console.log(
                  `  ... 외 ${sampleResult.mismatches.length - 20}건`,
                );
              }
            } else {
              console.log("  (--verbose 로 상세 확인)");
            }

            for (const m of sampleResult.mismatches) {
              for (const issue of m.issues) {
                discrepancies.push({
                  layer: 1,
                  checkName: "sample_source_verify",
                  entityType: "product",
                  entityExternalId: m.extId,
                  discrepancyType: issue.type,
                  fieldName: issue.field,
                  sourceValue: issue.sourceValue,
                  dbValue: issue.dbValue,
                  severity:
                    issue.type === "missing_in_db" ? "high" : "medium",
                });
              }
            }
          }

          const matchRate = parseFloat(sampleResult.matchRate);
          if (isNaN(matchRate)) tally("warn");
          else if (matchRate >= 95) tally("pass");
          else if (matchRate >= 80) tally("warn");
          else tally("fail");

          details.layer1Sample = sampleResult;
        }
      }
    }

    // ==========================================================
    // Internal Integrity
    // ==========================================================
    printSection("Internal Integrity Checks");

    const integrityResults = await checkIntegrity(sql);

    for (const check of integrityResults) {
      const icon = statusIcon(check.status);
      const countStr = check.count > 0 ? ` (${check.count}건)` : "";
      console.log(`  [${icon}] ${check.name}${countStr}`);
      tally(check.status);
    }

    details.integrity = integrityResults;

    // ==========================================================
    // Summary
    // ==========================================================
    printHeader("Summary");
    console.log(`  Total checks : ${totals.checked}`);
    console.log(`  Passed       : ${totals.passed}`);
    console.log(`  Warnings     : ${totals.warnings}`);
    console.log(`  Failures     : ${totals.failures}`);
    console.log(`  Discrepancies: ${discrepancies.length}건`);

    const overallRate =
      totals.checked > 0
        ? ((totals.passed / totals.checked) * 100).toFixed(1)
        : "N/A";
    console.log(`  Pass rate    : ${overallRate}%`);

    // ==========================================================
    // Persist
    // ==========================================================
    if (!args.dryRun) {
      try {
        const [tableCheck] = await sql`
          SELECT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = 'verification_runs'
          ) AS exists
        `;

        if (tableCheck.exists) {
          const runId = await saveVerificationRun(
            sql,
            {
              mode: args.mode,
              layers: args.layers,
              size: args.size,
              startedAt,
              totalChecked: totals.checked,
              totalPassed: totals.passed,
              totalWarnings: totals.warnings,
              totalFailures: totals.failures,
              details,
            },
            discrepancies,
          );
          console.log(
            `\n  Results saved: verification_runs id=${runId}, discrepancies=${discrepancies.length}건`,
          );
        } else {
          console.log(
            "\n  verification_runs 테이블 없음 — db/021_verification_tables.sql 실행 후 재시도",
          );
        }
      } catch (err) {
        console.log(`\n  저장 실패: ${err.message}`);
      }
    } else {
      console.log("\n  (dry-run — 결과 미저장)");
    }
  } finally {
    await sql.end();
  }
}

main().catch((error) => {
  console.error("FATAL:", error.message);
  process.exit(1);
});
