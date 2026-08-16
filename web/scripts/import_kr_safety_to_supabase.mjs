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
  const inputPath = path.join(rootDir, "tmp", "kr-gov-clean", "ingredient_profiles.normalized.jsonl");
  if (!existsSync(inputPath)) throw new Error(`Missing input file: ${inputPath}`);

  const supabase = getServiceRoleClient();

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
