# Visual Director Batch 3 — cabinet, photographed window, and Clockwork workshop

## Selection evidence

The batch chose three existing, instantiated assets with distinct visual problems:

- **Display cabinet:** `display_cabinet` is present in `room_photo_luna` and is Tier 1 room furniture at 33 × 76 × 18 inches. Accepted v002 has bright, uniformly lit shelves and a lighter case than the desired walnut target. The room photograph only shows an ambiguous cropped timber fragment, so cabinet construction is guided by the ArtBrief and approved visual target, not invented source-photo detail.
- **Photographed window:** `room_photo_window_production` is a Tier 1 architectural opening at 96 × 68 × 4 inches. `photo_holder/Sample (1).jpg` visibly shows stained timber, divided upper lights, double-hung sashes, meeting rails, and an outdoor view. The v002 Godot evaluation specifically failed its source-character check for missing readable sash hardware/transom and uniformly cool glazing.
- **Clockwork workshop:** `settlement_workshop` is a Tier 1, faction-defining 26 × 20 × 20-inch landmark. Accepted v004 already exposes machinery through a central roof opening; challenger v006 regresses by covering the boiler and stack. The new target tested a raised open canopy while retaining the existing Clockwork identity and landmark.

All three concept rounds include pixel-reviewed directions, explicit target scorecards, and dimension-derived scale guides. Their approved images remain appearance targets separate from the 3D incumbents.

## Production results

| Asset | Approved target → Godot candidate | Comparison and decision |
| --- | --- | --- |
| Display cabinet | [Walnut target](../../art/display_cabinet/visual_director/round-01/approved-target-r01.png) → [v003 render](../../art/display_cabinet/iterations/v003/render-runs/run-001/asset-three-quarter.png) | The target's darker unlit walnut, full-height paired doors, empty shelves, brass details, and crown transfer into the real room capture. The green wall darkens the interior compared with the target's studio backdrop. v003 validates and is promoted; the stable registry verifies. |
| Photographed window | [Transom target](../../art/room_photo_window_production/visual_director/round-01/approved-target-r01.png) → [v003 first pass](../../art/room_photo_window_production/iterations/v003/render-runs/run-002/asset-detail.png) → [v004 corrected render](../../art/room_photo_window_production/iterations/v004/render-runs/run-001/asset-detail.png) | v003 transferred the casing and divided transom, but Godot pixels showed the latch hidden behind the centre stile. Diagnosis identified geometry loss. v004 kept the same target/material plan and moved only the latch to the camera-facing surface. v004 validates, passes the source-photo gate, and is promoted. A mild cool cast remains from the live outdoor scene; v004 uses five upper panes where the target image has four. |
| Clockwork workshop | [Raised-canopy target](../../art/settlement_workshop/visual_director/round-01/approved-target-r01.png) → [v007 render](../../art/settlement_workshop/iterations/v007/render-runs/run-001/asset-three-quarter.png) | v007 is technically valid and exposes the boiler, but the target's supported broad ridge becomes an undersized one-sided awning. Compared with accepted v004, the canopy/load path reads weaker. Evaluation records geometry loss/proportion drift; v004 remains both best 3D and production asset. The target case is explicitly backlogged with the next useful correction. |

Full pixel-level comparisons and observations are in each asset's [cabinet report](../../art/display_cabinet/visual_director/round-01/visual-development.md), [window report](../../art/room_photo_window_production/visual_director/round-01/visual-development.md), and [workshop report](../../art/settlement_workshop/visual_director/round-01/visual-development.md). Candidate evaluations include the source-to-target transfer diagnosis and paths to registered Godot production renders.

## Workflow integration

Art Factory policy now auto-classifies priority tier, screen-space importance, source-photo requirement, faction-defining status, and current quality. High-impact candidates are blocked before generation until a hash-current approved target exists; low-impact supporting props can bypass. A recipe must name the approved target in `source_inputs`, and the normal candidate JSON/history records target provenance and attempt strategy.

For each approved target, attempt 1 is the initial transfer, attempt 2 requires a prior diagnosis and targeted correction, and attempt 3 requires a materially different backend or material method. The three ArtBrief iteration budgets account for their pre-existing version numbers and leave room for all three new target attempts. The CLI exposes `visual-director status`, `prepare`, `approve`, and `backlog`. `approved_visual_target`, `best_3d_candidate`, and `production_asset` remain separately recorded. The cabinet and window show the gate producing promoted assets; the workshop backlog preserves accepted v004 instead of passing off a weaker challenger.
