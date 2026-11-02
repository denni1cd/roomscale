# Batch 5 — Room A/B furniture family

## Selection and scope

This Tier 1 batch covered the six repeated Room A/B furniture IDs selected by the refreshed inventory: elevated workbench, assembly table, tool wardrobe, floor cabinet, chair, and side table. The brief bounds and all RoomDefinition positions, object identities, navigation footprints, work surfaces, anchors, and landmarks remained authoritative. The production registry and active RoomDefinitions were not changed.

The inventory still contains 95 visible-art class rows across 21 RoomDefinitions and 318 object records. It still has 15 canonical production Art Factory IDs. Before this batch, 8 Tier 1 rows mapped to accepted IDs, two desk aliases retained a failed strict result, and 46 Tier 1 rows had no strict result. Batch 5 added strict failed results for six further Tier 1 assets; no asset was promoted.

## Visual Director and candidate disposition

All six cases had separate approved visual targets and pixel-review evidence. Each asset received three 3D attempts: initial construction, a targeted wood-albedo/camera correction, and a materially different per-component directional wood-grain shader. All 18 candidates passed Godot technical bounds validation. The v003 scenes contain 27–92 component meshes each (63,360 triangles total). Full production-path room, gameplay-distance, three-quarter, oblique, profile, and detail captures were rendered and inspected.

| Asset | Final candidate | Visual result | Disposition |
|---|---|---|---|
| Elevated workbench | [`room_elevated_workbench-v003`](../../art/room_elevated_workbench/iterations/v003/evaluation.json) | Warm satin wood and directional grain are clearer; the vise, drawers, and broad joints still lack the target’s shaped profiles and fitted construction. | Best-current review; backlog |
| Assembly table | [`room_assembly_table-v003`](../../art/room_assembly_table/iterations/v003/evaluation.json) | Role and frame read; the Room B stool obstructs the close front view, and the component profiles remain simple. | Best-current review; backlog |
| Tool wardrobe | [`room_tool_wardrobe-v003`](../../art/room_tool_wardrobe/iterations/v003/evaluation.json) | Full gameplay and detail framing now include the crown; doors, moulding, and hinges still fall short of the approved craftsmanship. | Best-current review; backlog |
| Floor cabinet | [`room_floor_cabinet-v003`](../../art/room_floor_cabinet/iterations/v003/evaluation.json) | Drawer hierarchy and wood finish improve; case sides and fitted edges remain too simple. | Best-current review; backlog |
| Chair | [`room_chair-v003`](../../art/room_chair/iterations/v003/evaluation.json) | Grain and finish improve, but the fixed 25 × 19 × 23 inch envelope compresses the back; the render reads closer to a low bench than the approved spindle-chair target. | Best-current review; backlog |
| Side table | [`room_side_table-v003`](../../art/room_side_table/iterations/v003/evaluation.json) | Warmer material and turned-leg framing read more clearly; the top, apron, and shelf remain primitive component forms. | Best-current review; backlog |

The shader correction is a useful material improvement but does not meet the user’s replacement standard by itself. Repeated rounded boxes and cylinders still dominate the shapes, so no candidate passed the neutral-viewer, close-inspection, and craftsmanship gates. Each Visual Director case now records `backlog` at its three-attempt limit. The next furniture pass must use a mesh-authoring workflow that can produce the missing profiles and joins; do not spend another pass on color or shader changes alone.

## Whole-room comparison

Room A and Room B were rendered through the production harness with each room’s v003 family candidates loaded together. The new grain and warm timber make the candidate furniture read more cohesively than v002. Those are review-only captures; the active game is unchanged because no asset was promoted. The prior accepted production scene therefore remains the runtime baseline. Candidate render references: [Room A family](../../art/room_chair/iterations/v003/render-runs/run-005/room-scale.png) and [Room B family](../../art/room_tool_wardrobe/iterations/v003/render-runs/run-002/room-scale.png).

The chair remains semantically weak at gameplay distance within its supplied height. The assembly table’s room placement lets the Room B stool obstruct its front from the chosen close camera. The wardrobe detail view initially clipped the crown; its camera distance was corrected to 87.5 inches and the latest capture shows the full object. The gameplay camera is 81.2 inches for that 70-inch cabinet and remains 64 inches for shorter pieces.

## Performance and gameplay

The six review scenes have 274 component meshes and 63,360 triangles in total. These candidates were never installed in the production registry, so they add no runtime geometry or draw-call cost to the accepted game. The batch does not claim a new 50-citizen performance benchmark; the existing high-end RTX 5090 measurements remain the production baseline in [Batch 4](batch-04-room-shell-surfaces.md).

Room A/B object dimensions, collision, navigation, construction, delivery, and traversal remain unchanged. Exact-head verification runs are recorded under [`batch-05/ci`](batch-05/ci/). Ruff, 24 Art Factory integrity tests, Godot import, visual registry resolution, civilization/innovation contracts, live determinism, cancellation recovery, living-structure checks, focused Fast CI, conflict pressure, three-run mixed-combat determinism, five-run shared-world conflict determinism, three-run three-party conflict determinism, combined combat/live innovation, and second-room conflict all passed. The 50-citizen matrix passed Room A/Clockwork, Room A/Verdant, Room B/Clockwork, and Room B/Verdant. Each run passed M2, M3, M4, M5, M6, and M8 with production scenes enabled. Logs are stored in the matching `room_a-clockwork-smoke.log`, `room_a-verdant-smoke.log`, `room_b-clockwork-smoke.log`, and `room_b-verdant-smoke.log` files.

## Cumulative status and next priority

The canonical registry remains at 15 IDs. All six Batch 5 furniture candidates failed their candidate-level strict evaluations and remain review-only. In the refreshed inventory, the 48 Tier 1 rows include eight linked accepted IDs, two desk aliases with an assigned strict failure, and 46 rows without an assigned candidate strict result; the accepted IDs are included in those 46 because they have no assigned-candidate strict failure record. The registry cross-check and review-candidate evaluation counts are separate. The migration is not complete and the active human-room scene did not change in this batch.

At Batch 5 close, the next priority was to source a properly licensed French-door reference; Batch 6 completed that source-conditioned review without a promotion. Keep the six furniture v003 scenes as best-current review evidence, with future geometry work backlogged for a materially stronger mesh-authoring backend.
