# Validates hard system dependency references in hackage-packages.nix.
#
# hackage2ekapkgs emits three forms of system dependency:
#   {inherit (pkgs) name;}         resolved against corepkgs at generation time
#   {inherit (pkgs.set) name;}     injected by PostProcess hooks
#   {name = pkgs.some.path;}       from configuration-hackage2nix/system-dependency-paths.yaml
#   {name = pkgs.name or null;}    unresolved; the package carries
#                                  `broken = !(pkgs ? name)`, so this is safe
#
# The first two must exist in corepkgs with aliases disabled. If one is
# missing, corepkgs renamed or removed it since the last regeneration: add a
# system-dependency-paths entry (or drop the stale one) and regenerate.
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

  hackageSrc = builtins.readFile ../hackage-packages.nix;

  # builtins.split returns non-matches interleaved with lists of capture groups.
  captures = regex: lib.concatMap lib.toList (builtins.filter builtins.isList (builtins.split regex hackageSrc));

  words = s: lib.filter (n: n != "") (lib.splitString " " s);

  # `inherit (pkgs) a b;` and `inherit (pkgs.some.set) a b;` (from PostProcess hooks)
  inheritedNames = lib.concatMap words (captures "inherit \\(pkgs\\) ([^;]+);");
  inheritedNested =
    let
      m = builtins.filter builtins.isList (
        builtins.split "inherit \\(pkgs\\.([A-Za-z0-9_.'-]+)\\) ([^;]+);" hackageSrc
      );
    in
    lib.concatMap (g: map (n: "${builtins.elemAt g 0}.${n}") (words (builtins.elemAt g 1))) m;

  # `= pkgs.<path>;` (an `or null` fallback never ends directly in `;`)
  explicitPaths = captures "[A-Za-z0-9_'-]+ = pkgs\\.([A-Za-z0-9_.'-]+);";

  references = lib.unique (inheritedNames ++ inheritedNested ++ explicitPaths);

  missing = lib.filter (p: !(lib.hasAttrByPath (lib.splitString "." p) pkgs)) references;
in
{
  inherit references missing;
  # Forces hackage-packages.nix to be parsed (e.g. catches duplicate bindings).
  packageCount = builtins.length (builtins.attrNames pkgs.haskellPackages);
}
