# The generator must parse every .cabal file on Hackage, including ones
# using cabal-version syntax newer than GHC's bundled Cabal (3.12 for
# GHC 9.10). Mirrors nixpkgs' cabal2nix-unstable.
{ prev, ... }:
prev.hackage2ekapkgs.overrideScope (
  self: _: {
    Cabal = self.Cabal_3_16_1_0;
    Cabal-syntax = self.Cabal-syntax_3_16_1_0;
  }
)
