#!/usr/bin/env sh
set -eu

CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-clickhouse}"
CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-9000}"
CLICKHOUSE_USER="${CLICKHOUSE_USER:-gitai}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-gitai}"

ch() {
  clickhouse-client \
    --host "$CLICKHOUSE_HOST" \
    --port "$CLICKHOUSE_PORT" \
    --user "$CLICKHOUSE_USER" \
    --password "$CLICKHOUSE_PASSWORD" \
    "$@"
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

echo "Cleaning up ClickHouse system log tables..."

ch --multiquery --query "
  TRUNCATE TABLE IF EXISTS system.trace_log;
  TRUNCATE TABLE IF EXISTS system.text_log;
  TRUNCATE TABLE IF EXISTS system.metric_log;
  TRUNCATE TABLE IF EXISTS system.asynchronous_metric_log;
  TRUNCATE TABLE IF EXISTS system.query_thread_log;
  TRUNCATE TABLE IF EXISTS system.processors_profile_log;
  TRUNCATE TABLE IF EXISTS system.part_log;
  TRUNCATE TABLE IF EXISTS system.session_log;
  TRUNCATE TABLE IF EXISTS system.opentelemetry_span_log;
  TRUNCATE TABLE IF EXISTS system.asynchronous_insert_log;
  TRUNCATE TABLE IF EXISTS system.error_log;
  DROP TABLE IF EXISTS system.trace_log_0;
  DROP TABLE IF EXISTS system.text_log_0;
  DROP TABLE IF EXISTS system.metric_log_0;
  DROP TABLE IF EXISTS system.asynchronous_metric_log_0;
  DROP TABLE IF EXISTS system.query_thread_log_0;
  DROP TABLE IF EXISTS system.processors_profile_log_0;
  DROP TABLE IF EXISTS system.part_log_0;
  DROP TABLE IF EXISTS system.session_log_0;
  DROP TABLE IF EXISTS system.opentelemetry_span_log_0;
  DROP TABLE IF EXISTS system.asynchronous_insert_log_0;
  DROP TABLE IF EXISTS system.error_log_0;
"

echo "System log cleanup complete."
