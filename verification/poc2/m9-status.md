# Milestone 9 — Documentation and Final Verification

Status: **PASS — AC-48 is resolved. A fresh-context candidate authored from the cloned reconstruction skill/references and four photos passes structural/runtime-navigation validation and full M2–M6/M8 gameplay; its evidence and clone provenance are saved under `verification/poc2/candidates/secondary-room/fresh-context/`.**

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
- Final current-skill fresh-Luna check: `verification/poc2/fresh-luna-final/final-report.md` — two-photo input, no supplied scale, and structural/runtime-navigation PASS after one preserved validator-directed repair. The one-photo check in `ac8-photo-request-test/` found approximation sufficient; the second-room review separately identified a specific optional reverse view, satisfying AC-8 without making another photo a blocker.
- Clean-clone trial at commit `fba6d6a`: the documented setup installed Godot 4.7.2; the fast suite passed (`clean-clone-fast.log`), and the fresh two-photo candidate passed the cloned validator (`clean-clone-two-photo-validation.log`). It used canonical-room photos.
- Earlier different-room clean-clone trial at short commit `2dda51b`: validation and the full gameplay harness passed, and the original evidence remains in `clean-clone-secondary-room/`. That run used a continuing-context candidate, so it did not satisfy AC-48 fresh-context authorship at the time.
- AC-48 fresh-context run: clone `C:\Users\Zero\AppData\Local\Temp\roomscale-ac48-fresh-context-20260928`, commit `2dda51b979850794a5f1d292705d37bb51756b02`, with empty status before adding the four photos. The new candidate was authored from the cloned README, skill and references, contract, and photos. Attempt 1 passed validation (7 obstacles, 4 reachable approaches, valid derived site); the 360-second production run exited 0 with M2–M6/M8 PASS markers. Candidate, note, attempt, validator logs, gameplay log, and provenance are saved in `verification/poc2/candidates/secondary-room/fresh-context/`; no renderer or gameplay source changed.

The fast test prints Godot RendererDummy RID/ObjectDB shutdown-leak warnings after the pass marker, but exits 0 and its wrapper checks the explicit PASS marker and failure/error patterns. They are recorded in the fast log and did not mask script errors or a failed test.
