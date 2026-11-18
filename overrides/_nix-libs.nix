# hercules-ci-cnix-{store,expr} require nix < 2.34 and have API
# incompatibilities with 2.33+, so they (and cachix, which links the same
# store library) build against nix 2.31's component libraries.
pkgs: pkgs.nixVersions.nix_2_31.libs
