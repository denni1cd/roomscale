# v089 final gameplay-smoke repair

The required final gameplay run exposed an integration regression that was not covered by the earlier `citizen-v087` smoke evidence.

## First exact-registry run

- Source revision under test: `333cee7e44e43662c8a095843b1a1a2e78d1b835`.
- Registry: `best-current-art-showcase-registry-v089.json`, SHA-256 recorded by the smoke runner, mode `review_showcase`.
- Room A completed the gameplay assertions for 50 citizens, navigation, 11 deliveries, construction, physical grapple traversal, and three exploration arrivals. This run was **not accepted as PASS** because Godot also emitted citizen presentation script errors.
- Godot emitted 1,764,984 repeated errors from invalid `MeshInstance3D` accesses after the adapter had replaced those legacy nodes with MPFB `Node3D` animation pivots. The 756,189,902-byte raw log was dominated by repeated per-frame copies of this error and is summarized here rather than retained as a giant artifact.
- The failure was an actual v089 gameplay-presentation compatibility regression. It was not a renderer or room-file prerequisite failure. The earlier CI run did not catch it because its suite did not launch the exact v089 review showcase.

## Bounded repair

`citizen_agent.gd` now keeps the Art Factory animation-pivot references as `Node3D`, matching the adapter contract and the MPFB rig. Per-citizen material tinting remains conditional on `Body` itself being a `MeshInstance3D`; skinned MPFB body containers retain their authored PBR materials. The generated citizen, strict visual evaluation, canonical registry, RoomDefinition, acceptance amendment, and gameplay geometry were not changed.

## Follow-up verification

The repair was exercised with the explicit `review_showcase` registry in all three required rooms. The corrected `citizen_agent.gd` has SHA-256 `7a7f47d50cdcfab0db7edb739c8304d60313795c4a089768c80a2534b62d2a82`; the final review commit contains those same bytes.

- Registry contract: PASS. All 50 citizens instantiated as `citizen-v089`; desk-v007 and grapple-v006 resolve from the review-only registry; resolver diagnostics are zero; no registered asset silently falls back; canonical `art/registry.json` is unchanged.
- Room A: PASS. 50 citizens, navigation, all 11 deliveries, construction, physical grapple climb, continued exploration, and no script or required-asset failures. See `room-a-v089-review-showcase.log`.
- Room B: PASS with the same required behavior. See `room-b-v089-review-showcase.log`.
- Reconstructed `room_photo_luna`: PASS with the same required behavior and instantiated desk-v007. The first log parser attempt used the wrong scene label (`desk` instead of `computer-desk`) and rejected an otherwise successful run. The assertion was corrected and the reconstructed smoke was rerun to PASS; see `reconstructed-room-v089-review-showcase.log`.

The aggregate results and registry hashes are recorded in `v089-showcase-smoke-summary.json`. The tests exercise functionality only; they do not change the strict visual result for citizen-v089 or promote any asset.
