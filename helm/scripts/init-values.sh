#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required" >&2
  exit 1
fi

mkdir -p generated

VALUES_PATH="generated/values.local.yaml"
SCM_PATH="generated/scm-apps.generated.json"

if [[ ! -f "$SCM_PATH" ]]; then
  echo '[]' > "$SCM_PATH"
  echo "Created $SCM_PATH placeholder"
fi

if [[ -f "$VALUES_PATH" ]]; then
  echo "$VALUES_PATH already exists"
  exit 0
fi

rand_base64() {
  openssl rand -base64 32 | tr -d '\n'
}

rand_hex64() {
  openssl rand -hex 32
}

cat > "$VALUES_PATH" <<YAML
global:
  webBaseUrl: http://git-ai.local
  betterAuthUrl: http://git-ai.local
  workerPublicBaseUrl: http://git-ai.local
  webAppInternalBaseUrl: http://git-ai.local

ingress:
  enabled: false
  mode: nginx
  cloud: generic
  className: ""
  hosts:
    - host: git-ai.local
      paths:
        - path: /
          pathType: Prefix

secrets:
  licenseKey: REPLACE_ME_LICENSE_KEY
  betterAuthSecret: "$(rand_base64)"
  workerJwtSecret: "$(rand_hex64)"
  webInternalApiKey: "$(rand_hex64)"
  scmWebhookSecretKey: "$(rand_hex64)"

postgresql:
  auth:
    password: "$(rand_hex64)"
    postgresPassword: "$(rand_hex64)"

valkey:
  auth:
    password: "$(rand_hex64)"

clickhouse:
  auth:
    password: "$(rand_hex64)"
YAML

echo "Created $VALUES_PATH"
echo "Next steps:"
echo "1. Update secrets.licenseKey, ingress enabled/mode/cloud/host, and global URLs in $VALUES_PATH"
echo "2. Run: task scm:configure"
echo "3. Run: task up"
