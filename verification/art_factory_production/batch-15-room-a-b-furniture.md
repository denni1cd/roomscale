# Batch 15 — Room A/B Large Furniture Alternate Strategy

## Scope and strategy

Batch 15 completed a third bounded Visual Director attempt for five Tier 1 Room A/B assets: elevated workbench, assembly table, tool wardrobe, floor cabinet and side table. Each target episode had two reviewed candidates; a third generation had been refused at the iteration budget. Each ArtBrief budget was extended by one attempt only, preserving the existing target and episode history. The new candidates were recorded as alternate strategy attempt 3.

The generator now uses restrained, irregular oak variation rather than broad repeating waves. Workbench and assembly-table tops use separate boards with dog holes; the wardrobe uses narrower door leaves to widen the center reveal; the floor cabinet adds rounded feet and a shaped skirt; and the side table uses a joined-board top with a revised leg profile. All five models remain review-only.

The source Visual Director concepts had previously been pixel-reviewed and approved by Luna. New RoomScale candidate pixels were inspected directly by Codex; no Luna candidate-review tool was available, so these findings are not attributed to Luna.

## Candidate outcomes

| Asset | New candidate and technical bounds (inches) | Pixel review and incumbent decision |
|---|---|---|
| [Elevated workbench v009](../../art/room_elevated_workbench/iterations/v009/evaluation.json) | 58 × 36 × 30.12 raw; 7 meshes, 28,688 triangles; Godot import passed. Runtime fitting normalizes depth to RoomDefinition's 30 inches. | Separate boards, dog holes and calmer grain improve on v008. The screw vise, fitted joins and substantial drawer details remain absent. Best current becomes v009; strict realism and craft gates fail. [Target](../../art/room_elevated_workbench/visual_director/round-04/approved-target-r04.png), [three-quarter](../../art/room_elevated_workbench/iterations/v009/render-runs/run-003/asset-three-quarter.png), [detail](../../art/room_elevated_workbench/iterations/v009/render-runs/run-003/asset-detail.png). |
| [Assembly table v008](../../art/room_assembly_table/iterations/v008/evaluation.json) | 42 × 24 × 32; 6 meshes, 20,760 triangles; Godot import passed. | Joined top boards and quieter wood improve on v007. The target's end vise and fitted construction are not legible. Best current becomes v008; strict visual gates fail. [Target](../../art/room_assembly_table/visual_director/round-03/approved-target-r03.png), [three-quarter](../../art/room_assembly_table/iterations/v008/render-runs/run-001/asset-three-quarter.png), [detail](../../art/room_assembly_table/iterations/v008/render-runs/run-001/asset-detail.png). |
| [Tool wardrobe v008](../../art/room_tool_wardrobe/iterations/v008/evaluation.json) | 42 × 69.90 × 21.51; 5 meshes, 21,964 triangles; Godot import passed. Runtime fitting normalizes to 42 × 70 × 22. | The wider center reveal and calmer grain improve on v007, but mostly closed leaves still conceal an empty bay. Tools, drawers and crafted fittings from the target are missing. Best current becomes v008; strict visual gates fail. [Target](../../art/room_tool_wardrobe/visual_director/round-03/approved-target-r03.png), [three-quarter](../../art/room_tool_wardrobe/iterations/v008/render-runs/run-001/asset-three-quarter.png), [detail](../../art/room_tool_wardrobe/iterations/v008/render-runs/run-001/asset-detail.png). |
| [Floor cabinet v008](../../art/room_floor_cabinet/iterations/v008/evaluation.json) | 26 × 21 × 24; 4 meshes, 12,612 triangles; Godot import passed. | Grain is calmer and small rounded feet were added, but the front remains plain and the detail capture shows comb-like artifacting along the lower skirt. This is not a clear overall improvement; v005 remains best current. Strict gates fail. [Target](../../art/room_floor_cabinet/visual_director/round-03/approved-target-r03.png), [three-quarter](../../art/room_floor_cabinet/iterations/v008/render-runs/run-001/asset-three-quarter.png), [detail](../../art/room_floor_cabinet/iterations/v008/render-runs/run-001/asset-detail.png). |
| [Side table v008](../../art/room_side_table/iterations/v008/evaluation.json) | 20 × 20 × 17.02 raw; 4 meshes, 10,040 triangles; Godot import passed. Runtime fitting normalizes depth to 17 inches. | Joined top boards and calmer grain improve on v007, but the legs remain mostly straight and the apron is plain against the turned-leg target. Best current becomes v008; strict visual gates fail. [Target](../../art/room_side_table/visual_director/round-03/approved-target-r03.png), [three-quarter](../../art/room_side_table/iterations/v008/render-runs/run-001/asset-three-quarter.png), [detail](../../art/room_side_table/iterations/v008/render-runs/run-001/asset-detail.png). |

All five candidates fail neutral-viewer realism and close-inspection gates. Hardware, edge treatment, fitted joints, material response, surface variation and manufacturing detail remain incomplete. The episodes are exhausted at three strategies and backlogged; no candidate is promoted. The canonical production registry remains at 15 IDs.

## Integrated Room A/B comparison

The Room B review render loaded workbench v009, assembly table v008, wardrobe v008 and floor cabinet v008 together. The Room A review render loaded side table v008. Review-room JSON copies add only the candidate semantic appearance IDs to the authoritative RoomDefinitions; dimensions, placements, navigation, collision, citizen behavior and gameplay geometry were not changed.

Compared with Batch 10's overview captures, the broad timber waves are less prominent and the joined tops read as separate boards at closer furniture views. The 330-inch Room B overview and corresponding Room A overview still make the furniture small; they do not show a clear game-scale production-quality gain. This comparison is directional: the candidate framing is retained, but Batch 10 captures predate the Batch 12 lighting adjustment. The close and three-quarter captures provide stronger evidence for the specific surface and construction changes.

## Matched 50-citizen performance

Godot 4.7.2 GL Compatibility, NVIDIA RTX 5090, VSync disabled, 50 citizens and the same three camera views were measured in Rooms A and B. Baselines use the canonical production registry and original RoomDefinitions. Candidate runs use review-only registries containing the five challengers and review-room copies with unchanged geometry. Values are milliseconds for median/p95 frame time; draw calls and primitives are per-frame readings.

| Room | View | Baseline median / p95 ms | Candidate median / p95 ms | Draw calls, baseline → candidate | Primitives, baseline → candidate |
|---|---|---:|---:|---:|---:|
| B | Room | 2.048 / 2.139 | 2.029 / 2.143 | 980 → 918 | 541,960 → 570,598 |
| B | Settlement | 1.658 / 1.893 | 1.666 / 1.965 | 844 → 836 | 753,512 → 778,544 |
| B | Citizen | 2.341 / 2.841 | 2.020 / 2.851 | 1,118 → 1,097 | 815,572 → 846,350 |
| A | Room | 2.059 / 2.202 | 2.040 / 2.140 | 971 → 954 | 497,000 → 499,424 |
| A | Settlement | 1.853 / 1.940 | 1.844 / 2.019 | 1,058 → 1,058 | 771,854 → 771,854 |
| A | Citizen | 3.018 / 3.623 | 3.076 / 3.744 | 2,819 → 2,792 | 1,273,278 → 1,276,522 |

These single-session samples show no consistent frame-time regression. Candidate geometry adds about 0.5% of primitives in Room A and 3.3–5.3% across Room B views; draw-call counts are level or lower. P95 changes are small and mixed across views, so this is evidence of no measured material regression on this machine, not a broad performance guarantee. Raw JSON: [Room A baseline](batch-15-furniture/performance-room-a-baseline.json), [Room A review](batch-15-furniture/performance-room-a-candidate.json), [Room B baseline](batch-15-furniture/performance-room-b-baseline.json), [Room B review](batch-15-furniture/performance-room-b-candidate.json).

## Verification and next priority

The five Visual Director episodes are backlogged with best-current references preserved. Current bests are workbench v009, assembly table v008, wardrobe v008, floor cabinet v005 and side table v008. No production registry entry changed. The production inventory was refreshed after these state updates. The Art Factory integrity suite passed all 26 tests; both modified generator files passed Ruff and Python compilation.

The next ranked production target is the French-door opening. Its current round-02 episode is already exhausted; any further transfer needs a new, materially distinct hinge/material direction and room-context check, while keeping exterior greenery out of the door mesh. The current review inventory also continues to show the desk, room shell trim and faction identity as below-target work. This batch does not claim full-game art migration is complete.
