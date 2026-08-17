#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readJsonl, createJsonlWriter } from "./lib/jsonl.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..", "..");
const cleanDir = path.join(rootDir, "tmp", "kr-gov-clean");
const mentionFile = path.join(cleanDir, "product_ingredient_mentions.normalized.jsonl");
const profileFile = path.join(cleanDir, "ingredient_profiles.normalized.jsonl");

if (!existsSync(mentionFile) || !existsSync(profileFile)) {
  console.error("Normalized KR government files not found. Run npm run gov:normalize:kr first.");
  process.exit(1);
}

const outputDir = path.join(cleanDir, "mapped");
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

function normalizeKey(value) {
  const text = cleanInlineText(value);
  if (!text) {
    return null;
  }

  return text.toLowerCase().replace(/[^a-z0-9가-힣]/g, "");
}

function uniquePush(list, value) {
  if (!value) {
    return;
  }
  if (!list.includes(value)) {
    list.push(value);
  }
}

function parseSqlString(value) {
  return value.replace(/''/g, "'");
}

function extractIngredientBlocks(text) {
  return [...text.matchAll(/INSERT INTO ingredients[\s\S]*?VALUES([\s\S]*?);/g)].map(
    (match) => match[1],
  );
}

function extractSynonymBlocks(text) {
  return [...text.matchAll(/INSERT INTO ingredient_synonyms[\s\S]*?VALUES([\s\S]*?);/g)].map(
    (match) => match[1],
  );
}

function parseSeedCatalog() {
  const files = [
    path.join(rootDir, "db", "003_seed_data.sql"),
    path.join(rootDir, "db", "005_seed_supplementary.sql"),
    path.join(rootDir, "db", "008_seed_products_additional.sql"),
  ];

  const seedEntries = new Map();

  for (const filePath of files) {
    const text = readFileSync(filePath, "utf8");

    for (const block of extractIngredientBlocks(text)) {
      const ingredientRegex =
        /\('((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)'/g;

      for (const match of block.matchAll(ingredientRegex)) {
        const canonicalNameKo = parseSqlString(match[1]);
        const slug = parseSqlString(match[5]);
        const key = normalizeKey(canonicalNameKo);
        if (!key || !slug) {
          continue;
        }

        const existing =
          seedEntries.get(key) ??
          {
            canonicalNameKo,
            slug,
            aliases: [],
            source: "seed",
          };

        existing.slug = existing.slug || slug;
        uniquePush(existing.aliases, canonicalNameKo);
        seedEntries.set(key, existing);
      }
    }

    for (const block of extractSynonymBlocks(text)) {
      const synonymRegex =
        /\(\(SELECT id FROM ingredients WHERE slug='([^']+)'\),\s*'((?:[^']|'')*)',\s*'([^']*)',\s*'([^']*)',\s*(true|false)\)/g;

      for (const match of block.matchAll(synonymRegex)) {
        const slug = parseSqlString(match[1]);
        const synonym = parseSqlString(match[2]);

        for (const entry of seedEntries.values()) {
          if (entry.slug !== slug) {
            continue;
          }
          uniquePush(entry.aliases, synonym);
        }
      }
    }

    const rawLabelRegex =
      /\(\(SELECT id FROM products[\s\S]*?\(SELECT id FROM ingredients WHERE slug='([^']+)'\),\s*[^,]+,\s*'[^']*',\s*'[^']*',\s*'((?:[^']|'')*)'\)/g;

    for (const match of text.matchAll(rawLabelRegex)) {
      const slug = parseSqlString(match[1]);
      const rawLabel = parseSqlString(match[2]);
      for (const entry of seedEntries.values()) {
        if (entry.slug !== slug) {
          continue;
        }
        uniquePush(entry.aliases, rawLabel);
      }
    }
  }

  return [...seedEntries.values()];
}

function variantStrings(value) {
  const source = cleanInlineText(value);
  if (!source) {
    return [];
  }

  const prefixes = [
    "저분자",
    "가수분해",
    "어류",
    "해양",
    "피쉬",
    "marine",
    "혼합",
    "복합",
    "산화",
    "탄산",
    "구연산",
    "글루콘산",
    "피콜린산",
    "황산",
    "푸마르산",
    "피로인산",
    "유청",
    "해조",
    "천연",
    "d-",
    "dl-",
  ];
  const suffixes = [
    "추출물분말",
    "농축액분말",
    "추출분말",
    "농축분말",
    "껍질추출물",
    "추출물",
    "추출액",
    "농축액",
    "농축분말",
    "펩타이드",
    "분말",
    "농축",
    "제품",
  ];

  const queue = [source];
  const seen = new Set();
  const results = [];

  while (queue.length > 0) {
    const current = cleanInlineText(queue.shift());
    if (!current) {
      continue;
    }

    const dedupeKey = current.toLowerCase();
    if (seen.has(dedupeKey)) {
      continue;
    }
    seen.add(dedupeKey);
    results.push(current);

    const noParens = cleanInlineText(current.replace(/\([^)]+\)/g, " "));
    if (noParens && noParens !== current) {
      queue.push(noParens);
    }

    const noRecognition = cleanInlineText(
      current
        .replace(/제?\d{4}-\d+호?/g, " ")
        .replace(/\d+(\.\d+)?%/g, " ")
        .replace(/함량[^),]*/g, " "),
    );
    if (noRecognition && noRecognition !== current) {
      queue.push(noRecognition);
    }

    for (const prefix of prefixes) {
      if (current.toLowerCase().startsWith(prefix.toLowerCase())) {
        queue.push(current.slice(prefix.length));
      }
    }

    for (const suffix of suffixes) {
      if (current.toLowerCase().endsWith(suffix.toLowerCase())) {
        queue.push(current.slice(0, -suffix.length));
      }
    }

    if (current.includes("유산균")) {
      queue.push("유산균");
      queue.push("프로바이오틱스");
    }
  }

  return results;
}

const seedCatalog = parseSeedCatalog();
const mergedCatalog = new Map();

for (const seed of seedCatalog) {
  const key = normalizeKey(seed.canonicalNameKo);
  if (!key) {
    continue;
  }

  mergedCatalog.set(key, {
    canonicalNameKo: seed.canonicalNameKo,
    slug: seed.slug,
    aliases: [...new Set(seed.aliases.map((value) => cleanInlineText(value)).filter(Boolean))],
    sourceKinds: ["seed"],
    sourceDatasets: [],
  });
}

for await (const row of readJsonl(profileFile)) {
  const names = [
    row.canonicalNameKo,
    row.displayName,
    ...(row.aliases ?? []),
  ]
    .map((value) => cleanInlineText(value))
    .filter(Boolean);

  let catalogEntry = null;

  for (const name of names) {
    const key = normalizeKey(name);
    if (key && mergedCatalog.has(key)) {
      catalogEntry = mergedCatalog.get(key);
      break;
    }
  }

  if (!catalogEntry) {
    const key = normalizeKey(row.canonicalNameKo);
    if (!key) {
      continue;
    }
    catalogEntry = {
      canonicalNameKo: cleanInlineText(row.canonicalNameKo),
      slug: null,
      aliases: [],
      sourceKinds: [],
      sourceDatasets: [],
    };
    mergedCatalog.set(key, catalogEntry);
  }

  uniquePush(catalogEntry.sourceKinds, "mfds-profile");
  for (const dataset of row.sourceDatasets ?? []) {
    uniquePush(catalogEntry.sourceDatasets, dataset);
  }
  for (const value of names) {
    uniquePush(catalogEntry.aliases, value);
  }
}

const aliasIndex = new Map();

for (const entry of mergedCatalog.values()) {
  const terms = [entry.canonicalNameKo, ...(entry.aliases ?? [])]
    .map((value) => cleanInlineText(value))
    .filter(Boolean);

  for (const term of terms) {
    for (const variant of variantStrings(term)) {
      const key = normalizeKey(variant);
      if (!key) {
        continue;
      }

      const bucket = aliasIndex.get(key) ?? [];
      bucket.push({
        canonicalNameKo: entry.canonicalNameKo,
        slug: entry.slug,
      });
      aliasIndex.set(key, bucket);
    }
  }
}

for (const [key, values] of aliasIndex.entries()) {
  const unique = [];
  const seen = new Set();

  for (const value of values) {
    const signature = `${value.canonicalNameKo}::${value.slug ?? ""}`;
    if (seen.has(signature)) {
      continue;
    }
    seen.add(signature);
    unique.push(value);
  }

  aliasIndex.set(key, unique);
}

function resolveMention(rawLabelName) {
  const variants = variantStrings(rawLabelName);
  const exactKey = normalizeKey(rawLabelName);

  for (const variant of variants) {
    const key = normalizeKey(variant);
    if (!key) {
      continue;
    }

    const matches = aliasIndex.get(key) ?? [];
    if (matches.length !== 1) {
      continue;
    }

    return {
      ...matches[0],
      matchStrategy: key === exactKey ? "exact" : "variant",
      matchedVariant: variant,
      confidence: key === exactKey ? 1 : 0.9,
    };
  }

  return null;
}

const distinctMentions = new Map();

for await (const row of readJsonl(mentionFile)) {
  const rawLabelName = cleanInlineText(row.rawLabelName);
  if (!rawLabelName) {
    continue;
  }

  const existing =
    distinctMentions.get(rawLabelName) ??
    {
      rawLabelName,
      mentionCount: 0,
      exampleProductName: cleanInlineText(row.productName),
      exampleReportNo: cleanInlineText(row.reportNo),
      exampleRole: cleanInlineText(row.ingredientRole),
    };

  existing.mentionCount += 1;
  distinctMentions.set(rawLabelName, existing);
}

const mappingRows = [];
const unresolvedRows = [];
let matchedMentionCount = 0;
let unmatchedMentionCount = 0;

for (const mention of distinctMentions.values()) {
  const resolution = resolveMention(mention.rawLabelName);
  const row = {
    rawLabelName: mention.rawLabelName,
    mentionCount: mention.mentionCount,
    exampleProductName: mention.exampleProductName,
    exampleReportNo: mention.exampleReportNo,
    exampleRole: mention.exampleRole,
    canonicalNameKo: resolution?.canonicalNameKo ?? null,
    canonicalSlug: resolution?.slug ?? null,
    matchStrategy: resolution?.matchStrategy ?? null,
    matchedVariant: resolution?.matchedVariant ?? null,
    confidence: resolution?.confidence ?? null,
  };

  mappingRows.push(row);

  if (resolution) {
    matchedMentionCount += mention.mentionCount;
  } else {
    unresolvedRows.push(row);
    unmatchedMentionCount += mention.mentionCount;
  }
}

mappingRows.sort((a, b) => b.mentionCount - a.mentionCount || a.rawLabelName.localeCompare(b.rawLabelName, "ko"));
unresolvedRows.sort((a, b) => b.mentionCount - a.mentionCount || a.rawLabelName.localeCompare(b.rawLabelName, "ko"));

const mappingIndex = new Map(
  mappingRows.map((row) => [row.rawLabelName, row]),
);

const resolvedMentionsWriter = createJsonlWriter(
  path.join(outputDir, "product_ingredient_mentions.resolved.jsonl"),
);

for await (const row of readJsonl(mentionFile)) {
  const rawLabelName = cleanInlineText(row.rawLabelName);
  const mapping = rawLabelName ? mappingIndex.get(rawLabelName) : null;
  if (!mapping || !mapping.canonicalNameKo) {
    continue;
  }

  resolvedMentionsWriter.write({
    ...row,
    canonicalNameKo: mapping.canonicalNameKo,
    canonicalSlug: mapping.canonicalSlug,
    matchStrategy: mapping.matchStrategy,
    matchedVariant: mapping.matchedVariant,
    confidence: mapping.confidence,
  });
}

await resolvedMentionsWriter.close();

async function writeJsonl(filePath, rows) {
  const writer = createJsonlWriter(filePath);
  for (const row of rows) {
    writer.write(row);
  }
  await writer.close();
}

await writeJsonl(path.join(outputDir, "ingredient_catalog.merged.jsonl"), [...mergedCatalog.values()].sort((a, b) => a.canonicalNameKo.localeCompare(b.canonicalNameKo, "ko")));
await writeJsonl(path.join(outputDir, "ingredient_name_mapping.normalized.jsonl"), mappingRows);
await writeJsonl(path.join(outputDir, "ingredient_name_unresolved.normalized.jsonl"), unresolvedRows);

const summary = {
  generatedAt: new Date().toISOString(),
  inputFiles: {
    ingredientProfiles: profileFile,
    ingredientMentions: mentionFile,
  },
  outputDir,
  counts: {
    mergedCatalogEntries: mergedCatalog.size,
    distinctRawLabelNames: mappingRows.length,
    matchedDistinctNames: mappingRows.length - unresolvedRows.length,
    unresolvedDistinctNames: unresolvedRows.length,
    matchedMentionCount,
    unmatchedMentionCount,
  },
};

writeFileSync(
  path.join(outputDir, "summary.json"),
  `${JSON.stringify(summary, null, 2)}\n`,
);

console.log(JSON.stringify(summary, null, 2));
