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
