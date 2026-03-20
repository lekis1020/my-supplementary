#!/usr/bin/env node

import { createReadStream, existsSync, readFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import { execFileSync } from "node:child_process";
import { createClient } from "@supabase/supabase-js";
import { trackRefresh } from "./lib/track-refresh.mjs";

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
    .replace(/\r/g, "\n")
    .replace(/\u00A0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\n+/g, "\n")
    .trim();
}

function splitWarnings(text) {
  const normalized = cleanText(text)
    .replace(/\(\d+\)/g, "\n")
    .replace(/\d+\)/g, "\n")
    .replace(/①|②|③|④|⑤/g, "\n");

  return normalized
    .split("\n")
    .map((part) => cleanText(part))
    .filter(Boolean);
}

function inferPopulation(text) {
  const populations = [];
  if (/임산부|수유부|수유기/.test(text)) populations.push("임산부, 수유부");
  if (/영·유아|영유아|어린이/.test(text)) populations.push("영유아, 어린이");
  if (/알레르기/.test(text)) populations.push("알레르기 체질");
  if (/간장|신장|심장 기능|질환/.test(text)) populations.push("특정 질환자");
  return populations.join(", ") || "일반 성인";
}

function inferSafetyType(text) {
  if (/피하는 것이 좋습니다|섭취를 피할 것/.test(text)) return "contraindication";
  if (/이상사례 발생 시|섭취를 중단/.test(text)) return "management";
  if (/알레르기/.test(text)) return "allergy";
  if (/주의/.test(text)) return "caution";
  return "caution";
}

function inferSeverity(text) {
  if (/피하는 것이 좋습니다|섭취를 피할 것/.test(text)) return "severe";
  if (/이상사례 발생 시|전문가와 상담/.test(text)) return "moderate";
  if (/질환|간장|신장|심장 기능/.test(text)) return "moderate";
  return "mild";
}

function inferTitle(text) {
  if (/임산부|수유부|수유기/.test(text)) return "임산부·수유부 섭취 주의";
  if (/영·유아|영유아|어린이/.test(text)) return "영유아·어린이 섭취 주의";
  if (/알레르기/.test(text)) return "알레르기 체질 섭취 주의";
  if (/간장|신장|심장 기능|질환/.test(text)) return "특정 질환자 섭취 주의";
  if (/이상사례 발생 시|섭취를 중단/.test(text)) return "이상사례 발생 시 중단";
  return cleanText(text).slice(0, 60);
}

function inferManagementAdvice(text) {
  if (/이상사례 발생 시|섭취를 중단/.test(text)) return "섭취를 중단하고 전문가와 상담";
  if (/전문가와 상담/.test(text)) return "전문가와 상담";
  if (/알레르기/.test(text)) return "알레르기 이력이 있으면 성분 확인 후 섭취";
  return null;
}

function dedupeSafetyRows(rows) {
  return Array.from(
    rows.reduce((map, row) => {
      const key = `${row.ingredient_id}|${row.title}|${row.description}`;
      if (!map.has(key)) map.set(key, row);
      return map;
    }, new Map()).values(),
  );
}

async function main() {
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef);
  if (!supabaseUrl) throw new Error("Missing Supabase URL");
  if (!serviceRoleKey) throw new Error("Missing service role key");

  const inputPath = path.join(rootDir, "tmp", "kr-gov-clean", "ingredient_profiles.normalized.jsonl");
  if (!existsSync(inputPath)) throw new Error(`Missing input file: ${inputPath}`);

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ingredients = await fetchAllRows(
    supabase,
    "ingredients",
    "id, canonical_name_ko",
    args.batchSize,
  );
  const ingredientIdByName = new Map(
    ingredients
      .filter((row) => row.canonical_name_ko)
      .map((row) => [row.canonical_name_ko, row.id]),
  );

  const safetyRows = [];
  for await (const profile of readJsonl(inputPath)) {
    const ingredientId = ingredientIdByName.get(profile.canonicalNameKo);
    if (!ingredientId) continue;
    for (const warningText of profile.warningTexts ?? []) {
      for (const warningLine of splitWarnings(warningText)) {
        safetyRows.push({
          ingredient_id: ingredientId,
          safety_type: inferSafetyType(warningLine),
          title: inferTitle(warningLine),
          description: warningLine,
          severity_level: inferSeverity(warningLine),
          evidence_level: "regulatory",
          frequency_text: null,
          applies_to_population: inferPopulation(warningLine),
          management_advice: inferManagementAdvice(warningLine),
        });
      }
    }
  }

  const dedupedRows = dedupeSafetyRows(safetyRows);

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          projectRef,
          rawSafetyRows: safetyRows.length,
          dedupedSafetyRows: dedupedRows.length,
          examples: dedupedRows.slice(0, 12),
        },
        null,
        2,
      ),
    );
    return;
  }

  const { error: deleteError } = await supabase
    .from("safety_items")
    .delete()
    .eq("evidence_level", "regulatory");
  if (deleteError) throw deleteError;

  for (const batch of chunk(dedupedRows, args.batchSize)) {
    const { error } = await supabase.from("safety_items").insert(batch);
    if (error) throw error;
  }

  const { count, error: countError } = await supabase
    .from("safety_items")
    .select("id", { count: "exact", head: true });
  if (countError) throw countError;

  console.log(
    JSON.stringify(
      {
        projectRef,
        insertedSafetyItems: dedupedRows.length,
        counts: {
          safety_items: count ?? null,
        },
      },
      null,
      2,
    ),
  );

  await trackRefresh(supabase, { entityType: "safety_item", recordsProcessed: dedupedRows.length });
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
