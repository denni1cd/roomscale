# Batch 24 — Scavenger Work Area Transfer Review

## Scope and disposition

This batch built three presentation-only Scavenger Work Area candidates against the Luna-approved refined Direction C target. The candidate replaces only the review-scene display mesh; RoomDefinition landmarks, the work site, collision, navigation, selection, resource assignments and simulation remain authoritative.

The evaluation uses the Room A Godot production scene at its controlled 64-inch settlement camera, plus opposite and side views and close asset captures. These are reproducible camera-proxy renders, not interactive play captures. They show composition and occlusion at the target distance but do not establish how a player experiences an interactive session.

`scavenger_workarea-v001` is the best current 3D candidate. It uses textured timber, enamel and galvanized materials, and passes Godot validation at 22.81 × 8.045 × 11.48 inches. Luna scored its work-area identity 2/5 and tool-board visibility 1/5: the canopy still reads like a generic shelter.

`scavenger_workarea-v002` attempted the targeted shorter front roof. Blender generation succeeded, but Godot technical validation rejected it: the complete model depth was only 7.70 inches against the 12-inch target depth, outside the 20% proportion tolerance. The production render bridge correctly withheld capture for this invalid candidate, so it has no visual evaluation.

`scavenger_workarea-v003` used the final alternate material strategy, switching from baked patina maps to per-part solid PBR blocks and extending the supported rear canopy to pass proportions. Godot validation passed at 22.81 × 8.045 × 10.03 inches, with one mesh, seven surfaces and 15,444 triangles. Luna scored work-area identity 1/5, bench/vise visibility 2/5, tool-board/tools 1/5, material separation 2/5, and support plausibility 3/5. The Room A 64-inch views still show a shelter-first silhouette; the close capture confirms the bench but does not make the tool wall or work function read.

The target episode is backlogged after three strategies. The strict comparison retains v001 as the best current 3D candidate because v003's alternate material treatment weakens roof-to-bench separation and does not solve the 64-inch work-area read. No model was promoted, and the canonical production registry remains unchanged at 15 entries.

Because no candidate was promoted, this batch does not improve the accepted whole-game scene. The candidate-in-room renders are controlled review substitutions; the canonical production runtime still uses its previous presentation. No comparative 50-citizen performance measurement was run for this review-only batch.

## Inventory snapshot

The refreshed inventory covers 95 visible-art classes: 48 Tier 1, 11 Tier 2, and 36 Tier 3. It records 15 canonical registry entries. Of Tier 1, 8 classes resolve to accepted canonical assets, 17 have a best-current candidate, and 24 remain flagged as programmer art or primitive-driven; no Tier 1 assigned candidate currently has a strict-gate PASS recorded. Tier 2 contains 11 classes, 10 flagged programmer-art/primitive-driven. Overall, 68 of 95 classes are still flagged as programmer-art/primitive-driven. The scan records 13 scripts with 93 runtime geometry-builder sites. Full per-class details are in the refreshed [visual inventory](visual_inventory.md) and [JSON](visual_inventory.json).

## Evidence

- [Approved visual target](../../art/scavenger_workarea/visual_director/round-01/approved-target-r01.png)
- [Luna concept review](../../art/scavenger_workarea/visual_director/round-01/pixel-review.md)
- [v001 Room A 64-inch view](../../art/scavenger_workarea/iterations/v001/render-runs/run-001/settlement-scale.png)
- [v001 close three-quarter view](../../art/scavenger_workarea/iterations/v001/render-runs/run-001/asset-three-quarter.png)
- [v001 Luna review](../../art/scavenger_workarea/iterations/v001/review-luna-room-a.md)
- [v002 failed technical bounds](../../art/scavenger_workarea/iterations/v002/technical-validation.json)
- [v003 Room A 64-inch front view](../../art/scavenger_workarea/iterations/v003/render-runs/run-001/settlement-scale.png)
- [v003 Room A 64-inch opposite view](../../art/scavenger_workarea/iterations/v003/render-runs/run-001/settlement-scale-opposite-angle.png)
- [v003 Room A 64-inch side view](../../art/scavenger_workarea/iterations/v003/render-runs/run-001/settlement-scale-side-angle.png)
- [v003 close three-quarter view](../../art/scavenger_workarea/iterations/v003/render-runs/run-001/asset-three-quarter.png)
- [v003 Luna review](../../art/scavenger_workarea/iterations/v003/review-luna-room-a.md)
- [v003 strict evaluation](../../art/scavenger_workarea/iterations/v003/evaluation.json)

## Next step

Do not generate a fourth variant against this target. Continue the production queue with a different high-impact asset family and retain the Work Area target as backlog. The Room A proxy renders are useful for deciding whether geometry and materials survive at 64 inches; an interactive play capture remains necessary before claiming a live gameplay improvement.
