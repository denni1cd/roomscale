# POC 2.5 Best-Current Integration — Visual Review

**State:** evidence prepared for independent review. Every asset remains subject to its unchanged strict visual gate.
**Integration:** `room_photo_luna`, Clockwork profile, 50 active citizens, Godot 4.7.2 Compatibility renderer.
**Registry:** `final/best-current-art-showcase-registry-v089.json`, loaded only with `ROOMSCALE_ART_REGISTRY_MODE=review_showcase`. It does not change `art/registry.json`; citizen-v007 remains the production incumbent.
**Current capture:** `final/best-current-integration-run-009/receipt.json` reports PASS, 14 actual production captures, all required phases, zero missing phases, and 50 citizens. It uses the completed citizen-v089 broad-coat challenger as review art. The earlier v087 run is preserved at `final/best-current-integration-run-005/`.

## Representative captures

| View | Evidence |
|---|---|
| Room and its opposite angle | [room overview](final/best-current-integration-run-009/room-scale.png), [opposite view](final/best-current-integration-run-009/room-scale-opposite-angle.png) |
| Settlement architecture | [settlement scale](final/best-current-integration-run-009/settlement-scale.png), [workshop close](final/best-current-integration-run-009/nursery-close.png) |
| Major furniture | [desk in the production room](final/best-current-integration-run-009/major-furniture.png) |
| Citizens | [12-inch gameplay distance](final/best-current-integration-run-009/citizens-gameplay-distance.png), [close citizen](final/best-current-integration-run-009/citizen-close.png), [v089 four-facing production stills](../../art/citizen/iterations/v089/render-runs/run-001/) |
| Production activity | [material delivery](final/best-current-integration-run-009/resource-wood.png), [active construction](final/best-current-integration-run-009/active-construction.png), [deployed traversal route](final/best-current-integration-run-009/traversal-whole-route.png), [citizen climbing](final/best-current-integration-run-009/citizen-climbing.png) |
| Controlled AC-8 comparison | [baseline-matched.png](final/matched-visual-comparison/baseline-matched.png), [final-matched.png](final/matched-visual-comparison/final-matched.png), and the [comparison record](final/matched-visual-comparison/comparison.md) |

## Visual findings

- **Citizens:** `citizen-v089` retains the MPFB2 anatomical body and working 53-bone rig, with a broader split machinist overcoat, strengthened yoke, mechanically constructed helmet, paired goggles, pressure pack, boots, and carried tool. Its wider workwear silhouette improves on v087 and is a substantial anatomical/material improvement over block-built `citizen-v007`. The fixed 12-inch production facings still rate Clockwork readability 4/5, not the required 5/5; the role is not dominant from every facing and the tool masks the front garment. Its strict evaluation remains `continue`. Keep citizen-v007 in the production registry and label v089 as review-only best-current art.
- **Architecture:** the Clockwork settlement buildings use separate geometry for roofs, supports, doors, boiler, work surfaces, brass trim, and machinery. They read as a coherent miniature workshop set more clearly than the earlier placeholder-like blocks. The room shell and broad floor remain simple, large color fields and hard shadows still dominate, and the current images do not establish high-end architectural finish.
- **Furniture:** the desk is now framed from inside the room so the actual registered object is visible. `desk-v007` remains materially flat and misses the source photograph's reflection/material character; it remains review-only and fails the strict gate. The accepted furniture assets and RoomDefinition/gameplay bounds remain in place.
- **Grapple and activity:** the capture shows the real delivery, active build, deployed route, and a climbing worker using grapple hardware in the production scene. The dedicated `upper-anchor.png` camera is partly occluded by a foreground wall, so the climbing view and traversal receipt carry the deployed-use evidence. The grapple remains simplified in close workmanship and is not represented as a strict visual pass.
- **Controlled baseline comparison:** the new 1280×720 pair holds the RoomDefinition, Clockwork context, target, distance, tilt, yaw, FOV, overlay, and renderer constant. The pair looks substantially similar at this room-scale framing; citizens and settlement structures are not legible in it, the furniture changes are not clearly visible, and the grapple is not deployed. The comparison therefore does **not** establish amended criterion 8. Close citizen/workshop views show current-state detail but are not matched baseline evidence. See the [bounded comparison record](final/matched-visual-comparison/comparison.md). This finding does not change any strict asset result.

## Runtime and performance evidence

Fresh explicit `review_showcase` Clockwork smokes passed with citizen-v089 in Room A, Room B, and reconstructed `room_photo_luna`: each exercised 50 citizens, navigation, all 11 material deliveries, construction, actual grapple climbing, and continued exploration. The registry contract confirms v089/v007/v006 review-only resolution with zero diagnostics and no silent fallback; `art/registry.json` remained unchanged. Logs are `final/room-a-v089-review-showcase.log`, `final/room-b-v089-review-showcase.log`, and `final/reconstructed-room-v089-review-showcase.log`; the aggregate is `final/v089-showcase-smoke-summary.json`.

The latest VSync-disabled benchmark is [best-current-performance-run-002.json](final/best-current-performance-run-002.json). With v089 loaded, 50 citizens, Godot 4.7.2 Compatibility, and an RTX 5090, it measured 58.89 FPS / 18.83 ms p95 in the room view, 156.48 FPS / 7.70 ms p95 at settlement distance, and 241.94 FPS / 6.00 ms p95 in the citizen view. The room view is below 60 FPS and had a 52.34 ms maximum frame. A post-run snapshot showed 1% GPU utilization and 874 MiB used, but Windows did not identify several GPU clients; this was a shared desktop run, not an isolated target-hardware verdict. Do not claim a 60-FPS pass. The earlier v087 benchmark remains preserved in `best-current-performance-run-001.json`.

## CI classification

The original failures from Actions run `40256472981` on `04e75d2` were POC 2.5 regressions: citizen presentation leaked Clockwork art into Verdant, and Windows CRLF conversion broke text-scene registry hashes. Both were repaired. Runs `40738817339` and `40756019436` found formatting and lint issues in candidate-specific citizen generation scripts; those are also repaired. The final review-package commit is checked by its own [branch Actions history](https://github.com/denni1cd/roomscale/actions?query=branch%3Acodex%2Fpoc25-art-factory-review); the final handoff identifies the run on the exact pushed SHA. Earlier passing runs remain historical and are not substituted for final-head CI. The run-by-run evidence is in [dated CI classification](final/ci-quality-classification-2026-10-28.md) and [the original regression classification](final/ci-04e75d2-classification.md).

## Review boundary

This document presents best-current evidence. It does not weaken the visual evaluator, alter any past evaluation, promote desk/grapple/citizen, replace the canonical registry, or self-issue POC `COMPLETE`. Remaining visual and performance work is tracked in [PRODUCTION_ART_BACKLOG.md](PRODUCTION_ART_BACKLOG.md).
