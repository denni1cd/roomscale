# RoomScale

RoomScale is a small 3D civilization simulation where half-inch citizens treat a human room as a landscape. Furniture blocks floor movement; citizens investigate elevated surfaces, carry materials, build a grappling route, climb it, and explore the newly reachable area.

## Current status

POC 1.5 is complete and verified. Room A and Room B each pass the complete production scenario through the same gameplay systems; the required A → B → A sequence and five-run-per-room stability gates are recorded in [the acceptance matrix](docs/POC_1.5_ACCEPTANCE.md).

POC 2 is complete: its final architectural cleanup and required regression suite have passed. The packaged photo-to-RoomDefinition skill is in `skills/roomscale-room-reconstruction/`; the accepted canonical photo candidate is `verification/poc2/candidates/primary/attempt-7/room_photo_luna.json`, with attempt history, validation/gameplay logs, captures, and per-criterion status under `verification/poc2/`. AC-48 fresh-context different-room evidence also passes. POC 2 was marked complete only after these final checks passed; see [the acceptance matrix](verification/poc2/acceptance-matrix.md) and [milestone 9 status](verification/poc2/m9-status.md) for the evidence. The user accepts attempt 7 for current tests; closer visual resemblance is deferred graphics work.

## Setup and launch

The PowerShell setup script checks for Godot 4.7.2 standard Windows x86-64 and downloads it into the ignored `.tools/` folder when needed. No API key or Godot editor authoring is required.

```powershell
./SETUP_ROOM_SCALE.ps1
./RUN_ROOM_SCALE.ps1 -Room room_a
./RUN_ROOM_SCALE.ps1 -Room room_b
# Any safe room ID in rooms/, or a project-local RoomDefinition JSON file
./RUN_ROOM_SCALE.ps1 -Room verification/poc2/candidates/candidate_room.json
```

Room selection is a launch parameter; gameplay source files do not need edits between rooms. An explicit JSON path must be inside the project directory, and its filename without `.json` must match the definition's `id`.

## Reconstruct a room from photos

1. Give the ordinary room photographs to an AI session with `skills/roomscale-room-reconstruction/SKILL.md` and its referenced contract, evidence, and validation guides. No fixed photo count or known measurement is required.
2. Have the AI save a complete RoomDefinition JSON and a short evidence/uncertainty note as a new numbered candidate under `verification/poc2/candidates/`. Preserve each failed candidate and its validator log unchanged.
3. Validate the exact candidate file, then return any diagnostics to the same reconstruction AI for a minimal repair in a new attempt:

   ```powershell
   ./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/candidate_room.json -LogPath verification/poc2/candidates/candidate_room-validation.log
   ```

4. After structural and runtime-navigation validation passes, run the full production scenario with that same JSON file:

   ```powershell
   ./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/candidate_room.json -TimeoutSeconds 360 -LogPath verification/poc2/candidates/candidate_room-gameplay.log
   ```

   The path must stay inside the repository, and the filename stem must match the RoomDefinition `id`. A successful gameplay log includes M2–M6 and M8 markers; screenshots require the optional `-CaptureVisuals` flag.

Room placement data has a one-inch interior floor-edge clearance. Optional object `navigation_padding` is a nonnegative `[x,y,z]` vector, default `[0,0,0]`; X/Z expand the local horizontal footprint before rotation, while Y is ignored by 2D navigation. Spawn data has a 3D `center` and a three-number `dimensions` value with positive X/Z footprint sizes, conventionally `[width,0,depth]`.

## Controls

- Click the highlighted elevated surface, then choose **Reach / Explore** or press Enter.
- Click a citizen to inspect its identifier, state, current task, and destination/target.
- `1`, `2`, `3` switch between room, settlement, and citizen views.
- `WASD` or arrow keys pan; right mouse drag orbits; middle mouse drag pans; the wheel zooms; `Q`/`E` changes camera height.
- `F12` captures the current view into `verification/`.

## Verification

```powershell
# Fast deterministic room, navigation, geometry, and task-cleanup checks
./TEST_ROOM_SCALE_FAST.ps1 -TimeoutSeconds 30

# Structural plus derived-navigation validation before a candidate is integrated
./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/candidate_room.json

# Complete fresh-process integration scenario for either room
./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360
./TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 360
# Production gameplay for an arbitrary project-local candidate
./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/candidate_room.json -TimeoutSeconds 360

# Current canonical photo-based candidate (validation and gameplay evidence)
./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-7/room_photo_luna.json
./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-7/room_photo_luna.json -TimeoutSeconds 360

# Required no-source-change cross-room sequence
./TEST_ROOM_SCALE_CROSSROOM.ps1 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 18

# Five consecutive full runs for each definition (at most 40 minutes per batch)
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_a -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_b -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40

# Capture production viewport images at scenario milestones
./TEST_ROOM_SCALE.ps1 -Room room_a -CaptureVisuals -VisualDirectory verification/poc15/visual/room_a
```

The integration runner rejects missing M2–M6/M8 pass markers, script errors, assertion failures, and timeouts. Each POC 1.5 run has its own log under `verification/poc15/`; POC 2 candidate and regression evidence is kept under `verification/poc2/`.

## Architecture

Each `rooms/*.json` file is the room-specific input. `RoomDefinition` parses and validates the file before the population starts. The production scene generates room objects and floor geometry from that definition; floor navigation builds obstacle footprints from blocking objects; surface navigation registers generic navigable regions and derives investigation points and a construction site. The same task, citizen, delivery, construction, traversal, and exploration systems consume either room.

Room-specific coordinates belong in the selected data file. Gameplay code uses surface and region identifiers such as `STUDY_SURFACE` and `BENCH_SURFACE`; semantic names such as Desk and Workbench are presentation labels. See [the RoomDefinition contract](docs/RoomDefinition_Contract.md) before adding a room, and the copied [POC 1 plan](docs/RoomScale_POC_1_Project_Plan.md) and [POC 1.5 plan](docs/RoomScale_POC_1.5_Project_Plan.md) for scope and acceptance requirements.

## Repository map

- `rooms/` — authoritative room inputs.
- `scripts/` — runtime systems and deterministic integration/fast tests.
- `docs/` — project plans, RoomDefinition/photo-pipeline contract, and acceptance evidence.
- `screenshots/` — final Room A and Room B production captures, indexed by scenario phase.
- `verification/` — retained POC 1/1.5 evidence plus POC 2 candidates, validation logs, full gameplay runs, acceptance status, and visual captures.
