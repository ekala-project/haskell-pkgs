# Post-processing overlay for per-package fixes.
# Applied after auto-called packages from pkgs/.
final: prev: {
  # Add package-specific overrides here as needed.
  # Example:
  #   some-package = prev.some-package.override { doCheck = false; };
}
