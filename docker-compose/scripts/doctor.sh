#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for cmd in docker task node; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f .env ]]; then
  echo ".env is missing. Run: task init" >&2
  exit 1
fi

if [[ ! -f generated/scm.env ]]; then
  echo "generated/scm.env is missing. Run: task scm:configure" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source ./.env
# shellcheck disable=SC1091
source ./generated/scm.env
set +a

required_env=(
  WEB_BASE_URL
  BETTER_AUTH_URL
  LICENSE_KEY
  BETTER_AUTH_SECRET
  WORKER_JWT_SECRET
  WEB_INTERNAL_API_KEY
  SCM_WEBHOOK_SECRET_KEY
  STORAGE_BACKEND
  LOCAL_STORAGE_PATH
  ANALYZE_BATCH_PROVIDER
  DATABASE_URL
  REDIS_URL
  CLICKHOUSE_HTTP_URL
  CLICKHOUSE_USER
  CLICKHOUSE_PASSWORD
  CLICKHOUSE_DATABASE
)

for key in "${required_env[@]}"; do
  value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "Missing required env var: $key" >&2
    exit 1
  fi
done

node - <<'NODE'
const raw = process.env.SCM_APPS_CONFIG || "";
let parsed;
try {
  parsed = JSON.parse(raw);
} catch (error) {
  console.error(`SCM_APPS_CONFIG is invalid JSON: ${error.message}`);
  process.exit(1);
}
if (!Array.isArray(parsed) || parsed.length === 0) {
  console.error("SCM_APPS_CONFIG must be a non-empty JSON array");
  process.exit(1);
}
const required = ["provider", "domain", "slug", "app_id", "webhook_secret", "client_id", "client_secret"];
const supportedProviders = new Set(["github", "gitlab", "bitbucket"]);
const seenSlugs = new Set();
for (const [index, app] of parsed.entries()) {
  if (typeof app !== "object" || !app) {
    console.error(`SCM_APPS_CONFIG[${index}] must be an object`);
    process.exit(1);
  }
  for (const field of required) {
    if (typeof app[field] !== "string" || app[field].trim() === "") {
      console.error(`SCM_APPS_CONFIG[${index}] is missing ${field}`);
      process.exit(1);
    }
  }
  if (!supportedProviders.has(app.provider.trim().toLowerCase())) {
    console.error(
      `SCM_APPS_CONFIG[${index}] has unsupported provider '${app.provider}'. Supported: github, gitlab, bitbucket`
    );
    process.exit(1);
  }
  const slug = app.slug.trim();
  if (seenSlugs.has(slug)) {
    console.error(`SCM_APPS_CONFIG has duplicate slug '${slug}'`);
    process.exit(1);
  }
  seenSlugs.add(slug);
}

const analyzeProvider = (process.env.ANALYZE_BATCH_PROVIDER || "").trim().toLowerCase();
const supportedAnalyzeProviders = new Set(["local", "aws", "k8s", "gcp", "azure"]);
if (!supportedAnalyzeProviders.has(analyzeProvider)) {
  console.error(
    `ANALYZE_BATCH_PROVIDER must be one of: local, aws, k8s, gcp, azure (got '${process.env.ANALYZE_BATCH_PROVIDER || ""}')`
  );
  process.exit(1);
}
if (analyzeProvider === "gcp" || analyzeProvider === "azure") {
  console.error(
    `ANALYZE_BATCH_PROVIDER=${analyzeProvider} is not implemented yet in this build. Use 'local', 'aws', or 'k8s'.`
  );
  process.exit(1);
}
if (analyzeProvider === "aws") {
  for (const key of ["ANALYZE_BATCH_AWS_JOB_QUEUE", "ANALYZE_BATCH_AWS_JOB_DEFINITION"]) {
    const value = process.env[key] || "";
    if (!value.trim()) {
      console.error(`${key} is required when ANALYZE_BATCH_PROVIDER=aws`);
      process.exit(1);
    }
  }
}

const storageBackend = (process.env.STORAGE_BACKEND || "").trim().toLowerCase();
const supportedStorageBackends = new Set(["local", "filesystem", "aws", "azure", "gcp"]);
if (!supportedStorageBackends.has(storageBackend)) {
  console.error(
    `STORAGE_BACKEND must be one of: local, filesystem, aws, azure, gcp (got '${process.env.STORAGE_BACKEND || ""}')`
  );
  process.exit(1);
}
if (storageBackend === "local" || storageBackend === "filesystem") {
  if (!(process.env.LOCAL_STORAGE_PATH || "").trim()) {
    console.error("LOCAL_STORAGE_PATH is required when STORAGE_BACKEND=local/filesystem");
    process.exit(1);
  }
}
if (storageBackend === "aws") {
  if (!(process.env.WORKER_STORAGE_BUCKET_NAME || "").trim()) {
    console.error("WORKER_STORAGE_BUCKET_NAME is required when STORAGE_BACKEND=aws");
    process.exit(1);
  }
}
if (storageBackend === "azure") {
  if (!(process.env.AZURE_STORAGE_CONNECTION_STRING || "").trim()) {
    console.error("AZURE_STORAGE_CONNECTION_STRING is required when STORAGE_BACKEND=azure");
    process.exit(1);
  }
}
if (storageBackend === "gcp") {
  const gcpBucket =
    (process.env.GCP_STORAGE_BUCKET || "").trim() ||
    (process.env.WORKER_STORAGE_BUCKET_NAME || "").trim();
  if (!gcpBucket) {
    console.error(
      "GCP_STORAGE_BUCKET (or WORKER_STORAGE_BUCKET_NAME) is required when STORAGE_BACKEND=gcp"
    );
    process.exit(1);
  }
}

const dashboardEnabledRaw = (process.env.BULLMQ_DASHBOARD_ENABLED || "true").trim().toLowerCase();
const dashboardEnabled = dashboardEnabledRaw === "1" || dashboardEnabledRaw === "true";
if (dashboardEnabled) {
  const portRaw = (process.env.BULLMQ_DASHBOARD_PORT || "3001").trim();
  const port = Number.parseInt(portRaw, 10);
  if (!Number.isFinite(port) || port <= 0 || port > 65535) {
    console.error(`BULLMQ_DASHBOARD_PORT must be a valid TCP port (got '${portRaw}')`);
    process.exit(1);
  }
}
NODE


docker compose config >/dev/null

echo "Doctor checks passed"
