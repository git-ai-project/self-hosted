#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/grant-admin.sh <user-email-or-id>" >&2
  exit 1
fi

IDENTIFIER="$1"

set -a
# shellcheck disable=SC1091
source ./.env
set +a

UPDATED_COUNT="$({
  docker compose exec -T db psql \
    -U "${POSTGRES_USER:-postgres}" \
    -d "${POSTGRES_DB:-postgres}" \
    -v ident="$IDENTIFIER" \
    -t -A <<'SQL'
WITH updated AS (
  UPDATE "user"
  SET role = 'admin'
  WHERE id = :'ident' OR email = :'ident'
  RETURNING 1
)
SELECT count(*) FROM updated;
SQL
} | tr -d '[:space:]')"

if [[ "$UPDATED_COUNT" == "0" ]]; then
  echo "No user matched '$IDENTIFIER'." >&2
  exit 1
fi

echo "Updated $UPDATED_COUNT user(s) to role=admin"
