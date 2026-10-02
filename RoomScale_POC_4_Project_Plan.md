# RoomScale POC 4 — Needs, Priorities & Living Room Economy

## 1. Purpose

RoomScale has already established the core technical and presentation foundation:

- a tiny autonomous civilization can inhabit a human-scale room;
- the room is represented through a generalized `RoomDefinition`;
- materially different rooms can use the same simulation systems;
- ordinary photographs can be converted into a recognizable `RoomDefinition`;
- citizens can autonomously investigate barriers, transport resources, construct traversal infrastructure, and expand into newly reachable territory;
- the current POC 3 baseline is visually sufficient to continue development without making additional graphics work a prerequisite.

POC 4 exists to answer the next and more game-like question:

> Can RoomScale become a compelling hands-off civilization simulation in which citizens possess real needs, the player guides civilization-level priorities and directives rather than individual workers, and the civilization survives by harvesting and transforming the ordinary human room around it?

POC 4 should move RoomScale from a mostly scripted expansion scenario toward the foundation of the actual game.

The intended high-level loop is:

**needs create pressure → player establishes priorities/directives → civilization generates work → citizens gather/salvage room resources → resources feed survival and construction → the civilization alters the room → new territory and opportunities become available → population needs continue**

---

## 2. Central POC Question

The primary question is:

> Is it compelling to guide rather than directly control a tiny civilization as it autonomously satisfies survival needs, acquires resources from a human-scale room, and permanently changes that room in order to survive and expand?

POC 4 succeeds only if the player can understand and influence what the civilization is doing without manually assigning individual citizens.

The game should feel like guiding a society, not moving fifty units.

---

## 3. Core Design Principle — Hands-Off Civilization Control

Citizens remain autonomous.

The player must not be required to:

- select individual citizens to perform routine work;
- assign individual builders;
- assign individual haulers;
- assign individual harvesters;
- maintain manual worker counts;
- repeatedly move workers between professions;
- manually carry materials;
- manually tell citizens to eat, drink, or sleep;
- manually route each citizen to a resource;
- manually issue every step of a construction chain.

Instead, the player interacts through three high-level concepts:

1. **Priorities**
2. **Directives**
3. **Policies**

The simulation decides how to translate those decisions into citizen tasks.

---

## 4. Priorities

Priorities represent what the civilization should care about most.

POC 4 should support at minimum:

- **Survival**
- **Resource Acquisition**
- **Construction**
- **Exploration / Expansion**

A simple priority scale is sufficient, for example:

- Critical
- High
- Normal
- Low
- Disabled

Exact UI presentation is an implementation decision.

Priority changes must affect task scoring and labor allocation.

Example:

If Survival is Critical and Exploration is Low, thirsty citizens and water acquisition tasks should receive substantially more labor than optional exploration.

The player must be able to change priorities without assigning individual citizens.

---

## 5. Directives

Directives are explicit civilization-level objectives.

POC 4 must support enough directives to prove the interaction model.

Required directives:

### Salvage Object

The player selects a harvestable room object and authorizes the civilization to dismantle it for materials.

Example:

**Salvage Chair**

The directive does not specify which citizens perform the work.

### Secure Resource

The player selects a known resource source or requests that the civilization secure a specific resource.

Examples:

- Secure Water
- Secure Food

The civilization determines the work required.

### Reach / Explore

Preserve the existing generalized Reach/Explore behavior for elevated surfaces.

### Optional Stockpile Target

If practical, allow the player to specify a desired reserve for a resource.

Examples:

- Maintain 3 days of food
- Maintain 5 days of water
- Maintain 100 wood

This is useful but must not block the POC if it materially increases scope.

---

## 6. Policies

Policies establish standing rules.

POC 4 requires one important policy distinction:

### Protected vs Authorized Salvage

The civilization must not autonomously destroy arbitrary room objects merely because resources are low.

By default:

- major room objects are preserved;
- irreversible salvage requires explicit authorization or placement within an authorized salvage policy/zone;
- the simulation may recommend a source but must not silently destroy it.

This preserves player agency while keeping citizen-level work autonomous.

A future version may allow broad policies such as:

- aggressive salvage;
- preserve furniture;
- salvage only designated objects;
- maintain emergency reserves.

POC 4 only needs enough policy behavior to prove that the player controls irreversible world change without micromanaging labor.

---

## 7. Core Needs System

POC 4 introduces persistent citizen needs.

At minimum, each citizen must meaningfully participate in:

- **Food**
- **Water**
- **Rest**
- **Shelter**

The needs system must be real simulation state rather than decorative UI.

### Food

Citizens consume food over simulation time.

When hungry they should:

1. stop or deprioritize noncritical work when appropriate;
2. travel to an available food source or stockpile;
3. consume food;
4. return to autonomous activity.

### Water

Citizens consume water over simulation time.

When thirsty they should:

1. seek available stored water;
2. consume it;
3. return to autonomous activity.

Water should become urgent more quickly than food.

### Rest

Citizens accumulate fatigue while active.

When sufficiently tired they should:

1. find valid housing/rest space;
2. rest for a meaningful simulation duration;
3. recover;
4. return to available work.

A day/night system is not required.

### Shelter

The settlement must have finite shelter/rest capacity.

POC 4 may model shelter as a civilization capacity rather than a continuously changing individual meter.

The system should be able to distinguish:

- sheltered citizens;
- insufficient shelter capacity;
- available sleeping/rest positions.

Shelter shortages should be visible to the player.

---

## 8. Need Consequences

Needs must influence behavior.

POC 4 should use graduated consequences.

Example states:

- Satisfied
- Mild
- Serious
- Critical

At minimum:

- hunger and thirst should reduce willingness/ability to perform ordinary work when severe;
- fatigue should drive citizens toward rest;
- critical civilization shortages should generate strong planning pressure and player-visible alerts.

POC 4 does **not** require citizen death.

Death from starvation/dehydration may be added later if desired, but the POC should first prove that needs drive meaningful autonomous behavior.

The POC must not depend on killing citizens to demonstrate consequences.

---

## 9. Civilization Demand / Forecasting

The player should not need to inspect fifty individual need bars to understand survival.

Create civilization-level demand calculations.

At minimum display or calculate:

- current food stock;
- current water stock;
- approximate consumption rate;
- estimated days/time remaining;
- shelter capacity;
- current urgent need count.

Example:

`Food: 3.4 days`

`Water: 1.2 days`

`Shelter: 44 / 50`

Exact formatting is flexible.

The system should use the same underlying demand information to influence planning and task priority.

---

## 10. Resource Model

POC 4 introduces a small but real economy.

Required resources:

### Food

Consumed by citizens.

### Water

Consumed by citizens.

### Wood

Construction material derived from appropriate room objects.

### Metal

Construction material derived from appropriate room objects/components.

POC 4 should deliberately avoid a large crafting-resource list.

Future resources may include:

- fiber;
- plastic;
- glass;
- copper;
- mechanical parts;
- fuel;
- stone/mineral material.

These are out of scope unless needed to resolve a demonstrated blocker.

---

## 11. The Room Is the Resource Map

Ordinary room objects should become meaningful economic objects.

Examples:

- wooden chair → wood + small metal yield;
- wooden table → large wood yield;
- metal bracket → metal;
- screw/fastener → metal;
- book/paper object → future fiber/pulp resource;
- carpet/upholstery → future fiber;
- cup/container with water → water source;
- food item/crumb/cache → food source.

POC 4 does not require every room object to be harvestable.

It requires a generalized system capable of representing and harvesting suitable objects.

The economy should visually and mechanically emerge from the room rather than from abstract off-map resource nodes.

---

## 12. RoomDefinition Resource Contract

Extend the existing generalized room/world data contract without creating a POC-4-specific room format.

A `RoomObject` may expose or derive information such as:

- semantic type;
- material category;
- harvestable flag;
- resource yields;
- harvest work required;
- harvest stages/components;
- whether salvage is destructive;
- resource-source contents where relevant;
- whether the object is protected by default.

The exact schema is an implementation decision.

### Prefer Derivation Where Possible

Where existing semantic/material data is sufficient, resource properties should be derived through generalized rules.

Example:

`chair + wood material`

may imply a default wood-heavy resource profile.

Avoid requiring every historical room definition to manually specify detailed harvest data if the information can be inferred safely.

Optional explicit overrides are acceptable.

### No Canonical-Room Hacks

Do not implement logic such as:

`if object_id == "room_a_chair": yield 300 wood`

Resource behavior must operate through generic semantic/material data.

---

## 13. Resource Sources

POC 4 should distinguish two broad source types.

### Consumable / Extractable Resource Source

Examples:

- water container;
- food cache.

These produce or contain a survival resource.

A source may be:

- finite;
- effectively large for the POC;
- refillable only if explicitly supported later.

POC 4 does not require renewable agriculture.

### Salvageable World Object

Examples:

- chair;
- table;
- wooden crate;
- metal object.

These are permanently transformed or depleted through harvesting.

---

## 14. Staged Destruction / Salvage

POC 4 must **not** implement voxel destruction or arbitrary mesh carving.

Instead, destructive salvage should use staged object state.

Conceptually:

`INTACT → STRIPPED → PARTIAL → FRAME → DEPLETED`

The exact stage count may vary by object.

Each stage should have:

- work required;
- one or more material yields;
- a visible world-state change.

Example chair sequence:

1. remove braces/hardware;
2. remove seat;
3. remove one or more structural pieces;
4. leave a partial frame;
5. deplete/remove remaining salvageable components.

The object must visibly change as work progresses.

The final state must remain persistent for the current session.

---

## 15. No Fake Harvesting

Resource harvesting must be mechanically connected to the world object.

Not permitted:

- clicking Salvage and instantly adding resources;
- playing a destruction animation while resources are granted by unrelated logic;
- leaving the object visually intact after it has been fully harvested;
- spawning unlimited material from a depleted object;
- using test-only bypasses that skip harvesting.

Required sequence:

1. salvage authorized;
2. salvage work becomes available;
3. citizens travel to the object;
4. citizens visibly perform work;
5. stage progress advances;
6. a stage completes;
7. the object visually changes;
8. resource bundles/items become available;
9. haulers transport them;
10. settlement stockpile increases;
11. completed/depleted stages cannot be harvested again.

---

## 16. Salvage Work and Transport

Harvested materials should exist as visible transportable resources where practical.

Required:

- material generated at or near the source object;
- citizen pickup;
- visible carrying;
- delivery to a stockpile or active project;
- stockpile update only after valid pickup/delivery flow.

It is acceptable to aggregate small material into bundles.

Do not simulate hundreds of individual screws.

---

## 17. Resource Reservation

The economy must avoid obvious double spending.

Resources should support reservation for projects/tasks.

Example:

If a traversal project requires:

- 40 wood
- 10 metal

those materials cannot simultaneously be counted as available for another construction project after being reserved.

Required states may include:

- available;
- reserved;
- in transit;
- delivered;
- consumed.

Exact implementation is flexible.

---

## 18. Autonomous Labor Allocation

Citizens must not have permanent manually assigned jobs in POC 4.

Use the existing shared-task concept and extend it with demand-aware scoring.

Possible task families include:

- satisfy food need;
- satisfy water need;
- rest;
- harvest/salvage;
- collect resource;
- haul resource;
- build;
- explore;
- investigate;
- traverse;
- idle/wander.

Citizens should choose appropriate tasks based on factors such as:

- task priority;
- civilization priorities;
- urgency;
- distance;
- resource availability;
- current need state;
- task reservation/availability.

No LLM is required or permitted for per-citizen decisions.

---

## 19. Civilization Planning Layer

Add a deterministic planning layer between player intent / civilization state and citizen tasks.

Conceptually:

`needs + priorities + directives + policies + world state → work requirements → task queue → autonomous citizens`

This layer should determine that a problem exists and produce meaningful work.

Example:

`Water reserve critical`

→ known elevated water source exists

→ source currently unreachable

→ generalized Reach/Explore logic identifies missing traversal

→ traversal project requires materials

→ materials unavailable

→ player is informed that additional authorized salvage is needed

→ player authorizes chair salvage

→ salvage and hauling tasks execute

→ project receives resources

→ traversal completes

→ water collection begins

The player should be able to understand this causal chain.

---

## 20. Planner Boundaries

The planner must not become an open-ended AI agent.

Use deterministic simulation rules.

The planner should not:

- call an LLM;
- invent arbitrary technologies;
- generate unbounded plans;
- make irreversible room changes without authorization;
- secretly bypass construction/resource requirements.

POC 4 should prove a comprehensible deterministic gameplay system.

---

## 21. Survival Work Has Priority but Not Unlimited Authority

Citizens may automatically perform non-destructive survival actions such as:

- eating available food;
- drinking available water;
- resting;
- carrying already-authorized resources;
- working on existing player-approved projects.

The civilization may also automatically generate recommendations or work proposals.

However, it must not silently authorize irreversible destruction of protected room objects.

Example:

If wood is required but no source is authorized, the UI may state:

**Wood shortage — no authorized salvage source**

The player then decides what may be sacrificed.

---

## 22. Existing Traversal System Integration

POC 4 must reuse the generalized traversal / Reach logic rather than building a separate survival-specific path.

Needs should be able to create pressure that eventually causes the existing world-expansion systems to matter.

The intended relationship is:

**survival need → strategic objective → reachability check → infrastructure requirement → material requirement → resource acquisition → construction → traversal → access to resource**

This is one of the central POC 4 proofs.

---

## 23. Canonical POC 4 Scenario

Create one deterministic survival/economy scenario using normal production systems.

A suitable scenario is:

### Starting State

- approximately 50 citizens;
- existing RoomScale settlement;
- finite starting food;
- finite starting water;
- functional shelter for most or all starting citizens;
- insufficient construction materials to solve the main expansion problem without harvesting;
- at least one harvestable wooden/metal room object;
- an important water source located on an initially unreachable elevated surface;
- at least one accessible food source or sufficient food for the scenario duration.

### Player Goal

The player must stabilize the civilization's water supply without directly controlling individual citizens.

### Expected Sequence

1. simulation begins;
2. citizens autonomously work and satisfy needs;
3. food and water are consumed over time;
4. water forecast becomes increasingly dangerous;
5. UI communicates the shortage;
6. player raises Survival/Resource priority and/or issues **Secure Water**;
7. civilization identifies a known water source;
8. source is on an unreachable elevated surface;
9. existing reachability/traversal logic identifies the barrier;
10. a traversal project is generated or proposed;
11. project requires wood/metal beyond current stock;
12. UI reports the material shortage;
13. player authorizes **Salvage** on an appropriate room object;
14. citizens autonomously travel to the object;
15. salvage progresses through visible stages;
16. harvested bundles are created;
17. haulers transport material;
18. stockpile/project resources increase;
19. traversal project becomes fully supplied;
20. builders complete the infrastructure;
21. citizens traverse to the elevated surface;
22. water collection begins;
23. water is carried/stored through the normal task system;
24. civilization water forecast improves;
25. citizens continue eating, drinking, resting, hauling, constructing, and exploring autonomously;
26. the salvaged object remains visibly changed.

The player must not manually assign a single citizen during this scenario.

---

## 24. Sustained Simulation Requirement

POC 4 should prove that the system does not only work for a single scripted moment.

After the main water problem is solved, the scenario must continue for a meaningful accelerated simulation period.

Target:

**at least 7 simulated days**

During that period:

- food continues to be consumed;
- water continues to be consumed;
- citizens continue resting;
- stockpiles remain coherent;
- citizens do not deadlock;
- depleted salvage sources do not regenerate;
- completed infrastructure remains usable;
- task queues remain bounded/healthy;
- the settlement remains operational.

The exact real-time duration may be accelerated substantially.

---

## 25. Simulation Speed Controls

POC 4 needs accelerated time to make needs and long-form resource activity practical to observe.

Provide simple simulation speed controls.

Suggested:

- Pause
- 1x
- 4x
- 10x

Exact speeds may differ.

Simulation behavior must remain logically consistent at accelerated speeds.

The POC should not require the user to wait real-world hours to observe a survival cycle.

---

## 26. Player-Facing UI

POC 4 requires a clearer civilization-management UI.

At minimum show:

### Civilization Status

- population;
- food stock;
- food reserve estimate;
- water stock;
- water reserve estimate;
- wood;
- metal;
- shelter capacity;
- urgent-needs count.

### Strategic State

- active directives;
- priority settings;
- active construction projects;
- material shortages;
- key alerts.

### Object Inspection

When selecting a harvestable room object, display:

- object name/type;
- material/resource profile;
- estimated yield;
- salvage authorization state;
- current salvage stage/progress;
- protected state if applicable.

### Citizen Inspection

Preserve citizen inspection and add:

- hunger/food state;
- thirst/water state;
- fatigue/rest state;
- shelter/rest target if applicable;
- current task;
- task target.

---

## 27. Explainability

The player must be able to understand why the civilization is or is not acting.

Examples of useful explanations:

- `Water reserve critical`
- `Secure Water directive active`
- `Target source unreachable`
- `Traversal project waiting for 32 wood / 8 metal`
- `No authorized wood source`
- `Chair salvage authorized`
- `14 wood in transit`
- `Water collector supplied`
- `12 citizens seeking rest`

Do not require the user to infer every failure from watching citizens.

The debug UI may expose more detail than the normal UI.

---

## 28. World-State Persistence Within Session

POC 4 requires persistent current-session consequences.

At minimum:

- depleted food/water sources remain depleted as appropriate;
- salvaged object stages remain changed;
- fully dismantled objects do not reappear;
- resource stockpiles remain consistent;
- completed infrastructure remains;
- route connectivity remains;
- player priorities/directives remain active until changed/completed.

Save/load across application restarts is not required.

---

## 29. Navigation and Destruction Safety

Destructive salvage must not leave navigation in an obviously impossible or stale state.

If a room object changes its collision/obstacle footprint due to salvage:

- navigation representation should update appropriately;
- citizens should not continue treating removed geometry as blocked;
- citizens should not walk through remaining solid geometry.

POC 4 does not require generalized physics collapse.

If removing a component would require complex structural physics, use predetermined valid stage geometry.

---

## 30. Structural Consequences

POC 4 should support the concept that destroying room objects is consequential.

At minimum, the architecture must not assume salvage is purely cosmetic.

Where practical:

- removing a large obstacle may open floor space;
- removing a usable surface may make that surface unavailable;
- depleting an object must remove its future resource value.

POC 4 does not require dynamic furniture collapse physics.

The important principle is:

**world changes are real simulation changes.**

---

## 31. Compatibility With AI-Generated Rooms

POC 4 must preserve the RoomDefinition boundary established by earlier POCs.

Resource gameplay must not only work because one hand-authored room contains special hidden metadata.

The system should be designed so future AI-generated rooms can participate through:

- semantic object identity;
- material/appearance information;
- optional generalized resource metadata;
- generic resource-profile rules.

The canonical photo reconstruction workflow should remain viable.

If the resource system exposes a missing generalized RoomDefinition capability, extend the contract cleanly.

Do not add room-specific gameplay conditionals.

---

## 32. Regression Gate

Before treating POC 4 as complete:

- existing rooms must still load;
- existing generalized Reach/Explore behavior must still function;
- existing barrier detection must still function;
- existing construction must still function;
- existing traversal must still function;
- citizen autonomous reuse must still function;
- current POC 3 visual/presentation baseline must not be materially degraded by the simulation work.

POC 4 is a gameplay milestone, not a reason to rewrite working room reconstruction or traversal systems.

---

## 33. Fast Deterministic Test Layer

Add fast tests for core economy logic.

At minimum test:

- need decay;
- citizen consumption;
- rest/fatigue recovery;
- stockpile accounting;
- reserve forecasting;
- priority/task scoring;
- resource reservation;
- salvage-stage progression;
- salvage yield accounting;
- depleted-source behavior;
- resource bundle pickup/delivery;
- protected-object authorization;
- resource-profile derivation from generic object data;
- planner detection of missing resources;
- bounded task lifecycle.

These tests must not replace the full simulation scenario.

---

## 34. Full Automated Scenario Test

Extend the existing automated RoomScale verification tooling.

The automated POC 4 scenario must use the same production simulation logic as normal gameplay.

It must verify at minimum:

1. population initializes;
2. citizen needs initialize;
3. needs change over simulation time;
4. food is consumed;
5. water is consumed;
6. fatigue/rest behavior occurs;
7. reserve forecasting is correct enough to detect the water shortage;
8. Secure Water / equivalent strategic objective activates;
9. target water source is identified;
10. source is initially unreachable;
11. traversal project is required;
12. material shortage is detected;
13. salvage authorization is respected;
14. citizens perform real salvage work;
15. object progresses through visible/logical salvage stages;
16. resource yield occurs only from completed salvage work;
17. resources are physically/logically transported;
18. resources are reserved/delivered to the project;
19. traversal construction completes;
20. route activates;
21. citizens traverse;
22. water collection begins;
23. stored water increases;
24. reserve forecast recovers;
25. simulation continues for the sustained-run period;
26. task system remains healthy;
27. depleted object state persists;
28. completed infrastructure remains active.

---

## 35. Repeatability

The full POC 4 canonical scenario must pass:

**5 consecutive runs**

Different deterministic seeds may be used where useful.

A run fails if:

- citizens deadlock;
- required salvage never completes;
- resource accounting becomes negative or duplicates materials;
- citizens consume nonexistent food/water;
- the water crisis cannot be solved despite valid player authorization;
- construction remains permanently blocked after required resources exist;
- traversal fails;
- the simulation becomes unstable at accelerated speed;
- the salvaged object resets or generates duplicate yield;
- an unhandled error occurs.

---

## 36. Long-Run Stability

In addition to the five canonical scenario passes, run at least one accelerated long simulation.

Target:

**30 simulated days**

The long-run test may use a stable test configuration with sufficient food/water after the main scenario.

Verify:

- no runaway task growth;
- no unbounded history growth;
- no resource duplication;
- no citizen permanently trapped in completed tasks;
- no repeated salvage of depleted stages;
- no obvious need-state corruption;
- acceptable performance with the target population.

This is primarily a stability test, not a balance test.

---

## 37. Performance Target

Maintain approximately 50 active citizens.

Avoid per-frame civilization planning.

Recommended approach:

- needs update on fixed simulation intervals;
- planner runs periodically or event-driven;
- task scoring runs at sensible intervals;
- world/resource events trigger targeted recalculation;
- rendering remains independent from expensive planning where possible.

POC 4 does not require large-population optimization beyond the current target.

---

## 38. Architecture

Extend the existing architecture rather than replacing it.

Recommended new/expanded responsibilities:

### `NeedSystem`

Owns:

- hunger/food need;
- thirst/water need;
- fatigue/rest need;
- shelter availability checks;
- need thresholds;
- citizen need-state transitions.

### `EconomySystem`

Owns:

- stockpile totals;
- resource reservations;
- in-transit resources;
- consumption;
- supply/demand calculations;
- reserve forecasting.

### `ResourceSystem`

Owns:

- world resource sources;
- resource-profile derivation;
- resource bundles;
- source depletion.

### `SalvageSystem`

Owns:

- salvage authorization;
- stage progress;
- stage completion;
- yields;
- visible object-state transitions;
- depleted-object state.

### `CivilizationPlanner`

Owns:

- translating needs/priorities/directives/world state into work requirements;
- identifying shortages/blockers;
- producing deterministic project/task requests;
- exposing understandable reasons/status.

### Existing `GoalTaskSystem`

Continues to own/coordinate citizen task lifecycle and assignment.

### Existing `ConstructionSystem`

Continues to own project delivery and construction.

### Existing `NavigationSystem`

Continues to own movement/connectivity and must react correctly to world-state changes.

### Existing `TraversalSystem`

Continues to own generalized route infrastructure.

Avoid unnecessary abstraction beyond what is needed to keep these responsibilities clear and testable.

---

## 39. Data / State Separation

Keep authoritative simulation state separate from presentation.

Examples:

- UI reads food reserve state; it does not calculate consumption independently.
- visual salvage stage reflects actual salvage state; it does not decide yields;
- displayed construction shortage reflects actual reservations/deliveries;
- citizen need indicators reflect actual need values.

This prevents visual/UI logic from becoming a second conflicting simulation.

---

## 40. POC 4 Milestones

### Milestone 0 — Regression and Baseline Gate

Confirm the current RoomScale baseline before economy changes.

Verify:

- existing rooms load;
- 50-citizen simulation works;
- Reach/Explore works;
- barrier detection works;
- construction works;
- traversal/climbing works;
- current visual baseline is preserved.

#### Exit Condition

A known-good baseline exists and automated regression evidence is recorded.

---

### Milestone 1 — Core Needs

Implement:

- food need;
- water need;
- fatigue;
- rest;
- shelter capacity;
- stockpile consumption;
- citizen self-care tasks.

#### Exit Condition

Fifty citizens autonomously eat, drink, and rest from real simulation state without player micromanagement.

---

### Milestone 2 — Economy and Forecasting

Implement:

- food/water/wood/metal stockpiles;
- reservations;
- consumption accounting;
- reserve forecasting;
- shortage state;
- UI visibility.

#### Exit Condition

The player can understand current resources, consumption, and approaching shortages from the normal UI.

---

### Milestone 3 — Priorities and Directives

Implement:

- civilization priorities;
- Secure Resource directive;
- Salvage Object directive;
- integration with existing Reach/Explore goal;
- planner/task weighting.

#### Exit Condition

Changing a priority or issuing a directive changes civilization work allocation without selecting individual citizens.

---

### Milestone 4 — Room Resource Profiles

Implement generalized resource behavior for RoomDefinition objects.

Include:

- material/resource profile;
- harvestable state;
- yields;
- source/depletion state;
- generic derivation where practical.

#### Exit Condition

At least several ordinary room object types can become valid resource sources without room-specific gameplay code.

---

### Milestone 5 — Staged Salvage

Implement:

- authorization;
- salvage tasks;
- staged progress;
- visible object change;
- resource creation;
- transport;
- depletion.

#### Exit Condition

Citizens can autonomously dismantle a designated room object over time, carry the resulting materials away, and leave a persistently changed world object.

---

### Milestone 6 — Needs-to-Expansion Integration

Create the canonical water-shortage scenario.

Connect:

**water pressure → Secure Water → unreachable source → traversal project → material shortage → authorized salvage → material delivery → construction → traversal → water acquisition**

#### Exit Condition

The complete sequence succeeds without individual citizen commands.

---

### Milestone 7 — Sustained Simulation

Run the solved civilization for at least seven simulated days.

Verify ongoing:

- food consumption;
- water consumption;
- rest;
- hauling;
- task cleanup;
- stable world/resource state.

#### Exit Condition

The simulation remains coherent after the immediate scripted problem is solved.

---

### Milestone 8 — Automated Verification

Complete:

- fast deterministic tests;
- full scenario tests;
- five-run repeatability;
- 30-day accelerated stability run;
- regression suite.

#### Exit Condition

All required evidence is PASS.

---

### Milestone 9 — Gameplay Presentation Pass

Improve readability without expanding scope.

Allowed:

- clearer priority UI;
- resource icons;
- reserve estimates;
- object salvage progress;
- citizen need indicators;
- better bundle visuals;
- better work animations using the existing animation approach;
- alerts/status explanations;
- modest staged-destruction visual improvement.

Do not turn this into a new graphics overhaul.

#### Exit Condition

A new player can understand why the civilization is acting and how their strategic decisions changed it.

---

## 41. Acceptance Criteria

### AC-1 — Existing Gameplay Regression

Existing RoomScale room loading, navigation, construction, traversal, and exploration continue to function.

### AC-2 — Autonomous Citizen Needs

Citizens maintain real food, water, and fatigue/rest state.

### AC-3 — Food Consumption

Food stock is consumed through actual citizen need satisfaction.

### AC-4 — Water Consumption

Water stock is consumed through actual citizen need satisfaction.

### AC-5 — Rest

Fatigued citizens autonomously seek valid rest/shelter and recover.

### AC-6 — Shelter Capacity

The simulation represents finite shelter/rest capacity and exposes shortages.

### AC-7 — Need Consequences

Severe unmet needs materially affect citizen behavior/work selection.

### AC-8 — Civilization Forecast

The player can see meaningful food/water reserve estimates or equivalent shortage forecasts.

### AC-9 — Wood Resource

Wood exists as a real construction resource.

### AC-10 — Metal Resource

Metal exists as a real construction resource.

### AC-11 — Correct Resource Accounting

Consumption, reservation, in-transit, delivered, and available states do not double count the same resources.

### AC-12 — High-Level Priorities

The player can change civilization priorities without assigning individual citizens.

### AC-13 — Priority Effects

Priority changes measurably affect task/labor selection.

### AC-14 — Secure Resource Directive

The player can issue a civilization-level resource objective such as Secure Water.

### AC-15 — Salvage Directive

The player can authorize salvage of a room object without selecting workers.

### AC-16 — Protected Objects

The civilization does not destructively harvest protected/unauthorized major room objects by default.

### AC-17 — Generic Resource Profile

Harvestability/yields are represented or derived through generalized object/material data rather than room-specific coordinate/object hacks.

### AC-18 — AI-Room-Compatible Contract

Resource gameplay extends the standard RoomDefinition/world contract rather than introducing a special runtime room format.

### AC-19 — Staged Salvage

At least one ordinary room object is dismantled through multiple real salvage stages.

### AC-20 — Visible World Change

Salvage stages visibly alter the object.

### AC-21 — Persistent Destruction

The object's depleted/changed state persists for the current session.

### AC-22 — No Duplicate Harvest

A completed salvage stage cannot generate its yield again.

### AC-23 — Real Salvage Work

Citizens physically reach the object and perform work before resources are produced.

### AC-24 — Resource Bundles

Harvested construction materials are represented as real transport work rather than instantaneous stockpile additions.

### AC-25 — Real Hauling

Citizens pick up and deliver harvested resources.

### AC-26 — Planner Shortage Recognition

The civilization can recognize that an active strategic objective is blocked by missing resources.

### AC-27 — Explainable Blocker

The UI can explain important blockers such as insufficient wood or no authorized salvage source.

### AC-28 — Existing Traversal Reuse

The water scenario uses the existing generalized reachability/construction/traversal systems.

### AC-29 — Needs Drive Expansion

A real survival/resource pressure can result in the civilization pursuing access to previously unreachable territory.

### AC-30 — Canonical Material Shortage

The canonical scenario cannot complete its main traversal project from starting construction stock alone.

### AC-31 — Salvage Solves Material Shortage

Authorized salvage produces the resources necessary to unblock the construction chain.

### AC-32 — Traversal Completion

The civilization builds and activates the required traversal infrastructure.

### AC-33 — Resource Access After Traversal

Citizens reach the elevated water source and begin acquiring water.

### AC-34 — Crisis Recovery

Stored water and the water-reserve forecast improve after access is established.

### AC-35 — No Citizen Micromanagement

The canonical scenario can be completed without manually assigning or commanding an individual citizen.

### AC-36 — Simulation Speed Controls

The player can accelerate the simulation sufficiently to observe need/economy cycles in practical time.

### AC-37 — Seven-Day Sustained Run

The integrated scenario remains coherent for at least seven simulated days after or including crisis resolution.

### AC-38 — Fast Test Layer

Core need/economy/salvage/planner behavior has deterministic fast tests.

### AC-39 — Production-Code Full Test

The full automated scenario uses normal production simulation systems.

### AC-40 — Five-Run Repeatability

The full canonical scenario passes five consecutive runs.

### AC-41 — Thirty-Day Stability

At least one accelerated 30-simulated-day test shows no major state corruption, unbounded task growth, or duplicate harvesting.

### AC-42 — Approximately Fifty Citizens

The target population remains approximately fifty active citizens during the POC.

### AC-43 — No LLM Citizen Logic

Individual citizen behavior and civilization planning remain deterministic game systems rather than runtime LLM calls.

### AC-44 — No Manual Godot Authoring

POC 4 implementation and content do not require the user to manually author or repair Godot scenes.

### AC-45 — POC 3 Presentation Preserved

POC 4 does not materially regress the accepted current visual/presentation baseline while adding simulation depth.

---

## 42. Explicitly Out of Scope

POC 4 does not require:

- births;
- reproduction;
- families;
- relationships;
- personalities;
- morale simulation;
- social simulation;
- detailed health/injury;
- disease;
- citizen death from starvation/dehydration;
- combat;
- predators/enemies;
- diplomacy;
- multiple civilizations;
- classes/professions assigned by the player;
- skill trees;
- citizen experience levels;
- technology tree;
- research system;
- farming;
- renewable agriculture;
- complex cooking;
- complex production chains;
- factories;
- electricity;
- fuel;
- temperature simulation;
- seasons;
- day/night cycle;
- weather;
- arbitrary voxel destruction;
- free-form mesh cutting;
- physics-based structural collapse;
- realistic fracture simulation;
- hundreds of physical resource fragments;
- generalized destruction of walls/floors;
- save/load persistence across restarts;
- multiplayer;
- runtime LLM planning;
- another photo-reconstruction rewrite;
- another broad graphics overhaul.

Do not expand scope without explicit approval.

---

## 43. Anti-Fake Requirement

POC 4 functionality must be genuine.

Permitted simplifications:

- deterministic need decay;
- aggregated material bundles;
- staged rather than continuous destruction;
- fixed visual salvage states;
- generic semantic/material resource rules;
- simplified shelter capacity;
- accelerated simulation time;
- conservative resource yields;
- one canonical survival scenario.

Not permitted:

- fake need bars disconnected from citizen behavior;
- resources appearing because a timer expired without citizen work;
- instant stockpile changes disguised by animation;
- harvesting the same stage repeatedly;
- visually destroying an object while leaving gameplay geometry/resources unchanged;
- hard-coded canonical-room resource injections;
- test-only bypasses around normal economy;
- manually assigning hidden workers while claiming autonomy;
- declaring the scenario solved without running it.

Ugly but systemic remains preferable to polished but fake.

---

## 44. Failure Policy

When POC 4 fails:

1. capture the actual state/error;
2. identify the failing acceptance criterion;
3. identify which generalized subsystem owns the failure:
   - needs;
   - economy;
   - resource profile;
   - salvage;
   - planner;
   - task system;
   - navigation;
   - construction;
   - traversal;
   - UI/presentation;
4. correct the generalized subsystem;
5. rerun the smallest relevant deterministic test;
6. rerun the integrated scenario;
7. rerun prior regression tests if a shared contract changed.

Do not fix an economy failure with canonical-room-specific logic.

Do not ask the user to manually repair scenes or resource data in Godot.

---

## 45. Verification Artifacts

Preserve generated verification evidence.

Useful artifacts include:

- regression results;
- need-system test results;
- economy test results;
- salvage test results;
- planner test results;
- canonical scenario log;
- five-run repeatability summary;
- 30-day stability summary;
- resource accounting snapshots;
- screenshots of:
  - initial settlement;
  - resource/needs UI;
  - critical water forecast;
  - selected salvage object;
  - early salvage stage;
  - partially dismantled object;
  - resource hauling;
  - construction supplied from harvested materials;
  - completed traversal;
  - water acquisition;
  - final altered room state.

Automated capture is preferred where practical.

---

## 46. Documentation

Update repository documentation to describe:

- POC 4 gameplay;
- needs model;
- resource model;
- priority system;
- directives;
- salvage authorization;
- staged destruction;
- resource-profile/RoomDefinition additions;
- test commands;
- canonical scenario;
- known limitations;
- acceptance evidence.

Another Aphrael/Luna session should be able to resume POC 4 without relying on private conversation history.

---

## 47. Definition of Done

RoomScale POC 4 is complete when a user can launch the game and guide a roughly fifty-citizen miniature civilization through a real survival/resource problem using only civilization-level priorities and directives.

Citizens must possess genuine food, water, rest, and shelter requirements.

The room must function as part of the economy.

At least one ordinary room object must be destructively harvested through persistent visible stages, producing real materials that citizens carry and use.

The canonical scenario must demonstrate:

**needs create a water crisis → player establishes a high-level objective → civilization identifies an unreachable source → construction is blocked by missing materials → player authorizes room salvage → citizens dismantle and haul resources → construction completes → citizens traverse to the new territory → water supply is established → the civilization stabilizes and continues autonomously**

The player must never need to tell an individual citizen what to do.

The resulting altered room must remain visibly and mechanically changed.

The scenario must pass five consecutive automated runs and remain coherent through an extended accelerated simulation.

At that point RoomScale has proven the core foundation of its actual gameplay:

> **You do not control the tiny people. You guide what their civilization values, and they survive by transforming the enormous human world around them.**
