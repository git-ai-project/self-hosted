#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to generate secrets" >&2
  exit 1
fi

created_env=false
if [[ ! -f .env ]]; then
  if [[ "${1:-}" == --cube-secret-only ]]; then
    echo ".env is missing. Run: task init" >&2
    exit 1
  fi
  cp .env.example .env
  created_env=true
  echo "Created .env from .env.example"
fi

is_empty_value() {
  local raw="$1"
  local trimmed="${raw//[[:space:]]/}"
  trimmed="${trimmed%\"}"
  trimmed="${trimmed#\"}"
  [[ -z "$trimmed" ]]
}

set_if_empty() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  local found=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$key="* ]]; then
      found=1
      local current="${line#*=}"
      if is_empty_value "$current"; then
        echo "$key=$value" >> "$tmp"
      else
        echo "$line" >> "$tmp"
      fi
    else
      echo "$line" >> "$tmp"
    fi
  done < .env

  if [[ "$found" -eq 0 ]]; then
    echo "$key=$value" >> "$tmp"
  fi

  mv "$tmp" .env
}

rand_base64() {
  openssl rand -base64 32 | tr -d '\n'
}

rand_hex64() {
  openssl rand -hex 32
}

cube_secret_status() {
  # Use the Compose parser so quoted, interpolated and multiline values are preserved.
  docker compose -f - config --format json <<'YAML' | node -e '
    const { createHash } = require("node:crypto");
    const config = JSON.parse(require("node:fs").readFileSync(0, "utf8"));
    const secret = config.services.web.environment?.CUBEJS_API_SECRET ?? "";
    // SHA-256 of the retired shared Cube signing key.
    const retiredKeyHash = "f794e07b81e67aa00be73bc516734857d1ba433d63df2d525eeacec92f9be68e";
    const hash = createHash("sha256").update(secret).digest("hex");
    process.stdout.write(secret.replace(/\s/g, "").length >= 32 && hash !== retiredKeyHash ? "valid" : "invalid");
  '
services:
  web:
    image: busybox
    env_file: [./.env]
YAML
}

ensure_cube_secret() {
  local secret status tmp
  if [[ "$created_env" == true ]] || ! grep -qF CUBEJS_API_SECRET .env; then
    secret="$(rand_hex64)"
    set_if_empty CUBEJS_API_SECRET "$secret"
    return
  fi

  status="$(cube_secret_status)"
  if [[ "$status" == valid ]]; then
    return
  fi

  secret="$(rand_hex64)"
  tmp="$(mktemp .env.XXXXXX)"
  cat .env > "$tmp"
  # Compose uses the last assignment. Leave other entries and quoting intact.
  printf '\nCUBEJS_API_SECRET=%s\n' "$secret" >> "$tmp"
  mv "$tmp" .env
}

ensure_cube_secret
if [[ "${1:-}" == --cube-secret-only ]]; then
  exit 0
fi

mkdir -p generated config

if [[ ! -f generated/scm.env ]]; then
  echo "SCM_APPS_CONFIG='[]'" > generated/scm.env
  echo "Created generated/scm.env placeholder"
fi

set_if_empty BETTER_AUTH_SECRET "$(rand_base64)"
set_if_empty WORKER_JWT_SECRET "$(rand_hex64)"
set_if_empty WEB_INTERNAL_API_KEY "$(rand_hex64)"
set_if_empty SCM_WEBHOOK_SECRET_KEY "$(rand_hex64)"

echo "Initialized .env and generated defaults"
echo "Next: run 'task scm:configure'"
