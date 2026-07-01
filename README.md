# haskell-packages

Central location to curate Haskell packages for the ekapkgs poly-repo ecosystem.

## Structure

- `default.nix` - Entry point. Fetches corepkgs + nix-lib, composes overlays, and injects them via `config.overlays.haskell`.
- `haskell-packages.nix` - Post-processing overlay for per-package fixes applied after auto-called packages.
- `top-level.nix` - Top-level overlay for exposing Haskell tools at the `pkgs` scope.
- `pkgs/` - Auto-called package directory. Each subdirectory `pkgs/<name>/default.nix` provides a Haskell package overlay entry.

## Usage

```nix
# Evaluate the full package set
nix-instantiate --eval -E '(import ./. {}).haskellPackages'

# Build a specific package (once packages are populated)
nix-build -E '(import ./. {}).haskellPackages.<package-name>'
```

## Adding packages

Create a directory `pkgs/<package-name>/default.nix` with a Haskell package definition using `mkDerivation` from the Haskell package set scope. These are automatically discovered and included in the package set via `mkAutoCalledPackageDir`.

## Relationship to other repos

- **corepkgs** - Provides core Haskell infrastructure (generic-builder, make-package-set, haskell.lib, GHC compilers)
- **haskell-packages** (this repo) - Provides curated Haskell package definitions via `config.overlays.haskell`
- **ekapkgs** - Top-level integrator that combines all downstream package repos
