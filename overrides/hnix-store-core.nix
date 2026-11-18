# cachix requires hnix-store-core >= 0.8; Stackage selects 0.6.
{ prev, lib, ... }:
prev.callPackage (
  {
    mkDerivation,
    attoparsec,
    base,
    base16-bytestring,
    base64-bytestring,
    bytestring,
    constraints-extras,
    containers,
    crypton,
    data-default-class,
    dependent-sum,
    dependent-sum-template,
    filepath,
    hashable,
    hspec,
    memory,
    nix-derivation,
    some,
    tasty,
    tasty-discover,
    tasty-golden,
    tasty-hspec,
    text,
    time,
    unordered-containers,
    vector,
  }:
  mkDerivation {
    pname = "hnix-store-core";
    version = "0.8.0.0";
    sha256 = "1i6wdag25g3588mcxy1z09c22p45dd71cw1654l05gfxwhj05ivc";
    libraryHaskellDepends = [
      attoparsec
      base
      base16-bytestring
      base64-bytestring
      bytestring
      constraints-extras
      containers
      crypton
      data-default-class
      dependent-sum
      dependent-sum-template
      filepath
      hashable
      memory
      nix-derivation
      some
      text
      time
      unordered-containers
      vector
    ];
    testHaskellDepends = [
      attoparsec
      base
      base16-bytestring
      base64-bytestring
      bytestring
      containers
      crypton
      data-default-class
      hspec
      tasty
      tasty-golden
      tasty-hspec
      text
      time
      unordered-containers
    ];
    testToolDepends = [ tasty-discover ];
    description = "Core types used for interacting with the Nix store";
    license = lib.meta.getLicenseFromSpdxId "Apache-2.0";
  }
) { }
