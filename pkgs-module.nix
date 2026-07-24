# pkgs-module.nix — Expose haskell-packages overlays for capstone repo consumption.
#
# Returns an attrset meant to be passed as a `modules` argument to corepkgs
{ lib, ... }:

let
  pkgsOverlay = lib.packageSets.mkAutoCalledPackageDir ./pkgs;
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
  aliasesOverlay = import ./aliases.nix;
in
{
  config.overlays = {
    haskell = [ haskellOverlay ];
    pkgs = [ toplevelOverlay aliasesOverlay ];
  };
}
