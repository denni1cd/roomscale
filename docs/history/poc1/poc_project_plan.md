> Historical milestone plan. Current behavior and engineering commands are in [README](../../../README.md), [ARCHITECTURE](../../ARCHITECTURE.md) and [TESTING](../../TESTING.md). This file retains its original milestone scope.

# RoomScale — POC 1 Project Plan

## 1. Purpose

RoomScale is a 3D civilization simulation in which tiny civilizations inhabit and explore environments based on ordinary human rooms.

The defining fantasy is:

**A normal room becomes a vast landscape for a civilization of roughly half-inch-tall people.**

Furniture becomes terrain. Vertical surfaces become cliffs. Ordinary household objects become enormous obstacles, landmarks, resources, and infrastructure opportunities.

POC 1 exists to answer one primary question:

> Is it compelling to watch a tiny autonomous civilization explore a recognizable human-scale room, encounter terrain it cannot traverse, construct a technological solution, and expand into newly reachable territory?

POC 1 does **not** attempt photo-to-3D room reconstruction.

---

# 2. Non-Negotiable Development Constraint

The user is **not** the game developer or Godot operator.

The implementation must not require the user to:

* manually create Godot scenes
* place objects in the Godot editor
* configure nodes in the Inspector
* construct navigation meshes
* import or configure art assets
* build UI through the editor
* use Blender or another 3D modeling package
* fix scene files
* edit code
* debug the project
* manually configure the simulation
* perform repetitive development steps

The user may be asked to perform a **one-time software installation or permission step** if the agent cannot do it automatically.

For example, installing or extracting Godot is acceptable.

After the development environment exists, Aphrael/Luna must perform the implementation work.

**If a proposed feature requires substantial manual editor work, redesign the feature instead of asking the user to perform it.**

---

# 3. Agent Execution Model

Primary implementation model:

**GPT-6 Luna**

Aphrael acts as orchestrator/reviewer.

Luna is responsible for:

* repository structure
* code
* Godot project files
* generated scenes
* generated geometry
* generated materials
* procedural animation
* simulation systems
* automated tests
* debugging
* launch scripts
* verification artifacts
* documentation

Luna must not mark a milestone complete merely because code exists.

Each milestone requires execution and evidence.

Do not silently switch implementation to another model. If Luna cannot complete a milestone after reasonable attempts, report the failure and evidence so the user can decide whether to escalate.

The purpose of this project is partly to determine what Luna can accomplish.

---

# 4. Technology

## Engine

**Godot 4.7.2 standard Windows x86-64 build**

Use the normal Godot build, **not Godot .NET**.

## Language

**GDScript**

Do not introduce C#, .NET, Python runtime dependencies, or another game framework unless required to resolve a demonstrated blocker.

## Target

Windows desktop.

## Development Style

The project must be **code-authored**.

Godot's graphical editor may be opened by the agent for inspection if useful, but project creation or maintenance must not depend on manually editing scenes through the GUI.

Prefer:

* `.gd` scripts
* `.tscn` text files when needed
* `project.godot`
* procedurally generated meshes
* procedurally generated materials
* procedural animation
* command-line execution

---

# 5. User-Facing Tooling

The repository must contain:

### `SETUP_ROOM_SCALE.ps1`

Verifies the required runtime environment and reports anything missing.

If practical, it may automatically download/extract the approved Godot version.

### `RUN_ROOM_SCALE.ps1`

Launches the POC without requiring the user to open the Godot editor.

### `TEST_ROOM_SCALE.ps1`

Runs the automated acceptance suite and reports PASS/FAIL.

The normal user experience should ultimately be approximately:

`RUN_ROOM_SCALE.ps1`

and the game launches.

---

# 6. Milestone 0 — Development Pipeline Proof

Before building RoomScale, prove that Luna can successfully operate the chosen development environment.

Luna must:

1. verify or obtain the approved Godot binary;
2. record the Godot version;
3. create a minimal project from repository files;
4. create a 3D scene programmatically;
5. place a floor, simple object, camera, and light into it;
6. launch the project from the command line;
7. prove GDScript executes;
8. modify a visible property through code;
9. relaunch and prove the change took effect;
10. execute a headless automated smoke test;
11. produce a verification artifact/log.

### Milestone 0 Exit Condition

Luna has proven that it can:

**write → run → inspect → modify → rerun → test**

a Godot project without the user manually operating the Godot editor.

If this cannot be accomplished, stop the RoomScale implementation and report the blocker.

Do not continue under the assumption that later milestones will somehow solve the development-pipeline problem.

---

# 7. World Scale

Use:

**1 RoomScale world unit = 1 inch**

Therefore:

* citizen height: approximately `0.5`
* desk height: approximately `30`
* chair seat height: approximately `18`
* 12-foot wall: `144`
* 8-foot ceiling: `96`

Perfect real-world measurements are unnecessary, but relative scale must remain believable.

The room must visually read as ordinary human furniture inhabited by extremely small people.

No physics-heavy mechanics depend on Godot's default assumption that units represent meters, so RoomScale may use its own world-scale convention.

---

# 8. Visual Direction

POC 1 uses a **stylized 3D diorama** aesthetic.

The ordinary room should remain recognizable.

The civilization should provide most of the fantasy.

## Room

Generate a room containing:

* floor
* walls
* desk
* chair
* bookshelf or dresser
* rug/carpet
* several recognizable household props

All geometry may be generated from Godot primitive meshes.

No external 3D asset package is required.

## Civilization

The first civilization is steampunk/clockwork inspired.

Visual language:

* brass
* dark metal
* wood
* gears
* pipes
* boilers
* ropes
* pulleys
* steam
* mechanical machinery
* grappling equipment

The POC does not require production-quality art.

The visual goal is:

**recognizable, charming, readable, and clearly steampunk.**

---

# 9. Procedural Art Constraint

POC 1 must not depend on Blender or manually produced 3D assets.

Citizens, structures, furniture, tools, and traversal equipment should primarily be assembled from:

* boxes
* cylinders
* capsules
* spheres
* planes
* curves
* simple generated meshes

Materials should be created programmatically.

Simple procedural animation is preferred over skeletal animation.

For example, a citizen may consist of primitive body parts with code-driven:

* walking motion
* arm movement
* working motion
* climbing motion
* idle movement

This is sufficient for the POC.

---

# 10. Camera

Implement a free 3D strategy camera.

Required capabilities:

* pan
* orbit
* tilt
* zoom

The camera must support three useful viewing scales.

### Room View

See most of the room and understand overall geography.

### Settlement View

See buildings, routes, work crews, and groups of citizens.

### Citizen View

See individual citizens and what they are doing.

Camera collision avoidance is **not required** for POC 1.

---

# 11. Starting Environment

Generate one fixed test room entirely through project code/data.

Required objects:

* room shell
* desk
* chair
* bookshelf/dresser
* rug
* several small props

The room must be recreated automatically every time the POC starts.

No manual scene layout is permitted.

The civilization starts on the floor.

The desk surface is the primary inaccessible destination.

---

# 12. Navigation Architecture

Do **not** attempt general-purpose arbitrary 3D navigation for POC 1.

Use deterministic navigation regions.

At minimum:

### Floor Region

Citizens can navigate around the settlement and room floor.

### Desk Region

Citizens can navigate across the desk surface.

Initially these regions are disconnected.

Conceptually:

`FLOOR  --X--  DESK`

Citizens therefore cannot reach the desk.

After traversal infrastructure is completed:

`FLOOR  -----  DESK`

Use a custom navigation representation such as:

* `AStar3D`
* navigation nodes/grid
* explicit traversal connection nodes

Furniture footprints can remove/block navigation nodes.

This system must represent **real traversable paths**, not teleportation disguised as pathfinding.

---

# 13. Settlement

Create one tiny steampunk settlement on the floor.

Include simple representations of:

* workshop
* storage depot
* housing/tents
* construction/work area

All structures are procedural.

The settlement begins with sufficient resources to complete the POC scenario.

Resource extraction is not required.

---

# 14. Population

Spawn **50 citizens**.

Citizens must visibly exist as separate entities.

They may share the same procedural model.

Citizens do not require:

* names
* relationships
* families
* personalities
* hunger
* sleep
* health simulation

The goal is a functioning miniature civilization, not a life simulator.

---

# 15. Citizen Autonomy

Citizens are **not directly controlled**.

Implement a deterministic task/state system.

Required behaviors:

* idle
* wander
* travel
* explore
* carry resources
* construct
* climb/traverse
* return to autonomous activity

Citizens evaluate available tasks and select appropriate work.

Do not use an LLM for individual citizen decision-making.

Autonomy should be implemented as deterministic game logic.

---

# 16. Task System

Use a shared task system.

Example task types:

* `IDLE`
* `WANDER`
* `EXPLORE`
* `TRAVEL`
* `COLLECT_FROM_STOCKPILE`
* `DELIVER_RESOURCE`
* `BUILD`
* `TRAVERSE`
* `EXPLORE_NEW_REGION`

Tasks should have clear lifecycle states such as:

* available
* reserved
* active
* complete
* failed

This should make citizen behavior inspectable and testable.

---

# 17. Player Interaction

The player interacts with the civilization at a high level.

POC 1 requires one primary interaction:

### Reach / Explore Target

The player can select the desk surface and tell the civilization to reach/explore it.

The player must not need to:

* select individual citizens
* manually assign builders
* manually assign explorers
* carry resources
* place every component of the grapple
* manually tell citizens to climb

The civilization handles those actions.

---

# 18. Barrier Detection

When the player selects the desk:

1. the goal system requests a route;
2. navigation determines that no route currently exists;
3. explorers investigate the reachable area near the desk;
4. the system identifies the missing connection between floor and desk;
5. a traversal project is generated.

This is deterministic gameplay logic.

Do not attempt open-ended AI planning.

---

# 19. Construction Resources

Use three simple resources:

* wood
* metal
* mechanical parts

The settlement begins with a stockpile containing enough resources to build the grappling system.

Citizens must visibly transport resource bundles from storage to the construction site.

Resource harvesting and production chains are out of scope.

---

# 20. Construction System

Construction must have real visible progress.

Required sequence:

1. project created;
2. required resources calculated;
3. delivery tasks generated;
4. citizens retrieve resource bundles;
5. citizens carry bundles to the site;
6. delivered resources are recorded;
7. builder tasks become available;
8. citizens visibly perform construction;
9. construction percentage increases;
10. completed structure becomes active.

The finished object must not simply appear immediately after clicking the desk.

---

# 21. Grappling Traversal System

The first civilization solves the desk problem with a steampunk grappling installation.

The exact visual design may be chosen by Luna.

It should include recognizable components such as:

* base/winch
* mechanical launcher
* rope/cable
* upper anchor
* gears/pulleys

Required sequence:

1. construction occurs beside the desk;
2. grappling system becomes complete;
3. launcher performs a visible deployment sequence;
4. line connects the floor anchor to the desk anchor;
5. traversal connection activates;
6. navigation graph gains a connection between floor and desk;
7. citizens can climb the route.

The grapple does **not** require:

* projectile physics
* realistic ballistic simulation
* rope physics
* rope wrapping
* collision-based hook placement

Those systems do not help prove the POC concept.

---

# 22. Citizen Climbing

Citizen climbing may follow a deterministic spline/curve or series of traversal waypoints.

Citizens must visibly move from the lower anchor to the upper anchor.

They must not teleport between regions.

Simple procedural climbing animation is sufficient.

---

# 23. Exploration After Traversal

Once the first citizen reaches the desk:

* the desk region becomes explored;
* citizens can receive tasks located on the desk;
* additional citizens may autonomously use the grapple;
* visible activity begins on the desk.

The player must not issue separate commands to every citizen using the route.

---

# 24. Persistent World Change

Within the current play session:

* completed grappling infrastructure remains visible;
* the navigation connection remains active;
* citizens continue using it;
* discovered regions remain discovered.

Save/load persistence across game restarts is not required.

---

# 25. User Interface

Use simple Godot UI generated from code or repository scene files.

Display at minimum:

* population
* current civilization goal
* current exploration status
* number of active tasks
* construction status
* construction progress
* resource totals
* route status

Citizen inspection should allow the player to determine a selected citizen's current task.

No elaborate menus are required.

---

# 26. Core Playable Scenario

From a clean start:

1. RoomScale launches.
2. A recognizable room is visible.
3. A miniature steampunk settlement exists on the floor.
4. Fifty citizens are active.
5. Citizens autonomously wander and work.
6. Player selects the desk surface.
7. Player issues Reach/Explore.
8. Explorers move toward the desk.
9. The civilization determines that the desktop is inaccessible.
10. A grappling construction project begins.
11. Workers retrieve resources from storage.
12. Workers deliver resources to the project.
13. Builders visibly construct the mechanism.
14. Grappling equipment deploys.
15. A visible rope/cable reaches the desk.
16. The navigation connection becomes active.
17. Citizens climb to the desk.
18. The desk becomes explored.
19. Additional citizens autonomously use the route.
20. The grappling installation remains visible in the room.

This is the central definition of POC success.

---

# 27. Automated Test Mode

RoomScale must contain a non-interactive acceptance-test mode.

`TEST_ROOM_SCALE.ps1`

should invoke it.

The automated scenario must use the **same production simulation code** as the playable game.

Do not create fake test-only implementations of gameplay.

Tests must verify at least:

* world initialization
* citizen count
* floor navigation
* desk initially unreachable
* Reach goal creation
* barrier detection
* traversal-project creation
* resource delivery
* construction progress
* traversal completion
* navigation connection activation
* successful desk traversal
* autonomous reuse of completed route

Tests must return an unambiguous process success/failure result.

---

# 28. Repeatability Requirement

The complete simulation scenario must succeed **10 consecutive times** from reset conditions.

Different deterministic seeds may be used.

A run fails if:

* required tasks deadlock
* construction never completes
* no citizen reaches the desk
* navigation becomes permanently stuck
* the traversal route fails to activate
* the simulation throws an unhandled error

Record results for all ten runs.

---

# 29. Verification Artifacts

The repository should contain an ignored/generated `verification/` directory.

Luna should produce:

* automated-test results
* runtime logs
* milestone status
* captured screenshots where practical

Useful visual checkpoints include:

1. initial room
2. active settlement
3. citizens investigating desk
4. grapple under construction
5. completed grapple
6. citizens climbing
7. citizens active on desk

Screenshot capture should be automated by the project where practical.

The user should not be required to take screenshots for the agent.

---

# 30. Error Visibility

Development builds should expose useful diagnostics.

Examples:

* current citizen state
* task queue counts
* navigation region connectivity
* active civilization goal
* construction state
* route state

Debug information may be toggled separately from normal gameplay UI.

Failures should be diagnosable through logs rather than requiring the user to describe every visual problem manually.

---

# 31. Performance Target

The POC must simulate **50 active citizens** on the target Windows PC without obvious simulation stalls.

Avoid expensive per-frame planning.

Citizen decisions may run periodically rather than every rendered frame.

Use deterministic/event-driven task updates where appropriate.

No major optimization work is required unless profiling shows it is necessary.

---

# 32. Architecture

Keep architecture simple.

Recommended systems:

### `World`

Owns room creation and world state.

### `RoomDefinition`

Defines:

* room geometry
* tagged surfaces
* navigation regions
* obstacles
* traversal anchors

### `Simulation`

Coordinates simulation time and system updates.

### `CitizenSystem`

Owns citizens and citizen state.

### `GoalTaskSystem`

Translates civilization goals into tasks and assigns work.

### `NavigationSystem`

Owns surface navigation and connectivity.

### `ConstructionSystem`

Owns project resources and build progress.

### `TraversalSystem`

Owns grapple deployment and region connection.

### `UI`

Displays player-facing state.

Avoid unnecessary abstraction or production-engine architecture.

---

# 33. Future Photo-Reconstruction Seam

Photo reconstruction is not implemented in POC 1.

However, the manually generated room must conform to `RoomDefinition`.

Conceptually:

POC 1:

`Code-generated room -> RoomDefinition -> RoomScale simulation`

Future:

`Photo reconstruction -> RoomDefinition -> RoomScale simulation`

The civilization simulation must not depend on how the room was originally created.

A future reconstruction pipeline should eventually provide:

* geometry
* surfaces
* obstacles
* elevations
* semantic object labels
* navigation regions
* traversal anchors

---

# 34. Milestones

## Milestone 0 — Agent/Engine Proof

Prove Luna can autonomously create, run, modify, and test a Godot project.

**Gate:** mandatory.

---

## Milestone 1 — Room and Camera

Build the code-generated room and strategy camera.

### Exit Condition

Player can inspect the room from room scale to citizen scale.

---

## Milestone 2 — Living Settlement

Add procedural settlement, citizens, autonomous movement, and task infrastructure.

### Exit Condition

Fifty citizens visibly perform autonomous activity without player commands.

---

## Milestone 3 — Surface Navigation and Goal

Create floor/desk regions, navigation, desk selection, and Reach goal.

### Exit Condition

Citizens travel toward the desk and the system correctly determines that the desktop is inaccessible.

---

## Milestone 4 — Construction

Add stockpile, deliveries, build tasks, and visible construction progress.

### Exit Condition

Citizens autonomously transport resources and construct a persistent structure.

---

## Milestone 5 — Grappling Traversal

Add grapple deployment, traversal connection, climbing, and navigation expansion.

### Exit Condition

Citizens build the grapple and successfully reach the desktop.

---

## Milestone 6 — Integrated Gameplay

Connect the entire loop:

**Explore → encounter barrier → create project → deliver resources → construct → deploy → climb → explore**

### Exit Condition

The scenario functions from a fresh start without developer intervention.

---

## Milestone 7 — Automated Verification

Implement and run complete acceptance tests.

### Exit Condition

Ten consecutive complete scenario runs pass.

---

## Milestone 8 — POC Presentation Pass

Improve readability without changing scope.

Allowed:

* better procedural meshes
* materials
* lighting
* steam particles
* simple mechanical animation
* UI cleanup
* camera smoothing
* improved procedural citizen motion

### Exit Condition

The game clearly communicates the RoomScale concept to someone seeing it for the first time.

---

# 35. Acceptance Criteria

### AC-01 — Automated Bootstrap

The project can be prepared and launched without manually authoring anything in the Godot editor.

### AC-02 — 3D Room

A recognizable 3D room is generated automatically.

### AC-03 — Scale

Citizens appear approximately half an inch tall relative to room objects.

### AC-04 — Camera

Player can move between room, settlement, and citizen viewing scales.

### AC-05 — Population

Exactly or approximately 50 citizens are simultaneously active.

### AC-06 — Autonomous Activity

Citizens independently select and execute valid tasks.

### AC-07 — Floor Navigation

Citizens navigate the floor while respecting major obstacles.

### AC-08 — Target Selection

Player can select the elevated desk as a civilization goal.

### AC-09 — Barrier Recognition

The system correctly determines that the desktop is initially unreachable.

### AC-10 — Autonomous Response

The civilization automatically generates the appropriate traversal project.

### AC-11 — Resource Delivery

Citizens visibly carry required resources from storage to the construction site.

### AC-12 — Construction

Citizens visibly work on the project and advance real construction state.

### AC-13 — Grappling Infrastructure

A recognizable steampunk grappling system is deployed.

### AC-14 — Navigation Change

Completing the grapple creates a real navigable connection between floor and desk regions.

### AC-15 — Visible Traversal

Citizens visibly climb the route without teleporting.

### AC-16 — Desk Exploration

Citizens successfully reach and explore the desk surface.

### AC-17 — Autonomous Reuse

Additional citizens use the completed route without direct commands.

### AC-18 — Persistent Session State

Completed infrastructure remains present and operational.

### AC-19 — Player Feedback

Normal UI communicates goals, tasks, resources, construction, and route state.

### AC-20 — Repeatability

The automated complete scenario passes ten consecutive runs.

### AC-21 — Zero Required Editor Work

No acceptance criterion requires the user to manually manipulate Godot scenes, assets, nodes, navigation, or UI.

---

# 36. Explicitly Out of Scope

Do not implement:

* photo-to-3D reconstruction
* computer vision
* multiple civilizations
* combat
* diplomacy
* detailed economy
* production chains
* resource harvesting
* hunger
* sleep
* reproduction
* relationships
* citizen personalities
* large technology tree
* procedurally generated houses
* outdoor environments
* multiplayer
* first-person gameplay
* persistent save/load
* skeletal animation pipeline
* Blender workflow
* manually modeled assets
* marketplace asset dependencies
* general-purpose arbitrary 3D pathfinding
* physics-based grappling
* rope physics
* projectile simulation
* individual citizen LLMs
* commercial-quality artwork
* export/installer packaging unless trivial

Do not expand POC scope without explicit user approval.

---

# 37. Anti-Fake Requirement

POC functionality must be real.

Permitted shortcuts:

* primitive procedural meshes
* simple materials
* simple animation
* hard-coded test-room layout
* deterministic AI
* fixed traversal anchor locations
* starting resource stockpile
* simplified navigation

Not permitted:

* teleporting citizens while visually pretending they climbed
* pre-scripted videos
* fake construction progress disconnected from simulation state
* fake autonomous citizens
* automatically declaring success without executing the scenario
* test-only code that bypasses production gameplay
* hidden manual setup required for the demo to work

Ugly but functioning is preferable to impressive but fake.

---

# 38. Failure Policy

When implementation fails:

1. capture the actual error;
2. identify the failing acceptance criterion;
3. attempt a code-level correction;
4. rerun the relevant automated test;
5. rerun prior milestone tests to detect regressions.

Do not ask the user to open the Godot editor and manually fix the problem.

If the selected architecture genuinely cannot meet an acceptance criterion without manual development, report the blocker rather than disguising it.

---

# 39. Definition of Done

RoomScale POC 1 is complete when:

A user with no Godot development knowledge can run the supplied launch script and see a recognizable room containing a living half-inch steampunk civilization.

The user selects the desk as a destination.

Without directly controlling individual citizens, the civilization then:

**explores → discovers the vertical barrier → creates a traversal project → transports resources → constructs a grappling mechanism → deploys the route → climbs onto the desk → explores the new territory → continues using the new route autonomously.**

The same underlying scenario passes ten consecutive automated acceptance runs.

No manual Godot development is required from the user.

That is POC 1.
