#!/usr/bin/env bash
set -euo pipefail

REPO="next-element-inc/monorepo"
BRANCH="dev"

# Run git without invoking an interactive pager so diffs don't block the script.
git() {
  command git --no-pager "$@"
}

# Ctrl+C cancels the whole script.
trap 'echo; echo "Cancelled."; exit 130' INT

usage() {
  cat <<EOF
Usage: $(basename "$0") [TAG]

Bump the application and ClickHouse migrator image tags across this repository,
commit, and push.

If TAG is provided, use it directly.
If omitted, fetch the latest commit SHA from $REPO origin/$BRANCH.

You will be asked to approve the proposed tag before anything is changed.
Rejecting the proposal lets you enter an override tag instead.

Examples:
  $(basename "$0") abc1234
  $(basename "$0")
EOF
  exit 1
}

# Validate that a string looks like a short commit hash (hex, 7-40 chars).
is_valid_tag() {
  [[ "$1" =~ ^[0-9a-fA-F]{7,40}$ ]]
}

# Prompt for an override tag until a valid short commit hash is entered.
prompt_override_tag() {
  local input
  while true; do
    read -r -p "Enter an override tag (short commit hash): " input
    if is_valid_tag "$input"; then
      printf '%s' "$input"
      return 0
    fi
    echo "Invalid tag '$input'. Expected a hex commit hash of 7-40 characters." >&2
  done
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

cd "$(git rev-parse --show-toplevel)"

if [[ -n "${1:-}" ]]; then
  NEW_TAG="$1"
  if ! is_valid_tag "$NEW_TAG"; then
    echo "Error: '$NEW_TAG' is not a valid short commit hash (expected 7-40 hex characters)." >&2
    exit 1
  fi
else
  echo "Fetching latest commit from $REPO $BRANCH..."
  NEW_TAG=$(gh api "repos/$REPO/commits/$BRANCH" --jq '.sha' | head -c 7)
  if [[ -z "$NEW_TAG" ]]; then
    echo "Error: failed to fetch latest commit SHA. Make sure 'gh' is authenticated with access to $REPO." >&2
    exit 1
  fi
  echo "Resolved latest commit: $NEW_TAG"
fi

# Ask to approve the proposed tag; rejecting lets you enter an override.
while true; do
  read -r -p "Use image tag '$NEW_TAG'? [Y/n] " answer
  case "$answer" in
    "" | [Yy] | [Yy][Ee][Ss])
      break
      ;;
    [Nn] | [Nn][Oo])
      NEW_TAG=$(prompt_override_tag)
      echo "Using override tag: $NEW_TAG"
      break
      ;;
    *)
      echo "Please answer 'y' to approve or 'n' to enter an override tag." >&2
      ;;
  esac
done

OLD_TAG=$(sed -n 's/^  tag: "\(.*\)"/\1/p' helm/values.yaml)
OLD_MIGRATOR_TAG=$(sed -n 's/^    tag: "\(.*-clickhouse-migrator\)"/\1/p' helm/values.yaml)
NEW_MIGRATOR_TAG="$NEW_TAG-clickhouse-migrator"
if [[ "$OLD_TAG" == "$NEW_TAG" && "$OLD_MIGRATOR_TAG" == "$NEW_MIGRATOR_TAG" ]]; then
  echo "Image tags are already $NEW_TAG — nothing to do."
  exit 0
fi

echo "Bumping image tag: $OLD_TAG → $NEW_TAG"

sed -i '' "s|tag: \"$OLD_TAG\"|tag: \"$NEW_TAG\"|" helm/values.yaml
sed -i '' -E "s|tag: \"[0-9a-fA-F]{7,40}-clickhouse-migrator\"|tag: \"$NEW_MIGRATOR_TAG\"|" helm/values.yaml
sed -i '' "s|ghcr.io/git-ai-project/git-ai-web-ee:$OLD_TAG|ghcr.io/git-ai-project/git-ai-web-ee:$NEW_TAG|g" docker-compose/docker-compose.yml
sed -i '' -E "s|ghcr.io/git-ai-project/git-ai-web-ee:[0-9a-fA-F]{7,40}-clickhouse-migrator|ghcr.io/git-ai-project/git-ai-web-ee:$NEW_MIGRATOR_TAG|g" docker-compose/docker-compose.yml

echo "Updated files:"
git diff --stat

git add helm/values.yaml docker-compose/docker-compose.yml
git commit -m "update image tag to $NEW_TAG"
git push

echo "Done. Pushed image tag $NEW_TAG."
