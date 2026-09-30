# Post-processing overlay for per-package fixes.
# Applied after auto-called packages from pkgs/.
final: prev:
let
  inherit (prev.pkgs.haskell.lib.compose) overrideCabal;
  # Use nix 2.31's store lib — hercules-ci-cnix-store requires nix-store <2.34
  # and has API incompatibilities with 2.33+.
  nix-store-lib = prev.pkgs.nixVersions.nix_2_31.libs.nix-store;
in
{
  hercules-ci-cnix-store = overrideCabal (drv: {
    librarySystemDepends = (drv.librarySystemDepends or [ ]) ++ [ prev.pkgs.boehmgc ];
  }) (prev.hercules-ci-cnix-store.override { nix = nix-store-lib; });
  hercules-ci-cnix-expr = overrideCabal (drv: {
    librarySystemDepends = (drv.librarySystemDepends or [ ]) ++ [ prev.pkgs.boehmgc ];
  }) (prev.hercules-ci-cnix-expr.override { nix = nix-store-lib; });
  cachix = prev.cachix.override { nix = nix-store-lib; };
}
