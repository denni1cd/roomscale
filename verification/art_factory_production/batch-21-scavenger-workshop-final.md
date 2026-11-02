# Batch 21 — Scavenger Workshop Gameplay-Scale Review

## Scope and decision

This batch transferred the Luna-approved Scavenger appliance-workshop target into a presentation-only GLB and used the full three-attempt Visual Director budget. It created new Blender geometry and baked PBR material maps for candidates v001-v003. The live accepted registry was not changed; none of the candidates was promoted.

v001 established the salvage construction. Luna's matched settlement capture found the long canopy hid the working front and scored gameplay readability 2/5. v002 raised and shortened the front eave and improved gameplay readability to 3/5. For v003, a materially different rear-set, braced canopy exposed more of the work bay, while broad-scale baked enamel and galvanized patina changed the material method.

Godot 4.7.2 validation passed at 25.90 × 19.16 × 19.36 inches, with 10 meshes/surfaces and 107,784 triangles. The mesh remains presentation-only. No RoomDefinition, station, collision, navigation, selection, construction, citizen assignment, or simulation logic changed.

Luna inspected the approved target and actual v002/v003 Godot captures at matching distances. v003 is the best current review candidate because its bench and work bay are clearer in close views and its braced canopy is plausible. At the identical 64-inch settlement camera, v003 remains 3/5 and does not read materially better than v002; hand tools and small salvage details still collapse. The 330-inch human-room views do not show a room-wide change. A bright cog remains a mild Clockwork cue. The third attempt did not pass the production gate, so the approved target episode is backlogged. No fourth attempt is allowed under this target.

## Gameplay-distance evidence

- [v002 settlement camera](../../art/scavenger_workshop/iterations/v002/render-runs/run-001/settlement-scale.png)
- [v003 settlement camera](../../art/scavenger_workshop/iterations/v003/render-runs/run-002/settlement-scale.png)
- [v003 close three-quarter](../../art/scavenger_workshop/iterations/v003/render-runs/run-002/asset-three-quarter.png)
- [v003 330-inch room overview](../../art/scavenger_workshop/iterations/v003/render-runs/run-002/room-scale.png)
- [Luna's v003 pixel review](../../art/scavenger_workshop/iterations/v003/review-luna.md)
- [v003 strict evaluation](../../art/scavenger_workshop/iterations/v003/evaluation.json)

The settlement capture answers the close-up question: the exposed work bay is a useful improvement when inspecting the building, but not a material improvement at the normal gameplay distance. The room view remains too wide to show a difference.

## Disposition

- Attempts: `scavenger_workshop-v001`, `v002`, and `v003`.
- Best current 3D review candidate: v003.
- Accepted production asset: none; the canonical registry has no `scavenger_workshop` entry.
- Promotion: none. Production remains on the pre-existing presentation path.
- Target episode: backlogged after attempt 3 for unresolved settlement-distance readability and close-craft transfer.
- Performance: no warmed 50-citizen comparison was run for this single review-only workshop asset.
- Next priority: use the ranked inventory to select another high-impact faction-identity target; do not continue this workshop target episode.
