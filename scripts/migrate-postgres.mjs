#!/usr/bin/env node
import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { migrate } from "drizzle-orm/node-postgres/migrator";

function trimEnv(value) {
  return value?.trim() || "";
}

function resolveSslMode() {
  return (
    trimEnv(process.env.DB_SSLMODE) ||
    trimEnv(process.env.DB_SSL_MODE) ||
    trimEnv(process.env.PGSSLMODE)
  );
}

function appendSslMode(url, sslMode) {
  if (!sslMode) {
    return url;
  }

  if (/[?&]sslmode=/i.test(url)) {
    return url;
  }

  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}sslmode=${encodeURIComponent(sslMode)}`;
}

function resolveDatabaseUrl() {
  const sslMode = resolveSslMode();
  const direct = trimEnv(process.env.DATABASE_URL);
  if (direct) {
    return appendSslMode(direct, sslMode);
  }

  const components = {
    DB_HOST: trimEnv(process.env.DB_HOST),
    DB_PORT: trimEnv(process.env.DB_PORT),
    DB_NAME: trimEnv(process.env.DB_NAME),
    DB_USERNAME: trimEnv(process.env.DB_USERNAME),
    DB_PASSWORD: trimEnv(process.env.DB_PASSWORD),
  };

  const keys = Object.keys(components);
  const hasAny = keys.some((key) => components[key]);
  if (!hasAny) {
    throw new Error(
      "DATABASE_URL is not set. Provide DATABASE_URL or DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASSWORD.",
    );
  }

  const missing = keys.filter((key) => !components[key]);
  if (missing.length > 0) {
    throw new Error(
      `DATABASE_URL is not set and DB_* vars are incomplete (missing: ${missing.join(", ")})`,
    );
  }

  const baseUrl = `postgresql://${encodeURIComponent(components.DB_USERNAME)}:${encodeURIComponent(components.DB_PASSWORD)}@${components.DB_HOST}:${components.DB_PORT}/${encodeURIComponent(components.DB_NAME)}`;
  return appendSslMode(baseUrl, sslMode);
}

const databaseUrl = resolveDatabaseUrl();

const migrationsDir = "/app/migrations/postgres";
const migrationsTable =
  process.env.POSTGRES_MIGRATIONS_TABLE || "git_ai_schema_migrations_pg";
const migrationsSchema =
  process.env.POSTGRES_MIGRATIONS_SCHEMA || "public";
const readyMaxAttempts = Number.parseInt(
  process.env.POSTGRES_READY_MAX_ATTEMPTS || "120",
  10,
);
const readySleepMs = Number.parseInt(
  process.env.POSTGRES_READY_SLEEP_MS || "2000",
  10,
);

if (!Number.isFinite(readyMaxAttempts) || readyMaxAttempts <= 0) {
  throw new Error("POSTGRES_READY_MAX_ATTEMPTS must be a positive integer");
}
if (!Number.isFinite(readySleepMs) || readySleepMs <= 0) {
  throw new Error("POSTGRES_READY_SLEEP_MS must be a positive integer");
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitForDatabase(pool) {
  for (let attempt = 1; attempt <= readyMaxAttempts; attempt += 1) {
    try {
      await pool.query("SELECT 1");
      if (attempt > 1) {
        console.log(`Postgres became ready on attempt ${attempt}.`);
      }
      return;
    } catch (error) {
      if (attempt === readyMaxAttempts) {
        const reason = error instanceof Error ? error.message : String(error);
        throw new Error(
          `Postgres did not become ready after ${readyMaxAttempts} attempts: ${reason}`,
        );
      }
      console.log(
        `Waiting for Postgres (attempt ${attempt}/${readyMaxAttempts})...`,
      );
      await sleep(readySleepMs);
    }
  }
}

async function main() {
  const pool = new Pool({
    connectionString: databaseUrl,
    max: 1,
  });

  try {
    await waitForDatabase(pool);
    const db = drizzle(pool);
    console.log(`Running Drizzle migrations from ${migrationsDir}`);
    await migrate(db, {
      migrationsFolder: migrationsDir,
      migrationsTable,
      migrationsSchema,
    });
    console.log("Postgres migrations complete.");
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
