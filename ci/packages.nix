# Validates system dependency references in hackage-packages.nix.
#
# hackage-packages.nix uses `inherit (pkgs) name` for hard system deps.
# With aliases disabled, any reference to a renamed corepkgs attribute
# will be detected as missing.
#
# Known-missing deps (packages not yet ported to corepkgs) are listed
# in ci/known-missing-sysdeps.nix and excluded from the check.
#
# Usage:
#   nix-instantiate --eval --strict ci/eval.nix

{
  checkMeta ? false,
}:

let
  pkgs = import ../. {
    config = {
      inherit checkMeta;
      aliases.nixpkgs = false;

      handleEvalIssue =
        reason: msg:
        if
          builtins.elem reason [
            "unknown-meta"
            "broken-outputs"
          ]
        then
          abort msg
        else
          throw msg;
    };
  };

  inherit (pkgs) lib;

  # ── System dependency validation ──────────────────────────────────
  #
  # hackage-packages.nix uses two patterns for system deps:
  #   {inherit (pkgs) name;}          — hard dependency, fails if missing
  #   {name = pkgs.name or null;}     — optional dependency, safe
  #
  # We only care about hard deps (the `inherit` pattern).

  hackageSrc = builtins.readFile ../hackage-packages.nix;

  # Extract all `inherit (pkgs) name1 name2 ...;` references.
  inheritMatches = builtins.split "inherit \\(pkgs\\) ([^;]+);" hackageSrc;

  # builtins.split returns a flat list alternating non-matches and
  # match groups (which are lists of capture groups).
  extractNames =
    parts:
    let
      go =
        acc: xs:
        if xs == [ ] then
          acc
        else
          let
            head = builtins.head xs;
            tail = builtins.tail xs;
          in
          if builtins.isList head then
            go (acc ++ builtins.filter (s: s != "") (builtins.split " |\n" (builtins.head head))) tail
          else
            go acc tail;
    in
    go [ ] parts;

  inheritedNames = extractNames inheritMatches;

  # Deduplicate
  uniqueNames = builtins.attrNames (
    builtins.listToAttrs (map (n: { name = n; value = true; }) inheritedNames)
  );

  # Check which names are missing from pkgs
  missingNames = builtins.filter (n: !(builtins.hasAttr n pkgs)) uniqueNames;
in
{
  inherit uniqueNames missingNames;
  totalDeps = builtins.length uniqueNames;
  missingCount = builtins.length missingNames;
}
