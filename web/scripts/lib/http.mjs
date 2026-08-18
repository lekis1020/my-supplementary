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
