# Continuation passing style of import
# Values we care to modify are modified, while all other
# arguments are "passed through" to the next scope
{
  modules ? [ ],
  ...
}@args:

let
  pkgsModule = import ./pkgs-module.nix;
  pins = import ./pins.nix;
  filteredAttrs = builtins.removeAttrs args [
    "modules"
  ];
in

import pins.corepkgs (
  {
    modules = [ pkgsModule ] ++ modules;
  }
  // filteredAttrs
)
