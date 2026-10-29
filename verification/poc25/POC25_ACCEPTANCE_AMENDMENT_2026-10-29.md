# RoomScale POC 2.5 — User-Authorized Criterion 8 Amendment

**Amendment:** `POC25-AM-2026-10-29-01`
**Authority:** explicit user authorization in the continuation request received 2026-10-29.
**Scope:** replace only criterion 8 of [POC25-AM-2026-10-28-01](POC25_ACCEPTANCE_AMENDMENT_2026-10-28.md). All other criteria and constraints remain unchanged.

## Acceptance history

1. **Original execution direction:** Desk, Grapple, and Citizen had to pass the strict visual gate, or reach an approved evidence-backed plateau, before broad migration. That all-pilots condition is preserved as history in the original execution materials and in the previous-criterion section of the 2026-10-28 amendment.
2. **First user-authorized POC amendment, 2026-10-28:** the pilot-pass condition was removed as a POC closure blocker, while a new criterion required a materially more credible and coherent integrated scene than the pre-POC baseline. See `POC25-AM-2026-10-28-01`.
3. **Controlled comparison and independent finding, 2026-10-29:** the matched baseline/final overview looks substantially similar and does not establish broad scene-wide transformation. Preserve that result in [the comparison record](final/matched-visual-comparison/comparison.md). The review found a contract defect: requiring a broad visual transformation inside the Art Factory POC made a later production-art migration a prerequisite for closing the POC that proves the factory.
4. **Final narrow amendment, 2026-10-29:** replace only criterion 8 with the text below. Broad room-wide migration belongs to the next production phase. This corrects acceptance scope; it does not change the art or the strict evaluator.

## Current completion criteria

Criteria 1–7 and 9–13 are unchanged from `POC25-AM-2026-10-28-01`:

1. Reusable Art Factory contracts and orchestration are documented.
2. Multiple materially different production backends have been exercised.
3. Create → integrate → render → inspect → diagnose → refine or switch → compare is demonstrated by preserved candidates and evidence.
4. The evaluator rejects bad work honestly.
5. Incumbents, candidate histories, provenance, and promotion history are preserved.
6. Desk, Grapple, and Citizen each demonstrate the factory on a meaningfully different asset class.
7. A review-only best-current integrated scene is captured without changing the production-accepted registry.
8. **The Art Factory demonstrates material visual improvement over the pre-POC programmer-art approach in representative asset classes and successfully integrates its best-current outputs into the live RoomScale scene. Broad scene-wide visual transformation is deferred to the subsequent production-art migration phase.**
9. RoomDefinition, Room A/B, reconstructed-room, navigation, delivery, construction, traversal, and citizen activity remain intact.
10. Final representative-scene performance evidence is recorded with its hardware/workload limits.
11. Major unresolved art defects are in the production-art backlog.
12. No failed candidate is represented as production-quality PASS.
13. Future generation backends can be exchanged without redesigning gameplay or the factory's reusable orchestration.

No other acceptance criterion is changed, weakened, deferred, or added by this amendment.

## Evidence map for amended criterion 8

The required improvement is comparative and representative. It does not require every pilot to pass its separate strict production-art gate.

| Evidence area | Existing evidence and interpretation |
|---|---|
| Citizen | The production gameplay-distance renders for [citizen-v007](../../art/citizen/iterations/v007/render-runs/run-006/asset-gameplay-distance.png) and [citizen-v089](../../art/citizen/iterations/v089/render-runs/run-001/asset-gameplay-distance.png), with [v007 receipt](../../art/citizen/iterations/v007/render-runs/run-006/receipt.json), [v089 receipt](../../art/citizen/iterations/v089/render-runs/run-001/receipt.json), and [v089 evaluation](../../art/citizen/iterations/v089/evaluation.json), show primitive-proportioned legacy figures replaced by anatomical, clothed, rigged MPFB2 citizens. The capture receipts use equivalent gameplay-distance camera settings. v089 is still strict `continue` and review-only. |
| Settlement architecture | The actual production render and [evaluation](../../art/settlement_workshop/iterations/v004/evaluation.json) for [settlement-workshop v004](../../art/settlement_workshop/iterations/v004/render-runs/run-001/asset-three-quarter.png) document separated roof, supports, timber, boiler, metalwork, and windows. Its matched incumbent comparison against workshop-v002 chiefly improves boiler visibility and workshop readability. It remains an accepted Art Factory output with documented limits; this is representative asset evidence, not a claim that all settlement/room architecture is finished. |
| Furniture | The recorded [hammock v001](../../art/hammock_with_stand/iterations/v001/render-runs/run-001/asset-three-quarter.png) to [hammock v005](../../art/hammock_with_stand/iterations/v005/render-runs/run-001/asset-three-quarter.png) progression and [v005 evaluation](../../art/hammock_with_stand/iterations/v005/evaluation.json) show a fitted, striped cloth body added to the earlier bare frame. The accepted office-chair and other furniture renders provide additional production-path examples. |
| Grapple/traversal machinery | The [grapple-v006 close render](../../art/grapple/iterations/v006/render-runs/run-003/asset-detail.png), [evaluation](../../art/grapple/iterations/v006/evaluation.json), deployment captures, and gameplay smokes show a mechanically articulated spool/anchor integrated with working traversal. Its strict close-workmanship result remains FAIL. |
| Generated material workflow | Desk v023 [recipe](../../art/desk/iterations/v023/recipe.json) and [evaluation](../../art/desk/iterations/v023/evaluation.json) record generated albedo/roughness maps, separate PBR material slots, and the actual Godot production-path render. It is explicitly rejected because the tabletop exported vertically and the source-photo visual gate failed. This supports honest method/evaluator evidence; it is not counted as a successful desk visual improvement. |
| Live integration | The [v089 best-current review receipt](final/best-current-integration-run-009/receipt.json) records 14 production captures with no missing phases, 50 citizens, and a read-only review registry. The [review registry contract](final/v089-review-registry-contract.log), [Room A](final/room-a-v089-review-showcase.log), [Room B](final/room-b-v089-review-showcase.log), and [reconstructed-room](final/reconstructed-room-v089-review-showcase.log) logs verify that v089, desk-v007, and grapple-v006 resolve without silent fallback while gameplay remains functional. `art/registry.json` remains unchanged. |

The accepted and best-current examples above are not relabeled as strict pilot PASS. Their candidate evaluations and [production-art backlog](PRODUCTION_ART_BACKLOG.md) remain authoritative for production-quality readiness.

## Preserved next-phase finding

The controlled comparison still concludes: **broad scene-wide visual transformation has not yet occurred**. It is reclassified from a POC completion blocker to a production-art migration finding. It must not be deleted, softened, reframed as a visual PASS, or used to imply that the next phase is already complete.

The next phase is **Art Factory production deployment**: inventory visible RoomScale art, assign stable semantic IDs, prioritize assets by visual importance and current quality, process bounded batches, periodically review the whole integrated game, send unresolved quality issues to the production-art backlog, and replace generation backends when stronger supported methods become available. No broad migration is part of POC 2.5 closure.

## Unchanged boundaries

- The strict individual-asset visual evaluator is unchanged.
- The strict results remain: citizen-v089 `continue`; desk-v007 and grapple-v006 strict failures.
- No historical evaluation or promotion is rewritten.
- No best-current review asset is promoted into the canonical production registry.
- RoomDefinition and gameplay geometry remain authoritative; visual assets remain presentation-only.
- Runtime has no generation-service dependency.
- POC 2.5 art iteration is frozen. No new challenger or backend experiment is authorized by this amendment.
