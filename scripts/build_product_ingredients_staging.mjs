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

function ingredientRolePriority(role) {
  if (role === "active") return 3;
  if (role === "supporting") return 2;
  if (role === "capsule") return 1;
  return 0;
}

function normalizeToken(value) {
  const text = cleanInlineText(value);
  if (!text) return null;
  return text.toLowerCase().replace(/[^a-z0-9가-힣]/g, "");
}

function normalizeAmountUnit(unitRaw) {
  const unit = cleanInlineText(unitRaw);
  if (!unit) return null;

  const lowered = unit.toLowerCase();
  if (lowered.includes("억") && lowered.includes("cfu")) return "억 CFU";
  if (lowered.includes("천만") && lowered.includes("cfu")) return "천만 CFU";
  if (lowered.includes("백만") && lowered.includes("cfu")) return "백만 CFU";
  if (lowered.includes("만") && lowered.includes("cfu")) return "만 CFU";
  if (lowered.includes("cfu")) return "CFU";
  if (lowered.includes("mcg") || lowered.includes("μg") || lowered.includes("ug") || lowered.includes("㎍")) {
    return "mcg";
  }
  if (lowered.includes("mg") || lowered.includes("㎎")) return "mg";
  if (lowered === "g" || lowered.endsWith(" g")) return "g";
  if (lowered.includes("iu")) return "IU";
  if (lowered === "l" || lowered.endsWith(" l")) return "L";
  if (lowered.includes("ml")) return "mL";
  return unit;
}

function normalizeAmountForStorage(amountValue, amountUnit) {
  if (amountValue == null || amountUnit == null) {
    return {
      amountValue: amountValue ?? null,
      amountUnit: amountUnit ?? null,
    };
  }

  let normalizedValue = amountValue;
  let normalizedUnit = amountUnit;

  // Convert very large plain CFU values to 억 CFU to keep semantic meaning
  // while fitting DB numeric(12,4) precision.
  if (normalizedUnit === "CFU" && Math.abs(normalizedValue) >= 100000000) {
    normalizedValue = normalizedValue / 100000000;
    normalizedUnit = "억 CFU";
  }

  if (!Number.isFinite(normalizedValue) || Math.abs(normalizedValue) > 99999999.9999) {
    return {
      amountValue: null,
      amountUnit: null,
    };
  }

  if (normalizedValue <= 0) {
    return {
      amountValue: null,
      amountUnit: null,
    };
  }

  return {
    amountValue: Number(normalizedValue.toFixed(4)),
    amountUnit: normalizedUnit,
  };
}

function parseAmountMatches(text) {
  const source = cleanText(text);
  if (!source) return [];

  const pattern =
    /(-?\d{1,3}(?:,\d{3})*(?:\.\d+)?|-?\d+(?:\.\d+)?)\s*(억\s*cfu|천만\s*cfu|백만\s*cfu|만\s*cfu|cfu|mg|㎎|mcg|μg|ug|㎍|g|iu|ml|mL|l|L)/gi;
  const matches = [];
  for (const match of source.matchAll(pattern)) {
    const amountValue = Number((match[1] ?? "").replace(/,/g, ""));
    if (!Number.isFinite(amountValue)) continue;
    const amountUnit = normalizeAmountUnit(match[2]);
    if (!amountUnit) continue;

    matches.push({
      amountValue,
      amountUnit,
      snippet: source,
    });
  }

  return matches;
}

function splitCandidateSegments(text) {
  const source = cleanText(text);
  if (!source) return [];
  return source
    .split(/\n|;/g)
    .map((segment) => cleanInlineText(segment))
    .filter(Boolean);
}

function isDailyContext(text) {
  const source = cleanInlineText(text)?.toLowerCase() ?? "";
  if (!source) return false;
  return /(1일|일일|하루|day|섭취량당|일일기준치)/.test(source);
}

function extractIngredientAmounts({ product, row }) {
  const nameTokens = [
    normalizeToken(row.canonicalNameKo),
    normalizeToken(row.rawLabelName),
    ...(row.matchedVariants ?? []).map((item) => normalizeToken(item)),
  ].filter(Boolean);

  const candidates = [
    { text: row.rawLabelName, source: "raw_label_name" },
    { text: (row.matchedVariants ?? []).join("\n"), source: "matched_variants" },
    { text: product?.rawPrimaryMaterialName, source: "raw_primary_material_name" },
    { text: product?.rawIndividualMaterialName, source: "raw_individual_material_name" },
    { text: product?.standardsText, source: "standards_text" },
  ];

  const scopedMatches = [];
  for (const candidate of candidates) {
    const segments = splitCandidateSegments(candidate.text);
    for (const segment of segments) {
      const normalizedSegment = normalizeToken(segment);
      if (
        nameTokens.length > 0 &&
        normalizedSegment &&
        !nameTokens.some((token) => normalizedSegment.includes(token))
      ) {
        continue;
      }

      for (const match of parseAmountMatches(segment)) {
        scopedMatches.push({
          ...match,
          source: candidate.source,
          isDaily: isDailyContext(segment),
        });
      }
    }
  }

  if (scopedMatches.length === 0) {
    return {
      amountPerServing: null,
      amountUnit: null,
      dailyAmount: null,
      dailyAmountUnit: null,
      amountSource: null,
    };
  }

  const servingCandidate = scopedMatches.find((item) => !item.isDaily) ?? null;
  const dailyCandidate = scopedMatches.find((item) => item.isDaily) ?? null;
  const fallback = scopedMatches[0] ?? null;

  const servingRawValue = servingCandidate?.amountValue ?? fallback?.amountValue ?? null;
  const servingRawUnit = servingCandidate?.amountUnit ?? fallback?.amountUnit ?? null;
  const dailyRawValue = dailyCandidate?.amountValue ?? null;
  const dailyRawUnit = dailyCandidate?.amountUnit ?? null;

  const servingNormalized = normalizeAmountForStorage(servingRawValue, servingRawUnit);
  const dailyNormalized = normalizeAmountForStorage(dailyRawValue, dailyRawUnit);

  return {
    amountPerServing: servingNormalized.amountValue,
    amountUnit: servingNormalized.amountUnit,
    dailyAmount: dailyNormalized.amountValue,
    dailyAmountUnit: dailyNormalized.amountUnit,
    amountSource: servingNormalized.amountValue != null
      ? (servingCandidate?.source ?? fallback?.source ?? null)
      : dailyNormalized.amountValue != null
        ? dailyCandidate?.source ?? null
        : null,
  };
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
    const proposedRole = toProposedIngredientRole(row.ingredientRole);
    const signature = [
      reportNo,
      canonicalNameKo,
      cleanInlineText(row.canonicalSlug) ?? "",
      rawLabelName ?? "",
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
        proposedIngredientRole: proposedRole,
        minOrderHint: Number.isFinite(row.orderHint) ? row.orderHint : null,
        maxConfidence: typeof row.confidence === "number" ? row.confidence : null,
        matchedVariants: [],
        matchStrategies: [],
        promotionReasons: [],
        amountPerServing: null,
        amountUnit: null,
        dailyAmount: null,
        dailyAmountUnit: null,
        amountSource: null,
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

    if (
      ingredientRolePriority(proposedRole) >
      ingredientRolePriority(existing.proposedIngredientRole)
    ) {
      existing.proposedIngredientRole = proposedRole;
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

    const extractedAmounts = extractIngredientAmounts({ product, row: existing });
    if (existing.amountPerServing == null && extractedAmounts.amountPerServing != null) {
      existing.amountPerServing = extractedAmounts.amountPerServing;
      existing.amountUnit = extractedAmounts.amountUnit;
      existing.amountSource = extractedAmounts.amountSource;
    }
    if (existing.dailyAmount == null && extractedAmounts.dailyAmount != null) {
      existing.dailyAmount = extractedAmounts.dailyAmount;
      existing.dailyAmountUnit = extractedAmounts.dailyAmountUnit;
      if (!existing.amountSource) {
        existing.amountSource = extractedAmounts.amountSource;
      }
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
    rowsWithAmountPerServing: stagingRows.filter((row) => row.amountPerServing != null).length,
    rowsWithDailyAmount: stagingRows.filter((row) => row.dailyAmount != null).length,
  },
};

writeJsonl(path.join(outputDir, "product_ingredients.staging.jsonl"), stagingRows);
writeFileSync(
  path.join(outputDir, "product_ingredients.summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
