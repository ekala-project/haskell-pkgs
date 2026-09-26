---
name: update-pins
description: Update corepkgs pin and fix any haskell packages that reference renamed/removed attributes
disable-model-invocation: true
allowed-tools: Bash(nix *) Bash(git *) Bash(rm *) Bash(ls *) Bash(chmod *) Read Edit Glob Grep
---

## Overview

Update the corepkgs pin (both flake.lock and pins.nix), then run
`ci/eval.sh` to detect haskell packages that reference renamed or removed
corepkgs attributes. Fix any failures by updating the attribute references
in `hackage-packages.nix`, `haskell-packages.nix`, `aliases.nix`,
`top-level.nix`, or files under `pkgs/`.

## Steps

### 1. Update flake input

```
nix flake update
```

### 2. Sync pins.nix

Extract the corepkgs rev from `flake.lock` and update `pins.nix` to match:

```
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./flake.lock)' --json \
  | jq -r '.nodes.corepkgs.locked.rev'
```

Update the `rev` field in `pins.nix` to this value.

### 3. Run eval check

```
bash ci/eval.sh
```

If it passes, skip to step 6.

### 4. Fix missing attribute errors

When eval fails with `attribute 'foo' missing`, it means a haskell package
references a system dependency name that no longer exists in corepkgs
(aliases are disabled during eval).

Check the corepkgs aliases file to find the canonical name:

```
grep 'foo' /path/to/corepkgs/aliases/nixpkgs.nix
```

The alias entry has the form:
```nix
foo = renamed "foo" "bar.baz" bar.baz;
```

This means `foo` was renamed to `bar.baz`.

In `hackage-packages.nix`, the pattern is:
```nix
  somePackage = callPackage
    ({ mkDerivation, ..., foo, ... }:
     mkDerivation {
       ...
       librarySystemDepends = [ foo ];
       ...
     }) {inherit (pkgs) foo;};
```

Fix by:
1. Renaming the function parameter to a valid Nix identifier
   (e.g. `foo` → `bar-baz` using hyphens for dots)
2. Updating all uses of the old name inside the body
3. Changing the call argument from `inherit (pkgs) foo;` to
   `bar-baz = pkgs.bar.baz;`

**Make a separate commit for each renamed attribute** (not each file —
group all occurrences of the same rename into one commit).

### 5. Re-run eval

```
bash ci/eval.sh
```

Repeat steps 4–5 until eval passes.

### 6. Summary

Print a summary:
- Updated corepkgs pin revision
- Number of packages that evaluate successfully
- Any attribute renames that were applied
