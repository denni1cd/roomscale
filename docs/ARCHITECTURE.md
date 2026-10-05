# RoomScale architecture

This describes stabilization based on completed POC4.7.2 (`efa5950`). Current launch/test commands are in README and TESTING.
There is one room, one civilization, append-only citizen IDs and finite resources.

## Composition and configuration

`scenes/pipeline_proof.tscn` instantiates `pipeline_proof.gd`, the current composition
root. It loads RoomDefinition, builds room/shell/furniture, settlement presentation,
floor/surface navigation, coordinator, construction, population, camera and overlay.
This class is large; extracting visual builders is deferred to avoid scene/render churn.
Room JSON owns coordinates/configuration. Runtime copies support salvage/construction
obstacles; authored files are never mutated by simulation. RoomDefinition validates
schema 1/2, finite geometry, IDs, source/stage metadata, appearance and startup fields.
Runtime navigation validation is a separate gate from structural JSON validation.

Environment variables select room/file, autonomous mode and capture/test outputs at
launch. Test runners isolate them and restore parent process configuration. A local JSON
must stay inside the project and have a filename stem matching its room ID. Arbitrary
object IDs are mapped explicitly to room-object roots rather than interpreted as NodePaths.

## Simulation clock and order

`CivilizationSimulation._process` multiplies wall delta by selected speed and calls
`advance`; its accumulator repeatedly executes `step` at **0.1 simulation seconds**.
Each tick increments seconds, runs the governor (its internal five-second decision
cadence), advances the one-second planner cadence, decays each citizen's needs and
advances that citizen in stable array order, then advances traversal construction.
The new `advance_simulation` methods expose intentional stepping; engine callbacks
remain wrappers. Tests call the same production step, without reordering workers.
Simulation days are 600 seconds. Presentation camera/HUD updates have no economy or
capability authority. Pause stops production while explicit presentation refresh remains
possible. Changing insertion order, tick order or timers can change deterministic outcomes.

## State authority

| Domain | Authority | Consumers and mutation rules |
|---|---|---|
| Authored geometry/config | RoomDefinition | Composition validates then copies; no test rewrites live inputs to earn acceptance. |
| Floor obstacles/grid | FloorNavigation | Salvage/development update legitimate object state and refresh navigation; route changes must preserve physical traversal. |
| Surfaces/deployed links | SurfaceNavigation | Construction registers a link only after real build/deploy/attachment. A route is reachable only with its floor exit. |
| Citizen position/work | CitizenAgent | Follows validated waypoints at existing speed; owns current task/path, physical carry and work progress. |
| Task IDs/lifecycle/history | TaskCoordinator | Creates, claims, activates, completes/fails/cancels; cancellation releases domain reservations. Terminal task history is trimmed at 500; active/reserved tasks are retained even if the live ledger exceeds that bound. |
| Needs/rest slots | NeedSystem | Decay, self-care reservation and earned capacity; task work invokes real food/water consumption. |
| Depot inventory | EconomySystem | Exclusive available/reserved/transit/delivered/consumed tickets; audit enforces conservation. |
| World source contents/bundles | ResourceSystem | Finite remaining/reserved/extracted/delivered ledgers; physical work creates bundles, return trip receives stock. |
| Furniture salvage | SalvageSystem | Authorization, finite stage work/yields, once-only progression and depletion; production applies visual/navigation consequences. |
| Traversal project | ConstructionSystem | Material tickets, worker effort, stages, deployment and actual link creation. Legacy non-economy path retained. |
| Founding layout/reservations | SettlementSitePlanner | Bounded deterministic candidates and cloned-navigation checks; chooses sites/rest targets, never consumes inventory or completes construction. |
| Settlement projects/capabilities | SettlementDevelopmentSystem | Site checks, real deliveries/labor, once-only completed benefits and navigation obstacles. |
| Admission of citizens | PopulationSystem | Reserves/shelter/stability/cooldown/cap checks, then normal entities at safe connected positions. |
| Intent and priorities | Governor / CivilizationPlanner | Policies choose production requests/tasks, never grant materials/completion/citizens/links. |
| Events / viewing | EventJournal / HUD / narrative / camera | Bounded diagnostic events and state presentation; no domain ownership. |

Task, ticket and project dictionaries stay inspectable. A task copy given to a citizen
is not a second economic ledger. Coordinator's live task record stores pickup/progress;
Economy/Resource/Salvage remain accounting authorities. Wider typed domain records are
deferred; no generic entity/framework layer is introduced.

## Citizens and task lifecycle

Startup builds a complete valid roster atomically, preserving canonical starts. IDs
remain contiguous indices, node names CitizenNN and append order are explicit contracts.
A citizen claims a task, navigates its first leg, performs physical pickup/work, traverses
its delivery leg, completes or fails, releases reservations and chooses normal next work.
Unavailable navigation returns to idle/retry at the existing tick boundary; it must not
recursively exhaust the stack. Self-care can interrupt routine work and releases tickets.

Population growth uses completed capability/shelter and finite source forecasts. Founder
mode admits one real CitizenAgent; established legacy mode admits five. Initial founders
have no shelter by design; added citizens require earned capacity. No counter-only growth,
teleportation, mortality or resource creation is present.

## Economy, salvage and construction

Source reservation alone does not increase inventory. On-site extraction/salvage work
produces a finite bundle; actual hauling/receipt transfers it into Economy. Project pickup
moves a reserved ticket to transit; delivery moves it to delivered; construction consumes
once. Failed/canceled work releases or drops inventory using production accounting.
Stock and source audits are checked continuously in integration observers.

Primitive shelter, depot, workshop and housing earn their recorded benefits only at
completion. The bounded site planner reserves a connected shelter/depot/workshop/first-housing
layout and permanent rest targets before founding. Completion revalidates current
occupants and activity access. Failure caching must include transient planning state;
cloned navigation validation does not mutate the live world. Workshop completion
gates advanced traversal. Grapple construction uses ordinary costs, stages, work and
physical attachment/deployment before SurfaceNavigation receives its link.
No cleanup changes costs, durations, speed, need decay, founder count, housing/growth
rules, resource quantities or capability sequence.

## Navigation and traversal

FloorNavigation uses a four-inch A* grid with conservative rotated/padded obstacle
footprints and physically validated endpoint connectors. Narrow legal aisles have an
explicit physical connector fallback. Legacy established-room interior endpoints remain
supported; founder observers forbid entry into blocking geometry.
SurfaceNavigation joins floor paths, deployed cable/launcher points and elevated paths.
A citizen already on a link must continue on actual deployed geometry during replanning;
construction completion cannot drop it through open space. Reverse elevated-to-floor
routes now reject disconnected floor exits. No cleanup grants links or bypasses labor.

## Scene contracts and remaining coupling

The single production root contains TaskCoordinator, ConstructionSystem, FloorNavigation,
SurfaceNavigation, RoomObjects, Settlement, StrategyCamera and Overlay. These fixed names
are composition contracts; runtime services are wired by that root. Existing camera rig
private focus/transform access, raw task fields, construction stage internals and scene
room/citizen fields remain bounded single-scene coupling. Public stepping/replanning and
navigation-refresh APIs remove misleading engine/private invocation contracts without
changing state authority. Splitting the root, camera API redesign and full task mutation
encapsulation are deferred, with evidence in code-review.md.

Duplicating the civilization services is unsafe: it would duplicate finite source/salvage
ledgers and allow conflicting site reservations/navigation revisions. This document is
an ownership audit, not permission to implement multi-civilization features.

## Verification and artifacts

Focused fixtures exercise invalid paths/configuration, accounting and lifecycle without
claiming earned integration. Smoke validates scene/configuration; canonical observes five
founders through physical settlement/traversal/growth; historical regressions preserve
POC4/45/46 and original rooms. Campaigns vary authored definitions/seeds and observe
production fixed ticks with continuous conservation, capability, population and movement
checks. Soaks measure bounded retained task/event state and honest finite exhaustion.

Runner success requires process exit, explicit pass marker and no engine/script error.
Campaign reruns remove stale result files and execution failure overrides any JSON PASS.
Evidence audits cannot overwrite acceptance reports on inconsistency. The strengthened M4/M5/M6, POC47 live and POC46 camera drivers
check PNG output before declaring evidence success; older visual/sidecar paths retain
their historical behavior and do not supply cleanup visual acceptance. Ruff covers Python only; GDScript receives
manual review, parse/import and actual Godot regressions.

Raw outputs are ignored. Compact source-specific reports/manifests are published after
freezing verified production/harness SHA; any later executable source edit invalidates
that freeze. Verification/.gdignore prevents evidence assets from being imported as game
resources. Exact duplicate-image replacements are listed in the artifact manifest; unique
fixtures, images, seeds, failed investigations and independent repeat receipts are kept.
