#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/grant-admin.sh <user-email-or-id>" >&2
  exit 1
fi

IDENTIFIER="$1"
RELEASE="${HELM_RELEASE:-git-ai-self-hosting}"
NAMESPACE="${HELM_NAMESPACE:-git-ai}"
POSTGRES_SECRET="${POSTGRES_SECRET_NAME:-${RELEASE}-postgresql}"
APP_DB_NAME="${APP_DB_NAME:-gitai}"

decode_base64() {
  if base64 --decode </dev/null >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

POD="$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/name=postgresql" -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$POD" ]]; then
  echo "Could not find PostgreSQL pod for release $RELEASE" >&2
  exit 1
fi

POSTGRES_PASSWORD="$(kubectl get secret -n "$NAMESPACE" "$POSTGRES_SECRET" -o jsonpath='{.data.postgres-password}' | decode_base64)"

UPDATED_COUNT="$({
  kubectl exec -n "$NAMESPACE" "$POD" -- bash -lc "PGPASSWORD='${POSTGRES_PASSWORD}' psql -h 127.0.0.1 -U postgres -d '${APP_DB_NAME}' -v ident='${IDENTIFIER}' -t -A <<'SQL'
WITH updated AS (
  UPDATE \"user\"
  SET role = 'admin'
  WHERE id = :'ident' OR email = :'ident'
  RETURNING 1
)
SELECT count(*) FROM updated;
SQL"
} | tr -d '[:space:]')"

if [[ "$UPDATED_COUNT" == "0" ]]; then
  echo "No user matched '$IDENTIFIER'." >&2
  exit 1
fi

echo "Updated $UPDATED_COUNT user(s) to role=admin"
