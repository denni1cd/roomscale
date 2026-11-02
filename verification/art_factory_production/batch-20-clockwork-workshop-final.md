# Batch 20 — Clockwork Workshop Final Target Attempt

## Scope and decision

This batch completed the third and final strategy against the Luna-approved Clockwork workshop r01 target. Candidate `settlement_workshop-v009` was built by editing the current best 3D assembly, v008, with a Godot-authored full-width lower canopy, a chimney opening with copper flashing, and a raised rear ridge tier. The recipe, generator, native scene, technical report, and candidate-local renders are retained in the repository.

Godot 4.7.2 validation passed at 26 × 19.94 × 20 inches with 158 meshes/surfaces and 32,640 triangles. The boiler, flue, flywheel, gear, workbench, and presentation/gameplay ownership remain. The ArtBrief gameplay invariants and RoomDefinition were not changed.

The three-quarter and detail pixels show v009 makes a two-tier canopy more explicit than v008, but its raised tier reads as a separate, oversized canopy. The detail view shows panels crowding the lower roof and the thin monitor posts fail to read as supports. Their bottoms are at y=16.60 inches while the lower roof plane at x=±3.6 is about y=15.93, leaving approximately 0.67 inches without a roof, beam, or bracket connection. The render also falls short of the target's close-range framing, fasteners, bench tools, and material finish. Luna directly inspected the approved target and v008/v009 PNGs; she found v008 simpler but more coherent, noted that v009 hides more of the interior, and recommended continuing the two-tier direction only after reducing/centering it and joining its supports to load-bearing structure. The candidate evaluation records `continue` and a worse comparison; joins and manufacturing detail fail. Because this was attempt 3, the approved r01 episode is now backlogged. v008 remains the best current 3D candidate, while accepted v004 remains the canonical production asset. No promotion occurred.

The approved concept was previously reviewed by Luna. Luna also reviewed the actual candidate PNGs for this final attempt. Codex independently checked the same pixels and geometry dimensions.

## Matched integrated-scene review

The v008 and v009 settlement-scale captures use the same `room_photo_luna` RoomDefinition and Godot production path. v009's larger canopy is visible on the workshop, but the workshop remains small in frame. The surrounding settlement still reads as sparse prototype staging, so this asset-level improvement does not make RoomScale visibly better as a whole scene. See the [v008 overview](../../art/settlement_workshop/iterations/v008/render-runs/run-001/settlement-scale.png) and [v009 overview](../../art/settlement_workshop/iterations/v009/render-runs/run-001/settlement-scale.png).

At the room overview camera, the workshop is a tiny feature in the miniature settlement near the center of the human room; v004, v008, and v009 do not produce a visible room-wide transformation. These captures explain why the close asset view should not be treated as a gameplay-distance result: see [v004](../../art/settlement_workshop/iterations/v004/render-runs/run-002/room-scale.png), [v008](../../art/settlement_workshop/iterations/v008/render-runs/run-001/room-scale.png), and [v009](../../art/settlement_workshop/iterations/v009/render-runs/run-001/room-scale.png). The captures are Godot production-path renders with the review registry selected for the challenger; v009 is not the live canonical asset.

## Warmed 50-citizen performance

Godot 4.7.2 Compatibility samples used the same room file, 50 citizens, and three warmed 8-second views per candidate. These are single-session measurements; they are useful for a matched comparison, not a cross-hardware guarantee.

| View | v008 median / p95 ms | v009 median / p95 ms | Draw calls v008 → v009 |
| --- | ---: | ---: | ---: |
| Room | 2.976 / 3.527 | 3.080 / 3.620 | 1,276 → 1,322 |
| Settlement | 2.657 / 3.289 | 2.760 / 3.350 | 1,390 → 1,598 |
| Citizen | 2.316 / 2.948 | 2.470 / 3.020 | 1,188 → 887 |

The room and settlement medians rose by about 0.10 ms, and settlement draw calls rose by 208. The citizen sample also rose slightly in frame time while draw calls fell, so this one run does not support attributing every view delta to the workshop geometry. Every measured p95 was below 3.7 ms; these samples do not capture worst-case spikes. Raw results are [v008](batch-20/performance-v008.json) and [v009](batch-20/performance-v009.json).

## Inventory and integrity

The Visual Director record now shows three evaluated attempts and `backlog`; `best_3d_candidate` is v008 and `production_asset` is v004. `python -m scripts.art_factory verify settlement_workshop` passed against v004. The visual inventory was refreshed from the state-first best-3D record. The canonical registry still has 15 entries.

- Candidate attempted: settlement workshop v009, alternate Godot component-authoring strategy.
- Best current 3D candidate: v008. v009 was reviewed and is a worse challenger. Production: accepted v004. Promotions: none.
- Visual Director target: existing Luna-approved r01; Luna inspected actual candidate pixels, with no new target approval.
- Target disposition: three-strategy limit reached; backlog the disconnected raised-tier supports and remaining close-detail transfer loss.
- Whole-scene result: no obvious transformation; the settlement remains visibly prototype-heavy.
- Performance: small room/settlement frame-time increases in this matched 50-citizen sample; no measured frame-budget concern.
- Integrity: 28 Art Factory tests passed; Ruff and Python compilation passed for the updated integrity test; production verification passed against v004.
- Next priority: return to the ranked faction-identity queue and choose a source-supported Verdant or Scavenger asset with meaningful silhouette/construction impact.
