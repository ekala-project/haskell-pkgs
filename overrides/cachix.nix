# cachix has several executables, so the generator sets no mainProgram;
# setting it here also exposes `cachix` at top level. Build against the same
# nix store lib as hercules-ci-cnix-store.
{ prev, pkgs, haskellLib, ... }:
haskellLib.overrideCabal { mainProgram = "cachix"; } (
  prev.cachix.override { nix = (import ./_nix-libs.nix pkgs).nix-store; }
)
