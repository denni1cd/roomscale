# Batch 14 — Room A Household Bookcase Transfer

## Target and recovery

Batch 11's approved Tier 1 household-bookcase target remained the source of truth. The Room A object is 32 × 63 × 17 inches and uses the generic `detailed_furniture` fallback; the separate accepted `room_bookcase_production-v001` is fitted workshop storage and is not a replacement for this household bookcase.

The first Art Factory generation had stopped before Blender launched because `ROOMSCALE_BLENDER_EXECUTABLE` was missing. Blender 5.2.3 LTS was available at the main checkout, so the existing `bookcase-v001` record was retried with that executable. The original failed log and attempt identity were preserved; generation execution 2 succeeded under the same candidate and first Visual Director attempt. This exposed a real factory workflow gap: a blocked candidate could not resume without resetting its episode. The factory now stores retries under `generation-attempts/run-NNN`, preserves the original log, and records execution history on the candidate.

## Candidate review

| Candidate | Transfer and review result | Decision |
|---|---|---|
| [v001](../../art/bookcase/iterations/v001/evaluation.json) | First successful Blender transfer. The five-bay form, framed sides, shelf nosings, crown, plinth and book groups are present. The light/orange finish and weakly visible grain missed the darker household-oak target. | Continue to targeted correction. |
| [v002](../../art/bookcase/iterations/v002/evaluation.json) | Darker palette improved target color, but broad repeating waves appeared across the large panels. Pixel inspection showed the artifact clearly. This was worse than v001. | Reject as incumbent; preserve v001. |
| [v003](../../art/bookcase/iterations/v003/evaluation.json) | A materially different fine-grain strategy removed the broad waves and improved on v001. Fine grain is still evenly striped; shelf pins and frame joins remain hard to read. It is the best current 3D review candidate, but fails the close-craft and surface-variation gates. | Backlog the target at its three-strategy limit; no promotion. |

All three candidates preserve the measured envelope and share the same 11 meshes, 11 surfaces and 31,472 triangles. Godot 4.7.2 technical validation passed with no issues; v003 measures 32 × 63 × 17.06 inches against RoomDefinition's 32 × 63 × 17-inch dimensions. Candidate captures include [v001](../../art/bookcase/iterations/v001/render-runs/run-003/asset-detail.png), [v002](../../art/bookcase/iterations/v002/render-runs/run-001/asset-detail.png), and [v003](../../art/bookcase/iterations/v003/render-runs/run-001/asset-detail.png).

The target concept had prior Luna pixel-review provenance. No Luna reviewer tool was available for these candidate captures; the v001–v003 render pixels and evaluations were inspected directly in this session. Those candidate findings are not attributed to Luna.

## Integrated scene comparison

The source-photo-derived `room_photo_luna` definition contains no bookcase, so it was not used to invent one. The candidate was rendered in authoritative `rooms/room_a.json` with 50 citizens. Its [Room A overview](../../art/bookcase/iterations/v003/render-runs/run-001/room-scale.png) does not show a clear gameplay-distance improvement over the earlier [Room A review capture](../../art/room_chair/iterations/v006/render-runs/run-001/room-scale.png). The earlier image has a different review-only chair state and is not a strictly matched pre-batch capture, so this comparison is directional. Close inspection shows the improved dark palette and finer grain, but the bookcase is less visually prominent at overview scale than the previous shelf presentation.

No RoomDefinition dimensions, navigation, collision, citizen behavior, or gameplay geometry were changed. The bookcase remains review-only and the canonical production registry remains at 15 entries.

## Matched 50-citizen performance

Godot 4.7.2 GL Compatibility benchmarks used Room A, 50 citizens, the same machine and views, and disabled VSync. The candidate run enabled the review-only bookcase showcase registry. These machine-specific samples show small timing variation and no material regression.

| View | Baseline FPS / median / p95 ms | v003 FPS / median / p95 ms | Draw calls | Primitives |
|---|---:|---:|---:|---:|
| Room | 478.38 / 2.054 / 2.218 | 475.12 / 2.067 / 2.275 | 971 / 942 | 497,000 / 510,116 |
| Settlement | 535.33 / 1.848 / 1.962 | 534.59 / 1.855 / 1.950 | 1,058 / 1,058 | 771,854 / 771,854 |
| Citizen | 309.04 / 3.175 / 3.816 | 318.99 / 3.108 / 3.720 | 2,816 / 2,810 | 1,272,414 / 1,287,238 |

Raw evidence: [baseline](batch-14-bookcase/performance-baseline.json) and [v003 review](batch-14-bookcase/performance-candidate.json).

## Inventory, verification, and next priority

The inventory generator now reads current per-asset Visual Director state for best 3D review candidates while keeping them separate from the active runtime registry. It also checks the current production backlog rather than the archived POC backlog. The refreshed inventory covers 95 visible-art classes across 21 RoomDefinitions and 318 room-object records. It reports 48 Tier 1, 11 Tier 2, and 36 Tier 3 classes; 70 remain flagged as programmer-art or primitive-driven (26 Tier 1, 10 Tier 2, 34 Tier 3). Eight Tier 1 classes have accepted production registry entries and two more link to Art Factory asset families; 38 are not registered as unique production assets. These registry states do not mean every asset currently passes the repaired strict visual gate: the inventory has no Tier 1 strict-gate PASS recorded, and known incumbent re-audits include failures. Seven Tier 1 furniture classes now show explicit best-current review candidates, including this bookcase and the five Batch 10 challengers plus the chair. Tier 2 has one linked family and 10 unregistered classes. The canonical registry remains at 15 entries.

The Art Factory integrity suite passed **26 tests**. The next ranked target is the related Tier 1 Room A/B large-furniture family from Batch 10: workbench, assembly table, wardrobe, floor cabinet, and side table. Their previous challengers fit their envelopes but failed realism/craftsmanship gates, so another pass needs a materially different construction and material strategy.

This batch makes no claim that the full-game visual migration is complete.
