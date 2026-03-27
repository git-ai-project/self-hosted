#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RELEASE="${HELM_RELEASE:-git-ai-self-hosting}"
NAMESPACE="${HELM_NAMESPACE:-git-ai}"
TIMEOUT="${WAIT_TIMEOUT_SECONDS:-600s}"

echo "Waiting for ClickHouse..."
kubectl wait -n "$NAMESPACE" --for=condition=ready "pod" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=clickhouse" --timeout="$TIMEOUT"

echo "Waiting for Postgres..."
kubectl wait -n "$NAMESPACE" --for=condition=ready "pod" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/name=postgresql" --timeout="$TIMEOUT"

echo "Waiting for Valkey..."
kubectl wait -n "$NAMESPACE" --for=condition=ready "pod" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/name=valkey" --timeout="$TIMEOUT"

if kubectl get job -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=postgres" --no-headers 2>/dev/null | rg -q "."; then
  echo "Waiting for postgres migration jobs..."
  kubectl wait -n "$NAMESPACE" --for=condition=complete job -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=postgres" --timeout="$TIMEOUT"
fi

if kubectl get job -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=clickhouse" --no-headers 2>/dev/null | rg -q "."; then
  echo "Waiting for clickhouse migration jobs..."
  kubectl wait -n "$NAMESPACE" --for=condition=complete job -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=clickhouse" --timeout="$TIMEOUT"
fi

echo "Waiting for web and worker deployments..."
WEB_DEPLOYMENT="$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=web" -o jsonpath='{.items[0].metadata.name}')"
WORKER_DEPLOYMENT="$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=worker" -o jsonpath='{.items[0].metadata.name}')"

if [[ -z "$WEB_DEPLOYMENT" || -z "$WORKER_DEPLOYMENT" ]]; then
  echo "Could not find web/worker deployments for release $RELEASE in namespace $NAMESPACE" >&2
  exit 1
fi

kubectl rollout status -n "$NAMESPACE" "deployment/${WEB_DEPLOYMENT}" --timeout="$TIMEOUT"
kubectl rollout status -n "$NAMESPACE" "deployment/${WORKER_DEPLOYMENT}" --timeout="$TIMEOUT"

echo "Stack is ready"
