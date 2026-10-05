# Milestone 9 — Documentation and Final Verification

Status: **PASS — AC-48 is resolved and the final architectural cleanup is complete. The fresh-context second-room candidate, canonical attempt 7, Room A, and Room B all pass their required validation/gameplay regressions; all 48 POC 2 criteria remain PASS.**

## Updated durable workflow

- `README.md` explains the photo → skill and multimodal AI → RoomDefinition → validation/repair workflow, points to attempt 7, and states the completed POC 2 gates.
- `docs/RoomDefinition_Contract.md` and `skills/roomscale-room-reconstruction/references/roomdefinition-contract.md` are byte-identical. They document schema-v2 appearance fields, current generic archetypes and compatibility aliases, opening behavior, and optional bounded `exterior_scene` data.
- `skills/roomscale-room-reconstruction/SKILL.md` follows the contract and tells reconstruction models to author exterior primitives only when the photos show them; it preserves the photo-evidence/uncertainty and no-manual-authoring requirements.
- `verification/poc2/acceptance-matrix.md` gives all 48 criteria a conservative status and separates tested, documented-only, partial, and visually limited evidence. The final current-skill fresh-Luna run is recorded under `fresh-luna-final/`.
- Milestone evidence includes M0–M8 status, candidate attempts, validation logs, full production logs, and screenshot notes. The final cleanup changed only generic rendering, RoomDefinition validation/tests, candidates, and documentation; gameplay behavior files were not changed.

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

## Architectural cleanup closure

- Cleanup started from current `main` at base commit `ec95e2d2661db8b11b804865ce9ffd894d511648` in the isolated worktree `C:\Users\Zero\.codex\worktrees\poc2-exterior-data\roomscale`.
- `scripts/pipeline_proof.gd` no longer creates outdoor geometry for every window. It renders only opening-relative `exterior_scene.elements` supplied in the RoomDefinition. Attempt 7 now carries the former canonical scene as generic box, sphere, and cylinder data; the fresh-context living-room candidate has no exterior data and its windows remain free of invented deck, rail, tree, and foliage.
- `scripts/room_definition.gd` validates the optional scene, a maximum of 64 elements, supported generic shapes, finite bounded offsets/extents, positive dimensions, cylinder proportions, and optional appearance data. The fast suite tests invalid inputs, no-scene windows, and a two-element explicit scene that produces exactly those two shapes at the declared positions.
- The audit generalized the former dragon-specific triptych/emblem geometry to palette-driven abstract art, retained the old names as generic compatibility aliases, removed undeclared collectibles from display cabinets, and made map/collectible palettes follow appearance data. Hammock, display-cabinet structure, boxed-collectible layout, stone fireplace, and octagonal table remain reusable semantic forms without room-ID or gameplay logic.
- Final fast suite: `verification/poc2/architecture-cleanup-fast-repair1.log` — PASS, Room A/B, 29 malformed-input cases, and `exterior_scene=verified`. The initial expectation error and its failed run remain preserved in `architecture-cleanup-fast.log`. Godot's headless renderer leak warnings appear after the pass marker and do not affect the wrapper's exit 0.
- Canonical attempt 7 validation/gameplay: `architecture-cleanup-canonical-validation.log` and `architecture-cleanup-canonical-gameplay.log` — both PASS; gameplay used `-TimeoutSeconds 360` and records M2–M6/M8.
- Fresh-context second-room validation/gameplay: `architecture-cleanup-secondary-validation.log` and `architecture-cleanup-secondary-gameplay.log` — both PASS; gameplay used `-TimeoutSeconds 360` and records M2–M6/M8.
- Room regressions: `architecture-cleanup-room-a-gameplay.log` and `architecture-cleanup-room-b-gameplay.log` — both exit 0 with M2–M6/M8 PASS markers under the 360-second cap.
- Fresh 1280×720 initial-room captures were produced with the canonical and secondary-room production runs, reviewed, and saved under `verification/poc2/architecture-cleanup-visual/`.
- The reconstruction skill validator and `git diff --check` pass. `verification/poc2/acceptance-matrix.md`, `README.md`, this status file, `docs/POC2_Improvements.md`, and `PROJECT_PROGRESS.md` record the final scope and evidence.

The fast test prints Godot RendererDummy RID/ObjectDB shutdown-leak warnings after the pass marker, but exits 0 and its wrapper checks the explicit PASS marker and failure/error patterns. They are recorded in the fast log and did not mask script errors or a failed test.
