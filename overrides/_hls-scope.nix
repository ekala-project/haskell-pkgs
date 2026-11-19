# haskell-language-server 2.15 is not in Stackage, and the latest-Hackage
# defaults of its dependencies don't fit it or GHC 9.10: it needs lsp 2.8,
# lsp-types 2.4 and lsp-test 0.18, and allows ormolu <= 0.8 and fourmolu <= 0.20. The
# releases that use GHC 9.10's ghc-lib-parser 9.12 (ormolu 0.8.0.2, fourmolu
# 0.19.0.1) need Cabal-syntax 3.14, where GHC 9.10 bundles 3.12; with the
# bundled one, the closure carries two Cabal-syntax instances and Cabal
# refuses to configure. So the closure is built in one scope, as in nixpkgs'
# configuration-common.nix ("haskell-language-server section").
haskellLib: self: super: {
  Cabal-syntax = self.Cabal-syntax_3_14_2_0;
  Cabal = self.Cabal_3_14_2_0;
  lsp = self.lsp_2_8_0_0;
  lsp-types = self.lsp-types_2_4_0_0;
  lsp-test = self.lsp-test_0_18_0_0;
  # main.yaml pins hie-bios < 0.18 and hiedb < 0.8 for ghcide 2.13.
  hie-bios = self.hie-bios_0_21_0;
  hiedb = self.hiedb_0_8_0_0;
  unordered-containers = self.unordered-containers_0_2_21;
  ormolu = self.ormolu_0_8_0_2;
  fourmolu = self.fourmolu_0_19_0_1;
  # The default 0.1.0.2 wants Cabal 3.12; 0.1.1.0 accepts Cabal-syntax 3.14.
  extensions = self.extensions_0_1_1_0;
  # Bounded to Cabal-syntax ^>= 3.12.
  cabal-install-parsers = haskellLib.doJailbreak super.cabal-install-parsers;
  # Needs Cabal only for its Setup.hs; keep the bundled one so there is a
  # single ghc-paths in the closure.
  ghc-paths = super.ghc-paths.override { Cabal = null; };
}
