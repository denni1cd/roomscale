# RoomScale POC 4.5 — Autonomous Colony / Fishbowl Mode

## 1. Purpose

RoomScale POC 4 proved that a tiny civilization can possess real needs, gather finite resources, salvage ordinary room objects, haul materials, construct traversal infrastructure, and recover from a resource crisis while the player acts only at the civilization level.

POC 4.5 exists to answer the next experiential question:

> **Can RoomScale become something worth leaving running simply to watch an autonomous tiny civilization survive, expand, construct a visibly larger settlement, and adapt to the finite human-scale room around it without requiring player intervention?**

The target experience is a **fishbowl / aquarium mode**:

- launch RoomScale;
- the civilization governs itself;
- citizens continue using the same production simulation and task systems;
- settlement buildings appear through real construction;
- population grows when the colony can support it;
- resource pressure changes civilization priorities;
- ordinary room objects are selectively salvaged when necessary;
- the physical settlement becomes visibly larger over time;
- an automatic camera director follows interesting activity;
- an event feed explains what the civilization is doing and why;
- the user may simply watch.

POC 4.5 is an **extension of POC 4**, not a replacement architecture and not a new game mode implemented through cheats.

The core loop is:

**needs create pressure → autonomous governor sets civilization priorities/directives → citizens perform ordinary production work → resources are acquired and transformed → settlement infrastructure expands → spare capacity permits population growth → larger population creates new pressure → the cycle continues**

---

## 2. Central POC Question

The primary question is:

> Is it compelling to watch a RoomScale civilization autonomously grow from a small settlement into a visibly larger colony while surviving through the same needs, economy, navigation, salvage, hauling, and construction systems available in normal gameplay?

Success is not defined merely by surviving indefinitely.

The simulation should create **visible history**:

- new structures;
- changed room objects;
- larger population;
- shifting activity centers;
- new infrastructure;
- resource depletion;
- recurring crises and recoveries;
- a settlement that looks materially different after many simulated days.

---

## 3. Relationship to Existing POCs

POC 4.5 starts from the verified POC 4 implementation.

The following remain authoritative production systems:

- citizen movement and task execution;
- `NeedSystem`;
- `EconomySystem`;
- `ResourceSystem`;
- `SalvageSystem`;
- `CivilizationPlanner`;
- `CivilizationSimulation`;
- navigation and surface navigation;
- Reach / Explore;
- traversal construction;
- resource bundles and hauling;
- RoomDefinition;
- existing procedural presentation.

POC 4.5 must **extend these systems rather than bypass them**.

Normal POC 4/manual gameplay must remain available.

Fishbowl mode may automatically use high-level actions that are normally player-controlled, but those actions must pass through the same generalized interfaces and authorization rules.

---

## 4. Core Design Principle

The civilization governs itself at the **same strategic layer normally occupied by the player**.

The autonomous governor may:

- change civilization priority categories;
- issue existing generalized resource directives;
- authorize safe salvage under fishbowl policy;
- request settlement development projects;
- permit population growth when capacity and reserves allow it.

The autonomous governor must **not**:

- directly move citizens;
- directly assign individual workers;
- teleport citizens or materials;
- create stock from nothing;
- complete construction instantly;
- bypass traversal;
- silently alter needs;
- bypass resource accounting;
- override physical reachability;
- use runtime LLM calls.

Conceptually:

`world state + needs + reserves + infrastructure + policy → governor decision → existing high-level civilization interface → ordinary citizen work`

---

## 5. Fishbowl Mode

Add a distinct launch path for autonomous viewing.

Recommended command:

```powershell
./RUN_ROOM_SCALE_FISHBOWL.ps1
```

Fishbowl mode should:

- launch the canonical POC 4.5 room/configuration;
- enable autonomous governor behavior immediately;
- require no clicks to begin progression;
- preserve speed controls;
- enable the automatic camera director by default;
- show the fishbowl event feed;
- retain citizen/object inspection where practical;
- allow the governor/camera director to be toggled if convenient.

The ordinary RoomScale launch must not silently become fully autonomous.

---

## 6. No Required Player Intervention

A complete fishbowl run must succeed from startup without player input.

The user must not need to:

- issue Secure Water;
- issue Secure Food;
- manually change priorities;
- choose salvage objects;
- authorize salvage;
- select construction locations;
- create housing;
- admit new citizens;
- route citizens;
- select workers;
- recover deadlocked tasks.

The user may still use camera/speed/inspection controls while watching.

---

## 7. Autonomous Governor

Create a deterministic `AutonomousGovernor` or equivalent production system.

It should evaluate civilization state periodically rather than every rendered frame.

Inputs should include at least:

- food reserve and forecast;
- water reserve and forecast;
- urgent citizen count;
- shelter capacity and occupancy;
- current population;
- wood and metal inventory;
- known finite sources;
- source reachability;
- active traversal project;
- active settlement development projects;
- authorized salvage candidates;
- current settlement development capacity;
- population growth cooldown/state.

Outputs should use existing/generalized high-level interfaces.

---

## 8. Governor Priority Rules

The governor should be understandable and deterministic.

A recommended initial hierarchy is:

### Emergency survival

If food or water forecast falls below a critical threshold:

- Survival becomes Critical;
- the relevant resource directive is activated;
- expansion/development priorities are reduced;
- the civilization focuses on restoring supply.

### Material shortage

If an approved survival or development project is blocked by wood/metal:

- Resource Acquisition increases;
- the governor searches for safe salvage candidates;
- a suitable object may be authorized according to fishbowl salvage policy.

### Shelter pressure

If occupancy approaches shelter capacity and survival reserves are healthy:

- Construction becomes High/Critical;
- an additional housing project is requested.

### Stable growth

If survival reserves, shelter headroom, and infrastructure are healthy for a sustained period:

- a new population cohort may join the settlement.

### Development

If the colony is stable and no urgent crisis exists:

- the governor may construct a useful non-housing settlement module or maintain normal exploration/activity.

Exact thresholds are implementation constants and should be documented/testable.

---

## 9. Governor Hysteresis and Anti-Thrashing

The governor must not oscillate priorities every second.

Use simple hysteresis/cooldowns such as:

- a priority minimum hold time;
- different enter/exit thresholds for shortages;
- project cooldowns;
- population-growth cooldowns;
- salvage authorization only when there is a demonstrated resource requirement or strategic reason.

The event feed should not spam repeated identical decisions.

---

## 10. Fishbowl Salvage Policy

POC 4 requires explicit player authorization for destructive salvage.

Fishbowl mode may provide an **explicit autonomous salvage policy** that acts as the civilization-level authorizer.

This policy is enabled only for autonomous mode.

A candidate salvage object must be rejected if it:

- is already depleted;
- supports a currently required resource source;
- supports active traversal/infrastructure;
- is itself settlement infrastructure;
- is inaccessible to real workers;
- would immediately invalidate the current critical objective;
- is explicitly protected by data/policy;
- has insufficient useful yield for the current shortage when a better safe candidate exists.

Candidate selection should prefer a deterministic score using factors such as:

- needed resource yield;
- distance from settlement/depot;
- destructive cost;
- accessibility;
- whether the object has strategic surface value.

No canonical object ID should be required.

---

## 11. Population Growth Model

POC 4.5 introduces **abstract population growth**, not families/reproduction simulation.

The fiction may be described neutrally as a new cohort joining the settlement.

Do not model:

- pregnancy;
- births;
- child citizens;
- family trees;
- relationships;
- aging;
- immigration characters with external origin simulation.

Population growth exists only to create increasing economic and settlement pressure.

---

## 12. Population Growth Conditions

A population cohort may be added only when all required conditions are true for a sustained period.

Recommended minimum conditions:

- food forecast at or above a healthy threshold;
- water forecast at or above a healthy threshold;
- shelter capacity exceeds current population by at least the cohort size;
- urgent citizen count is low;
- no unresolved survival emergency;
- no critical material deadlock;
- growth cooldown expired.

Recommended starting cohort size:

**5 citizens**

Recommended hard POC safety cap:

**150 citizens**

The exact cap may be reduced if profiling demonstrates a real performance limitation.

The cap must be explicit, not silently reached because spawning stops working.

---

## 13. Population Growth Behavior

New citizens must be real production citizen entities.

They must:

- spawn at a valid settlement arrival/spawn area;
- receive real need state;
- participate in the same task coordinator;
- consume food/water;
- rest;
- move normally;
- haul/build/salvage/collect like existing citizens;
- appear in population and inspection UI;
- affect demand/forecast immediately.

Do not model population growth by incrementing only a numeric counter.

---

## 14. Settlement Growth

The settlement itself must visibly expand.

POC 4.5 should support at least two functional development module types and may include one additional decorative/utility type if cheap.

Required modules:

### Housing Block

Purpose:

- increases shelter capacity;
- enables future population cohorts;
- creates a visible new building/module.

### Workshop Annex

Purpose:

- visibly expands the industrial settlement;
- provides a modest systemic benefit, such as increasing safe concurrent construction/salvage labor capacity or reducing construction work time within a conservative bound.

Optional module:

### Storehouse / Utility Building

Possible simple effect:

- raises desired reserve target;
- improves resource-buffer behavior;
- provides visible storage infrastructure.

Do not introduce a large production-chain system.

---

## 15. Development Project Lifecycle

Settlement development must use real project lifecycle state.

Conceptually:

`PLANNED → WAITING_FOR_MATERIALS → SUPPLIED → UNDER_CONSTRUCTION → COMPLETE`

A development project should contain:

- project ID;
- module type;
- chosen build location;
- resource requirements;
- delivered resources;
- construction work required;
- current stage/progress;
- resulting systemic effect;
- visible construction state.

Projects must not complete by timer unless workers are actually performing the required work.

---

## 16. Settlement Construction Architecture

Do not replace the existing traversal construction implementation merely to support housing.

A small `SettlementDevelopmentSystem` / `SettlementConstructionSystem` may own settlement projects while reusing:

- economy reservations;
- bundle/material hauling;
- citizen construction work;
- navigation;
- task scoring;
- construction presentation conventions.

If a small generalized construction abstraction cleanly supports both traversal and development without destabilizing POC 4, that is acceptable.

A broad rewrite of `ConstructionSystem` is not required for POC 4.5.

---

## 17. Real Development Materials

Housing/workshop projects must consume real materials from the civilization economy.

At minimum they should require:

- wood;
- metal where appropriate.

Materials must pass through existing accounting states sufficiently to prevent duplication.

A new building must not appear because the governor requested it while resources were unavailable.

---

## 18. Real Development Work

Citizens must physically reach the build site and perform construction work.

Required sequence:

**project requested → materials reserved/acquired → materials physically delivered → builders travel to site → visible construction progresses → building completes → effect becomes active**

No instant structure creation.

---

## 19. Settlement Build-Site Selection

The autonomous settlement needs a generalized method for finding valid construction sites.

Preferred approach:

- derive a settlement center from existing settlement landmarks/structures;
- search outward through candidate positions/rings;
- require room-bound validity;
- require floor accessibility;
- reject overlap with room objects;
- reject overlap with existing settlement structures;
- reject active traversal/construction space;
- preserve useful passage width where practical;
- choose the best candidate deterministically.

Room-specific fixed housing coordinates should not be required.

A room definition may optionally expose a broad settlement-development zone in the future, but POC 4.5 should remain usable from existing settlement landmark data where practical.

---

## 20. Navigation and New Buildings

Completed development structures must update world navigation appropriately.

If a structure blocks floor movement:

- it must become an obstacle;
- routes must adapt;
- citizens must not walk through it.

Construction stages should not permanently corrupt navigation if a project is abandoned/rejected.

Buildings should not trap the settlement by blocking every route from the depot/housing/workshop area.

---

## 21. Visible Construction Stages

Each required module should have simple predetermined visual stages.

Example:

`FOUNDATION → FRAME → SHELL → COMPLETE`

POC 4.5 does not require:

- free-form building placement;
- voxel construction;
- physics-based assembly;
- detailed interiors;
- furniture inside houses.

The visual goal is for a viewer to clearly see a structure being built and later recognize that the settlement has grown.

---

## 22. Settlement History

The room should accumulate visible history during the session.

Examples:

- depleted chair;
- partially salvaged furniture;
- original settlement;
- additional housing blocks;
- workshop annex;
- traversal route;
- increased citizen activity;
- new district/path clusters.

After many simulated days, the world should not look identical to startup.

---

## 23. Resource Limits and Carrying Capacity

POC 4.5 intentionally keeps finite resources.

Do not make food, water, wood, or metal infinite merely so the fishbowl can run forever.

The room should have a practical carrying capacity.

The autonomous governor should slow or halt population growth when:

- reserves cannot remain healthy;
- safe salvage opportunities diminish;
- shelter expansion cannot be funded;
- critical sources are exhausted;
- the population cap is reached.

A mature fishbowl may therefore stabilize instead of expanding indefinitely.

That is a valid and desirable outcome.

---

## 24. Canonical POC 4.5 Room

POC 4.5 should use a canonical room derived from the existing POC 4 room rather than discarding it.

The room should provide enough finite resources for visible development over many simulated days.

It may adjust/add generalized resource metadata or additional ordinary room objects if needed to support the fishbowl duration.

Avoid hidden special stockpiles that exist only to make tests pass.

The room must still visibly behave as a room whose contents are being transformed by tiny inhabitants.

---

## 25. Canonical Fishbowl Sequence

A representative autonomous run should look approximately like this:

1. 50 citizens begin in the existing settlement.
2. Needs start consuming food/water.
3. Governor recognizes the water problem.
4. Governor raises survival priority and issues Secure Water.
5. Elevated water requires traversal.
6. Traversal project becomes blocked by materials.
7. Governor identifies and authorizes a safe salvage candidate.
8. Citizens dismantle/haul/build through the existing POC 4 chain.
9. Water access is established and reserves recover.
10. Governor returns priorities toward stable development.
11. Shelter capacity is at/near population capacity.
12. Governor requests a housing block.
13. Materials are obtained from safe room salvage.
14. Citizens deliver resources and construct the housing block visibly.
15. Shelter capacity increases.
16. Healthy reserves persist through the configured growth stability window.
17. A cohort of new citizens joins.
18. Population demand increases.
19. Governor responds to new resource/shelter pressure.
20. Additional settlement modules appear over subsequent days.
21. The settlement becomes visibly larger while the room shows persistent resource depletion.
22. Growth eventually slows/stabilizes when room capacity or configured population cap is approached.

No step requires player input.

---

## 26. Initial Growth Targets

The exact final population is emergent and should not be hard-coded as a scripted ending.

However, the canonical room should be balanced so that a normal verified fishbowl run can demonstrate meaningful growth.

Target expectations:

- starts at **50 citizens**;
- reaches at least **65 citizens** in the standard autonomous scenario;
- constructs at least **2 new housing blocks**;
- completes at least **1 non-housing development module**;
- performs at least one autonomous salvage authorization after the initial water crisis;
- visibly changes multiple room/settlement elements.

A longer stability run should normally grow farther unless finite resources or deliberate governor safety rules stop it.

---

## 27. Event Journal

Create a bounded structured event journal.

Important event types should include:

- resource reserve becoming low/critical;
- governor priority change;
- directive issued;
- salvage authorized;
- salvage object depleted;
- traversal project created/completed;
- development project created;
- development materials supplied;
- development project completed;
- shelter capacity increased;
- population cohort joined;
- population growth paused and reason;
- source exhausted;
- civilization stabilized.

The journal should retain a bounded history and avoid duplicate spam.

---

## 28. Fishbowl Event Feed UI

Display recent meaningful events on screen.

The event feed should be understandable without opening debug diagnostics.

Example:

```text
Day 2.1 — Water reserve critical
Day 2.1 — Governor: Survival → Critical
Day 2.2 — Secure Water objective started
Day 2.8 — Chair authorized for salvage
Day 4.5 — Housing Block 01 started
Day 5.3 — Housing Block 01 complete (+10 shelter)
Day 7.4 — New cohort joined (+5 citizens)
```

Do not flood the feed with every meal, path waypoint, or task assignment.

---

## 29. Automatic Camera Director

Fishbowl mode should include a deterministic automatic camera director.

The director should use production state/events rather than a scripted timeline.

It may choose among views such as:

- wide room overview;
- settlement overview;
- active salvage site;
- material hauling activity;
- active development construction;
- newly completed building;
- traversal construction;
- resource expedition/climb;
- newly arrived population cohort.

The camera must not change simulation state.

---

## 30. Camera Behavior

Camera movement should be watchable rather than frantic.

Recommended behavior:

- stay on a shot for a minimum real-time duration;
- prefer important new events;
- otherwise rotate through useful overview/activity views;
- use smooth transitions where existing camera rig permits;
- periodically return to a wide settlement/room view;
- avoid switching for repetitive minor events.

The user should be able to disable automatic camera control and use ordinary camera controls.

---

## 31. Fishbowl HUD

The fishbowl HUD should prioritize watchability.

At minimum display:

- day/time;
- population;
- shelter capacity;
- food days;
- water days;
- wood;
- metal;
- current governor mode/reason;
- active strategic objective;
- active development project;
- recent event feed;
- simulation speed;
- autonomous governor state.

The existing detailed inspection/debug UI may remain available separately.

---

## 32. Simulation Speed

Retain:

- Pause;
- 1x;
- 4x;
- 10x.

A higher fishbowl-only speed such as 20x/25x may be added if profiling demonstrates stable behavior, but it is not required for acceptance.

All speeds must advance the same fixed-step authoritative simulation.

Do not skip work or needs merely because the simulation is accelerated.

---

## 33. Performance Target

The simulation begins with approximately 50 citizens and may grow substantially.

Target:

- maintain acceptable interactive performance through at least **100 active citizens** on the target machine;
- do not fail solely because population grows beyond the original POC 4 value;
- governor planning and development planning must not run every rendered frame;
- avoid O(population × all-world-state) work at high frequency when simpler indexing/batching is practical.

If profiling shows a real threshold below the requested 150 cap, document the measured limitation and choose a conservative explicit cap.

---

## 34. Determinism

Core simulation decisions remain deterministic game logic.

No runtime LLM calls.

If randomness is used for visual variety or equivalent site choices:

- it must be seeded;
- test mode must be reproducible;
- different seeds must not bypass rules.

The governor's reasons should be inspectable.

---

## 35. Normal Mode Preservation

POC 4 manual strategic gameplay must continue to work.

Fishbowl mode must not force autonomous salvage or autonomous population growth in ordinary manual mode unless explicitly enabled.

Regression should verify:

- normal POC 4 launch still allows player priorities/directives;
- protected salvage still requires manual authorization in normal mode;
- no autonomous population growth occurs when fishbowl governor is disabled;
- existing traversal scenario remains operational.

---

## 36. Long-Run Stability

Fishbowl mode is specifically intended to run for long periods.

Add long-run verification beyond the POC 4 thirty-day check.

Required final stability run:

**60 simulated days**

Verify at least:

- finite needs remain valid;
- resource accounting remains conserved;
- sources do not duplicate/refill unexpectedly;
- salvage yields remain once-only;
- development costs are conserved;
- population count equals actual citizen entities;
- shelter capacity matches completed housing effects;
- growth obeys configured cohort/cooldown/cap rules;
- task history remains bounded;
- event history remains bounded;
- completed projects do not regenerate;
- no stuck permanent active project;
- no navigation corruption after multiple new buildings;
- no citizen position/need corruption;
- no unbounded object/bundle/ticket growth;
- governor does not thrash continuously;
- simulation remains capable of reaching a stable state when further growth is unsafe.

---

## 37. Repeatability

The complete autonomous fishbowl scenario must pass **at least 3 consecutive fresh runs**.

Each run should continue long enough to demonstrate:

- autonomous recovery from the initial water crisis;
- autonomous settlement development;
- at least one population cohort;
- continued operation after growth.

If runtime cost remains modest, five consecutive runs are preferred.

---

## 38. Fast Test Layer

Add deterministic fast tests for:

### Governor

- critical water chooses survival action;
- critical food chooses food action;
- healthy reserves do not repeatedly issue emergency directives;
- material shortage selects resource acquisition;
- safe salvage candidate ranking;
- unsafe/critical object rejection;
- hysteresis/cooldowns;
- development suppression during crisis.

### Population

- growth blocked without shelter;
- growth blocked with unhealthy reserves;
- growth succeeds with stable reserves/capacity;
- cohort size correct;
- real citizens created;
- demand/forecast changes immediately;
- population cap respected.

### Development

- valid build-site selection;
- collision/object overlap rejection;
- material reservation/delivery;
- construction stages;
- completed housing increases shelter exactly once;
- workshop effect applies exactly once;
- completed building updates navigation;
- failed project does not leak obstacle/navigation state.

### Event journal / camera

- duplicate event suppression;
- bounded event history;
- important event classification;
- camera director chooses valid focus and never changes simulation state.

---

## 39. Full Production Scenario Test

Create an automated fishbowl scenario that uses the production scene and production systems.

The test may enable fishbowl mode automatically, but must not manually issue each expected decision.

The test should observe the governor making decisions from world state.

It must verify at least:

1. 50 real citizens initialize;
2. governor is enabled;
3. needs consume real stock;
4. governor detects initial water risk;
5. Secure Water is autonomously issued;
6. traversal requirement is discovered;
7. materials become a real blocker;
8. safe salvage is autonomously authorized;
9. staged salvage/hauling occurs;
10. traversal completes;
11. water access/recovery occurs;
12. housing pressure is recognized;
13. housing project is autonomously created;
14. real materials are supplied;
15. real builders complete housing;
16. shelter capacity increases exactly once;
17. population cohort joins automatically;
18. new citizens have real needs/tasks;
19. demand rises with population;
20. at least one additional development/salvage response occurs;
21. settlement remains operational after growth.

No test-side stock injection or forced decision sequence.

---

## 40. Visual Verification

Capture useful real production screenshots/video-frame equivalents where practical.

Required screenshot checkpoints should include:

- initial settlement;
- autonomous water crisis response;
- autonomous salvage authorization/work;
- post-water-recovery settlement;
- first housing project planned/under construction;
- housing frame/shell stage;
- completed housing block;
- population after first cohort;
- multiple completed development structures;
- later settlement overview showing visible growth;
- altered/depleted room objects;
- mature fishbowl state.

The user should not be required to capture these manually.

---

## 41. Event/Decision Evidence

The verification artifacts should retain enough information to reconstruct why major autonomous decisions occurred.

For each major governor decision, log at least:

- simulation time/day;
- triggering condition;
- relevant reserve/capacity values;
- action selected;
- candidate object/project if applicable;
- reason for rejection of unsafe alternatives where useful.

This is important because fishbowl mode can otherwise appear arbitrary.

---

## 42. Architecture Recommendations

Recommended additions:

### `AutonomousGovernor`

Owns deterministic civilization-level strategic decisions.

### `PopulationSystem`

Owns cohort eligibility/cooldowns/cap and production citizen creation.

### `SettlementDevelopmentSystem`

Owns module blueprints, site selection, development project lifecycle, effects, and visible build stages.

### `EventJournal`

Owns bounded meaningful civilization events.

### `FishbowlCameraDirector`

Chooses camera targets from production events/state without changing simulation state.

These exact class names are not mandatory.

Avoid combining every fishbowl responsibility into `CivilizationSimulation`.

---

## 43. Data and Configuration

Fishbowl behavior should be configurable through generalized data/constants rather than canonical-room IDs.

Useful configuration may include:

- governor enabled;
- cohort size;
- population cap;
- healthy/critical reserve thresholds;
- growth stability duration;
- growth cooldown;
- development module costs/effects;
- fishbowl salvage policy;
- camera-director enabled;
- event-history limit.

Do not expose a giant tuning schema merely for this POC.

Keep the contract inspectable and conservative.

---

## 44. Milestones

### Milestone 0 — POC 4 Baseline Gate

Run current POC 4 fast/full regression and establish known-good evidence before fishbowl changes.

**Exit condition:** verified POC 4 baseline remains green.

### Milestone 1 — Event Journal and Governor Skeleton

Add bounded events and deterministic governor state/reasoning without yet growing the settlement.

**Exit condition:** governor correctly changes priorities/directives from simulated conditions and logs meaningful decisions.

### Milestone 2 — Autonomous Survival

Enable fishbowl policy to autonomously solve the existing POC 4 water crisis, including safe salvage authorization.

**Exit condition:** canonical POC 4 crisis completes with zero user input through production systems.

### Milestone 3 — Settlement Development Projects

Add generalized development module definitions, site selection, material gates, hauling, construction work, visual stages, and completed effects.

**Exit condition:** at least one housing block is built autonomously from real materials and visibly persists.

### Milestone 4 — Population Growth

Add cohort eligibility, real citizen spawning, increased consumption and capacity checks.

**Exit condition:** settlement grows above 50 real citizens only after satisfying survival/capacity rules.

### Milestone 5 — Sustained Growth Loop

Governor alternates survival/resource/development behavior as population grows.

**Exit condition:** autonomous run reaches at least 65 citizens and at least three total new settlement modules without intervention.

### Milestone 6 — Fishbowl Presentation

Add launch script, watchable HUD, event feed and camera director.

**Exit condition:** user can launch one command and watch meaningful autonomous activity without interacting.

### Milestone 7 — Repeatability and Long-Run Stability

Run repeated autonomous scenarios and sixty-day stability.

**Exit condition:** no resource duplication, task/project leak, navigation corruption or uncontrolled governor thrashing.

### Milestone 8 — Documentation and Final Verification

Finalize usage, limits, acceptance matrix, screenshots/logs and progress records.

**Exit condition:** another session can understand, launch, test and extend fishbowl mode from repository documentation alone.

---

# 45. Acceptance Criteria

### AC-1 — POC 4 Regression
Existing POC 4 manual gameplay/tests remain functional.

### AC-2 — Dedicated Fishbowl Launch
A one-command fishbowl launch exists and starts autonomous mode.

### AC-3 — Zero Required Input
The canonical fishbowl run progresses without any player action.

### AC-4 — Deterministic Governor
Civilization-level autonomous decisions are deterministic production game logic, not runtime LLM behavior.

### AC-5 — Existing Strategic Interfaces Reused
Governor uses generalized priorities/directives/authorization/development requests rather than directly controlling citizens.

### AC-6 — Water Crisis Recognized
Governor detects the canonical starting water risk.

### AC-7 — Secure Water Issued Automatically
The governor autonomously starts the appropriate resource objective.

### AC-8 — Existing Traversal Reused
Water access still depends on the production Reach/barrier/construction/traversal systems.

### AC-9 — Material Blocker Recognized
Governor understands when traversal/development is blocked by wood/metal.

### AC-10 — Autonomous Safe Salvage
Fishbowl policy can authorize an appropriate safe salvage object.

### AC-11 — Unsafe Salvage Rejected
Critical/resource-support/infrastructure/protected candidates are not destructively authorized.

### AC-12 — Salvage Remains Real
Citizens physically perform once-only staged salvage work.

### AC-13 — Hauling Remains Real
Harvested materials are physically transported and accounted for.

### AC-14 — Initial Survival Recovery
The autonomous civilization reaches and stores water without user intervention.

### AC-15 — Governor Hysteresis
Priority/directive behavior does not continuously thrash around thresholds.

### AC-16 — Bounded Governor Frequency
Strategic planning is periodic/event-driven rather than per-frame.

### AC-17 — Development Module System
Generalized settlement module definitions exist.

### AC-18 — Housing Module
A completed housing block visibly exists and increases shelter capacity.

### AC-19 — Non-Housing Module
At least one functional non-housing module exists and completes through the same development framework.

### AC-20 — Development Site Derived
Build sites are selected from world/navigation state rather than fixed canonical coordinates.

### AC-21 — Site Collision Safety
Development rejects invalid overlap with room objects or existing structures.

### AC-22 — Real Development Materials
Settlement projects consume actual wood/metal through conserved accounting.

### AC-23 — Real Development Hauling
Project materials reach the construction site through real citizen movement.

### AC-24 — Real Development Work
Citizens physically perform construction work before completion.

### AC-25 — Visible Build Stages
At least housing and workshop construction have visibly distinct intermediate stages.

### AC-26 — Persistent New Structures
Completed settlement buildings remain for the session.

### AC-27 — Navigation Updated
Completed structures affect navigation when their footprint requires it.

### AC-28 — Failed Project Safety
Rejected/failed site creation does not leak navigation/obstacle state.

### AC-29 — Growth Requires Capacity
Population cannot increase without sufficient shelter headroom.

### AC-30 — Growth Requires Healthy Survival State
Population cannot increase while food/water state is unsafe.

### AC-31 — Real Cohort Citizens
A growth event creates real citizen entities with ordinary needs/tasks.

### AC-32 — Demand Changes with Population
Food/water demand/forecast changes immediately when population grows.

### AC-33 — Growth Cooldown
Repeated cohorts obey a documented cooldown/stability window.

### AC-34 — Population Cap
Configured hard population cap is respected.

### AC-35 — Meaningful Growth
Canonical autonomous scenario reaches at least 65 citizens.

### AC-36 — Multiple New Structures
Canonical scenario completes at least two housing blocks and one non-housing module.

### AC-37 — Visible Settlement Change
Late-game settlement overview is materially different from startup.

### AC-38 — Finite Room Resources
Sources/salvage remain finite; fishbowl mode does not create infinite hidden resources.

### AC-39 — Growth Can Stabilize
Governor can stop/slow population growth when carrying capacity becomes unsafe.

### AC-40 — Event Journal
Meaningful civilization events are retained in a bounded journal.

### AC-41 — Event Feed
Fishbowl HUD shows recent major events/reasons.

### AC-42 — Camera Director
Autonomous camera follows meaningful activity without changing simulation state.

### AC-43 — Camera Can Be Disabled
User can return to normal manual camera behavior.

### AC-44 — Watchable HUD
Population, reserves, shelter, governor state, objective, development and speed are visible.

### AC-45 — Existing Speed Controls
Pause/1x/4x/10x operate the authoritative fixed-step simulation.

### AC-46 — 100-Citizen Operation
Simulation remains functionally stable with at least 100 active citizens in a test or canonical long run.

### AC-47 — Fast Fishbowl Tests
Deterministic governor/population/development/event tests exist and pass.

### AC-48 — Production-Code Full Scenario
Automated fishbowl scenario exercises the actual production scene/systems with no scripted worker control or stock injection.

### AC-49 — Consecutive Repeatability
At least three consecutive fresh full fishbowl scenarios pass.

### AC-50 — Sixty-Day Stability
One accelerated production fishbowl run completes at least 60 simulated days with conserved resources and bounded state.

### AC-51 — Population Consistency
Reported population always equals the actual number of active production citizen entities.

### AC-52 — Development Effect Consistency
Shelter/workshop effects are applied exactly once per completed structure and match visible completed modules.

### AC-53 — No Runtime LLM Citizen/Governor Logic
No model/API call makes citizen or governor decisions.

### AC-54 — Normal Mode Remains Manual
Autonomous salvage/growth does not occur in ordinary POC 4 mode unless fishbowl/autonomy is explicitly enabled.

### AC-55 — No Manual Godot Authoring
Implementation, launch, testing and verification require no user scene/node/editor work.

---

## 46. Long-Run Health Metrics

During sustained tests record at least:

- simulated day;
- population;
- shelter capacity;
- food reserve/days;
- water reserve/days;
- wood;
- metal;
- source remaining totals;
- number of depleted salvage objects;
- active/completed development projects;
- structures by type;
- governor mode/priority state;
- growth events;
- task count/history maximum;
- ticket count maximum;
- bundle count maximum;
- event-history count maximum;
- failed task count;
- oldest active task/project age;
- citizen movement sanity;
- frame/simulation performance where practical.

Use these metrics to diagnose stability instead of relying only on a final PASS marker.

---

## 47. Anti-Fake Requirements

Allowed simplifications:

- deterministic rule-based governor;
- five-citizen cohorts;
- predetermined building meshes/stages;
- simple functional building bonuses;
- grid/ring-based site selection;
- finite canonical resource pool;
- aggregate shelter capacity;
- bounded population cap;
- deterministic camera rules.

Not allowed:

- incrementing population without actual citizen entities;
- adding shelter capacity without a completed building;
- instant governor-created resources;
- direct stock injection for development;
- instant building completion;
- invisible construction pretending to be real work;
- test-only growth logic;
- scripted timeline decisions that ignore world state;
- hidden per-citizen assignments by the governor;
- teleporting new citizens to arbitrary inaccessible locations;
- silent resource regeneration;
- unlimited repeated salvage yield;
- fishbowl-only shortcuts around traversal/navigation;
- declaring success from screenshots without simulation evidence.

As with POC 4:

> **Ugly but systemic remains preferable to polished but fake.**

---

## 48. Explicitly Out of Scope

POC 4.5 does not include:

- reproduction/family simulation;
- aging;
- children;
- relationships;
- personalities;
- detailed morale;
- disease/health simulation;
- death system;
- combat;
- enemies;
- multiple civilizations;
- diplomacy;
- technology/research trees;
- farming;
- renewable agriculture;
- factories/production chains;
- detailed crafting;
- electricity/fuel grids;
- weather/temperature;
- day/night survival effects;
- voxel/freeform building;
- player free-placement city builder tools;
- structural collapse;
- arbitrary furniture destruction;
- save/load persistence across application restarts;
- cloud/server simulation;
- multiplayer;
- runtime LLM planning;
- broad graphics overhaul;
- full elevated-surface colony construction unless it falls out cheaply from generalized site selection.

---

## 49. Failure Policy

When a fishbowl run fails:

1. capture actual world/governor/project state;
2. identify the failed acceptance criterion;
3. identify the generalized subsystem responsible;
4. reproduce with the smallest deterministic test possible;
5. fix the generalized issue;
6. rerun the targeted test;
7. rerun the relevant integrated fishbowl scenario;
8. rerun POC 4 regression if shared production systems changed.

Do not patch the canonical room with special-case coordinates or free resources merely to make the fishbowl pass.

---

## 50. Verification Artifacts

Maintain generated/retained evidence under an appropriate structure such as:

`verification/poc45/`

Useful artifacts:

- baseline regression logs;
- fast governor/population/development tests;
- autonomous survival run;
- full fishbowl scenario logs/JSON;
- repeated-run summaries;
- 60-day stability report;
- governor decision/event log;
- population/shelter timeline;
- resource-conservation snapshots;
- development project history;
- screenshots of growth stages;
- camera/event-feed verification;
- acceptance matrix;
- final report.

---

## 51. Documentation

Update repository documentation with:

- what fishbowl mode is;
- how to launch it;
- what the autonomous governor controls;
- how population growth works;
- how settlement development works;
- how finite resources limit growth;
- how to disable automatic camera/governor if supported;
- test commands;
- intentional scope limits;
- current known performance/population cap.

Another Aphrael/Work session must be able to continue from the repository without relying on this conversation.

---

## 52. Definition of Done

POC 4.5 is complete when the user can launch RoomScale in fishbowl mode and **do nothing** while observing the following real production chain:

**50-citizen settlement → needs pressure → autonomous strategic response → autonomous safe salvage → real hauling/construction/traversal → water recovery → autonomous housing project → real settlement construction → increased shelter → autonomous population cohort → increased consumption/pressure → further development → visibly larger persistent settlement**

The canonical autonomous scenario must reach at least 65 real citizens and build multiple new settlement structures.

The systems must remain stable across repeated fresh runs and a 60-simulated-day accelerated test.

Normal POC 4 manual mode must remain intact.

The desired end-state experience is:

> **Launch RoomScale, put it on another monitor, and watch a tiny civilization slowly turn an ordinary room into its world.**
