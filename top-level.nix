# Top-level overlay for exposing Haskell tools at the pkgs scope.
final: prev: {
  # Example: expose cabal-install at top level
  # cabal-install = final.haskellPackages.cabal-install;
}
