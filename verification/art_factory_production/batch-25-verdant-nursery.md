# Batch 25 — Verdant Growth Nursery transfer review

## Scope and disposition

This batch transferred the Luna-approved Verdant nursery concept into the existing Room A workshop envelope. It produced three Blender GLB candidates and rendered two technically valid candidates through the Godot 4.7.2 production resolver in the Room A scene. The settlement captures are controlled 64-inch static camera proxies, not interactive gameplay recordings.

The first tall concept was visually attractive but under-specified for the actual 26 × 10 × 18 inch Room A module. `verdant_nursery-v001` measured 23.26 × 9.44 × 10.52 inches, so its depth reached only 58.5% of the target and failed the 20% technical tolerance. No production render was made. The concept episode was backlogged with that reason, then a low, broad target was pixel-reviewed and approved for the actual envelope.

`verdant_nursery-v002` corrected the source fit to 23.26 × 9.44 × 16.84 inches and passed technical validation (one mesh, ten material surfaces, 24,600 triangles). Its 64-inch Room A view read as a small leafy platform. Luna found the trunk, pods, front bay, and ladder too small or occluded; close inspection restored some detail, but green and wood materials remained washed out.

`verdant_nursery-v003` kept the passing envelope at 23.26 × 9.58 × 16.08 inches, with one mesh, ten material surfaces, and 20,872 triangles. It darkened foliage and rootwood, reduced leaf overlap, and enlarged front-facing pods. In the 64-inch capture the central trunk and ochre pods now register. The ladder still merges with the front deck, so the open nursery work bay remains unclear across settlement, opposite, and side views. Luna rates the transfer as improved but backlogged.

The three-candidate budget is exhausted. v003 is preserved as the best current 3D review candidate, but it does not pass gameplay-readability or close-inspection gates and was not promoted. The canonical registry remains unchanged at 15 entries. No full-scene visual improvement or 50-citizen performance comparison is claimed. Candidate rendering only substitutes the presentation mesh; RoomDefinition landmarks, simulation, collision, navigation, selection, work contracts, and growth behavior remain unchanged.

## Inventory snapshot

The refreshed inventory covers 95 visible-art classes, 15 canonical registry entries, 13 runtime geometry-building scripts, and 93 builder sites. The Verdant Settlement entry now records v003 as review-only best current art and keeps the nursery entrance/readability defect in backlog. Full per-class details remain in the refreshed [visual inventory](visual_inventory.md) and [JSON](visual_inventory.json).

## Evidence

- [Initial tall concept](../../art/verdant_nursery/visual_director/round-01/approved-target-r01.png)
- [Dimension-corrected target](../../art/verdant_nursery/visual_director/round-02/approved-target-r01.png)
- [v001 failed bounds](../../art/verdant_nursery/iterations/v001/technical-validation.json)
- [v002 technical validation](../../art/verdant_nursery/iterations/v002/technical-validation.json)
- [v002 64-inch Room A capture](../../art/verdant_nursery/iterations/v002/render-runs/run-003/settlement-scale.png)
- [v002 Luna review](../../art/verdant_nursery/iterations/v002/review-luna-room-a.md)
- [v002 evaluation](../../art/verdant_nursery/iterations/v002/evaluation.json)
- [v003 technical validation](../../art/verdant_nursery/iterations/v003/technical-validation.json)
- [v003 64-inch Room A capture](../../art/verdant_nursery/iterations/v003/render-runs/run-001/settlement-scale.png)
- [v003 close view](../../art/verdant_nursery/iterations/v003/render-runs/run-001/asset-three-quarter.png)
- [v003 Luna review](../../art/verdant_nursery/iterations/v003/review-luna-room-a.md)
- [v003 evaluation](../../art/verdant_nursery/iterations/v003/evaluation.json)
- [Visual Director status and backlog reason](../../art/verdant_nursery/visual_director/state.json)

## Next step

Keep v003 as best current review art. Any future attempt should separate the ladder from the platform edge, simplify the front deck silhouette, and frame the open work bay so those cues remain distinct at 64 inches. The current run provides evidence about static Room A camera readability; a live interactive capture is still needed to establish in-play readability.
