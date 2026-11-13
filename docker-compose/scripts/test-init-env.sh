#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir "$TEST_DIR/scripts"
cp "$ROOT_DIR/scripts/init-env.sh" "$TEST_DIR/scripts/"
cp "$ROOT_DIR/.env.example" "$TEST_DIR/"
cd "$TEST_DIR"
unset CUBEJS_API_SECRET

read_secret() {
  docker compose -f - config --format json <<'YAML' | node -e '
    const config = JSON.parse(require("node:fs").readFileSync(0, "utf8"));
    process.stdout.write(config.services.web.environment?.CUBEJS_API_SECRET ?? "");
  '
services:
  web:
    image: busybox
    env_file: [./.env]
YAML
}

assert_generated() {
  if [[ ! "$1" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "Expected a generated Cube signing key ($2)" >&2
    exit 1
  fi
}

bash scripts/init-env.sh >/dev/null
fresh_secret="$(read_secret)"
assert_generated "$fresh_secret" 'fresh install'
bash scripts/init-env.sh >/dev/null
[[ "$(read_secret)" == "$fresh_secret" ]] || { echo 'Re-running init changed the Cube signing key' >&2; exit 1; }

for previous in '' 'CUBEJS_API_SECRET=""' \
    "CUBEJS_API_SECRET='  too short  ' # invalid"; do
  printf 'WEB_BASE_URL=https://git-ai.example.com\n%s' "$previous" > .env
  bash scripts/init-env.sh --cube-secret-only >/dev/null
  upgraded_secret="$(read_secret)"
  assert_generated "$upgraded_secret" 'upgrade'
  [[ "$upgraded_secret" != "$fresh_secret" ]] || { echo 'Installs share a Cube signing key' >&2; exit 1; }
  grep -qx 'WEB_BASE_URL=https://git-ai.example.com' .env
  if grep -q '^BETTER_AUTH_SECRET=' .env; then
    echo 'Cube upgrade altered unrelated secrets' >&2
    exit 1
  fi
  cp .env expected.env
  bash scripts/init-env.sh --cube-secret-only >/dev/null
  cmp -s expected.env .env || { echo 'Re-running the upgrade modified .env' >&2; exit 1; }
done

export TEST_CUBE_KEY='a-long-operator-managed-cube-signing-key'
printf '%s\n' 'export CUBEJS_API_SECRET="${TEST_CUBE_KEY}" # keep this assignment' > .env
cp .env expected.env
bash scripts/init-env.sh --cube-secret-only >/dev/null
cmp -s expected.env .env || { echo 'Upgrade modified an operator-managed Cube key' >&2; exit 1; }
[[ "$(read_secret)" == "$TEST_CUBE_KEY" ]] || { echo 'Operator-managed Cube key did not resolve' >&2; exit 1; }
