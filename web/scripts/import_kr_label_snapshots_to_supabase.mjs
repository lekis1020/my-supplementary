#!/usr/bin/env node

import { existsSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import { trackRefresh } from "./lib/track-refresh.mjs";
import { loadEnv } from "./lib/env.mjs";
import { getServiceRoleClient, fetchAllRows } from "./lib/supabase.mjs";
import { chunk } from "./lib/batch.mjs";
import { readJsonl } from "./lib/jsonl.mjs";

loadEnv();

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");

function parseArgs(argv) {
  const args = {
    dryRun: false,
    batchSize: 500,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }
    if (token.startsWith("--batch-size=")) {
      args.batchSize = Number(token.split("=")[1]);
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));

function cleanText(value) {
  return String(value ?? "")
    .replace(/\s+/g, " ")
    .replace(/\u00A0/g, " ")
    .trim();
}

function parseDateYYYYMMDD(value) {
  const text = cleanText(value);
  if (!/^\d{8}$/.test(text)) return null;
  return `${text.slice(0, 4)}-${text.slice(4, 6)}-${text.slice(6, 8)}`;
}

function buildRawLabelText(row) {
  const parts = [
    row.directionsText ? `섭취 방법: ${cleanText(row.directionsText)}` : null,
    row.warningText ? `주의 사항: ${cleanText(row.warningText)}` : null,
    row.storageText ? `보관 방법: ${cleanText(row.storageText)}` : null,
    row.standardsText ? `기준 규격: ${cleanText(row.standardsText)}` : null,
  ].filter(Boolean);

  return parts.length > 0 ? parts.join("\n") : null;
}

async function main() {
  const inputPath = path.join(rootDir, "tmp", "kr-gov-clean", "staging", "products.staging.jsonl");
  if (!existsSync(inputPath)) throw new Error(`Missing input file: ${inputPath}`);

  const supabase = getServiceRoleClient();

  const products = await fetchAllRows(
    supabase,
    "products",
    "id, approval_or_report_no",
    args.batchSize,
  );
  const productIdByReportNo = new Map(
    products
      .filter((row) => row.approval_or_report_no)
      .map((row) => [row.approval_or_report_no, row.id]),
  );

  const snapshots = [];
  for await (const row of readJsonl(inputPath)) {
    const productId = productIdByReportNo.get(row.reportNo);
    if (!productId) continue;

    const directionsText = cleanText(row.directionsText);
    const warningText = cleanText(row.warningText);
    const storageText = cleanText(row.storageText);
    const rawLabelText = buildRawLabelText(row);

    if (!directionsText && !warningText && !storageText && !rawLabelText) continue;

    snapshots.push({
      product_id: productId,
      label_version: "kr-gov-v1",
      source_name: "KR Government API",
      source_url: null,
      serving_size_text: null,
      servings_per_container: null,
      warning_text: warningText || null,
      storage_text: storageText || null,
      directions_text: directionsText || null,
      raw_label_text: rawLabelText,
      captured_at: null,
      effective_date: parseDateYYYYMMDD(row.reportDate),
      is_current: true,
    });
  }

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          snapshotCount: snapshots.length,
          examples: snapshots.slice(0, 10),
        },
        null,
        2,
      ),
    );
    return;
  }

  const { error: deleteError } = await supabase.from("label_snapshots").delete().gt("id", 0);
  if (deleteError) throw deleteError;

  for (const batch of chunk(snapshots, args.batchSize)) {
    const { error } = await supabase.from("label_snapshots").insert(batch);
    if (error) throw error;
  }

  const { count, error: countError } = await supabase
    .from("label_snapshots")
    .select("id", { count: "exact", head: true });
  if (countError) throw countError;

  console.log(
    JSON.stringify(
      {
        insertedLabelSnapshots: snapshots.length,
        counts: {
          label_snapshots: count ?? null,
        },
      },
      null,
      2,
    ),
  );

  await trackRefresh(supabase, { entityType: "label_snapshot", recordsProcessed: snapshots.length });
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
