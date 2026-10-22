# POC 5.6 Execution State

**Approved contract:** `CONTRACT APPROVED`, then explicitly approved by the user (“go for it!”)

**Implementation branch:** `codex/poc56-playtest-stabilization`

**Worktree:** `C:\Users\Zero\.codex\worktrees\poc56-stabilization\roomscale`

**Starting `main` SHA:** `b4a0f7579379aceb0fd0e33fa8d2087e10f63614`
**Current phase:** `DELIVERED` — the Rules Lawyer returned `COMPLETE`; PR [#11](https://github.com/denni1cd/roomscale/pull/11) is open; the required GitHub Actions Fast check passes; the branch remains unmerged.
**Selected pace:** `0.5x`, confirmed in a rendered live-feel probe after comparing it to the current 1x reference. Existing 1x remains the deterministic regression reference.

This file is the compact implementation scaffold and running evidence index. The attached POC 5.6 plan and the user-approved Execution Contract remain authoritative for scope and acceptance.

## Starting Boundary and Workflow

- Strategerium and its independent Rules Lawyer approved the product contract before the user approved implementation.
- The actual installed Adeptus Necroneerium skill was loaded and its current Adeptus mode is in use.
- The branch began clean at the verified protected `main` SHA above, which includes POC 5.5 / PR #10. The user’s original dirty checkout was left untouched.
- Baseline collection and the captures below are WP0 evidence. Production code implements the approved WP1–WP7 scope, with final renderer and cross-cutting evidence recorded below.
- Work packages are bounded and reviewed before proceeding: WP1 progression/salvage; WP2 movement/spacing; WP3 construction readability; WP4 generalized inspection; WP5 population visibility; WP6 start/setup; WP7 pacing. A cross-cutting gate covers compatibility, evidence, docs, and delivery.
- Every package retains the approved acceptance criteria. A failed or unverified criterion does not pass a gate. Changes to scope or acceptance require a revised contract and renewed user approval.
- Adeptus will stop at `READY FOR REVIEW`; the external Strategerium Rules Lawyer determines final status. The PR will remain unmerged.

## System Topology and Authority

```text
project.godot / launch wrappers
        │
        ├── pipeline_proof.gd ── RoomDefinition / room data / generated scene
        │                              │
        │                              ├── CitizenAgent ↔ TaskCoordinator
        │                              ├── Economy / Resource / Salvage
        │                              ├── SettlementDevelopment / Population
        │                              └── WorldSimulation (shared fixed 0.1s tick)
        │
        ├── FishbowlHud / Civilization UI (read-only presentation and player actions)
        ├── SpectatorDirector / StrategyCamera (existing POC 5.5 focus path)
        └── conflict_startup.gd → ConflictScenario → shared WorldSimulation
```

Implementation seams and dependencies:

- Keep the 0.1-second deterministic world tick and authoritative systems intact. Presentation smoothing and UI must consume authoritative state.
- `SettlementDevelopmentSystem` already owns project requests, site choice, deliveries, work, completion effects, and outlines. Its project state and truthful blocker reporting also feed project labels and inspection.
- `ResourceSystem.derive` supplies size/material-based finite salvage profiles. `SalvageSystem` owns real stage work and yields; visual/navigational object changes happen through `CivilizationSimulation.apply_salvage_stage`.
- `CitizenAgent` advances authoritative positions and task work. Rendering can smooth a child visual pose, but target/path/work positions remain authoritative. Deterministic standing offsets must stay inside the existing navigation checks and task work radius.
- Generalized inspection must resolve stable runtime/semantic identity and coexist with the POC 5.5 event-focus/highlight path. It must not replace event navigation or manual camera ownership.
- `PopulationSystem` remains the only admission authority. Normal UI reads its reason, stability/cooldown, headroom, and admission events.
- Session setup uses `CivilizationDefinition`, `RoomDefinition`, existing 1-society startup, `ConflictScenario.prepare`, and the existing shared-world 2/3-society paths. Unsupported room/count combinations are disabled or rejected before launch.
- The menu and pace selector depend on launch configuration; below-1x pacing changes wall-clock scheduling only. Fixed 1x simulation timing stays unchanged.

High-risk compatibility seams are project/task reservation cleanup, material conservation, navigation-safe shared work positions, POC 5.5 event highlighting, multi-society startup, and deterministic replay. Targeted regression coverage and production-path probes gate each seam.

## WP0 — Baseline and Playtest Reconciliation

### Baseline identity and gates

| Item | Result | Evidence |
|---|---|---|
| Protected `main` / POC 5.5 baseline | `b4a0f7579379aceb0fd0e33fa8d2087e10f63614`, PR #10 merge present | Branch was created from this exact commit; initial worktree was clean |
| Pre-change Fast gate | **PASS**, exit 0; `ROOMSCALE_CATEGORY_PASS category=Fast`, including the repository’s Python/tooling and Godot fast gates | `verification/stabilization/runs/poc56-baseline-fast/` |
| Rendered 1x founder run | **PASS**, 185.999 sim seconds / 186.037 wall seconds; 5 real founders; first shelter completed at 145.3 sim seconds with real delivery and 60 worker-seconds; no failed tasks | `verification/poc56/baseline/result.json`; `startup.png`, `normal-speed-*.png`, `first-shelter-built-live.png` |
| Long founder production path | **PASS**, 4,800 sim seconds; shelter 145, depot 237, workshop 383, housing 632, first real citizen admission 935, traversal 1,489; all required checkpoints, conservation, real labor, navigation, and no-deadlock assertions passed | `verification/poc56/baseline/poc47-scenario-result.json` |
| Repeated expansion production path | **PASS**, 8 sim days in the 50-citizen `room_poc45` colony at its production 10x speed; population 50→80, earned shelter 50→90, four housing completions, workshop, real growth/traversal, conservation and `no_stuck_project` passed | `verification/poc56/baseline/poc45-scenario-result.json` |
| Rendered ordinary travel | Production `CitizenAgent` at 1x: 18 rendered frames; 10 repeated authoritative positions and 7 changed positions. Position advances in 0.65-inch steps per 0.1 sim-second; heading changes directly from 0 to approximately −π. | `verification/poc56/baseline/motion/motion.json` and `motion-00.png` through `motion-17.png` |
| Rendered shared worksite | Two real shelter builders at exactly `(2, 0, 45)` inches; measured minimum distance `0.0`, so one figure occludes the other in the capture | `verification/poc56/baseline/worksite/concurrent-builders.json`, `concurrent-builders.png` |
| Live pace comparison | 1x reference was approximately 1 sim-second per wall-second. A rendered 0.5x probe measured 7.5 sim seconds over 14.831 wall seconds (`0.506` ratio). Selected `0.5x`; this confirms a half-rate pace while retaining the 1x baseline. | `verification/poc56/baseline/pacing/pacing.json`, `speed-0.5x.png` |

### Finding disposition and current source explanation

| Playtest item | WP0 finding | Source / regression response |
|---|---|---|
| Building locations need clearer outlines | Reproduced as a low-contrast, thin pale perimeter at normal settlement-view distance. | `SettlementDevelopmentSystem.render_primitive()` uses 0.03-inch lines in one cream color for all states. WP3 will render stronger, state-aware perimeters. |
| Bookcase disappears after one resource pull | Not reproduced on POC 5.5. Both canonical founder and 50-citizen production runs emitted four real bookcase stages at cumulative work 8, 20, 32, and 42 seconds. The first extraction yielded 2 metal and left the object `STRIPPED`; it was removed only after final depletion. | `ResourceSystem.derive()` derives finite stages from object profile/size; `SalvageSystem.work()` completes one stage at a time; `CivilizationSimulation.apply_salvage_stage()` removes only depleted objects. Add a direct production-profile regression for a full-size bookcase after its first stage and conservation through depletion. |
| Citizen motion is visibly jerky | Reproduced in actual rendered travel. At 1x, authoritative 10 Hz position updates produce repeated render frames then 0.65-inch jumps; rotation is set directly each update. | `CitizenAgent._advance_path()` updates `global_position` and `rotation.y` on the simulation tick. WP2 will smooth only presentation transforms and preserve the authoritative path state. |
| Citizens overlap / share standing points | Reproduced: two real project builders had identical work positions, distance `0.0`; one figure occludes the other. | Construction tasks share the same `active.target`. WP2 will generate deterministic, navigation-safe local standing positions within the existing work radius and test them against obstacles. |
| Construction needs useful labels/status | Site label missing; the current HUD project panel shows name/state/materials, but there is no in-world name/progress/blocker label. The outline blends into the floor. | Project presentation is in `SettlementDevelopmentSystem.render()` and `render_primitive()`; current progress panel is `FishbowlHud.refresh()`. WP3 will expose the project’s authoritative state at its footprint and improve outline contrast. |
| Click inspection is too narrow | Current hit flow is split: `pipeline_proof.gd._unhandled_input()` tries goal surfaces, salvage/resource objects, then citizens. Completed buildings and active projects do not share a generalized inspector. | Existing object inspection is in `FishbowlHud`/`CivilizationSimulation`; citizen selection is `_selected_citizen`; POC 5.5 event clicks route through `FishbowlHud` to `FishbowlCameraDirector.focus_event()`. WP4 will add common descriptors/highlights without intercepting event focus or manual camera input. |
| Population growth is unclear | `PopulationSystem.reason` is authoritative and includes shelter, reserves/emergency, prerequisite, material, stability, cooldown, and safe-arrival states. Normal HUD does not keep these conditions visible; the details/diagnostic surface is required to inspect them. | `PopulationSystem.evaluate()` and `.eligibility()` remain the only decision source. WP5 will expose that state and admission events through ordinary UI. |
| Setup menu and society count | No normal setup menu; `project.godot` launches `pipeline_proof.tscn` directly. | WP6 will present only validated entries and invoke current production paths. |
| Supported society counts | One society: `RUN_ROOM_SCALE_FISHBOWL.ps1` → `RUN_ROOM_SCALE.ps1` with a room and `CivilizationDefinition`; two: `RUN_ROOM_SCALE_CONFLICT.ps1 -Scenario clockwork_vs_verdant`; three: same wrapper with `-Scenario three_party_conflict`. Both multi-society entries use `room_conflict` and existing shared-world startup. | `ConflictScenario.prepare()` validates definitions and slots; `conflict_startup.gd` composes real runtimes in one `WorldSimulation`. Menu choices will retain these boundaries; arbitrary-N is excluded. |
| Pace controls | Current options are Pause/0x, 1x, 4x, and 10x. 1x live timing matches wall time. A direct live property probe at 0.5 runs at half rate, but current integer HUD formatting displays it as `0x`. | Current speed buttons are built by `FishbowlHud`; simulation advances via `CivilizationSimulation.advance()`. WP7 will add 0.5x, exact display formatting, and menu selection while keeping 1x regression timing. |
| “Expand Shelter” never progressed | Not reproduced in either production regression run. The five-founder room built its first shelter and housing; the larger colony completed repeated housing projects and growth over eight sim days. Existing tests assert no stale project (`poc46_scenario_test.gd`) and complete real founder progression (`poc47_scenario_test.gd`). | No evidence supports changing housing costs, population rules, or site rules. The failure mode remains credible because current project states can look active while awaiting materials/workers and blocker detail is not prominent. WP1 will add truthful project lifecycle/blocker state and a targeted regression for progress, retry, and reservation cleanup. |
| Walls / defenses | Explicitly deferred. | No POC 5.6 implementation scope. |

### Authoritative docs and implementation read before design

Read before implementation: `README.md`, `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/POC47_FOUNDERS.md`, `docs/SPECTATOR_DIRECTOR.md`, the complete attached plan, and the production files named in the disposition table above. Relevant launch/scenario data read: `RUN_ROOM_SCALE_FISHBOWL.ps1`, `RUN_ROOM_SCALE_CONFLICT.ps1`, `scenarios/clockwork_vs_verdant.json`, `scenarios/three_party_conflict.json`, `rooms/room_poc47.json`, and `rooms/room_poc45.json`.

WP0 exit is met: both progression reports were investigated in production paths; the renderer documented motion and overlap; current UI/data paths, population rules, launch counts, controls, and live pace were recorded. The accepted provisional `0.5x` is confirmed, so no contract revision is required. A salvage regression guard will be added because the failure remains credible even though it does not reproduce on this SHA.

## Work Package Plan and Gates

| Package | Scope / dependent seam | Gate evidence |
|---|---|---|
| WP1 | Shelter/project lifecycle truth, retry/cleanup, finite large-object salvage. Supplies authoritative status used by labels and inspection. | Focused lifecycle and salvage assertions pass; POC47 and POC45 production scenarios pass; intact/partial bookcase captures and receipt are present. Independent review pending. |
| WP2 | Render-only motion interpolation, heading presentation, deterministic shared-site spacing that respects navigation and work radius. | WP2 position/heading and legal-slot assertions pass; real 8-frame position/yaw sequence and spaced-worksite capture pass; navigation and POC 5.5 suites pass. Independent review pending. |
| WP3 | High-contrast state-aware footprint and concise in-world active-project label from WP1 state. | Real-renderer planned, progressing, blocked, and completed captures show distinct state colors, footprint, work, and truthful blocker. Independent review pending. |
| WP4 | Common inspectable descriptor and selected-entity highlight for citizens, buildings, projects, furniture, resources/sites/surfaces. | WP4 descriptor assertions pass; real captures cover citizen, project, completed building, intact/partial furniture, resource, and elevated surface; POC 5.5 event behavior passes. Independent review pending. |
| WP5 | Ordinary growth status sourced from PopulationSystem, including reason, headroom, stability/cooldown, and actual admission. | Adapter/UI assertions pass; rendered growth blocker is captured; production founder and expansion runs record real admission/growth. Independent review pending. |
| WP6 | Normal setup scene; supported room/scenario and 1–3 count validation; per-society real definition selection; default launch and command-line/test compatibility. | Menu/config validation and one/two/three-society runtime composition pass; both real menu states are captured; wrapper compatibility passes. Independent review pending. |
| WP7 | 0.5x pace control and initial-speed menu preference, exact fractional speed presentation, unchanged 1x simulation semantics. | Pace formatting/fixed-step tests pass; rendered 0.5x pacing measured at 0.505580 (3.0 simulation seconds / 5.933778 wall seconds); speed-switch frames and 1x regression pass. Independent review pending. |
| Cross-cutting | Test/evidence assertion review, full AC-to-evidence map, authoritative docs/README updates, clean protected-main branch/PR delivery. | Final Fast, POC 5.5, founder, expansion, multi-society, and real-renderer gates pass. Independent Rules Lawyer review pending before push/PR. |

## Current Implementation State

| Gate | Result | Evidence |
|---|---|---|
| Final Fast | **PASS**, `ROOMSCALE_CATEGORY_PASS category=Fast`; includes Ruff/format, tooling, room/navigation, POC47 Fast, roles, WP1–WP7 focused tests, and placement regressions. | `verification/stabilization/runs/poc56-final-fast/fast/`; invoked with the worktree `.venv/Scripts/python.exe` so pinned Ruff 0.15.20 is used. |
| POC 5.5 regression | **PASS**, full `TEST_ROOM_SCALE_POC55.ps1 -Mode All`, including lifecycle, producer/UI, deterministic director modes, rendered UI, and rendered priority/random graphics. | `verification/stabilization/runs/poc56-poc55-final/` |
| Founder production | **PASS**, 8-day production run; 12 citizens, seven growth cohorts, shelter/depot/workshop/housing complete, oldest task 130.5 sim seconds, oldest project 135 sim seconds. | `verification/stabilization/runs/poc56-poc47-final/scenario.json` |
| Repeated expansion production | **PASS**, 8-day 50→80 colony run; shelter 50→90, four housing completions, five total projects, oldest task 184.2 seconds, oldest project 180 seconds. | `verification/stabilization/runs/poc56-poc45-final/scenario.json` |
| Civilization systems | **PASS**: POC54 `RunCount 3` (ownership/data/armory/behavior and 3-party integration repeatability); innovation definition and live determinism; two-party, three-party, and conflict-pressure scenarios. | `verification/stabilization/runs/poc56-poc54-final/`, `poc56-innovation-final/`, `poc56-innovation-live-final/`, `poc56-conflict-two-party/`, `poc56-conflict-three-party/`, `poc56-conflict-pressure/` |
| Real renderer | **PASS**, 26 captures at 1920×1080 on Windows / NVIDIA GeForce RTX 5090; no assertion failures. The configured main scene transitions to setup before simulation, then the actual Start button launches the selected session. Live 0.5× ratio 0.505580 (3.0 sim seconds / 5.933778 wall seconds). Rendered position and yaw telemetry changes across the eight-frame sequence; entity and event highlights coexist in a rendered capture. | `verification/poc56/final/renderer-evidence.json` and its PNG captures. |
| Work-package focused tests | **PASS**, WP1–WP7 plus 1/2/3-society production configuration, lifecycle cleanup, and placement/navigation checks. | `verification/stabilization/runs/poc56-final-fast/fast/` and `scripts/poc56_wp1_test.gd` through `scripts/poc56_wp7_test.gd` |

Raw run outputs are ignored runtime evidence; curated renderer PNGs and the concise receipt are part of the review packet. Godot-generated unrelated `.import` changes and legacy script UID files were removed from the worktree diff. The first default-Python Fast invocation stopped because global Python lacks Ruff; rerunning with the repository-local pinned Python completed the full gate successfully.

`README.md` describes the normal menu launch, validated one/two/three-society presets, direct wrapper behavior, and the new 0.5x control.

## Acceptance-to-Evidence Map

| AC | Contract outcome | Planned / current evidence |
|---|---|---|
| 01 | Clean protected-main baseline including POC 5.5 | Starting SHA and clean worktree record above; final ancestry check remains part of delivery. |
| 02 | Fast suite passes before and after | Baseline Fast and final `poc56-final-fast/fast/` pass; post-review Fast and CI remain for delivery. |
| 03 | Shelter expansion progresses or reports truthful blocker | WP1 focused test; 8-day POC47/POC45 production receipts; planned and blocked captures. |
| 04 | Transient retries are bounded and observable | WP1 retry/site/worker/material blocker tests and project status receipt. |
| 05 | Failed/cancelled/superseded projects release reservations/tasks | WP1 lifecycle test log verifies economy tickets and TaskCoordinator ownership cleanup. |
| 06 | Full-size bookcase survives first extraction | `selected-bookcase-full.png`, `selected-partial-bookcase.png`, WP1 salvage test. |
| 07 | Large salvage requires accumulated work/stages | WP1 work/stage ledger assertions; partial stage 1/4 receipt and POC47 production JSON. |
| 08 | Salvage and finite resources remain conserved | Resource/economy audits in WP1, POC54, POC47, and POC45 production receipts. |
| 09 | Partial furniture stays visible and blocks navigation until depletion | WP1 rendered/navigability checks; partial-stage capture shows remaining physical geometry. |
| 10 | Citizen translation looks smooth | `smooth-motion-00.png` through `smooth-motion-07.png` and authoritative/rendered position telemetry. |
| 11 | Citizen heading changes are readable | Eight-frame rendered yaw telemetry and smoothed-turn assertion in `renderer-evidence.json`. |
| 12 | Citizens normally use distinct shared-site positions | `spaced-worksite.png`, distinct standing-target data, WP2 standing-slot test. |
| 13 | Spacing stays in legal navigation | WP2 obstacle/work-radius checks and final navigation/traversal/combat regression gates. |
| 14 | Build footprint is high-contrast and state-aware | Planned, active, blocked, and completed site PNGs show state-specific outline colors. |
| 15 | Active project has a readable in-world name | Planned and active footprint captures show project name and lifecycle. |
| 16 | Label/inspector shows real progress and truthful blocker | Active/blocked site captures and authoritative WP1/WP3 state-source assertions. |
| 17 | Citizen click inspection remains useful | `selected-citizen.png` plus synthetic viewport click through `_unhandled_input()` in WP4, asserting live citizen identity. |
| 18 | Completed building inspection shows real function/state | `selected-completed-building.png` and production-backed descriptor assertion. |
| 19 | Active project inspection shows stage/material/workers/blocker | `selected-active-project.png` plus actual viewport click and normal inspector routing in WP4. |
| 20 | Furniture inspection shows semantic and salvage state | Full and partial bookcase captures plus actual furniture viewport click and WP4 descriptor assertions. |
| 21 | Important supported entities can be inspected/highlighted | Resource, site, and surface actual viewport clicks in WP4; `selection-event-highlight-coexistence.png`; goal-surface click also asserts the existing Reach/Explore action remains available. |
| 22 | PopulationSystem remains authoritative | WP5 adapter tests assert fields derive from PopulationSystem only. |
| 23 | Normal UI explains population growth and blockers | `population-growth-blocker.png` plus WP5 reason/headroom/stability/cooldown UI assertions. |
| 24 | Admission creates real citizens through existing path | POC47 production receipt records real admitted cohorts; WP5 production test. |
| 25 | Normal graphical launch shows setup before simulation | Real-renderer harness instantiates configured `pipeline_proof.tscn` with menu overrides unset, confirms transition to `start-menu.png` before simulation, then clicks Start in the actual viewport. |
| 26 | Supported 1/2/3 societies are configurable | `start-menu-three-society-defaults.png`; WP6 clicks actual Start for one-, two-, and three-society configurations. |
| 27 | Menu choices enter real CivilizationDefinitions/shared-world runtime | WP6 actual Start-button runs assert selected definition IDs, live rosters, and runtime society composition; POC54 shared-world integration runs. |
| 28 | Unsupported combinations are rejected; existing launch paths work | WP6 validation tests, menu state, and final Fast/wrapper compatibility checks. |
| 29 | Initial speed selection is honored | WP6 selects non-default 1.0x/0.5x values in the menu, clicks Start, and asserts runtime initial speed; graphical launch capture clicks Start at default 0.5x. |
| 30 | Below-1x speed works | `pacing-probe.png`, `speed-switch-1x.png`, renderer ratio `0.505580`. |
| 31 | Existing 1x semantics remain deterministic | Final Fast and POC55 deterministic isolation/repeatability gates. |
| 32 | POC 5.5 spectator and economy behavior regress cleanly | Full POC55 All result under `poc56-poc55-final/`. |
| 33 | Founder lifecycle and economy regress cleanly | POC47 eight-day run and POC45 eight-day expansion run, plus WP1. |
| 34 | Conflict/innovation/doctrine/mobilization systems regress cleanly | POC54 3×, innovation live repeatability, pair/three-party conflict, and pressure scenarios. |
| 35 | All plan renderer evidence exists | 26-entry `renderer-evidence.json` manifest and PNGs under `verification/poc56/final/`, including actual menu launch, selected entities, highlight coexistence, construction, population, spacing, and motion captures. |
| 36 | No manual user development/evidence work | Implementation, evidence capture, and regression gates are automated in branch scripts. |
| 37 | Walls/defenses remain excluded | Final scope review against the approved out-of-scope boundary is part of independent review. |
| 38 | Protected-main branch/PR workflow retained | Branch is based on the approved POC 5.5 SHA; PR #11 is open and unmerged. |
| 39 | Strategerium contract reached independent `CONTRACT APPROVED` | Approved contract retained in task history |
| 40 | No target implementation before explicit user approval | Task history; approval received as “go for it!” before Adeptus invocation and branch changes |
| 41 | Installed Adeptus workflow used after approval | Loaded skill path and WP gate/handoff record |
| 42 | Adeptus `READY FOR REVIEW` then external Rules Lawyer review | The complete implementation/evidence packet received the independent Rules Lawyer `COMPLETE` verdict before delivery. |
| 43 | Push branch/open PR/run Fast; do not merge | PR [#11](https://github.com/denni1cd/roomscale/pull/11) is open from branch `codex/poc56-playtest-stabilization`; the required Fast check and all workflow jobs pass. PR remains unmerged. |
| 44 | Approved WP0–WP7 boundaries retained | Source and diff scope review is included in final independent review. |
| 45 | Baseline/reconciliation completed before product changes | WP0 baseline identity, gates, renderer receipts, source mapping, issue dispositions, launch map, and confirmed 0.5x decision above. |

## Final Evidence Folder Convention

Keep pre-change evidence under `verification/poc56/baseline/`. Keep final renderer captures and concise machine-readable receipts under `verification/poc56/final/`. The completed AC map is this document. Generated Godot import metadata and local editor caches are not acceptance evidence and will be removed from the change set.
