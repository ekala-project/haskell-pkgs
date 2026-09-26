# Validates that hackage-packages.nix system dependency references
# resolve against the canonical corepkgs attribute set (aliases disabled).
#
# Missing deps are checked against ci/known-missing-sysdeps.nix.
# Any dep that is missing AND not in the whitelist is a renamed
# or removed attribute — a real bug that must be fixed.
#
# Usage:
#   nix-instantiate --eval --strict ci/eval.nix
#   nix-instantiate --eval --strict --json ci/eval.nix

let
  packages = import ./packages.nix { };
  inherit (packages) missingNames totalDeps;

  knownMissing = import ./known-missing-sysdeps.nix;
  knownSet = builtins.listToAttrs (map (n: { name = n; value = true; }) knownMissing);

  # Names that are missing AND not in the known-missing whitelist.
  # These are likely renamed attributes that need updating.
  unexpectedMissing = builtins.filter (n: !(builtins.hasAttr n knownSet)) missingNames;

  # Names in the whitelist that are no longer missing (newly ported to corepkgs).
  newlyAvailable = builtins.filter (n: !(builtins.elem n missingNames)) knownMissing;
in
assert
  unexpectedMissing == [ ]
  || builtins.throw ''
    The following system dependencies referenced via `inherit (pkgs) name`
    in hackage-packages.nix do not exist in corepkgs (with aliases disabled):

      ${builtins.concatStringsSep "\n  " unexpectedMissing}

    These are NOT in ci/known-missing-sysdeps.nix, so they were likely
    renamed or removed.  Fix by updating the references in
    hackage-packages.nix to use the canonical attribute name.

    If the package genuinely does not exist in corepkgs, add it to
    ci/known-missing-sysdeps.nix instead.
  '';
assert
  newlyAvailable == [ ]
  || builtins.trace ''
    Note: the following system deps are now available in corepkgs.
    Consider removing them from ci/known-missing-sysdeps.nix:

      ${builtins.concatStringsSep "\n  " newlyAvailable}
  '' true;
{
  systemDepsChecked = totalDeps;
  knownMissing = builtins.length missingNames;
  ok = true;
}
