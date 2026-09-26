# RoomScale POC 1.5 Acceptance Status

Status: **PASS** (verified 2026-09-26)

The evidence below is from fresh Godot 4.7.2 processes running the production scene. The cross-room test ran Room A, then Room B, then Room A without source changes. Repeatability batches ran five fresh full scenarios per room and stopped on the first failure.

| Criterion | Status | Verification evidence |
| --- | --- | --- |
| AC-1 POC 1 regression | PASS | Room A full scenario in `verification/poc15/room_a/inspection-final.log`; M2-M6/M8 all pass. |
| AC-2 Builder cleanup | PASS | M4 evidence reports `builders_returned=true`; smoke asserts zero active builders, empty construction worker set, and no construction task remains on a citizen. |
| AC-3 Bounded task history | PASS | `verification/poc15/fast-locked-source.log`; canceled/superseded fixture remains at 500/500 after overflow. |
| AC-4 RoomDefinition exists | PASS | `scripts/room_definition.gd`, `rooms/room_a.json`, `rooms/room_b.json`; both load through the same parser. |
| AC-5 Room A migrated | PASS | Room A production log loads `room_a`, generates its objects and navigation from JSON, then completes M2-M6/M8. |
| AC-6 Geometry data driven | PASS | `pipeline_proof.gd` iterates object descriptors; both logs verify generated floor/object geometry. |
| AC-7 Obstacles data driven | PASS | Floor navigation reports 11 Room A and 12 Room B generated obstacle rectangles; smoke compares them with blocking objects. |
| AC-8 Elevated surfaces data driven | PASS | Generic `surface` records produce `STUDY_SURFACE` and `BENCH_SURFACE`; both targets are selected and explored. |
| AC-9 Generic surface goals | PASS | Runtime goal/task/navigation code uses region IDs and `target_surface_id`; source audit has no hard-coded DESK gameplay region. |
| AC-10 Dynamic investigation | PASS | M3 in both room logs: two citizens physically reach definition-derived approaches and confirm the missing connection. |
| AC-11 Dynamic construction site | PASS | M4 in both logs reports a derived reachable clear site: Room A `(2,0,-52)`, Room B `(12,0,-64)`. |
| AC-12 Dynamic traversal | PASS | M5 in both logs reports geometry-derived routes and target heights: Room A 79.2in to 30in; Room B 81.2in to 36in. |
| AC-13 Room B exists | PASS | `rooms/room_b.json` changes dimensions, target type/location/elevation, obstacles, furniture, and settlement positions. |
| AC-14 No Room B gameplay changes | PASS | `verification/poc15/cross-room-final/summary.md` is 3/3 A→B→A; no source changes between runs and no room-specific branch in gameplay systems. |
| AC-15 Room switching | PASS | `RUN_ROOM_SCALE.ps1 -Room room_a` and `-Room room_b`; test runner accepts the same room parameter. |
| AC-16 Validation | PASS | Fast log covers 12 malformed definitions: missing floor, unknown target, duplicate IDs, invalid bounds, outside approaches, unusable approaches, malformed dimensions/metadata. |
| AC-17 Room A complete loop | PASS | Room A M2-M6/M8 markers and nine visual phases in `verification/poc15/visual/room_a/`. |
| AC-18 Room B complete loop | PASS | Room B M2-M6/M8 markers and nine visual phases in `verification/poc15/visual/cross-room/step-02-room_b/`. |
| AC-19 Cross-room regression | PASS | `cross-room-final/summary.md`, 3/3 steps. |
| AC-20 Room A stability | PASS | `repeatability/room_a/summary.md`, 5/5; per-run logs `run-01.log` through `run-05.log`. |
| AC-21 Room B stability | PASS | `repeatability/room_b/summary.md`, 5/5; per-run logs `run-01.log` through `run-05.log`. |
| AC-22 Real movement | PASS | M5/M6 logs record 79.3in/81.3in continuous traversal with sampled maximum steps; smoke rejects discontinuities and teleport-sized jumps. |
| AC-23 Persistent infrastructure | PASS | M6 in both room logs reports `persistent_link=true`, three explorations, and two autonomous route reuses. |
| AC-24 Grapple presentation | PASS | M5 reports eight segmented cable pieces, radius 0.07in, and partial deployment; visual phases include grapple deployment. |
| AC-25 Citizen inspection | PASS | Smoke clicks a citizen marker and asserts identifier, TASK, and TARGET text; visual evidence includes `citizen-inspection`. |
| AC-26 Fast verification layer | PASS | `TEST_ROOM_SCALE_FAST.ps1` and `scripts/room_definition_test.gd`; fast log PASS. |
| AC-27 Repository documentation | PASS | `README.md`, copied plans under `docs/`, this matrix, and `PROJECT_PROGRESS.md`. |
| AC-28 Photo pipeline contract | PASS | `docs/RoomDefinition_Contract.md` defines scale, floor/walls, objects, obstacle footprints, elevated surfaces, approaches, provenance, and validation. |
| AC-29 Zero manual level authoring | PASS | Both rooms launch from JSON and code-generated geometry; no Godot editor steps are required. |

## Visual evidence

Each captured room has nine 1280x720 PNGs: `initial-room`, `citizen-inspection`, `living-civilization`, `target-investigation`, `resource-hauling`, `construction`, `grapple-deployment`, `citizen-traversal`, and `elevated-surface-exploration`. Room A is in `verification/poc15/visual/room_a/`; Room B is in `verification/poc15/visual/cross-room/step-02-room_b/`. Capture sidecar text files record room, phase, viewport, target region, and camera framing.

## Commands

```powershell
./TEST_ROOM_SCALE_FAST.ps1 -TimeoutSeconds 30
./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360
./TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 360
./TEST_ROOM_SCALE_CROSSROOM.ps1 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 18
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_a -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_b -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40
```
