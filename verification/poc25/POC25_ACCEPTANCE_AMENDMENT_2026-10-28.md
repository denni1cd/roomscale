# RoomScale POC 2.5 — User-Authorized Acceptance Amendment

**Amendment:** POC25-AM-2026-10-28-01
**Authority:** explicit user authorization in the continuation note received 2026-10-28.
**State:** implementation direction amended; independent Rules Lawyer review still decides whether the POC is complete.

## Previous criterion

The earlier execution direction required Desk, Grapple, and Citizen to pass the repaired strict production-art visual gate, or reach an approved evidence-backed pilot plateau, before broad migration and READY FOR REVIEW. That requirement is preserved here as historical contract text. Its pilot-pass condition is superseded for POC-level completion by this amendment.

## Unchanged asset-level standard

The strict evaluator is not weakened. It continues to answer the realistic-read, close-inspection, seven craftsmanship, source-photo, and anti-placeholder questions from actual production captures. A failed or continued candidate remains failed or continued. This amendment does not retroactively change evaluations, promote assets, or turn legacy accepted registry entries into strict visual passes.

The canonical incumbents remain intact. The direct strict re-audit still finds visual failures for desk-v007, grapple-v006, and citizen-v007. Citizen v086 and v087 are also recorded as strict-gate continuations. See the append-only re-audit and candidate evaluations.

## New POC-level question

POC 2.5 may succeed when it proves the reusable autonomous Art Factory architecture and produces an integrated, materially improved best-current RoomScale experience, even while individual assets remain below production-final quality. The remaining strict-gate defects become a durable production-art backlog rather than automatic POC blockers.

## New completion criteria

The independent reviewer should assess the following evidence, rather than require every pilot to pass the strict art gate:

1. Reusable Art Factory contracts and orchestration are documented.
2. Multiple materially different production backends have been exercised.
3. Create → integrate → render → inspect → diagnose → refine or switch → compare is demonstrated by preserved candidates and evidence.
4. The evaluator rejects bad work honestly.
5. Incumbents, candidate histories, provenance, and promotion history are preserved.
6. Desk, Grapple, and Citizen each demonstrate the factory on a meaningfully different asset class.
7. A review-only best-current integrated scene is captured without changing the production-accepted registry.
8. The integrated scene is materially more credible and coherent than the pre-POC programmer-art baseline.
9. RoomDefinition, Room A/B, reconstructed-room, navigation, delivery, construction, traversal, and citizen activity remain intact.
10. Final representative-scene performance evidence is recorded with its hardware/workload limits.
11. Major unresolved art defects are in the production-art backlog.
12. No failed candidate is represented as production-quality PASS.
13. Future generation backends can be exchanged without redesigning gameplay or the factory's reusable orchestration.

READY FOR REVIEW means this evidence package is ready for independent Rules Lawyer disposition. It is not a self-issued COMPLETE.

## Evidence map

| Completion question | Evidence |
|---|---|
| Factory architecture and backend boundary | ART_FACTORY_ARCHITECTURE.md, scripts/art_factory/, scripts/visuals/ |
| Strategy variety | TRELLIS.2/DINOv3 desk-v049, Pixal3D desk-v052/v053, Hunyuan3D 2.1 desk-v054, SUPRA-Tex desk-v058, Blender component/PBR desk family, MPFB2 Citizen family, and procedural/Godot settlement/furniture records |
| Honest evaluation | final/strict-incumbent-visual-gate-reaudit.json, desk v052-v058 evaluations, Grapple v007-v009, Citizen v077-v087 |
| Preservation | unchanged art/registry.json and append-only art/<asset>/iterations/ candidate/evaluation/render history |
| Review-only integration and visual review | final/best-current-art-showcase-registry.json, [best-current integration review](BEST_CURRENT_INTEGRATION_REVIEW.md), and final/best-current-integration-run-005/ (14 captures and passing receipt) |
| Production-art follow-up | PRODUCTION_ART_BACKLOG.md |
| Current gameplay regressions | final/final-integration-smoke/room-a-showcase.log, room-b-showcase.log, and reconstructed-room-showcase.log |
| Performance evidence and limits | final/best-current-performance-run-001.json; RTX 5090 room/settlement/citizen results and the shared-workload limitation are recorded in BEST_CURRENT_INTEGRATION_REVIEW.md |
| Historical CI classification | final/ci-04e75d2-classification.md; later CI run 40417656855 passed all six jobs |

## Registry semantics

art/registry.json remains the production-accepted registry. The separate poc25_best_current_showcase registry uses best_current_review for the three pilots that fail the current strict re-audit. Loading those entries requires explicit ROOMSCALE_ART_REGISTRY_MODE=review_showcase; otherwise the runtime resolver rejects the registry. Captures and receipts carry the label BEST CURRENT / PRODUCTION ART FOLLOW-UP REQUIRED. This mode is a review/showcase boundary, not promotion or acceptance.

## Consolidation update — 2026-10-29

The bounded citizen experiment ended with `citizen-v089`: it improves the fitted workcoat silhouette over v087 while retaining the MPFB2 anatomy, 53-bone rig, five RoomScale pivots, and gameplay attachment contract. Its strict result remains `continue` at 4/5 Clockwork readability; it is not a visual PASS or production promotion. `citizen-v007` remains the production incumbent. No additional citizen refinement was started after this bounded experiment, consistent with the amended POC direction to consolidate rather than continue local art polishing.

The best-current showcase is captured with v089 in `final/best-current-integration-run-009/` and selected only by `final/best-current-art-showcase-registry-v089.json`. The receipt passes all 14 required production captures with 50 citizens, including furniture, settlement, active construction, deployed traversal, and citizen climbing. Earlier v087 integration evidence remains in run 005. The canonical production registry is unchanged.

The v089 50-citizen Compatibility-renderer performance record is `final/best-current-performance-run-002.json`: 58.89 FPS / 18.83 ms p95 in the room view, 156.48 / 7.70 ms at settlement distance, and 241.94 / 6.00 ms in the citizen view, VSync disabled. The room view is below 60 FPS; GPU clients were present and not all could be identified, so this remains a shared-desktop measurement rather than a controlled target-hardware verdict.

This dated update supplements the original acceptance amendment without rewriting its historical evidence or weakening the asset visual gate. The current evidence map is in `READY_FOR_REVIEW.md` and `BEST_CURRENT_INTEGRATION_REVIEW.md`; disposition remains `READY FOR REVIEW` pending independent review.