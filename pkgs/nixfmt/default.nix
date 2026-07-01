{ mkDerivation, lib, fetchFromGitHub
, base, bytestring, cmdargs, containers, directory, file-embed
, filepath, megaparsec, mtl, parser-combinators, pretty-simple
, process, safe-exceptions, scientific, text, transformers, unix
}:
mkDerivation {
  pname = "nixfmt";
  version = "1.3.1";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixfmt";
    rev = "v1.3.1";
    hash = "sha256-FRqEYVeQ9zUYuurh/183fm13KFWVNTo3atSpn6H5EbA=";
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base containers megaparsec mtl parser-combinators pretty-simple
    scientific text transformers
  ];
  executableHaskellDepends = [
    base bytestring cmdargs directory file-embed filepath
    process safe-exceptions text transformers unix
  ];
  description = "The official formatter for Nix code";
  license = lib.licenses.mpl20;
  mainProgram = "nixfmt";
}
