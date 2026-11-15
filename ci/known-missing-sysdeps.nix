# System dependencies referenced by hackage-packages.nix via
# `inherit (pkgs) name` that do not exist in corepkgs.
#
# These are packages from the broader ecosystem not yet ported to
# corepkgs.  The haskell packages that depend on them will fail to
# build, but that is expected — they are typically marked
# `broken = true` or `hydraPlatforms = lib.platforms.none`.
#
# When a name is added to corepkgs, remove it from this list.
# When a name is *renamed* in corepkgs, do NOT add it here — instead
# fix the reference in hackage-packages.nix.
[
]
