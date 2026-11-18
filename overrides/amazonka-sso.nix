{ prev, haskellLib, ... }:
import ./_fix-amazonka.nix haskellLib prev.amazonka-sso
