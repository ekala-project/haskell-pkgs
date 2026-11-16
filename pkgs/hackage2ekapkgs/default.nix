{
  mkDerivation,
  lib,
  fetchFromGitHub,
  aeson,
  ansi-terminal,
  base,
  bytestring,
  Cabal,
  containers,
  deepseq,
  directory,
  filepath,
  hackage-db,
  hopenssl,
  hpack,
  lens,
  monad-par,
  monad-par-extras,
  mtl,
  optparse-applicative,
  parsec-class,
  pretty,
  prettyprinter,
  process,
  QuickCheck,
  split,
  text,
  time,
  transformers,
  yaml,
}:
mkDerivation {
  pname = "hackage2ekapkgs";
  version = "0.1.0.0-unstable-2026-07-24";
  # Generator for hackage-packages.nix. Pinned so that regeneration is
  # reproducible; scripts/regenerate-hackage-packages.sh --hackage2ekapkgs
  # overrides src with a local checkout for development.
  src = fetchFromGitHub {
    owner = "ekala-project";
    repo = "hackage2ekapkgs";
    rev = "e6e39abdc1083bb998907329cdc7a0daa2e2b9cb";
    hash = "sha256-SO0GlShcMK2y1KIB5cfp7rDWCiE4szAYcQyieE4wmk0=";
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson
    ansi-terminal
    base
    bytestring
    Cabal
    containers
    deepseq
    directory
    filepath
    hackage-db
    hopenssl
    hpack
    lens
    optparse-applicative
    parsec-class
    pretty
    prettyprinter
    process
    QuickCheck
    split
    text
    time
    transformers
    yaml
  ];
  executableHaskellDepends = [
    aeson
    base
    bytestring
    Cabal
    containers
    directory
    filepath
    hopenssl
    lens
    monad-par
    monad-par-extras
    mtl
    optparse-applicative
    pretty
  ];
  description = "Generate per-package Nix expressions from Hackage for ekapkgs";
  homepage = "https://github.com/ekala-project/hackage2ekapkgs";
  license = lib.licenses.bsd3;
  mainProgram = "hackage2ekapkgs";
}
