#!/usr/bin/env node

import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readJsonl, createJsonlWriter } from "./lib/jsonl.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..", "..");
const mappedDir = path.join(rootDir, "tmp", "kr-gov-clean", "mapped");
const classifiedDir = path.join(mappedDir, "classified");

const baseMappingFile = path.join(mappedDir, "ingredient_name_mapping.normalized.jsonl");
const mentionFile = path.join(rootDir, "tmp", "kr-gov-clean", "product_ingredient_mentions.normalized.jsonl");
const classifiedFile = path.join(classifiedDir, "ingredient_name_unresolved.classified.jsonl");

if (!existsSync(baseMappingFile) || !existsSync(classifiedFile) || !existsSync(mentionFile)) {
  console.error("Required mapped/classified files not found. Run npm run gov:map:kr and npm run gov:classify-mentions:kr first.");
  process.exit(1);
}

const outputDir = path.join(mappedDir, "promoted");
mkdirSync(outputDir, { recursive: true });

function cleanText(value) {
  if (value == null) {
    return null;
  }

  const text = String(value)
    .replace(/\r\n/g, "\n")
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/？/g, "~")
    .replace(/\u00a0/g, " ")
    .split("\n")
    .map((line) => line.replace(/[ \t]+/g, " ").trim())
    .filter(Boolean)
    .join("\n")
    .trim();

  return text || null;
}

function cleanInlineText(value) {
  const text = cleanText(value);
  return text ? text.replace(/\s+/g, " ").trim() : null;
}

async function writeJsonl(filePath, rows) {
  const writer = createJsonlWriter(filePath);
  for (const row of rows) {
    writer.write(row);
  }
  await writer.close();
}

const baseMappings = [];
const mappingIndex = new Map();

for await (const row of readJsonl(baseMappingFile)) {
  baseMappings.push(row);
  mappingIndex.set(row.rawLabelName, row);
}

function promoteClassification(row) {
  const candidates = Array.isArray(row.candidateCanonicals)
    ? row.candidateCanonicals.filter((item) => item && item.canonicalNameKo)
    : [];

  if (candidates.length !== 1) {
    return null;
  }

  if (!row.classification || !row.classification.startsWith("active_candidate")) {
    return null;
  }

  const only = candidates[0];
  const role = cleanInlineText(row.exampleRole) ?? "";
  let confidence = 0.82;
  let promotionReason = "single_candidate";

  if (row.classification === "active_candidate_declared_raw_material") {
    confidence = role === "main" || role === "individual" ? 0.96 : 0.9;
    promotionReason = "declared_raw_material_single_candidate";
  } else if (row.classification === "active_candidate_probiotic_strain") {
    confidence = 0.9;
    promotionReason = "probiotic_strain_to_parent";
  } else if (row.classification === "active_candidate_by_alias_hint") {
    confidence = 0.85;
    promotionReason = "alias_hint_single_candidate";
  }

  if (cleanInlineText(row.rawLabelName) === cleanInlineText(only.canonicalNameKo)) {
    confidence = Math.max(confidence, 0.98);
    promotionReason = "exact_name_after_classification";
  }

  return {
    rawLabelName: row.rawLabelName,
    mentionCount: row.mentionCount,
    exampleProductName: row.exampleProductName,
    exampleReportNo: row.exampleReportNo,
    exampleRole: row.exampleRole,
    canonicalNameKo: only.canonicalNameKo,
    canonicalSlug: only.canonicalSlug ?? null,
    matchStrategy: "promoted_active_candidate",
    matchedVariant: only.matchedToken ?? null,
    confidence,
    promotionReason,
    classification: row.classification,
  };
}

const promotedRows = [];
for await (const row of readJsonl(classifiedFile)) {
  const promoted = promoteClassification(row);
  if (!promoted) {
    continue;
  }

  const existing = mappingIndex.get(promoted.rawLabelName);
  if (existing?.canonicalNameKo) {
    continue;
  }

  promotedRows.push(promoted);
  mappingIndex.set(promoted.rawLabelName, promoted);
}

const mergedMappings = baseMappings
  .map((row) => mappingIndex.get(row.rawLabelName) ?? row)
  .concat(
    promotedRows.filter(
      (row) => !baseMappings.some((existing) => existing.rawLabelName === row.rawLabelName),
    ),
  )
  .sort((a, b) => b.mentionCount - a.mentionCount || a.rawLabelName.localeCompare(b.rawLabelName, "ko"));

const promotedIndex = new Map(promotedRows.map((row) => [row.rawLabelName, row]));
const resolvedMentions = [];

for await (const row of readJsonl(mentionFile)) {
  const rawLabelName = cleanInlineText(row.rawLabelName);
  if (!rawLabelName) {
    continue;
  }

  const promoted = promotedIndex.get(rawLabelName);
  if (!promoted) {
    continue;
  }

  resolvedMentions.push({
    ...row,
    canonicalNameKo: promoted.canonicalNameKo,
    canonicalSlug: promoted.canonicalSlug,
    matchStrategy: promoted.matchStrategy,
    matchedVariant: promoted.matchedVariant,
    confidence: promoted.confidence,
    promotionReason: promoted.promotionReason,
  });
}

await writeJsonl(path.join(outputDir, "ingredient_name_mapping.promoted.jsonl"), mergedMappings);
await writeJsonl(path.join(outputDir, "ingredient_name_promoted_only.jsonl"), promotedRows);
await writeJsonl(path.join(outputDir, "product_ingredient_mentions.promoted.jsonl"), resolvedMentions);

const summary = {
  generatedAt: new Date().toISOString(),
  inputFiles: {
    baseMappingFile,
    classifiedFile,
    mentionFile,
  },
  outputDir,
  counts: {
    promotedDistinctNames: promotedRows.length,
    promotedMentionCount: promotedRows.reduce((sum, row) => sum + (row.mentionCount ?? 0), 0),
    promotedResolvedMentionRows: resolvedMentions.length,
  },
};

writeFileSync(
  path.join(outputDir, "summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
