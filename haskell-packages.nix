# Post-processing overlay for per-package fixes, applied after the
# auto-called packages from pkgs/.
#
# Each overrides/<attr>.nix replaces haskellPackages.<attr> and is a
# function of { final, prev, lib, pkgs, haskellLib, ... }, where haskellLib
# is haskell.lib.compose. Files starting with `_` are shared helpers and
# are not loaded as overrides.
final: prev:
let
  inherit (prev) lib;

  args = {
    inherit final prev lib;
    inherit (prev) pkgs;
    haskellLib = prev.pkgs.haskell.lib.compose;
  };

  isOverride = name: type: type == "regular" && lib.hasSuffix ".nix" name && !lib.hasPrefix "_" name;
in
lib.mapAttrs' (
  name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (import (./overrides + "/${name}") args)
) (lib.filterAttrs isOverride (builtins.readDir ./overrides))
