# Batch 16 — Reconstructed-Room French Door, Round 03

## Target and scope

The highest-priority open architectural item was the source-conditioned French-door pair. The previous r02 episode had exhausted three attempts. A new three-quarter target (r03) was approved for paired four-row glazing, exposed hinges, readable jamb depth, clear glazing, and restrained stained-oak figure. The target image was directly pixel-inspected and approved by Codex; this review is not attributed to Luna.

Target: [approved r03 image](../../art/room_photo_french_door_production/visual_director/round-03/approved-target-r03.png), [pixel-review evidence](../../art/room_photo_french_door_production/visual_director/round-03/pixel-review-r03.md). Target SHA-256: `381f0ec6dbd63f51032f5e9b8e276e90a9b9d82d247f4172982d66e179900be7`.

The target episode used three bounded 3D strategies. All renders used the same review copy at `art/room_photo_french_door_production/iterations/v003/review/room_photo_luna.json`. No RoomDefinition, opening placement, collision, navigation, selection, simulation, or production registry entry changed.

## Candidate outcomes

| Candidate | Technical result | Pixel review and disposition |
|---|---|---|
| [v009](../../art/room_photo_french_door_production/iterations/v009/evaluation.json) | Godot import succeeded, but bounds were 66 × 82 × 4.615 in. | The r03 oak map and front-mounted hinge plates improved on v008: all six hinge locations became visible and the four-row layout transferred. Depth exceeded the brief by 0.615 in, and the oak streaks remained repetitive. Rejected for exact-envelope failure. [Detail](../../art/room_photo_french_door_production/iterations/v009/render-runs/run-002/asset-detail.png), [three-quarter](../../art/room_photo_french_door_production/iterations/v009/render-runs/run-002/asset-three-quarter.png). |
| [v010](../../art/room_photo_french_door_production/iterations/v010/evaluation.json) | 66 × 82 × 4 in; six meshes, six surfaces, 59,188 triangles; no import issues. | Recessing the stepped casing and constraining hardware to the envelope fixed depth. All six hinge locations and the four-row lights remain visible. Oak is still narrow-grained and repetitive; retain as the best 3D review candidate, not a production pass. [Detail](../../art/room_photo_french_door_production/iterations/v010/render-runs/run-001/asset-detail.png), [three-quarter](../../art/room_photo_french_door_production/iterations/v010/render-runs/run-001/asset-three-quarter.png). |
| [v011](../../art/room_photo_french_door_production/iterations/v011/evaluation.json) | 66 × 82 × 4 in; six meshes, six surfaces, 59,188 triangles; no import issues. | Switched from the repeated image tile to baked anisotropic procedural PBR. The wood became nearly uniform brown and lost the target figure. Rejected as worse than v010. [Detail](../../art/room_photo_french_door_production/iterations/v011/render-runs/run-001/asset-detail.png), [three-quarter](../../art/room_photo_french_door_production/iterations/v011/render-runs/run-001/asset-three-quarter.png). |

The Visual Director episode is backlogged after its third strategy. `visual-director/state.json` retains v010 as `best_3d_candidate`; `production_asset` remains null. No candidate was promoted, and the canonical registry remains at 15 entries.

## Validator correction

The original technical gate accepted v009 because its 15.4% depth excess remained within the generic 20% proportion-ratio tolerance. That was insufficient for this ArtBrief’s exact 4-inch opening depth. Added optional `dimension_tolerance_inches` to ArtBrief, set the door brief to 0.01 in, and made Godot validation check each axis independently when a brief declares that tolerance. The Python model rejects non-finite and negative tolerances. Revalidation now records v009 as fail and accepts v010/v011 at their exact dimensions. This does not change legacy briefs that omit the field.

## Integrated room review

The production-path renderer captured the room overview, opposite angle, settlement scale, three-quarter, interior-oblique, profile, and detail views with 50 citizens present. The overview reads as a paired door in the existing opening, but its 330-inch camera does not show a clear whole-scene quality gain over v008. Hinge construction and material differences are clearest in detail and three-quarter views.

The registered reconstructed room has blue-gray exterior context behind the door. The glass remains clear, but this render cannot establish the concept’s garden colors. No foliage was added to the door mesh or invented in the production room.

## Matched 50-citizen performance

Godot 4.7.2, GL Compatibility, NVIDIA RTX 5090, VSync disabled. Both runs used the same review RoomDefinition, 50 citizens, camera views, and warmed 8-second sampling windows. The comparison is review candidate v005 versus v010, not a production-registry A/B.

| View | v005 median / p95 ms | v010 median / p95 ms | Draw calls | Primitives |
|---|---:|---:|---:|---:|
| Room | 3.021 / 4.164 | 3.005 / 3.657 | 1,241 → 1,241 | 703,587 → 696,525 |
| Settlement | 2.739 / 3.373 | 2.641 / 3.160 | 1,380 → 1,303 | 992,948 → 931,292 |
| Citizen | 2.587 / 3.404 | 2.463 / 2.998 | 919 → 872 | 1,010,638 → 976,166 |

These single-session samples show no measurable rendering-cost regression from v010. See [v005 raw measurements](batch-16/performance-v005.json) and [v010 raw measurements](batch-16/performance-v010.json); they are not a broad performance guarantee.

## Verification and next priority

- `python scripts/test_art_factory.py`: 27 tests passed.
- Ruff passed for `models.py`, `test_art_factory.py`, and the modified Blender generator.
- Python compilation passed for the same three files.
- Godot import/validation passed for v010 and v011; the new exact-dimension gate correctly rejects v009.
- French-door backlog updated; the generated full inventory still covers 95 visible-art classes across 21 RoomDefinitions and 318 room-object records.

The next ranked batch is a materially different desk transfer strategy. Room shell trim and French-door oak/context defects remain explicit backlog items. Full-game visual migration remains incomplete; no Tier 1 asset was promoted in this batch.
