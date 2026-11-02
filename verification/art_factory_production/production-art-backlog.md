# Production Art Backlog — Updated after Batch 12

This is the post-POC production backlog. It preserves POC 2.5 evidence and acceptance results; the entries below are not POC 2.5 regressions or changes to its acceptance amendment.

## Current priority after Batch 12

1. **Room shell beyond finishes.** Batch 4 accepted photo-room carpet v003 and green paint v002. The floor remains a RoomDefinition sheet and the shell uses segmented planes; review source/style-specific trim and visible ceiling while keeping RoomDefinition geometry and gameplay authority intact.
2. **Room A/B large furniture and household bookcase.** Batch 10's workbench, assembly table, wardrobe, floor cabinet, and side table challengers fit their envelopes but failed the strict visual gate. Revisit only with a materially different construction/material strategy. The Room A household-bookcase target is approved, but its first generation attempt was blocked before Blender launched and has no 3D candidate.
3. **French-door opening.** Batch 9's round-02 v008 matches the four-row pane layout but remains too flat in wood and has unreadable hinges; v005 remains best current review. Resume only with a materially different hinge/material strategy and greenery in review-room context, never foliage in the door mesh.
4. **Desk transfer follow-up.** desk-v007 remains the production incumbent but fails the strict visual gate for material separation and glazing. Batch 2's v059-v061 work reached a material/render diagnosis plateau. Resume only with a materially different material/render strategy.
5. **Faction visual identity.** Preserve current Clockwork building production and citizen-v089 as best-current review art. Verdant needs distinctive organic construction and dimensional foliage; Scavenger needs salvage silhouettes/materials. Avoid color-only variants and another citizen-only loop.

## Whole-scene and cumulative status

Batches 5-12 made no new canonical registry promotion; the canonical registry remains at 15 entries. The current inventory covers 95 visible-art classes across 21 RoomDefinitions and 318 room object records: 48 Tier 1, 11 Tier 2, and 36 Tier 3. Eight Tier 1 classes have accepted production assets and two more link to accepted asset families; the other 38 Tier 1 classes are not registered as unique assets. Tier 2 has one linked asset family and 10 unregistered classes. The inventory flags 70 classes as programmer-art or primitive-driven (26 Tier 1, 10 Tier 2, 34 Tier 3). Runtime geometry remains 91 builder sites across 12 scripts.

Batch 10 made no integrated production-quality furniture gain. Batch 11 approved the household-bookcase target but produced no model because Blender was not configured in the generation process. Batch 12 improved the shared lighting presentation modestly without changing geometry or the registry; its matched captures and performance records are in the [Batch 12 lighting review](batch-12-lighting.md).

The French door remains review-only: v005 is best current, v008 is an evaluated challenger, and the round-02 target episode is exhausted. Batch 10's five new furniture challengers corrected key envelope errors but still fail realism and craftsmanship. Best current candidates are workbench v008, assembly table v007, wardrobe v007, floor cabinet v005, and side table v007. The Room A household-bookcase target remains approved with one blocked attempt and no best 3D candidate. See the [Batch 11 Room A bookcase attempt](batch-11-room-a-bookcase.md), [Batch 10 Room A/B furniture transfer](batch-10-room-a-b-furniture.md), [Batch 5 furniture transfer review](batch-05-room-a-b-furniture.md), [Batch 6 French-door transfer review](batch-06-french-door.md), [Batch 7 chair geometry pilot](batch-07-room-a-b-furniture-geometry.md), [Batch 8 furniture geometry and finish](batch-08-room-a-b-furniture-geometry.md), and [Batch 9 French-door transfer](batch-09-french-door.md).

## Batch 12 disposition

The Visual Director approved one scene-wide lighting direction. No 3D asset was generated, no mesh candidate was evaluated, and no production registry asset was promoted. The selected Godot settings modestly improve material warmth and cutaway contrast. Matched Room A, Room B, and photo-derived-room evidence uses the canonical production registry and 50 citizens. The 50-citizen benchmark showed no rendering-cost regression. The Art Factory integrity suite passed all 24 tests.

## Promoted production assets

- Batch 1: `settlement_depot-v005`, `settlement_housing-v004`, and `room_bookcase_production-v001`.
- Batch 3: `display_cabinet-v003` and `room_photo_window_production-v004`. Workshop v007 remains a weaker challenger; v004 is retained.
- Batch 4: `room_shell_floor-v003` and `room_shell_wall_finish-v002`.

These are scoped improvements. The inventory still contains substantial unregistered room furniture, runtime-generated geometry, and incomplete faction-specific art.

Batches 5–12 did not change the production registry; Batch 12 changed only scene-wide lighting settings. The earlier Room A/B furniture candidates, Batch 10's five challengers, the French-door v005, chair v006, and the blocked household-bookcase attempt remain outside accepted production; see the batch reports linked above.

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
