# RoomScale Innovation Architecture

RoomScale innovation is problem-driven and autonomous. It is intentionally not a conventional player-selected technology tree.

## Core rule

**The room creates problems. Experience reveals problems. Technologies grant capabilities. Capabilities make civilization-specific solutions possible. Solutions change the room.**

The contracts are separated so future civilizations can be added without adding civilization-specific branches to the core simulation.

## Layers

### Problems

`innovation/problems.json` defines civilization-agnostic problem ids such as `VERTICAL_ACCESS`, `WATER_SHORTAGE`, and `LONG_HAUL_DISTANCE`.

World systems may report active problem instances through `ProblemRegistry`. A world detector must not choose or name a civilization-specific invention. For example, an inaccessible shelf reports `VERTICAL_ACCESS`; it never reports `NEEDS_GRAPPLE`.

### Capabilities

`innovation/capabilities.json` defines shared abstract capabilities. Technologies grant capabilities and solutions require them.

Capabilities may imply more general capabilities. For example, `STEAM_POWER` implies `POWER_SOURCE`, so an authored solution can require generic powered machinery without knowing which civilization-specific technology supplied the power.

### Civilization innovation catalogs

Each civilization owns one data file at:

`innovation/civilizations/<civilization_id>.json`

The file contains:

- authored technologies and the capabilities they grant;
- optional capability prerequisites for technologies;
- authored solutions;
- the shared problems each solution addresses;
- capability requirements for each solution;
- solution/research priority weights and future construction metadata.

`InnovationCatalog` loads these files by convention. `InnovationSystem` contains no Clockwork/Verdant switch statement.

### Resolver

`InnovationSystem` deterministically evaluates current problems against one civilization's catalog and current capabilities.

It can answer:

- which technologies are currently researchable;
- which solutions are already viable for a problem;
- which research candidates move the civilization toward authored solutions;
- which candidate has the highest deterministic score.

Identical state produces identical results. Future cultural/personality weights should enter as data/scoring inputs rather than civilization-specific code branches.

The resolver follows capability prerequisites backward to currently researchable
enabling technologies. A prerequisite-only invention can therefore advance a useful
solution even when it does not directly grant that solution's final requirements.
Cycles without an available entry point and unreachable prerequisite branches do not
produce research candidates. Every requirement of a scored solution must be reachable.

For each problem instance and technology, the score uses the strongest authored
solution contribution: severity × scaled solution priority × scaled technology priority
× fraction of missing capabilities advanced. Each priority is divided by its catalog
maximum (at least 1), a common scale that preserves ranking and prevents finite
authored weights from overflowing. Alternative solutions do not multiply the world's
pressure. Contributions from different problem instances accumulate in canonical
type/severity order. Scores sort in strictly descending numeric order, with technology
IDs breaking exact ties; approximate equality is not used for ordering.

Loaders validate types before normalization and publish definitions only after
structural validation succeeds. IDs and array members must be non-empty strings;
schema version must be numeric 1; priorities and construction costs must be finite
non-negative numbers; authored research work must be finite and positive. Creation
also validates all shared capability/problem references and starting capabilities.
Failed loads or system creation return diagnostics and a null runtime object.
`TEST_ROOM_SCALE_INNOVATION.ps1` runs both the original contracts and the hostile-data,
prerequisite-path, ordering, and third-civilization robustness suite.

## Combination example

Clockwork's `steam_lift` addresses vertical access and logistics problems. It requires:

- `CABLE_ENGINEERING`;
- `POWER_SOURCE`;
- `LOAD_BEARING_FRAMES`.

Those capabilities can be assembled through multiple technologies. In the initial Clockwork catalog, grapple engineering supplies cable engineering, steam power satisfies the generic power source requirement, and structural engineering supplies load-bearing frames. The lift becomes viable only after the combination exists.

Verdant receives the same `VERTICAL_ACCESS` world problem but has authored biological solutions instead, such as a climbing vine or climbing tree.

## Adding another civilization

A new civilization should normally require:

1. Its existing `civilizations/<id>.json` presentation definition.
2. A new `innovation/civilizations/<id>.json` innovation catalog.
3. New shared problem or capability definitions only when the concept truly is general and does not already exist.
4. Civilization-specific visuals/behavior for its authored solutions when those solutions are integrated into the physical simulation.

Adding a civilization must not require editing `InnovationSystem` merely to recognize its id.

## Live production integration

Opt in with `RUN_ROOM_SCALE_FISHBOWL.ps1 -Innovation`. Each society owns an
`InnovationRuntime` and resolver. The world detector groups valuable inaccessible
sources into generic `VERTICAL_ACCESS` observations; it has no catalog or civilization
knowledge. A manual elevated-surface request reports the same problem.

Citizens first earn the ordinary workshop. The live service filters research to
solutions with implemented deployment adapters, follows capability prerequisites,
and issues research jobs at that workshop through the existing task board and planner.
Technology completes only after actual citizen work. Clockwork researches grapple
engineering, Verdant cultivates vines, and Scavenger completes a three-invention chain.

A viable solution reserves a shared region claim and a connected legal floor site.
Materials are reserved in the society's economy, picked up at its depot and physically
carried to the site. Mechanical parts are fabricated at the depot using one reserved
metal and twelve citizen work seconds per part. Construction uses the catalog's labor
requirement; only completion consumes delivered tickets and registers a real shared
surface-navigation link. Citizens use that link to reach elevated resources.

Only live, owned, active task records and workers in their native production WORK
callback may apply effort. Work is bounded to the fixed step and accepted at most once
per actor per world tick. Pause freezes research, hauling and construction. Urgent
self-care can interrupt innovation tasks normally. Cancelled projects release claims,
return reservations, drop carried materials normally and recover delivered materials as
physical bundles at the site; they do not grant a link. Settlement planning preserves
innovation sites across societies. A completed shared route clears other societies'
access problems without granting them the builder's knowledge.

HUD project/progress cards, journal notifications and camera focus consume live state.
Conflict mode includes each society's current innovation activity in its shared HUD.
`TEST_ROOM_SCALE_INNOVATION_LIVE.ps1` exercises three production catalogs twice,
including paid construction, traversal, pause and rejected forged work; its
`-CancellationProbe` variant verifies physical recovery and successful retry.

## Supported deployment boundary

The live slice detects vertical access and insufficient shelter. It implements
`climb_route` (cable/vine/rope) and `living_structure` (tree with real shelter). `deployment` is optional catalog metadata; entries without it
remain resolver examples and are excluded from live research. Unknown physical classes
are excluded; invalid properties on a registered adapter fail live startup. Authored
live solutions require finite positive construction work and supported resource costs.
Catalogs may also be loaded through an explicit validated `innovation_catalog_path`.

The route climbs from a legal floor base to the real furniture edge, then lies on
the supported surface. Exact segment tests reject intersections with rotated furniture
volumes. It is visible, progressively constructed geometry and a bounded kinematic path.
It does not simulate structural loading, cable sag, growth biology or powered lift
operation. Automatic water/logistics detectors, fuel-consuming lifts, bridges,
reservoirs and route upgrades remain additional adapters; their catalog capabilities
and dependency composition are covered by foundation tests. Legacy launches retain
the accepted workshop/grapple progression when innovation is disabled.

## POC 5.3 stabilization contracts

### Global construction selection

`solution_candidates` ranks all recognized active pressures against all viable,
registered physical classes. It keeps the maximum severity per generic problem type;
additional sources/detectors of the same type do not multiply construction priority.
A candidate score sums `severity × priority / common_max_priority` across distinct
addressed types. Stable solution IDs break exact ties. Representatives use greatest
severity then source ID; types and contributions have canonical order. The scale
bounds finite priorities without changing ranking. Unsupported adapters are excluded.
The runtime walks this ranking for a physically legal, connected, unclaimed plan and
starts one project. It does not choose the first problem in the registry. Existing
research scoring still accumulates distinct source instances, as the earlier documented
experience-pressure mechanic; alternative inventions contribute their strongest value.
Active work is not automatically preempted solely because another severity changes.

### Experience and recognition

Detectors return generic evidence through `WorldProblemDetector.observe`, currently
vertical access and insufficient shelter. `ProblemRegistry.observe_batch` receives
one batch at each five-second production-clock observation. Strength defaults to 0.35;
awareness saturates at 1.0 after three ordinary observations. Absence is UNSEEN,
then EMERGING and RECOGNIZED. Count, first/last observation, awareness, severity and
recognition time remain inspectable. Contributions/context are sorted before folding;
repeating the same batch at the same time is inert. Solved/disappeared instances are
removed; reappearance begins fresh evidence. Manual elevated targets supply strength
1.0. The legacy `set_problem` API is an explicit authoritative recognized report,
retained for contracts/integrators. The resolver skips explicit EMERGING instances.
Recognition grants no technology, resources, work or link.

### Physical adapter boundary

`innovation/deployment_adapters.json` maps generic adapter IDs to implementations.
`DeploymentAdapterRegistry` validates and instantiates them; runtime code has no
adapter-ID switch. Each adapter supplies:

- `supports(solution)`: validate its own authored properties;
- `prepare(sim, solution, problem)`: pure planning returning a legal work target,
  site, stable exclusive claim key and opaque deployment payload;
- `status(sim, project)`: target validity/redundancy;
- `render(root, project, fraction, color)`: presentation only;
- `finish(sim, project)`: atomic domain effect after full delivered cost and labor;
- optional `advance(sim, project, delta)`: persistent effects on each fixed production
  tick, including pause behavior.

The runtime owns materials, citizen jobs, effort, claims, cancellation and completion.
Adapters own geometry, target-specific validity and domain effects. Before completion,
planning/rendering must not mutate domain state, so generic cancellation can release
claims/jobs/tickets and recover physical material without adapter-specific rollback.
Adapters must keep completion effects idempotent. Required API shape and behavior are
an in-repository trusted-code contract, not a sandbox for arbitrary scripts.

`climb_route` wraps the existing cable/vine/rope path. `living_structure` builds a
permanent climb structure and applies authored integer `shelter_capacity` once to
its owner's real needs/population-admission capacity. It can use an already-shared
route and cannot stack another structure/benefit at the same region across societies.
The authored Verdant tree adds four shelter places, after its larger bill and labor.
Throughput, maintenance and operating-cost catalog fields remain metadata.

### Resource and recipe boundary

`ResourceVocabulary` is the single canonical material authority shared by catalogs,
economy and world resources. Current IDs remain food, water, wood, metal and
mechanical_parts. Innovation projects iterate the authored bill, excluding `work`;
food/water construction and a non-navigation adapter are tested through actual jobs.
Unknown materials are rejected rather than silently discarded by the catalog loader.
Presentation aliases such as resin/fiber do not create new canonical resources.
A genuinely new material requires extending the economy/resource authority and its
supply/presentation contract, but no innovation-resolver/material-loop change.

`production_recipes` is an explicit catalog opt-in list. Recipes in
`innovation/production_recipes.json` describe one input, one output, finite positive
quantities/work and workshop eligibility. Shipped catalogs opt into `metal_parts`;
another catalog can omit it. The generic recipe service performs the depot transform
only through real owned citizen work and reserved input. Outputs are preflighted before
consuming input, including finite ledger/bundle capacity. Recipe jobs belong to their
project and cancel normally. Recipe chains, multiple simultaneous inputs, arbitrary
exotic material systems and world resource generators are not implemented.
