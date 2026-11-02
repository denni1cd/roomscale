# Production Art Backlog — Updated after Batch 22

This is the post-POC production backlog. It preserves POC 2.5 evidence and acceptance results; the entries below are not POC 2.5 regressions or changes to its acceptance amendment.

## Current priority after Batch 22

1. **Faction visual identity.** The Scavenger workshop r01 and Depot r01 episodes have each exhausted three strategies and remain review-only. The Depot's v003 improves the correctly framed Room A gameplay read, but its hoist and side storage remain too small and its close craft misses the production gate. Continue with the next high-prominence Scavenger structure from the inventory, starting with housing; preserve all existing sites, dimensions, and gameplay contracts. Avoid another citizen iteration loop until a bounded role-kit batch is ready.
2. **Clockwork workshop target episode.** v008 remains the best current 3D candidate; v004 remains production. v009's upper tier is oversized and disconnected, and Luna's pixel review found it less coherent than v008. The r01 episode is backlogged after three strategies. Do not make a fourth variant against the same approved target.
3. **Room shell trim and French door.** Both approved-target episodes have exhausted three strategies. Trim v002 remains best current but misses close-craft and grain; French-door v010 has exact bounds and readable hinges but repetitive oak. The blue-gray pane capture cannot establish transparency. Preserve room dimensions; keep any garden context outside the door mesh.
4. **Desk transfer.** The r01 episode remains at three attempts. A current matched rerender makes v061 the best 3D review candidate because its probe restores broad room reflections and its constructed underframe reads better than v007. It still renders too green and transparent against the source and target; preserve v007 in production and do not generate a fourth r01 variant.
5. **Visible ceiling.** It is hidden in the representative open-top gameplay camera and should wait for a view where it is visible.

## Whole-scene and cumulative status

Across Batches 5-18 there were no new canonical registry promotions; the canonical registry remains at 15 entries. The current inventory covers 95 visible-art classes across 21 RoomDefinitions and 318 room object records: 48 Tier 1, 11 Tier 2, and 36 Tier 3. Eight Tier 1 classes have accepted registry status and two more link to Art Factory asset families; the other 38 Tier 1 classes are not registered as unique production assets. Registry status does not itself establish a current strict-gate pass: the inventory records no Tier 1 strict-gate PASS, while the desk and Clockwork citizen incumbent re-audits are known failures. Seven Tier 1 furniture classes have explicit best-current review candidates (household bookcase, chair, assembly table, workbench, wardrobe, floor cabinet, and side table), all still below target. Tier 2 has one linked asset family and 10 unregistered classes. The inventory flags 70 classes as programmer-art or primitive-driven (26 Tier 1, 10 Tier 2, 34 Tier 3). Runtime geometry is 93 builder sites across 13 scripts, including the shared trim-profile helper.

Batch 10 made no integrated production-quality furniture gain. Batch 15 tested a materially different construction and calm-wood strategy on the same five furniture assets. The new planked tops and quieter grain improve four best-current candidates, but no model meets the strict visual gate; v005 remains best for the floor cabinet. All five episodes are backlogged at their third strategy. Batch 11 approved the household-bookcase target but the initial Blender invocation was blocked. Batch 14 resumed that same candidate record with Blender configured, evaluated three strategies, and backlogged the target without promoting a model. Batch 12 improved the shared lighting presentation modestly without changing geometry or the registry; its matched captures and performance records are in the [Batch 12 lighting review](batch-12-lighting.md). Batch 13 completed three trim candidates but did not meet the close-craft gate; see the [Batch 13 trim review](batch-13-room-shell.md). See the [Batch 14 bookcase transfer review](batch-14-bookcase.md) and [Batch 15 furniture review](batch-15-room-a-b-furniture.md).

The French door remains review-only: v010 is the best 3D candidate after the r03 episode; v011's alternate procedural material was rejected, and no production asset was promoted. Batch 15's five furniture target episodes are exhausted; best current candidates are workbench v009, assembly table v008, wardrobe v008, floor cabinet v005, and side table v008. The Room A household-bookcase target is approved; after resuming the original blocked candidate, v003 is its best current 3D review candidate, the three-strategy episode is exhausted, and no Room A bookcase model was promoted. The separate accepted `room_bookcase_production-v001` remains the fitted workshop parts rack. Room shell trim v002 is best current review with no promotion; its target episode is exhausted. See the [Batch 16 French-door review](batch-16-french-door.md), [Batch 15 furniture review](batch-15-room-a-b-furniture.md), [Batch 14 bookcase review](batch-14-bookcase.md), [Batch 13 trim review](batch-13-room-shell.md), [Batch 12 lighting review](batch-12-lighting.md), [Batch 11 Room A bookcase attempt](batch-11-room-a-bookcase.md), [Batch 10 Room A/B furniture transfer](batch-10-room-a-b-furniture.md), [Batch 5 furniture transfer review](batch-05-room-a-b-furniture.md), [Batch 6 French-door transfer review](batch-06-french-door.md), [Batch 7 chair geometry pilot](batch-07-room-a-b-furniture-geometry.md), [Batch 8 furniture geometry and finish](batch-08-room-a-b-furniture.md), and [Batch 9 French-door transfer](batch-09-french-door.md).

## Batch 12 disposition

The Visual Director approved one scene-wide lighting direction. No 3D asset was generated, no mesh candidate was evaluated, and no production registry asset was promoted. The selected Godot settings modestly improve material warmth and cutaway contrast. Matched Room A, Room B, and photo-derived-room evidence uses the canonical production registry and 50 citizens. The 50-citizen benchmark showed no rendering-cost regression. The Art Factory integrity suite passed all 24 tests.

## Batch 13 disposition

The source-conditioned trim target was approved, but three bounded candidates did not pass strict close review. v001's procedural material produced repeated warm bands; v002 removed those bands and became the best current review, but its uniform finish and remaining profile bands missed the close-craft gate; v003's alternate grain/profile transfer regressed in the production closeups. No candidate was promoted and the canonical registry remains at 15 entries. The runtime default still uses cuboid trim. Matched 50-citizen performance samples showed no measurable frame-time regression from the review-only candidate. The Art Factory integrity suite passed all 25 tests.

## Batch 14 disposition

The approved Room A household-bookcase target was resumed after configuring the available Blender 5.2.3 executable. `bookcase-v001` retained its original blocked generation log and candidate identity; the retry became execution 2 of the same candidate. The Art Factory retry path now records each generation execution separately instead of resetting Visual Director history. v001 was the first transfer; v002's large repeating grain waves made it worse; v003 removed those waves and is best current, but its remaining even striping and weak shelf-pin/join readability fail the close-craft and surface-variation gates. The Room A overview comparison did not show a clear gameplay-distance gain. The target episode is exhausted at three strategies and v003 remains review-only; no production asset was promoted. The integrity suite passed 26 tests. See [Batch 14](batch-14-bookcase.md) for candidate evidence, scene comparison and 50-citizen performance.

## Batch 16 disposition

The new r03 French-door target was pixel-inspected and approved by Codex; it is not attributed to Luna. The three candidates preserved the gameplay definition and registry. v009 exposed a validator gap by passing with 4.615 inches of depth; an optional per-axis ArtBrief tolerance now rejects that overshoot. v010 passes exact 66 × 82 × 4-inch bounds and is the best 3D review candidate, with visible hinge placement but repetitive oak. v011 passes bounds but its alternate procedural oak is nearly flat and was rejected. No door asset was promoted, and the canonical registry remains at 15 entries.

The matched reconstructed-room overview did not show an obvious game-scale quality gain. A warmed 50-citizen comparison of review candidate v005 to v010 showed no rendering-cost regression across room, settlement, or citizen views. The Art Factory suite passed 27 tests; the changed Python files passed Ruff and compilation. See the [Batch 16 French-door review](batch-16-french-door.md) and matched JSON in `batch-16/`.

## Batch 17 disposition

The desk r01 episode remains backlogged at its three-strategy limit. Current same-project production captures used Godot 4.7.2 Compatibility, the same reconstructed-room RoomDefinition, camera positions and 50 citizens for v007 and v061. Direct pixel inspection by Codex—not a new Luna review—shows v061 has broader reflections and more readable support construction than v007 in close views, while the room overview still shows no obvious scene-wide transformation. The v061 candidate-local ReflectionProbe is the material-response difference: a no-probe control with the same scene geometry and effective StandardMaterial3D values loses the broad room reflection.

The current re-evaluation makes v061 the best 3D review candidate, but does not pass source-character or craftsmanship gates: the tabletop remains too green/transparent, and its leading edge is too dark. v007 remains the production asset and the canonical registry remains at 15 entries. In one warmed 50-citizen sample, the v061 probe added about 0.53 ms to room-view median frame time versus its no-probe control; settlement and citizen samples showed little change. The 50-citizen room-scale showcase remains visibly prototype-heavy, with green cutaway walls, plain floors, and sparse low-detail furnishings. See the [Batch 17 desk material/reflection control](batch-17-desk-control.md) and its raw JSON measurements.

## Batch 18 disposition

Direct pixel review reconfirmed the trim and French-door candidate dispositions without creating new variants: trim v002 remains best current, v003 remains rejected, and French-door v010 remains best current after the r03 episode. The French-door panes appear uniform blue-gray against an equally blank exterior, so the current render cannot establish target-like transparency or garden transfer. No promotion or production/runtime change occurred. The latest 50-citizen whole-scene capture remains prototype-heavy and shows no obvious visual transformation. Existing Batch 13 and Batch 16 performance samples remain applicable because this batch changed no runtime content. See the [Batch 18 architecture review](batch-18-human-room-architecture-review.md).

## Batch 19 disposition

The Luna-approved Clockwork workshop r01 episode resumed for attempt 2. v008 replaces the split incumbent wings with a tied gable and improves the roof assembly, but omits the broad lower cover and raised upper ridge shown in the approved target. Keep v008 as best-current 3D review and v004 in the canonical production registry; no promotion occurred. Matched 50-citizen renders show a small 0.16 ms p95 increase in room/settlement views and flat citizen performance. Whole-scene settlement captures show no broad transformation. The inventory now follows Visual Director best-3D state ahead of the legacy showcase entry. One alternate strategy remains; after that, move on. See [Batch 19](batch-19-clockwork-workshop.md).

## Batch 20 disposition

The final materially different attempt, `settlement_workshop-v009`, uses a component-authored full-width lower canopy with a chimney opening and raised rear ridge. The raised tier is more apparent than v008, but Luna's direct review of the actual PNGs found it oversized and visually separate, with thin supports, panels crowding the lower roof, and less interior readability. Code dimensions also show the monitor posts stop about 0.67 inches above the sloped lower roof. Luna judged v008 simpler but more coherent overall; the strict v009 evaluation records `worse`, so v008 remains best current 3D. Close-range framing, fasteners, tools, and finish remain substantially under-transferred. Joins and manufacturing detail fail.

Godot 4.7.2 validation passed at 26 × 19.94 × 20 inches, 158 meshes/surfaces, and 32,640 triangles. The target episode is backlogged at attempt three. The best-3D record remains v008; the production asset and canonical registry entry remain v004. There was no promotion and no gameplay or RoomDefinition change.

The matched settlement-scale v008/v009 captures show a wider workshop canopy but no obvious scene-wide transformation. The workshop remains small in frame and the surrounding settlement remains visibly sparse and prototype-like. In warmed 50-citizen samples, v009 versus v008 room median/p95 was 3.080/3.620 vs 2.976/3.527 ms, settlement was 2.760/3.350 vs 2.657/3.289 ms, and citizen was 2.470/3.020 vs 2.316/2.948 ms. These single-session values indicate a small frame-time increase; settlement draw calls rose from 1,390 to 1,598. See [Batch 20](batch-20-clockwork-workshop-final.md) and its [v008](batch-20/performance-v008.json) and [v009](batch-20/performance-v009.json) raw samples.

## Batch 21 disposition

The Luna-approved Scavenger workshop target received three bounded Blender transfers. v002 improved the 64-inch gameplay readability score from 2/5 to 3/5; v003's rear-set, braced roof improves the close work-bay view and is the best current 3D candidate, but Luna found no material readability jump over v002 at the matched gameplay camera. The 330-inch room overview remains inconclusive. Godot validation passed at 25.90 × 19.16 × 19.36 inches, 10 meshes/surfaces, and 107,784 triangles. The episode is backlogged at attempt three; no candidate was promoted, and the production registry remains unchanged. See [Batch 21](batch-21-scavenger-workshop-final.md).

Batch 21 selected the Scavenger settlement architecture family because it repeats across the active settlement and still reuses the Clockwork family with simple scrap overlays. Batch 22 addressed the Depot; v003 is retained for review, while the next structure target is Scavenger housing.

## Batch 22 disposition

The Scavenger Depot r01 target received three bounded Blender transfers. The first gameplay reviews used the default human-room fixture and did not center the Depot; corrected matched captures use the actual Room A scene. v003 is the best current candidate: its paired appliance doors and open route score 4/5 at 64 inches, with stronger Scavenger identity than v001/v002. The hand hoist and side storage remain under-readable (2/5), close craft remains 3/5, and the roof is more regular than the approved gantry. Godot validation passed at 23.63 × 12.18 × 18.61 inches, 10 meshes/surfaces, and 52,048 triangles. The episode is backlogged after attempt three; no candidate was promoted and the canonical registry remains unchanged. See [Batch 22](batch-22-scavenger-depot-final.md).

## Promoted production assets

- Batch 1: `settlement_depot-v005`, `settlement_housing-v004`, and `room_bookcase_production-v001`.
- Batch 3: `display_cabinet-v003` and `room_photo_window_production-v004`. Workshop v007 remains a weaker challenger; v004 is retained.
- Batch 4: `room_shell_floor-v003` and `room_shell_wall_finish-v002`.

These are scoped improvements. The inventory still contains substantial unregistered room furniture, runtime-generated geometry, and incomplete faction-specific art.

No canonical production assets were promoted in Batches 5–22; Batch 12 changed scene-wide lighting settings, and Batch 15 added no runtime promotion. Review-only candidates remain outside accepted production, including desk-v061 (with desk-v007 retained in production), French door v010, trim v002, Room A bookcase v003, the Batch 15 furniture candidates, Scavenger workshop v003, and Scavenger Depot v003. See the batch reports linked above.

## Batch 1 promotion detail

- `settlement_depot-v005` — accepted as a materially better, constructed depot.
- `settlement_housing-v004` — accepted as a materially better paired-home structure.
- `room_bookcase_production-v001` — accepted as fitted workshop storage; Room B appearance uses the new semantic ID.

These promotions improve specific assets. They do not satisfy the scene-wide production objective while the room foundation and large human-room furniture remain prototype-level.

## Evidence references
- [Batch 12 lighting and environment review](batch-12-lighting.md)

- [Visual Director Batch 2 — desk concept-to-production application](visual_director_batch-02.md)
- [Batch 1 visual review and matched views](batch-01/visual-review.md)
- [Current full visible-art inventory](visual_inventory.md)
- [Preserved Batch 0 performance](performance.json)
- [Batch 1 performance](batch-01/performance-batch1.json)

## Source-photo targeting note

The Visual Director's first application selected the photographed, instantiated desk in `room_photo_luna`. The supplied room-photo set does not show a sofa or fireplace; those backlog labels should not be treated as observed source furniture without another reference or room-specific evidence. The current photo set does show the desk, hammock, and display cabinet. Batch 0 inventory/material findings remain the baseline and are not reopened by this note.
