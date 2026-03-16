#!/usr/bin/env node

import { readFileSync, existsSync } from "node:fs";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();
const envCandidates = [
  path.join(rootDir, ".env.local"),
  path.join(rootDir, "web", ".env.local"),
  path.join(rootDir, ".env"),
  path.join(rootDir, "web", ".env"),
];

function parseEnvFile(filePath) {
  const values = {};
  const content = readFileSync(filePath, "utf8");

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

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
  if (!existsSync(envPath)) {
    continue;
  }

  const values = parseEnvFile(envPath);
  for (const [key, value] of Object.entries(values)) {
    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

const foodsafetyKey = process.env.FOODSAFETY_KOREA_API_KEY;
const dataGoKey =
  process.env.DATA_GO_KR_SERVICE_KEY_DECODED ||
  process.env.DATA_GO_KR_SERVICE_KEY_ENCODED;

if (!foodsafetyKey) {
  console.error("Missing FOODSAFETY_KOREA_API_KEY");
  process.exit(1);
}

if (!dataGoKey) {
  console.error(
    "Missing DATA_GO_KR_SERVICE_KEY_DECODED or DATA_GO_KR_SERVICE_KEY_ENCODED",
  );
  process.exit(1);
}

const tests = [
  {
    name: "식품안전나라 I0030 건강기능식품 품목제조 신고사항 현황",
    url: `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I0030/json/1/1`,
    kind: "foodsafety",
  },
  {
    name: "식품안전나라 I0760 건강기능식품 영양DB",
    url: `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I0760/json/1/1`,
    kind: "foodsafety",
  },
  {
    name: "식품안전나라 I-0040 건강기능식품 기능성 원료인정현황",
    url: `http://openapi.foodsafetykorea.go.kr/api/${foodsafetyKey}/I-0040/json/1/1`,
    kind: "foodsafety",
  },
  {
    name: "공공데이터포털 건강기능식품정보 getHtfsList01",
    url: `https://apis.data.go.kr/1471000/HtfsInfoService03/getHtfsList01?ServiceKey=${encodeURIComponent(dataGoKey)}&pageNo=1&numOfRows=1&type=json`,
    kind: "data-go",
  },
];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isFoodsafetySuccess(payload) {
  const entry = Object.values(payload).find(
    (value) => value && typeof value === "object" && "RESULT" in value,
  );

  return entry?.RESULT?.CODE === "INFO-000";
}

function summarizeFoodsafety(payload) {
  const [serviceName, body] = Object.entries(payload)[0];
  const row = body?.row?.[0] ?? {};
  const label =
    row.PRDLST_NM ||
    row.HELT_ITM_GRP_NM ||
    row.APLC_RAWMTRL_NM ||
    row.RAWMTRL_NM ||
    "row";

  return `${serviceName}: ${label}`;
}

function isDataGoSuccess(payload) {
  return payload?.header?.resultCode === "00";
}

function summarizeDataGo(payload) {
  const item = payload?.body?.items?.[0]?.item ?? payload?.body?.items?.item ?? {};
  const label = item.PRDUCT || item.ENTRPS || "item";
  return `resultCode=${payload?.header?.resultCode} sample=${label}`;
}

async function run() {
  const results = [];

  for (const test of tests) {
    if (test.kind === "foodsafety") {
      await sleep(1500);
    }

    const response = await fetch(test.url, {
      headers: {
        Accept: "application/json",
      },
    });
    const raw = await response.text();

    let payload;
    try {
      payload = JSON.parse(raw);
    } catch (error) {
      throw new Error(`${test.name}: non-JSON response\n${raw}`);
    }

    if (test.kind === "foodsafety" && !isFoodsafetySuccess(payload)) {
      throw new Error(`${test.name}: unexpected response ${raw}`);
    }

    if (test.kind === "data-go" && !isDataGoSuccess(payload)) {
      throw new Error(`${test.name}: unexpected response ${raw}`);
    }

    results.push({
      name: test.name,
      summary:
        test.kind === "foodsafety"
          ? summarizeFoodsafety(payload)
          : summarizeDataGo(payload),
    });
  }

  console.log("Korean government API smoke test passed.");
  for (const result of results) {
    console.log(`- ${result.name}: ${result.summary}`);
  }
  console.log(
    "- 공공데이터포털 '기능성 원료인정 현황'은 LINK 유형이라 실제 호출은 식품안전나라 I-0040으로 검증합니다.",
  );
}

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
