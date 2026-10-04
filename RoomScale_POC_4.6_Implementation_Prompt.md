> Historical milestone plan. Current project behavior and engineering commands are described in README.md and docs/ARCHITECTURE.md. This file retains its original milestone scope.

# RoomScale POC 4.6 Implementation Prompt

Implement **RoomScale POC 4.6 — Fishbowl Presentation & Spectator Experience**.

Repository root:

`C:\Users\Zero\python_projects\ai\roomscale`

Authoritative project plan:

`C:\Users\Zero\python_projects\ai\roomscale\RoomScale_POC_4.6_Project_Plan.md`

Verified POC 4.5 baseline:

- branch: `codex/roomscale-poc45-fishbowl`
- commit: `c0b93c5dd74081bc20068b7455ec9805dc5fb71d`

Create/use a dedicated branch such as:

`codex/roomscale-poc46-spectator-ui`

Do not merge into `main`.

The user has NOT manually tested POC 4.5 yet. This pass is intended to make the first manual fishbowl experience materially better, so visual quality and watchability matter.

==================================================
FIRST: READ AND BASELINE
==================================================

Before changing production code:

1. Read the ENTIRE POC 4.6 project plan.
2. Read the existing POC 4.5 fishbowl documentation.
3. Inspect the current fishbowl implementation, especially:
   - `scripts/civilization_ui.gd`
   - `scripts/fishbowl_camera_director.gd`
   - `scripts/event_journal.gd`
   - `scripts/autonomous_governor.gd`
   - `scripts/settlement_development_system.gd`
   - `scripts/population_system.gd`
   - `scripts/civilization_simulation.gd`
   - `scripts/citizen_agent.gd`
   - `scripts/task_coordinator.gd`
   - `RUN_ROOM_SCALE_FISHBOWL.ps1`
   - `TEST_ROOM_SCALE_POC45.ps1`
   - POC 4.5 verification artifacts.
4. Confirm the starting branch is at `c0b93c5dd74081bc20068b7455ec9805dc5fb71d` or a descendant.
5. Run and retain baseline evidence:
   - POC 4.5 fast suite;
   - one full POC 4.5 scenario;
   - POC 4 fast/cleanup regression.
6. Put new evidence under:
   - `verification/poc46/`

Do not proceed from a broken baseline.

==================================================
PRIMARY OBJECTIVE
==================================================

POC 4.5 already proves the autonomous colony works.

POC 4.6 must make it enjoyable to WATCH.

The target experience is:

- launch one command;
- autonomous colony immediately begins at a useful speed;
- the room and citizens dominate the screen;
- a compact status HUD explains civilization health at a glance;
- major events temporarily explain the colony's story;
- automatic camera shots are contextual and understandable;
- active construction gets a small progress card;
- detailed debugging remains available on demand;
- the default screen no longer feels like a test dashboard;
- five-person cohorts visibly arrive as five distinct real citizens.

This is a presentation/spectator pass.

Do NOT broaden it into another gameplay POC.

==================================================
NON-NEGOTIABLE PRESERVATION RULE
==================================================

The verified POC 4.5 production simulation remains authoritative.

Do not replace or bypass:

- AutonomousGovernor;
- CitizenAgent;
- NeedSystem;
- EconomySystem;
- ResourceSystem;
- SalvageSystem;
- CivilizationPlanner;
- CivilizationSimulation;
- TaskCoordinator;
- ConstructionSystem;
- SettlementDevelopmentSystem;
- PopulationSystem;
- FloorNavigation;
- SurfaceNavigation;
- EventJournal;
- existing traversal behavior.

The presentation layer OBSERVES these systems.

Except for explicit user controls such as speed/camera/details, presentation must not change simulation state.

==================================================
DO NOT REOPEN THE SIMULATION DESIGN
==================================================

Do not add:

- new needs;
- reproduction;
- families;
- farming;
- tech;
- crafting;
- professions;
- combat;
- diplomacy;
- new building types;
- new resources;
- save/load;
- runtime LLMs;
- a new governor;
- a new pathfinding system;
- a broad graphics rewrite.

Do not rebalance finite food/water/materials merely to make screenshots easier.

==================================================
MILESTONE 0 — BASELINE
==================================================

Run the baseline gates before modifying shared code.

Record:

- command;
- exit status;
- wall time;
- commit SHA;
- result.

Store under `verification/poc46/baseline/`.

==================================================
MILESTONE 1 — BUILD A TRUE SPECTATOR HUD
==================================================

The current fishbowl HUD is verification-friendly but too dense for enjoyable viewing.

Replace the DEFAULT fishbowl presentation with a compact spectator layout.

The world must remain the main visual subject.

Persistent information must include:

- Day
- Population
- Shelter capacity
- Food days
- Water days
- Wood
- Metal
- Current speed
- Governor enabled state
- Concise governor state/reason

Target style:

`Day 4.71 · Population 70/80 · Food 2.9d · Water 2.8d · Wood 9 · Metal 2 · 10×`

with a concise second line such as:

`Governor: Colony stable — preparing shelter expansion`

Do not expose raw implementation enums as the primary spectator wording.

The spectator HUD should be compact and anchored to viewport edges.

Do not cover the center of the room with a giant panel.

Support at least:

- 1920×1080
- 2560×1440

Avoid fragile fixed-position-only layout where practical.

==================================================
MILESTONE 2 — KEEP DIAGNOSTICS, BUT HIDE THEM
==================================================

Do NOT delete the detailed POC 4.5 information.

Put it behind a clear diagnostics/details toggle.

Preferred:

- `F3`
- optional visible `Details` control

Fishbowl default:

- diagnostics OFF

Diagnostics should retain useful detailed data such as:

- planner reasons;
- directives;
- governor internals;
- traversal state;
- project state;
- event history;
- citizen inspection;
- salvage/object state;
- accounting/debug details.

Toggling diagnostics must have ZERO simulation side effects.

Normal/manual RoomScale UI must remain intact.

==================================================
MILESTONE 3 — TRANSIENT EVENT CARDS
==================================================

Use production `EventJournal` events to create readable temporary notifications.

Do not create a scripted timeline.

At minimum present friendly cards for:

- water crisis / survival response;
- Secure Water directive;
- salvage authorization;
- traversal completion;
- development start;
- development completion;
- shelter increase;
- cohort arrival;
- source exhaustion;
- expansion/growth pause.

Examples:

WATER RESERVE LOW
The colony is securing the elevated water source.

SALVAGE AUTHORIZED
The Bookcase will be dismantled for construction material.

POPULATION GROWTH
Five citizens joined the settlement · Population 65.

EXPANSION PAUSED
Safe material reserves cannot fund another housing block.

Requirements:

- friendly headline;
- concise subtitle;
- real production evidence;
- wall-clock duration;
- fade in/out;
- bounded queue;
- duplicate suppression;
- major event priority.

At 10x, cards must still remain readable because display lifetime is REAL TIME, not simulation time.

Do not flood the screen.

==================================================
MILESTONE 4 — NARRATIVE ADAPTER
==================================================

Add a small deterministic presentation mapping layer if needed.

Translate internal terms for spectator use.

Examples:

- `SURVIVAL` → `Securing survival resources`
- `MATERIALS` → `Gathering construction materials`
- `STABLE` → `Colony stable`
- `WAITING_FOR_MATERIALS` → `Waiting for materials`
- `UNDER_CONSTRUCTION` → `Building`
- `FRAME` → `Frame construction`
- `SHELL` → `Enclosing structure`
- traversal → `Grapple route`
- `growth_paused` → `Expansion paused`

Diagnostics may continue to show raw terms.

Do not alter the underlying production state names merely for presentation.

==================================================
MILESTONE 5 — CONTEXTUAL PROJECT CARDS
==================================================

When a settlement project is active, show a small contextual card.

Required:

- module name;
- friendly stage;
- authoritative progress;
- delivered/required wood;
- delivered/required metal.

Example:

Housing Block 3
Frame construction · 72%
Wood 10/10 · Metal 2/2

Hide/collapse the card when no development project is active.

During the initial water story, show a traversal card when relevant:

Grapple Route
Building · 64%
Wood 4/4 · Metal 4/4

Do NOT permanently reserve UI space for traversal after completion.

==================================================
MILESTONE 6 — FIX DEVELOPMENT TASK PROGRESS
==================================================

There is a small POC 4.5 presentation/correctness ambiguity:

development `CONSTRUCTION_BUILD` task progress can fall back to legacy traversal construction stage progress.

Clean this up narrowly.

Requirements:

- development task progress = active development project work / required work;
- traversal build task progress remains based on traversal construction progress;
- no resource-cost change;
- no work-rate change;
- no completion-rule change.

Add a targeted regression.

==================================================
MILESTONE 7 — CAMERA SHOT TITLES
==================================================

Keep the existing state/event-driven `FishbowlCameraDirector`.

Do NOT replace it with a scripted cinematic timeline.

When the automatic camera begins a meaningful shot, display a brief title/subtitle.

Examples:

EXPEDITION TO THE DESK
Securing the colony's water supply

SALVAGE OPERATION
Recovering material from the Bookcase

HOUSING DISTRICT EXPANSION
Housing Block 2 under construction

NEW ARRIVALS
Population increased to 65

COLONY OVERVIEW
Day 8 · Population 80

Requirements:

- derive title from actual event/activity/focus;
- title duration uses real time;
- title does not obscure focused subject;
- no title for meaningless camera movement;
- title has zero simulation side effects.

==================================================
MILESTONE 8 — CAMERA WATCHABILITY TUNING
==================================================

Tune the current camera only where necessary.

Maintain:

- event/state driven selection;
- smooth existing camera rig;
- minimum shot duration;
- periodic wide shot;
- automatic camera disable.

Improve:

- salvage framing;
- building + worker framing;
- cohort-arrival framing;
- citizen close-shot distance;
- avoidance of poor/clipped framing.

Remember citizens are about half an inch tall.

A "close shot" must actually make them visible.

Do not move citizens for the camera.

==================================================
MILESTONE 9 — HUD AUTO-DE-EMPHASIS
==================================================

Add a subtle quiet-state fade/de-emphasis.

Suggested behavior:

- full opacity at startup;
- full opacity while event/title active;
- after ~8–12 real seconds of quiet, fade persistent spectator UI to lower opacity;
- keep vital signs legible;
- restore full opacity on:
  - major event;
  - UI mouse-over;
  - speed change;
  - camera toggle;
  - details toggle.

Use real time.

Do not fully hide the information unless there is a clear user way to restore it.

==================================================
MILESTONE 10 — FISHBOWL DEFAULTS TO 10x
==================================================

Dedicated fishbowl mode should start at 10x.

Normal RoomScale must remain 1x.

Implement this through a clean initial-speed configuration or fishbowl initialization.

Do not bury a global hard-coded 10x inside general simulation logic.

Verify:

- `RUN_ROOM_SCALE_FISHBOWL.ps1` → 10x
- normal `RUN_ROOM_SCALE.ps1` → 1x
- Pause works
- 1x works
- 4x works
- 10x works
- tests using fixed manual ticks remain deterministic.

==================================================
MILESTONE 11 — DISTINCT COHORT ARRIVAL POSITIONS
==================================================

POC 4.5 currently creates five real citizens but initializes the cohort at one shared position.

Fix this.

For each cohort, derive five distinct nearby arrival points around the settlement/housing arrival area.

Every point must be:

- within room bounds;
- floor walkable;
- not an obstacle;
- not inside a completed development building;
- connected by a real path to the depot/settlement;
- meaningfully spaced from the other four positions.

Selection must be deterministic.

Do not teleport citizens apart after spawn.

Do not spawn a partial cohort.

If five safe arrival positions cannot be found:

- cohort does not join;
- population stays unchanged;
- explain the reason in population/growth state;
- optionally journal a bounded `growth_paused` reason.

Recommended spacing target:

roughly 1–3 inches between arrival citizens, adjusted to the actual navigation grid.

The result must still be five ordinary production `CitizenAgent` nodes with normal needs/tasks.

==================================================
MILESTONE 12 — COHORT ARRIVAL PRESENTATION
==================================================

When the cohort joins:

- journal the production event;
- focus camera on actual arrival centroid when appropriate;
- show a temporary `NEW ARRIVALS` card;
- show updated real population;
- do not fake a ceremonial scene.

The five citizens should be visibly separate in a close capture.

==================================================
MILESTONE 13 — RESPONSIVE / INPUT POLISH
==================================================

Verify 1920×1080 and 2560×1440.

Check:

- text clipping;
- panel overlap;
- safe margins;
- project card placement;
- event card placement;
- camera title placement;
- speed controls;
- auto-camera toggle;
- details toggle.

Decorative controls should use mouse pass-through/ignore behavior so the UI does not steal world interaction.

Only actual buttons/toggles should intercept clicks.

==================================================
PRESENTATION MUST BE STATE-TRUE
==================================================

Every visible number must come from actual production state.

Examples:

- population = real citizen array/entity count;
- shelter = NeedSystem;
- food/water days = EconomySystem forecast;
- wood/metal = economy state;
- project progress = project work / required work;
- project stage = actual project stage;
- event = EventJournal;
- camera focus = actual production event/activity location;
- speed = actual simulation speed.

No shadow UI model that can drift from the game.

==================================================
PRESENTATION MUST NOT DRIVE GAMEPLAY
==================================================

Except explicit user controls, the new UI must not:

- set governor priorities;
- issue resource directives;
- authorize salvage;
- request buildings;
- spawn cohorts;
- move citizens;
- alter needs;
- inject stock;
- complete work;
- change navigation.

The observer remains an observer.

==================================================
FAST TESTS — REQUIRED
==================================================

Add deterministic tests for at least:

SPECTATOR STATUS
- actual day/population/shelter/resources map to display model;
- governor mode maps to friendly wording;
- no active project hides project card;
- active project shows authoritative values.

EVENTS
- production event maps to expected headline/category;
- duplicate suppression;
- bounded event queue;
- major priority;
- display lifetime independent of simulation speed;
- presentation event has no simulation side effect.

SPEED
- fishbowl initialization starts 10x;
- normal initialization starts 1x;
- Pause/1x/4x/10x remain authoritative.

COHORT POSITIONS
- exactly five unique points;
- all walkable;
- all connected;
- no obstacle overlap;
- minimum spacing;
- deterministic result;
- blocked fixture produces zero new citizens;
- valid fixture produces five real CitizenAgent nodes.

DEVELOPMENT PROGRESS
- development task uses development project progress;
- traversal build uses traversal progress.

CAMERA/TITLES
- title derives from actual shot/event;
- disabled camera creates no automatic shot;
- presentation leaves simulation time/needs/positions unchanged.

DIAGNOSTICS
- default off in fishbowl;
- toggle exposes details;
- toggle does not change simulation.

==================================================
FULL AUTONOMOUS TEST
==================================================

The integrated fishbowl test remains an OBSERVER.

It may:

- enable fishbowl;
- advance fixed production ticks;
- inspect state;
- inspect presentation state;
- capture visuals.

It may NOT:

- issue Secure Water;
- authorize salvage;
- request development;
- create cohorts directly;
- inject resources;
- assign workers;
- teleport citizens.

Verify the full POC 4.5 chain still occurs autonomously.

==================================================
REPEATABILITY
==================================================

Because population arrival behavior changes, run:

3 CONSECUTIVE fresh eight-day scenarios.

Each must reach at least 65 real citizens and demonstrate:

- water crisis;
- autonomous directive;
- safe salvage;
- traversal;
- recovery;
- housing;
- workshop;
- population growth;
- real distinct cohort positions;
- no failed tasks from arrival placement;
- resource conservation.

Do not count retries as consecutive success.

A new sixty-day run is not automatically required.

Run sixty-day stability only if the cohort-position or other changes materially alter simulation behavior or the shorter runs reveal instability.

==================================================
VISUAL VERIFICATION — THIS IS A PRESENTATION POC
==================================================

Rendered verification is mandatory.

Capture at least:

1. startup spectator UI;
2. water crisis card;
3. salvage shot + title;
4. traversal project card;
5. water recovery;
6. first housing foundation/frame;
7. housing completion event;
8. workshop activity;
9. cohort arrival showing five distinct citizens;
10. population ≥65 settlement;
11. later expanded settlement;
12. quiet faded HUD;
13. diagnostics/details open;
14. automatic camera OFF with manual view;
15. 2560×1440 or equivalent higher-resolution layout check.

Actually inspect the image content.

Do not pass a criterion because a PNG exists.

For each image ask:

- Is the room the main subject?
- Is the event understandable?
- Is the focused citizen/building visible?
- Is text readable?
- Is there UI overlap?
- Does anything look like a debug tool unnecessarily?
- Does the event/title correspond to real state?
- Is the result enjoyable enough to leave on another monitor?

If not, fix the generalized presentation problem.

==================================================
NO MANUAL GODOT WORK FOR THE USER
==================================================

Do not ask the user to:

- open Godot editor;
- position controls;
- inspect anchors;
- edit scenes;
- capture screenshots;
- drive test scenarios;
- select camera targets;
- manually validate cohort points.

You own implementation and verification.

==================================================
ANTI-FAKE RULE
==================================================

Still applies completely.

Prohibited:

- fake population UI;
- fake construction percent;
- fake event cards;
- scripted camera timeline;
- hidden stock injection;
- test-side strategic decisions;
- fake citizens;
- screenshot-only state changes;
- citizen teleportation to make the cohort look better.

Presentation must make the real simulation easier to understand.

==================================================
ACCEPTANCE REVIEW
==================================================

Review ALL 60 acceptance criteria in the authoritative POC 4.6 plan individually.

Create:

`verification/poc46/acceptance.md`

PASS requires evidence.

Do not mark PASS merely because a class exists.

==================================================
DOCUMENTATION
==================================================

Update:

- `README.md`
- `PROJECT_PROGRESS.md`
- fishbowl documentation
- launch instructions

Document:

- 10x fishbowl default;
- spectator HUD;
- event cards;
- camera titles;
- active project card;
- diagnostics toggle;
- auto-fade;
- distinct cohort arrival;
- remaining limits.

Do not overwrite historical POC 4.5 evidence.

==================================================
FINAL REPORT
==================================================

Create:

`verification/poc46/final-report.md`

Report:

- overall PASS / PARTIAL / BLOCKED;
- starting baseline SHA;
- final branch;
- final SHA;
- files changed;
- architecture added/changed;
- spectator UI design;
- event presentation rules;
- camera/title behavior;
- fishbowl default speed;
- cohort placement algorithm;
- development progress fix;
- test commands actually run;
- fast-test results;
- three-run repeatability results;
- POC 4 regression result;
- screenshots reviewed;
- 1080p/1440p layout findings;
- performance impact;
- every acceptance criterion status;
- known limitations.

==================================================
COMPLETION STANDARD
==================================================

Do not stop because the code compiles.

Do not stop because the simulation still passes.

Do not stop because the UI technically displays the right values.

POC 4.6 is complete when the DEFAULT fishbowl view is genuinely spectator-oriented:

- clean;
- compact;
- readable;
- understandable;
- contextual;
- nonintrusive;
- autonomous;
- visually demonstrable.

The target reaction is:

"I can leave this running on another monitor and understand what the tiny civilization is doing without operating it."

Commit and push the completed work to the dedicated POC 4.6 branch.

Do not merge into main.
