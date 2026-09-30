# Post-processing overlay for per-package fixes.
# Applied after auto-called packages from pkgs/.
final: prev:
let
  inherit (prev.pkgs.haskell.lib.compose) doJailbreak overrideCabal;

  # amazonka 2.0 uses DisambiguateRecordFields which GHC 9.10 rejects
  # in re-export lists with duplicate field names. The upstream fix
  # (d836f682) switches to DuplicateRecordFields.
  fixAmazonka = pkg: doJailbreak (overrideCabal (drv: {
    postPatch = (drv.postPatch or "") + ''
      find . -name '*.hs' -exec sed -i \
        's/DisambiguateRecordFields/DuplicateRecordFields/g' {} +
    '';
  }) pkg);
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

  # Fix amazonka for GHC 9.10: relax bounds + fix DuplicateRecordFields.
  amazonka = doJailbreak prev.amazonka;
  amazonka-core = doJailbreak prev.amazonka-core;
  amazonka-s3 = fixAmazonka prev.amazonka-s3;
  amazonka-sso = fixAmazonka prev.amazonka-sso;
  amazonka-sts = fixAmazonka prev.amazonka-sts;
}
