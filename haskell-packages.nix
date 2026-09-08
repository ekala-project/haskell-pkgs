# Post-processing overlay for per-package fixes.
# Applied after auto-called packages from pkgs/.
final: prev:
let
  inherit (prev) lib pkgs;
  hl = pkgs.haskell.lib.compose;

  # haskell-language-server's formatters (ormolu 0.8, fourmolu 0.19) need
  # Cabal-syntax 3.14 where the compilers bundle 3.10 (GHC 9.8) or 3.12 (GHC
  # 9.10); with the bundled one, the closure ends up with two Cabal-syntax
  # instances and Cabal refuses to configure. Build the whole closure in one
  # 3.14 scope, the way nixpkgs' configuration-common.nix does.
  hlsScope = lself: lsuper: {
    Cabal-syntax = lself.Cabal-syntax_3_14_2_0;
    Cabal = lself.Cabal_3_14_2_0;
    # Bounded to Cabal-syntax < 3.13; picks 3.14 once the bound is lifted.
    cabal-install-parsers = hl.doJailbreak lsuper.cabal-install-parsers;
    # The default 0.1.0.2 wants Cabal 3.12; 0.1.1.0 is the Cabal-syntax 3.14 release.
    extensions = hl.doJailbreak lself.extensions_0_1_1_0;
    # Depends on Cabal for its Setup.hs only; keep the bundled one so there is
    # a single ghc-paths in the set.
    ghc-paths = lsuper.ghc-paths.override { Cabal = null; };
  };
  inHlsScope = names: lib.genAttrs names (name: prev.${name}.overrideScope hlsScope);
  hlsClosure = inHlsScope [
    "haskell-language-server"
    "hls-plugin-api"
    "ghcide"
    "hlint"
    "ormolu"
    "fourmolu"
    "lsp-types"
  ];
in
{
  # A versioned Cabal must be built against its own Cabal-syntax, not the
  # compiler's bundled one.
  Cabal_3_14_2_0 = prev.Cabal_3_14_2_0.override { Cabal-syntax = final.Cabal-syntax_3_14_2_0; };
  Cabal_3_16_1_0 = prev.Cabal_3_16_1_0.override { Cabal-syntax = final.Cabal-syntax_3_16_1_0; };

  # deepseq upper bound excludes the 1.5.1.0 that GHC 9.10 ships.
  hw-fingertree = hl.doJailbreak prev.hw-fingertree;
}
// hlsClosure
// {
  # haskell-language-server links its executables dynamically by default; unless
  # the builder is told so, the fixup check finds an RPATH into /build. Same
  # override as nixpkgs' configuration-nix.nix.
  haskell-language-server = hl.overrideCabal (_: {
    enableSharedExecutables = true;
  }) hlsClosure.haskell-language-server;
}
