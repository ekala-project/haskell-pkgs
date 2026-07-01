# Top-level overlay for exposing Haskell tools at the pkgs scope.
final: prev: {
  nix-output-monitor = final.haskellPackages.nix-output-monitor;
  nixfmt = final.haskellPackages.nixfmt;
  nixfmt-rfc-style = final.nixfmt;
}
