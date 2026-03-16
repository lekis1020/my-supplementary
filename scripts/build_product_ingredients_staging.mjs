#!/usr/bin/env node

import { createReadStream, createWriteStream, existsSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";

const rootDir = process.cwd();
const cleanDir = path.join(rootDir, "tmp", "kr-gov-clean");
const mappedDir = path.join(cleanDir, "mapped");
const promotedDir = path.join(mappedDir, "promoted");

const requiredFiles = {
  products: path.join(cleanDir, "products.normalized.jsonl"),
  resolved: path.join(mappedDir, "product_ingredient_mentions.resolved.jsonl"),
  promoted: path.join(promotedDir, "product_ingredient_mentions.promoted.jsonl"),
};

for (const filePath of Object.values(requiredFiles)) {
  if (!existsSync(filePath)) {
    console.error(`Required file not found: ${filePath}`);
    process.exit(1);
  }
}

const outputDir = path.join(cleanDir, "staging");
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

async function readJsonl(filePath, onRecord) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lineReader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  for await (const line of lineReader) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }

    onRecord(JSON.parse(trimmed));
  }
}

function writeJsonl(filePath, rows) {
  const stream = createWriteStream(filePath, { encoding: "utf8" });
  for (const row of rows) {
    stream.write(`${JSON.stringify(row)}\n`);
  }
  stream.end();
}

function toProposedIngredientRole(rawRole) {
  const role = cleanInlineText(rawRole);
  if (role === "main" || role === "individual") {
    return "active";
  }

  if (role === "capsule") {
    return "capsule";
  }

  return "supporting";
}

const productsByReportNo = new Map();

await readJsonl(requiredFiles.products, (row) => {
  productsByReportNo.set(cleanInlineText(row.reportNo), row);
});

const grouped = new Map();
const sourceRows = [
  { filePath: requiredFiles.resolved, sourceKind: "resolved" },
  { filePath: requiredFiles.promoted, sourceKind: "promoted" },
];

for (const source of sourceRows) {
  await readJsonl(source.filePath, (row) => {
    const reportNo = cleanInlineText(row.reportNo);
    const canonicalNameKo = cleanInlineText(row.canonicalNameKo);
    if (!reportNo || !canonicalNameKo) {
      return;
    }

    const rawLabelName = cleanInlineText(row.rawLabelName);
    const signature = [
      reportNo,
      canonicalNameKo,
      cleanInlineText(row.canonicalSlug) ?? "",
      rawLabelName ?? "",
      cleanInlineText(row.ingredientRole) ?? "",
    ].join("::");

    const product = productsByReportNo.get(reportNo) ?? null;
    const existing =
      grouped.get(signature) ??
      {
        reportNo,
        productName: product?.productName ?? cleanInlineText(row.productName),
        manufacturerName: product?.manufacturerName ?? null,
        canonicalNameKo,
        canonicalSlug: cleanInlineText(row.canonicalSlug),
        rawLabelName,
        sourceDatasets: [],
        sourceKinds: [],
        rawIngredientRoles: [],
        proposedIngredientRole: toProposedIngredientRole(row.ingredientRole),
        minOrderHint: Number.isFinite(row.orderHint) ? row.orderHint : null,
        maxConfidence: typeof row.confidence === "number" ? row.confidence : null,
        matchedVariants: [],
        matchStrategies: [],
        promotionReasons: [],
      };

    const sourceDataset = cleanInlineText(row.sourceDataset);
    if (sourceDataset && !existing.sourceDatasets.includes(sourceDataset)) {
      existing.sourceDatasets.push(sourceDataset);
    }
    if (!existing.sourceKinds.includes(source.sourceKind)) {
      existing.sourceKinds.push(source.sourceKind);
    }

    const rawRole = cleanInlineText(row.ingredientRole);
    if (rawRole && !existing.rawIngredientRoles.includes(rawRole)) {
      existing.rawIngredientRoles.push(rawRole);
    }

    const matchedVariant = cleanInlineText(row.matchedVariant);
    if (matchedVariant && !existing.matchedVariants.includes(matchedVariant)) {
      existing.matchedVariants.push(matchedVariant);
    }

    const matchStrategy = cleanInlineText(row.matchStrategy);
    if (matchStrategy && !existing.matchStrategies.includes(matchStrategy)) {
      existing.matchStrategies.push(matchStrategy);
    }

    const promotionReason = cleanInlineText(row.promotionReason);
    if (promotionReason && !existing.promotionReasons.includes(promotionReason)) {
      existing.promotionReasons.push(promotionReason);
    }

    const orderHint = Number.isFinite(row.orderHint) ? row.orderHint : null;
    if (orderHint != null) {
      existing.minOrderHint =
        existing.minOrderHint == null
          ? orderHint
          : Math.min(existing.minOrderHint, orderHint);
    }

    const confidence =
      typeof row.confidence === "number" ? row.confidence : null;
    if (confidence != null) {
      existing.maxConfidence =
        existing.maxConfidence == null
          ? confidence
          : Math.max(existing.maxConfidence, confidence);
    }

    grouped.set(signature, existing);
  });
}

const stagingRows = [...grouped.values()]
  .map((row) => ({
    ...row,
    sourceDatasets: row.sourceDatasets.sort(),
    sourceKinds: row.sourceKinds.sort(),
    rawIngredientRoles: row.rawIngredientRoles.sort(),
    matchedVariants: row.matchedVariants.sort(),
    matchStrategies: row.matchStrategies.sort(),
    promotionReasons: row.promotionReasons.sort(),
  }))
  .sort((a, b) => {
    const left = `${a.reportNo}:${a.minOrderHint ?? 999999}:${a.canonicalNameKo}`;
    const right = `${b.reportNo}:${b.minOrderHint ?? 999999}:${b.canonicalNameKo}`;
    return left.localeCompare(right, "ko");
  });

const productsCovered = new Set(stagingRows.map((row) => row.reportNo)).size;
const ingredientNamesCovered = new Set(
  stagingRows.map((row) => row.canonicalNameKo),
).size;

const summary = {
  generatedAt: new Date().toISOString(),
  inputFiles: requiredFiles,
  outputDir,
  counts: {
    stagingRows: stagingRows.length,
    distinctProductsCovered: productsCovered,
    distinctCanonicalIngredients: ingredientNamesCovered,
    activeRows: stagingRows.filter((row) => row.proposedIngredientRole === "active").length,
    supportingRows: stagingRows.filter((row) => row.proposedIngredientRole === "supporting").length,
    capsuleRows: stagingRows.filter((row) => row.proposedIngredientRole === "capsule").length,
  },
};

writeJsonl(path.join(outputDir, "product_ingredients.staging.jsonl"), stagingRows);
writeFileSync(
  path.join(outputDir, "product_ingredients.summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
