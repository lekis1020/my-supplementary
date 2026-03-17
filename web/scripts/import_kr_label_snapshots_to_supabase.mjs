#!/usr/bin/env node

import { createReadStream, existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import { execFileSync } from "node:child_process";
import { createClient } from "@supabase/supabase-js";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");
const supabaseTempDir = path.join(rootDir, "supabase", ".temp");

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
    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) continue;

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();
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

function readTempValue(filename) {
  const filePath = path.join(supabaseTempDir, filename);
  if (!existsSync(filePath)) return null;
  return readFileSync(filePath, "utf8").trim() || null;
}

function resolveProjectRef() {
  return process.env.SUPABASE_PROJECT_REF ?? readTempValue("project-ref");
}

function resolveSupabaseUrl(projectRef) {
  const envUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL;
  if (envUrl && !envUrl.includes("placeholder.supabase.co")) return envUrl;
  return projectRef ? `https://${projectRef}.supabase.co` : envUrl ?? null;
}

function resolveServiceRoleKey(projectRef) {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) return process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!projectRef) return null;

  const output = execFileSync(
    "supabase",
    ["projects", "api-keys", "list", "--project-ref", projectRef, "--output", "json"],
    { cwd: rootDir, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  );
  const keys = JSON.parse(output);
  return keys.find((item) => item.id === "service_role")?.api_key ?? null;
}

async function* readJsonl(filePath) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lineReader = readline.createInterface({ input: stream, crlfDelay: Infinity });
  for await (const line of lineReader) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    yield JSON.parse(trimmed);
  }
}

function chunk(array, size) {
  const output = [];
  for (let index = 0; index < array.length; index += size) {
    output.push(array.slice(index, index + size));
  }
  return output;
}

async function fetchAllRows(supabase, tableName, columns, batchSize) {
  const rows = [];
  let from = 0;
  while (true) {
    const to = from + batchSize - 1;
    const { data, error } = await supabase
      .from(tableName)
      .select(columns)
      .order("id", { ascending: true })
      .range(from, to);
    if (error) throw error;
    if (!data || data.length === 0) break;
    rows.push(...data);
    if (data.length < batchSize) break;
    from += batchSize;
  }
  return rows;
}

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
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef);

  if (!supabaseUrl) throw new Error("Missing Supabase URL");
  if (!serviceRoleKey) throw new Error("Missing service role key");

  const inputPath = path.join(rootDir, "tmp", "kr-gov-clean", "staging", "products.staging.jsonl");
  if (!existsSync(inputPath)) throw new Error(`Missing input file: ${inputPath}`);

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

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
          projectRef,
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
        projectRef,
        insertedLabelSnapshots: snapshots.length,
        counts: {
          label_snapshots: count ?? null,
        },
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
