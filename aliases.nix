# Aliases for system dependencies referenced by hackage-packages.nix.
#
# The generated hackage-packages.nix uses `inherit (pkgs) name;` for C/system
# library dependencies. When a name doesn't exist in corepkgs (different
# attribute path, e.g. xorg.*), add a mapping here.
#
# For packages not yet available in corepkgs, hackage-packages.nix uses
# `name = pkgs.name or null;` directly, with `broken = true;` on the
# Haskell package.
final: prev: {
}
