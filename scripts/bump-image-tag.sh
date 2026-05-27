#!/usr/bin/env bash
set -euo pipefail

REPO="next-element-inc/monorepo"
BRANCH="dev"

usage() {
  cat <<EOF
Usage: $(basename "$0") [TAG]

Bump the application image tag across this repository, commit, and push.

If TAG is provided, use it directly.
If omitted, fetch the latest commit SHA from $REPO origin/$BRANCH.

Examples:
  $(basename "$0") abc1234
  $(basename "$0")
EOF
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

cd "$(git rev-parse --show-toplevel)"

if [[ -n "${1:-}" ]]; then
  NEW_TAG="$1"
else
  echo "Fetching latest commit from $REPO $BRANCH..."
  NEW_TAG=$(gh api "repos/$REPO/commits/$BRANCH" --jq '.sha' | head -c 7)
  if [[ -z "$NEW_TAG" ]]; then
    echo "Error: failed to fetch latest commit SHA. Make sure 'gh' is authenticated with access to $REPO." >&2
    exit 1
  fi
  echo "Resolved latest commit: $NEW_TAG"
fi

OLD_TAG=$(sed -n 's/^  tag: "\(.*\)"/\1/p' helm/values.yaml)
if [[ "$OLD_TAG" == "$NEW_TAG" ]]; then
  echo "Image tag is already $NEW_TAG — nothing to do."
  exit 0
fi

echo "Bumping image tag: $OLD_TAG → $NEW_TAG"

sed -i '' "s|tag: \"$OLD_TAG\"|tag: \"$NEW_TAG\"|" helm/values.yaml
sed -i '' "s|ghcr.io/git-ai-project/git-ai-web-ee:$OLD_TAG|ghcr.io/git-ai-project/git-ai-web-ee:$NEW_TAG|g" docker-compose/docker-compose.yml

echo "Updated files:"
git diff --stat

git add helm/values.yaml docker-compose/docker-compose.yml
git commit -m "update image tag to $NEW_TAG"
git push

echo "Done. Pushed image tag $NEW_TAG."
