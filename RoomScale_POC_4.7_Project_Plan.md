# RoomScale POC 4.7 — Founder Start & Organic Civilization Growth

## 1. Purpose

RoomScale POC 4.5 proved that an autonomous civilization can survive, gather finite resources, salvage room objects, haul materials, construct infrastructure, and grow.

POC 4.6 proved that the resulting civilization can be presented as a watchable spectator experience.

However, those POCs retain an important prototype shortcut:

- the civilization begins with 50 citizens;
- a workshop already exists;
- housing already exists;
- a depot already exists;
- a work area already exists;
- the settlement already looks established;
- Fishbowl mode defaults to 10× speed.

Those assumptions were useful for proving systems.

They are no longer the desired game experience.

POC 4.7 exists to answer the next question:

> **Can RoomScale begin with only a handful of founders and no constructed settlement, then autonomously grow into a real civilization through resource gathering, survival, construction, infrastructure development, population growth, and expansion — while remaining enjoyable to watch at normal 1× speed?**

The target experience is:

**five founders → survive → scavenge → establish camp → construct shelter → establish storage → build workshop → improve housing → grow population → construct advanced infrastructure → expand into the room**

The player should be able to launch RoomScale and watch a civilization genuinely come into existence.

---

# 2. Baseline

Implementation begins from the verified POC 4.6 branch:

- Branch: `codex/roomscale-poc46-spectator-ui`
- Verified branch tip: `801060bd3b265e5fcb2d207b36434f9149d31e3a`
- POC 4.6 implementation commit: `0c53dbc0c44ca02ba029e032e178f5eb45f65999`

Create a new branch such as:

`codex/roomscale-poc47-founder-start`

Do not merge into `main`.

POC 4.7 must preserve the useful production systems established by POC 4–4.6:

- CitizenAgent;
- NeedSystem;
- EconomySystem;
- ResourceSystem;
- SalvageSystem;
- CivilizationPlanner;
- AutonomousGovernor;
- CivilizationSimulation;
- TaskCoordinator;
- ConstructionSystem;
- SettlementDevelopmentSystem;
- PopulationSystem;
- FloorNavigation;
- SurfaceNavigation;
- traversal construction;
- physical hauling;
- EventJournal;
- Fishbowl camera;
- Fishbowl spectator HUD;
- event cards;
- citizen inspection;
- diagnostics;
- RoomDefinition.

POC 4.7 is an evolution of those systems, not a replacement architecture.

---

# 3. Explicitly Superseded Previous Assumptions

POC 4.7 intentionally supersedes the following earlier requirements for the new canonical Fishbowl experience:

### POC 4.5

- 50 starting citizens;
- pre-existing settlement infrastructure;
- starting workshop;
- starting depot;
- starting housing;
- starting work area.

### POC 4.6

- Fishbowl default simulation speed of 10×.

These remain valid historical POC behaviors and may remain available as legacy regression fixtures.

They are no longer the desired default game state.

All other useful POC 4.5/4.6 simulation and presentation behavior should be preserved.

---

# 4. Central Design Principle

The civilization must begin **before the settlement exists**.

At startup the room contains:

- the human-scale room;
- ordinary human objects;
- finite resource opportunities;
- exactly five founder citizens;
- a settlement origin / arrival area;
- portable founder supplies;
- no completed civilization-owned structures.

There must be no completed:

- workshop;
- depot;
- house;
- work area;
- grapple;
- industrial structure;
- expansion structure.

The civilization must construct its own physical history.

---

# 5. Founder Starting State

The canonical POC 4.7 civilization begins with:

**5 real CitizenAgent entities.**

They receive the normal production behavior, navigation, needs, autonomous decision-making and inspection behavior.

They must not be decorative placeholders or a population counter.

### Founder equipment

The founders may begin with a small amount of portable supplies.

Recommended:

- approximately two simulated days of food;
- approximately two simulated days of water;
- basic hand tools assumed as personal equipment;
- no meaningful construction-material stockpile.

The exact food/water amount may be tuned during testing.

The purpose is to provide enough time to establish the first camp without making early resource acquisition irrelevant.

Basic hand tools do not need a separate crafting/inventory system in this POC.

---

# 6. What May Exist at Time Zero

A small visible founder drop/cache is acceptable.

Examples:

- packs;
- crates of personal provisions;
- loose tools;
- a ground resource pile;
- a camp marker.

These are **portable supplies**, not settlement infrastructure.

They must not provide:

- formal housing capacity;
- workshop capability;
- advanced construction capability;
- permanent storage bonuses;
- traversal capability.

The screen should visually communicate:

> Five tiny people have arrived here.

Not:

> A functioning town already existed before the simulation began.

---

# 7. Remove the Prebuilt Settlement Assumption

The new canonical RoomDefinition must not contain completed civilization-owned:

- workshop;
- depot;
- housing;
- work area.

Existing code currently assumes these landmarks exist.

POC 4.7 must remove that assumption from founder-mode gameplay.

Introduce a generalized settlement origin/start representation rather than requiring fixed completed buildings.

Conceptually:

`Settlement Origin → constructed settlement state`

rather than:

`RoomDefinition → already completed settlement`

Legacy rooms may still define starting infrastructure for regression purposes.

---

# 8. Settlement Capability State

Settlement functionality should derive from infrastructure that actually exists.

The implementation may introduce a generalized capability model such as:

- `SHELTER`
- `STORAGE`
- `WORKSHOP`
- `ADVANCED_CONSTRUCTION`
- `TRAVERSAL_ENGINEERING`

Exact naming is not mandatory.

The important rule is:

> A civilization must not receive the benefit of infrastructure it has not built.

For example:

- no housing capacity from a nonexistent house;
- no workshop construction benefit before the workshop exists;
- no advanced grapple construction before the civilization possesses the required workshop capability.

Legacy starting buildings may register their capabilities immediately when loading legacy POC rooms.

POC 4.7 founder mode begins with none.

---

# 9. Bootstrap Construction

Avoid a circular dependency where a workshop is required to build a workshop.

The founders must be capable of limited **hand construction**.

Initial hand-buildable projects should include at minimum:

### Primitive Shelter

Purpose:

- first permanent civilization structure;
- provides shelter/rest capacity for the original founders.

Recommended capacity:

- 5 citizens.

It should require real gathered/salvaged material and real worker effort.

### Primitive Depot / Store

Purpose:

- establishes the first permanent material/storage point;
- becomes the settlement's primary construction-material pickup area.

Before it exists, the civilization may use the temporary founder ground cache.

### Workshop

Purpose:

- marks the transition from primitive camp to functioning settlement;
- unlocks or enables advanced infrastructure.

The workshop itself must be buildable using hand construction plus gathered materials.

---

# 10. Initial Civilization Progression

The intended first-stage sequence is:

1. Five founders arrive.
2. Citizens inspect/use nearby resources.
3. The governor recognizes lack of shelter/infrastructure.
4. Accessible human-room objects are evaluated for safe resource acquisition.
5. Citizens physically travel to resource locations.
6. Citizens gather or salvage material.
7. Materials are physically transported.
8. Primitive shelter project begins.
9. Shelter is visibly built.
10. Shelter capacity becomes available only after completion.
11. Depot/storage is constructed.
12. Workshop is constructed.
13. Advanced settlement projects become available.
14. Permanent housing expands.
15. Stable surplus permits population growth.
16. Settlement visibly becomes larger.
17. Advanced traversal infrastructure becomes possible.
18. Civilization expands onto elevated room territory.

This progression must emerge through production systems.

It must not be a scripted animation.

---

# 11. No Free Settlement Material

POC 4.7 should strongly prefer:

**resource in room → physical acquisition → hauling → project delivery → construction**

rather than beginning with enough wood and metal to construct the settlement automatically.

The initial room must contain enough accessible material to bootstrap.

Appropriate sources include ordinary room objects already represented through the salvage/resource systems.

The first construction project must require material that citizens genuinely acquire.

Do not spawn wood or metal when a project is requested.

Do not refill salvage objects.

---

# 12. Settlement Development Modules

At minimum POC 4.7 must support construction of:

1. primitive founder shelter;
2. depot/storage;
3. workshop;
4. permanent housing;
5. traversal infrastructure.

Existing POC 4.5 housing/workshop construction should be reused where appropriate.

The system may add primitive variants where necessary.

Every completed structure must:

- occupy physical world space;
- persist;
- have visible construction stages;
- require resource delivery;
- require real builder work;
- alter settlement state only after legitimate completion.

---

# 13. Population Growth

POC 4.7 begins with exactly five citizens.

Population growth must be impossible until the settlement can support additional citizens.

Minimum conditions should include:

- sufficient shelter capacity;
- healthy food reserve;
- healthy water reserve;
- no critical survival emergency;
- settlement infrastructure adequate for growth;
- sustained stability.

For the founder phase, growth should occur in much smaller increments than the current five-person cohort jump.

Preferred:

**1 new citizen per growth event.**

This remains abstract population growth.

POC 4.7 does not implement:

- pregnancy;
- children;
- families;
- aging;
- genetic simulation;
- detailed immigration origin.

The purpose is organic civilization growth, not life simulation.

The population must not jump from 5 directly to 10 merely because the older Fishbowl cohort size was 5.

Legacy POC 4.5 mode may preserve five-person cohorts.

---

# 14. Population Pressure

Population growth must create real consequences.

As population increases:

- food demand increases;
- water demand increases;
- shelter demand increases;
- rest demand increases;
- more labor becomes available;
- settlement expansion becomes necessary.

Growth must stop or pause when the civilization cannot safely support it.

The governor should be willing to choose stability over growth.

---

# 15. Canonical Simulation Speed

POC 4.7 changes the Fishbowl design target.

### Default speed

**1×**

The canonical Fishbowl experience must launch at 1×.

### Optional controls

Retain:

- Pause;
- 1×;
- 4×;
- 10×.

4× and 10× are fast-forward controls.

They are not the pace around which gameplay is designed.

---

# 16. 1× Must Be Worth Watching

Do not simply change the startup multiplier from 10 to 1 and declare success.

POC 4.7 must evaluate real gameplay pacing.

At normal speed:

- citizens should visibly move and work;
- resource hauling should be understandable;
- construction should progress at a watchable rate;
- meaningful decisions should occur frequently enough to retain interest;
- population growth should feel earned;
- the viewer should be able to follow what happened.

Recommended experiential targets, subject to tuning:

- meaningful founder activity begins within ~30 seconds;
- first major project begins within ~1–2 minutes;
- first primitive shelter completes within several minutes;
- workshop/depot progression becomes visible within ~5–10 minutes;
- first population growth becomes achievable within roughly ~10–20 minutes;
- advanced expansion/traversal may occur later.

These are experience targets, not hard-coded timers.

The simulation should accomplish them through real work.

---

# 17. Automated Tests May Run Faster

Production gameplay must default to 1×.

Automated verification does **not** need to wait in wall-clock real time.

Tests may efficiently advance the same deterministic simulation ticks.

Do not change production rules specifically for tests.

Do not create test-only construction shortcuts.

---

# 18. Autonomous Governor Changes

The governor must understand the founder phase.

Suggested strategic hierarchy:

### Survival

Secure food/water when forecasts become unsafe.

### Immediate shelter

If founders lack shelter, establish minimum shelter before discretionary expansion.

### Bootstrap materials

Acquire enough wood/metal for the next essential project.

### Settlement establishment

Construct storage/depot and workshop.

### Stable growth

Once basic infrastructure and reserves are healthy, permit population growth.

### Expansion

Construct additional housing and advanced infrastructure.

### Exploration

Reach useful elevated territory once the civilization possesses the material and technological capability to do so.

The governor must continue operating at the civilization level.

It must not assign individual workers.

---

# 19. Advanced Construction Gate

The founders must not immediately build the sophisticated steampunk grapple.

Advanced traversal infrastructure should require an established workshop or equivalent settlement capability.

Conceptually:

`founders → shelter → depot → workshop → advanced grapple`

This creates an actual civilization-development arc.

No large technology tree is required yet.

---

# 20. RoomDefinition / Start-State Architecture

Do not hard-code founder-mode coordinates or structure IDs throughout gameplay.

Extend the room/start contract cleanly.

A playable starting state should be able to describe, directly or indirectly:

- settlement origin;
- spawn region;
- starting population;
- starting portable supplies;
- initial constructed infrastructure;
- available room resources.

For the canonical founder room:

- starting population = 5;
- initial constructed infrastructure = none.

For legacy regression rooms:

- starting infrastructure may remain populated.

The same simulation should support both.

---

# 21. Preserve POC 4.6 Spectator Presentation

Retain the POC 4.6 improvements:

- compact HUD;
- transient event cards;
- construction cards;
- camera context;
- automatic camera;
- diagnostics toggle;
- citizen inspection;
- narrative wording;
- responsive layout.

Update the narrative to tell the founding story.

Useful event concepts include:

- FOUNDERS ARRIVED
- FIRST SALVAGE
- SHELTER STARTED
- FIRST SHELTER COMPLETE
- DEPOT ESTABLISHED
- WORKSHOP COMPLETE
- SETTLEMENT ESTABLISHED
- NEW CITIZEN
- FIRST PERMANENT HOUSING
- ADVANCED CONSTRUCTION AVAILABLE
- FIRST TRAVERSAL
- NEW TERRITORY REACHED

The event feed should make the transition from five founders to a settlement legible.

---

# 22. Legacy Regression

POC 4.7 intentionally changes the canonical default, but previous capabilities must not disappear.

Preserve the ability to run the old POC 4.5/4.6 room/configuration with:

- 50 citizens;
- existing settlement;
- five-person cohorts where appropriate;
- existing Fishbowl behavior.

The exact old 10× default is intentionally superseded for the new canonical launch and need not remain the default.

Tests that assert the previous 10× startup should be updated or scoped to the legacy configuration rather than treated as a regression failure.

---

# 23. Milestones

## Milestone 0 — Baseline

Verify POC 4.6 before modifications.

Required:

- fast tests;
- one full autonomous scenario;
- presentation smoke test;
- previous production regressions.

Record baseline SHA and evidence.

---

## Milestone 1 — Founder Start

Create the new canonical start state.

Exit condition:

- exactly 5 citizens;
- no completed civilization structures;
- small portable supplies;
- valid navigation;
- Fishbowl launches at 1×.

---

## Milestone 2 — Primitive Survival Construction

Add/bootstrap hand construction.

Exit condition:

- founders acquire real materials;
- first shelter is constructed by real citizens;
- shelter capability appears only after completion.

---

## Milestone 3 — Settlement Establishment

Construct depot/storage and workshop.

Exit condition:

- both are physically built;
- materials are delivered;
- citizens perform real work;
- settlement capabilities update only on completion.

---

## Milestone 4 — Organic Population Growth

Adapt population growth to founder mode.

Exit condition:

- population begins at 5;
- remains 5 until conditions are satisfied;
- growth occurs one citizen at a time;
- increased population changes demand.

---

## Milestone 5 — 1× Gameplay Pacing

Tune founder progression for observation at normal speed.

Exit condition:

- early game contains continuous understandable activity;
- the viewer does not need 10× to make the game interesting;
- optional fast-forward remains functional.

---

## Milestone 6 — Advanced Civilization Expansion

Gate advanced infrastructure behind established settlement capability.

Exit condition:

- workshop exists before grapple construction;
- traversal uses real resources/work;
- founders eventually expand to elevated territory.

---

## Milestone 7 — Spectator Integration

Adapt POC 4.6 presentation to the founding arc.

Exit condition:

- default Fishbowl UI clearly tells the story from founders to settlement;
- automatic camera follows meaningful founder activity;
- diagnostics remain optional.

---

## Milestone 8 — Complete Autonomous Founding Scenario

From a clean launch:

**5 founders → acquire resources → shelter → depot → workshop → housing → population growth → advanced traversal → new territory**

No user input required.

---

## Milestone 9 — Verification and Documentation

Run repeatability, preserve evidence, update README/project documentation, and record final acceptance status.

---

# 24. Acceptance Criteria

### AC-01 — Five Founders
Canonical Fishbowl starts with exactly five real citizens.

### AC-02 — No Prebuilt Settlement
No completed civilization-owned workshop, depot, housing or work area exists at startup.

### AC-03 — Portable Supplies Only
Starting possessions do not provide permanent settlement capabilities.

### AC-04 — 1× Default
Canonical Fishbowl starts at 1×.

### AC-05 — Fast Forward Preserved
Pause, 1×, 4× and 10× remain available.

### AC-06 — Real Founder Needs
All five founders use normal NeedSystem behavior.

### AC-07 — Real Resource Acquisition
Construction resources are obtained through production resource/salvage systems.

### AC-08 — No Free Materials
Projects do not spawn required materials.

### AC-09 — Real Hauling
Materials physically travel with citizens to project locations.

### AC-10 — Primitive Shelter
Founders build their first shelter.

### AC-11 — Shelter Effect After Completion
Shelter capacity is not granted before legitimate construction completion.

### AC-12 — Depot Construction
Founders construct a permanent depot/storage structure.

### AC-13 — Workshop Construction
Founders construct a workshop.

### AC-14 — Workshop Capability
Advanced infrastructure is unavailable until workshop capability exists.

### AC-15 — Visible Build Stages
Founder structures visibly progress through construction.

### AC-16 — Real Builder Labor
Construction progress comes from CitizenAgent work.

### AC-17 — Physical Settlement History
Completed structures remain visible and change the room.

### AC-18 — Population Held Until Supported
Population does not grow before survival/infrastructure criteria are satisfied.

### AC-19 — Small Growth Increment
Founder mode adds population one citizen at a time.

### AC-20 — Real New Citizen
Each population increase creates another full CitizenAgent.

### AC-21 — Demand Scales
Food/water/shelter demand increases with population.

### AC-22 — Growth Can Pause
Unsafe conditions prevent further population expansion.

### AC-23 — Autonomous Governor
No player commands are required to establish the settlement.

### AC-24 — No Individual Worker Control
Governor never directly assigns or moves individual citizens.

### AC-25 — Advanced Traversal
Established civilization can construct traversal infrastructure.

### AC-26 — Workshop Before Traversal
Advanced traversal cannot precede required settlement capability.

### AC-27 — Real Traversal
Citizens physically use completed traversal infrastructure.

### AC-28 — Elevated Expansion
Civilization reaches and uses new elevated territory.

### AC-29 — 1× Watchability
Founder progression is meaningfully observable at normal speed.

### AC-30 — POC 4.6 Presentation Preserved
Compact HUD, cards, camera, details and inspection continue working.

### AC-31 — Founder Narrative
Important founding milestones are communicated through spectator presentation.

### AC-32 — Legacy Room Still Runs
Previous established-settlement configuration remains executable.

### AC-33 — Data-Driven Start
Founder population/infrastructure are not hard-coded throughout unrelated gameplay systems.

### AC-34 — Repeatability
Complete founding scenario succeeds at least three consecutive fresh runs.

### AC-35 — Anti-Fake
No test-only or visual-only shortcut substitutes for production gameplay.

---

# 25. Explicitly Out of Scope

Do not add in POC 4.7:

- children;
- pregnancy;
- families;
- aging;
- death simulation;
- genetics;
- professions;
- detailed crafting;
- factories;
- farming;
- renewable food chains;
- large technology trees;
- combat;
- diplomacy;
- other civilizations;
- save/load;
- multiplayer;
- freeform player building placement;
- runtime LLM decision-making;
- a broad graphics rewrite.

Those may become future gameplay layers.

POC 4.7 is about **founding and organic settlement growth**.

---

# 26. Anti-Fake Requirement

Permitted:

- deterministic governor logic;
- simplified resource quantities;
- primitive procedural structures;
- abstract population arrival;
- hand-tool assumptions;
- fixed blueprint types;
- accelerated automated test execution.

Not permitted:

- spawning completed settlement buildings;
- starting founder mode with hidden housing/workshop capabilities;
- spawning project resources;
- teleporting deliveries;
- silently increasing shelter;
- bypassing physical worker construction;
- allowing advanced infrastructure before prerequisites;
- artificially setting population higher during the test;
- using a separate fake simulation for verification.

---

# 27. Definition of Done

POC 4.7 is complete when a clean canonical Fishbowl launch begins at 1× with:

**five tiny founders standing in a human-scale room and no settlement.**

Without player intervention, those founders:

**survive → acquire resources → haul materials → construct shelter → establish storage → construct a workshop → expand housing → grow their population → construct advanced traversal infrastructure → reach new room territory**

while the POC 4.6 spectator systems make the progression understandable and enjoyable to watch.

At the end of the run, the settlement must visibly exist because the citizens built it.

The room should look materially different from the room they arrived in.

That is POC 4.7.

---

# 28. Implementation verification — 2026-10-03

Implemented on `codex/roomscale-poc47-founder-start` from baseline
`801060bd3b265e5fcb2d207b36434f9149d31e3a`. M0–M9 and AC-01–AC-35 pass.
The canonical launcher starts five agents at 1x with portable provisions and no
completed structures or construction capability. Three consecutive fresh eight-day
production runs independently build shelter, depot, workshop and housing, grow to
twelve citizens, deploy a grapple and collect elevated resources, with zero failed
tasks. Their production records are identical.

Shelter completes at 2:36, depot at 3:44, workshop at 6:15, the sixth citizen arrives
at 13:05, traversal deploys at 24:07 and elevated territory is used at 24:42.
A separate live opening measured 185.4 simulation seconds in 185.611 wall seconds.
The rendered full scenario and legacy regression gates pass.

- [Final report and verification limits](verification/poc47/final-report.md)
- [Acceptance matrix](verification/poc47/acceptance.md)
- [Milestone record](verification/poc47/milestones.md)
- [Rendered evidence review](verification/poc47/visual-review.md)
- [Implementation guide and commands](docs/POC47_FOUNDERS.md)

Finite resources, simple procedural art and the absence of a new sixty-day founder
test remain explicit limits. Main has not been merged.
