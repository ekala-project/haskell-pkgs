#!/usr/bin/env bash
# Fails if regenerating from the pinned inputs (corepkgs, all-cabal-hashes,
# hackage2ekapkgs, configuration-hackage2nix/) changes any generated file,
# i.e. if hackage-packages.nix or top-level.nix were edited by hand or not
# regenerated after a configuration change.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

scripts/regenerate-hackage-packages.sh "$@"

if ! git diff --exit-code --stat -- hackage-packages.nix top-level.nix; then
  echo >&2 "error: generated files are out of date; run scripts/regenerate-hackage-packages.sh and commit the result"
  exit 1
fi
echo "Generated files are up to date."
