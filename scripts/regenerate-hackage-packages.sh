#!/usr/bin/env bash
# Regenerate hackage-packages.nix using hackage2nix.
#
# This script bootstraps from nixpkgs' hackage2nix tool and generates
# a hackage-packages.nix file for the haskell-packages repo.
#
# hackage2nix expects a nixpkgs-like directory layout for its --nixpkgs flag,
# so we create a temporary directory structure, run the tool, and copy the
# output to our repo root.
#
# Prerequisites:
#   - nixpkgs checkout at $NIXPKGS_PATH (or auto-detected)
#   - nix-build, nix-shell available
#
# Usage:
#   ./scripts/regenerate-hackage-packages.sh [--nixpkgs PATH] [--fast]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NIXPKGS_PATH="${NIXPKGS_PATH:-/home/jon/projects/nixpkgs}"
FAST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nixpkgs)
      NIXPKGS_PATH="$2"
      shift 2
      ;;
    --fast|-f)
      FAST=1
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--nixpkgs PATH] [--fast]"
      echo ""
      echo "  --nixpkgs PATH   Path to nixpkgs checkout (default: $NIXPKGS_PATH)"
      echo "  --fast, -f       Skip transitive-broken regeneration"
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

# hackage2nix uses --nixpkgs for two things:
# 1. To evaluate nixpkgs attribute paths (derivation-attr-paths.nix)
# 2. To write the output hackage-packages.nix
# We point it at a copy of nixpkgs with a writable output directory.
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Create a minimal writable overlay on top of nixpkgs for the output
mkdir -p "$TMPDIR/pkgs/development/haskell-modules"
# Symlink everything from nixpkgs except the output directory
for item in "$NIXPKGS_PATH"/*; do
  base=$(basename "$item")
  if [[ "$base" != "pkgs" ]]; then
    ln -s "$item" "$TMPDIR/$base" 2>/dev/null || true
  fi
done
# For pkgs/, symlink everything except development/haskell-modules
mkdir -p "$TMPDIR/pkgs"
for item in "$NIXPKGS_PATH/pkgs"/*; do
  base=$(basename "$item")
  if [[ "$base" != "development" ]]; then
    ln -s "$item" "$TMPDIR/pkgs/$base" 2>/dev/null || true
  fi
done
mkdir -p "$TMPDIR/pkgs/development"
for item in "$NIXPKGS_PATH/pkgs/development"/*; do
  base=$(basename "$item")
  if [[ "$base" != "haskell-modules" ]]; then
    ln -s "$item" "$TMPDIR/pkgs/development/$base" 2>/dev/null || true
  fi
done
# Symlink most of haskell-modules from nixpkgs, but keep hackage-packages.nix writable
for item in "$NIXPKGS_PATH/pkgs/development/haskell-modules"/*; do
  base=$(basename "$item")
  if [[ "$base" != "hackage-packages.nix" ]]; then
    ln -s "$item" "$TMPDIR/pkgs/development/haskell-modules/$base" 2>/dev/null || true
  fi
done

echo "=== Step 1: Obtaining Hackage data ==="

# Fetch and extract all-cabal-hashes in a single nix-build
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

echo "=== Step 2: Generating compiler configuration ==="

# Generate compiler config from the GHC we use (via nixpkgs for bootstrap)
COMPILER_CONFIG=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
  let nixpkgs = import <nixpkgs> {};
  in nixpkgs.haskellPackages.cabal2nix-unstable.compilerConfig
")

echo "  Compiler config: $COMPILER_CONFIG"

echo "=== Step 3: Running hackage2nix ==="

# Get hackage2nix binary
HACKAGE2NIX_BIN=$(nix-build --no-out-link -I nixpkgs="$NIXPKGS_PATH" -E "
  let nixpkgs = import <nixpkgs> {};
  in nixpkgs.haskellPackages.cabal2nix-unstable.bin
")/bin/hackage2nix

echo "  Using: $HACKAGE2NIX_BIN"

"$HACKAGE2NIX_BIN" \
  --hackage "$UNPACKED_HACKAGE" \
  --preferred-versions <(for n in "$UNPACKED_HACKAGE"/*/preferred-versions; do cat "$n"; echo; done) \
  --nixpkgs "$TMPDIR" \
  --config "$COMPILER_CONFIG" \
  --config "$CONFIG_DIR/main.yaml" \
  --config "$CONFIG_DIR/stackage.yaml" \
  --config "$CONFIG_DIR/broken.yaml" \
  --config "$CONFIG_DIR/transitive-broken.yaml"

echo "=== Step 4: Copying output ==="

GENERATED="$TMPDIR/pkgs/development/haskell-modules/hackage-packages.nix"

if [[ ! -f "$GENERATED" ]]; then
  echo "Error: hackage2nix did not produce output at $GENERATED"
  echo "Contents of tmpdir:"
  find "$TMPDIR" -type f
  exit 1
fi

LINES=$(wc -l < "$GENERATED")
SIZE=$(du -h "$GENERATED" | cut -f1)
echo "  Generated: $LINES lines ($SIZE)"

cp "$GENERATED" "$REPO_ROOT/hackage-packages.nix"

echo ""
echo "=== Done ==="
echo "hackage-packages.nix has been regenerated at $REPO_ROOT/hackage-packages.nix"
echo "Lines: $LINES"
