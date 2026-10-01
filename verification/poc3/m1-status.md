# Milestone 1 — PASS

The production room renderer now resolves semantics through a centralized
JSON catalog and `scripts/visuals/visual_resolver.gd`. RoomDefinition-derived
collision, navigation, and target selection are unchanged. Existing room and
photo appearance recipes are retained as the procedural fallback.

`logs/m1-resolver.log`: catalog loading, unknown archetype fallback, missing
preferred asset diagnostics/fallback, and transformed bounds PASS.
`logs/m1-fast.log`: prior deterministic assertions PASS, with the same
pre-existing shutdown resource leaks recorded in M0.
`logs/m1-room-a.log`: full production M2–M6/M8 PASS with 50 citizens,
all deliveries, construction, continuous traversal, exploration, and reuse.
Preferred imported-asset normalization is implemented but its GLB runtime
experiment remains M4 work; it is not claimed verified by the fallback test.

Existing procedural room structure and child names remain compatible.
M0 screenshots document the unchanged representations resolved at this gate.
