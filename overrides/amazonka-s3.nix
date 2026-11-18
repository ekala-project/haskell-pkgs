{ prev, haskellLib, ... }:
import ./_fix-amazonka.nix haskellLib prev.amazonka-s3
