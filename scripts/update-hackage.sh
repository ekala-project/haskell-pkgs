#!/usr/bin/env bash
# Update the all-cabal-hashes pin to the latest Hackage snapshot.
# Adapted from nixpkgs/maintainers/scripts/haskell/update-hackage.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN_FILE="$REPO_ROOT/data/hackage/pin.json"

OWNER=commercialhaskell
REPO=all-cabal-hashes
BRANCH=hackage

echo "Fetching latest commit from $OWNER/$REPO ($BRANCH branch)…"

response=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH")
commit=$(echo "$response" | jq -r '.commit.sha')
msg=$(echo "$response" | jq -r '.commit.commit.message')

if [[ "$commit" == "null" || -z "$commit" ]]; then
  echo "Error: Failed to fetch commit. API response:"
  echo "$response"
  exit 1
fi

old_commit=$(jq -r '.commit' "$PIN_FILE")

if [[ "$commit" == "$old_commit" ]]; then
  echo "Already up to date at $commit"
  exit 0
fi

url="https://github.com/$OWNER/$REPO/archive/$commit.tar.gz"

echo "Prefetching $url …"
sha256=$(nix-prefetch-url --unpack "$url" 2>/dev/null)

echo "Updating pin.json…"
cat > "$PIN_FILE" << EOF
{
  "commit": "$commit",
  "url": "$url",
  "sha256": "$sha256",
  "msg": "$msg"
}
EOF

old_date=$(echo "$old_commit" | head -c 7)
new_date=$(echo "$commit" | head -c 7)
echo "Updated: $old_date -> $new_date"
echo "$msg"
