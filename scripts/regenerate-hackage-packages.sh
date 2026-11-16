#!/usr/bin/env bash
# Regenerate hackage-packages.nix and top-level.nix from pinned inputs:
#
#   - data/hackage/pin.json               Hackage snapshot (all-cabal-hashes)
#   - pins.nix                            corepkgs, used for system dep resolution
#   - pkgs/hackage2ekapkgs                the generator, built from this repo
#   - configuration-hackage2nix/*.yaml    version pins, broken lists,
#                                         system-dependency-paths, compiler config
#
# Running this on an unmodified checkout must produce no diff; CI relies on
# that, so never hand-edit the generated files.
#
# Usage:
#   scripts/regenerate-hackage-packages.sh [--hackage2ekapkgs PATH]
#
#   --hackage2ekapkgs PATH  build the generator from a local checkout instead
#                           of the pinned source (for generator development)
#   HACKAGE2EKAPKGS=BIN     use an already-built generator binary

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/configuration-hackage2nix"
H2E_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hackage2ekapkgs)
      H2E_SRC="$(realpath "$2")"
      shift 2
      ;;
    --help | -h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

configs=(
  "$CONFIG_DIR/compiler.yaml"
  "$CONFIG_DIR/main.yaml"
  "$CONFIG_DIR/stackage.yaml"
  "$CONFIG_DIR/broken.yaml"
  "$CONFIG_DIR/transitive-broken.yaml"
  "$CONFIG_DIR/system-dependency-paths.yaml"
)
for f in "${configs[@]}"; do
  [[ -f "$f" ]] || { echo "Error: missing config file $f" >&2; exit 1; }
done

echo "=== Checking compiler config ==="
# Read the compiler directly, not via haskellPackages: that would parse the
# hackage-packages.nix this script is about to replace.
ghc_version=$(nix-instantiate --eval --json -E '(import ./. { }).haskell.compiler.${import ./compiler.nix}.version' | tr -d '"')
if ! grep -qx "compiler: ghc-$ghc_version" "$CONFIG_DIR/compiler.yaml"; then
  echo "Error: compiler.yaml does not match haskellPackages.ghc ($ghc_version)." >&2
  echo "Run scripts/generate-compiler-config.sh first." >&2
  exit 1
fi

echo "=== Building hackage2ekapkgs ==="
if [[ -n "${HACKAGE2EKAPKGS:-}" ]]; then
  H2E_BIN="$HACKAGE2EKAPKGS"
elif [[ -n "$H2E_SRC" ]]; then
  H2E_BIN="$(nix-build --no-out-link --arg src "$H2E_SRC" -E '
    { src }:
    let pkgs = import ./. { };
    in pkgs.haskell.lib.compose.overrideSrc { src = pkgs.lib.cleanSource src; }
         pkgs.haskellPackages.hackage2ekapkgs
  ')/bin/hackage2ekapkgs"
else
  H2E_BIN="$(nix-build --no-out-link -A haskellPackages.hackage2ekapkgs)/bin/hackage2ekapkgs"
fi
echo "  $H2E_BIN"

echo "=== Fetching Hackage snapshot ==="
# builtins.fetchTarball needs no stdenv, and pin.json holds the unpacked hash.
# --read-write-mode makes sure the tree is actually written to the store.
HACKAGE="$(nix-instantiate --read-write-mode --eval --json -E '
  let pin = builtins.fromJSON (builtins.readFile ./data/hackage/pin.json);
  in "${builtins.fetchTarball { inherit (pin) url sha256; }}"
' | tr -d '"')"
echo "  $HACKAGE ($(jq -r .msg data/hackage/pin.json))"

echo "=== Running hackage2ekapkgs ==="
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

config_args=()
for f in "${configs[@]}"; do config_args+=(--config "$f"); done

# Resolve system deps against corepkgs itself with aliases disabled, so that
# only canonical attribute names are emitted.
"$H2E_BIN" \
  --hackage "$HACKAGE" \
  --preferred-versions <(for n in "$HACKAGE"/*/preferred-versions; do cat "$n"; echo; done) \
  --pkgs-path "(import $REPO_ROOT/pins.nix).corepkgs" \
  --pkgs-args '{ config.aliases.nixpkgs = false; }' \
  --output-dir "$OUT/hackage" \
  "${config_args[@]}"

echo "=== Assembling hackage-packages.nix ==="
python3 -I "$REPO_ROOT/scripts/assemble-hackage-packages.py" "$OUT/hackage" "$REPO_ROOT/hackage-packages.nix"

echo "=== Regenerating top-level.nix ==="
python3 -I "$REPO_ROOT/scripts/generate-top-level.py"

echo "=== Done ==="
git -C "$REPO_ROOT" diff --stat -- hackage-packages.nix top-level.nix | tail -1
