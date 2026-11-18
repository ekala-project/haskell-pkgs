# cachix requires hnix-store-core >= 0.8. This replaces the default for all
# consumers; main.yaml keeps the generated default below 0.7 only because
# hnix 0.17 needs it.
{ prev, ... }:
prev.hnix-store-core_0_8_0_0
