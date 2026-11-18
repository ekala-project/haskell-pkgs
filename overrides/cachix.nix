# Build against the same nix store lib as hercules-ci-cnix-store.
{ prev, pkgs, ... }:
prev.cachix.override { nix = (import ./_nix-libs.nix pkgs).nix-store; }
