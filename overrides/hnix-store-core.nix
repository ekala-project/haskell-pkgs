# cachix and hnix-store-nar require hnix-store-core >= 0.8. This replaces
# the default for all consumers; main.yaml keeps the generated default below
# 0.7 only because hnix 0.17 needs it, and generates 0.8.0.0 because 0.9
# requires crypton >= 1.1.
{ prev, ... }:
prev.hnix-store-core_0_8_0_0
