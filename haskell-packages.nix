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

  # Upgrade hnix-store-core to 0.8 (cachix requires >=0.8).
  hnix-store-core = prev.callPackage
    ({ mkDerivation, attoparsec, base, base16-bytestring
     , base64-bytestring, bytestring, constraints-extras, containers
     , crypton, data-default-class, dependent-sum, dependent-sum-template
     , filepath, hashable, hspec, memory, nix-derivation, some, tasty
     , tasty-discover, tasty-golden, tasty-hspec, text, time
     , unordered-containers, vector
     }:
     mkDerivation {
       pname = "hnix-store-core";
       version = "0.8.0.0";
       sha256 = "1i6wdag25g3588mcxy1z09c22p45dd71cw1654l05gfxwhj05ivc";
       libraryHaskellDepends = [
         attoparsec base base16-bytestring base64-bytestring bytestring
         constraints-extras containers crypton data-default-class
         dependent-sum dependent-sum-template filepath hashable memory
         nix-derivation some text time unordered-containers vector
       ];
       testHaskellDepends = [
         attoparsec base base16-bytestring base64-bytestring bytestring
         containers crypton data-default-class hspec tasty tasty-golden
         tasty-hspec text time unordered-containers
       ];
       testToolDepends = [ tasty-discover ];
       description = "Core types used for interacting with the Nix store";
       license = prev.lib.meta.getLicenseFromSpdxId "Apache-2.0";
     }) {};
}
