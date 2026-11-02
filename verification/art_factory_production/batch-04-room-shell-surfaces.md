# Batch 4 — photographed room shell surfaces

## Selection and scope

This was a two-asset, closely related Tier 1 surface batch for the photographed `room_photo_luna` room. The carpet spans the 156 × 144 inch floor; the matte green finish spans all four existing wall planes. Both are highly visible in the room overview and have source-photo references. These are material replacements, not constructed-geometry replacements; RoomDefinition still owns all dimensions, openings, collision, navigation, and furniture placement.

The inventory was refreshed after promotion: 95 visible-art classes (48 Tier 1, 11 Tier 2, 36 Tier 3), 21 RoomDefinitions, 318 object records, and 15 accepted canonical Art Factory IDs. At the class-row level, 8 Tier 1 rows currently point to accepted IDs; two desk aliases inherit the recorded strict failure for desk v007, and 46 Tier 1 rows have no strict-gate result. These are inventory rows, not counts of unique production-quality objects.

## Production attempts and dispositions

| Asset | Target and 3D attempts | Result |
|---|---|---|
| `room_shell_floor` | Visual Director round 02 approved a seamless warm gray-beige carpet target after the round-01 target showed an edge mismatch. v001 exposed both a visible repeat seam and over-bright output. v002 removed the seam and square repeat, but the integrated room still read too bright. v003 applied the diagnosed linear albedo tint correction while keeping the approved target, 8-inch world repeat, roughness, normal map, and geometry fixed. | **Promoted `room_shell_floor-v003`.** Godot validation passed at exact 156 × 1 × 144 inch sample bounds. The production close view shows dense short pile without a visible tile seam; room-scale value is closer to the photograph and previous floor. |
| `room_shell_wall_finish` | Visual Director round 02 approved a seamless deep green paint target. v001 showed a 12-inch repeating-square pattern. v002 increased the world repeat to 24 inches; the square pattern disappeared while the matte color and fine stipple remained. | **Promoted `room_shell_wall_finish-v002`.** Godot validation passed at exact 156 × 108 × 2 inch sample bounds. Four source wall planes and every opening stayed under RoomDefinition control. |

Both approved round-02 targets passed pixel edge inspection: carpet opposite edges have 0 mean RGB difference and no more than 1 level; wall target edges match exactly. Candidate evaluations reference only their own registered production renders. Canonical registry hashes, Visual Director production state, and candidate evaluations agree; `cli verify` passes for both assets.

The adjacent French-door record remains **continue/backlog**. v002 has no legible hinges or latch, reads as opaque dark glazing, and the supplied room photograph does not depict the door. I removed its stale unregistered `asset_id` from the live room so production does not imply an accepted candidate. `VisualResolver` now treats any explicit but unregistered `asset_id` as a required-asset failure instead of silently switching to catalog geometry; a regression assertion covers this case. The door opening and RoomDefinition geometry remain unchanged.

## Matched whole-room comparison

Baseline: [same-camera production room without the two new surface IDs](../../art/room_photo_window_production/iterations/v004/render-runs/run-002/room-scale.png). Candidate: [floor v003 with the wall v002 review dependency](../../art/room_shell_floor/iterations/v003/render-runs/run-002/room-scale.png). Both use Godot 4.7.2 Compatibility, 1280 × 720, focus `(0, 12, 0)`, distance 330 inches, tilt 52°, yaw 1.5708, and FOV 55°. The no-surface baseline used the same room definition, with only the floor/wall asset IDs removed; the unaccepted French-door ID was removed from both captures.

The candidate overview changes the flat light gray floor to a warm gray-brown short-pile carpet and gives the continuous walls a deep matte green finish. Furniture, openings, room outline, and composition remain aligned. At clear floor pixel `(500, 480)`, RGB changes from `(202, 199, 194)` to `(129, 121, 110)`; this is a rendered value comparison, not a calibrated photo-color measurement. Both captures report 1203 draw calls and 614,471 primitives, so these materials add no measured geometry/draw-call cost in the overview.

The carpet still needs continued review in ordinary gameplay lighting, and both surface candidates are intentionally described as material work rather than a substitute for more constructed human-room assets. The French door, broad furniture, generic room lighting, and civilization faction identity remain visible weaknesses.

## Gameplay, performance, and CI

- 50-citizen real-renderer benchmark on an RTX 5090: room 330.5 FPS / 3.01 ms median / 3.60 ms p95; settlement 368.3 FPS / 2.69 ms median / 3.21 ms p95; citizen close 393.5 FPS / 2.51 ms median / 3.05 ms p95. This is one high-end machine, not a low-end hardware claim. Full report: [batch-04 performance JSON](batch-04-performance-room-photo.json).
- Full `room_photo_luna` production gameplay smoke passed M2–M8 with 50 citizens: navigation, investigations, 11 deliveries, three construction stages, grapple deployment, climbing, three explorers, persistent link/reuse, and presentation. Log: [photo-room gameplay smoke](batch-04-room-photo-clockwork-smoke.log).
- `TEST_ROOM_SCALE.ps1 -Mode Fast` passed. Ruff check/format, all 24 Art Factory integrity tests, Godot import, visual resolver, accepted asset validation, presentation, civilization contracts, innovation contracts/live determinism, cancellation recovery, extensibility (3/3), and Verdant living-structure (3/3) passed. The full 4/4 Room A/B clockwork/verdant production smoke matrix passed with 50 citizens. Logs: [Room A Clockwork](batch-04/ci-smoke/room_a-clockwork.log), [Room A Verdant](batch-04/ci-smoke/room_a-verdant.log), [Room B Clockwork](batch-04/ci-smoke/room_b-clockwork.log), [Room B Verdant](batch-04/ci-smoke/room_b-verdant.log).

## Cumulative coverage and next priority

The canonical production registry now has 15 IDs. This batch adds two accepted Tier 1 room-surface IDs; it does not make the scene-wide migration complete. Inventory coverage remains dominated by unregistered classes and runtime geometry. The next batch should prioritize the instantiated Room A/B furniture families with the most repeated active use—assembly table, chair, side table, elevated workbench, floor cabinet, and tool wardrobe—while keeping the desk v007 plateau backlogged instead of restarting its material loop.

Detailed records: [floor evaluation](../../art/room_shell_floor/iterations/v003/evaluation.json), [wall evaluation](../../art/room_shell_wall_finish/iterations/v002/evaluation.json), [updated visual inventory](visual_inventory.md), and [production art backlog](production-art-backlog.md).
