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
