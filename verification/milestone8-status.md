# Milestone 8 — Presentation Pass

Status: **PASS**

## Presentation changes

- Added a procedural toothed gear at the workshop bench and animate its rotation in the production scene.
- Added a small GPU steam emitter over the workshop chimney and a softly pulsing warm boiler light.
- Reduced key, fill, ambient, and glow intensity to keep the wood, painted furniture, steam, and lamps readable without clipping the pale walls.
- Restyled the HUD with compact brass-trimmed panels, shortened status copy, and a smaller upper-left footprint so the room stays visible behind it.
- Added eased camera transitions for preset changes and camera movement; visible startup capture waits for a settled camera (with an 8-second upper bound).

## Verification

- `TEST_ROOM_SCALE.ps1 -TimeoutSeconds 300 -LogPath verification/milestone8-smoke.log` — M2 through M6 regressions and the M8 presentation assertions pass on Godot 4.7.2 standard Windows build.
- `RUN_ROOM_SCALE.ps1` — production user launch workflow returned successfully and captured the running production scene.
- `verification/milestone8-launch-startup.png` — inspected full-room composition with the updated HUD.
- `verification/milestone8-settlement-view.png` — inspected settled 132in settlement view. This preset intentionally crops to the active living-work area; the full-room capture is the broad layout evidence.
- Visible capture logs are preserved alongside each PNG; the headless smoke transcript is `verification/milestone8-smoke.log`.

## Scope

All planned milestones M0–M8 are complete. No M9 or other gameplay work is in scope. The user-provided `docs/history/poc1/poc_project_plan.md` remains untouched and untracked.
