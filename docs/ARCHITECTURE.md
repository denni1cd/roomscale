# RoomScale architecture

This describes stabilization based on completed POC4.7.2 (`efa5950`) plus the
civilization-selection boundary introduced after that baseline. Current launch/test
commands are in README and TESTING. There is one room and **one active civilization per
run**, append-only citizen IDs and finite resources. Clockwork and Verdant are selectable
implementations of the same production simulation; simultaneous civilizations are not
implemented.

## Composition and configuration

`scenes/pipeline_proof.tscn` instantiates `pipeline_proof.gd`, the current composition
root. It loads RoomDefinition, builds room/shell/furniture, settlement presentation,
floor/surface navigation, coordinator, construction, population, camera and overlay.
This class is large; extracting visual builders is deferred to avoid scene/render churn.
Room JSON owns coordinates/configuration. Runtime copies support salvage/construction
obstacles; authored files are never mutated by simulation. RoomDefinition validates
schema 1/2, finite geometry, IDs, source/stage metadata, appearance and startup fields.
Runtime navigation validation is a separate gate from structural JSON validation.

`CivilizationDefinition` is a separate input contract under `civilizations/`. It owns
civilization identity, presentation vocabulary, palette/style identifiers and player-facing
construction/resource terminology. It does **not** own room coordinates, economy ledgers,
navigation links or citizen decision state. `clockwork.json` remains the compatibility
default; `verdant.json` is the second implementation.

Environment variables select room/file, civilization, autonomous mode and capture/test
outputs at launch. Test runners isolate them and restore parent process configuration. A
local JSON must stay inside the project and have a filename stem matching its room ID.
Arbitrary object IDs are mapped explicitly to room-object roots rather than interpreted as
NodePaths. Room and civilization selection are orthogonal: a room definition never gains
Clockwork grapple coordinates or Verdant vine coordinates.

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

`CivilizationSimulation` means the **shared society runtime**. It must not be confused
with `CivilizationDefinition`: selecting Verdant does not create a second simulation,
economy, task board or navigation authority.

## State authority

| Domain | Authority | Consumers and mutation rules |
|---|---|---|
| Authored geometry/config | RoomDefinition | Composition validates then copies; no test rewrites live inputs to earn acceptance. |
| Active civilization identity/vocabulary | CivilizationDefinition | Loaded once from `civilizations/`; presentation consumes it. It cannot mutate room geometry or production ledgers. |
| Civilization appearance | CivilizationPresentation / VerdantDevelopmentPresentation | Reads real production state and creates/hides presentation only; no task, cost, progress, collision or navigation authority. |
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

Startup builds a complete valid roster atomically, preserving the original five-founder
and Room A/B positions. Compact legacy spawn areas are seed regions: small rosters
can fall back to distinct legal connected room cells; larger rosters remain within
their explicitly sized spawn footprint. IDs
remain contiguous indices, node names CitizenNN and append order are explicit contracts.
A citizen claims a task, navigates its first leg, performs physical pickup/work, traverses
its delivery leg, completes or fails, releases reservations and chooses normal next work.
Unavailable navigation returns to idle/retry at the existing tick boundary; it must not
recursively exhaust the stack. Self-care can interrupt routine work and releases tickets.

Population growth uses completed capability/shelter and finite source forecasts. Founder
mode admits one real CitizenAgent; established legacy mode admits five. Initial founders
have no shelter by design; added citizens require earned capacity. No counter-only growth,
teleportation, mortality or resource creation is present.

Citizen locomotion/work animation remains shared. Civilization presentation decorates the
same live figure rig rather than creating a second agent class. Verdant hides Clockwork-only
hat/goggle/tool details and adds woodland/acorn/leaf/faerie details while preserving the
same citizen identity, task, needs, movement and animation state.

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
gates advanced traversal. Traversal construction uses ordinary costs, stages, work and
physical attachment/deployment before SurfaceNavigation receives its link.
No civilization presentation change grants links, materials, completed stages, citizens or
capabilities.

The current compatibility seam deliberately retains the production resource slot IDs
`wood`, `metal` and `mechanical_parts` so POC4.x economy/salvage behavior is not rewritten.
Clockwork presents those names directly. Verdant presents the same paced slots as Living
Fiber, Resin and Growth Spores. Likewise the shared stage IDs remain `base`, `winch` and
`launcher`, while Verdant presents Root Bed, Growth Lattice and Bloom Anchor. These aliases
are a stable presentation mapping for this milestone, not a claim of asymmetric economics.

No cleanup changes costs, durations, speed, need decay, founder count, housing/growth
rules, resource quantities or capability sequence.

## Navigation and traversal

FloorNavigation uses a four-inch A* grid with conservative rotated/padded obstacle
footprints and physically validated endpoint connectors. Narrow legal aisles have an
explicit physical connector fallback. Legacy established-room interior endpoints remain
supported; founder observers forbid entry into blocking geometry.
SurfaceNavigation joins floor paths, deployed traversal points and elevated paths. A
citizen already on a link must continue on actual deployed geometry during replanning;
construction completion cannot drop it through open space. Reverse elevated-to-floor
routes reject disconnected floor exits. No presentation code grants links or bypasses labor.

Clockwork renders the completed route as the existing grapple/cable. Verdant reads the
**same real deployment path and deployment cursor** and renders progressive living-vine
segments and an organic upper anchor. The underlying SurfaceNavigation connection remains
the one created by ConstructionSystem. Verdant reclamation is bounded deterministic visual
state only; moss, roots and fungi have no collision/navigation or resource authority.

## Settlement presentation and lifecycle

The established settlement still originates from the verified production composition.
Verdant does not delete or replace simulation-owned building parents. Existing Clockwork
presentation children are retained and hidden, then a `VerdantOverlay` is added to the same
Workshop/Depot/Housing/WorkArea node. This is deliberate: the production root retains
references to animated gears, boiler lights and other presentation nodes, and freeing them
would create stale-reference risk.

Founder-mode development remains owned by `SettlementDevelopmentSystem`. As it earns and
re-renders shelter, depot, housing and workshop modules, `VerdantDevelopmentPresentation`
observes their real `module`/`stage` metadata, recolors the produced structure and adds
organic growth appropriate to the actual construction stage. It never advances the stage or
applies the structure's gameplay effect.

## Scene contracts and remaining coupling

The single production root contains TaskCoordinator, ConstructionSystem, FloorNavigation,
SurfaceNavigation, RoomObjects, Settlement, StrategyCamera and Overlay. These fixed names
are composition contracts; runtime services are wired by that root. Existing camera rig
private focus/transform access, raw task fields, construction stage internals and scene
room/citizen fields remain bounded single-scene coupling. Public stepping/replanning and
navigation-refresh APIs remove misleading engine/private invocation contracts without
changing state authority. Splitting the root, camera API redesign and full task mutation
encapsulation are deferred, with evidence in code-review.md.

The civilization presentation adapter currently reads a small number of production scene
fields (citizen roster, construction deployment path/cursor/stage state). That is explicit
compatibility debt chosen to avoid destabilizing the verified POC4.7.2 lifecycle while the
civilization boundary is introduced. Those reads have presentation authority only.

Duplicating `CivilizationSimulation`, EconomySystem, ResourceSystem, SalvageSystem,
TaskCoordinator or navigation services remains unsafe: it would duplicate finite ledgers
and allow conflicting reservations/revisions. Two civilization **definitions** therefore do
not imply two live societies in one room. Multi-civilization coexistence requires a future
shared-world authority design rather than instantiating today's services twice.

## Verification and artifacts

Focused fixtures exercise invalid paths/configuration, accounting and lifecycle without
claiming earned integration. Smoke validates scene/configuration; canonical observes five
founders through physical settlement/traversal/growth; historical regressions preserve
POC4/45/46 and original rooms. Campaigns vary authored definitions/seeds and observe
production fixed ticks with continuous conservation, capability, population and movement
checks. Soaks measure bounded retained task/event state and honest finite exhaustion.

Civilization verification is layered:

- `civilization_definition_test.gd` validates both profiles, shared pacing slots and invalid-ID rejection;
- `civilization_visual_test.gd` loads the real main scene as Verdant and verifies settlement, citizen, UI and reclamation presentation while production-owned nodes remain alive;
- the GitHub Actions matrix runs the unchanged M2-M6/M8 production smoke for Clockwork and Verdant in both Room A and Room B.

Runner success requires process exit, explicit pass marker and no engine/script error.
Campaign reruns remove stale result files and execution failure overrides any JSON PASS.
Evidence audits cannot overwrite acceptance reports on inconsistency. The strengthened
M4/M5/M6, POC47 live and POC46 camera drivers check PNG output before declaring evidence
success; older visual/sidecar paths retain their historical behavior and do not supply
cleanup visual acceptance. Ruff covers Python only; GDScript receives parse/import,
contract and actual Godot regression coverage.

Raw outputs are ignored. Compact source-specific reports/manifests are published after
freezing verified production/harness SHA; any later executable source edit invalidates
that freeze. Verification/.gdignore prevents evidence assets from being imported as game
resources. Exact duplicate-image replacements are listed in the artifact manifest; unique
fixtures, images, seeds, failed investigations and independent repeat receipts are kept.
