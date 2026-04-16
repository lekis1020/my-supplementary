/**
 * Shared env loader — .env.local, .env 파일을 web/ 또는 repo 루트에서 찾아 load.
 * 기존 import_kr_*.mjs 스크립트의 env 로딩 패턴을 재사용하기 위해 추출.
 */

import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

function parseEnvFile(filePath) {
  const values = {};
  const content = readFileSync(filePath, "utf8");

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const sep = line.indexOf("=");
    if (sep === -1) continue;

    const key = line.slice(0, sep).trim();
    let value = line.slice(sep + 1).trim();

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

export function loadEnv() {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const webDir = path.resolve(scriptDir, "..", "..");
  const rootDir = path.resolve(webDir, "..");

  const candidates = [
    path.join(webDir, ".env.local"),
    path.join(rootDir, ".env.local"),
    path.join(webDir, ".env"),
    path.join(rootDir, ".env"),
  ];

  for (const file of candidates) {
    if (!existsSync(file)) continue;
    const values = parseEnvFile(file);
    for (const [k, v] of Object.entries(values)) {
      if (process.env[k] === undefined) process.env[k] = v;
    }
  }
}

export function requireEnv(...keys) {
  const missing = keys.filter((k) => !process.env[k]);
  if (missing.length > 0) {
    console.error(`Missing required env vars: ${missing.join(", ")}`);
    console.error("Set them in web/.env.local or project root .env.local");
    process.exit(1);
  }
}
