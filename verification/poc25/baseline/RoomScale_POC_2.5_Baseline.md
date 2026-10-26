# RoomScale POC 2.5 Baseline

Captured before POC 2.5 implementation writes.

## Repository state

- Baseline commit: `1d7388f` (`Merge pull request #11 ...`), same as `origin/main`.
- Branch: `main`.
- Working tree already contained unrelated edits and untracked work before this baseline. Preserved modified files: `README.md`, `RUN_ROOM_SCALE.ps1`, `TEST_ROOM_SCALE.ps1`, `scripts/citizen_agent.gd`, `scripts/civilization_presentation.gd`, `scripts/construction_system.gd`, `scripts/pipeline_proof.gd`, `scripts/poc56_renderer_evidence.gd`, `scripts/setup_menu.gd`, `scripts/smoke_test.gd`, `scripts/surface_navigation.gd`, `scripts/task_coordinator.gd`, `verification/milestone8-launch-startup.log`, and `verification/milestone8-launch-startup.png`. A pre-existing deletion is `verification/poc3/aphrael-session.json`. The tree also contained pre-existing untracked POC 3/5 artifacts; none were removed or rewritten.
- `pipeline_proof.gd` had a pre-existing graphical-launch change that redirects to the setup menu whenever `ROOMSCALE_NO_MENU` is unset, even when a room is selected. The canonical graphical smoke command therefore stopped before production-scene initialization (`requested=clockwork definition={}`). The graphical evidence capture below set `ROOMSCALE_NO_MENU=1` to exercise the selected RoomDefinition in the production scene. The source change remains untouched.

## Baseline gates

| Gate | Result | Evidence |
|---|---|---|
| Existing deterministic fast suite (`TEST_ROOM_SCALE.ps1 -Mode Fast`) | PASS; includes Ruff, 14 Python unit tests, and current fast Godot/regression gates | `fast/` |
| Room A / Room B / Room A regression | PASS, 3/3 | `cross-room/summary.md` and per-room logs |
| Canonical RoomDefinition validation (`attempt-7/room_photo_luna.json`) | PASS; schema v2, 11 obstacles, 3 reachable target approaches, valid construction site, runtime navigation | `canonical-validation.log` |
| Canonical headless production smoke | PASS; M2–M8, 50 citizens, construction, deployment, traversal, and citizen activity | `canonical-headless-smoke.log` |
| Existing visual resolver, asset validation, and civilization presentation gates | PASS | `visual-tests/` |
| Canonical graphical smoke through the unmodified standard wrapper | PRE-EXISTING FAILURE; setup-menu redirect prevented production scene initialization | `canonical-visual-menu-conflict.log` |

The only observed failure in these baseline gates was the pre-existing graphical-launch redirect described above. The smoke run with `ROOMSCALE_NO_MENU=1` passed and produced standard production-path captures.

## Render evidence and observations

Godot 4.7.2, Compatibility renderer, 1280×720 captures. The initial, living-civilization, and settlement-scale renders are in `canonical-visuals/`.

- **Room scale:** the reconstructed room is recognizable, but the shell and many objects use broad flat surfaces and low-detail shapes. The production desk resolves to `res://assets/generated/writing_desk.glb`; it is the existing candidate, not proof of POC 2.5 quality.
- **Settlement scale:** huts, the work area, and construction presentation are visible, but the structures read as simple primitive assemblies. The close render includes an oversized green glowing patch.
- **Citizen scale:** the first canonical close capture (`room_photo_luna-citizen-close.png`) does not show its selected citizen. The selected Citizen01 was assigned workshop maintenance at approximately `(-34.8, 0, 4.8)`, inside the workshop foundation footprint (26×18 inches, centered at `(-42, 0, 5)`, with its top at 1 inch). This is an existing visual-occlusion condition, not an Art Factory result. The production scene was then captured without moving or pausing any citizen, using visible Citizen10 while it naturally travelled in open floor space; `room_photo_luna-citizen-close-visible.png` is the usable close-scale baseline. It shows the current small, block-and-cylinder figure and gives a genuine production-render comparison target.
- **Performance snapshot:** captured close citizen evidence reports 276 draw calls and 153,672 primitives; settlement-close evidence reports 1,476 draw calls and 659,166 primitives; FPS in those frames was 56. These are baseline observations, not performance acceptance claims.

## Evidence layout

- `canonical-visuals/`: production-path room, civilization, settlement, obstructed citizen, and visible citizen renders plus per-image metadata.
- `fast/`: deterministic baseline suite output.
- `cross-room/`: Room A / Room B / Room A output.
- `visual-tests/`: existing resolver and presentation test output.
- `canonical-validation.log`, `canonical-headless-smoke.log`, and graphical-smoke logs: canonical-room gates.
