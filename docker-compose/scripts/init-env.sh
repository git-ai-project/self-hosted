#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to generate secrets" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

mkdir -p generated config

if [[ ! -f generated/scm.env ]]; then
  echo "SCM_APPS_CONFIG='[]'" > generated/scm.env
  echo "Created generated/scm.env placeholder"
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

set_if_empty BETTER_AUTH_SECRET "$(rand_base64)"
set_if_empty WORKER_JWT_SECRET "$(rand_hex64)"
set_if_empty WEB_INTERNAL_API_KEY "$(rand_hex64)"
set_if_empty SCM_WEBHOOK_SECRET_KEY "$(rand_hex64)"

echo "Initialized .env and generated defaults"
echo "Next: run 'task scm:configure'"
