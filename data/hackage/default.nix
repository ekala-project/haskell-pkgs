# Hackage database snapshot (unpacked all-cabal-hashes tree).
#
# pin.json's sha256 is the hash of the *unpacked* archive, as produced by
# `nix-prefetch-url --unpack` (see scripts/update-hackage.sh). GitHub archive
# tarballs are not guaranteed to be byte-stable, but their contents are.
{ lib, fetchzip }:
let
  pin = lib.importJSON ./pin.json;
in
fetchzip {
  inherit (pin) url sha256;
  name = "all-cabal-hashes-${lib.substring 0 7 pin.commit}";
  meta = {
    license = lib.licenses.mit;
  };
}
