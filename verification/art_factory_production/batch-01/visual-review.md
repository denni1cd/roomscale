# Art Factory Production Deployment — Batch 1 Review

**Status:** Bounded Batch 1 production and verification completed. Three candidates were promoted after strict candidate evaluation. The overall production deployment remains incomplete: the integrated rooms still contain large areas of prototype-level room shell, major furniture, and faction foliage.

**Review registry:** [batch-01-review-registry.json](batch-01-review-registry.json) is review-only and begins from the exact Batch 0 citizen-v089 showcase state. Only the seven selected asset IDs differ. The canonical registry was changed only for the three passing promotions.

## Selected assets and outcomes

The selection comes from the Tier 1 settlement buildings and large room objects in the full visible-art inventory, plus the prominent windows and reconstructed-room door openings. The candidates were made with modular Blender 5.2.3 mesh construction, bevelled joinery, distinct geometry, and embedded PBR maps; the unchanged Art Factory process imported, rendered, and evaluated every candidate in Godot.

| Asset | Candidate | Outcome | Production finding |
|---|---|---|---|
| Room B workshop parts rack | `room_bookcase_production-v001` | **Promoted** | Replaces the generic bookcase fallback with a fitted, framed cabinet with four shelf levels, nine parts trays/drawers, labels, hardware, and organized stock. The RoomDefinition footprint and gameplay geometry are unchanged. |
| Clockwork depot | `settlement_depot-v005` | **Promoted** | Clear improvement over v003: framed storehouse, paneled loading doors, roof seams, braces, hoist, and strapped supplies. |
| Clockwork housing | `settlement_housing-v004` | **Promoted** | Clear improvement over v002: distinct gables, layered siding, framed openings, divided windows, and porch construction. |
| Clockwork workshop | `settlement_workshop-v006` | Continue; v004 retained | The broad roof wings hide the boiler and stack. It loses defining machinery readability against the accepted incumbent. |
| Clockwork work area | `settlement_workarea-v006` | Continue; v005 retained | The new canopy hides the bench drive and equipment. It is not a clear improvement over the accepted incumbent. |
| Reconstructed-room windows | `room_photo_window_production-v002` | Continue; review-only | Oak framing improves the match, but close views lack readable sash locks and upper transom lights; glazing appears uniform and opaque. Strict source-character gate fails. |
| Reconstructed-room French door | `room_photo_french_door_production-v002` | Continue; review-only | Required hinges and latch hardware are not legible and the glazing reads opaque. The supplied room photo does not depict a door, so photo-character acceptance cannot be established. |

The four settlement briefs now state the approved miniature-diorama art direction explicitly. This permits deliberate scale-driven stylization while their evaluations still require constructed joinery, distinct materials, and close-range detail; it does not make the workshop or work-area deficiencies pass.

All seven candidates have persisted ArtFactory `evaluation.json` files with explicit realism, close-inspection, craftsmanship, and style-gate answers. The window and door evaluations also record their photographic comparison and limitations. Failed/continued versions remain in candidate history. No desk, citizen, or grapple iteration was restarted.

## Matched integrated views

The Batch 0 and Batch 1 Room A overview captures use the same RoomDefinition, 1280×720 viewport, camera target, position, tilt, yaw, and FOV. Batch 1 uses the review-only v089 citizen baseline plus the selected Batch 1 candidates. Equivalent Room B and reconstructed-room views are included under the same `batch-0` and `batch-1` folders.

| View | Batch 0 | Batch 1 |
|---|---|---|
| Room A matched overview | [baseline-matched.png](baseline-matched.png) | [final-matched.png](final-matched.png) |
| Room A settlement gameplay | [Batch 0](batch-0/room-a/settlement-gameplay.png) | [Batch 1](batch-1/room-a/settlement-gameplay.png) |
| Room B parts rack | [Batch 0](batch-0/room-b/parts-rack-gameplay.png) | [Batch 1](batch-1/room-b/parts-rack-gameplay.png) |
| Reconstructed room overview | [Batch 0](batch-0/room-photo-luna/room-photo-gameplay.png) | [Batch 1](batch-1/room-photo-luna/room-photo-gameplay.png) |

**Visual disposition:** The depot, paired housing, and parts rack are materially better and clearly constructed at their asset and gameplay views. The settlement close-up shows this improvement most clearly. The room overview changes are more localized, and the reconstructed human room remains dominated by its flat shell, fallback furniture, and simplified exterior foliage. Therefore Batch 1 does **not** satisfy the scene-wide exit condition that an ordinary viewer immediately see broad material improvement. The evidence supports three focused promotions, not a claim that the game-wide art backlog is complete.

## Gameplay and integration

The full Room A smoke ran with `ROOMSCALE_ART_REGISTRY_MODE=review_showcase` and the exact matched registry above. It reports:

- 50 citizen nodes initialized; 47 active at the M2 checkpoint.
- M2 navigation, M3 target investigation, and M4 resource delivery/construction passed.
- 11 deliveries completed: wood 4, metal 4, mechanical parts 3; all three build stages completed.
- M5 physical grapple traversal reached the 30-inch RoomDefinition surface over the 87.2-inch route.
- M6 completed three arrivals, three explorations, and two autonomous route reuses.
- M8 steam, gear, inspection, and camera checks passed.
- No `REQUIRED_VISUAL_ASSET_FAILURE`, `VISUAL_ASSET_FALLBACK`, or smoke failure markers were found in the log.

The Room B and reconstructed-room receipts report `pass`, `production_path=true`, review-only mode, and exact challenger IDs. Room B confirms the parts-rack GLB. The reconstructed-room receipt confirms two window instances and one French-door instance. See [Room A smoke](room-a-smoke.log), [Room B receipt](batch-1/room-b/receipt.json), and [photo-room receipt](batch-1/room-photo-luna/receipt.json).

## Performance comparison

Both captures used Godot 4.7.2, the Compatibility renderer on the same RTX 5090 workstation, 50 citizens, disabled VSync, and three 8-second views. The Batch 0 numbers come from the preserved [baseline report](../performance.json); Batch 1 is [performance-batch1.json](../performance-batch1.json).

| View | FPS B0 → B1 | p95 ms B0 → B1 | Draw calls B0 → B1 | Primitives B0 → B1 |
|---|---:|---:|---:|---:|
| Room | 379.5 → 440.5 | 3.093 → 2.722 | 791 → 498 | 272,084 → 296,154 |
| Settlement | 397.7 → 458.9 | 2.992 → 2.569 | 1,041 → 589 | 509,300 → 675,404 |
| Citizen close | 304.2 → 366.0 | 4.307 → 3.449 | 2,053 → 1,279 | 724,878 → 860,046 |

These workstation captures show no frame-time regression in this run. Settlement/citizen primitive counts rose with the higher-detail imported assets; this is not a target-hardware guarantee.

## Backlog and next phase

The specific remaining work is recorded in [production-art-backlog.md](../production-art-backlog.md). The top unresolved items are the room shell and large furniture, source-faithful window glazing/hardware, a real French-door reference, exposed workshop/work-area machinery, and distinct Scavenger/Verdant silhouette and foliage geometry. Continue with bounded multi-asset batches; do not treat the three promotions as broad art completion.
