#!/usr/bin/env node

import { createReadStream, createWriteStream, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";

const rootDir = process.cwd();
const cleanDir = path.join(rootDir, "tmp", "kr-gov-clean");
const mappedDir = path.join(cleanDir, "mapped");
const stagingDir = path.join(cleanDir, "staging");

const requiredFiles = {
  normalizedProducts: path.join(cleanDir, "products.normalized.jsonl"),
  ingredientProfiles: path.join(cleanDir, "ingredient_profiles.normalized.jsonl"),
  ingredientCatalog: path.join(mappedDir, "ingredient_catalog.merged.jsonl"),
  productIngredientsStaging: path.join(stagingDir, "product_ingredients.staging.jsonl"),
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

function splitOutsideParens(value) {
  const source = cleanText(value);
  if (!source) {
    return [];
  }

  const items = [];
  let buffer = "";
  let depth = 0;

  for (const char of source) {
    if (char === "(" || char === "[") {
      depth += 1;
      buffer += char;
      continue;
    }

    if ((char === ")" || char === "]") && depth > 0) {
      depth -= 1;
      buffer += char;
      continue;
    }

    if ((char === "," || char === ";" || char === "\n") && depth === 0) {
      const item = cleanInlineText(buffer);
      if (item) {
        items.push(item);
      }
      buffer = "";
      continue;
    }

    buffer += char;
  }

  const tail = cleanInlineText(buffer);
  if (tail) {
    items.push(tail);
  }

  return items;
}

function normalizeKey(value) {
  const text = cleanInlineText(value);
  if (!text) {
    return null;
  }

  return text.toLowerCase().replace(/[^a-z0-9가-힣]/g, "");
}

function parseSqlString(value) {
  return value.replace(/''/g, "'");
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

function extractIngredientBlocks(text) {
  return [...text.matchAll(/INSERT INTO ingredients[\s\S]*?VALUES([\s\S]*?);/g)].map(
    (match) => match[1],
  );
}

function parseSeedIngredients() {
  const files = [
    path.join(rootDir, "db", "003_seed_data.sql"),
    path.join(rootDir, "db", "005_seed_supplementary.sql"),
    path.join(rootDir, "db", "008_seed_products_additional.sql"),
  ];

  const metadata = new Map();

  for (const filePath of files) {
    const text = readFileSync(filePath, "utf8");

    for (const block of extractIngredientBlocks(text)) {
      const regex =
        /\('((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*(NULL|'(?:[^']|'')*')/g;

      for (const match of block.matchAll(regex)) {
        const canonicalNameKo = parseSqlString(match[1]);
        const key = normalizeKey(canonicalNameKo);
        if (!key) {
          continue;
        }

        metadata.set(key, {
          canonicalNameKo,
          canonicalNameEn: parseSqlString(match[2]) || null,
          displayName: parseSqlString(match[3]) || null,
          scientificName: parseSqlString(match[4]) || null,
          slug: parseSqlString(match[5]) || null,
          ingredientType: parseSqlString(match[6]) || null,
          description: parseSqlString(match[7]) || null,
          originType: parseSqlString(match[8]) || null,
          formDescription: parseSqlString(match[9]) || null,
          standardizationInfo:
            match[10] === "NULL" ? null : parseSqlString(match[10].slice(1, -1)),
        });
      }
    }
  }

  return metadata;
}

function inferIngredientType(name) {
  const text = cleanInlineText(name) ?? "";
  if (!text) {
    return "other";
  }

  if (text.includes("비타민")) {
    return "vitamin";
  }
  if (["칼슘", "마그네슘", "아연", "철", "셀레늄", "크롬"].some((term) => text.includes(term))) {
    return "mineral";
  }
  if (text.includes("유산균") || text.includes("프로바이오틱스") || /lactobacillus|bifidobacterium|lacticaseibacillus|lactiplantibacillus/i.test(text)) {
    return "probiotic";
  }
  if (text.includes("오메가") || text.includes("DHA") || text.includes("EPA")) {
    return "fatty_acid";
  }
  if (["크레아틴", "글루코사민", "콜라겐", "L-아르지닌", "L-시스틴", "타우린"].some((term) => text.includes(term))) {
    return "amino_acid";
  }
  if (["홍삼", "가르시니아", "밀크씨슬", "녹차", "마리골드", "프로폴리스", "알로에", "쏘팔메토", "헛개", "결명자", "마카"].some((term) => text.includes(term))) {
    return "herbal";
  }
  return "other";
}

function isClearlyProbioticStrainName(name) {
  const text = cleanInlineText(name) ?? "";
  if (!text) {
    return false;
  }

  const latinSpeciesPattern =
    /(lactobacillus|lacticaseibacillus|lactiplantibacillus|limosilactobacillus|bifidobacterium|bacillus|saccharomyces|streptococcus|enterococcus)\s+[a-z][a-z-]+/i;
  const abbreviatedGenusPattern = /\b[LBSE]\.\s*[a-z][a-z-]+/;
  const strainCodePattern = /\b[A-Z]{1,6}[- ]?\d{1,5}[A-Z0-9-]*\b/;
  const koreanSpeciesPattern =
    /(플란타룸|람노서스|카제이|파라카세이|애시도필루스|가세리|로이테리|살리바리우스|헬베티쿠스|락티스|비피덤|브레베|롱검|인판티스|코아귤란스)/;

  return (
    latinSpeciesPattern.test(text) ||
    abbreviatedGenusPattern.test(text) ||
    strainCodePattern.test(text) ||
    koreanSpeciesPattern.test(text)
  );
}

function inferParentIngredientSlug(name, ingredientType, slug) {
  if (slug === "probiotics" || ingredientType !== "probiotic") {
    return null;
  }

  const text = cleanInlineText(name) ?? "";
  if (!text) {
    return null;
  }

  if (text === "프로바이오틱스") {
    return null;
  }

  if (isClearlyProbioticStrainName(text)) {
    return "probiotics";
  }

  if ((text.includes("프로바이오틱스") || text.includes("유산균")) && /[A-Za-z]/.test(text)) {
    return "probiotics";
  }

  return null;
}

function normalizeNameToken(value) {
  const text = cleanInlineText(value);
  if (!text) {
    return null;
  }

  return text.toLowerCase().replace(/[^a-z0-9가-힣]/g, "");
}

function probioticTokenVariants(value) {
  const normalized = normalizeNameToken(value);
  if (!normalized) {
    return [];
  }

  const stripped = normalized
    .replace(/프로바이오틱스|프로바이오틱|유산균/g, "")
    .replace(/probiotics|probiotic/g, "");

  return [...new Set([normalized, stripped].filter((token) => token && token.length >= 4))];
}

function isSimilarToken(left, right) {
  if (!left || !right) {
    return false;
  }

  if (left === right) {
    return true;
  }

  if (left.length < 6 || right.length < 6) {
    return false;
  }

  return left.includes(right) || right.includes(left);
}

function getOrderedProductNameCandidates(row) {
  const candidates = row.productNameCandidates ?? {};
  const preferredKeys = ["data-go-15056760", "foodsafety-c003", "foodsafety-i0030"];

  return preferredKeys
    .map((key) => ({
      source: key,
      value: cleanInlineText(candidates[key]),
    }))
    .filter((candidate) => candidate.value);
}

function resolveProbioticProductPresentation(row, stats) {
  const canonicalNames = [...(stats?.canonicalNames ?? new Set())].map((name) => cleanInlineText(name)).filter(Boolean);
  const canonicalTokens = canonicalNames.flatMap((name) => probioticTokenVariants(name));
  const rawMaterialNames = [
    row.rawPrimaryMaterialName,
    row.rawIndividualMaterialName,
  ]
    .flatMap((value) => splitOutsideParens(value))
    .map((name) => cleanInlineText(name))
    .filter(Boolean);
  const rawMaterialTokens = rawMaterialNames.flatMap((name) => probioticTokenVariants(name));
  const currentProductName = cleanInlineText(row.productName);

  const isSingleActiveProbiotic =
    (stats?.activeIngredientRows ?? 0) <= 1 &&
    (stats?.stagingCanonicalIngredientCount ?? 0) <= 1 &&
    canonicalNames.length === 1 &&
    inferIngredientType(canonicalNames[0]) === "probiotic";

  if (!isSingleActiveProbiotic) {
    return {
      productName: currentProductName,
      productNameSource: "default",
      productNameResolution: "kept_original",
      isIngredientLikeProduct: false,
      isPublished: true,
    };
  }

  const ingredientLikeName = (name) => {
    const tokens = probioticTokenVariants(name);
    if (tokens.length === 0) {
      return false;
    }

    return tokens.some((token) =>
      [...canonicalTokens, ...rawMaterialTokens].some((baseToken) =>
        isSimilarToken(token, baseToken),
      ),
    );
  };

  const hasDistinctCurrentName = currentProductName && !ingredientLikeName(currentProductName);
  if (hasDistinctCurrentName) {
    return {
      productName: currentProductName,
      productNameSource: "normalized_default",
      productNameResolution: "kept_distinct_product_name",
      isIngredientLikeProduct: false,
      isPublished: true,
    };
  }

  const candidate = getOrderedProductNameCandidates(row).find(
    (entry) => entry.value && !ingredientLikeName(entry.value),
  );

  if (candidate) {
    return {
      productName: candidate.value,
      productNameSource: candidate.source,
      productNameResolution: "preferred_distinct_source_name",
      isIngredientLikeProduct: false,
      isPublished: true,
    };
  }

  return {
    productName: currentProductName ?? canonicalNames[0] ?? rawMaterialNames[0] ?? null,
    productNameSource: "ingredient_like_fallback",
    productNameResolution: "suppressed_probiotic_ingredient_like_product",
    isIngredientLikeProduct: true,
    isPublished: false,
  };
}

const seedIngredients = parseSeedIngredients();

const catalogByName = new Map();
await readJsonl(requiredFiles.ingredientCatalog, (row) => {
  const key = normalizeKey(row.canonicalNameKo);
  if (!key) {
    return;
  }
  catalogByName.set(key, row);
});

const productIngredientStats = new Map();
const ingredientStats = new Map();

await readJsonl(requiredFiles.productIngredientsStaging, (row) => {
  const reportNo = cleanInlineText(row.reportNo);
  const ingredientName = cleanInlineText(row.canonicalNameKo);
  if (!reportNo || !ingredientName) {
    return;
  }

  const productStat =
    productIngredientStats.get(reportNo) ??
    {
      stagingIngredientRows: 0,
      activeIngredientRows: 0,
      supportingIngredientRows: 0,
      capsuleIngredientRows: 0,
      canonicalNames: new Set(),
      maxIngredientConfidence: null,
    };

  productStat.stagingIngredientRows += 1;
  if (row.proposedIngredientRole === "active") {
    productStat.activeIngredientRows += 1;
  } else if (row.proposedIngredientRole === "capsule") {
    productStat.capsuleIngredientRows += 1;
  } else {
    productStat.supportingIngredientRows += 1;
  }
  productStat.canonicalNames.add(ingredientName);
  if (typeof row.maxConfidence === "number") {
    productStat.maxIngredientConfidence =
      productStat.maxIngredientConfidence == null
        ? row.maxConfidence
        : Math.max(productStat.maxIngredientConfidence, row.maxConfidence);
  }
  productIngredientStats.set(reportNo, productStat);

  const ingredientKey = normalizeKey(ingredientName);
  const ingStat =
    ingredientStats.get(ingredientKey) ??
    {
      mappedProductReportNos: new Set(),
      mappedMentionRows: 0,
      activeMentionRows: 0,
      supportingMentionRows: 0,
      capsuleMentionRows: 0,
      maxConfidence: null,
    };

  ingStat.mappedProductReportNos.add(reportNo);
  ingStat.mappedMentionRows += 1;
  if (row.proposedIngredientRole === "active") {
    ingStat.activeMentionRows += 1;
  } else if (row.proposedIngredientRole === "capsule") {
    ingStat.capsuleMentionRows += 1;
  } else {
    ingStat.supportingMentionRows += 1;
  }
  if (typeof row.maxConfidence === "number") {
    ingStat.maxConfidence =
      ingStat.maxConfidence == null
        ? row.maxConfidence
        : Math.max(ingStat.maxConfidence, row.maxConfidence);
  }
  ingredientStats.set(ingredientKey, ingStat);
});

const productRows = [];
await readJsonl(requiredFiles.normalizedProducts, (row) => {
  const reportNo = cleanInlineText(row.reportNo);
  if (!reportNo) {
    return;
  }

  const stats = productIngredientStats.get(reportNo);
  const probioticPresentation = resolveProbioticProductPresentation(row, stats);
  productRows.push({
    reportNo,
    productName: probioticPresentation.productName,
    brandName: cleanInlineText(row.brandName),
    manufacturerName: cleanInlineText(row.manufacturerName),
    distributorName: cleanInlineText(row.distributorName),
    countryCode: cleanInlineText(row.countryCode) ?? "KR",
    productType: "health_functional_food",
    approvalOrReportNo: reportNo,
    status: "active",
    sourceDatasets: (row.sourceDatasets ?? []).slice().sort(),
    functionalityItems: (row.functionalityItems ?? []).slice().sort(),
    directionsText: cleanText(row.directionsText),
    warningText: cleanText(row.warningText),
    storageText: cleanText(row.storageText),
    standardsText: cleanText(row.standardsText),
    shapeName: cleanInlineText(row.shapeName),
    formulationMethod: cleanText(row.formulationMethod),
    packagingMaterialsText: cleanText(row.packagingMaterialsText),
    shelfLifeText: cleanInlineText(row.shelfLifeText),
    reportDate: cleanInlineText(row.reportDate),
    lastUpdatedAt: cleanInlineText(row.lastUpdatedAt),
    registrationDate: cleanInlineText(row.registrationDate),
    rawPrimaryMaterialName: cleanInlineText(row.rawPrimaryMaterialName),
    rawIndividualMaterialName: cleanInlineText(row.rawIndividualMaterialName),
    productNameSource: probioticPresentation.productNameSource,
    productNameResolution: probioticPresentation.productNameResolution,
    isIngredientLikeProduct: probioticPresentation.isIngredientLikeProduct,
    isPublished: probioticPresentation.isPublished,
    stagingIngredientRows: stats?.stagingIngredientRows ?? 0,
    stagingCanonicalIngredientCount: stats?.canonicalNames?.size ?? 0,
    activeIngredientRows: stats?.activeIngredientRows ?? 0,
    supportingIngredientRows: stats?.supportingIngredientRows ?? 0,
    capsuleIngredientRows: stats?.capsuleIngredientRows ?? 0,
    maxIngredientConfidence: stats?.maxIngredientConfidence ?? null,
  });
});

productRows.sort((a, b) => a.reportNo.localeCompare(b.reportNo, "ko"));

const ingredientRows = [];
await readJsonl(requiredFiles.ingredientProfiles, (row) => {
  const key = normalizeKey(row.canonicalNameKo);
  if (!key) {
    return;
  }

  const seedMeta = seedIngredients.get(key) ?? null;
  const catalogMeta = catalogByName.get(key) ?? null;
  const stats = ingredientStats.get(key) ?? null;
  const ingredientType = seedMeta?.ingredientType ?? inferIngredientType(row.canonicalNameKo);
  const ingredientSlug = seedMeta?.slug ?? catalogMeta?.slug ?? null;

  ingredientRows.push({
    ingredientType,
    parentIngredientSlug: inferParentIngredientSlug(
      row.canonicalNameKo,
      ingredientType,
      ingredientSlug,
    ),
    canonicalNameKo: cleanInlineText(row.canonicalNameKo),
    canonicalNameEn: seedMeta?.canonicalNameEn ?? null,
    displayName: seedMeta?.displayName ?? cleanInlineText(row.displayName),
    scientificName: seedMeta?.scientificName ?? null,
    slug: ingredientSlug,
    originType: seedMeta?.originType ?? null,
    formDescription: seedMeta?.formDescription ?? null,
    standardizationInfo: seedMeta?.standardizationInfo ?? null,
    description: seedMeta?.description ?? null,
    aliases: (row.aliases ?? []).slice().sort(),
    sourceDatasets: (row.sourceDatasets ?? []).slice().sort(),
    functionalityItems: (row.functionalityItems ?? []).slice().sort(),
    warningTexts: (row.warningTexts ?? []).slice().sort(),
    dosageGuidelines: row.dosageGuidelines ?? [],
    recognitionNos: (row.recognitionNos ?? []).slice().sort(),
    healthItemGroupCodes: (row.healthItemGroupCodes ?? []).slice().sort(),
    healthItemGroupNames: (row.healthItemGroupNames ?? []).slice().sort(),
    mappedProductCount: stats?.mappedProductReportNos?.size ?? 0,
    mappedMentionRows: stats?.mappedMentionRows ?? 0,
    activeMentionRows: stats?.activeMentionRows ?? 0,
    supportingMentionRows: stats?.supportingMentionRows ?? 0,
    capsuleMentionRows: stats?.capsuleMentionRows ?? 0,
    maxMappedConfidence: stats?.maxConfidence ?? null,
    sourceRecordCount: row.sourceRecordCount ?? 0,
  });
});

ingredientRows.sort((a, b) =>
  a.canonicalNameKo.localeCompare(b.canonicalNameKo, "ko"),
);

const summary = {
  generatedAt: new Date().toISOString(),
  inputFiles: requiredFiles,
  outputDir,
  counts: {
    productsStagingRows: productRows.length,
    publishedProductsStagingRows: productRows.filter((row) => row.isPublished).length,
    suppressedIngredientLikeProducts: productRows.filter((row) => row.isIngredientLikeProduct).length,
    ingredientsStagingRows: ingredientRows.length,
    productsWithMappedIngredients: productRows.filter((row) => row.stagingIngredientRows > 0).length,
    ingredientsWithMappedProducts: ingredientRows.filter((row) => row.mappedProductCount > 0).length,
  },
};

writeJsonl(path.join(outputDir, "products.staging.jsonl"), productRows);
writeJsonl(path.join(outputDir, "ingredients.staging.jsonl"), ingredientRows);
writeFileSync(
  path.join(outputDir, "core_entities.summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
