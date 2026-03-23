import postgres from "postgres";

function createDb() {
  return postgres(process.env.DATABASE_URL!, {
    max: 3,
    idle_timeout: 20,
    connect_timeout: 10,
  });
}

const globalForDb = globalThis as unknown as {
  adminDb: ReturnType<typeof postgres> | undefined;
};

export const adminDb =
  globalForDb.adminDb ?? createDb();

if (process.env.NODE_ENV !== "production") {
  globalForDb.adminDb = adminDb;
}
