#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source ./.env
set +a

exec docker compose exec db psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}"
