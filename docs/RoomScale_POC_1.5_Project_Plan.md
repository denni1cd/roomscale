> Historical milestone plan. Current project behavior and engineering commands are described in README.md and docs/ARCHITECTURE.md. This file retains its original milestone scope.

# RoomScale POC 1.5 — Room Abstraction & Portability

## 1. Purpose

POC 1 proved the core RoomScale gameplay loop:

**living tiny civilization → select elevated destination → investigate barrier → transport resources → construct traversal infrastructure → climb → explore newly reachable territory**

POC 1.5 exists to prove that this gameplay is **not dependent on the specific hard-coded test room**.

The central question is:

> Can RoomScale load substantially different room definitions and run the same civilization, navigation, goal, construction, and traversal systems without room-specific gameplay code?

A successful POC 1.5 establishes the interface that future photo reconstruction will produce.

---

## 2. Primary Architectural Goal

Introduce a formal **`RoomDefinition`** representation.

The simulation should conceptually become:

**RoomDefinition → room generation/navigation metadata → RoomScale simulation**

instead of:

**hard-coded room coordinates scattered throughout gameplay systems**

The civilization simulation must not know that:

- the desk is at a particular coordinate;
- the desk is always on the left;
- the grapple site is always at a fixed location;
- investigation points have fixed coordinates;
- furniture is always arranged like POC 1;
- the room always has the same dimensions.

Those details belong in or must be derived from the active RoomDefinition.

---

## 3. Development Constraint

The same autonomy rule from POC 1 remains binding.

The user may install or approve software when genuinely necessary, but must not be required to:

- edit Godot scenes;
- reposition furniture;
- define navigation manually;
- modify JSON/resource files by hand;
- repair generated rooms;
- alter traversal anchors;
- write or debug code;
- use Blender;
- operate Godot as a level editor.

Aphrael/Luna owns implementation, testing, migration, and verification.

---

## 4. POC 1 Regression Gate

Before substantial refactoring, preserve a known-good baseline.

The existing POC 1 complete gameplay scenario must continue to pass.

Fix the known defects discovered during review before treating the new architecture as complete.

Required cleanup includes:

- construction workers must correctly leave completed build tasks;
- cancelled/superseded tasks must not prevent task-history cleanup;
- grappling cable scale should be visually appropriate relative to 0.5-inch citizens;
- obvious stale project/build state must not remain after construction completes.

POC 1 functionality cannot be sacrificed to achieve the new abstraction.

---

## 5. RoomDefinition

Create one authoritative data structure representing a playable room.

The exact file format is an implementation decision. JSON, Godot Resource, or another text-based representation is acceptable provided it remains inspectable and can eventually be generated automatically.

At minimum, a RoomDefinition must be capable of describing:

### Room geometry

- room width
- room depth
- wall height
- floor
- walls

### Objects

Each significant object should contain enough information to describe:

- unique ID
- semantic type
- display name
- position
- dimensions
- orientation
- whether it blocks floor navigation
- whether it contains a navigable elevated surface

Examples:

`desk`  
`chair`  
`bookshelf`  
`dresser`  
`table`  
`rug`  
`storage_box`

The system must not require a fixed list of every possible future household object.

---

## 6. Navigable Surfaces

RoomDefinition must support explicit or derived navigable surfaces.

Examples:

- floor
- desk top
- dresser top
- shelf
- table top

A navigable surface should contain sufficient information for RoomScale to determine:

- region identity
- world position
- footprint/bounds
- elevation
- accessible/unreachable state
- relationships to other navigation regions

POC 1.5 does not require arbitrary mesh navigation.

Simple rectangular surfaces remain acceptable.

---

## 7. Obstacles

Floor navigation obstacles must be generated from RoomDefinition rather than duplicated manually inside the navigation system.

For example:

If RoomDefinition places a desk at a new position, its navigation footprint must move automatically.

Do not maintain a separate hard-coded list such as:

`desk = (-58, -52)`

inside the floor-navigation implementation.

There should be one authoritative room description.

---

## 8. Traversal Opportunities

Elevated surfaces must expose enough information for the simulation to create traversal opportunities.

RoomDefinition may explicitly provide candidate anchor information, or the simulation may derive anchors from surface geometry.

Either implementation is acceptable.

The gameplay systems must be able to determine:

- lower approach location;
- upper target surface;
- target elevation;
- potential traversal connection;
- appropriate construction-site vicinity.

The system must not require a hard-coded grapple site for each room.

---

## 9. Goal Generalization

Remove gameplay assumptions that the player's target is literally `"DESK"`.

The game may still display semantic names such as:

**Desk**

but navigation and goal systems should operate on generalized surface or region IDs.

Conceptually:

`FLOOR → SURFACE_001`

rather than:

`FLOOR → DESK`

The current desk remains a valid target in Room A.

Room B may use another elevated object as the primary target.

---

## 10. Investigation Generalization

Exploration/barrier detection must no longer use fixed desk-edge investigation coordinates.

Given a target elevated surface, RoomScale must identify or derive suitable reachable investigation positions.

The explorers must:

1. receive the goal;
2. navigate toward valid approach areas;
3. physically reach those areas;
4. determine that no current connection reaches the target region;
5. trigger the traversal project.

This must work in both POC rooms.

---

## 11. Construction-Site Generalization

The grapple construction location must not be fixed to the original POC coordinates.

The system must choose or derive a valid build site near the relevant traversal opportunity.

The site must:

- be on reachable floor terrain;
- not overlap blocked furniture geometry;
- be close enough to plausibly connect to the target;
- remain accessible to resource carriers and builders.

A fixed algorithm is acceptable.

Open-ended AI planning is not required.

---

## 12. Traversal Generation

The grappling system must generate its route based on the active target surface.

Required behavior remains:

**lower construction site → mechanical grapple → cable → elevated anchor → navigation connection**

The cable and citizen route should automatically adapt to different:

- target positions;
- target heights;
- room layouts.

No Room-B-specific traversal code is permitted.

---

## 13. Room A Migration

Convert the existing POC 1 room into the new RoomDefinition system.

Room A should remain visually and behaviorally equivalent enough to preserve the existing POC.

The room's geometry must no longer be primarily defined by coordinates embedded throughout unrelated scripts.

Room A's full gameplay scenario must continue to pass.

---

## 14. Room B

Create a second room definition that is **substantially different** from Room A.

Room B must change enough geometry to prove that the abstraction is genuine.

At minimum, change:

- room dimensions;
- target object's position;
- target object's elevation;
- furniture layout;
- obstacle arrangement;
- settlement position.

Preferably also change the semantic target type.

For example:

Room A target:

**Desk**

Room B target:

**Dresser** or **workbench/table**

Room B should not merely be Room A translated a few inches.

---

## 15. Room Selection

Provide a simple way to launch either room.

For example:

`RUN_ROOM_SCALE.ps1 -Room room_a`

and:

`RUN_ROOM_SCALE.ps1 -Room room_b`

Exact syntax may differ.

No source-code changes should be necessary to switch rooms.

---

## 16. Same Simulation Requirement

The same production gameplay implementations must operate in both rooms.

The following systems must not contain Room-B-specific logic:

- citizen behavior
- task assignment
- goal handling
- barrier recognition
- resource delivery
- construction
- traversal
- desk/elevated-surface exploration
- autonomous reuse

RoomDefinition adapters/generation code may necessarily interpret room data.

Gameplay systems may query semantic room data through defined interfaces.

---

## 17. Core Room A Scenario

Room A must still support:

**settlement → elevated target selected → investigation → barrier detection → construction → resource delivery → grapple deployment → climb → exploration → autonomous reuse**

This is the POC 1 regression requirement.

---

## 18. Core Room B Scenario

From a fresh launch of Room B:

1. Room B loads.
2. Its different layout is visually recognizable.
3. 50 citizens populate the room.
4. Citizens operate autonomously.
5. Player selects Room B's designated elevated target.
6. Explorers autonomously investigate it.
7. The target is correctly determined to be inaccessible.
8. A valid nearby construction location is chosen.
9. Citizens deliver resources.
10. Builders construct the grappling mechanism.
11. The grapple adapts to Room B's target location and height.
12. A real navigation connection is created.
13. A citizen visibly climbs to the elevated target.
14. The target surface becomes explored.
15. Additional citizens autonomously reuse the route.

No gameplay source code may be modified between testing Room A and Room B.

---

## 19. Automated Room Validation

Implement automated validation for RoomDefinition files.

Before a room launches, detect invalid definitions such as:

- missing floor;
- duplicate object IDs;
- unknown target surface;
- impossible dimensions;
- elevated surface with invalid bounds;
- navigation region outside room bounds;
- target without usable approach geometry.

Failures should produce useful diagnostics.

Do not silently attempt to run irreparably malformed definitions.

---

## 20. Automated Test Coverage

The automated test suite must support running the complete simulation against either room definition.

Tests must verify for both Room A and Room B:

| Area | Required verification |
|---|---|
| Room loading | Correct RoomDefinition loaded |
| Geometry | Expected major objects generated |
| Navigation | Obstacles match loaded room |
| Population | 50 citizens created |
| Autonomy | Citizens perform normal tasks |
| Target | Correct elevated surface can be selected |
| Reachability | Target begins unreachable |
| Investigation | Explorers reach dynamically derived approach points |
| Barrier | Missing region connection recognized |
| Build site | Valid site generated dynamically |
| Resources | Real pickup and delivery occurs |
| Construction | Real builder work occurs |
| Traversal | Route created from room geometry |
| Movement | Citizen physically traverses route |
| Exploration | Target surface actually explored |
| Reuse | Additional citizens autonomously use route |
| Persistence | Infrastructure remains active during session |

---

## 21. Cross-Room Regression

A complete automated verification sequence must perform:

**Room A PASS → Room B PASS → Room A PASS again**

without source changes between runs.

This verifies that changing rooms is genuinely data-driven rather than modifying shared state or code.

---

## 22. Repeatability

After Room B is stable:

Run the complete scenario at least **5 consecutive times per room**.

Required:

**Room A: 5/5 PASS**  
**Room B: 5/5 PASS**

The previous POC 1 ten-run test does not need to be repeated as ten runs every development cycle.

The existing ten-run result remains historical evidence.

Five per room is sufficient for POC 1.5 final verification.

---

## 23. Fast Test Layer

The current full integration scenario takes several minutes.

Add a faster automated test layer for core deterministic systems where practical.

Examples:

- RoomDefinition parsing
- room validation
- obstacle creation
- target-surface discovery
- approach-position generation
- traversal-site generation
- navigation-region connectivity
- task cleanup

The existing full simulation remains the final integration gate.

Do not replace the full simulation tests with unit tests.

---

## 24. Task-System Cleanup

Correct the POC 1 lifecycle issues.

Required behavior:

- completed construction workers return to normal autonomous work;
- no citizen remains stuck indefinitely in a completed build state;
- cancelled and superseded tasks can be removed from bounded task history;
- task history remains bounded during long-running simulation;
- no stale build tasks remain active after project completion.

Add tests specifically for these behaviors.

---

## 25. Grapple Presentation Cleanup

Correct obvious POC 1 presentation problems without turning this into an art milestone.

Required:

- cable diameter is believable relative to 0.5-inch citizens;
- grapple remains visually readable;
- deployment visibly occurs rather than the entire final cable simply existing instantaneously.

A simple procedural deployment animation is sufficient.

No rope physics are required.

---

## 26. Citizen Inspection

Complete the lightweight inspection behavior originally intended for POC 1.

The player should be able to select/click a citizen and see at minimum:

- citizen identifier;
- current state;
- current task;
- current target if applicable.

No detailed character UI is required.

---

## 27. Repository Durability

Add repository documentation sufficient for another Aphrael/Luna session to resume work without relying on conversation history.

Required repository documents:

### `README.md`

Include:

- what RoomScale is;
- current POC status;
- setup;
- launch commands;
- test commands;
- controls;
- room selection;
- important architecture.

### Project specification

Commit the authoritative POC plans under a `docs/` directory.

### Acceptance status

Maintain an acceptance-status file linking each criterion to verification evidence.

The repository should become the durable project record.

---

## 28. Architecture Boundary

By completion, gameplay systems should conceptually depend on interfaces/data such as:

`RoomDefinition`  
`RoomObject`  
`NavigableSurface`  
`NavigationRegion`  
`TraversalOpportunity`

Exact class names are not mandatory.

The important requirement is separation of responsibilities.

Room generation knows what exists.

Navigation knows where movement is possible.

The civilization knows how to respond to goals.

Construction knows how to build infrastructure.

Those systems should not independently contain copies of Room A's layout.

---

## 29. Future Photo-Reconstruction Contract

POC 1.5 must document the minimum information that a future photo-to-room pipeline must generate.

At minimum, that contract should cover:

- room dimensions or approximate scale;
- floor boundary;
- walls;
- major object bounding boxes;
- semantic object labels;
- obstacle footprints;
- elevated navigable surfaces;
- surface heights;
- traversal-candidate information if not derived automatically.

This becomes the input contract for POC 2.

Do **not** implement computer vision yet.

---

## 30. Explicitly Out of Scope

POC 1.5 does not include:

- photo reconstruction;
- camera calibration;
- depth estimation;
- object detection models;
- room scanning;
- textures from photographs;
- multiple civilizations;
- combat;
- diplomacy;
- deeper economy;
- resource gathering;
- tech trees;
- save games;
- procedural household generation;
- generalized arbitrary-mesh pathfinding;
- generalized climbing of every object;
- Blender assets;
- final-quality art.

POC 1.5 is an architecture and portability milestone.

---

# Acceptance Criteria

### AC-1 — POC 1 Regression

Existing POC 1 core scenario still functions after refactoring.

### AC-2 — Known Builder Bug Fixed

No construction worker remains stuck on a completed build project.

### AC-3 — Task History Fixed

Cancelled/superseded tasks do not prevent history cleanup and task history remains bounded.

### AC-4 — RoomDefinition Exists

A formal external/data-driven RoomDefinition is the authoritative description of each room.

### AC-5 — Room A Migrated

Existing POC room is recreated through RoomDefinition.

### AC-6 — Geometry Data Driven

Major furniture geometry is generated from RoomDefinition rather than duplicated gameplay constants.

### AC-7 — Obstacles Data Driven

Floor navigation obstacles derive from RoomDefinition.

### AC-8 — Elevated Surfaces Data Driven

Navigable elevated surfaces derive from RoomDefinition.

### AC-9 — Generic Surface Goals

Goal/navigation logic does not depend on `"DESK"` as a hard-coded special region.

### AC-10 — Dynamic Investigation

Exploration approach positions are generated from the selected target geometry rather than fixed coordinates.

### AC-11 — Dynamic Construction Site

Traversal project location is determined from active room/target geometry.

### AC-12 — Dynamic Traversal

Grapple path adapts to target position and elevation.

### AC-13 — Room B Exists

A substantially different second room definition exists.

### AC-14 — Room B Requires No Gameplay Code Changes

Room B works through the same citizen/task/navigation/construction systems as Room A.

### AC-15 — Room Switching

User can launch either room without editing source code.

### AC-16 — Room Validation

Malformed room definitions are rejected with useful diagnostics.

### AC-17 — Room A Complete Loop

Room A completes the entire gameplay scenario.

### AC-18 — Room B Complete Loop

Room B completes the entire gameplay scenario.

### AC-19 — Cross-Room Regression

Room A → Room B → Room A all pass sequentially without source changes.

### AC-20 — Five-Run Room A Stability

Room A passes five consecutive full runs.

### AC-21 — Five-Run Room B Stability

Room B passes five consecutive full runs.

### AC-22 — Real Movement

Traversal in both rooms uses continuous citizen movement rather than teleportation.

### AC-23 — Persistent Infrastructure

Constructed routes remain active and reusable within the session in both rooms.

### AC-24 — Grapple Presentation Improved

Cable scale is reasonable and a visible deployment sequence occurs.

### AC-25 — Citizen Inspection

Player can select a citizen and see current state/task.

### AC-26 — Fast Verification Layer

A faster deterministic test layer exists for room parsing/navigation/derived geometry logic.

### AC-27 — Repository Documentation

README, plans, architecture information and acceptance evidence are committed.

### AC-28 — Photo Pipeline Contract

The required RoomDefinition output for future photo reconstruction is explicitly documented.

### AC-29 — Zero Manual Level Authoring

Neither room requires the user to manually author anything in Godot.

---

# Definition of Done

POC 1.5 is complete when the exact same RoomScale simulation can be launched against **two materially different room definitions** and autonomously solve the elevated-terrain problem in both.

Changing rooms must require changing only the selected RoomDefinition, not civilization or gameplay source code.

The successful end state is:

**Room A data → same simulation → successful civilization expansion**

and

**Room B data → same simulation → successful civilization expansion**

with automated evidence demonstrating both.

At that point, RoomScale is ready for:

# POC 2 — Photo → RoomDefinition

The key acceptance test for this phase is **AC-14**. If Room B works only because room-specific conditionals are added throughout gameplay code, POC 1.5 has failed even if every test is green. The point of this phase is proving that the room has genuinely become **input data** to the game.
