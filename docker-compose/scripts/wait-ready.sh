#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-300}"
DEADLINE=$((SECONDS + TIMEOUT_SECONDS))

get_container_id() {
  docker compose ps -a -q "$1" 2>/dev/null || true
}

get_state_value() {
  local container_id="$1"
  local template="$2"
  docker inspect -f "$template" "$container_id" 2>/dev/null || true
}

wait_for_migrator_success() {
  local service="$1"
  while true; do
    if (( SECONDS > DEADLINE )); then
      echo "Timed out waiting for ${service} to complete successfully" >&2
      return 1
    fi

    local container_id
    container_id="$(get_container_id "$service")"
    if [[ -z "$container_id" ]]; then
      sleep 2
      continue
    fi

    local status
    status="$(get_state_value "$container_id" "{{.State.Status}}")"
    local exit_code
    exit_code="$(get_state_value "$container_id" "{{.State.ExitCode}}")"

    if [[ "$status" == "exited" && "$exit_code" == "0" ]]; then
      return 0
    fi

    if [[ "$status" == "exited" && "$exit_code" != "0" ]]; then
      echo "${service} exited with code ${exit_code}" >&2
      docker compose logs "$service" || true
      return 1
    fi

    sleep 2
  done
}

wait_for_running_service() {
  local service="$1"
  local require_health="${2:-false}"
  while true; do
    if (( SECONDS > DEADLINE )); then
      echo "Timed out waiting for ${service} to become ready" >&2
      return 1
    fi

    local container_id
    container_id="$(get_container_id "$service")"
    if [[ -z "$container_id" ]]; then
      sleep 2
      continue
    fi

    local status
    status="$(get_state_value "$container_id" "{{.State.Status}}")"
    if [[ "$status" != "running" ]]; then
      sleep 2
      continue
    fi

    if [[ "$require_health" == "false" ]]; then
      return 0
    fi

    local health
    health="$(get_state_value "$container_id" "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}")"
    if [[ "$health" == "healthy" || "$health" == "none" ]]; then
      return 0
    fi

    sleep 2
  done
}

echo "Waiting for migrators..."
wait_for_migrator_success "migrator-postgres"
wait_for_migrator_success "migrator-clickhouse"

echo "Waiting for app services..."
wait_for_running_service "web" "true"
wait_for_running_service "worker" "false"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source ./.env
  set +a
fi

if command -v curl >/dev/null 2>&1; then
  primary_base="${WEB_BASE_URL:-http://localhost:3000}"
  primary_base="${primary_base%/}"
  primary_url="${primary_base}/api/health"

  echo "Checking health endpoint: ${primary_url}"
  if ! curl -fsS --max-time 10 "${primary_url}" >/dev/null; then
    fallback_url="http://localhost:3000/api/health"
    if [[ "${primary_url}" != "${fallback_url}" ]]; then
      echo "Primary health endpoint failed; retrying with ${fallback_url}"
      curl -fsS --max-time 10 "${fallback_url}" >/dev/null
    else
      return 1
    fi
  fi
fi

echo "Stack is ready."
