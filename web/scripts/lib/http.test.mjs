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
