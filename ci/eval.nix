# Validates that every hard system dependency reference in
# hackage-packages.nix resolves against corepkgs (aliases disabled).
# See ci/packages.nix for the reference forms.
#
# Usage:
#   nix-instantiate --eval --strict ci/eval.nix
#   nix-instantiate --eval --strict --json ci/eval.nix

let
  inherit (import ./packages.nix { }) references missing packageCount;
in
assert
  missing == [ ]
  || builtins.throw ''
    The following system dependencies referenced by hackage-packages.nix do
    not exist in corepkgs (with aliases disabled):

      ${builtins.concatStringsSep "\n  " missing}

    corepkgs renamed or removed them since hackage-packages.nix was last
    regenerated. Map the generator's name to the canonical attribute path in
    configuration-hackage2nix/system-dependency-paths.yaml (or drop a stale
    entry), then run scripts/regenerate-hackage-packages.sh.
  '';
{
  inherit packageCount;
  systemDepsChecked = builtins.length references;
  ok = true;
}
