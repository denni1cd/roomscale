# RoomScale architecture

POC 5 builds on accepted `8621b08`. Normal launches preserve the original society
runtime. The conflict launch composes two instance-owned society runtimes over one
finite room. Citizen IDs are globally append-only and casualties remain terminal nodes.
See [POC 5](POC5.md) for the scenario, evidence and current limitations.

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

`WorldSimulation` owns the 0.1-second accumulator, seconds and integer tick. The
primary `CivilizationSimulation._process` delegates elapsed time to that world; secondary
society nodes have no engine-driven gameplay callback. Explicit `advance`/`step` calls
also delegate to the same world clock, preserving existing observers.

Each tick advances society runtimes in scenario insertion order. Within a runtime the
existing order remains governor, one-second planner cadence, living citizens in roster
order, then that society's traversal construction. Shared contact/territory observation
and combat run afterward. Rendering updates only labels, decoration, camera and flashes.
Single-civilization conflict services stay dormant. Pause stops the production clock.

`CivilizationSimulation` now serves as the civilization runtime: instance identity,
definition, roster, needs, depot economy, development, population and strategic intent.
It holds references to the one world ResourceSystem, SalvageSystem and bundle visuals.
Its room view contains society startup anchors; world geometry/depletion is never
initialized from that view a second time. Production navigation nodes remain shared.

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
are globally allocated, node names CitizenNN and append order are explicit contracts.
A society resolves citizens by ID rather than assuming its roster index equals a global ID.
A citizen claims a task, navigates its first leg, performs physical pickup/work, traverses
its delivery leg, completes or fails, releases reservations and chooses normal next work.
Unavailable navigation returns to idle/retry at the existing tick boundary; it must not
recursively exhaust the stack. Self-care can interrupt routine work and releases tickets.

Population growth uses completed capability/shelter and finite source forecasts. Founder
mode admits one real CitizenAgent; established legacy mode admits five. Initial founders
have no shelter by design; added citizens require earned capacity. No counter-only growth,
teleportation or resource creation is present. Combat mortality is described below.

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

Independent copies of ResourceSystem, SalvageSystem or live navigation would still be
unsafe. POC 5 separates their world authority from society economies and task boards;
coexistence uses shared service references rather than duplicating the former scene.

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

## POC 5 ownership and combat boundary

`WorldSimulation` initializes sources/salvage once and owns the global citizen registry,
ID allocator, journal, TerritorySystem, CombatSystem and clock. The existing FloorNavigation
and SurfaceNavigation are the only live navigation authorities. Temporary cloned grids
remain non-authoritative placement proofs.

Each society has an owned TaskCoordinator and ConstructionSystem. Task IDs and economy
tickets are local to their owning service; citizen IDs are global. Board claims reject
foreign or dead citizens and records carry `instance_id`. Source reservations track
instance ownership inside the one aggregate finite ledger. Bundles bind both citizen ID
and instance ID; delivery rejects a different depot economy. Cancellation releases only
the owner's source quantities. Shared salvage progresses once, while each society chooses
a legal work approach. Projects use globally unique instance-prefixed IDs and shared
occupant, activity and future-footprint checks. A traversal objective can be committed
by only one society at a time; either society can use its eventual shared link.

Combat selects reachable living citizens without cargo, reserved tickets/bundles, urgent
self-care or unstable vertical position. CitizenAgent owns terminal health/life state,
physical paths and duty; CombatSystem alone authorizes damage at fixed ticks. Target
selection is distance then citizen ID. Attacks resolve in global citizen ID order, with
morale evaluated after each attack so the remaining force can retreat before a lethal
volley destroys it. This initiative convention is deterministic and is not balanced.

Death stops work and need decay, releases active tasks safely, retains the fallen node
and excludes it from living forecasts/admission calculations. IDs are never recycled;
replacement uses normal housing/reserve/stability/cooldown production rules. No other
mortality cause exists. Retreat navigates survivors to their real rally, then restores
ordinary duty. Losing commitment gets a 600-second cooldown; the current small scenario
runs one encounter, without automatic repeated wars.

Territory uses authored strategic anchors: NEUTRAL, CLAIMED, CONTESTED, CONTROLLED.
Actual arriving scouts create overlapping claims and one UNKNOWN → CONTACT → HOSTILE
relation keyed by instance IDs. The winner must remain present while all retreating
opponents physically clear attack range, then hold for ten seconds. Capture changes the
shared site record and its industrial/organic marker. It never deletes traversal links.
