# Post-processing overlay for per-package fixes.
# Applied after auto-called packages from pkgs/.
final: prev:
let
  # Use the nix-store subcomponent instead of the full nix wrapper package.
  # The full nix package pulls in nix-manual (needs mdbook/Rust) and
  # nix-functional-tests (needs mercurial/Rust) as build-time deps.
  nix-store-lib = prev.pkgs.nixVersions.stable.libs.nix-store;
in
{
  hercules-ci-cnix-store = prev.hercules-ci-cnix-store.override { nix = nix-store-lib; };
  hercules-ci-cnix-expr = prev.hercules-ci-cnix-expr.override { nix = nix-store-lib; };
  cachix = prev.cachix.override { nix = nix-store-lib; };
}
