#!/usr/bin/env python3
"""Post-process hackage-packages.nix after regeneration.

For system dependencies not available in corepkgs, replace:
    }) {inherit (pkgs) <name>;};
with:
    }) {<name> = pkgs.<name> or null;};
and set:
    broken = !(pkgs ? <name>);

The corepkgs package set is queried via `nix-instantiate --eval` to
determine which attrs actually exist.  Any `inherit (pkgs) <name>;`
where <name> is absent from corepkgs is converted.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HACKAGE_PACKAGES = REPO_ROOT / "hackage-packages.nix"


def available_pkgs() -> set[str]:
    """Return the set of top-level attribute names in the corepkgs set."""
    expr = "builtins.attrNames (import ./pins.nix).corepkgs.pkgs"
    try:
        out = subprocess.check_output(
            ["nix-instantiate", "--eval", "--json", "-E", expr],
            cwd=str(REPO_ROOT),
            stderr=subprocess.DEVNULL,
        )
        return set(json.loads(out))
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(
            "Warning: could not query corepkgs attrs; "
            "falling back to existing or-null markers",
            file=sys.stderr,
        )
        return set()


def collect_all_inherited_names(path: Path) -> set[str]:
    """Return every <name> that appears in `inherit (pkgs) <name>;`."""
    text = path.read_text()
    return set(re.findall(r"inherit\s+\(pkgs\)\s+(\w+)\s*;", text))


def transform(path: Path, missing: set[str]) -> None:
    if not missing:
        print("Nothing to transform.")
        return

    lines = path.read_text().splitlines(keepends=True)
    out: list[str] = []
    i = 0
    modifications = 0

    while i < len(lines):
        line = lines[i]

        # Detect closing override block: `    }) {`
        if re.match(r"\s*\}\)\s*\{", line):
            block_start = len(out)
            block_lines = [line]
            while not line.rstrip().endswith("};"):
                i += 1
                if i >= len(lines):
                    break
                line = lines[i]
                block_lines.append(line)
            block_text = "".join(block_lines)

            # Find inherits that reference missing packages
            inherits = re.findall(r"inherit\s+\(pkgs\)\s+(\w+)\s*;", block_text)
            missing_inherits = [n for n in inherits if n in missing]

            if missing_inherits:
                modifications += 1

                # Replace each missing inherit with `<name> = pkgs.<name> or null;`
                new_block = block_text
                for name in missing_inherits:
                    new_block = re.sub(
                        r"inherit\s+\(pkgs\)\s+" + re.escape(name) + r"\s*;",
                        f"{name} = pkgs.{name} or null;",
                        new_block,
                    )

                # Check if mkDerivation body already has a broken expression
                has_broken = False
                for j in range(block_start - 1, max(block_start - 200, -1), -1):
                    if "callPackage" in out[j]:
                        break
                    if re.search(r"broken\s*=", out[j]):
                        has_broken = True
                        break

                # Build the conditional broken expression
                conditions = [f"!(pkgs ? {dep})" for dep in missing_inherits]
                broken_expr = " || ".join(conditions)

                if has_broken:
                    # Replace existing broken line with conditional
                    for j in range(block_start - 1, max(block_start - 200, -1), -1):
                        if "callPackage" in out[j]:
                            break
                        if re.search(r"broken\s*=", out[j]):
                            indent = re.match(r"^(\s*)", out[j]).group(1)
                            out[j] = f"{indent}broken = {broken_expr};\n"
                            break
                else:
                    # Insert broken line before the closing `}) {`
                    indent_match = re.match(r"^(\s*)", lines[block_start])
                    indent = indent_match.group(1) if indent_match else "     "
                    out.append(f"{indent}  broken = {broken_expr};\n")

                out.append(new_block if new_block.endswith("\n") else new_block + "\n")
            else:
                out.extend(block_lines)
        else:
            out.append(line)

        i += 1

    path.write_text("".join(out))
    print(f"Transformed {modifications} packages with missing system deps.")


def main():
    # Determine which system deps are missing from corepkgs
    pkgs = available_pkgs()
    inherited = collect_all_inherited_names(HACKAGE_PACKAGES)

    if pkgs:
        missing = inherited - pkgs
    else:
        # Fallback: treat names already marked `or null` as missing
        text = HACKAGE_PACKAGES.read_text()
        missing = set(re.findall(r"(\w+)\s*=\s*pkgs\.\w+\s+or\s+null\s*;", text))
        # Also look for inherits that would fail
        print(f"Using {len(missing)} existing or-null markers as missing set.")

    print(f"System deps referenced: {len(inherited)}")
    print(f"Missing from corepkgs:  {len(missing)}")

    transform(HACKAGE_PACKAGES, missing)


if __name__ == "__main__":
    main()
