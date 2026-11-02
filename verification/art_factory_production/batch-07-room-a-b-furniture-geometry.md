# Batch 7 — Room A/B chair geometry pilot

## Selection and scope

Batch 5 identified missing target-specific profiles and fitted joints across six Tier 1 Room A/B furniture assets. The chair was selected as the first geometry pilot because its silhouette is scene-defining and its earlier three attempts had plateaued on rounded boxes, cylinders, and shader work. Its r01 target episode was exhausted, so Batch 7 generated and pixel-reviewed a materially clarified round-02 target with a new target hash. The candidate process preserved the exact 25 × 19 × 23 inch ArtBrief envelope and all RoomDefinition/gameplay authority.

## Visual Director and candidate results

The round-02 target was approved with pixel-review evidence. Exactly three attempts were used under that target:

| Candidate | Strategy | Technical result | Visual result and disposition |
|---|---|---|---|
| `room_chair-v004` | Initial custom mesh transfer: dished seat, lathed turned parts, swept crest | Pass; 29 meshes, 40,736 triangles, bounds 23.58 × 18.84 × 20.75 in. Lowest point was 0.066 in below floor. | Geometry became chair-shaped, but custom mesh winding and dark timber made several surfaces visually muddy. Continue. |
| `room_chair-v005` | Targeted correction: front-face winding, closed ends, rolled seat edge, brighter wood and visible pins | Pass; 29 meshes, 76,288 triangles, bounds 23.58 × 18.71 × 20.75 in. Lowest point is 0.058 in above floor. | Surfaces and turnings became legible. Seat dish, joinery, and finish still failed strict craftsmanship and realism. Continue. |
| `room_chair-v006` | Alternate strategy: flattened leaf-profile spindles, deeper seat dish, chair-specific satin wood shader | Pass; 29 meshes, 74,752 triangles, same in-envelope bounds and 0.058 in floor clearance. | Best review candidate. Grain and chair parts read better, but carved seat shaping, fitted joinery, and target-like wood variation remain below the strict gate. Continue/backlog. |

The target episode is now at its three-attempt limit and state is `backlog`. `room_chair-v006` is recorded as the best current review candidate; no candidate was promoted or rejected. The approved visual target, best 3D review candidate, and canonical production asset remain separate.

## Render and transfer review

Godot generation, technical validation, and production-path review captures passed. The first v004 render against canonical `rooms/room_a.json` did not instantiate the chair because the source object has no Art Factory `appearance.asset_id`. That failed log is preserved. Subsequent review renders use a room-copy in the iteration folder that changes only the chair’s `appearance` field; the object ID, position, dimensions, navigation, and every other RoomDefinition field match the source. Captures use `review_showcase`; no canonical room or registry entry was changed.

Compared with the Batch 5 v003 capture, v006 replaces the slab-like seat and simple round back members with a visibly shaped rim, sculpted legs, and broader leaf-profile spindles. In the whole-room capture the chair still occupies little screen area, so the improvement is clearest in the gameplay-distance and detail views. It remains review-only and the active game is visually unchanged by this batch. One-shot FPS values vary between captures and are not treated as a performance benchmark.

## Integrity and verification

- Canonical `art/registry.json` remains at 15 IDs; no promotion or runtime assignment occurred.
- RoomDefinition files, gameplay scripts, collision, navigation, construction, delivery, citizen behavior, and traversal were not changed.
- `python scripts/test_art_factory.py`: 24 tests passed.
- Python compilation for the Art Factory CLI, factory, and models passed.
- Godot 4.7.2 editor import passed; `visual_resolver_test.gd` passed, including required-asset and review-showcase integrity checks.
- v004, v005, and v006 candidate generation, technical validation, and review capture all passed.
- The prior Batch 5 50-citizen gameplay matrix remains the latest full matrix. This batch did not rerun it because changes are confined to review art, mesh authoring, and chair-specific shading; no gameplay or canonical runtime path changed.

## Cumulative status and next batch

The full inventory remains 95 visible-art classes across 21 RoomDefinitions and 318 object records, including 48 Tier 1 rows. Six Tier 1 rows currently map to strict-passing accepted production assets; nine rows are associated with best-current/below-target evidence (six Batch 5 furniture assets, the French door, and two desk aliases pointing to one failed desk candidate); the remaining 33 Tier 1 rows have no assigned strict failure record or are handled as linked families. The canonical registry remains at 15 entries. The inventory still exposes obvious human-room fallbacks, unfinished citizen/faction art, and primitive/runtime construction and traversal presentation.

Next priority is Batch 8: the five remaining Tier 1 Room A/B furniture candidates—elevated workbench, assembly table, tool wardrobe, floor cabinet, and side table. Use fresh Visual Director targets and geometry-led production, preserve the strict per-asset attempt limits, render the whole room, and promote only passing improvements. Chair v006 stays review-only in its exhausted episode.
