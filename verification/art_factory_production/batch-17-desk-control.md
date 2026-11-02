# Batch 17 — Desk Material and Reflection Control

## Scope

Reassess the approved desk r01 target after the updated room lighting and the failed v059–v061 material attempts. No new visual target or 3D candidate was created. The r01 episode remains capped at three strategies.

The approved target remains [incumbent-edit-r01.png](../../art/desk/visual_director/round-01/incumbent-edit-r01.png), SHA-256 4a84c2e1f348f051cc634a90271d65c8e5d18bfbb3046b226691af40d79f4fef; its pixel approval was recorded by Luna. The current renders were directly inspected by Codex and are not attributed to Luna.

## Matched production renders

desk-v007 run-004 and desk-v061 run-002 used Godot 4.7.2, GL Compatibility, the same room_photo_luna RoomDefinition, current project lighting, 1280×720 output, 50 citizens, and the same production camera positions and angles. The 330-inch room view reports the same camera position for both runs; the asset three-quarter, opposite, profile, and detail views also use identical camera transforms.

- [v007 room overview](../../art/desk/iterations/v007/render-runs/run-004/room-scale.png), [three-quarter](../../art/desk/iterations/v007/render-runs/run-004/asset-three-quarter.png), [detail](../../art/desk/iterations/v007/render-runs/run-004/asset-detail.png)
- [v061 room overview](../../art/desk/iterations/v061/render-runs/run-002/room-scale.png), [three-quarter](../../art/desk/iterations/v061/render-runs/run-002/asset-three-quarter.png), [detail](../../art/desk/iterations/v061/render-runs/run-002/asset-detail.png)

The current v061 close renders show a stronger broad reflection and more readable rail, column stages, saddles, and feet than v007. At the 330-inch overview, the improvement remains modest; it does not create an obvious room-wide quality transformation.

The separate 50-citizen whole-scene review remains prototype-heavy: the cutaway room has broad green wall surfaces, a plain floor, sparse low-detail furnishings, and visible exterior staging. It does not show a whole-room visual transformation. See the [room-scale showcase capture](batch-17/room-photo-luna/room-scale.png) and [capture receipt](batch-17/room-photo-luna/receipt.json).

## Effective material and probe control

A Godot diagnostic instantiates v007, v061, and a copy of v061 with only its ReflectionProbe removed, then records each MeshInstance3D.get_active_material(surface) value. The raw report is [desk-material-effective-values.json](batch-17/desk-material-effective-values.json); the reproducible diagnostic is [desk-material-diagnostic.gd](batch-17/desk-material-diagnostic.gd).

| Candidate | Meshes | Reflection probes | Effective glass values |
|---|---:|---:|---|
| v007 | 19 | 0 | RGBA 0.188/0.227/0.239/0.58; alpha transparency; metallic 0.08; roughness 0.08; rim 0.38; clearcoat 0.98 |
| v061 | 22 | 1 | Same effective glass values |
| v061 no-probe control | 22 | 0 | Same effective glass values |

Godot confirmed the v061 wrapper assigns smoked glass to the desktop, graphite to the frame, satin steel to fasteners, and rubber to pads/levelers. Removing only the probe from v061 leaves those material values, geometry, room, camera, and lights unchanged. The resulting [no-probe three-quarter](batch-17/desk-v061-no-probe/asset-three-quarter.png) and [detail](batch-17/desk-v061-no-probe/asset-detail.png) views lose the broad reflections and reveal the wall/floor through the top. This isolates the probe as the source of most of the new reflection response.

## 50-citizen performance

Godot 4.7.2, NVIDIA RTX 5090, GL Compatibility, VSync disabled; same reconstructed room, 50 citizens, and warmed 8-second sampling windows. These are single-session measurements.

| View | v007 median / p95 ms | v061 with probe | v061 no-probe |
|---|---:|---:|---:|
| Room | 2.970 / 3.610 | 3.484 / 4.136 | 2.953 / 3.534 |
| Settlement | 2.600 / 3.133 | 2.625 / 3.057 | 2.625 / 3.165 |
| Citizen | 2.463 / 3.107 | 2.467 / 2.966 | 2.489 / 3.116 |

The probe adds approximately 0.53 ms to the room-view median and 0.60 ms to p95 versus the no-probe control in this sample. The settlement and citizen samples remain close. Raw results: [v007](batch-17/performance-v007.json), [v061](batch-17/performance-v061.json), [v061 without probe](batch-17/performance-v061-no-probe.json). This does not establish a broad performance guarantee.

## Evaluation and disposition

The latest evaluation now records v061 as **better than v007 and the best current 3D review candidate**. It still fails the source-character and strict craftsmanship gates: the top reads too green and transparent compared with the source photo and approved target, and its glass edge highlight remains too dark. The prior run-001 evaluation is preserved as [evaluation-run-001.json](../../art/desk/iterations/v061/evaluation-run-001.json).

- Production asset remains desk-v007.
- No canonical registry change or promotion; 15 entries remain.
- No RoomDefinition placement, dimensions, navigation, surface anchor, or gameplay geometry changed.
- The r01 episode remains backlogged after three strategies. Move to room-shell trim; revisit desk only under a newly approved Visual Director target and a materially different source-conditioned strategy.

The current inventory still covers 95 visible-art classes, 21 RoomDefinitions, and 318 room-object records. Full visual migration remains incomplete.
