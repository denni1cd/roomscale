# RoomScale

RoomScale is a small 3D civilization simulation where half-inch citizens treat a human room as a landscape. Furniture blocks floor movement; citizens investigate elevated surfaces, carry materials, build a grappling route, climb it, and explore the newly reachable area.

## Current status

POC 1.5 is complete and verified. Room A and Room B each pass the complete production scenario through the same gameplay systems; the required A → B → A sequence and five-run-per-room stability gates are recorded in [the acceptance matrix](docs/POC_1.5_ACCEPTANCE.md).

## Setup and launch

The PowerShell setup script checks for Godot 4.7.2 standard Windows x86-64 and downloads it into the ignored `.tools/` folder when needed. No API key or Godot editor authoring is required.

```powershell
./SETUP_ROOM_SCALE.ps1
./RUN_ROOM_SCALE.ps1 -Room room_a
./RUN_ROOM_SCALE.ps1 -Room room_b
```

Room selection is a launch parameter; gameplay source files do not need edits between rooms.

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

# Complete fresh-process integration scenario for either room
./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360
./TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 360

# Required no-source-change cross-room sequence
./TEST_ROOM_SCALE_CROSSROOM.ps1 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 18

# Five consecutive full runs for each definition (at most 40 minutes per batch)
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_a -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40
./TEST_ROOM_SCALE_REPEATABILITY.ps1 -Room room_b -RunCount 5 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 40

# Capture production viewport images at scenario milestones
./TEST_ROOM_SCALE.ps1 -Room room_a -CaptureVisuals -VisualDirectory verification/poc15/visual/room_a
```

The integration runner rejects missing M2–M6/M8 pass markers, script errors, assertion failures, and timeouts. Every run has its own log under `verification/poc15/`.

## Architecture

Each `rooms/*.json` file is the room-specific input. `RoomDefinition` parses and validates the file before the population starts. The production scene generates room objects and floor geometry from that definition; floor navigation builds obstacle footprints from blocking objects; surface navigation registers generic navigable regions and derives investigation points and a construction site. The same task, citizen, delivery, construction, traversal, and exploration systems consume either room.

Room-specific coordinates belong in the selected data file. Gameplay code uses surface and region identifiers such as `STUDY_SURFACE` and `BENCH_SURFACE`; semantic names such as Desk and Workbench are presentation labels. See [the RoomDefinition contract](docs/RoomDefinition_Contract.md) before adding a room, and the copied [POC 1 plan](docs/RoomScale_POC_1_Project_Plan.md) and [POC 1.5 plan](docs/RoomScale_POC_1.5_Project_Plan.md) for scope and acceptance requirements.

## Repository map

- `rooms/` — authoritative room inputs.
- `scripts/` — runtime systems and deterministic integration/fast tests.
- `docs/` — project plans, RoomDefinition/photo-pipeline contract, and acceptance evidence.
- `screenshots/` — final Room A and Room B production captures, indexed by scenario phase.
- `verification/` — retained POC 1 history and POC 1.5 run logs, summaries, and visual captures.
