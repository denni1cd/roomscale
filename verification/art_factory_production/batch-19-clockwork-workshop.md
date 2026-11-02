# Batch 19 — Clockwork Workshop Canopy Correction

## Scope and Visual Director

This bounded pass resumed the Luna-approved r01 target for the Tier 1 Clockwork workshop. It produced one targeted correction, `settlement_workshop-v008`, from accepted v004. This is attempt 2 of 3. The actual candidate and incumbent pixels were inspected directly by Codex; the available tools do not provide a Luna review interface, so this report does not attribute the candidate review to Luna. The approved target itself remains the previously recorded Luna-reviewed target.

The correction replaces v004's detached roof wings with a tied gable over the workbench bay. It keeps the boiler/flue lane open and preserves the accepted machinery, materials, presentation bounds, and gameplay-owned contracts. The [candidate recipe](../../art/settlement_workshop/iterations/v008/recipe.json), [generator](../../scripts/art_factory/generators/generate_workshop_ridge_correction.gd), and [technical validation](../../art/settlement_workshop/iterations/v008/technical-validation.json) are retained.

Godot 4.7.2 validation passed with exact bounds of 26 × 19.94 × 20 inches, 112 meshes/surfaces, 23,808 triangles, and no reported issues. Matched production captures show a coherent ridge and connected trusses while the boiler, flywheel, and workbench remain visible. See [v008 three-quarter](../../art/settlement_workshop/iterations/v008/render-runs/run-001/asset-three-quarter.png) and [detail](../../art/settlement_workshop/iterations/v008/render-runs/run-001/asset-detail.png), compared with [v004 three-quarter](../../art/settlement_workshop/iterations/v004/render-runs/run-002/asset-three-quarter.png) and [detail](../../art/settlement_workshop/iterations/v004/render-runs/run-002/asset-detail.png).

The approved target has a much broader lower roof and a second raised ridge tier. v008 covers only the workbench bay, so it is not ready for production. The evidence-backed evaluation records `continue`, a target-fit hard failure, and v008 as the better 3D review candidate. The canonical registry and production asset remain v004; there is no promotion. The next step is the final alternate-strategy attempt, aimed at the two-tier roof, an opening around the chimney, connected supports, an open front, and the existing envelope.

## Integrated scene and performance

The same room, 50 citizens, renderer, and settlement camera were used for v004 and v008. In the [settlement-scale v004 capture](../../art/settlement_workshop/iterations/v004/render-runs/run-002/settlement-scale.png) and [v008 capture](../../art/settlement_workshop/iterations/v008/render-runs/run-001/settlement-scale.png), the workshop remains small in frame; the canopy change is not a visible whole-scene transformation. The surrounding settlement staging remains sparse and prototype-like.

Warmed 50-citizen renderer samples used three 8-second views per candidate:

| View | v004 median / p95 ms | v008 median / p95 ms | Draw calls v004 → v008 |
| --- | ---: | ---: | ---: |
| Room | 2.911 / 3.543 | 3.036 / 3.709 | 1250 → 1276 |
| Settlement | 2.575 / 2.970 | 2.675 / 3.134 | 1381 → 1459 |
| Citizen | 2.528 / 3.180 | 2.491 / 3.052 | 915 → 915 |

The two settlement-focused p95 values increased by about 0.16 ms; the citizen view was effectively flat. These are single-session measurements on the configured RTX 5090 renderer, not broad hardware guarantees. Raw results are [v004](batch-19/performance-v004.json) and [v008](batch-19/performance-v008.json).

## Inventory, integrity, and disposition

The inventory generator previously chose the legacy showcase candidate ahead of a newer Visual Director evaluation. It now uses `best_3d_candidate` first, with a regression test; the refreshed inventory reports v008 / `continue` while production remains accepted v004. The Visual Director record also clears stale backlog status when a target episode resumes. The canonical registry remains at 15 entries. Inventory coverage remains 95 art classes, 21 RoomDefinitions, and 318 room-object records.

- Candidate attempted: Clockwork workshop v008; no new target approval.
- Best 3D review candidate: v008. Production asset: v004. Promotions: none.
- Target disposition: one alternate-strategy attempt remains; do not broaden this episode beyond its three-attempt limit.
- Gameplay/RoomDefinition: no changes to the authority, geometry, stations, steam, gears, or citizen assignments.
- Verification: candidate validation passed; `python -m scripts.art_factory verify settlement_workshop` passed; 28 Art Factory tests passed; Ruff lint and Python compilation passed for the touched Python files, and formatting checks passed for the inventory and test modules; visual inventory refreshed successfully.
- Full Fast CI was not rerun in this batch; the targeted integrity suite passed.
- Full-game migration remains incomplete. Continue with the bounded final workshop attempt, then return to the ranked faction-identity queue.
