/**
 * Shared JSONL helpers — streaming reader + append/stream writers.
 * Reader extracted from readJsonl copies in import_kr_*.mjs,
 * appendJsonl from backfill_kr_gov_raw.mjs, stream writer from root scripts.
 */
import { createReadStream, createWriteStream, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import readline from "node:readline";

export async function* readJsonl(filePath) {
  const stream = createReadStream(filePath, { encoding: "utf8" });
  const lineReader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  for await (const line of lineReader) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    yield JSON.parse(trimmed);
  }
}

export async function readAllJsonl(filePath) {
  const rows = [];
  for await (const row of readJsonl(filePath)) {
    rows.push(row);
  }
  return rows;
}

export function appendJsonl(filePath, records) {
  if (!records || records.length === 0) return;
  mkdirSync(path.dirname(filePath), { recursive: true });
  const lines = records.map((record) => JSON.stringify(record)).join("\n") + "\n";
  writeFileSync(filePath, lines, { flag: "a" });
}

export function createJsonlWriter(filePath) {
  mkdirSync(path.dirname(filePath), { recursive: true });
  const stream = createWriteStream(filePath, { encoding: "utf8" });
  return {
    write(record) {
      stream.write(JSON.stringify(record) + "\n");
    },
    close() {
      return new Promise((resolve, reject) => {
        stream.on("error", reject);
        stream.end(resolve);
      });
    },
  };
}
