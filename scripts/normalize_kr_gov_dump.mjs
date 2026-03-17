#!/usr/bin/env node

import {
  createReadStream,
  createWriteStream,
  existsSync,
  mkdirSync,
  writeFileSync,
} from "node:fs";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";

const rootDir = process.cwd();
const inputDir = path.join(rootDir, "tmp", "kr-gov");
const outputDir = path.join(rootDir, "tmp", "kr-gov-clean");

if (!existsSync(inputDir)) {
  console.error(`Input directory not found: ${inputDir}`);
  process.exit(1);
}

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

function uniquePush(list, value) {
  if (!value) {
    return;
  }

  if (!list.includes(value)) {
    list.push(value);
  }
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

function splitFunctionalText(value) {
  const text = cleanText(value);
  if (!text) {
    return [];
  }

  const normalized = text
    .replace(/\[[^\]]+\]/g, " ")
    .replace(/[①②③④⑤⑥⑦⑧⑨⑩]/g, "\n")
    .replace(/\(\d+\)/g, "\n")
    .replace(/[·•]/g, " ")
    .replace(/\n{2,}/g, "\n");

  return normalized
    .split("\n")
    .map((item) => cleanInlineText(item))
    .filter(
      (item) =>
        Boolean(item) &&
        !["(국문)", "(영문)", "국문", "영문"].includes(item),
    );
}

function normalizeNameVariants(rawName) {
  const full = cleanInlineText(rawName);
  if (!full) {
    return {
      canonicalName: null,
      displayName: null,
      aliases: [],
    };
  }

  const parenMatches = [...full.matchAll(/\(([^)]+)\)/g)]
    .map((match) => cleanInlineText(match[1]))
    .filter(Boolean);
  const base = cleanInlineText(full.replace(/\([^)]+\)/g, " "));
  const aliases = [full];

  if (!parenMatches.length) {
    return {
      canonicalName: full,
      displayName: full,
      aliases,
    };
  }

  if (base) {
    uniquePush(aliases, base);
  }

  for (const item of parenMatches) {
    uniquePush(aliases, item);
  }

  return {
    canonicalName: base || full,
    displayName: full,
    aliases,
  };
}

function canonicalKey(name) {
  const { canonicalName } = normalizeNameVariants(name);
  if (!canonicalName) {
    return null;
  }

  return canonicalName.replace(/\s+/g, "").toLowerCase();
}

function parseNumeric(value) {
  if (value == null) {
    return null;
  }

  const text = cleanInlineText(value);
  if (!text) {
    return null;
  }

  const numeric = Number(text);
  return Number.isFinite(numeric) ? numeric : null;
}

async function readJsonl(fileName, onRecord) {
  const filePath = path.join(inputDir, fileName);
  if (!existsSync(filePath)) {
    return;
  }

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

function createProductRecord(reportNo) {
  return {
    reportNo,
    productName: null,
    manufacturerName: null,
    distributorName: null,
    countryCode: "KR",
    sourceDatasets: [],
    sourceRecords: {},
    rawPrimaryMaterialName: null,
    rawIndividualMaterialName: null,
    functionalityTexts: [],
    functionalityItems: [],
    directionsText: null,
    warningText: null,
    storageText: null,
    standardsText: null,
    shapeName: null,
    formulationMethod: null,
    packagingMaterialsText: null,
    shelfLifeText: null,
    reportDate: null,
    lastUpdatedAt: null,
    registrationDate: null,
  };
}

function mergeScalar(target, key, value) {
  if (target[key]) {
    return;
  }
  target[key] = value ?? null;
}

function writeJsonl(filePath, rows) {
  const stream = createWriteStream(filePath, { encoding: "utf8" });
  for (const row of rows) {
    stream.write(`${JSON.stringify(row)}\n`);
  }
  stream.end();
}

const products = new Map();
const ingredientProfiles = new Map();
const ingredientMentions = [];
const regulatoryStandards = [];

function upsertIngredientProfile(rawName, patch) {
  const key = canonicalKey(rawName);
  if (!key) {
    return;
  }

  const variants = normalizeNameVariants(rawName);
  const existing =
    ingredientProfiles.get(key) ??
    {
      canonicalNameKo: variants.canonicalName,
      displayName: variants.displayName,
      aliases: [],
      sourceDatasets: [],
      functionalityTexts: [],
      functionalityItems: [],
      warningTexts: [],
      dosageGuidelines: [],
      recognitionNos: [],
      healthItemGroupCodes: [],
      healthItemGroupNames: [],
      sourceRecordCount: 0,
    };

  uniquePush(existing.aliases, variants.displayName);
  for (const alias of variants.aliases) {
    uniquePush(existing.aliases, alias);
  }

  if (patch.dataset) {
    uniquePush(existing.sourceDatasets, patch.dataset);
  }

  for (const text of patch.functionalityTexts ?? []) {
    uniquePush(existing.functionalityTexts, text);
  }

  for (const item of patch.functionalityItems ?? []) {
    uniquePush(existing.functionalityItems, item);
  }

  for (const text of patch.warningTexts ?? []) {
    uniquePush(existing.warningTexts, text);
  }

  for (const guideline of patch.dosageGuidelines ?? []) {
    const signature = JSON.stringify(guideline);
    if (!existing.dosageGuidelines.some((item) => JSON.stringify(item) === signature)) {
      existing.dosageGuidelines.push(guideline);
    }
  }

  for (const value of patch.recognitionNos ?? []) {
    uniquePush(existing.recognitionNos, value);
  }

  for (const value of patch.healthItemGroupCodes ?? []) {
    uniquePush(existing.healthItemGroupCodes, value);
  }

  for (const value of patch.healthItemGroupNames ?? []) {
    uniquePush(existing.healthItemGroupNames, value);
  }

  existing.sourceRecordCount += 1;
  ingredientProfiles.set(key, existing);
}

await readJsonl("foodsafety-i0030.jsonl", (row) => {
  const reportNo = cleanInlineText(row.PRDLST_REPORT_NO);
  if (!reportNo) {
    return;
  }

  const product = products.get(reportNo) ?? createProductRecord(reportNo);
  uniquePush(product.sourceDatasets, "foodsafety-i0030");
  product.sourceRecords["foodsafety-i0030"] = {
    lastUpdatedAt: cleanInlineText(row.LAST_UPDT_DTM),
  };

  mergeScalar(product, "productName", cleanInlineText(row.PRDLST_NM));
  mergeScalar(product, "manufacturerName", cleanInlineText(row.BSSH_NM));
  mergeScalar(product, "rawPrimaryMaterialName", cleanInlineText(row.RAWMTRL_NM));
  mergeScalar(
    product,
    "rawIndividualMaterialName",
    cleanInlineText(row.INDIV_RAWMTRL_NM),
  );
  mergeScalar(product, "directionsText", cleanText(row.NTK_MTHD));
  mergeScalar(product, "warningText", cleanText(row.IFTKN_ATNT_MATR_CN));
  mergeScalar(product, "storageText", cleanText(row.CSTDY_MTHD));
  mergeScalar(product, "standardsText", cleanText(row.STDR_STND));
  mergeScalar(product, "shapeName", cleanInlineText(row.PRDT_SHAP_CD_NM));
  mergeScalar(product, "formulationMethod", cleanInlineText(row.FRMLC_MTHD));
  mergeScalar(
    product,
    "packagingMaterialsText",
    cleanText(row.FRMLC_MTRQLT),
  );
  mergeScalar(product, "shelfLifeText", cleanInlineText(row.POG_DAYCNT));
  mergeScalar(product, "reportDate", cleanInlineText(row.PRMS_DT));
  mergeScalar(product, "lastUpdatedAt", cleanInlineText(row.LAST_UPDT_DTM));

  const functionalityText = cleanText(row.PRIMARY_FNCLTY);
  if (functionalityText) {
    uniquePush(product.functionalityTexts, functionalityText);
    for (const item of splitFunctionalText(functionalityText)) {
      uniquePush(product.functionalityItems, item);
    }
  }

  const productName = cleanInlineText(row.PRDLST_NM);
  const mentionSources = [
    { role: "main", value: row.RAWMTRL_NM },
    { role: "individual", value: row.INDIV_RAWMTRL_NM },
    { role: "other", value: row.ETC_RAWMTRL_NM },
    { role: "capsule", value: row.CAP_RAWMTRL_NM },
  ];

  for (const source of mentionSources) {
    const items = splitOutsideParens(source.value);
    items.forEach((item, index) => {
      ingredientMentions.push({
        reportNo,
        productName,
        sourceDataset: "foodsafety-i0030",
        ingredientRole: source.role,
        orderHint: index + 1,
        rawLabelName: item,
      });
    });
  }

  products.set(reportNo, product);
});

await readJsonl("foodsafety-c003.jsonl", (row) => {
  const reportNo = cleanInlineText(row.PRDLST_REPORT_NO);
  if (!reportNo) {
    return;
  }

  const product = products.get(reportNo) ?? createProductRecord(reportNo);
  uniquePush(product.sourceDatasets, "foodsafety-c003");
  product.sourceRecords["foodsafety-c003"] = {
    lastUpdatedAt: cleanInlineText(row.LAST_UPDT_DTM),
  };

  mergeScalar(product, "productName", cleanInlineText(row.PRDLST_NM));
  mergeScalar(product, "manufacturerName", cleanInlineText(row.BSSH_NM));
  mergeScalar(product, "rawPrimaryMaterialName", cleanInlineText(row.RAWMTRL_NM));
  mergeScalar(product, "directionsText", cleanText(row.NTK_MTHD));
  mergeScalar(product, "warningText", cleanText(row.IFTKN_ATNT_MATR_CN));
  mergeScalar(product, "storageText", cleanText(row.CSTDY_MTHD));
  mergeScalar(product, "standardsText", cleanText(row.STDR_STND));
  mergeScalar(product, "shapeName", cleanInlineText(row.PRDT_SHAP_CD_NM));
  mergeScalar(product, "reportDate", cleanInlineText(row.PRMS_DT));
  mergeScalar(product, "lastUpdatedAt", cleanInlineText(row.LAST_UPDT_DTM));

  const functionalityText = cleanText(row.PRIMARY_FNCLTY);
  if (functionalityText) {
    uniquePush(product.functionalityTexts, functionalityText);
    for (const item of splitFunctionalText(functionalityText)) {
      uniquePush(product.functionalityItems, item);
    }
  }

  splitOutsideParens(row.RAWMTRL_NM).forEach((item, index) => {
    ingredientMentions.push({
      reportNo,
      productName: cleanInlineText(row.PRDLST_NM),
      sourceDataset: "foodsafety-c003",
      ingredientRole: "formula",
      orderHint: index + 1,
      rawLabelName: item,
    });
  });

  products.set(reportNo, product);
});

await readJsonl("data-go-15056760.jsonl", (row) => {
  const reportNo = cleanInlineText(row.STTEMNT_NO);
  if (!reportNo) {
    return;
  }

  const product = products.get(reportNo) ?? createProductRecord(reportNo);
  uniquePush(product.sourceDatasets, "data-go-15056760");
  product.sourceRecords["data-go-15056760"] = {
    registrationDate: cleanInlineText(row.REGIST_DT),
  };

  mergeScalar(product, "productName", cleanInlineText(row.PRDUCT));
  mergeScalar(product, "manufacturerName", cleanInlineText(row.ENTRPS));
  mergeScalar(product, "registrationDate", cleanInlineText(row.REGIST_DT));

  products.set(reportNo, product);
});

await readJsonl("foodsafety-i2710.jsonl", (row) => {
  const rawName = row.PRDCT_NM;
  upsertIngredientProfile(rawName, {
    dataset: "foodsafety-i2710",
    functionalityTexts: [cleanText(row.PRIMARY_FNCLTY)],
    functionalityItems: splitFunctionalText(row.PRIMARY_FNCLTY),
    warningTexts: [cleanText(row.IFTKN_ATNT_MATR_CN)],
    dosageGuidelines: [
      {
        sourceDataset: "foodsafety-i2710",
        doseMin: parseNumeric(row.DAY_INTK_LOWLIMIT),
        doseMax: parseNumeric(row.DAY_INTK_HIGHLIMIT),
        doseUnit: cleanInlineText(row.INTK_UNIT),
        notes: cleanText(row.INTK_MEMO),
      },
    ],
  });
});

await readJsonl("foodsafety-i0040.jsonl", (row) => {
  const rawName = row.APLC_RAWMTRL_NM;
  upsertIngredientProfile(rawName, {
    dataset: "foodsafety-i0040",
    functionalityTexts: [cleanText(row.FNCLTY_CN)],
    functionalityItems: splitFunctionalText(row.FNCLTY_CN),
    warningTexts: [cleanText(row.IFTKN_ATNT_MATR_CN)],
    dosageGuidelines: [
      {
        sourceDataset: "foodsafety-i0040",
        doseText: cleanText(row.DAY_INTK_CN),
      },
    ],
    recognitionNos: [cleanInlineText(row.HF_FNCLTY_MTRAL_RCOGN_NO)],
  });
});

await readJsonl("foodsafety-i0050.jsonl", (row) => {
  const rawName = row.RAWMTRL_NM || row.HF_FNCLTY_MTRAL_RCOGN_NO;
  upsertIngredientProfile(rawName, {
    dataset: "foodsafety-i0050",
    functionalityTexts: [cleanText(row.PRIMARY_FNCLTY)],
    functionalityItems: splitFunctionalText(row.PRIMARY_FNCLTY),
    warningTexts: [cleanText(row.IFTKN_ATNT_MATR_CN)],
    dosageGuidelines: [
      {
        sourceDataset: "foodsafety-i0050",
        doseMin: parseNumeric(row.DAY_INTK_LOWLIMIT),
        doseMax: parseNumeric(row.DAY_INTK_HIGHLIMIT),
        doseUnit: cleanInlineText(row.WT_UNIT),
      },
    ],
    recognitionNos: [cleanInlineText(row.HF_FNCLTY_MTRAL_RCOGN_NO)],
  });
});

await readJsonl("foodsafety-i0760.jsonl", (row) => {
  upsertIngredientProfile(row.HELT_ITM_GRP_NM, {
    dataset: "foodsafety-i0760",
    healthItemGroupCodes: [cleanInlineText(row.HELT_ITM_GRP_CD)],
    healthItemGroupNames: [cleanInlineText(row.HELT_ITM_GRP_NM)],
  });
});

await readJsonl("foodsafety-i0960.jsonl", (row) => {
  regulatoryStandards.push({
    sourceDataset: "foodsafety-i0960",
    productCode: cleanInlineText(row.PRDLST_CD),
    testNameKo: cleanInlineText(row.PC_KOR_NM),
    minValue: cleanInlineText(row.MNMM_VAL),
    maxValue: cleanInlineText(row.MXMM_VAL),
    unit: cleanInlineText(row.UNIT),
    validStartDate: cleanInlineText(row.VALD_BEGN_DT),
    validEndDate: cleanInlineText(row.VALD_END_DT),
    sourceText: cleanText(row.SORC),
    injuryFlag: cleanInlineText(row.INJRY_YN),
  });
});

const dedupedMentions = [];
const mentionSeen = new Set();
for (const mention of ingredientMentions) {
  const signature = [
    mention.reportNo,
    mention.sourceDataset,
    mention.ingredientRole,
    mention.rawLabelName,
  ].join("::");

  if (mentionSeen.has(signature)) {
    continue;
  }

  mentionSeen.add(signature);
  dedupedMentions.push(mention);
}

const productRows = [...products.values()]
  .map((product) => ({
    ...product,
    functionalityTexts: product.functionalityTexts.sort(),
    functionalityItems: product.functionalityItems.sort(),
    sourceDatasets: product.sourceDatasets.sort(),
  }))
  .sort((a, b) => a.reportNo.localeCompare(b.reportNo));

const ingredientRows = [...ingredientProfiles.values()]
  .map((ingredient) => ({
    ...ingredient,
    aliases: ingredient.aliases.sort(),
    sourceDatasets: ingredient.sourceDatasets.sort(),
    functionalityTexts: ingredient.functionalityTexts.sort(),
    functionalityItems: ingredient.functionalityItems.sort(),
    warningTexts: ingredient.warningTexts.sort(),
    recognitionNos: ingredient.recognitionNos.sort(),
    healthItemGroupCodes: ingredient.healthItemGroupCodes.sort(),
    healthItemGroupNames: ingredient.healthItemGroupNames.sort(),
  }))
  .sort((a, b) => a.canonicalNameKo.localeCompare(b.canonicalNameKo, "ko"));

const regulatoryRows = regulatoryStandards.sort((a, b) => {
  const left = `${a.productCode ?? ""}:${a.testNameKo ?? ""}`;
  const right = `${b.productCode ?? ""}:${b.testNameKo ?? ""}`;
  return left.localeCompare(right, "ko");
});

writeJsonl(path.join(outputDir, "products.normalized.jsonl"), productRows);
writeJsonl(
  path.join(outputDir, "product_ingredient_mentions.normalized.jsonl"),
  dedupedMentions,
);
writeJsonl(
  path.join(outputDir, "ingredient_profiles.normalized.jsonl"),
  ingredientRows,
);
writeJsonl(
  path.join(outputDir, "regulatory_standards.normalized.jsonl"),
  regulatoryRows,
);

const summary = {
  generatedAt: new Date().toISOString(),
  inputDir,
  outputDir,
  counts: {
    products: productRows.length,
    productIngredientMentions: dedupedMentions.length,
    ingredientProfiles: ingredientRows.length,
    regulatoryStandards: regulatoryRows.length,
  },
};

writeFileSync(
  path.join(outputDir, "summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
