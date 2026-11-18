# hercules-ci-cnix-store requires nix-store < 2.34 and has API
# incompatibilities with 2.33+, so it (and cachix, which links the same
# store library) builds against nix 2.31's store lib.
pkgs: pkgs.nixVersions.nix_2_31.libs.nix-store
