# Phase 3 — 파이프라인 스크립트 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `web/scripts/` + 루트 `scripts/`의 파이프라인 스크립트에서 복붙된 공통 코드(env 파서 ×12, supabase 클라이언트 해석 ×11, chunk ×6, fetchAllRows ×4, JSONL 입출력, 재시도 없는 fetch)를 공유 lib으로 추출·적용하고, postgres.js 기반 import에 트랜잭션을 도입하며, 두 스크립트 트리를 `web/scripts/` 단일 트리로 통합한다.

**Architecture:** 공유 lib은 `web/scripts/lib/*.mjs`(기존 `env.mjs` 패턴 준수, ESM). lib 신설(Task 1–3) → 기존 스크립트 lib 적용(Task 4–6) → 트랜잭션+멱등성 문서(Task 7) → 트리 통합(Task 8) 순서. 동작 변경은 최소화하고(리팩토링), 실 DB 쓰기는 실행하지 않는다.

**Tech Stack:** Node ESM(.mjs), @supabase/supabase-js, postgres(porsager), vitest

**근거 문서:** `.omc/plans/refactoring-plan-2026-08-10.md` §2-C(#1~#12), §Phase 3. 3-4(Drizzle 점진 도입)는 **명시적으로 이번 범위에서 제외**(선택·후순위).

## Global Constraints

- 브랜치: `feat/phase3-pipeline-scripts` (main 직접 커밋 금지, 머지는 사용자가 PR로)
- 커밋: conventional 형식, 마지막 줄 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`, **`git add -A` 금지** — 항상 명시적 경로
- 게이트(각 태스크 마지막): `cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint` — 테스트 전부 통과(기준 97개+신규), lint 에러 0(기존 경고 5개는 허용)
- **실 DB 쓰기 실행 금지**: 스크립트 동작 검증은 `node --check`, `--dry-run`, read-only 명령(`npm run verify:sample` 등)까지만. 실제 import/scrape 실행은 사용자 확인 후
- 셸 `cd`는 zoxide 경유 — 단일 복합 명령 사용, cwd가 web/에 남는 함정 주의. macOS에 `timeout` 없음. 대괄호 경로는 따옴표
- 스크립트는 admin/파이프라인 트랙(service_role/DATABASE_URL) — 소비자용 RLS Supabase 클라이언트와 절대 혼용 금지
- 스크립트 lib 테스트는 lib 파일과 같은 폴더의 `*.test.mjs` (vitest include 확장은 Task 1에서 수행)
- 라인 번호는 main `a0b543e` 기준. 편집 후 밀리므로 내용 앵커로 위치를 확인할 것

---

## 현황 요약 (구현자용 참조)

- **env 파서 인라인 복붙**(로직 동일, 스타일만 상이) 12곳: `web/scripts/{backfill_kr_gov_raw, check_freshness, import_kr_staging_to_db, import_kr_dosage_to_supabase, import_kr_label_snapshots_to_supabase, import_kr_claims_to_supabase, import_kr_core_to_supabase, import_kr_safety_to_supabase, report_ingredient_evidence_gaps, verify_data_integrity}.mjs` + `scripts/test_korean_gov_apis.mjs`. 이미 `./lib/env.mjs`를 쓰는 7개: `scrape_cafe24, scrape_naver_shopping, enrich_products_from_staging, apply_migration, classify_ingredient_types, scrape_ckdhc, validate_product_images`
- **동작 차이 주의**: 인라인 복사본은 `if (!process.env[key])`(빈 문자열 덮어씀), lib은 `=== undefined`(빈 문자열 유지). lib 채택 시 빈 문자열 env가 유지되는 쪽으로 통일됨 — 의도된 변경
- **createClient 변형**: Variant A(env 직접 + `{persistSession:false}`) 6개 / Variant B(projectRef→supabase CLI 폴백 + `{persistSession:false, autoRefreshToken:false}`) 5개(import_kr_claims/core/safety/label/dosage)
- **postgres.js 사용** 6개: `import_kr_staging_to_db, backfill_kr_gov_raw, check_freshness, verify_data_integrity, report_ingredient_evidence_gaps, apply_migration`
- **fetch 재시도/백오프/타임아웃 전무** — 고정 딜레이 throttle만 존재
- **루트 scripts/**: DB 접속 없음(파일 변환·SQL 생성), `rootDir = process.cwd()` 의존, package.json 참조는 `gov:smoke:kr`(test_korean_gov_apis)뿐. 체인: normalize → map → classify → promote (에러 메시지 관습으로만 연결)

---

### Task 1: `lib/batch.mjs` + `lib/jsonl.mjs` + vitest include 확장

**Files:**
- Create: `web/scripts/lib/batch.mjs`
- Create: `web/scripts/lib/jsonl.mjs`
- Modify: `web/vitest.config.mts`
- Test: `web/scripts/lib/batch.test.mjs`, `web/scripts/lib/jsonl.test.mjs`

**Interfaces:**
- Consumes: 없음 (node stdlib만)
- Produces:
  - `chunk(array, size) => T[][]`
  - `async function* readJsonl(filePath)` — 한 줄당 JSON.parse, 빈 줄 skip
  - `readAllJsonl(filePath) => Promise<any[]>`
  - `appendJsonl(filePath, records) => void` — records 비면 no-op, 디렉터리 생성, append 모드
  - `createJsonlWriter(filePath) => { write(record), close(): Promise<void> }`

- [ ] **Step 1: vitest include 확장**

`web/vitest.config.mts`의 include를 다음으로 교체:

```ts
  test: {
    environment: "node",
    include: ["src/**/*.test.ts", "scripts/**/*.test.mjs"],
  },
```

- [ ] **Step 2: 실패하는 테스트 작성**

`web/scripts/lib/batch.test.mjs`:

```js
import { describe, expect, it } from "vitest";
import { chunk } from "./batch.mjs";

describe("chunk", () => {
  it("splits an array into fixed-size chunks", () => {
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
  });

  it("returns a single chunk when size exceeds length", () => {
    expect(chunk([1, 2], 10)).toEqual([[1, 2]]);
  });

  it("returns [] for an empty array", () => {
    expect(chunk([], 3)).toEqual([]);
  });

  it("splits exactly on multiples", () => {
    expect(chunk([1, 2, 3, 4], 2)).toEqual([[1, 2], [3, 4]]);
  });
});
```

`web/scripts/lib/jsonl.test.mjs`:

```js
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { appendJsonl, createJsonlWriter, readAllJsonl, readJsonl } from "./jsonl.mjs";

let dir;
beforeEach(() => {
  dir = mkdtempSync(path.join(tmpdir(), "jsonl-test-"));
});
afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

describe("readJsonl / readAllJsonl", () => {
  it("streams rows and skips blank lines", async () => {
    const file = path.join(dir, "in.jsonl");
    writeFileSync(file, '{"a":1}\n\n{"a":2}\n', "utf8");
    const rows = [];
    for await (const row of readJsonl(file)) rows.push(row);
    expect(rows).toEqual([{ a: 1 }, { a: 2 }]);
    expect(await readAllJsonl(file)).toEqual([{ a: 1 }, { a: 2 }]);
  });
});

describe("appendJsonl", () => {
  it("appends records, creating parent dirs, and no-ops on empty", () => {
    const file = path.join(dir, "sub", "out.jsonl");
    appendJsonl(file, []);
    appendJsonl(file, [{ a: 1 }]);
    appendJsonl(file, [{ a: 2 }, { a: 3 }]);
    expect(readFileSync(file, "utf8")).toBe('{"a":1}\n{"a":2}\n{"a":3}\n');
  });
});

describe("createJsonlWriter", () => {
  it("writes one JSON line per record and flushes on close", async () => {
    const file = path.join(dir, "w.jsonl");
    const writer = createJsonlWriter(file);
    writer.write({ a: 1 });
    writer.write({ a: 2 });
    await writer.close();
    expect(readFileSync(file, "utf8")).toBe('{"a":1}\n{"a":2}\n');
  });
});
```

- [ ] **Step 3: 실패 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib`
Expected: FAIL — `Cannot find module './batch.mjs'` 류

- [ ] **Step 4: 구현**

`web/scripts/lib/batch.mjs` (6개 스크립트의 byte-identical 구현 그대로):

```js
/**
 * Shared batching helper — extracted from 6 identical copies in import_kr_*.mjs.
 */
export function chunk(array, size) {
  const output = [];
  for (let index = 0; index < array.length; index += size) {
    output.push(array.slice(index, index + size));
  }
  return output;
}
```

`web/scripts/lib/jsonl.mjs`:

```js
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
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib`
Expected: PASS (batch 4, jsonl 3)

- [ ] **Step 6: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/lib/batch.mjs web/scripts/lib/batch.test.mjs web/scripts/lib/jsonl.mjs web/scripts/lib/jsonl.test.mjs web/vitest.config.mts && git commit -m "feat(scripts): add shared batch/jsonl libs with tests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: `lib/http.mjs` — retry/backoff/timeout 있는 fetchJson

**Files:**
- Create: `web/scripts/lib/http.mjs`
- Test: `web/scripts/lib/http.test.mjs`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `sleep(ms) => Promise<void>`
  - `class HttpError extends Error` — `{ status: number|null, retryable: boolean }`
  - `fetchJson(url, { headers?, retries?=3, backoffMs?=500, timeoutMs?=30000, fetchImpl?, sleepImpl? }) => Promise<any>` — 429/5xx/네트워크 오류/타임아웃은 지수 백오프 재시도, 그 외 4xx·비JSON 응답은 즉시 throw

- [ ] **Step 1: 실패하는 테스트 작성**

`web/scripts/lib/http.test.mjs`:

```js
import { describe, expect, it, vi } from "vitest";
import { HttpError, fetchJson, sleep } from "./http.mjs";

function jsonResponse(body, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    text: async () => (typeof body === "string" ? body : JSON.stringify(body)),
  };
}

describe("fetchJson", () => {
  it("returns parsed JSON on first success", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse({ ok: 1 }));
    const result = await fetchJson("https://x.test/a", { fetchImpl, sleepImpl: async () => {} });
    expect(result).toEqual({ ok: 1 });
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("retries on 500 then succeeds, with exponential backoff", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse("boom", 500))
      .mockResolvedValueOnce(jsonResponse("boom", 503))
      .mockResolvedValueOnce(jsonResponse({ ok: 1 }));
    const delays = [];
    const result = await fetchJson("https://x.test/a", {
      fetchImpl,
      backoffMs: 100,
      sleepImpl: async (ms) => delays.push(ms),
    });
    expect(result).toEqual({ ok: 1 });
    expect(fetchImpl).toHaveBeenCalledTimes(3);
    expect(delays).toEqual([100, 200]);
  });

  it("retries on network error (TypeError)", async () => {
    const fetchImpl = vi
      .fn()
      .mockRejectedValueOnce(new TypeError("fetch failed"))
      .mockResolvedValueOnce(jsonResponse({ ok: 1 }));
    const result = await fetchJson("https://x.test/a", { fetchImpl, sleepImpl: async () => {} });
    expect(result).toEqual({ ok: 1 });
    expect(fetchImpl).toHaveBeenCalledTimes(2);
  });

  it("throws immediately on 404 without retrying", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse("nope", 404));
    await expect(
      fetchJson("https://x.test/a", { fetchImpl, sleepImpl: async () => {} }),
    ).rejects.toMatchObject({ status: 404 });
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("throws immediately on non-JSON 200 body", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse("<html>oops</html>"));
    await expect(
      fetchJson("https://x.test/a", { fetchImpl, sleepImpl: async () => {} }),
    ).rejects.toThrow(/Non-JSON response/);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("throws the last error after exhausting retries", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse("boom", 500));
    await expect(
      fetchJson("https://x.test/a", { fetchImpl, retries: 2, sleepImpl: async () => {} }),
    ).rejects.toBeInstanceOf(HttpError);
    expect(fetchImpl).toHaveBeenCalledTimes(3);
  });
});

describe("sleep", () => {
  it("resolves", async () => {
    await expect(sleep(1)).resolves.toBeUndefined();
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib/http.test.mjs`
Expected: FAIL — `Cannot find module './http.mjs'`

- [ ] **Step 3: 구현**

`web/scripts/lib/http.mjs`:

```js
/**
 * Shared HTTP helper for pipeline scripts — JSON GET with timeout and
 * retry/backoff. Retryable: 429, 5xx, network errors, timeouts.
 * Fail-fast: other 4xx and non-JSON bodies.
 * (Previously no script had any retry/backoff/timeout — scripts-review #5.)
 */
export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export class HttpError extends Error {
  constructor(message, { status = null, retryable = false } = {}) {
    super(message);
    this.name = "HttpError";
    this.status = status;
    this.retryable = retryable;
  }
}

export async function fetchJson(url, {
  headers = { Accept: "application/json" },
  retries = 3,
  backoffMs = 500,
  timeoutMs = 30_000,
  fetchImpl = globalThis.fetch,
  sleepImpl = sleep,
} = {}) {
  let lastError;

  for (let attempt = 0; attempt <= retries; attempt += 1) {
    if (attempt > 0) {
      await sleepImpl(backoffMs * 2 ** (attempt - 1));
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetchImpl(url, { headers, signal: controller.signal });
      const text = await response.text();

      if (response.status === 429 || response.status >= 500) {
        lastError = new HttpError(`HTTP ${response.status} for ${url}`, {
          status: response.status,
          retryable: true,
        });
        continue;
      }

      if (!response.ok) {
        throw new HttpError(`HTTP ${response.status} for ${url}`, {
          status: response.status,
        });
      }

      try {
        return JSON.parse(text);
      } catch {
        throw new HttpError(`Non-JSON response for ${url}\n${text.slice(0, 500)}`, {
          status: response.status,
        });
      }
    } catch (error) {
      if (error instanceof HttpError && !error.retryable) {
        throw error;
      }
      lastError = error;
    } finally {
      clearTimeout(timer);
    }
  }

  throw lastError;
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib/http.test.mjs`
Expected: PASS (7 tests)

- [ ] **Step 5: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/lib/http.mjs web/scripts/lib/http.test.mjs && git commit -m "feat(scripts): add shared fetchJson with retry/backoff/timeout

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: `lib/supabase.mjs` — service-role 클라이언트 해석 + fetchAllRows

**Files:**
- Create: `web/scripts/lib/supabase.mjs`
- Test: `web/scripts/lib/supabase.test.mjs`

**Interfaces:**
- Consumes: 없음 (env는 호출자가 `loadEnv()`로 선주입)
- Produces:
  - `resolveProjectRef() => string|null` — `SUPABASE_PROJECT_REF` → `supabase/.temp/project-ref` 파일
  - `resolveSupabaseUrl(projectRef) => string|null`
  - `resolveServiceRoleKey(projectRef, { cliFallback?=true, exec? }) => string|null`
  - `getServiceRoleClient({ cliFallback?=true }) => SupabaseClient` — 해석 실패 시 명확한 메시지로 throw
  - `fetchAllRows(supabase, tableName, columns, batchSize=500) => Promise<any[]>` — id asc 페이징

- [ ] **Step 1: 실패하는 테스트 작성**

`web/scripts/lib/supabase.test.mjs`:

```js
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { fetchAllRows, resolveServiceRoleKey, resolveSupabaseUrl } from "./supabase.mjs";

const ENV_KEYS = [
  "NEXT_PUBLIC_SUPABASE_URL",
  "SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
  "SUPABASE_PROJECT_REF",
];
let saved;
beforeEach(() => {
  saved = Object.fromEntries(ENV_KEYS.map((k) => [k, process.env[k]]));
  for (const k of ENV_KEYS) delete process.env[k];
});
afterEach(() => {
  for (const k of ENV_KEYS) {
    if (saved[k] === undefined) delete process.env[k];
    else process.env[k] = saved[k];
  }
});

describe("resolveSupabaseUrl", () => {
  it("prefers a real env URL", () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://real.supabase.co";
    expect(resolveSupabaseUrl("abc")).toBe("https://real.supabase.co");
  });

  it("derives from projectRef when env URL is a placeholder", () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://placeholder.supabase.co";
    expect(resolveSupabaseUrl("abc")).toBe("https://abc.supabase.co");
  });

  it("returns null when nothing is available", () => {
    expect(resolveSupabaseUrl(null)).toBeNull();
  });
});

describe("resolveServiceRoleKey", () => {
  it("prefers the env var", () => {
    process.env.SUPABASE_SERVICE_ROLE_KEY = "svc-key";
    expect(resolveServiceRoleKey("abc")).toBe("svc-key");
  });

  it("falls back to the supabase CLI when allowed", () => {
    const exec = vi.fn().mockReturnValue(
      JSON.stringify([{ id: "service_role", api_key: "cli-key" }]),
    );
    expect(resolveServiceRoleKey("abc", { exec })).toBe("cli-key");
    expect(exec).toHaveBeenCalledOnce();
  });

  it("returns null without projectRef or when cliFallback is off", () => {
    expect(resolveServiceRoleKey(null)).toBeNull();
    const exec = vi.fn();
    expect(resolveServiceRoleKey("abc", { cliFallback: false, exec })).toBeNull();
    expect(exec).not.toHaveBeenCalled();
  });
});

describe("fetchAllRows", () => {
  function stubClient(pages) {
    let call = 0;
    const query = {
      from: () => query,
      select: () => query,
      order: () => query,
      range: () => Promise.resolve({ data: pages[call++] ?? [], error: null }),
    };
    return query;
  }

  it("pages through until a short page", async () => {
    const rows = await fetchAllRows(
      stubClient([[{ id: 1 }, { id: 2 }], [{ id: 3 }]]),
      "t",
      "id",
      2,
    );
    expect(rows).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }]);
  });

  it("throws on error", async () => {
    const query = {
      from: () => query,
      select: () => query,
      order: () => query,
      range: () => Promise.resolve({ data: null, error: new Error("boom") }),
    };
    await expect(fetchAllRows(query, "t", "id", 2)).rejects.toThrow("boom");
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib/supabase.test.mjs`
Expected: FAIL — `Cannot find module './supabase.mjs'`

- [ ] **Step 3: 구현**

`web/scripts/lib/supabase.mjs`:

```js
/**
 * Shared service-role Supabase client for pipeline scripts.
 * Merges two prior copy-pasted variants:
 *  - env-only (scrape_*, enrich, classify, validate)
 *  - env → SUPABASE_PROJECT_REF → supabase CLI fallback (import_kr_*)
 * Callers must run loadEnv() from ./env.mjs first.
 */
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createClient } from "@supabase/supabase-js";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const webDir = path.resolve(scriptDir, "..", "..");
const rootDir = path.resolve(webDir, "..");
const supabaseTempDir = path.join(rootDir, "supabase", ".temp");

function readTempValue(filename) {
  const filePath = path.join(supabaseTempDir, filename);
  if (!existsSync(filePath)) return null;
  return readFileSync(filePath, "utf8").trim() || null;
}

export function resolveProjectRef() {
  return process.env.SUPABASE_PROJECT_REF ?? readTempValue("project-ref");
}

export function resolveSupabaseUrl(projectRef) {
  const envUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL;

  if (envUrl && !envUrl.includes("placeholder.supabase.co")) {
    return envUrl;
  }

  return projectRef ? `https://${projectRef}.supabase.co` : envUrl ?? null;
}

export function resolveServiceRoleKey(
  projectRef,
  { cliFallback = true, exec = execFileSync } = {},
) {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY;
  }

  if (!cliFallback || !projectRef) {
    return null;
  }

  const output = exec(
    "supabase",
    ["projects", "api-keys", "list", "--project-ref", projectRef, "--output", "json"],
    { cwd: rootDir, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  );

  const keys = JSON.parse(output);
  const serviceRole = keys.find((item) => item.id === "service_role");
  return serviceRole?.api_key ?? null;
}

export function getServiceRoleClient({ cliFallback = true } = {}) {
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef, { cliFallback });

  if (!supabaseUrl) {
    throw new Error(
      "Missing Supabase URL (set NEXT_PUBLIC_SUPABASE_URL, SUPABASE_URL, or SUPABASE_PROJECT_REF)",
    );
  }
  if (!serviceRoleKey) {
    throw new Error(
      cliFallback
        ? "Missing SUPABASE_SERVICE_ROLE_KEY and could not resolve via Supabase CLI"
        : "Missing SUPABASE_SERVICE_ROLE_KEY",
    );
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function fetchAllRows(supabase, tableName, columns, batchSize = 500) {
  const rows = [];
  let from = 0;

  while (true) {
    const to = from + batchSize - 1;
    const { data, error } = await supabase
      .from(tableName)
      .select(columns)
      .order("id", { ascending: true })
      .range(from, to);

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    rows.push(...data);

    if (data.length < batchSize) {
      break;
    }

    from += batchSize;
  }

  return rows;
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `cd /Users/napler/projects/my-supple/web && npx vitest run scripts/lib/supabase.test.mjs`
Expected: PASS (8 tests)

- [ ] **Step 5: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/lib/supabase.mjs web/scripts/lib/supabase.test.mjs && git commit -m "feat(scripts): add shared service-role supabase client and fetchAllRows

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: supabase-js import 스크립트 5종 lib 적용

**Files:**
- Modify: `web/scripts/import_kr_claims_to_supabase.mjs`
- Modify: `web/scripts/import_kr_core_to_supabase.mjs`
- Modify: `web/scripts/import_kr_dosage_to_supabase.mjs`
- Modify: `web/scripts/import_kr_label_snapshots_to_supabase.mjs`
- Modify: `web/scripts/import_kr_safety_to_supabase.mjs`

**Interfaces:**
- Consumes: `loadEnv()` (`./lib/env.mjs`), `getServiceRoleClient()`·`fetchAllRows(supabase, tableName, columns, batchSize)` (`./lib/supabase.mjs`), `chunk(array, size)` (`./lib/batch.mjs`), `readJsonl(filePath)`·`readAllJsonl(filePath)` (`./lib/jsonl.mjs`)
- Produces: 없음 (동작 동일한 스크립트)

5개 스크립트 각각에 동일한 치환 패턴을 적용한다. **스크립트당 수정 → 검증 → 커밋을 1사이클로 반복** (claims → core → dosage → label → safety 순).

- [ ] **Step 1: import_kr_claims_to_supabase.mjs 치환**

제거할 블록(내용 앵커 기준):
1. 인라인 env 블록: `const envCandidates = [...]`, `function parseEnvFile(...)`, `for (const envPath of envCandidates) {...}` 적용 루프 (a0b543e 기준 L17–66). **주의**: `scriptDir`/`webDir`/`rootDir` 상수(L12–14)는 입력 경로 계산에 쓰이므로 유지. `supabaseTempDir`(L15)는 lib으로 이동했으므로 제거
2. `function readTempValue(...)`, `resolveProjectRef`, `resolveSupabaseUrl`, `resolveServiceRoleKey` (L90–135) — `execFileSync` import도 다른 사용처가 없으면 제거
3. `async function* readJsonl(...)` (L137–152)
4. `function chunk(...)` (L154–160)
5. `async function fetchAllRows(...)` (L410–440)

추가할 import + 초기화(파일 상단, 기존 import 뒤):

```js
import { loadEnv } from "./lib/env.mjs";
import { getServiceRoleClient, fetchAllRows } from "./lib/supabase.mjs";
import { chunk } from "./lib/batch.mjs";
import { readJsonl } from "./lib/jsonl.mjs";

loadEnv();
```

`main()`의 클라이언트 해석 블록 치환 — 기존:

```js
  const projectRef = resolveProjectRef();
  const supabaseUrl = resolveSupabaseUrl(projectRef);
  const serviceRoleKey = resolveServiceRoleKey(projectRef);

  if (!supabaseUrl) {
    throw new Error("Missing Supabase URL");
  }
  if (!serviceRoleKey) {
    throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY and could not resolve via Supabase CLI");
  }
```

→ 신규 (이후의 `createClient(supabaseUrl, serviceRoleKey, {...})` 호출도 함께 대체하고 `createClient` import 제거):

```js
  const supabase = getServiceRoleClient();
```

- [ ] **Step 2: claims 검증**

```bash
cd /Users/napler/projects/my-supple/web && node --check scripts/import_kr_claims_to_supabase.mjs && node scripts/import_kr_claims_to_supabase.mjs --dry-run
```

Expected: dry-run 요약 출력(쓰기 0건). 입력 파일(`tmp/kr-gov-clean/ingredient_profiles.normalized.jsonl`)이나 env가 없어 dry-run이 불가능하면 그 사실을 보고하고 `node --check` 통과로 갈음.

- [ ] **Step 3: claims 커밋**

```bash
cd /Users/napler/projects/my-supple && git add web/scripts/import_kr_claims_to_supabase.mjs && git commit -m "refactor(scripts): use shared libs in import_kr_claims

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 4: import_kr_core_to_supabase.mjs — Step 1과 같은 치환 + core 특이사항**

같은 5종 제거(env L16–65, resolve* 헬퍼, chunk L192, 인라인 JSONL reader) + import/loadEnv 추가 + `main()` 해석 블록을 `getServiceRoleClient()`로. core 특이사항: `fetchAllRows`가 없고 자체 `readAllRows`(JSONL 전체 읽기, L467 부근 정의·L777 사용)를 사용 — 이를 `readAllJsonl`로 대체:

```js
import { readAllJsonl } from "./lib/jsonl.mjs";
```

`const rows = await readAllRows(inputPath);` → `const rows = await readAllJsonl(inputPath);` (인자·반환 동일). core의 명시적 에러 throw(L747/751 부근)는 `getServiceRoleClient()`가 대신 수행하므로 제거.

검증: `node --check` + `node scripts/import_kr_core_to_supabase.mjs --dry-run` (dry-run 분기 L786 — 쓰기 없음).
커밋: `refactor(scripts): use shared libs in import_kr_core`

- [ ] **Step 5: import_kr_dosage_to_supabase.mjs — 같은 치환**

제거: env(L16–52), resolve* 헬퍼, readJsonl(L103), chunk(L113), fetchAllRows(L121). 추가/치환은 Step 1과 동일 패턴.
검증: `node --check` + `--dry-run`. 커밋: `refactor(scripts): use shared libs in import_kr_dosage`

- [ ] **Step 6: import_kr_label_snapshots_to_supabase.mjs — 같은 치환**

제거: env(L16–53), resolve* 헬퍼, readJsonl(L105), chunk(L115), fetchAllRows(L123).
검증: `node --check` + `--dry-run`. 커밋: `refactor(scripts): use shared libs in import_kr_label_snapshots`

- [ ] **Step 7: import_kr_safety_to_supabase.mjs — 같은 치환**

제거: env(L16–50), resolve* 헬퍼, readJsonl(L99), chunk(L109), fetchAllRows(L117).
검증: `node --check` + `--dry-run`. 커밋: `refactor(scripts): use shared libs in import_kr_safety`

- [ ] **Step 8: 전체 게이트**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
```

Expected: 전부 통과 (스크립트는 tsc 대상이 아니지만 게이트는 관례대로 전체 실행)

---

### Task 5: postgres.js 스크립트 5종 lib 적용 (+ fetchJson 채택)

**Files:**
- Modify: `web/scripts/import_kr_staging_to_db.mjs`
- Modify: `web/scripts/backfill_kr_gov_raw.mjs`
- Modify: `web/scripts/check_freshness.mjs`
- Modify: `web/scripts/verify_data_integrity.mjs`
- Modify: `web/scripts/report_ingredient_evidence_gaps.mjs`

**Interfaces:**
- Consumes: `loadEnv()` (`./lib/env.mjs`), `chunk` (`./lib/batch.mjs`), `readJsonl`·`appendJsonl` (`./lib/jsonl.mjs`), `fetchJson`·`sleep` (`./lib/http.mjs`)
- Produces: 없음 (동작 동일; fetch에 재시도/타임아웃이 추가되는 것만 의도된 변경)

스크립트당 수정 → 검증 → 커밋 1사이클 (staging → backfill → check_freshness → verify → report 순).

- [ ] **Step 1: import_kr_staging_to_db.mjs**

- 인라인 env 블록(L13–62) 제거, `scriptDir`/`webDir`/`rootDir`(L9–11)는 유지. `import { loadEnv } from "./lib/env.mjs";` + `loadEnv();` 추가. 이제 안 쓰는 `readFileSync` import 정리
- `async function* readRows(filePath)`(L394–409) 제거 → `import { readJsonl } from "./lib/jsonl.mjs";`, 사용처 `readRows(dataset.filePath)` → `readJsonl(dataset.filePath)`
- `function chunk(...)`(L411–417) 제거 → `import { chunk } from "./lib/batch.mjs";`

검증: `cd /Users/napler/projects/my-supple/web && node --check scripts/import_kr_staging_to_db.mjs && node scripts/import_kr_staging_to_db.mjs --dry-run` (dry-run은 DATABASE_URL 불필요, 단 입력 jsonl 부재 시 exit 1 — 그 경우 `node --check`로 갈음하고 보고)
커밋: `refactor(scripts): use shared libs in import_kr_staging_to_db`

- [ ] **Step 2: backfill_kr_gov_raw.mjs**

- 인라인 env 블록(L13–62) 제거(경로 상수 유지), loadEnv 추가
- 로컬 `fetchJson`(L378 부근)과 `sleep` 제거 → `import { fetchJson, sleep } from "./lib/http.mjs";` — 시그니처 호환(`fetchJson(url)`), 비JSON 에러 메시지가 전문(全文)에서 500자 절단으로 바뀌는 것은 의도된 변경. **의도된 변경(추가)**: 구 로컬 fetchJson은 HTTP 상태를 검사하지 않고 JSON 파싱 가능한 응답을 전부 수용했으나, lib 버전은 비-ok 상태에서 throw(429/5xx는 재시도 후) — 오류 페이로드의 원본 적재를 막는 교정이며, 실제 backfill 첫 실행(사용자 승인 후) 시 관찰할 것
- `function writeJsonl(outDir, connector, records)`(L606–615) 를 lib 위임으로 축약:

```js
import { appendJsonl } from "./lib/jsonl.mjs";

function writeJsonl(outDir, connector, records) {
  if (!outDir || records.length === 0) return;
  appendJsonl(path.join(outDir, `${connector.key}.jsonl`), records);
}
```

검증: `node --check scripts/backfill_kr_gov_raw.mjs` (실행은 KR gov API 호출이므로 금지)
커밋: `refactor(scripts): use shared env/http/jsonl libs in backfill_kr_gov_raw`

- [ ] **Step 3: check_freshness.mjs**

인라인 env 블록(L30–71) 제거(경로 상수 L26–28 유지), loadEnv 추가.
검증: `node --check scripts/check_freshness.mjs`; DATABASE_URL이 있으면 `npm run freshness:ci`(read-only) 실행.
커밋: `refactor(scripts): use shared env lib in check_freshness`

- [ ] **Step 4: verify_data_integrity.mjs**

인라인 env 블록(L36–77) 제거(경로 상수 L32–34 유지), loadEnv 추가. 로컬 `fetchJson`(L131 부근)·`sleep` 제거 → `./lib/http.mjs`에서 import (기존은 `res.ok` 체크 후 `.json()` — lib 버전과 호환).
검증: `node --check scripts/verify_data_integrity.mjs`; env가 있으면 `npm run verify:sample`(read-only) 실행해 기존과 같은 판정 나오는지 확인.
커밋: `refactor(scripts): use shared env/http libs in verify_data_integrity`

- [ ] **Step 5: report_ingredient_evidence_gaps.mjs**

인라인 env 블록(L24–64) 제거(경로 상수 L20–22 유지), loadEnv 추가.
검증: `node --check scripts/report_ingredient_evidence_gaps.mjs`
커밋: `refactor(scripts): use shared env lib in report_ingredient_evidence_gaps`

- [ ] **Step 6: 잔존 중복 0건 확인 + 전체 게이트**

```bash
cd /Users/napler/projects/my-supple && grep -rn "function parseEnvFile" web/scripts --include="*.mjs" | grep -v "lib/env.mjs"
```

Expected: 출력 없음 (루트 scripts/의 test_korean_gov_apis.mjs는 Task 8에서 처리)

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
```

---

### Task 6: Variant A 스크립트 6종 — createClient → getServiceRoleClient

**Files:**
- Modify: `web/scripts/enrich_products_from_staging.mjs:44-48`
- Modify: `web/scripts/classify_ingredient_types.mjs:27-31`
- Modify: `web/scripts/scrape_ckdhc.mjs:44-48`
- Modify: `web/scripts/scrape_naver_shopping.mjs:67-71`
- Modify: `web/scripts/scrape_cafe24.mjs:38-42`
- Modify: `web/scripts/validate_product_images.mjs:28-32`

**Interfaces:**
- Consumes: `getServiceRoleClient({ cliFallback: false })` (`./lib/supabase.mjs`)
- Produces: 없음

이 6개는 이미 `lib/env.mjs`의 `loadEnv`/`requireEnv`를 사용 중. **`requireEnv(...)` 호출은 그대로 유지**(supabase 키 포함 — 기존의 친절한 exit(1) 메시지 보존)하고, 클라이언트 생성만 교체한다.

- [ ] **Step 1: 6개 파일 각각 치환**

기존 (각 파일의 명시 라인):

```js
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);
```

→ 신규:

```js
const supabase = getServiceRoleClient({ cliFallback: false });
```

각 파일에서 `import { createClient } from "@supabase/supabase-js";` 제거, `import { getServiceRoleClient } from "./lib/supabase.mjs";` 추가. (동작 변화: `autoRefreshToken: false`가 추가되고 URL 해석에 projectRef 폴백이 생김 — 서버 스크립트에서 둘 다 무해한 개선)

- [ ] **Step 2: 검증**

```bash
cd /Users/napler/projects/my-supple/web && for f in enrich_products_from_staging classify_ingredient_types scrape_ckdhc scrape_naver_shopping scrape_cafe24 validate_product_images; do node --check "scripts/$f.mjs" || exit 1; done && echo ALL-OK
```

Expected: `ALL-OK`. 추가로 dry-run이 안전한 것 1개만 확인: `node scripts/scrape_naver_shopping.mjs --dry-run --limit=1` (외부 API 키 부재 시 생략하고 보고)

- [ ] **Step 3: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/enrich_products_from_staging.mjs web/scripts/classify_ingredient_types.mjs web/scripts/scrape_ckdhc.mjs web/scripts/scrape_naver_shopping.mjs web/scripts/scrape_cafe24.mjs web/scripts/validate_product_images.mjs && git commit -m "refactor(scripts): route service-role client creation through shared lib

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: staging import 트랜잭션 래핑 + 멱등성 문서

**Files:**
- Modify: `web/scripts/import_kr_staging_to_db.mjs` (importDataset 함수)
- Create: `web/scripts/README.md`

**Interfaces:**
- Consumes: postgres.js `sql.begin(async (tx) => ...)` — 트랜잭션 스코프 sql 인스턴스를 콜백 인자로 받음
- Produces: 없음

**설계 결정(문서에도 기록)**: 트랜잭션은 postgres.js 기반 스크립트에서만 가능하다. supabase-js(REST/PostgREST) 기반 import 5종은 프로토콜상 멀티-스테이트먼트 트랜잭션이 불가 — 이들은 멱등성(재실행 안전성) 문서화로 처방한다(계획 3-3의 "sql.begin + 멱등성 문서화" 이원 처방 그대로).

- [ ] **Step 1: importDataset을 데이터셋 단위 트랜잭션으로 래핑**

`importDataset` 내 실쓰기 부분(현재):

```js
  if (options.truncate) {
    await truncateTable(sql, dataset.tableName);
  }

  for (const batch of chunk(rows, options.batchSize)) {
    await upsertBatch(sql, dataset, batch, options.importBatch);
  }
```

→ 신규 (truncate와 upsert가 하나의 트랜잭션 — 중단 시 테이블이 비거나 부분 적재된 상태로 남지 않음):

```js
  await sql.begin(async (tx) => {
    if (options.truncate) {
      await truncateTable(tx, dataset.tableName);
    }

    for (const batch of chunk(rows, options.batchSize)) {
      await upsertBatch(tx, dataset, batch, options.importBatch);
    }
  });
```

트랜잭션 범위는 데이터셋 단위(전체 4종 묶음 아님) — 단일 거대 트랜잭션의 잠금/메모리 부담을 피하면서, "한 테이블은 온전히 이전 상태 아니면 온전히 새 상태"를 보장.

- [ ] **Step 2: 검증**

```bash
cd /Users/napler/projects/my-supple/web && node --check scripts/import_kr_staging_to_db.mjs && node scripts/import_kr_staging_to_db.mjs --dry-run
```

Expected: dry-run 정상(트랜잭션 경로는 미실행). **실제 트랜잭션 동작 확인(실 import)은 사용자 확인 후 별도 실행** — README와 최종 보고에 명기.

- [ ] **Step 3: `web/scripts/README.md` 작성**

```markdown
# Pipeline Scripts

파이프라인/관리 스크립트 안내. 모든 스크립트는 admin 트랙(service_role 또는
`DATABASE_URL`)으로 실 DB를 만진다. **실행 전 반드시 `--dry-run`(지원 시)으로
확인할 것.** npm wiring의 권위는 `web/package.json`의 scripts 항목.

## 공유 lib (`lib/`)

| 모듈 | 제공 |
|---|---|
| `env.mjs` | `loadEnv()`(web→root 순 .env.local/.env), `requireEnv(...keys)` |
| `supabase.mjs` | `getServiceRoleClient({cliFallback})`, `fetchAllRows()`, resolve* 헬퍼 |
| `batch.mjs` | `chunk(array, size)` |
| `http.mjs` | `fetchJson(url, opts)` — 429/5xx/네트워크/타임아웃 지수 백오프 재시도, `sleep` |
| `jsonl.mjs` | `readJsonl`(스트리밍), `readAllJsonl`, `appendJsonl`, `createJsonlWriter` |

## import 스크립트 멱등성 (scripts-review #10)

supabase-js(REST) 기반 스크립트는 프로토콜상 트랜잭션이 불가하다. 아래 표의
"중단 시" 열을 반드시 숙지할 것.

| 스크립트 | DB 접근 | 쓰기 패턴 | 멱등성 | 중단 시 |
|---|---|---|---|---|
| `import_kr_staging_to_db` | postgres.js | 데이터셋 단위 **트랜잭션**(truncate 옵션+upsert) | ✅ 재실행 안전 | 롤백됨 — 이전 상태 유지 |
| `import_kr_claims_to_supabase` | supabase-js | 순수 upsert (`claim_code`, `ingredient_id,claim_id,approval_country_code`) | ✅ 재실행 안전 | 부분 upsert — 재실행으로 수렴 |
| `import_kr_core_to_supabase` | supabase-js | delete(products, product_ingredients) 후 insert + ingredients upsert | ⚠️ 재실행으로 복구 | 부분 상태 — **완주될 때까지 재실행 필수** |
| `import_kr_dosage_to_supabase` | supabase-js | 전체 delete 후 insert (full refresh) | ⚠️ 재실행으로 복구 | 테이블 비었거나 부분 적재 — 완주 재실행 필수 |
| `import_kr_label_snapshots_to_supabase` | supabase-js | 전체 delete 후 insert | ⚠️ 재실행으로 복구 | 상동 |
| `import_kr_safety_to_supabase` | supabase-js | 전체 delete 후 insert | ⚠️ 재실행으로 복구 | 상동 |
| `enrich_products_from_staging` | supabase-js | row별 update/insert (`--limit`, 기본 50) | ✅ 점진·재실행 안전 | 다음 실행이 이어서 처리 |
| `classify_ingredient_types` | supabase-js | row별 update | ✅ 재실행 안전 | 상동 |

## 경로 규약

- 스크립트는 `web/scripts/`에서 실행 위치와 무관하게 동작해야 한다:
  `rootDir`는 `import.meta.url` 기준으로 계산하고 `process.cwd()`를 쓰지 않는다.
- 입출력 데이터는 repo 루트의 `tmp/` 아래 (`tmp/kr-gov/`, `tmp/kr-gov-clean/`).
```

(표 내용은 서베이 확정 사실 기준. Task 8 완료 후 KR gov 전처리 체인 스크립트 4종이 이 트리로 들어오면 "DB 접근: 없음(파일 변환)" 행을 추가할 것 — Task 8 Step 5에 포함)

- [ ] **Step 4: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/import_kr_staging_to_db.mjs web/scripts/README.md && git commit -m "feat(scripts): per-dataset transactions in staging import; document idempotency

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: 루트 scripts/ → web/scripts/ 단일 트리 통합

**Files:**
- Move(git mv): `scripts/{test_korean_gov_apis, normalize_kr_gov_dump, map_kr_ingredient_mentions, classify_kr_unresolved_mentions, promote_kr_active_candidate_mappings, fetch_dailymed_labels}.mjs` → `web/scripts/`
- Move(git mv): `scripts/fetch_pubmed_evidence.py` → `web/scripts/`
- Move(git mv): `scripts/archive/` → `web/scripts/archive/`
- Delete: `scripts/__pycache__/` (생성물)
- Modify: `web/package.json`, `CLAUDE.md`, `GEMINI.md`, `web/.env.local.example`, `web/scripts/README.md`

**Interfaces:**
- Consumes: `loadEnv()` (`./lib/env.mjs`)
- Produces: npm 명령 `gov:normalize:kr`, `gov:map:kr`, `gov:classify-mentions:kr`, `gov:promote:kr`; `gov:smoke:kr` 경로 갱신

- [ ] **Step 1: 파일 이동**

```bash
cd /Users/napler/projects/my-supple && git mv scripts/test_korean_gov_apis.mjs scripts/normalize_kr_gov_dump.mjs scripts/map_kr_ingredient_mentions.mjs scripts/classify_kr_unresolved_mentions.mjs scripts/promote_kr_active_candidate_mappings.mjs scripts/fetch_dailymed_labels.mjs scripts/fetch_pubmed_evidence.py web/scripts/ && git mv scripts/archive web/scripts/archive && rm -rf scripts/__pycache__ && rmdir scripts
```

- [ ] **Step 2: 이동한 .mjs 6개의 경로/env 규약 표준화**

각 파일에서 `process.cwd()` 기반 경로를 파일 위치 기준으로 교체. 공통 패턴(파일 상단):

```js
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..", "..");
```

파일별 적용 지점 (a0b543e 기준):
- `normalize_kr_gov_dump.mjs`: `inputDir`(L15, `tmp/kr-gov`)·`outputDir`(L16, `tmp/kr-gov-clean`)을 `path.join(rootDir, "tmp", "kr-gov")` 형태로
- `map_kr_ingredient_mentions.mjs`: `cleanDir`(L9)·출력 `mapped/` 경로(L18)를 rootDir 기준으로
- `classify_kr_unresolved_mentions.mjs`: 입력(L9–11)·출력(L18–19)을 rootDir 기준으로
- `promote_kr_active_candidate_mappings.mjs`: 입력(L9–14)·출력(L21)을 rootDir 기준으로
- `fetch_dailymed_labels.mjs`: `OUTPUT_PATH`(L15, `db/011_seed_dailymed_labels.sql`)를 `path.join(rootDir, "db", "011_seed_dailymed_labels.sql")`로
- `test_korean_gov_apis.mjs`: 인라인 env 파서(L7–57, cwd 기준·root 우선 순서) 전체 삭제 → `import { loadEnv } from "./lib/env.mjs"; loadEnv();` (후보 순서가 web 우선으로 바뀜 — 동일 키가 양쪽에 있으면 web/.env.local이 이김. 의도된 표준화이므로 보고에 명기)
- 스크립트 내 에러 메시지의 안내 경로 갱신: `map_kr_ingredient_mentions.mjs:14` "Run scripts/normalize_kr_gov_dump.mjs first" → "Run npm run gov:normalize:kr first" / `classify_kr_unresolved_mentions.mjs:14`의 map 안내 → "npm run gov:map:kr"
- 이동한 4개 전처리 스크립트의 JSONL 입출력을 lib으로 치환: 로컬 `readJsonl(filePath, onRecord)` 콜백형 → `for await (const row of readJsonl(file))` (`./lib/jsonl.mjs`), `createWriteStream` 수동 writer → `createJsonlWriter(filePath)` (`map:512, classify:394, promote:66, normalize:256` 부근). 치환이 구조 변경을 크게 요구하면(콜백 내부 상태 공유 등) 해당 파일은 경로 표준화만 하고 JSONL 치환은 보류 항목으로 보고

- [ ] **Step 3: fetch_pubmed_evidence.py 경로 고정**

파일 상단에:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
```

`open("db/009_seed_evidence.sql", "w")`(L297) → `open(ROOT / "db" / "009_seed_evidence.sql", "w")`. 파일 내 다른 cwd-상대 경로도 같은 방식으로 조사·치환. `NCBI_API_KEY` env 필수 로직(L15–17)은 그대로 유지.

- [ ] **Step 4: web/package.json wiring 갱신**

```json
    "gov:smoke:kr": "node scripts/test_korean_gov_apis.mjs",
    "gov:normalize:kr": "node scripts/normalize_kr_gov_dump.mjs",
    "gov:map:kr": "node scripts/map_kr_ingredient_mentions.mjs",
    "gov:classify-mentions:kr": "node scripts/classify_kr_unresolved_mentions.mjs",
    "gov:promote:kr": "node scripts/promote_kr_active_candidate_mappings.mjs",
```

(`gov:smoke:kr`는 기존 `node ../scripts/...`의 경로만 교체, 나머지 4개는 신규 — `gov:backfill:kr` 앞에 배치)

- [ ] **Step 5: 문서 갱신**

- `CLAUDE.md`(프로젝트): "KR Government Data Pipeline" 명령 목록에 신규 4개 추가, "스크립트는 `web/scripts/` 단일 트리(공유 lib은 `web/scripts/lib/`)" 한 줄 추가
- `GEMINI.md`: L29/33의 `scripts/` 설명과 L67 `python3 scripts/fetch_pubmed_evidence.py` → `python3 web/scripts/fetch_pubmed_evidence.py`, L89의 매핑 설명 갱신
- `web/.env.local.example:40`: 주석 경로 `scripts/fetch_pubmed_evidence.py` → `web/scripts/fetch_pubmed_evidence.py`
- `web/scripts/README.md`: 전처리 체인 4종(normalize→map→classify-mentions→promote, DB 접근 없음·파일 변환)과 `test_korean_gov_apis`, `fetch_dailymed_labels`, `fetch_pubmed_evidence.py` 행 추가

- [ ] **Step 6: 검증**

```bash
cd /Users/napler/projects/my-supple && ls scripts 2>&1; cd /Users/napler/projects/my-supple/web && for f in test_korean_gov_apis normalize_kr_gov_dump map_kr_ingredient_mentions classify_kr_unresolved_mentions promote_kr_active_candidate_mappings fetch_dailymed_labels; do node --check "scripts/$f.mjs" || exit 1; done && python3 -m py_compile scripts/fetch_pubmed_evidence.py && echo ALL-OK
```

Expected: `ls scripts` → "No such file or directory", 이어서 `ALL-OK`. env 키가 있으면 `npm run gov:smoke:kr`(read-only 연결 확인)도 실행. 전처리 4종의 실제 실행은 tmp/ 입력·출력 덮어쓰기가 있으므로 **하지 않는다**.

- [ ] **Step 7: 전체 게이트 + 커밋**

```bash
cd /Users/napler/projects/my-supple/web && npm test && npx tsc --noEmit && npm run build && npm run lint
cd /Users/napler/projects/my-supple && git add web/scripts/test_korean_gov_apis.mjs web/scripts/normalize_kr_gov_dump.mjs web/scripts/map_kr_ingredient_mentions.mjs web/scripts/classify_kr_unresolved_mentions.mjs web/scripts/promote_kr_active_candidate_mappings.mjs web/scripts/fetch_dailymed_labels.mjs web/scripts/fetch_pubmed_evidence.py web/scripts/archive web/scripts/README.md web/package.json CLAUDE.md GEMINI.md web/.env.local.example && git status --short && git commit -m "refactor(scripts): unify root scripts/ into web/scripts single tree

- move 7 root scripts + archive into web/scripts
- path convention: rootDir from import.meta.url, no process.cwd()
- wire preprocessing chain as npm scripts (gov:normalize/map/classify-mentions/promote)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(`git status --short`로 `git mv` 잔여 rename 항목이 스테이징됐는지 확인 — rename은 `git add` 경로 지정으로 old/new 모두 잡히지만, 누락이 보이면 해당 경로를 명시적으로 add)

---

## 범위 제외·보류 (보고에 포함할 것)

- **3-4 Drizzle 점진 도입** — 계획상 선택·후순위, 이번 브랜치에서 하지 않음 (Phase 4 이후 재평가)
- CLI 플래그 파싱 3패턴 통일 — scripts-review 부수 발견이나 Phase 3 범위(#1–#5, #9, #10) 밖. 보류
- supabase-js import 4종(core/dosage/label/safety)의 delete→insert를 트랜잭션화하려면 postgres.js 전환이 필요 — 3-4와 함께 재평가
- `apply_migration.mjs`는 이미 lib/env.mjs 사용·단독 postgres 실행기로 변경 불요
- 실제 import 실행(트랜잭션 실동작 확인 포함)은 사용자 승인 후

## 최종 검증 (finishing 전)

1. `grep -rn "function parseEnvFile\|function chunk(\|async function fetchAllRows" web/scripts --include="*.mjs" | grep -v lib/` → 출력 없음
2. 게이트 전체 통과 + `npm run verify:sample`(env 있을 때) 기존 판정 유지
3. `npm run gov:smoke:kr` 경로 동작 (env 있을 때)
