# RoomScale

RoomScale is a small 3D civilization simulation where half-inch citizens treat a human room as a landscape. Furniture blocks floor movement; citizens investigate elevated surfaces, carry materials, build a grappling route, climb it, and explore the newly reachable area.

## Current status

POC 4.7.1 validates and hardens founding with deterministic layout/resource variants,
continuous production invariants and fresh long soaks on
`codex/roomscale-poc471-founder-stress`. See the
[robustness harness guide](docs/POC471_ROBUSTNESS.md) and
[campaign report](verification/poc471/final-report.md).

POC 4.7 adds **five founders, no prebuilt settlement and 1x startup** on
`codex/roomscale-poc47-founder-start`. Citizens autonomously salvage, haul and build
shelter, storage, a workshop and housing; supported growth adds one real citizen at
a time. A completed workshop gates advanced traversal. See the
[founder guide](docs/POC47_FOUNDERS.md) and
[verification report](verification/poc47/final-report.md).

Historical POC 4.6 added a spectator view on `codex/roomscale-poc46-spectator-ui`:
**10x fishbowl startup**, compact vital signs, real event cards, contextual project
progress, camera titles/worker close-ups, quiet HUD fading and five distinct
cohort arrival points. **F3 / Details** opens diagnostics. See the
[spectator guide](docs/POC46_SPECTATOR.md) and
[POC 4.6 verification](verification/poc46/final-report.md).

POC 4.5 is **PASS** on `codex/roomscale-poc45-fishbowl`: all 55 criteria,
three consecutive fresh full runs, sixty-day stability and 120 real citizens.
Launch `./RUN_ROOM_SCALE_FISHBOWL.ps1 -Room room_poc45` and watch the governor, real salvage,
traversal, settlement construction and five-citizen cohorts operate without input.
See [the fishbowl guide](docs/POC45_FISHBOWL.md) and
[verification](verification/poc45/final-report.md). Ordinary launch remains manual.

POC 4 is **PASS**: 50 citizens maintain food, water and rest needs; civilization
priorities and salvage authorization drive real resource hauling, construction,
and access to elevated water. All 45 criteria, five consecutive complete scenarios,
seven days after recovery, and thirty days of stability passed. See the
[final report](verification/poc4/final-report.md),
[acceptance matrix](verification/poc4/acceptance.md), and
[gameplay guide](docs/POC4_GAMEPLAY.md).

POC 3 visual work is on `codex/roomscale-poc3-visual-fidelity`: semantic visual
resolution, generated GLB desk, detailed furniture, shared materials, clockwork
citizens/settlement, task-driven resource props, staged grapple machinery, and
attachment-before-navigation deployment. See [the visual workflow](docs/POC3_VISUALS.md)
and [current acceptance status](verification/poc3/acceptance.md). POC 3 visual
completion still requires the plan's human review; functional results alone
do not satisfy its presentation gate.

The refinement pass connects settlement districts with plank streets, utilities,
lanterns and working yards; adds mundane scale references; softens the floor;
and improves task poses and capture framing. Normal viewing now uses a compact
HUD; **F3** toggles the retained diagnostics. See the [refinement review](verification/poc3/refinement/review.md).

The [final polish review](verification/poc3/refinement/final-polish/review.md)
covers builder contact, utility routing, subtle floor wear and the latest captures.

POC 1.5 is complete and verified. Room A and Room B each pass the complete production scenario through the same gameplay systems; the required A → B → A sequence and five-run-per-room stability gates are recorded in [the acceptance matrix](docs/POC_1.5_ACCEPTANCE.md).

POC 2 adds a portable photo-to-RoomDefinition workflow. The packaged reconstruction skill is in `skills/roomscale-room-reconstruction/`; the current canonical photo candidate, attempt history, logs, captures, and per-criterion status are under `verification/poc2/`. The user accepts primary attempt 7 for current tests; closer visual resemblance is deferred graphics work. See [the POC 2 acceptance matrix](verification/poc2/acceptance-matrix.md) for the remaining fresh-AI different-room authoring evidence.

## Setup and launch

The PowerShell setup script checks for Godot 4.7.2 standard Windows x86-64 and downloads it into the ignored `.tools/` folder when needed. No API key or Godot editor authoring is required.

```powershell
./SETUP_ROOM_SCALE.ps1
./RUN_ROOM_SCALE.ps1 # Default: POC 4 living economy
./RUN_ROOM_SCALE_FISHBOWL.ps1 # Five founders at 1x; no gameplay input needed
./RUN_ROOM_SCALE_FISHBOWL.ps1 -Room room_poc45 # Legacy established colony
./RUN_ROOM_SCALE_FISHBOWL.ps1 -ManualCamera
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

- In POC 4, set Survival/Resources/Construction priorities, issue **Secure Water**,
  select **Chair**, and choose **Authorize Salvage** when materials are missing.
  Citizens choose their own tasks. Watch reserves and project supply in the HUD.
- **Pause / 1x / 4x / 10x** control simulation time; **F3** toggles diagnostics.
- Click the highlighted elevated surface, then choose **Reach / Explore** or press Enter.
- Click a citizen to inspect its identifier, state, current task, and destination/target.
- `1`, `2`, `3` switch between room, settlement, and citizen views.
- `WASD` or arrow keys pan; right mouse drag orbits; middle mouse drag pans; the wheel zooms; `Q`/`E` changes camera height.
- `F12` captures the current view into `verification/`.

## Verification

```powershell
# Fast deterministic room, navigation, geometry, and task-cleanup checks
# POC 4 full gates; add -CaptureVisuals to a Sustained run for screenshots
./TEST_ROOM_SCALE_POC4.ps1 -Mode All
./TEST_ROOM_SCALE_POC471.ps1 -Mode Short
./TEST_ROOM_SCALE_POC471.ps1 -Mode Full -Count 60
./TEST_ROOM_SCALE_POC45.ps1 -Mode All
./TEST_ROOM_SCALE_POC45.ps1 -Mode Stability -CaptureVisuals
./TEST_ROOM_SCALE_POC4.ps1 -Mode Sustained -CaptureVisuals

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
