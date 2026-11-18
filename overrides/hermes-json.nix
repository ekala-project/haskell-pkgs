# hermes-json 0.9 requires text-iso8601 >= 0.2; Stackage pins 0.1.
{ prev, final, ... }:
prev.hermes-json.override { text-iso8601 = final.text-iso8601_0_2_0_0; }
