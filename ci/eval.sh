#!/usr/bin/env bash
# Validates that hackage-packages.nix system dependency references
# resolve against the canonical corepkgs package set (aliases disabled).
#
# See ci/eval.nix for what counts as a failure.

set -euo pipefail

cd "$(dirname "$0")/.."

stderr="$(mktemp)"
trap 'rm -f "$stderr"' EXIT

if ! result="$(nix-instantiate --eval --strict --json ci/eval.nix --show-trace 2>"$stderr")"; then
  cat "$stderr" >&2
  exit 1
fi

# Nix's evaluation warnings are errors here.
if grep -q '^warning:' "$stderr"; then
  cat "$stderr" >&2
  echo
  echo "Evaluation emitted the warnings above; fix them or the job stays red."
  exit 1
fi

# Print any other trace output.
if [ -s "$stderr" ]; then
  cat "$stderr" >&2
fi

# Extract fields from the JSON result.
checked="$(echo "$result" | sed -E 's/.*"systemDepsChecked":([0-9]+).*/\1/')"

count="$(echo "$result" | sed -E 's/.*"packageCount":([0-9]+).*/\1/')"

echo "haskellPackages: $count attributes; checked $checked system dependency references, all resolved."
