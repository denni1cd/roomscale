# Production Art Backlog — Updated after Batch 6

This is the post-POC production backlog. It preserves POC 2.5 evidence and acceptance results; the entries below are not POC 2.5 regressions or changes to its acceptance amendment.

## Current priority after Batch 7

1. **Room A/B furniture geometry — next batch.** Batch 7 used one fresh Visual Director target to pilot a Godot-authored mesh workflow on the chair. Candidate v006 is the best review result after three attempts: the custom front-face winding, closed turnings, shaped seat edge, leaf spindles, and chair-specific wood finish are materially better than v003. The strict visual gate still fails on the carved seat, joinery, and wood variation. Do not reopen this target episode. Use the geometry pilot to develop fresh round-02 targets and meaningful geometry for the five remaining Tier 1 assets: elevated workbench, assembly table, tool wardrobe, floor cabinet, and side table. Promote only assets that pass their own strict gate.
2. **French door source and production model.** Batch 6 sourced a relevant CC BY 4.0 door reference and evaluated v003–v005 within its approved target episode. v005 is the best review candidate, but the hinges still do not read, its oak grain is too repetitive, and the current room gives blue sky through the glazing instead of the reference garden. Preserve it as review-only. Resume after a materially different hinge/material approach is available and the exterior-context limitation has a room-compatible solution; do not add a synthetic backdrop to the asset.
3. **Desk transfer follow-up.** `desk-v007` remains the production incumbent but fails the strict visual gate for material separation and glazing. Batch 2’s v059–v061 work reached a material/render diagnosis plateau. Do not restart parameter-only iterations; resume only with a materially different material/render strategy.
4. **Room shell beyond finishes.** Batch 4 accepted photo-room carpet v003 and green paint v002. The floor is still a RoomDefinition sheet and the shell still uses segmented planes; keep geometry/gameplay authoritative. Room A/B boards, trim, ceilings, and lighting need source/style-specific review instead of reusing the photo-room carpet or wall color indiscriminately.
5. **Faction visual identity.** Preserve current Clockwork building production and citizen-v089 as best-current review art. Verdant needs distinctive organic construction and dimensional foliage; Scavenger needs salvage silhouettes/materials. Avoid color-only variants and another citizen-only loop.
## Promoted production assets

- Batch 1: `settlement_depot-v005`, `settlement_housing-v004`, and `room_bookcase_production-v001`.
- Batch 3: `display_cabinet-v003` and `room_photo_window_production-v004`. Workshop v007 remains a weaker challenger; v004 is retained.
- Batch 4: `room_shell_floor-v003` and `room_shell_wall_finish-v002`.

These are scoped improvements. The inventory still contains substantial unregistered room furniture, runtime-generated geometry, and incomplete faction-specific art.

Batches 5–7 did not change the production registry. The six Room A/B furniture candidates, the French-door v005, and chair v006 remain review-only and below target; see [Batch 5 furniture transfer review](batch-05-room-a-b-furniture.md), [Batch 6 French-door transfer review](batch-06-french-door.md), and [Batch 7 chair geometry pilot](batch-07-room-a-b-furniture-geometry.md).

## Batch 1 promotion detail

- `settlement_depot-v005` — accepted as a materially better, constructed depot.
- `settlement_housing-v004` — accepted as a materially better paired-home structure.
- `room_bookcase_production-v001` — accepted as fitted workshop storage; Room B appearance uses the new semantic ID.

These promotions improve specific assets. They do not satisfy the scene-wide production objective while the room foundation and large human-room furniture remain prototype-level.

## Evidence references

- [Visual Director Batch 2 — desk concept-to-production application](visual_director_batch-02.md)
- [Batch 1 visual review and matched views](batch-01/visual-review.md)
- [Current full visible-art inventory](visual_inventory.md)
- [Preserved Batch 0 performance](performance.json)
- [Batch 1 performance](batch-01/performance-batch1.json)

## Source-photo targeting note

The Visual Director's first application selected the photographed, instantiated desk in `room_photo_luna`. The supplied room-photo set does not show a sofa or fireplace; those backlog labels should not be treated as observed source furniture without another reference or room-specific evidence. The current photo set does show the desk, hammock, and display cabinet. Batch 0 inventory/material findings remain the baseline and are not reopened by this note.
