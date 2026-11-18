# Setup.hs uses defaultUserHooks, which Cabal 3.12 (GHC 9.10) removed.
# csv has no configure script, so simpleUserHooks is equivalent.
{ prev, haskellLib, ... }:
haskellLib.overrideCabal (drv: {
  postPatch = (drv.postPatch or "") + ''
    substituteInPlace Setup.hs --replace-fail defaultUserHooks simpleUserHooks
  '';
}) prev.csv
