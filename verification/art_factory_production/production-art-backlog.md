# Production Art Backlog — Updated after Batch 15

This is the post-POC production backlog. It preserves POC 2.5 evidence and acceptance results; the entries below are not POC 2.5 regressions or changes to its acceptance amendment.

## Current priority after Batch 15

1. **French-door opening.** Batch 9's round-02 v008 matches the four-row pane layout but remains too flat in wood and has unreadable hinges; v005 remains best current review. That target episode is exhausted. Continue only with a new, materially distinct hinge/material direction and greenery in review-room context, never foliage in the door mesh.
2. **Desk transfer follow-up.** desk-v007 remains the production incumbent but fails the strict visual gate for material separation and glazing. Batch 2's v059-v061 work reached a material/render diagnosis plateau. Resume only with a materially different material/render strategy.
3. **Room shell trim.** Batch 13 used all three Visual Director attempts; v002 is the best current review candidate but misses close-craft and surface-variation gates, and no candidate was promoted. Reopen only with a new mesh/render diagnosis. Keep RoomDefinition dimensions and gameplay authority intact.
4. **Faction visual identity.** Preserve Clockwork building candidates and citizen-v089 as best-current review art; Verdant needs distinctive organic construction and dimensional foliage, and Scavenger needs salvage silhouettes/materials.
5. **Visible ceiling.** It is hidden in the representative open-top gameplay camera and should wait for a view where it is visible.

## Whole-scene and cumulative status

Across Batches 5-14 there were no new canonical registry promotions; the canonical registry remains at 15 entries. The current inventory covers 95 visible-art classes across 21 RoomDefinitions and 318 room object records: 48 Tier 1, 11 Tier 2, and 36 Tier 3. Eight Tier 1 classes have accepted registry status and two more link to Art Factory asset families; the other 38 Tier 1 classes are not registered as unique production assets. Registry status does not itself establish a current strict-gate pass: the inventory records no Tier 1 strict-gate PASS, while the desk and Clockwork citizen incumbent re-audits are known failures. Seven Tier 1 furniture classes have explicit best-current review candidates (household bookcase, chair, assembly table, workbench, wardrobe, floor cabinet, and side table), all still below target. Tier 2 has one linked asset family and 10 unregistered classes. The inventory flags 70 classes as programmer-art or primitive-driven (26 Tier 1, 10 Tier 2, 34 Tier 3). Runtime geometry is 93 builder sites across 13 scripts, including the shared trim-profile helper.

Batch 10 made no integrated production-quality furniture gain. Batch 15 tested a materially different construction and calm-wood strategy on the same five furniture assets. The new planked tops and quieter grain improve four best-current candidates, but no model meets the strict visual gate; v005 remains best for the floor cabinet. All five episodes are backlogged at their third strategy. Batch 11 approved the household-bookcase target but the initial Blender invocation was blocked. Batch 14 resumed that same candidate record with Blender configured, evaluated three strategies, and backlogged the target without promoting a model. Batch 12 improved the shared lighting presentation modestly without changing geometry or the registry; its matched captures and performance records are in the [Batch 12 lighting review](batch-12-lighting.md). Batch 13 completed three trim candidates but did not meet the close-craft gate; see the [Batch 13 trim review](batch-13-room-shell.md). See the [Batch 14 bookcase transfer review](batch-14-bookcase.md) and [Batch 15 furniture review](batch-15-room-a-b-furniture.md).

The French door remains review-only: v005 is best current, v008 is an evaluated challenger, and the round-02 target episode is exhausted. Batch 15's five furniture target episodes are now exhausted; best current candidates are workbench v009, assembly table v008, wardrobe v008, floor cabinet v005, and side table v008. The Room A household-bookcase target is approved; after resuming the original blocked candidate, v003 is its best current 3D review candidate, the three-strategy episode is exhausted, and no Room A bookcase model was promoted. The separate accepted `room_bookcase_production-v001` remains the fitted workshop parts rack. Room shell trim v002 is best current review with no promotion; its target episode is exhausted. See the [Batch 15 furniture review](batch-15-room-a-b-furniture.md), [Batch 14 bookcase review](batch-14-bookcase.md), [Batch 13 trim review](batch-13-room-shell.md), [Batch 12 lighting review](batch-12-lighting.md), [Batch 11 Room A bookcase attempt](batch-11-room-a-bookcase.md), [Batch 10 Room A/B furniture transfer](batch-10-room-a-b-furniture.md), [Batch 5 furniture transfer review](batch-05-room-a-b-furniture.md), [Batch 6 French-door transfer review](batch-06-french-door.md), [Batch 7 chair geometry pilot](batch-07-room-a-b-furniture-geometry.md), [Batch 8 furniture geometry and finish](batch-08-room-a-b-furniture.md), and [Batch 9 French-door transfer](batch-09-french-door.md).

## Batch 12 disposition

The Visual Director approved one scene-wide lighting direction. No 3D asset was generated, no mesh candidate was evaluated, and no production registry asset was promoted. The selected Godot settings modestly improve material warmth and cutaway contrast. Matched Room A, Room B, and photo-derived-room evidence uses the canonical production registry and 50 citizens. The 50-citizen benchmark showed no rendering-cost regression. The Art Factory integrity suite passed all 24 tests.

## Batch 13 disposition

The source-conditioned trim target was approved, but three bounded candidates did not pass strict close review. v001's procedural material produced repeated warm bands; v002 removed those bands and became the best current review, but its uniform finish and remaining profile bands missed the close-craft gate; v003's alternate grain/profile transfer regressed in the production closeups. No candidate was promoted and the canonical registry remains at 15 entries. The runtime default still uses cuboid trim. Matched 50-citizen performance samples showed no measurable frame-time regression from the review-only candidate. The Art Factory integrity suite passed all 25 tests.

## Batch 14 disposition

The approved Room A household-bookcase target was resumed after configuring the available Blender 5.2.3 executable. `bookcase-v001` retained its original blocked generation log and candidate identity; the retry became execution 2 of the same candidate. The Art Factory retry path now records each generation execution separately instead of resetting Visual Director history. v001 was the first transfer; v002's large repeating grain waves made it worse; v003 removed those waves and is best current, but its remaining even striping and weak shelf-pin/join readability fail the close-craft and surface-variation gates. The Room A overview comparison did not show a clear gameplay-distance gain. The target episode is exhausted at three strategies and v003 remains review-only; no production asset was promoted. The integrity suite passed 26 tests. See [Batch 14](batch-14-bookcase.md) for candidate evidence, scene comparison and 50-citizen performance.

## Promoted production assets

- Batch 1: `settlement_depot-v005`, `settlement_housing-v004`, and `room_bookcase_production-v001`.
- Batch 3: `display_cabinet-v003` and `room_photo_window_production-v004`. Workshop v007 remains a weaker challenger; v004 is retained.
- Batch 4: `room_shell_floor-v003` and `room_shell_wall_finish-v002`.

These are scoped improvements. The inventory still contains substantial unregistered room furniture, runtime-generated geometry, and incomplete faction-specific art.

Batches 5–15 did not change the production registry; Batch 12 changed scene-wide lighting settings, and Batch 15 added no runtime promotion. The Room A/B furniture best-current candidates, the French-door v005, chair v006, bookcase v003, and trim v002 remain outside accepted production; see the batch reports linked above.

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
