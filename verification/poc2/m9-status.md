# Milestone 9 — Documentation and Final Verification

Status: **PASS for repository instructions and final verification artifacts; overall POC is not declared complete because acceptance limitations and the Aphrael Work handoff remain open.**

## Updated durable workflow

- `README.md` now explains the photo → numbered candidate → validator → AI repair → full production run workflow, gives the canonical accepted candidate path, and states the candidate path/filename rules.
- `docs/RoomDefinition_Contract.md` and `skills/roomscale-room-reconstruction/references/roomdefinition-contract.md` now agree on schema-v2 fields, the 1-inch interior floor-edge clearance, the optional `[x,y,z]` nonnegative navigation-padding vector and default, and spawn center/footprint shape.
- `skills/roomscale-room-reconstruction/SKILL.md` points the reconstruction model to those placement rules and preserves the photo-evidence/uncertainty and no-manual-authoring requirements.
- `verification/poc2/acceptance-matrix.md` gives all 48 criteria a conservative status and separates tested, documented-only, partial, and visually limited evidence. The final current-skill fresh-Luna run is recorded under `fresh-luna-final/`.
- Milestone evidence includes M0–M8 status, candidate attempts, validation logs, full production logs, and screenshot notes. Root review is complete. The Aphrael Work request remains pending, and no Aphrael implementation result is claimed.

## Final verification

- README relative Markdown targets resolve, including the POC 2 acceptance matrix.
- Skill package quick validation: `python C:\Users\Zero\.codex\skills\.system\skill-creator\scripts\quick_validate.py skills\roomscale-room-reconstruction` — PASS.
- PowerShell parser check for `TEST_ROOM_SCALE.ps1` and `TEST_ROOM_SCALE_FAST.ps1` — PASS.
- Godot `--check-only` passes for `scripts/smoke_test.gd` and `scripts/citizen_agent.gd`.
- Final fast test: `verification/poc2/m6-snapshot-fast-final-verified.log` — PASS, 26 malformed-input cases, Room A/B, schema-v2 renderer/navigation fixtures, and 500/500 bounded history.
- Canonical final structural/runtime-navigation validator: `verification/poc2/canonical-primary-final-validation.log` — PASS, six obstacles, three reachable target approaches, valid derived construction site.
- Final canonical full production run: `verification/poc2/canonical-primary-full-final.log` — PASS, measured wall time 289.91 seconds under the 1200-second recorded cap. The README's 360-second candidate-test limit is above this observed wall time.
- Final Room A and Room B full runs: `verification/poc2/final-room-a-full.log` and `verification/poc2/final-room-b-full.log` — both M2–M6/M8 PASS; Room B wrapper wall time is recorded as 256.38 seconds.
- Final current-skill fresh-Luna check: `verification/poc2/fresh-luna-final/final-report.md` — two-photo input, no supplied scale, and structural/runtime-navigation PASS after one preserved validator-directed repair. The one-photo check in `ac8-photo-request-test/` found approximation sufficient and did not request another view, so AC-8 remains documented-only.
- Clean-clone trial at commit `fba6d6a`: the documented setup installed Godot 4.7.2; the fast suite passed (`clean-clone-fast.log`), and the fresh two-photo candidate passed the cloned validator (`clean-clone-two-photo-validation.log`). The clone used the canonical room photos, so AC-48 remains partial pending a different-room trial.

The fast test prints Godot RendererDummy RID/ObjectDB shutdown-leak warnings after the pass marker, but exits 0 and its wrapper checks the explicit PASS marker and failure/error patterns. They are recorded in the fast log and did not mask script errors or a failed test.
