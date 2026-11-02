# Batch 13 — Room Photo Trim Profile Transfer

## Direction and scope

The source photo shows dark stained residential molding against green walls and muted carpet. The representative open-top gameplay camera does not expose the ceiling, so this batch focused on the visible baseboard and crown trim. The approved Visual Director target is [trim-direction-d-edit01](../../art/room_shell_trim/visual_director/round-01/approved-target-r01.png); concept review and the schematic profile reference are recorded in [Visual Director Round 01](../../art/room_shell_trim/visual_director/round-01/visual-development.md).

The trim remains presentation-only. Candidate room files add only the `room_shell_trim` asset ID to the baseboard and crown appearance records. RoomDefinition dimensions, wall/opening geometry, object placement, collision, navigation, and gameplay data remain unchanged. The 48 x 5 x 1.4-inch ArtBrief sample is a candidate envelope, not a room dimension.

## Art Factory attempts

| Candidate | Production finding | Decision |
|---|---|---|
| v001 | The procedural wood albedo and normal response rendered as repeated warm bands over the profiles. The candidate retained the measured envelopes and validated at two meshes, two surfaces, and 92 triangles. | Continue; material and close-craft gates failed. |
| v002 | Removing the generated maps restored broad continuous brown faces. The smooth finish and remaining profile bands still missed the target's restrained grain and close-craft threshold. It is the best current review candidate. | Continue; no promotion. |
| v003 | The alternate low-frequency material and reduced contour were still banded in production closeups and did not improve on v002. It validated at two meshes, two surfaces, and 72 triangles. | Reject. |

The approved target episode used all three attempts and is now backlogged. The factory state preserves v002 as `best_3d_candidate`; there is no accepted trim production asset. The runtime default remains the existing RoomDefinition-driven cuboids. The [v001 evaluation](../../art/room_shell_trim/iterations/v001/evaluation.json), [v002 evaluation](../../art/room_shell_trim/iterations/v002/evaluation.json), and [v003 evaluation](../../art/room_shell_trim/iterations/v003/evaluation.json) preserve the pixel-based findings and transfer diagnoses.

Capture evidence includes the [v001 baseboard](../../art/room_shell_trim/iterations/v001/render-runs/run-005/baseboard-profile-detail.png) and [crown](../../art/room_shell_trim/iterations/v001/render-runs/run-005/crown-profile-detail.png), [v002 baseboard](../../art/room_shell_trim/iterations/v002/render-runs/run-001/baseboard-profile-detail.png) and [crown](../../art/room_shell_trim/iterations/v002/render-runs/run-001/crown-profile-detail.png), and [v003 baseboard](../../art/room_shell_trim/iterations/v003/render-runs/run-001/baseboard-profile-detail.png) and [crown](../../art/room_shell_trim/iterations/v003/render-runs/run-001/crown-profile-detail.png). The matched whole-room captures show that the dark material reduces the original bright-orange perimeter line, but the visible change remains small at gameplay distance.

## Runtime integration and validation

- Added a shared extruded profile helper for baseboard and crown. `RoomDefinition` continues to supply wall segments, heights, and openings; the profile does not alter gameplay extents.
- The Art Factory harness now focuses the custom profile captures at the measured room-side center of each section and uses an unobstructed south-wall position. Earlier misframed/occluded captures remain in candidate history; run-005 supplied the v001 evaluation evidence.
- Updated the performance harness to accept a review RoomDefinition file so the baseline and review-only candidate can use the same photo room and normal 50-citizen population.
- Godot 4.7.2 GL Compatibility technical validation passed for v001, v002, and v003. The v001-v003 render receipts each record 50 citizens.
- `python scripts/test_art_factory.py` passed: **25 tests**.
- Production inventory refreshed: 21 RoomDefinition files, 318 room records, 95 visible-art classes, 15 canonical registry entries, and 93 runtime geometry builder sites across 13 scripts.

## 50-citizen performance

The benchmark compared the default photo-room definition with a review-only copy adding the trim asset ID, on the same RTX 5090, Godot version, renderer, and views. These are machine-specific snapshots; they do not show a consistent regression or a general performance gain.

| View | Baseline FPS / median / p95 ms | v002 review FPS / median / p95 ms | Draw calls | Primitives |
|---|---:|---:|---:|---:|
| Room | 333.20 / 2.975 / 3.534 | 337.31 / 2.940 / 3.444 | 1244 / 1244 | 660,133 / 660,441 |
| Settlement | 378.24 / 2.612 / 3.165 | 370.86 / 2.644 / 3.206 | 1381 / 1381 | 851,330 / 851,774 |
| Citizen | 386.07 / 2.543 / 3.178 | 385.29 / 2.508 / 3.183 | 916 / 872 | 829,820 / 813,516 |

The raw captures are [baseline](batch-13-room-shell/performance-baseline.json) and [review candidate](batch-13-room-shell/performance-candidate.json).

## Backlog

Batch 13 produced no canonical registry promotion, so the registry remains at 15 entries. The highest next priority is the approved Tier 1 Room A household bookcase, whose first generation was blocked before Blender launched because the Art Factory process lacked `ROOMSCALE_BLENDER_EXECUTABLE`. Preserve that attempt and its target; continue only if the dependency can be resolved without inventing render evidence or resetting attempt history. The ceiling remains deferred because the current gameplay cutaway hides it.

This batch does not complete the RoomScale visual migration. The [production backlog](production-art-backlog.md) retains unresolved furniture, openings, faction visuals, room shell, and runtime-generated art.
