let
  coreRepo = import (
    builtins.fetchGit {
      url = "https://github.com/ekala-project/corepkgs.git";
      rev = "5dfa770776f9eb18f2a7cd1f15c15771ed36faad";
    }
  );

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

# Continuation passing style of import
# Values we care to modify are modified, while all other
# arguments are "passed through" to the next scope
{
  overlays ? [ ],
  config ? { },
  ...
}@args:

let
  filteredAttrs = builtins.removeAttrs args [
    "overlays"
    "config"
  ];
in

coreRepo (
  {
    overlays = [
      toplevelOverlay
    ]
    ++ overlays;

    config = config // {
      overlays.haskell = [ haskellOverlay ] ++ (config.overlays.haskell or [ ]);
    };
  }
  // filteredAttrs
)
