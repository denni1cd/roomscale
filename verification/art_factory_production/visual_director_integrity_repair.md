# Visual Director integrity repair

Date: 2026-11-01

This repair reconciles existing Visual Director records and fixes evaluation provenance. It does not open another art attempt.

## Production source of truth

`art/registry.json` is the single canonical production registry. A Visual Director case records its approved target, best 3D candidate, and production asset separately; its `production_asset` must match the canonical entry after promotion. Render receipts identify the asset and candidate they loaded. The runtime resolver reads the canonical registry and treats accepted registered assets as required, with no procedural fallback if the file, hash, or import is invalid. Candidate review registries under render-run folders remain temporary review inputs and are not production registries.

| Semantic asset ID | Approved target (SHA-256) | Best 3D candidate | Production candidate | Canonical/runtime asset |
| --- | --- | --- | --- | --- |
| `display_cabinet` | `art/display_cabinet/visual_director/round-01/approved-target-r01.png` (`a0fe5cef719d1a9385b6298b885dfcc6e2d3e9669b9e639f7bd0b8178c03a8fb`) | `display_cabinet-v003` | `display_cabinet-v003` (`production_pass`) | `art/display_cabinet/iterations/v003/generated/asset.glb` (`8c15eca7a425ae995bffeca013876c63aae8efd0e383649cfb046bcebe371d02`) |
| `room_photo_window_production` | `art/room_photo_window_production/visual_director/round-01/approved-target-r01.png` (`9c1d6b5d103f1e3840bcb44dd79a12a7ff53df07d859d9d5ed91154feba421c1`) | `room_photo_window_production-v004` | `room_photo_window_production-v004` (`production_pass`) | `art/room_photo_window_production/iterations/v004/generated/asset.glb` (`2ac833c5e331a5f7a2b191df4808074e089607fc33ca264bc6d8b21083b15d61`) |
| `settlement_workshop` | `art/settlement_workshop/visual_director/round-01/approved-target-r01.png` (`9313647a47a2c7ea5c71840499e0e8202e8191e02e72435fb58c7238eb7037b5`) | `settlement_workshop-v004` | `settlement_workshop-v004` (`backlog`) | `art/settlement_workshop/iterations/v004/generated/settlement_workshop.tscn` (`51d0a17746bc0319e2238689dca5c45c6b7d20f58ce1c57a025b6af11cfcec3c`) |

For each row, the canonical registry, Visual Director `production_asset`, promoted candidate evaluation, production receipt's `loaded_candidate_id`/`loaded_asset_path`, and runtime resolution now agree. Workshop v007 remains a failed challenger; its `continue` evaluation and backlog state preserve v004 as production.

## Corrected evaluation evidence

The iteration evaluation and Visual Director assessment were corrected together for each candidate:

- Cabinet: [iteration evaluation](../../art/display_cabinet/iterations/v003/evaluation.json) and [assessment](../../art/display_cabinet/visual_director/round-01/assessments/display_cabinet-v003.json). Evidence now describes the walnut case, framed doors, shelves, hardware, and crown/base in the cabinet's registered Godot renders. It contains no window-specific evidence.
- Window v003: [iteration evaluation](../../art/room_photo_window_production/iterations/v003/evaluation.json) and [assessment](../../art/room_photo_window_production/visual_director/round-01/assessments/room_photo_window_production-v003.json). The center stile still hides the target latch, so v003 remains a non-promoted failed transfer.
- Window v004: [iteration evaluation](../../art/room_photo_window_production/iterations/v004/evaluation.json) and [assessment](../../art/room_photo_window_production/visual_director/round-01/assessments/room_photo_window_production-v004.json). Evidence describes the casing, transom, sash, sill, glazing, and visible latch. The render has five upper panes while the target has four; this recorded mismatch did not change the existing scores or promotion.
- Workshop v007: [iteration evaluation](../../art/settlement_workshop/iterations/v007/evaluation.json) and [assessment](../../art/settlement_workshop/visual_director/round-01/assessments/settlement_workshop-v007.json). Evidence now describes posts, braces, canopy, boiler fittings, flywheel, workbench, timber, metal, and stone. It contains no window-specific evidence. The incomplete one-sided canopy remains a visual failure.

The contamination was in the saved evaluation records. The evaluator required free-form evidence strings but did not bind each craftsmanship claim to a candidate render or reject reused prose; the review template also lacked per-check render references. The evaluator had no hardcoded cabinet/window/workshop evidence defaults. Each craftsmanship check now cites a render path registered to that candidate's production render, and `ArtFactory.record_evaluation` requires those references and rejects identical craftsmanship wording recorded for a different semantic asset. The review template instructs reviewers to record visible, asset-specific evidence and to report absent or unclear details instead of reusing prose from another evaluation.

## Dispositions

| Candidate under review | Disposition after evidence correction | Production result |
| --- | --- | --- |
| `display_cabinet-v003` | **PROMOTED** | Cabinet renders show the described construction and hardware; canonical production remains v003. |
| `room_photo_window_production-v004` | **PROMOTED** | The second-pass latch is visible in the Godot close view; canonical production remains v004. The five-versus-four pane mismatch is documented. |
| `settlement_workshop-v007` | **INCUMBENT RETAINED** | The v007 canopy/truss transfer remains weaker; v004 remains best 3D and production, with the target episode backlogged. |

No promotion was revoked, and no new art was generated.

## Automated safeguards and verification

- `scripts/test_art_factory.py` checks registry/state/evaluation/receipt candidate agreement, content hashes, per-check render references, and cross-asset window-term leakage.
- `scripts/visuals/visual_resolver_test.gd` resolves the three production cases through the canonical runtime registry and asserts the loaded candidate/path with no fallback.
- `scripts/room_definition_test.gd` validates the promoted cabinet v003 GLB's material-batched glazing, interior, and frame; it no longer expects the retired v002 scene's node names.
- `.github/workflows/quality.yml` runs the Art Factory integrity tests and visual resolution checks as part of CI.
- Local checks passed: Ruff lint, Ruff format, 24 Art Factory tests, the full fast verification suite, Godot asset validation, production registry resolution, and presentation checks.
- The previous final-head workflow run, [41311559055](https://github.com/denni1cd/roomscale/actions/runs/41311559055), failed Ruff on unsorted imports and unused locals. Those reported issues were repaired; its stale presentation expectation for cabinet v002 was updated to v003.

Final-head GitHub Actions results are attached to the repair commit and reported with its exact SHA and run ID.
