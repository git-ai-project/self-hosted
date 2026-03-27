#!/usr/bin/env sh
set -eu

CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-clickhouse}"
CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-9000}"
CLICKHOUSE_USER="${CLICKHOUSE_USER:-gitai}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-gitai}"
CLICKHOUSE_DATABASE="${CLICKHOUSE_DATABASE:-default}"
MIGRATIONS_PATH="/app/migrations/clickhouse"

if [ ! -d "$MIGRATIONS_PATH" ]; then
  echo "Migrations directory not found: $MIGRATIONS_PATH" >&2
  exit 1
fi

ch() {
  clickhouse-client \
    --host "$CLICKHOUSE_HOST" \
    --port "$CLICKHOUSE_PORT" \
    --user "$CLICKHOUSE_USER" \
    --password "$CLICKHOUSE_PASSWORD" \
    "$@"
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

has_executable_sql() {
  awk '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (line == "" || index(line, "--") == 1) {
        next
      }
      found = 1
      exit
    }
    END {
      exit found ? 0 : 1
    }
  ' "$1"
}

echo "Waiting for ClickHouse at $CLICKHOUSE_HOST:$CLICKHOUSE_PORT..."
tries=0
until ch --query "SELECT 1" >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -gt 120 ]; then
    echo "ClickHouse did not become ready in time" >&2
    exit 1
  fi
  sleep 1
done

ch --query "CREATE DATABASE IF NOT EXISTS ${CLICKHOUSE_DATABASE}" </dev/null
ch --database "$CLICKHOUSE_DATABASE" --query "
  CREATE TABLE IF NOT EXISTS git_ai_schema_migrations (
    filename String,
    checksum String,
    applied_at DateTime DEFAULT now()
  ) ENGINE = MergeTree ORDER BY filename
" </dev/null

applied=0
skipped=0

tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT
find "$MIGRATIONS_PATH" -maxdepth 1 -type f -name '*.sql' | sort > "$tmp_list"

while IFS= read -r file; do
  filename="$(basename "$file")"
  checksum="$(hash_file "$file")"

  existing_checksum="$(ch --database "$CLICKHOUSE_DATABASE" --query "SELECT checksum FROM git_ai_schema_migrations WHERE filename = '${filename}' LIMIT 1 FORMAT TSVRaw" </dev/null || true)"

  if [ -n "$existing_checksum" ] && [ "$existing_checksum" != "$checksum" ]; then
    echo "Checksum mismatch for already applied migration: $filename" >&2
    exit 1
  fi

  if [ -n "$existing_checksum" ]; then
    skipped=$((skipped + 1))
    echo "Skipping $filename (already applied)"
    continue
  fi

  if ! has_executable_sql "$file"; then
    skipped=$((skipped + 1))
    echo "Recording $filename (no executable SQL)"
    ch --database "$CLICKHOUSE_DATABASE" --query "
      INSERT INTO git_ai_schema_migrations (filename, checksum) VALUES ('${filename}', '${checksum}')
    " </dev/null
    continue
  fi

  echo "Applying $filename"
  ch --database "$CLICKHOUSE_DATABASE" --multiquery < "$file"
  ch --database "$CLICKHOUSE_DATABASE" --query "
    INSERT INTO git_ai_schema_migrations (filename, checksum) VALUES ('${filename}', '${checksum}')
  " </dev/null
  applied=$((applied + 1))
done < "$tmp_list"

echo "ClickHouse migrations complete. Applied: $applied, skipped: $skipped"
