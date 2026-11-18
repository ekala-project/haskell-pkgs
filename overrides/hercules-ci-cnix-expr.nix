# Links nix's C++ API (see _nix-libs.nix), which needs boehmgc. The .cabal
# file requires the nix-store, nix-expr, nix-main and nix-flake pkg-config
# modules, but the generator maps them all to a single `nix` argument.
{
  prev,
  pkgs,
  haskellLib,
  ...
}:
let
  nixLibs = import ./_nix-libs.nix pkgs;
in
haskellLib.overrideCabal (drv: {
  librarySystemDepends = (drv.librarySystemDepends or [ ]) ++ [ pkgs.boehmgc ];
  libraryPkgconfigDepends = (drv.libraryPkgconfigDepends or [ ]) ++ [
    nixLibs.nix-main
    nixLibs.nix-flake
  ];
}) (prev.hercules-ci-cnix-expr.override { nix = nixLibs.nix-expr; })
