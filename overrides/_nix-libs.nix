# hercules-ci-cnix-{store,expr} (and cachix, which links the same store
# library) build against nix 2.31's component libraries. They accept nix up
# to 2.35, but from 2.32 on the nix-util/nix-store/nix-fetchers .pc files
# list libraries (blake3, libsodium, libcpuid, ...) under Requires.private
# that corepkgs' -dev outputs don't propagate, so pkg-config fails.
pkgs: pkgs.nixVersions.nix_2_31.libs
