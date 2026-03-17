#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import postgres from "postgres";

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const webDir = path.resolve(scriptDir, "..");
const rootDir = path.resolve(webDir, "..");

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

function parseArgs(argv) {
  const args = {
    dryRun: false,
    limitPages: null,
    service: "all",
    outDir: null,
  };

  for (const token of argv) {
    if (token === "--dry-run") {
      args.dryRun = true;
      continue;
    }

    if (token.startsWith("--limit-pages=")) {
      args.limitPages = Number(token.split("=")[1]);
      continue;
    }

    if (token.startsWith("--service=")) {
      args.service = token.split("=")[1];
      continue;
    }

    if (token.startsWith("--out-dir=")) {
      args.outDir = path.resolve(rootDir, token.split("=")[1]);
    }
  }

  return args;
}

const args = parseArgs(process.argv.slice(2));

const foodsafetyKey = process.env.FOODSAFETY_KOREA_API_KEY;
const dataGoKey =
  process.env.DATA_GO_KR_SERVICE_KEY_DECODED ||
  process.env.DATA_GO_KR_SERVICE_KEY_ENCODED;
const databaseUrl = process.env.DATABASE_URL;

const connectors = [
  {
    key: "foodsafety-i0030",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i0030",
    sourceCategory: "product_catalog",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "product",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.PRDLST_REPORT_NO ?? null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I0030/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I0030.total_count ?? 0),
        records: payload.I0030.row ?? [],
      };
    },
  },
  {
    key: "foodsafety-c003",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-c003",
    sourceCategory: "product_catalog",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "product_rawmaterial",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.PRDLST_REPORT_NO ?? null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/C003/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.C003.total_count ?? 0),
        records: payload.C003.row ?? [],
      };
    },
  },
  {
    key: "foodsafety-i2710",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i2710",
    sourceCategory: "regulator",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "ingredient_claim_profile",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.PRDCT_NM ? `I2710:${record.PRDCT_NM}` : null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I2710/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I2710.total_count ?? 0),
        records: payload.I2710.row ?? [],
      };
    },
  },
  {
    key: "foodsafety-i0040",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i-0040",
    sourceCategory: "regulator",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "ingredient_regulatory_record",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.HF_FNCLTY_MTRAL_RCOGN_NO ?? null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I-0040/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload["I-0040"].total_count ?? 0),
        records: payload["I-0040"].row ?? [],
      };
    },
  },
  {
    key: "foodsafety-i0050",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i-0050",
    sourceCategory: "regulator",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "ingredient_recognition_profile",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.HF_FNCLTY_MTRAL_RCOGN_NO ?? null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I-0050/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload["I-0050"].total_count ?? 0),
        records: payload["I-0050"].row ?? [],
      };
    },
  },
  {
    key: "foodsafety-i0760",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i0760",
    sourceCategory: "regulator",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "ingredient_group",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      return record.HELT_ITM_GRP_CD ?? null;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I0760/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I0760.total_count ?? 0),
        records: payload.I0760.row ?? [],
      };
    },
  },
  {
    key: "foodsafety-i0960",
    sourceName: "식품안전나라",
    connectorName: "foodsafety-kr-i0960",
    sourceCategory: "regulator",
    baseUrl: "http://openapi.foodsafetykorea.go.kr/api",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 30,
    entityType: "regulatory_standard",
    pageSize: 1000,
    sleepMs: 2200,
    externalId(record) {
      if (!record.PRDLST_CD || !record.PC_KOR_NM) {
        return null;
      }

      return `${record.PRDLST_CD}:${record.PC_KOR_NM}`;
    },
    buildPageUrl(page) {
      const start = (page - 1) * this.pageSize + 1;
      const end = start + this.pageSize - 1;
      return `${this.baseUrl}/${foodsafetyKey}/I0960/json/${start}/${end}`;
    },
    normalizePage(payload) {
      return {
        totalCount: Number(payload.I0960.total_count ?? 0),
        records: payload.I0960.row ?? [],
      };
    },
  },
  {
    key: "data-go-15056760",
    sourceName: "공공데이터포털",
    connectorName: "data-go-kr-15056760",
    sourceCategory: "product_catalog",
    baseUrl: "https://apis.data.go.kr/1471000/HtfsInfoService03",
    accessStrategy: "api",
    authType: "api_key",
    rateLimitPerMinute: 60,
    entityType: "product_catalog",
    pageSize: 500,
    sleepMs: 300,
    externalId(record) {
      return record.STTEMNT_NO ?? null;
    },
    buildPageUrl(page) {
      return `${this.baseUrl}/getHtfsList01?ServiceKey=${encodeURIComponent(
        dataGoKey,
      )}&pageNo=${page}&numOfRows=${this.pageSize}&type=json`;
    },
    normalizePage(payload) {
      const items = payload?.body?.items ?? [];
      const records = Array.isArray(items)
        ? items.map((entry) => entry.item)
        : Array.isArray(items.item)
          ? items.item
          : items.item
            ? [items.item]
            : [];

      return {
        totalCount: Number(payload?.body?.totalCount ?? 0),
        records,
      };
    },
  },
];

const selectedConnectors =
  args.service === "all"
    ? connectors
    : connectors.filter((connector) => connector.key === args.service);

if (selectedConnectors.length === 0) {
  console.error(`Unknown service: ${args.service}`);
  process.exit(1);
}

if (
  selectedConnectors.some((connector) => connector.key.startsWith("foodsafety-")) &&
  !foodsafetyKey
) {
  console.error("Missing FOODSAFETY_KOREA_API_KEY");
  process.exit(1);
}

if (
  selectedConnectors.some((connector) => connector.key.startsWith("data-go-")) &&
  !dataGoKey
) {
  console.error(
    "Missing DATA_GO_KR_SERVICE_KEY_DECODED or DATA_GO_KR_SERVICE_KEY_ENCODED",
  );
  process.exit(1);
}

if (!databaseUrl && !args.dryRun && !args.outDir) {
  console.error(
    "Missing DATABASE_URL. Use --dry-run or --out-dir=... if you only want to fetch without DB writes.",
  );
  process.exit(1);
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchJson(url) {
  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
    },
  });
  const text = await response.text();
  let payload;

  try {
    payload = JSON.parse(text);
  } catch (error) {
    throw new Error(`Non-JSON response for ${url}\n${text}`);
  }

  return payload;
}

async function ensureSourceConnector(sql, connector) {
  const sourceRows = await sql`
    select id
    from sources
    where source_name = ${connector.sourceName}
    limit 1
  `;

  if (sourceRows.length === 0) {
    throw new Error(`Source not found: ${connector.sourceName}`);
  }

  const sourceId = sourceRows[0].id;
  const existingRows = await sql`
    select id
    from source_connectors
    where source_id = ${sourceId}
      and connector_name = ${connector.connectorName}
    limit 1
  `;

  if (existingRows.length > 0) {
    await sql`
      update source_connectors
      set source_category = ${connector.sourceCategory},
          base_url = ${connector.baseUrl},
          access_strategy = ${connector.accessStrategy},
          auth_type = ${connector.authType},
          rate_limit_per_minute = ${connector.rateLimitPerMinute},
          is_active = true,
          retry_policy = ${sql.json({
            maxRetries: 3,
            backoffSeconds: [2, 4, 8],
          })},
          parser_config = ${sql.json({
            responseFormat: "json",
            rawMode: "record",
          })},
          updated_at = now()
      where id = ${existingRows[0].id}
    `;

    return existingRows[0].id;
  }

  const inserted = await sql`
    insert into source_connectors (
      source_id,
      connector_name,
      source_category,
      base_url,
      access_strategy,
      auth_type,
      is_active,
      rate_limit_per_minute,
      retry_policy,
      parser_config
    )
    values (
      ${sourceId},
      ${connector.connectorName},
      ${connector.sourceCategory},
      ${connector.baseUrl},
      ${connector.accessStrategy},
      ${connector.authType},
      true,
      ${connector.rateLimitPerMinute},
      ${sql.json({
        maxRetries: 3,
        backoffSeconds: [2, 4, 8],
      })},
      ${sql.json({
        responseFormat: "json",
        rawMode: "record",
      })}
    )
    returning id
  `;

  return inserted[0].id;
}

async function ensureCollectionJob(sql, connectorId, connector) {
  const jobName = `backfill:${connector.key}`;
  const existingRows = await sql`
    select id
    from collection_jobs
    where source_connector_id = ${connectorId}
      and job_name = ${jobName}
    order by id desc
    limit 1
  `;

  if (existingRows.length > 0) {
    await sql`
      update collection_jobs
      set job_type = 'full_sync',
          entity_type = ${connector.entityType},
          query_payload = ${sql.json({
            pageSize: connector.pageSize,
            sourceKey: connector.key,
          })},
          status = 'running',
          started_at = now(),
          finished_at = null,
          error_message = null,
          updated_at = now()
      where id = ${existingRows[0].id}
    `;

    return existingRows[0].id;
  }

  const inserted = await sql`
    insert into collection_jobs (
      source_connector_id,
      job_type,
      entity_type,
      job_name,
      query_payload,
      priority,
      status,
      scheduled_at,
      started_at
    )
    values (
      ${connectorId},
      'full_sync',
      ${connector.entityType},
      ${jobName},
      ${sql.json({
        pageSize: connector.pageSize,
        sourceKey: connector.key,
      })},
      'high',
      'running',
      now(),
      now()
    )
    returning id
  `;

  return inserted[0].id;
}

async function startCollectionRun(sql, jobId) {
  const inserted = await sql`
    insert into collection_runs (
      collection_job_id,
      run_status,
      started_at
    )
    values (
      ${jobId},
      'running',
      now()
    )
    returning id
  `;

  return inserted[0].id;
}

async function finishCollectionRun(sql, runId, summary, errorMessage) {
  await sql`
    update collection_runs
    set run_status = ${errorMessage ? "failed" : "succeeded"},
        records_fetched = ${summary.recordsFetched},
        records_created = ${summary.recordsCreated},
        records_unchanged = ${summary.recordsUnchanged},
        records_failed = ${summary.recordsFailed},
        finished_at = now(),
        execution_log = ${summary.executionLog.join("\n")},
        error_details = ${errorMessage
          ? sql.json({ message: errorMessage })
          : null}
    where id = ${runId}
  `;
}

async function finishCollectionJob(sql, jobId, errorMessage) {
  await sql`
    update collection_jobs
    set status = ${errorMessage ? "failed" : "succeeded"},
        finished_at = now(),
        error_message = ${errorMessage ?? null},
        updated_at = now()
    where id = ${jobId}
  `;
}

async function loadExistingChecksums(sql, connectorId, externalIds) {
  if (externalIds.length === 0) {
    return new Map();
  }

  const rows = await sql`
    select distinct on (entity_external_id)
      entity_external_id,
      checksum
    from raw_documents
    where source_connector_id = ${connectorId}
      and entity_external_id = any(${sql.array(externalIds, "text")})
    order by entity_external_id, fetched_at desc, id desc
  `;

  return new Map(rows.map((row) => [row.entity_external_id, row.checksum]));
}

function writeJsonl(outDir, connector, records) {
  if (!outDir || records.length === 0) {
    return;
  }

  mkdirSync(outDir, { recursive: true });
  const filePath = path.join(outDir, `${connector.key}.jsonl`);
  const lines = records.map((record) => JSON.stringify(record)).join("\n") + "\n";
  writeFileSync(filePath, lines, { flag: "a" });
}

async function processConnector(sql, connector) {
  const summary = {
    recordsFetched: 0,
    recordsCreated: 0,
    recordsUnchanged: 0,
    recordsFailed: 0,
    executionLog: [],
  };

  const connectorId = sql ? await ensureSourceConnector(sql, connector) : null;
  const jobId = sql ? await ensureCollectionJob(sql, connectorId, connector) : null;
  const runId = sql ? await startCollectionRun(sql, jobId) : null;
  let errorMessage = null;

  try {
    const firstPayload = await fetchJson(connector.buildPageUrl(1));
    const firstPage = connector.normalizePage(firstPayload);
    const totalPages = Math.ceil(firstPage.totalCount / connector.pageSize) || 1;
    const pageLimit = args.limitPages
      ? Math.min(totalPages, args.limitPages)
      : totalPages;

    summary.executionLog.push(
      `${connector.key}: totalCount=${firstPage.totalCount}, totalPages=${totalPages}, pageLimit=${pageLimit}`,
    );

    for (let page = 1; page <= pageLimit; page += 1) {
      if (page > 1) {
        await sleep(connector.sleepMs);
      }

      const payload = page === 1 ? firstPayload : await fetchJson(connector.buildPageUrl(page));
      const normalized = connector.normalizePage(payload);
      const records = normalized.records;
      const prepared = records.map((record, index) => {
        const rawText = JSON.stringify(record);
        const externalId = connector.externalId(record) ?? `${connector.key}:page-${page}:row-${index + 1}`;

        return {
          externalId,
          checksum: sha256(rawText),
          rawText,
          record,
          sourceUrl: connector.buildPageUrl(page),
        };
      });

      summary.recordsFetched += prepared.length;

      if (args.outDir) {
        writeJsonl(
          args.outDir,
          connector,
          prepared.map((entry) => entry.record),
        );
      }

      if (args.dryRun || !sql) {
        summary.executionLog.push(
          `${connector.key}: page=${page}, fetched=${prepared.length}, mode=${args.dryRun ? "dry-run" : "file-only"}`,
        );
        continue;
      }

      const existingChecksums = await loadExistingChecksums(
        sql,
        connectorId,
        prepared.map((entry) => entry.externalId),
      );

      const toInsert = prepared.filter((entry) => {
        const previousChecksum = existingChecksums.get(entry.externalId);
        if (previousChecksum && previousChecksum === entry.checksum) {
          summary.recordsUnchanged += 1;
          return false;
        }

        return true;
      });

      if (toInsert.length > 0) {
        await sql`
          insert into raw_documents (
            source_connector_id,
            entity_type,
            entity_external_id,
            source_url,
            content_type,
            raw_text,
            raw_json,
            checksum,
            fetched_at
          )
          values ${sql(
            toInsert.map((entry) => [
              connectorId,
              connector.entityType,
              entry.externalId,
              entry.sourceUrl,
              "application/json",
              entry.rawText,
              sql.json(entry.record),
              entry.checksum,
              new Date(),
            ]),
          )}
        `;
      }

      summary.recordsCreated += toInsert.length;
      summary.executionLog.push(
        `${connector.key}: page=${page}, fetched=${prepared.length}, inserted=${toInsert.length}, unchanged=${prepared.length - toInsert.length}`,
      );
    }
  } catch (error) {
    errorMessage = error instanceof Error ? error.message : String(error);
    summary.recordsFailed += 1;
    summary.executionLog.push(`${connector.key}: error=${errorMessage}`);
  }

  if (sql && runId) {
    await finishCollectionRun(sql, runId, summary, errorMessage);
    await finishCollectionJob(sql, jobId, errorMessage);
  }

  if (errorMessage) {
    throw new Error(errorMessage);
  }

  return summary;
}

async function main() {
  const sql = databaseUrl && !args.dryRun
    ? postgres(databaseUrl, {
        max: 1,
        idle_timeout: 5,
        connect_timeout: 30,
      })
    : null;

  try {
    for (const connector of selectedConnectors) {
      const summary = await processConnector(sql, connector);
      console.log(
        [
          connector.key,
          `fetched=${summary.recordsFetched}`,
          `inserted=${summary.recordsCreated}`,
          `unchanged=${summary.recordsUnchanged}`,
          args.dryRun ? "mode=dry-run" : null,
          args.outDir ? `outDir=${args.outDir}` : null,
        ]
          .filter(Boolean)
          .join(" "),
      );
    }
  } finally {
    if (sql) {
      await sql.end();
    }
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
