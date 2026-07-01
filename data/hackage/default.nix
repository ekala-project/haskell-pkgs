# Hackage database snapshot
{ lib, fetchurl }:
let
  pin = lib.importJSON ./pin.json;
in
fetchurl (finalAttrs: {
  inherit (pin) url sha256;
  name = "${finalAttrs.pname}-${finalAttrs.version}.tar.gz";
  pname = "all-cabal-hashes";
  version = lib.substring 0 7 pin.commit;
  meta = {
    license = lib.licenses.mit;
  };
})
