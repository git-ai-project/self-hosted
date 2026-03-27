#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RELEASE="${HELM_RELEASE:-git-ai-self-hosting}"
NAMESPACE="${HELM_NAMESPACE:-git-ai}"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
  exit 0
fi

case "$TARGET" in
  web)
    DEPLOYMENT="$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=web" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$DEPLOYMENT" ]]; then
      echo "Web deployment not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" -f "deployment/${DEPLOYMENT}"
    ;;
  worker)
    DEPLOYMENT="$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=worker" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$DEPLOYMENT" ]]; then
      echo "Worker deployment not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" -f "deployment/${DEPLOYMENT}"
    ;;
  clickhouse)
    POD="$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=clickhouse" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$POD" ]]; then
      echo "ClickHouse pod not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" -f "$POD"
    ;;
  migrator-postgres)
    JOB="$(kubectl get job -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=postgres" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$JOB" ]]; then
      echo "Postgres migrator job not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" "job/${JOB}"
    ;;
  migrator-clickhouse)
    JOB="$(kubectl get job -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/component=migrator,app.kubernetes.io/part=clickhouse" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$JOB" ]]; then
      echo "ClickHouse migrator job not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" "job/${JOB}"
    ;;
  postgres)
    POD="$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/name=postgresql" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$POD" ]]; then
      echo "Postgres pod not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" -f "$POD"
    ;;
  valkey)
    POD="$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE,app.kubernetes.io/name=valkey" -o jsonpath='{.items[0].metadata.name}')"
    if [[ -z "$POD" ]]; then
      echo "Valkey pod not found for release $RELEASE" >&2
      exit 1
    fi
    kubectl logs -n "$NAMESPACE" -f "$POD"
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    echo "Expected one of: web, worker, clickhouse, migrator-postgres, migrator-clickhouse, postgres, valkey" >&2
    exit 1
    ;;
esac
