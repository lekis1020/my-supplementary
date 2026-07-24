#!/usr/bin/env node
/**
 * SQL 마이그레이션 파일을 원격 Supabase(DATABASE_URL)에 적용.
 *
 * 사용법:
 *   cd web
 *   node scripts/apply_migration.mjs ../db/041_sale_verification.sql
 *   node scripts/apply_migration.mjs ../db/041_sale_verification.sql --verify-only
 */

import { readFileSync } from "node:fs";
import postgres from "postgres";
import { loadEnv, requireEnv } from "./lib/env.mjs";

const [file, ...flags] = process.argv.slice(2);
const VERIFY_ONLY = flags.includes("--verify-only");

if (!file) {
  console.error("Usage: node scripts/apply_migration.mjs <path-to-sql> [--verify-only]");
  process.exit(1);
}

loadEnv();
requireEnv("DATABASE_URL");

const sql = postgres(process.env.DATABASE_URL, { max: 1, prepare: false });

try {
  if (!VERIFY_ONLY) {
    const ddl = readFileSync(file, "utf8");
    await sql.unsafe(ddl);
    console.log(`Applied: ${file}`);
  }

  // 041 검증 쿼리
  const byChannel = await sql`
    SELECT sale_channel, COUNT(*)::int AS n
    FROM products
    WHERE sale_verified_at IS NOT NULL
    GROUP BY sale_channel
    ORDER BY n DESC
  `;
  console.log("판매 확인 제품 (채널별):", JSON.stringify(byChannel, null, 2));

  const queue = await sql`
    SELECT status, COUNT(*)::int AS n
    FROM product_enrichment_queue
    GROUP BY status
  `;
  console.log("보강 큐:", JSON.stringify(queue, null, 2));
} finally {
  await sql.end();
}
