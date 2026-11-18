---
name: update-pins
description: Update corepkgs pin, regenerate the Haskell package set against it, and map any renamed system dependencies
disable-model-invocation: true
allowed-tools: Bash(nix *) Bash(nix-build *) Bash(nix-instantiate *) Bash(git *) Bash(jq *) Bash(bash ci/*) Bash(ci/*) Bash(scripts/*) Bash(python3 *) Read Edit Glob Grep
---

## Overview

Update the corepkgs pin (both `flake.lock` and `pins.nix`), regenerate
`hackage-packages.nix` and `top-level.nix` against it, and fix fallout.

System dependencies are resolved at generation time against corepkgs with
aliases disabled. A dependency corepkgs renamed shows up after regeneration
as `broken = !(pkgs ? <name>)` on packages that used to build; map the old
name in `configuration-hackage2nix/system-dependency-paths.yaml` instead of
editing generated files.

## Steps

### 1. Update the pin

```
nix flake update corepkgs
rev=$(jq -r '.nodes.corepkgs.locked.rev' flake.lock)
sed -i "s/rev = \"[0-9a-f]\{40\}\"/rev = \"$rev\"/" pins.nix
```

### 2. Check the compiler

`compiler.nix` names the default GHC. If corepkgs removed or renamed it,
update `compiler.nix`. If the compiler's version changed, refresh its boot
package list:

```
scripts/generate-compiler-config.sh
```

(The regenerate script fails if `configuration-hackage2nix/compiler.yaml`
doesn't match the compiler's version.)

### 3. Regenerate

```
scripts/regenerate-hackage-packages.sh
```

This takes several minutes; run it in the background.

### 4. Review the diff

```
git diff --stat hackage-packages.nix top-level.nix
```

Look for packages whose `broken` changed from absent to
`!(pkgs ? <name>)`. For each newly missing `<name>`, find the corepkgs
attribute that replaced it (aliases list renames):

```
grep -rn '<name>' "$(nix-instantiate --eval --read-write-mode -E '"${(import ./pins.nix).corepkgs}"' | tr -d '"')"/aliases/
```

Add `<name>: <attr.path>` to `system-dependency-paths.yaml` (keep it sorted
case-insensitively; use `null` with a comment for libraries provided by libc
or the toolchain), then regenerate again. Remove entries whose target no
longer exists, or that the generator now resolves on its own.

Also look for packages that became buildable (`broken` dropped) — they are
expected when corepkgs gains a dependency.

### 5. Run the checks

```
bash ci/eval.sh
nix-instantiate --eval --strict ci/shadowed-packages.nix -A all --json
nix-build ci/ci-jobs.nix
```

`ci/eval.sh` must pass and the shadowed list must be empty (for a
`pkgs/` package that corepkgs now provides, delete it from `pkgs/`). Fix
build failures in the smoke set with `overrides/<attr>.nix` files (see
AGENTS.md).

### 6. Commit

- `corepkgs: update pin`, including the regenerated files and
  `system-dependency-paths.yaml` changes needed for the bump.
- Separate commits for unrelated fixes (e.g. `<pkg>: <message>` for an
  override).

### 7. Summary

Print:
- Old and new corepkgs revision
- Packages that became broken or buildable, and the mappings added
- Smoke-set build results
