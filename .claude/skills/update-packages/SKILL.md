---
name: update-packages
description: Update Haskell packages — bump the Hackage snapshot and regenerate hackage-packages.nix, or update a single package — then fix eval/build fallout
disable-model-invocation: true
allowed-tools: Bash(nix *) Bash(nix-build *) Bash(nix-instantiate *) Bash(git *) Bash(bash ci/*) Bash(ci/*) Bash(./scripts/*) Bash(scripts/*) Bash(python3 *) Bash(jq *) Bash(grep *) Bash(ls *) Bash(diff *) Read Edit Glob Grep
---

## Overview

There are two kinds of update:

- **Full update** (default): bump the all-cabal-hashes snapshot, regenerate
  `hackage-packages.nix` and `top-level.nix`, then fix what breaks.
- **Single package** (when a package name is given as an argument): move
  one package to a newer version.

If the corepkgs pin also needs bumping, run the `update-pins` skill first,
so pin fallout and Hackage fallout end up in separate commits.

Start from a clean working tree (`git status`). If it isn't clean, stop
and ask.

Generated files are never edited by hand: every fix goes into
`configuration-hackage2nix/`, `overrides/` or `pkgs/` (see AGENTS.md), and
`ci/check-regeneration.sh` must pass at every commit.

## Full update

### 1. Bump the Hackage snapshot

```
scripts/update-hackage.sh
```

If it prints "Already up to date", stop and report that. Otherwise commit
`data/hackage/pin.json` together with the regeneration in step 2.

Stackage updates come with the snapshot: also refresh
`configuration-hackage2nix/stackage.yaml` if a newer LTS for the same GHC
series exists, and review `default-package-overrides` in `main.yaml` —
dated entries often say when they can be dropped.

### 2. Regenerate

```
scripts/regenerate-hackage-packages.sh
```

This takes several minutes (more if hackage2ekapkgs has to be rebuilt);
run it in the background.

### 3. Review the diff

```
git diff --stat hackage-packages.nix top-level.nix
git diff hackage-packages.nix | grep -E '^[-+] +version = ' | wc -l
```

Check packages whose `broken` changed. A new `broken = !(pkgs ? <name>)`
means a system dependency the generator couldn't find in corepkgs; if
corepkgs has it under another name, map it in
`configuration-hackage2nix/system-dependency-paths.yaml` and regenerate.

### 4. Eval gate

```
bash ci/eval.sh
nix-instantiate --eval --strict ci/shadowed-packages.nix -A all --json
```

### 5. Commit the regeneration

Stage `data/hackage/pin.json`, `configuration-hackage2nix/`,
`hackage-packages.nix` and `top-level.nix`. Use the snapshot date from the
`msg` field of `pin.json`:

```
hackage-packages: update to Hackage snapshot <YYYY-MM-DD>
```

### 6. Review overrides

Each `overrides/<attr>.nix` and `pkgs/<name>` was written for older
versions. For each one:

1. Find the newly generated version:
   `grep -n -A3 '^  <name> = callPackage' hackage-packages.nix`.
2. Ask whether it is still needed:
   - **Versioned attribute selection** (e.g. `overrides/hnix-store-core.nix`):
     if the default version has caught up, delete the file.
   - **`doJailbreak`**: try without it. Keep it only if the build fails on
     bounds.
   - **Source patches / `postPatch`**: check whether upstream fixed it
     (the comment usually cites the upstream commit).
   - **`pkgs/<name>`**: compare its version with the Hackage one. If
     Hackage has caught up, delete the directory and regenerate.
3. Build it: `nix-build -A haskellPackages.<name>`.

Make one commit per override removed or changed
(`<pkg>: drop doJailbreak`, `<pkg>: remove override, fixed upstream`).

### 7. Build the smoke set

```
nix-build ci/ci-jobs.nix
```

This covers every `pkgs/` package, every override and a few key
consumers. Haskell builds are slow: run it in the background and keep
working on other fixes in the meantime.

Fix new failures with one `overrides/<attr>.nix` per package (one commit
each, `<pkg>: <succinct fix>`, with a comment on *why*), preferring:

- Bounds only → `doJailbreak`
- Test-suite failure that isn't a real bug → `dontCheck`
- Needs an older or newer dependency → pin it in
  `configuration-hackage2nix/main.yaml` (`default-package-overrides`, with
  a dated comment) and regenerate; for a one-off, select a generated
  versioned attribute in an override file
- Genuinely broken upstream → add it to
  `configuration-hackage2nix/broken.yaml` and regenerate

### 8. Summary

Report:
- Old → new Hackage snapshot (commit and date)
- Number of packages added, removed or changed
- Packages that became broken or buildable, and mappings added
- Overrides removed or changed
- Builds that still fail, with the error summary for each

## Single package update

Use this when a package name is given.

1. Find the current version:
   `nix-instantiate --eval -A haskellPackages.<name>.version`.
2. Decide where the new version belongs:
   - **On Hackage, in the current snapshot, for everyone:** pin it in
     `default-package-overrides` in `configuration-hackage2nix/main.yaml`
     and regenerate.
   - **On Hackage, for one consumer or a one-off:** if the version isn't
     already generated as `<name>_<version>` (the latest Hackage version
     is, whenever the default is pinned lower), add it to
     `extra-packages` in `main.yaml` and regenerate. Then select the
     versioned attribute in `overrides/<name>.nix` (see
     `overrides/hnix-store-core.nix`), or pass it to the consumer with
     `.override`.
   - **Newer than the snapshot:** bump the snapshot (full update) instead.
   - **Not on Hackage / git source:** create or update
     `pkgs/<name>/default.nix` (see `pkgs/nixfmt`) and regenerate, which
     also refreshes `top-level.nix`.
3. Build it and the smoke set: `nix-build -A haskellPackages.<name>`,
   `nix-build ci/ci-jobs.nix`.
4. Run `bash ci/eval.sh` and `ci/check-regeneration.sh`.
5. Commit: `<name>: <old version> -> <new version>`.
