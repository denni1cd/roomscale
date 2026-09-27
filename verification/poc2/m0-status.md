# POC 2 Milestone 0 — RoomDefinition Contract Gate

Status: **PASS**

## Contract and architecture

- `docs/RoomDefinition_Contract.md` documents schema version 1, inch units, X/Z floor plane and Y elevation, room bounds, significant object geometry, optional object rotation/navigation padding, elevated surfaces, target selection, room metadata, structural validation, navigation validation, and photo-pipeline expectations.
- `scripts/room_definition.gd` loads JSON definitions and validates their structure before production setup. `scripts/pipeline_proof.gd` loads the selected `rooms/<id>.json`, builds room geometry and furniture from the definition, validates derived navigation, then initializes the shared simulation.
- `scripts/floor_navigation.gd` creates obstacle footprints from each object's `blocks_navigation`, `position`, `dimensions`, `navigation_padding`, and rotation. `scripts/surface_navigation.gd` discovers elevated regions and derives reachable approaches and construction sites from their geometry. `scripts/task_coordinator.gd`, `scripts/construction_system.gd`, and `scripts/citizen_agent.gd` use region IDs, surface geometry, and derived routes; no room ID, target region name, Desk/Workbench label, or canonical-photo coordinate branch was found in the production gameplay source.
- `scripts/pipeline_proof.gd` has a default launch choice of `room_a` when `ROOMSCALE_ROOM` is unset. The selected room is otherwise loaded by filename. Its renderer uses generic `kind` archetypes; the `workbench` archetype adds generic vise/tool-rail details.
- At the M0 gate, the contract did not yet enumerate all renderer appearance data. M2 later closed that gap with the v2 object appearance, room shell, opening, ceiling, crown, and archetype contract; see `verification/poc2/m2-status.md` and the current `docs/RoomDefinition_Contract.md`.

## Fresh runtime evidence

All commands were run from the repository root using Godot `4.7.2.stable.official.ed1daf0bf` and the current production scene/test harness:

| Check | Result | Evidence |
| --- | --- | --- |
| Fast parse, malformed-definition, obstacle/target/approach/site derivation, navigation, and bounded task-history preflight | PASS | `verification/poc2-preflight-fast.log` (root-run before implementation) |
| Full production scenario, Room A | PASS | `./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360 -LogPath verification/poc2/m0-room-a-full.log` |
| Full production scenario, Room B | PASS | `./TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 360 -LogPath verification/poc2/m0-room-b-full.log` |

Both original fresh logs contain `ROOMSCALE_M2_SMOKE_PASS`, `ROOMSCALE_M3_SMOKE_PASS`, `ROOMSCALE_M4_SMOKE_PASS`, `ROOMSCALE_M5_SMOKE_PASS`, `ROOMSCALE_M6_SMOKE_PASS`, and `ROOMSCALE_M8_SMOKE_PASS`. After later M4/M6 harness changes, the full regression was rerun in `verification/poc2/final-room-a-full.log` and `verification/poc2/final-room-b-full.log`; both contain the same pass markers. These cover 50-citizen initialization, navigation around room-derived obstacles, investigation of each room's elevated goal, all 11 material deliveries, construction, continuous climbing, elevated exploration, autonomous route reuse, and the existing presentation assertions.

## Gate decision

RoomDefinition is a real versioned input boundary, structural and navigation validation execute before population setup, and both existing room definitions pass complete fresh production scenarios through the same gameplay systems. POC 2 may proceed to M1. The appearance-field documentation gap is tracked above for resolution before the reconstruction skill treats the contract as exact.
