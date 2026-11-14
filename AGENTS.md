# haskell-pkgs Agent Guide

This repository curates the Haskell package set for the ekapkgs poly-repo ecosystem, built on [ekala-project/corepkgs](https://github.com/ekala-project/corepkgs). corepkgs supplies the Haskell infrastructure (GHC compilers, `generic-builder`, `make-package-set`, `haskell.lib`); this repo supplies the package definitions via `config.overlays.haskell`.

## Repository Layout

| Path | Purpose |
|------|---------|
| [`default.nix`](default.nix) | Entry point; imports `pins.nix` and applies `pkgs-module.nix` via the corepkgs module system |
| [`pins.nix`](pins.nix) | Pinned corepkgs revision (must match `flake.lock`) |
| [`pkgs-module.nix`](pkgs-module.nix) | Composes the haskell overlay (`hackage-packages.nix` → `pkgs/` → `haskell-packages.nix`) and the top-level overlays; selects the default GHC (`haskellPackages = haskell.packages.ghc9103Binary`) |
| [`hackage-packages.nix`](hackage-packages.nix) | **Generated** (~365k lines) by hackage2ekapkgs + `scripts/postprocess-hackage-packages.py` |
| [`pkgs/`](pkgs/) | Hand-written Haskell packages, auto-called via `mkAutoCalledPackageDir`; these override same-named entries from `hackage-packages.nix` |
| [`haskell-packages.nix`](haskell-packages.nix) | Post-processing overlay for per-package fixes (jailbreaks, `overrideCabal`, version bumps, dependency overrides) |
| [`top-level.nix`](top-level.nix) | **Generated** by `scripts/generate-top-level.py`; exposes executables at `pkgs` scope via `justStaticExecutables` |
| [`aliases.nix`](aliases.nix) | Top-level mappings for system deps referenced by `hackage-packages.nix` whose names differ in corepkgs |
| [`configuration-hackage2nix/`](configuration-hackage2nix/) | hackage2nix config: `main.yaml`, `stackage.yaml`, `broken.yaml`, `transitive-broken.yaml` |
| [`data/hackage/`](data/hackage/) | all-cabal-hashes snapshot pin (`pin.json`) |
| [`scripts/`](scripts/) | Regeneration and update scripts |
| [`ci/`](ci/) | Eval checks |

## Commit Conventions

- **New packages:** `<pkg>: init at <version>`
- **Version updates:** `<pkg>: <old version> -> <new version>`
- **Build fixes:** `<pkg>: <succinct message>` (e.g. `lzma-conduit: doJailbreak for GHC 9.10`)
- **System-dep renames after a pin bump:** `rename <old> to <new>`, one commit per renamed attribute (all occurrences grouped together)
- **Do not** add AI attribution (e.g., `Co-Authored-By`) to commit messages
- **One logical change per commit** — squash small fixups into the commit they belong to rather than creating separate fixup commits

## Where to Make a Change

**Never hand-edit `hackage-packages.nix` or `top-level.nix` for ordinary fixes** — they are regenerated. The one exception is the system-dependency rename workflow in the [update-pins](.claude/skills/update-pins/SKILL.md) skill.

| Goal | Where |
|------|-------|
| Relax version bounds, patch sources, add/remove deps, disable tests | `haskell-packages.nix`, using `haskell.lib.compose` helpers (`doJailbreak`, `overrideCabal`, `dontCheck`, ...) |
| Use a newer version than Hackage/Stackage selects (one-off) | `haskell-packages.nix` with `prev.callPackage (...) { }` (see `hnix-store-core`), or a new `pkgs/<name>/default.nix` |
| Package not on Hackage, or built from a git source | `pkgs/<name>/default.nix` |
| Change which version hackage2nix generates | `configuration-hackage2nix/main.yaml` (`default-package-overrides`), then regenerate |
| Mark/unmark broken | `configuration-hackage2nix/broken.yaml`, then regenerate |
| System dep name differs in corepkgs | `aliases.nix` |
| System dep not yet in corepkgs | `ci/known-missing-sysdeps.nix` (remove it once corepkgs gains it) |
| Change the default GHC | `ghcOverlay` in `pkgs-module.nix` |

In `haskell-packages.nix`, take everything from `prev` (e.g. `prev.pkgs.boehmgc`, `prev.pkgs.haskell.lib.compose`) and add a comment explaining *why* each override exists (e.g. the upstream issue or GHC incompatibility).

## Writing Packages in `pkgs/`

The directory name becomes the attribute name in `haskellPackages`. Packages use the Haskell `mkDerivation`, not `stdenv.mkDerivation`:

```nix
{
  mkDerivation,
  lib,
  fetchFromGitHub,
  base,
  text,
}:
mkDerivation {
  pname = "<name>";
  version = "<version>";
  src = fetchFromGitHub {
    owner = "...";
    repo = "...";
    rev = "v<version>";
    hash = "sha256-...";
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [ base text ];
  executableHaskellDepends = [ base ];
  description = "...";
  license = lib.licenses.bsd3;
  mainProgram = "<exe>";
}
```

See [`pkgs/nixfmt`](pkgs/nixfmt/default.nix) and [`pkgs/cachix`](pkgs/cachix/default.nix) for working examples. `cabal2nix` output can be used as a starting point.

After a corepkgs pin bump, check whether anything in `pkgs/` now duplicates corepkgs:

```bash
nix-instantiate --eval --strict ci/shadowed-packages.nix -A all --json | jq .
```

## Validation

```bash
# Evaluate a package
nix-instantiate -A haskellPackages.<pkg>

# Build a package (or a top-level executable)
nix-build -A haskellPackages.<pkg>
nix-build -A <exe>

# CI eval gate: every `inherit (pkgs) <name>` system dep in
# hackage-packages.nix resolves with corepkgs aliases disabled
bash ci/eval.sh
```

Nix evaluation warnings make `ci/eval.sh` fail. If it reports an unexpected missing name, it was most likely renamed in corepkgs — fix the reference (see [update-pins](.claude/skills/update-pins/SKILL.md)) rather than adding it to `ci/known-missing-sysdeps.nix`.

Packages in `hackage-packages.nix` that need a system dep missing from corepkgs are generated as `<name> = pkgs.<name> or null;` with `broken = !(pkgs ? <name>);`, so they become buildable automatically once corepkgs gains the dependency.

## Regenerating

| Task | Command |
|------|---------|
| Update corepkgs pin and fix renamed attributes | [update-pins](.claude/skills/update-pins/SKILL.md) skill |
| Full Hackage update (snapshot bump → regenerate → fix fallout) or a single package bump | [update-packages](.claude/skills/update-packages/SKILL.md) skill |
| Bump the Hackage snapshot (`data/hackage/pin.json`) | `scripts/update-hackage.sh` |
| Regenerate `hackage-packages.nix` from the snapshot + `configuration-hackage2nix/` | `scripts/regenerate-hackage-packages.sh [--nixpkgs PATH] [--hackage2ekapkgs PATH]` (needs a nixpkgs checkout to build the tool) |
| Rewrite `or null` / `broken` markers for missing system deps | `scripts/postprocess-hackage-packages.py` (run automatically by the regenerate script) |
| Regenerate `top-level.nix` | `scripts/generate-top-level.py` |

After regenerating, re-run `bash ci/eval.sh` and rebuild any packages overridden in `haskell-packages.nix` or `pkgs/` — overrides may become obsolete or break with new versions.

## External Dependencies

| Pin | Repository | Purpose |
|-----|-----------|---------|
| `corepkgs` | [ekala-project/corepkgs](https://github.com/ekala-project/corepkgs) | Base package set, module system, GHC and Haskell infrastructure |
| all-cabal-hashes | [commercialhaskell/all-cabal-hashes](https://github.com/commercialhaskell/all-cabal-hashes) | Hackage snapshot used for generation |
| hackage2ekapkgs | [ekala-project/hackage2ekapkgs](https://github.com/ekala-project/hackage2ekapkgs) | Generator for `hackage-packages.nix` |
