# amazonka 2.0 uses DisambiguateRecordFields, which GHC 9.10 rejects in
# re-export lists with duplicate field names. The upstream fix (d836f682)
# switches to DuplicateRecordFields.
haskellLib: pkg:
haskellLib.doJailbreak (
  haskellLib.overrideCabal (drv: {
    postPatch = (drv.postPatch or "") + ''
      find . -name '*.hs' -exec sed -i \
        's/DisambiguateRecordFields/DuplicateRecordFields/g' {} +
    '';
  }) pkg
)
