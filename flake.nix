{
  description = "Haskell packages";

  inputs = {
    corepkgs.url = "github:ekala-project/corepkgs";
  };

  outputs =
    { self, corepkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (s: {
            name = s;
            value = f s;
          }) systems
        );
      pkgsModule = import ./pkgs-module.nix;
    in
    {
      legacyPackages = forAllSystems (
        system:
        import corepkgs {
          inherit system;
          modules = [ pkgsModule ];
        }
      );
    };
}
