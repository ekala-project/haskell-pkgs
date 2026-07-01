{ mkDerivation, lib, fetchFromGitHub
, ansi-terminal, async, attoparsec, base, bytestring, cassava
, containers, directory, extra, filelock, filepath, hermes-json
, MemoTrie, nix-derivation, optics, relude, safe, safe-exceptions
, stm, streamly-core, strict, strict-types, terminal-size, text
, time, transformers, word8
, typed-process, unix
}:
mkDerivation {
  pname = "nix-output-monitor";
  version = "2.1.6";
  src = fetchFromGitHub {
    owner = "maralorn";
    repo = "nix-output-monitor";
    rev = "v2.1.6";
    hash = "sha256-YfxFcGD9U7RzctnTRUQX1Nsz2EtiDIUGpz2nTo0OSWw=";
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    ansi-terminal async attoparsec base bytestring cassava containers
    directory extra filelock filepath hermes-json MemoTrie
    nix-derivation optics relude safe safe-exceptions stm streamly-core
    strict strict-types terminal-size text time transformers word8
  ];
  executableHaskellDepends = [
    base typed-process unix
  ];
  description = "Pipe nix-build output through nom for additional information";
  license = lib.licenses.agpl3Plus;
  mainProgram = "nom";
}
