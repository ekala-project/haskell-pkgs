---
name: update-packages
description: Update Haskell packages — bump the Hackage snapshot and regenerate hackage-packages.nix, or update a single package — then fix eval/build fallout
disable-model-invocation: true
allowed-tools: Bash(nix *) Bash(nix-build *) Bash(nix-instantiate *) Bash(git *) Bash(bash ci/*) Bash(./scripts/*) Bash(scripts/*) Bash(python3 scripts/*) Bash(jq *) Bash(grep *) Bash(ls *) Bash(diff *) Read Edit Glob Grep
---

## Overview

There are two kinds of update:

- **Full update** (default): bump the all-cabal-hashes snapshot, regenerate
  `hackage-packages.nix` and `top-level.nix`, then fix what breaks.
- **Single package** (when a package name is given as an argument): move
  one package to a newer version without regenerating the whole set.

If the corepkgs pin also needs bumping, run the `update-pins` skill first
and leave this skill for afterwards, so pin fallout and Hackage fallout end
up in separate commits.

Start from a clean working tree (`git status`). If it isn't clean, stop
and ask.

## Full update

### 1. Record the baseline

Before changing anything, save what the hand-fixes depend on, because
regeneration overwrites `hackage-packages.nix`:

```
git rev-parse HEAD
grep -c ' or null;' hackage-packages.nix
grep -o '[a-zA-Z0-9_-]* = pkgs\.[a-zA-Z0-9_.]*;' hackage-packages.nix | sort -u > /tmp/hp-renamed-sysdeps.txt
```

That last file lists the system-dependency renames applied by hand in
earlier `rename <old> to <new>` commits (e.g. `SDL2 = pkgs.sdl2-compat`).
Also run `git log --oneline --grep '^rename ' -- hackage-packages.nix`
to see them.

### 2. Bump the Hackage snapshot

```
scripts/update-hackage.sh
```

If it prints "Already up to date", stop and report that. Otherwise commit
`data/hackage/pin.json` together with the regeneration in step 3, not on
its own.

### 3. Regenerate

```
scripts/regenerate-hackage-packages.sh [--nixpkgs PATH]
```

This needs a nixpkgs checkout, used only to build hackage2ekapkgs. The
default is `$NIXPKGS_PATH` or `/home/jon/projects/nixpkgs`.

**Check where the output went.** The script passes
`--output-dir "$REPO_ROOT/hackage"`, but the repo uses a single
`hackage-packages.nix`, which is what `pkgs-module.nix` imports and
`postprocess-hackage-packages.py` rewrites. After it runs:

- Check `git status`. If `hackage-packages.nix` is unchanged and a
  new `hackage/` directory appeared instead, **stop and report it to
  the user**. Don't wire a new layout in on your own.
- If `hackage-packages.nix` changed, continue.

### 4. Restore system-dependency renames

The generator emits upstream nixpkgs attribute names. The post-processor
turns any name missing from corepkgs into `<name> = pkgs.<name> or null;`
with `broken = !(pkgs ? <name>);`. That would silently mark a package
broken when its dependency was only renamed.

Compare against the baseline:

```
grep -o '[a-zA-Z0-9_-]* = pkgs\.[a-zA-Z0-9_.]*;' hackage-packages.nix | sort -u > /tmp/hp-renamed-sysdeps.new
diff /tmp/hp-renamed-sysdeps.txt /tmp/hp-renamed-sysdeps.new
grep -o '[a-zA-Z0-9_]* = pkgs\.[a-zA-Z0-9_]* or null;' hackage-packages.nix | sort | uniq -c | sort -rn
```

For every `or null` name that isn't in `ci/known-missing-sysdeps.nix`,
find its canonical corepkgs name (see the `update-pins` skill, step 4) and
re-apply the rename. Apply it to every package that uses it: rename the
lambda parameter, update its uses in the body, change the call argument to
`new-name = pkgs.new.name;`, and remove the `broken = !(pkgs ? old)` term
it added.

Fold these into the regeneration commit. They restore earlier work, so
they aren't new renames.

### 5. Regenerate top-level.nix

```
python3 scripts/generate-top-level.py
```

### 6. Eval gate

```
bash ci/eval.sh
```

Fix failures as described in the `update-pins` skill. If a name in
`ci/known-missing-sysdeps.nix` shows up as newly available, remove it from
the list.

### 7. Commit the regeneration

Stage `data/hackage/pin.json`, `hackage-packages.nix`, `top-level.nix`
and `ci/known-missing-sysdeps.nix` (if it changed). Use the snapshot date
from the `msg` field of `pin.json` in the commit message:

```
hackage-packages: update to Hackage snapshot <YYYY-MM-DD>
```

### 8. Review overrides

The overrides in `haskell-packages.nix` and `pkgs/` were written for the
old versions. For each one:

1. Find the newly generated version:
   `grep -n -A3 '^  <name> = callPackage' hackage-packages.nix`.
2. Ask whether the override is still needed:
   - **Inline `callPackage` version bump** (e.g. `hnix-store-core`): if
     the generated version is now ≥ the pinned one, delete the override.
   - **`doJailbreak`**: try without it. Keep it only if the build fails on
     bounds.
   - **Source patches / `postPatch`**: check whether upstream fixed it
     (the comment usually cites the upstream commit).
   - **`pkgs/<name>`**: compare its version with the Hackage one. If
     Hackage has caught up, delete the directory (and regenerate
     `top-level.nix`).
3. Build it: `nix-build -A haskellPackages.<name>`.

Make one commit per override removed or changed
(`<pkg>: drop doJailbreak`, `<pkg>: remove override, fixed upstream`).

### 9. Build the important consumers

Build every attribute overridden in `haskell-packages.nix` and `pkgs/`,
plus the tools other repos depend on:

```
nix-build --no-out-link -A cachix -A nixfmt -A nix-output-monitor
```

Haskell builds are slow. Run long builds in the background and keep
working on other fixes in the meantime.

For new failures, fix them in `haskell-packages.nix` (one commit per
package, `<pkg>: <succinct fix>`) and comment on *why*. Use these, in
order of preference:

- Bounds only → `doJailbreak`
- Test-suite failure that isn't a real bug → `dontCheck`
- Needs an older or newer dependency → pin it in
  `configuration-hackage2nix/main.yaml` (`default-package-overrides`, with
  a dated comment) and regenerate. Use an inline override only for a
  one-off.
- Genuinely broken upstream → add it to
  `configuration-hackage2nix/broken.yaml` and regenerate

### 10. Summary

Report:
- Old → new Hackage snapshot (commit and date)
- Number of packages added, removed or changed
  (`git diff --stat` and a count of `version =` changes)
- Renames restored, and known-missing deps that are now available
- Overrides removed or changed
- Builds that still fail, with the error summary for each

## Single package update

Use this when a package name is given.

1. Find the current version:
   `nix-instantiate --eval -A haskellPackages.<name>.version`.
2. Decide where the new version belongs:
   - **On Hackage, within the current snapshot:** pin it in
     `configuration-hackage2nix/main.yaml` and do a full regeneration
     (steps 3–7). Use this only if a regeneration is acceptable;
     otherwise use the next option.
   - **On Hackage, quick one-off:** add an inline
     `prev.callPackage ({ mkDerivation, ... }: mkDerivation { ... }) { }`
     to `haskell-packages.nix`, modelled on `hnix-store-core`. Get the
     expression from `cabal2nix cabal://<name>-<version>` (run it with
     `nix run nixpkgs#cabal2nix --`). Comment on why the bump is needed.
   - **Not on Hackage / git source:** create or update
     `pkgs/<name>/default.nix` (see `pkgs/nixfmt`), and run
     `python3 scripts/generate-top-level.py` if it ships an executable.
3. Build it and its reverse dependencies in this repo's overrides:
   `nix-build -A haskellPackages.<name>`.
4. Run `bash ci/eval.sh`.
5. Commit: `<name>: <old version> -> <new version>`.
