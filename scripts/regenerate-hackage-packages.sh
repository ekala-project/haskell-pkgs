#!/usr/bin/env bash
# Regenerate per-package hackage Nix expressions using hackage2ekapkgs.
#
# This script bootstraps hackage2ekapkgs and generates per-package .nix
# files under hackage/ for the haskell-packages repo.
#
# Prerequisites:
#   - nixpkgs checkout at $NIXPKGS_PATH (for building the tool)
#   - nix-build available
#
# Usage:
#   ./scripts/regenerate-hackage-packages.sh [--nixpkgs PATH]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NIXPKGS_PATH="${NIXPKGS_PATH:-/home/jon/projects/nixpkgs}"
HACKAGE2EKAPKGS_URL="https://github.com/ekala-project/hackage2ekapkgs.git"
HACKAGE2EKAPKGS_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nixpkgs)
      NIXPKGS_PATH="$2"
      shift 2
      ;;
    --hackage2ekapkgs)
      HACKAGE2EKAPKGS_SRC="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--nixpkgs PATH] [--hackage2ekapkgs PATH]"
      echo ""
      echo "  --nixpkgs PATH           Path to nixpkgs checkout (default: $NIXPKGS_PATH)"
      echo "  --hackage2ekapkgs PATH   Local path to hackage2ekapkgs (default: fetched from GitHub)"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ ! -d "$NIXPKGS_PATH/pkgs" ]]; then
  echo "Error: nixpkgs not found at $NIXPKGS_PATH"
  echo "Set NIXPKGS_PATH or use --nixpkgs"
  exit 1
fi

CONFIG_DIR="$REPO_ROOT/configuration-hackage2nix"

for f in main.yaml stackage.yaml broken.yaml transitive-broken.yaml; do
  if [[ ! -f "$CONFIG_DIR/$f" ]]; then
    echo "Error: Missing config file: $CONFIG_DIR/$f"
    exit 1
  fi
done

echo "=== Step 1: Building hackage2ekapkgs ==="

if [[ -n "$HACKAGE2EKAPKGS_SRC" ]]; then
  echo "  Using local source: $HACKAGE2EKAPKGS_SRC"
  HACKAGE2EKAPKGS_BIN=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
    let nixpkgs = import <nixpkgs> {};
    in nixpkgs.haskellPackages.callCabal2nix \"hackage2ekapkgs\" $HACKAGE2EKAPKGS_SRC {}
  ")/bin/hackage2ekapkgs
else
  echo "  Fetching from $HACKAGE2EKAPKGS_URL"
  HACKAGE2EKAPKGS_BIN=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
    let
      nixpkgs = import <nixpkgs> {};
      src = builtins.fetchGit {
        url = \"$HACKAGE2EKAPKGS_URL\";
      };
    in nixpkgs.haskellPackages.callCabal2nix \"hackage2ekapkgs\" src {}
  ")/bin/hackage2ekapkgs
fi

echo "  Using: $HACKAGE2EKAPKGS_BIN"

echo "=== Step 2: Obtaining Hackage data ==="

UNPACKED_HACKAGE=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
  let
    nixpkgs = import <nixpkgs> {};
    pin = builtins.fromJSON (builtins.readFile $REPO_ROOT/data/hackage/pin.json);
    tarball = nixpkgs.fetchurl {
      url = pin.url;
      sha256 = pin.sha256;
      name = \"all-cabal-hashes.tar.gz\";
    };
  in
  nixpkgs.runCommandLocal \"unpacked-cabal-hashes\" { }
    \"tar xf \${tarball} --strip-components=1 --one-top-level=\\\$out\"
")

echo "  Hackage data: $UNPACKED_HACKAGE"

echo "=== Step 3: Generating compiler configuration ==="

COMPILER_CONFIG=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
  let nixpkgs = import <nixpkgs> {};
  in nixpkgs.haskellPackages.cabal2nix-unstable.compilerConfig
")

echo "  Compiler config: $COMPILER_CONFIG"

echo "=== Step 4: Running hackage2ekapkgs ==="

# Resolve the ekapkgs package set path for system dep resolution
EKAPKGS_PATH=$(nix-instantiate --eval --json -E '(import ./pins.nix).corepkgs.outPath' 2>/dev/null | tr -d '"' || echo ".")

"$HACKAGE2EKAPKGS_BIN" \
  --hackage "$UNPACKED_HACKAGE" \
  --preferred-versions <(for n in "$UNPACKED_HACKAGE"/*/preferred-versions; do cat "$n"; echo; done) \
  --pkgs-path "$EKAPKGS_PATH" \
  --output-dir "$REPO_ROOT/hackage" \
  --config "$COMPILER_CONFIG" \
  --config "$CONFIG_DIR/main.yaml" \
  --config "$CONFIG_DIR/stackage.yaml" \
  --config "$CONFIG_DIR/broken.yaml" \
  --config "$CONFIG_DIR/transitive-broken.yaml"

echo ""
echo "=== Step 5: Post-processing hackage-packages.nix ==="

# Replace `inherit (pkgs) <name>;` with `<name> = pkgs.<name> or null;`
# for system deps missing from corepkgs, and set
# `broken = !(pkgs ? <name>);` on each affected package.
python3 "$REPO_ROOT/scripts/postprocess-hackage-packages.py"

echo ""
echo "=== Done ==="
echo "Per-package Nix files generated in $REPO_ROOT/hackage/"
echo "Packages: $(find "$REPO_ROOT/hackage" -name default.nix -not -path "$REPO_ROOT/hackage/default.nix" | wc -l)"
