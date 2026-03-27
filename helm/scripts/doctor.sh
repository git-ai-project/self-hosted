#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for cmd in helm kubectl task node; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

VALUES_FILE="${HELM_VALUES_FILE:-generated/values.local.yaml}"
SCM_FILE="${SCM_APPS_FILE:-generated/scm-apps.generated.json}"
RELEASE="${HELM_RELEASE:-git-ai-self-hosting}"
NAMESPACE="${HELM_NAMESPACE:-git-ai}"

if [[ ! -f "$VALUES_FILE" ]]; then
  echo "Missing values file: $VALUES_FILE (run: task init)" >&2
  exit 1
fi

if [[ ! -f "$SCM_FILE" ]]; then
  echo "Missing SCM config file: $SCM_FILE (run: task scm:configure)" >&2
  exit 1
fi

SCM_FILE="$SCM_FILE" node - <<'NODE'
const fs = require("fs");
const path = process.env.SCM_FILE;
const raw = fs.readFileSync(path, "utf8").trim();

let parsed;
try {
  parsed = JSON.parse(raw || "[]");
} catch (error) {
  console.error(`SCM config is invalid JSON (${path}): ${error.message}`);
  process.exit(1);
}

if (!Array.isArray(parsed) || parsed.length === 0) {
  console.error("SCM config must be a non-empty JSON array");
  process.exit(1);
}

const required = [
  "provider",
  "domain",
  "slug",
  "app_id",
  "webhook_secret",
  "client_id",
  "client_secret",
];
const supportedProviders = new Set(["github", "gitlab", "bitbucket"]);
const seenSlugs = new Set();

for (const [index, app] of parsed.entries()) {
  if (typeof app !== "object" || !app) {
    console.error(`SCM config entry ${index} must be an object`);
    process.exit(1);
  }
  for (const field of required) {
    if (typeof app[field] !== "string" || app[field].trim() === "") {
      console.error(`SCM config entry ${index} is missing ${field}`);
      process.exit(1);
    }
  }
  const provider = app.provider.trim().toLowerCase();
  if (!supportedProviders.has(provider)) {
    console.error(
      `SCM config entry ${index} has unsupported provider '${app.provider}'`
    );
    process.exit(1);
  }
  const slug = app.slug.trim();
  if (seenSlugs.has(slug)) {
    console.error(`SCM config has duplicate slug '${slug}'`);
    process.exit(1);
  }
  seenSlugs.add(slug);
}
NODE

helm dependency update . >/dev/null

helm lint . >/dev/null
helm lint . \
  -f values.yaml \
  -f "$VALUES_FILE" \
  --set-file secrets.scmAppsConfigJson="$SCM_FILE" >/dev/null

helm template "$RELEASE" . \
  --namespace "$NAMESPACE" \
  -f values.yaml \
  -f "$VALUES_FILE" \
  --set-file secrets.scmAppsConfigJson="$SCM_FILE" >/dev/null

./scripts/test-render.sh

echo "Doctor checks passed"
