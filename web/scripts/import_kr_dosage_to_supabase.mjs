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

function normalizeDoseUnit(unit) {
  const cleaned = cleanText(unit).replace(/\/(일|day)$/i, "");
  if (!cleaned) return null;
  return cleaned;
}

function normalizeFrequency(unitOrText) {
  const cleaned = cleanText(unitOrText);
  if (/\/(일|day)$/i.test(cleaned)) return "1일";
  if (/(^| )1일( |$)/.test(cleaned)) return "1일";
  return "1일";
}

function parseNumber(value) {
  if (value == null || value === "") return null;
  const normalized = String(value).replace(/,/g, "");
  const number = Number(normalized);
  return Number.isFinite(number) ? number : null;
}

function parseDoseText(doseText) {
  const text = cleanText(doseText);
  if (!text) return null;

  const rangeMatch = text.match(/([0-9][0-9,]*(?:\.[0-9]+)?)\s*[~∼-]\s*([0-9][0-9,]*(?:\.[0-9]+)?)\s*(mg|g|mcg|μg|IU)\s*\/?\s*(일|day)?/i);
  if (rangeMatch) {
    return {
      doseMin: parseNumber(rangeMatch[1]),
      doseMax: parseNumber(rangeMatch[2]),
      doseUnit: normalizeDoseUnit(rangeMatch[3]),
      frequencyText: "1일",
      normalizedText: text,
    };
  }

  const singleMatch = text.match(/([0-9][0-9,]*(?:\.[0-9]+)?)\s*(mg|g|mcg|μg|IU)\s*\/?\s*(일|day)?/i);
  if (singleMatch) {
    const value = parseNumber(singleMatch[1]);
    return {
      doseMin: value,
      doseMax: value,
      doseUnit: normalizeDoseUnit(singleMatch[2]),
      frequencyText: "1일",
      normalizedText: text,
    };
  }

  return {
    doseMin: null,
    doseMax: null,
    doseUnit: null,
    frequencyText: null,
    normalizedText: text,
  };
}

function buildGuidelineRecords(profile) {
  const dosageGuidelines = profile.dosageGuidelines ?? [];
  const recognitionNo = profile.recognitionNos?.[0] ?? null;

  return dosageGuidelines.map((entry, index) => {
    let doseMin = parseNumber(entry.doseMin);
    let doseMax = parseNumber(entry.doseMax);
    let doseUnit = entry.doseUnit ? normalizeDoseUnit(entry.doseUnit) : null;
    let frequencyText = entry.doseUnit ? normalizeFrequency(entry.doseUnit) : null;
    let rawDoseText = entry.doseText ? cleanText(entry.doseText) : null;

    if (rawDoseText) {
      const parsed = parseDoseText(rawDoseText);
      doseMin ??= parsed?.doseMin ?? null;
      doseMax ??= parsed?.doseMax ?? null;
      doseUnit ??= parsed?.doseUnit ?? null;
      frequencyText ??= parsed?.frequencyText ?? null;
    }

    if (doseMin == null && doseMax == null && !rawDoseText) {
      return null;
    }

    return {
      sourceDataset: entry.sourceDataset ?? profile.sourceDatasets?.[0] ?? "foodsafety-unknown",
      populationGroup: "일반 성인",
      indicationContext: "건강기능식품 일일섭취량",
      doseMin,
      doseMax,
      doseUnit,
      frequencyText: frequencyText ?? "1일",
      route: "oral",
      recommendationType: "regulatory_daily_intake",
      notes: [entry.notes, rawDoseText, recognitionNo].filter(Boolean).join(" | "),
      sequence: index + 1,
    };
  }).filter(Boolean);
}

function dedupeGuidelines(rows) {
  return Array.from(
    rows.reduce((map, row) => {
      const key = [
        row.ingredientId,
        row.populationGroup,
        row.indicationContext,
        row.doseMin ?? "",
        row.doseMax ?? "",
        row.doseUnit ?? "",
        row.frequencyText ?? "",
        row.recommendationType ?? "",
        row.route ?? "",
      ].join("|");

      const current = map.get(key);
      if (!current) {
        map.set(key, row);
        return map;
      }

      if (row.notes && current.notes && row.notes !== current.notes && !current.notes.includes(row.notes)) {
        current.notes = `${current.notes}\n${row.notes}`;
      } else if (!current.notes) {
        current.notes = row.notes;
      }

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

  const guidelineRows = [];
  let profileCount = 0;
  for await (const profile of readJsonl(inputPath)) {
    profileCount += 1;
    const ingredientId = ingredientIdByName.get(profile.canonicalNameKo);
    if (!ingredientId) continue;
    const rows = buildGuidelineRecords(profile).map((row) => ({
      ingredientId,
      ...row,
    }));
    guidelineRows.push(...rows);
  }

  const dedupedRows = dedupeGuidelines(guidelineRows);

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          projectRef,
          profileCount,
          rawGuidelineRows: guidelineRows.length,
          dedupedGuidelineRows: dedupedRows.length,
          examples: dedupedRows.slice(0, 10),
        },
        null,
        2,
      ),
    );
    return;
  }

  const { error: deleteError } = await supabase.from("dosage_guidelines").delete().gt("id", 0);
  if (deleteError) throw deleteError;

  for (const batch of chunk(dedupedRows, args.batchSize)) {
    const payload = batch.map((row) => ({
      ingredient_id: row.ingredientId,
      population_group: row.populationGroup,
      indication_context: row.indicationContext,
      dose_min: row.doseMin,
      dose_max: row.doseMax,
      dose_unit: row.doseUnit,
      frequency_text: row.frequencyText,
      route: row.route,
      recommendation_type: row.recommendationType,
      notes: row.notes,
      source_id: null,
    }));

    const { error } = await supabase.from("dosage_guidelines").insert(payload);
    if (error) throw error;
  }

  const { count, error: countError } = await supabase
    .from("dosage_guidelines")
    .select("id", { count: "exact", head: true });
  if (countError) throw countError;

  console.log(
    JSON.stringify(
      {
        projectRef,
        insertedDosageGuidelines: dedupedRows.length,
        counts: {
          dosage_guidelines: count ?? null,
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
