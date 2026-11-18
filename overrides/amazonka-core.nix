# Upper bounds exclude the GHC 9.10 boot libraries.
{ prev, haskellLib, ... }:
haskellLib.doJailbreak prev.amazonka-core
