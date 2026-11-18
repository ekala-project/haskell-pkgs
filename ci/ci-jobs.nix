# Build smoke set for eka-ci (.ekaci/config.json): every package with a
# hand-written definition (pkgs/) or override (overrides/), which are the
# ones most likely to break when the generated set or corepkgs changes,
# plus a few widely used consumers.
#
# Usage:
#   nix-build ci/ci-jobs.nix
let
  pkgs = import ../. { };
  inherit (pkgs) lib;
  hp = pkgs.haskellPackages;

  names =
    dir: pred: builtins.attrNames (lib.filterAttrs pred (builtins.readDir dir));

  handWritten = names ../pkgs (_: type: type == "directory");
  overridden = map (lib.removeSuffix ".nix") (
    names ../overrides (
      name: type: type == "regular" && lib.hasSuffix ".nix" name && !lib.hasPrefix "_" name
    )
  );

  consumers = [
    "pandoc"
    "hledger"
    "ShellCheck"
  ];
in
lib.genAttrs (lib.unique (handWritten ++ overridden ++ consumers)) (n: hp.${n})
