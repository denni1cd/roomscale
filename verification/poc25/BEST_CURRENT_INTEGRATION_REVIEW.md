# POC 2.5 Best-Current Integration — Visual Review

**State:** evidence prepared for independent review. Every asset remains subject to its unchanged strict visual gate.
**Integration:** `room_photo_luna`, Clockwork profile, 50 active citizens, Godot 4.7.2 Compatibility renderer.
**Registry:** `final/best-current-art-showcase-registry.json`, loaded only with `ROOMSCALE_ART_REGISTRY_MODE=review_showcase`. It does not change `art/registry.json`.
**Capture:** `final/best-current-integration-run-005/receipt.json` reports PASS, 14 actual production captures, all required phases, zero missing phases, and 50 citizens. The filenames record the captures; `nursery-close.png` is the close workshop/settlement view in this no-founder simulation.

## Representative captures

| View | Evidence |
|---|---|
| Room and its opposite angle | [room overview](final/best-current-integration-run-005/room-scale.png), [opposite view](final/best-current-integration-run-005/room-scale-opposite-angle.png) |
| Settlement architecture | [settlement scale](final/best-current-integration-run-005/settlement-scale.png), [workshop close](final/best-current-integration-run-005/nursery-close.png) |
| Major furniture | [desk in the production room](final/best-current-integration-run-005/major-furniture.png) |
| Citizens | [12-inch gameplay distance](final/best-current-integration-run-005/citizens-gameplay-distance.png), [close citizen](final/best-current-integration-run-005/citizen-close.png), [v087 four-facing production stills](../../art/citizen/iterations/v087/render-runs/run-003/) |
| Production activity | [material delivery](final/best-current-integration-run-005/resource-wood.png), [active construction](final/best-current-integration-run-005/active-construction.png), [deployed traversal route](final/best-current-integration-run-005/traversal-whole-route.png), [citizen climbing](final/best-current-integration-run-005/citizen-climbing.png) |
| Baseline comparison anchor | [pre-POC canonical room capture](baseline/canonical-visuals/room_photo_luna-initial-room.png) |

## Visual findings

- **Citizens:** `citizen-v087` retains the MPFB2 anatomical body and working 53-bone rig, with a Clockwork helmet, paired goggles, fitted teal workwear, canvas apron, pressure pack, boots, and carried tool. It is a substantial anatomical/material improvement over the block-built `citizen-v007`. The controlled capture and the integrated 12-inch view show those role cues, but the strict evaluation still records `continue`: the role does not remain unmistakable at all facings, the tool masks the apron, and population performance is not isolated. Keep citizen-v007 as the production incumbent and v087 as best-current review art.
- **Architecture:** the Clockwork settlement buildings use separate geometry for roofs, supports, doors, boiler, work surfaces, brass trim, and machinery. They read as a coherent miniature workshop set more clearly than the earlier placeholder-like blocks. The room shell and broad floor remain simple, large color fields and hard shadows still dominate, and the current images do not establish high-end architectural finish.
- **Furniture:** the desk is now framed from inside the room so the actual registered object is visible. `desk-v007` remains materially flat and misses the source photograph's reflection/material character; it remains review-only and fails the strict gate. The accepted furniture assets and RoomDefinition/gameplay bounds remain in place.
- **Grapple and activity:** the capture shows the real delivery, active build, deployed route, and a climbing worker using grapple hardware in the production scene. The dedicated `upper-anchor.png` camera is partly occluded by a foreground wall, so the climbing view and traversal receipt carry the deployed-use evidence. The grapple remains simplified in close workmanship and is not represented as a strict visual pass.
- **Baseline comparison:** the baseline and final overview cameras differ, so these images are not a pixel-matched before/after benchmark. The evidence supports a material improvement in the modeled citizen, settlement, and furniture asset classes and a more complete integrated presentation. It does not show a finished room-wide environment; a reviewer should judge whether this constitutes the amended POC-level improvement.

## Runtime and performance evidence

Fresh explicit-showcase Clockwork smokes passed in Room A, Room B, and reconstructed `room_photo_luna`: each exercised 50 production citizens, navigation, all 11 material deliveries, construction, grapple deployment/traversal, and exploration. Logs are in `final/final-integration-smoke/`.

The VSync-disabled benchmark in [best-current-performance-run-001.json](final/best-current-performance-run-001.json) used an RTX 5090, Godot 4.7.2 Compatibility, and 50 citizens. It recorded 32.98 FPS / 32.95 ms p95 in the room view, 88.55 FPS / 15.94 ms p95 at settlement distance, and 206.20 FPS / 10.95 ms p95 in the citizen view. The room view is below 60 FPS. A GPU snapshot immediately after the run showed 78% utilization and one process whose identity was inaccessible; therefore the result is recorded but not an isolated target-hardware verdict. Do not claim a 60-FPS pass from this run.

## CI classification

The original failures from Actions run `40256472981` on `04e75d2` were POC 2.5 regressions: citizen presentation leaked Clockwork art into Verdant, and Windows CRLF conversion broke text-scene registry hashes. Both were repaired. The newer quality runs `40738817339` and `40756019436` then found formatting and lint issues in candidate-specific citizen generation scripts; the civilization smoke jobs passed. Those issues have local repairs, but remote CI still needs a fresh run after the review package is pushed. The run-by-run evidence is in [dated CI classification](final/ci-quality-classification-2026-10-28.md) and [the original regression classification](final/ci-04e75d2-classification.md).

## Review boundary

This document presents best-current evidence. It does not weaken the visual evaluator, alter any past evaluation, promote desk/grapple/citizen, replace the canonical registry, or self-issue POC `COMPLETE`. Remaining visual and performance work is tracked in [PRODUCTION_ART_BACKLOG.md](PRODUCTION_ART_BACKLOG.md).
