#!/usr/bin/env node

/**
 * check_freshness.mjs
 *
 * refresh_policies + entity_refresh_states를 조회하여
 * stale 데이터를 탐지하고 갱신이 필요한 항목을 리포트한다.
 *
 * Usage:
 *   node scripts/check_freshness.mjs [options]
 *
 * Options:
 *   --warn-only    stale 항목이 있어도 exit 0 (CI용)
 *   --json         JSON 형식 출력
 */

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

const args = {
  warnOnly: process.argv.includes("--warn-only"),
  json: process.argv.includes("--json"),
};

const databaseUrl = process.env.DATABASE_URL;

// ============================================================================
// 갱신 필요 import 스크립트 매핑
// ============================================================================

const refreshCommands = {
  product: "npm run gov:import-core:kr",
  ingredient: "npm run gov:import-core:kr",
  product_ingredient: "npm run gov:import-core:kr",
  claim: "npm run gov:import-claims:kr",
  ingredient_claim: "npm run gov:import-claims:kr",
  dosage_guideline: "npm run gov:import-dosage:kr",
  label_snapshot: "npm run gov:import-labels:kr",
  safety_item: "npm run gov:import-safety:kr",
  evidence_study: "(수동 갱신 필요)",
};

// ============================================================================
// Main
// ============================================================================

async function main() {
  if (!databaseUrl) {
    console.error("ERROR: DATABASE_URL not set");
    process.exit(1);
  }

  const sql = postgres(databaseUrl, {
    max: 1,
    idle_timeout: 5,
    connect_timeout: 30,
  });

  try {
    // refresh_policies와 entity_refresh_states(batch sentinel)를 JOIN
    const rows = await sql`
      SELECT
        rp.entity_type,
        rp.staleness_days,
        rp.refresh_mode,
        rp.change_detection_method,
        ers.last_fetched_at,
        ers.last_changed_at,
        ers.last_refresh_status,
        ers.last_checksum AS records_processed,
        CASE
          WHEN ers.last_fetched_at IS NULL THEN 'never'
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days || ' days')::interval THEN 'stale'
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days * 0.7 || ' days')::interval THEN 'aging'
          ELSE 'fresh'
        END AS freshness,
        CASE
          WHEN ers.last_fetched_at IS NOT NULL
          THEN EXTRACT(DAY FROM NOW() - ers.last_fetched_at)::int
          ELSE NULL
        END AS days_since_fetch
      FROM refresh_policies rp
      LEFT JOIN entity_refresh_states ers
        ON rp.entity_type = ers.entity_type
        AND ers.entity_id = 0
        AND ers.source_connector_id IS NULL
      WHERE rp.is_active = TRUE
      ORDER BY
        CASE
          WHEN ers.last_fetched_at IS NULL THEN 0
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days || ' days')::interval THEN 1
          WHEN ers.last_fetched_at < NOW() - (rp.staleness_days * 0.7 || ' days')::interval THEN 2
          ELSE 3
        END,
        rp.staleness_days ASC
    `;

    if (rows.length === 0) {
      console.log("refresh_policies에 데이터 없음 — db/022_seed_refresh_policies.sql 실행 필요");
      return;
    }

    // JSON 출력
    if (args.json) {
      const result = rows.map((r) => ({
        entityType: r.entity_type,
        freshness: r.freshness,
        daysSinceFetch: r.days_since_fetch,
        stalenessDays: r.staleness_days,
        lastFetchedAt: r.last_fetched_at,
        lastStatus: r.last_refresh_status,
        recordsProcessed: r.records_processed,
        refreshCommand: refreshCommands[r.entity_type] ?? null,
      }));
      console.log(JSON.stringify(result, null, 2));
      await sql.end();

      const hasStale = result.some(
        (r) => r.freshness === "stale" || r.freshness === "never",
      );
      if (hasStale && !args.warnOnly) process.exit(1);
      return;
    }

    // 텍스트 리포트
    console.log("=".repeat(64));
    console.log("  Data Freshness Report");
    console.log("=".repeat(64));
    console.log(`  Date: ${new Date().toISOString()}\n`);

    const statusIcon = {
      fresh: "OK",
      aging: "~~",
      stale: "!!",
      never: "--",
    };

    let staleCount = 0;
    let agingCount = 0;
    let neverCount = 0;
    const staleItems = [];

    for (const row of rows) {
      const icon = statusIcon[row.freshness] ?? "??";
      const ageStr =
        row.days_since_fetch !== null
          ? `${row.days_since_fetch}일 전`
          : "미갱신";

      const threshold = `(${row.staleness_days}일 기준)`;
      const statusStr = row.last_refresh_status
        ? ` [${row.last_refresh_status}]`
        : "";
      const recordsStr = row.records_processed
        ? ` ${row.records_processed}건`
        : "";

      console.log(
        `  [${icon}] ${row.entity_type.padEnd(22)} ${ageStr.padStart(10)} ${threshold}${statusStr}${recordsStr}`,
      );

      if (row.freshness === "stale") {
        staleCount++;
        staleItems.push(row);
      } else if (row.freshness === "aging") {
        agingCount++;
      } else if (row.freshness === "never") {
        neverCount++;
        staleItems.push(row);
      }
    }

    // Summary
    console.log(`\n${"─".repeat(64)}`);
    console.log(
      `  Fresh: ${rows.length - staleCount - agingCount - neverCount} | Aging: ${agingCount} | Stale: ${staleCount} | Never fetched: ${neverCount}`,
    );

    // 갱신 권장 명령어
    if (staleItems.length > 0) {
      console.log(`\n--- 갱신 필요 ---\n`);

      const commands = new Set();
      for (const item of staleItems) {
        const cmd = refreshCommands[item.entity_type];
        if (cmd) commands.add(cmd);
      }

      for (const cmd of commands) {
        const types = staleItems
          .filter((i) => refreshCommands[i.entity_type] === cmd)
          .map((i) => i.entity_type)
          .join(", ");
        console.log(`  ${cmd}`);
        console.log(`    → ${types}\n`);
      }
    }

    await sql.end();

    if (staleItems.length > 0 && !args.warnOnly) {
      process.exit(1);
    }
  } catch (err) {
    await sql.end();
    throw err;
  }
}

main().catch((error) => {
  console.error("FATAL:", error.message);
  process.exit(1);
});
