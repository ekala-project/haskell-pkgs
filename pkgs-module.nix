# pkgs-module.nix — Expose haskell-packages overlays for capstone repo consumption.
#
# Returns an attrset with:
#   overlays — top-level overlays (applied to pkgs directly)
#   module   — NixOS module for config.overlays.haskell
let
  lib = import (
    builtins.fetchGit {
      url = "https://github.com/jonringer/nix-lib.git";
      rev = "c19c816e39d14a60dd368d601aa9b389b09d0bbb";
    }
  );

  pkgsOverlay = lib.mkAutoCalledPackageDir ./pkgs;
  haskellOverrides = import ./haskell-packages.nix;

  # The generated hackage-packages.nix has signature:
  #   { pkgs, lib, callPackage }: self: { ... }
  # We convert it to an overlay (final: prev:) by using the pkgs and lib
  # that make-package-set.nix exposes on the set.
  hackagePackagesOverlay =
    final: prev:
    import ./hackage-packages.nix {
      inherit (prev) pkgs lib callPackage;
    } final;

  haskellOverlay = lib.composeManyExtensions [
    hackagePackagesOverlay
    pkgsOverlay
    haskellOverrides
  ];

  toplevelOverlay = import ./top-level.nix;
in
{
  overlays = [ toplevelOverlay ];
  module = { ... }: {
    _file = "haskell-packages/pkgs-module.nix";
    config.overlays.haskell = [ haskellOverlay ];
  };
}
