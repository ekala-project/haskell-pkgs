# Build the closure in one consistent scope; see _hls-scope.nix.
# haskell-language-server links its executables dynamically: without
# enableSharedExecutables, the fixup check finds an RPATH into /build (as
# in nixpkgs' configuration-nix.nix).
{ prev, haskellLib, ... }:
haskellLib.overrideCabal { enableSharedExecutables = true; } (
  prev.haskell-language-server.overrideScope (import ./_hls-scope.nix haskellLib)
)
