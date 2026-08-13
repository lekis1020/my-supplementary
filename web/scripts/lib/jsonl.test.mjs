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
