# Production Art Backlog — Updated after Batch 4

This is the post-POC production backlog. It preserves POC 2.5 evidence and acceptance results; the entries below are not POC 2.5 regressions or changes to its acceptance amendment.

## Current priority after Batch 4

1. **Room A/B major furniture family — next batch.** The refreshed inventory identifies instantiated Tier 1 assembly tables (4 definitions), chairs (6), side tables (6), elevated workbenches (4), floor cabinets (4), and tool wardrobes (4). These remain catalog imports or procedural/detailed-furniture fallbacks in the active rooms. Build a coordinated, materially constructed 5–6 asset family; preserve each RoomDefinition envelope and gameplay interaction. Reuse accepted assets only where the object role and silhouette actually fit.
2. **French door source and production model.** The source photograph does not show the door. `room_photo_french_door_production-v002` remains continue because its hinges/latch are unreadable and glazing looks opaque. Its stale `asset_id` has been removed from the production room. Source an appropriate door reference before another bounded, source-conditioned attempt.
3. **Desk transfer follow-up.** `desk-v007` remains the production incumbent but fails the strict visual gate for material separation and glazing. Batch 2’s v059–v061 work reached a material/render diagnosis plateau. Do not restart parameter-only iterations; resume only with a materially different material/render strategy.
4. **Room shell beyond finishes.** Batch 4 accepted photo-room carpet v003 and green paint v002. The floor is still a RoomDefinition sheet and the shell still uses segmented planes; keep geometry/gameplay authoritative. Room A/B boards, trim, ceilings, and lighting need source/style-specific review instead of reusing the photo-room carpet or wall color indiscriminately.
5. **Faction visual identity.** Preserve current Clockwork building production and citizen-v089 as best-current review art. Verdant needs distinctive organic construction and dimensional foliage; Scavenger needs salvage silhouettes/materials. Avoid color-only variants and another citizen-only loop.

## Promoted production assets

- Batch 1: `settlement_depot-v005`, `settlement_housing-v004`, and `room_bookcase_production-v001`.
- Batch 3: `display_cabinet-v003` and `room_photo_window_production-v004`. Workshop v007 remains a weaker challenger; v004 is retained.
- Batch 4: `room_shell_floor-v003` and `room_shell_wall_finish-v002`.

These are scoped improvements. The inventory still contains substantial unregistered room furniture, runtime-generated geometry, and incomplete faction-specific art.

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
