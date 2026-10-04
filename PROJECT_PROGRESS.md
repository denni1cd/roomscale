# RoomScale Progress

## POC 4.7 founder start

Five founders now build the settlement through production salvage, hauling and
construction. Canonical Fishbowl starts at 1x with no completed infrastructure.
Shelter, storage and workshop capabilities activate on completion; growth adds
one CitizenAgent after sustained healthy conditions. Workshop capability gates
advanced traversal. The existing established colony remains a legacy fixture.
See the [founder guide](docs/POC47_FOUNDERS.md) and
[verification report](verification/poc47/final-report.md) for final gate evidence.

## POC 4.6 spectator experience

Implemented on `codex/roomscale-poc46-spectator-ui` from verified POC 4.5
`c0b93c5dd74081bc20068b7455ec9805dc5fb71d`. Compact HUD, real-time event cards,
context projects, automatic shot titles/close-ups, F3 details, quiet fade and 10x
fishbowl startup are in place. Cohorts now validate five distinct navigation points
before any spawn, and task-board development progress uses development work.
Three consecutive fresh eight-day runs passed at 80 real citizens, with zero failed
tasks and conserved economy. POC 4.5 fast and POC 4 fast/contract/cleanup remain green.
Rendered 1080p/1440p captures and each acceptance item are reviewed in the
[POC 4.6 report](verification/poc46/final-report.md). Historical POC 4.5 evidence
remains intact; no merge into main.

## POC 4.5 autonomous colony

**PASS** on `codex/roomscale-poc45-fishbowl`, extending verified POC 4.
M0–M8 and all 55 criteria pass. Fresh full runs reach 80 citizens and four housing
blocks plus a workshop; sixty-day production reaches 120 citizens, seven housing
blocks and one workshop before stabilizing at finite material capacity. Final fresh
repeatability is 3/3; POC 4/manual and Room A→B→A regressions remain green.
The governor acts through civilization priorities/directives/authorization;
citizens retain ordinary needs, movement, hauling, salvage, traversal and work.
Housing/workshop modules use conserved delivery tickets and physical builders;
five-node cohorts require sustained reserves and capacity. Manual mode is preserved.

The [milestone record](verification/poc45/milestones.md),
[55-criterion matrix](verification/poc45/acceptance.md), and
[final report](verification/poc45/final-report.md) record the actual gate results,
population/material limits, regressions, long-run metrics and inspected captures.
Use [the gameplay guide](docs/POC45_FISHBOWL.md) to continue without chat context.

## POC 4 completion

**PASS** on 2026-10-02. Milestones 0–9 and all 45 acceptance criteria are
complete. The canonical water crisis is resolved through authorized furniture
salvage, physical hauling, existing construction/traversal, and stored water;
50 citizens continue consuming food/water and resting autonomously.

| Milestone | Status | Evidence under verification/poc4/ |
| --- | --- | --- |
| M0 — Regression and Baseline Gate | PASS | `baseline/`, `m0-m2-status.md` |
| M1 — Core Needs | PASS | `final-fast/fast.log`, `release/stability-30days.json` |
| M2 — Economy and Forecasting | PASS | Exclusive tickets, conservation audits, real consumption in final fast/full logs |
| M3 — Priorities and Directives | PASS | Ranking and production labor checks; rendered high-level controls |
| M4 — Room Resource Profiles | PASS | Generic profiles; `final-fast/contract.log`, alternate-surface scenario |
| M5 — Staged Salvage | PASS | Four on-site stages, 13 wood/4 metal, real bundles and delivery |
| M6 — Needs-to-Expansion Integration | PASS | `release/repeat-01.json`, complete causal chain |
| M7 — Sustained Simulation | PASS | Five seven-day runs plus rendered `final-evidence/sustained-7days.json` |
| M8 — Automated Verification | PASS | `release/summary.json`: 8/8, including five consecutive scenarios and 30 days |
| M9 — Gameplay Presentation Pass | PASS | 17 inspected captures, normal HUD/inspection, `visual-review.md` |

See the [criterion matrix](verification/poc4/acceptance.md) and
[final report](verification/poc4/final-report.md) for exact commands, results,
architecture changes and scope limits. The default launch is now POC 4;
explicit historical rooms retain their existing scenarios. Earlier POC 3 human
visual acceptance remains a separate historical gate.

## POC 3 implementation

The visual implementation and retained baseline are on
`codex/roomscale-poc3-visual-fidelity`. Functional A/B/photo-room scenarios pass,
the semantic catalog and original automated GLB pipeline are implemented, and
enhanced citizens, settlement details, furniture, resources and grapple stages
are captured from real simulation. See [the POC 3 acceptance record](verification/poc3/acceptance.md)
for exact evidence, failed iterations, performance caveats and outstanding
human visual acceptance. POC 3 is not declared complete from functional tests.

The final constrained polish improves builder/tool contact, routes utility wires
around the settlement perimeter with physical fittings, and adds quiet floor wear.
See [the final polish review](verification/poc3/refinement/final-polish/review.md).

The scene-composition refinement adds linked districts, storage clusters,
miniature homes, human pencil/coin references, a neutral low-contrast floor,
lit working poses and compact presentation HUD. Iterations and canonical
refinement evidence are preserved separately; see [the refinement review](verification/poc3/refinement/review.md).

| Milestone | Status | Evidence |
| --- | --- | --- |
| M0 — Agent/engine proof | PASS | `verification/milestone0-status.md`, commit `dbdedb0` |
| M1 — Room and camera | PASS | `verification/milestone1-status.md`, commit `224ae40` |
| M2 — Living settlement | PASS | `verification/milestone2-status.md` |
| M3 — Surface navigation and goal | PASS | `verification/milestone3-status.md`; headless and live UI path verified |
| M4 — Construction | PASS | `verification/milestone4-status.md`, `milestone4-smoke.log`, hauling and construction captures |
| M5 — Grappling traversal | PASS | `verification/milestone5-status.md`, smoke log, and inspected cable/desk captures |
| M6 — Integrated gameplay | PASS | `verification/milestone6-status.md`, smoke log, and inspected desk/reuse captures |
| M7 — Automated verification | PASS | 10/10 full scenarios in fresh Godot processes; `verification/milestone7-repeatability-summary.md` |
| M8 — Presentation pass | PASS | `verification/milestone8-status.md`, `milestone8-smoke.log`, inspected launch screenshots |

## POC 1.5 completion

POC 1.5 is PASS. The current production source has no Room B gameplay branch and no fixed Room A target coordinates in citizen, task, navigation, construction, traversal, or exploration systems. The complete evidence map is [docs/POC_1.5_ACCEPTANCE.md](docs/POC_1.5_ACCEPTANCE.md).

| Gate | Result | Evidence |
| --- | --- | --- |
| Fast deterministic verification | PASS | `verification/poc15/ac10-fast.log`; 2 definitions without required approach hints, 12 malformed cases, geometry-derived reachable candidates, generated obstacles, derived sites, runtime navigation validation, region connectivity, bounded task history 500/500 |
| Room A complete scenario | PASS | `verification/poc15/ac10-room_a.log`; M2-M6/M8 PASS, 50 citizens, real deliveries/build/traversal/reuse, citizen inspection |
| Room B complete scenario | PASS | `verification/poc15/ac10-room_b.log`; 260x220 room, Workbench target at 36in, same M2-M6/M8 production markers |
| Cross-room regression | PASS | `verification/poc15/ac10-cross-room/summary.md`; Room A → Room B → Room A, 3/3 |
| Room A repeatability | PASS | `verification/poc15/repeatability/room_a/summary.md`; 5/5 fresh full runs |
| Room B repeatability | PASS | `verification/poc15/repeatability/room_b/summary.md`; 5/5 fresh full runs |
| Visual verification | PASS | `verification/poc15/visual/room_a/` and `verification/poc15/visual/cross-room/step-02-room_b/`; nine 1280x720 phases per room |

## Acceptance Criteria

| AC | Status | Notes |
| --- | --- | --- |
| AC-01 Automated Bootstrap | PASS | Setup, run, and test scripts; no editor work required. |
| AC-02 3D Room | PASS | Runtime-generated room and furnishings. |
| AC-03 Scale | PASS | Inch-based world; citizen figure height checked at 0.5in. |
| AC-04 Camera | PASS | Room (300in), settlement (132in), and citizen views; eased presets and pan/orbit/tilt/zoom checks. |
| AC-05 Population | PASS | Exactly 50 separate citizen nodes, all assigned active tasks. |
| AC-06 Autonomous Activity | PASS | Citizens move, carry parcels, and cycle shared tasks deterministically. |
| AC-07 Floor Navigation | PASS | Grid A* detours around furniture and settlement footprints. |
| AC-08 Target Selection | PASS | Live desk click selected the collider surface; Reach / Explore button and Enter both issued the goal. |
| AC-09 Barrier Recognition | PASS | After two explorers physically reach clear A* investigation points, repeated FLOOR-to-DESK route request confirms the missing link. |
| AC-10 Autonomous Response | PASS | Barrier confirmation automatically creates the grapple project and assigns delivery work. |
| AC-11 Resource Delivery | PASS | Eleven citizens pick up 4 wood, 4 metal, and 3 mechanical-parts units and carry each by floor A* paths; smoke verifies pickup, travel, and delivery records. |
| AC-12 Construction | PASS | Material gates unlock builders; on-site work advances and reveals base, winch, and launcher components. |
| AC-13 Grappling Infrastructure | PASS | Completed launcher deploys a segmented visible cable from its top to a desk anchor. |
| AC-14 Navigation Change | PASS | FLOOR and DESK remain disconnected until launcher completion; deployment registers the physical route. |
| AC-15 Visible Traversal | PASS | Citizen follows floor A*, climbs the launcher and cable with continuous 3D movement, and reaches the desk at 30in. |
| AC-16 Desk Exploration | PASS | Each climber walks a multi-waypoint route on the desk, then performs validated work; three completions recorded. |
| AC-17 Autonomous Reuse | PASS | Two additional citizens are assigned the deployed FLOOR–DESK path automatically after desk exploration; no player/test command dispatches them. |
| AC-18 Persistent Session State | PASS | Within the live session, cable segments and FLOOR–DESK connection remain operational through desk exploration and both later traversals; persistent save files are out of scope. |
| AC-19 Player Feedback | PASS | HUD names the focused citizen and displays desk arrivals, explorations, route reuses, and infrastructure state. |
| AC-20 Repeatability | PASS | Ten full scenarios passed consecutively in separate fresh Godot processes; per-run logs retained. |
| AC-21 Zero Required Editor Work | PASS | Current project and scene pipeline are code-authored. |

## Latest Verification

`TEST_ROOM_SCALE.ps1 -LogPath verification/milestone6-smoke.log` — **PASS**, Godot `4.7.2.stable.official.ed1daf0bf` (exit 0). M2–M5 regression gates pass. M3 confirmed the initial FLOOR–DESK disconnection after two physical approaches (16.50s). M4 verified all 11 depot deliveries, material gates, three completed construction stages, and 100% progress. M5 verified the 13-segment cable, a 63-point joined floor-A*/launcher/cable/desk route, and continuous arrival at 30in. M6 then recorded three distinct completed traversals, three desk explorations with 12.0 total seconds of validated work, and two coordinator-dispatched autonomous route reuses. Each task records at least 90% of its path distance, and 0.2s movement sampling saw no teleport-sized step (maximum 1.36in). Cable geometry and the navigation connection remained operational after the chain. Fresh visible captures were inspected: `verification/milestone6-desk-exploration.png` and `verification/milestone6-autonomous-route-reuse.png`.

`TEST_ROOM_SCALE_REPEATABILITY.ps1 -RunCount 10 -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 60` — **PASS**, 10/10 fresh Godot processes, total 33.99 minutes. Every run exited 0 and included M2–M6 PASS markers; all ten per-run logs were rechecked for missing markers and script/smoke errors. Summary and status: `verification/milestone7-repeatability-summary.md`, `verification/milestone7-status.md`. Future runner defaults are 300 seconds per run and 40 minutes overall; first failure stops the batch.

`TEST_ROOM_SCALE.ps1 -TimeoutSeconds 300 -LogPath verification/milestone8-smoke.log` — **PASS**, Godot `4.7.2.stable.official.ed1daf0bf` (exit 0). M2–M6 regression assertions and M8 presentation assertions all passed. Camera controls include eased preset transitions; smoke confirms desk selection works while transition state is active. The presentation pass adds a toothed animated workshop gear, emitted boiler steam, warm pulsing boiler light, more balanced ambient/glow lighting, brass-edged translucent HUD panels, and a smaller HUD that leaves more of the room visible. `RUN_ROOM_SCALE.ps1` launched the production scene and produced fresh captures: `verification/milestone8-launch-startup.png` (room composition) and `verification/milestone8-settlement-view.png` (132in settlement composition). Both were inspected; the broad room shot is the primary composition, while the settlement preset intentionally gives a closer crop of the living work area. Details: `verification/milestone8-status.md`.

## Open Issues

No known blocking defect. Construction progress is bounded at 100%; the floor-to-desk link appears only after launcher completion. Desk exploration and autonomous route reuse are session-scoped; no save-file persistence is required by the plan.

## Next Action

POC 4 implementation and verification are complete. Play with
`./RUN_ROOM_SCALE.ps1`; no Godot editing is needed. Earlier plans and evidence
remain preserved.
