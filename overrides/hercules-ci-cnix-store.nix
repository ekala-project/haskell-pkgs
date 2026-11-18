# Links nix's C++ API (see _nix-libs.nix), which needs boehmgc.
{
  prev,
  pkgs,
  haskellLib,
  ...
}:
haskellLib.overrideCabal (drv: {
  librarySystemDepends = (drv.librarySystemDepends or [ ]) ++ [ pkgs.boehmgc ];
}) (prev.hercules-ci-cnix-store.override { nix = (import ./_nix-libs.nix pkgs).nix-store; })
