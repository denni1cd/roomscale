> Historical milestone plan. Current behavior and engineering commands are in [README](../../../README.md), [ARCHITECTURE](../../ARCHITECTURE.md) and [TESTING](../../TESTING.md). This file retains its original milestone scope.

# RoomScale POC 4.6 — Fishbowl Presentation & Spectator Experience

## 1. Purpose

RoomScale POC 4.5 proved that the civilization can govern itself, recover from the canonical water crisis, authorize safe salvage, construct traversal infrastructure, expand the settlement, create real new citizens, and remain stable for long autonomous runs.

POC 4.6 exists to answer a different question:

> **Is the autonomous colony actually enjoyable to leave running and watch?**

The simulation underneath is already doing interesting things. POC 4.6 is a focused presentation pass that makes those events legible, cinematic, and pleasant to observe without turning the screen into a debug dashboard.

The target experience is:

- launch one command;
- fishbowl mode begins immediately at a useful viewing speed;
- the room, settlement, and citizens remain visually dominant;
- a compact persistent HUD gives the civilization's vital signs at a glance;
- important events appear as temporary story-like notifications;
- active construction receives a small contextual progress card;
- automatic camera shots receive short contextual titles;
- detailed diagnostics remain available on demand rather than occupying the default view;
- population cohorts arrive as visibly distinct citizens rather than overlapping at one point;
- the user can simply watch the colony evolve.

POC 4.6 is **not a simulation expansion**. It is a spectator-experience and presentation-quality pass over the verified POC 4.5 systems.

---

## 2. Baseline

Implementation begins from the verified POC 4.5 branch and commit:

- Branch: `codex/roomscale-poc45-fishbowl`
- Verified baseline commit: `c0b93c5dd74081bc20068b7455ec9805dc5fb71d`

The baseline already demonstrates:

- deterministic autonomous governor;
- real needs and finite resources;
- autonomous safe salvage;
- physical hauling;
- existing traversal construction and climbing;
- settlement development;
- housing and workshop construction;
- cohort-based population growth;
- 80-citizen repeatable eight-day runs;
- 120 real citizens in sixty-day stability;
- automatic camera;
- event journal;
- manual POC 4 regression compatibility.

POC 4.6 must preserve those behaviors.

---

## 3. Central Design Question

The core POC 4.6 question is:

> **Can a person understand and enjoy what the colony is doing from the default fishbowl view without reading a dense debug panel or manually operating the game?**

A successful result should feel more like observing a living miniature world and less like monitoring a test harness.

The world should be the star.

---

## 4. Scope

POC 4.6 includes:

1. spectator-first fishbowl HUD;
2. transient event notifications;
3. camera-shot title cards;
4. contextual construction/development card;
5. diagnostics/detail toggle;
6. automatic HUD fading/de-emphasis when nothing important is happening;
7. fishbowl-only default speed of 10x;
8. improved cohort arrival placement;
9. camera/presentation tuning necessary to make important activity visible;
10. responsive layout and visual verification.

POC 4.6 does **not** add new civilization mechanics.

---

## 5. Non-Goals

Do not add:

- new needs;
- reproduction;
- families;
- aging;
- death;
- farming;
- renewable resources;
- technology;
- crafting chains;
- professions;
- combat;
- diplomacy;
- new development module types;
- new traversal systems;
- new resource types;
- save/load;
- multiplayer;
- runtime LLM planning;
- a broad art rewrite;
- freeform city building;
- a new simulation architecture.

Do not rebalance the economy merely to make the presentation easier.

---

## 6. Core Presentation Principle

Fishbowl mode uses **progressive disclosure**.

### Default spectator view

Show only what is useful for watching:

- day;
- population / shelter;
- food reserve horizon;
- water reserve horizon;
- wood;
- metal;
- simulation speed;
- governor state;
- active strategic intent when useful.

### Contextual information

Show temporarily when relevant:

- crisis;
- new directive;
- salvage authorization;
- traversal completion;
- building start/completion;
- cohort arrival;
- source exhaustion;
- expansion pause / carrying-capacity event.

### Detailed information

Keep the existing dense information available through an explicit diagnostics/details toggle.

The spectator should not be forced to read implementation terminology during normal viewing.

---

## 7. Default Fishbowl Layout

The default fishbowl interface should occupy a small fraction of the viewport and avoid covering the center of the room.

Recommended composition:

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│ Day 4.71   Pop 70 / Shelter 80   Food 2.9d   Water 2.8d   W 9   M 2   10x  │
│ Governor: STABLE — preparing room for continued growth                 AUTO │
└───────────────────────────────────────────────────────────────────────────────┘


                         [ROOM / SETTLEMENT]


                                                ┌────────────────────────────┐
                                                │ Housing Block             │
                                                │ FRAME  ███████░░░ 72%     │
                                                │ Wood 10/10 · Metal 2/2    │
                                                └────────────────────────────┘


     ┌─────────────────────────────────────────────────────┐
     │ POPULATION GROWTH                                   │
     │ Five new citizens joined the settlement · Pop 65   │
     └─────────────────────────────────────────────────────┘
```

The exact styling may differ, but the hierarchy must remain:

1. world;
2. compact vital signs;
3. current interesting event;
4. current active project;
5. diagnostics only on request.

---

## 8. Persistent Status Bar

Create a compact spectator status bar.

It must display:

- simulated day;
- actual population;
- shelter capacity;
- food days;
- water days;
- available wood;
- available metal;
- current simulation speed;
- autonomous governor enabled state;
- current governor mode/reason in concise language.

It should not display every internal planner message.

### Example

`Day 4.71 · Population 70/80 · Food 2.9d · Water 2.8d · Wood 9 · Metal 2 · 10×`

Second line or compact subtitle:

`Governor: Stable — evaluating shelter expansion`

The status bar should remain readable at 1920×1080 without covering significant room content.

---

## 9. Human-Facing Language

Fishbowl presentation should translate internal state into concise spectator language.

Avoid making the main UI read like:

- `MATERIALS`;
- `WAITING_FOR_MATERIALS`;
- `UNDER_CONSTRUCTION`;
- `No authorized wood salvage source`;
- `Traversal project_created`;
- raw enum names.

Internal terminology remains valid in diagnostics.

Suggested user-facing translations:

| Internal state | Fishbowl language |
| --- | --- |
| `SURVIVAL` | Securing survival resources |
| `MATERIALS` | Gathering construction materials |
| `STABLE` | Colony stable |
| `WAITING_FOR_MATERIALS` | Waiting for materials |
| `UNDER_CONSTRUCTION` | Building |
| `FRAME` | Frame construction |
| `SHELL` | Enclosing structure |
| traversal project | Grapple route |
| `growth_paused` | Expansion paused |

The adapter must be deterministic and presentation-only.

---

## 10. Event Notifications

Important macro events should appear as temporary notifications rather than permanent dashboard rows.

Each notification should contain:

- short headline;
- one concise explanatory line;
- optional day/time;
- optional relevant quantity.

Examples:

### Crisis

**WATER RESERVE LOW**  
The colony is securing the elevated water source.

### Salvage

**SALVAGE AUTHORIZED**  
The Bookcase will be dismantled for construction material.

### Traversal

**NEW ROUTE COMPLETE**  
The grapple route to the desk is operational.

### Building

**HOUSING STARTED**  
Citizens have begun Housing Block 2.

### Population

**POPULATION GROWTH**  
Five citizens joined the settlement · Population 65.

### Carrying capacity

**EXPANSION PAUSED**  
Safe material reserves cannot fund another housing block.

Notifications must come from production `EventJournal` state or equivalent production events.

No scripted event timeline.

---

## 11. Event Notification Behavior

Notifications should:

- use real wall-clock display duration, not simulation time;
- remain visible long enough to read at 10x;
- fade in/out smoothly;
- avoid stacking excessive cards;
- prioritize major events;
- suppress repeated equivalent messages;
- maintain a bounded queue;
- never pause or alter the simulation unless the user explicitly pauses.

Recommended duration:

- minor event: 4–6 real seconds;
- major event: 7–10 real seconds.

If several major events occur rapidly, queue them in order rather than flashing them too quickly to read.

---

## 12. Event History

The bounded event journal remains authoritative.

The default fishbowl view does not need to display six permanent event rows.

Detailed event history should be available in diagnostics/details mode.

The presentation system may retain the most recent event unobtrusively, but the center of attention should remain the world.

---

## 13. Active Project Card

When a settlement development project is active, display a small contextual card.

Required fields:

- friendly module name;
- friendly stage name;
- progress percentage;
- required/delivered wood;
- required/delivered metal.

Example:

**Housing Block 3**  
`Frame construction · 72%`  
`Wood 10/10 · Metal 2/2`

When no development project is active, this card should hide or collapse.

The card must read authoritative `SettlementDevelopmentSystem` state.

It must not estimate progress from animation timing.

---

## 14. Traversal Context

During the initial water crisis, the spectator needs to understand what citizens are doing.

When the traversal project is relevant, the UI may temporarily show a contextual card such as:

**Grapple Route**  
`Building · 64%`  
`Wood 4/4 · Metal 4/4`

Once traversal is complete and no longer the active story, the card should disappear.

Do not permanently reserve large UI space for traversal after completion.

---

## 15. Camera Shot Titles

The automatic camera is already event/state driven.

POC 4.6 should add a lightweight title/subtitle when a meaningful automatic shot begins.

Examples:

**EXPEDITION TO THE DESK**  
Securing the colony's water supply

**SALVAGE OPERATION**  
Recovering wood and metal from the Bookcase

**HOUSING DISTRICT EXPANSION**  
Housing Block 2 under construction

**NEW ARRIVALS**  
Population increased to 65

**COLONY OVERVIEW**  
Day 8 · Population 80

Shot titles should:

- appear only for meaningful shots;
- fade after several real seconds;
- not obscure the focused subject;
- be derived from the camera target/event/state;
- not invent events.

---

## 16. Camera Presentation Tuning

The automatic camera should remain autonomous and production-state driven.

Tune only where needed for watchability.

Requirements:

- minimum readable shot duration;
- smooth transition using existing camera rig;
- major events outrank routine activity;
- periodic return to wide overview;
- close activity shots should be close enough to see half-inch citizens;
- building shots should frame the building and nearby workers;
- salvage shots should frame the object and worker activity;
- cohort shots should show the arriving cohort and settlement context;
- camera must not clip deeply into room geometry;
- camera must never alter simulation state.

Do not turn the camera into a scripted cinematic timeline.

---

## 17. Automatic HUD De-Emphasis

Add a lightweight auto-fade/de-emphasis behavior.

When:

- no new major event is being shown;
- no active contextual interaction is occurring;
- the mouse is not over UI;

the persistent spectator HUD may fade to a lower opacity after a short real-time delay.

When:

- a major event occurs;
- the user moves over the HUD;
- the user changes speed;
- the user toggles camera/details;

the relevant UI returns to full opacity.

Recommended behavior:

- full opacity during startup and events;
- fade after roughly 8–12 real seconds of quiet;
- remain legible rather than disappearing completely.

The user should still be able to glance at the current population and reserve state.

---

## 18. Diagnostics / Details Mode

Preserve the useful dense POC 4.5 information.

Add a clear toggle, preferably:

- `F3` for diagnostics/details;
- optional small `Details` button/icon.

Diagnostics mode should expose the existing or equivalent detailed information:

- planner reasons;
- directives;
- governor internal mode/reason;
- development state;
- traversal state;
- event history;
- selected citizen needs/task;
- salvage/object inspection;
- resource accounting useful for debugging.

Fishbowl launches with diagnostics **off**.

Toggling diagnostics must not change simulation behavior.

---

## 19. Fishbowl Controls

The default spectator UI must keep the important viewer controls accessible:

- Pause;
- 1x;
- 4x;
- 10x;
- automatic camera on/off;
- diagnostics/details toggle.

These controls should be compact.

The user should not need to open the dense diagnostics panel merely to change speed or disable the camera.

---

## 20. Fishbowl Default Speed

Dedicated fishbowl launch should start at:

> **10x simulation speed**

Reason: at 1x, the first house begins around sixteen real minutes into the verified canonical run; at 10x, major progress becomes visible within minutes.

This must be **fishbowl-only**.

Requirements:

- `RUN_ROOM_SCALE_FISHBOWL.ps1` starts at 10x by default;
- normal `RUN_ROOM_SCALE.ps1` remains 1x by default;
- user can immediately select Pause/1x/4x/10x;
- tests that explicitly control fixed ticks remain unaffected;
- implementation should use a generalized initial-speed configuration or fishbowl initialization rather than hard-coding behavior deep in simulation logic.

---

## 21. Startup Experience

Fishbowl startup should be immediately understandable.

Recommended:

- start at a wide colony view;
- compact HUD visible;
- 10x active;
- automatic camera active;
- brief non-blocking title:

**ROOMSCALE**  
*Autonomous Colony · Fishbowl Mode*

Fade this after a few real seconds.

No click should be required.

---

## 22. Cohort Arrival Presentation Fix

POC 4.5 creates five real citizens correctly, but all five currently begin at one arrival coordinate.

POC 4.6 must derive **five distinct nearby valid arrival positions**.

Requirements:

- all five positions are real floor-walkable points;
- all remain connected to the settlement/depot;
- positions are not inside obstacles;
- positions do not overlap existing completed structures;
- positions maintain reasonable spacing from each other;
- positions are selected deterministically;
- no citizen is teleported after initialization merely to separate the group;
- if five valid arrival positions cannot be found, the cohort does not join and the population system explains why;
- no partial cohort should be spawned.

Recommended spacing:

approximately 1–3 inches between citizens, adjusted to navigation resolution.

The cohort must still contain five ordinary production `CitizenAgent` nodes.

---

## 23. Cohort Arrival Camera

When a cohort joins, the event/camera system should be able to focus on the actual arrival group.

The camera target should be based on the derived arrival positions or their centroid.

A temporary card should explain:

**NEW ARRIVALS**  
Five citizens joined the settlement · Population 65

The camera must not trigger the cohort or affect its positions.

---

## 24. Responsive Layout

Avoid a fishbowl UI made entirely from fragile absolute pixel positions.

Support at minimum:

- 1920×1080;
- 2560×1440.

The layout should:

- anchor logically to viewport edges;
- maintain safe margins;
- avoid overlapping itself;
- avoid covering the center unnecessarily;
- prevent text clipping;
- keep speed/camera controls usable;
- adapt if text wraps.

Testing at additional common aspect ratios is welcome but not required.

---

## 25. Input / Mouse Behavior

Decorative spectator UI elements must not accidentally block world inspection/camera input.

Use appropriate mouse filtering.

Only actual controls should intercept mouse input.

The user should still be able to:

- orbit/pan when automatic camera is disabled;
- inspect citizens where existing interaction supports it;
- use speed/camera/details controls.

---

## 26. Presentation Time vs Simulation Time

Fishbowl UI animation timing should normally use **real time**.

This includes:

- fade duration;
- event toast duration;
- title card duration;
- HUD idle fade;
- camera shot hold timing where already real-time based.

At 10x simulation speed, notifications must not vanish ten times faster.

Simulation state remains based on the authoritative fixed simulation tick.

---

## 27. Visual Style

Stay within the established RoomScale visual language.

Desired qualities:

- dark translucent panels;
- warm clockwork/steampunk accent;
- restrained borders;
- high contrast;
- readable typography;
- subtle animation;
- small footprint.

Avoid:

- giant opaque panels;
- neon sci-fi dashboard styling inconsistent with the game;
- excessive icons;
- heavy full-screen effects;
- broad UI framework rewrites.

The goal is polish, not a new art direction.

---

## 28. Storytelling Priority

When multiple things are happening, the presentation system should prioritize the most meaningful story.

Suggested priority:

1. survival crisis;
2. major infrastructure completion;
3. population cohort;
4. building start/completion;
5. salvage authorization/depletion;
6. source exhaustion;
7. growth/carrying-capacity decision;
8. routine activity.

Do not interrupt a major event card with a minor repeated state message.

---

## 29. Production-State Integrity

All displayed values must come from actual production state.

Examples:

- population from real `sim.citizens.size()`;
- shelter from `NeedSystem`;
- resource days from economy forecast;
- project progress from development project work/required work;
- stage from authoritative project state;
- events from production journal;
- camera target from actual event/activity position;
- speed from actual simulation speed.

Do not maintain a second UI-only version of game state.

---

## 30. No Presentation Side Effects

Except for explicit user controls:

- UI must not modify governor priorities;
- event cards must not issue directives;
- camera titles must not affect camera target selection;
- HUD fade must not pause the simulation;
- diagnostics must not change task behavior;
- screenshots/tests must not drive strategic decisions.

Presentation observes production state.

---

## 31. Development Progress Integrity

While touching the project card, clean up the small POC 4.5 task-progress ambiguity:

Development `CONSTRUCTION_BUILD` tasks should expose progress based on the active development project, not the legacy traversal construction stage progress.

This is a narrow correctness/presentation cleanup.

Requirements:

- development task progress reflects `active.work / active.required_work`;
- traversal build task progress continues to use traversal construction progress;
- no change to actual work rate;
- no change to resource cost;
- no change to completion criteria.

Add a targeted regression.

---

## 32. Architecture Guidance

Prefer a small spectator-presentation layer over expanding `civilization_ui.gd` into a larger monolith.

Reasonable structure:

- `FishbowlHUD` or spectator HUD controller;
- `FishbowlEventPresenter`;
- `FishbowlNarrativeAdapter`;
- existing `FishbowlCameraDirector`;
- optional small `FishbowlPresentationController`.

Exact names are not mandatory.

The important separation is:

`production simulation state → presentation adapter/controller → UI/camera visuals`

Do not move simulation decisions into presentation classes.

---

## 33. Manual Mode Preservation

Normal/manual RoomScale must remain intact.

Normal launch must retain:

- manual priorities/directives;
- manual salvage authorization;
- existing detailed HUD behavior;
- 1x default;
- no autonomous population growth unless fishbowl mode is enabled;
- no automatic fishbowl event presentation unless appropriate.

Fishbowl UI must not silently replace the normal POC 4 interface.

---

## 34. Milestone 0 — Baseline Gate

Before production changes:

1. confirm working branch is the verified POC 4.5 commit or descendant;
2. run POC 4.5 fast tests;
3. run one POC 4.5 full autonomous scenario;
4. run POC 4 fast/cleanup regression;
5. retain baseline evidence under `verification/poc46/baseline/`.

Do not begin from a broken baseline.

---

## 35. Milestone 1 — Spectator HUD Shell

Implement:

- compact status bar;
- concise governor line;
- compact speed controls;
- camera toggle;
- diagnostics toggle;
- fishbowl-only layout.

At this milestone:

- default fishbowl should no longer show the large dense panel;
- diagnostics must still be reachable;
- no simulation behavior should change.

---

## 36. Milestone 2 — Event Presentation

Implement:

- production journal event adapter;
- friendly headlines/subtitles;
- queue;
- duplicate suppression;
- major/minor priority;
- real-time fade;
- bounded presentation state.

Verify crisis, salvage, traversal, structure, cohort, and growth-pause examples.

---

## 37. Milestone 3 — Context Cards and Camera Titles

Implement:

- active development card;
- traversal card when relevant;
- automatic camera shot title/subtitle;
- camera/event integration;
- non-obstructive positioning.

Verify camera titles correspond to real camera focus and production events.

---

## 38. Milestone 4 — Watchability Tuning

Implement:

- HUD auto-de-emphasis;
- layout polish;
- camera framing tuning;
- readable 10x presentation;
- startup title if used;
- friendly terminology.

Verify no critical information becomes unreadable.

---

## 39. Milestone 5 — 10x Fishbowl Launch

Implement fishbowl-only 10x default speed.

Verify:

- dedicated fishbowl launch starts 10x;
- speed buttons work;
- Pause works;
- normal launch remains 1x;
- fixed-step tests remain deterministic.

---

## 40. Milestone 6 — Cohort Arrival Fix

Implement distinct deterministic arrival points.

Verify:

- five distinct positions;
- valid floor navigation;
- no partial cohort;
- no obstacle overlap;
- real entities;
- normal needs/tasks;
- cohort camera/event presentation.

---

## 41. Milestone 7 — Progress and Diagnostics Cleanup

Implement:

- authoritative development task progress;
- diagnostics/details presentation;
- event history access;
- no duplicate conflicting HUDs.

Do not expand simulation scope.

---

## 42. Milestone 8 — Visual and Integrated Verification

Run:

- fast presentation tests;
- POC 4.5 autonomous scenario;
- three fresh fishbowl scenarios after spawn changes;
- POC 4 regressions;
- rendered visual capture scenario at 10x presentation settings.

A new sixty-day run is **not required** unless simulation behavior materially changes beyond cohort placement.

If cohort placement or presentation changes unexpectedly affect long-run stability, run the sixty-day test.

---

## 43. Visual Evidence

Capture actual production viewport images for at least:

1. startup/default spectator view;
2. water crisis event card;
3. salvage camera shot + title;
4. traversal project card;
5. water recovery;
6. first housing construction;
7. housing completion notification;
8. workshop construction;
9. cohort arrival with distinct citizens;
10. 65+ population settlement;
11. later expanded settlement;
12. diagnostics/details view;
13. manual camera with automatic camera disabled;
14. quiet-state faded HUD.

Every image should be inspected, not merely checked for file existence.

---

## 44. Visual Review Questions

For each relevant capture ask:

- Is the room still the main visual subject?
- Is the text readable?
- Does any panel cover the important action?
- Does the headline describe what is visibly happening?
- Can the citizen/building being discussed actually be seen?
- Is the active project state understandable?
- Are controls obvious but unobtrusive?
- Are there duplicated/conflicting UI elements?
- Does the layout feel like a spectator mode rather than a debug tool?
- Does the 10x experience remain understandable?

Fix generalized presentation problems and rerun captures.

---

## 45. Fast Tests

Add deterministic tests covering at least:

### Spectator UI/state adapter

- status values match production state;
- friendly governor mapping;
- friendly project stage mapping;
- active project card hides without active project;
- traversal card hides after completion;
- default diagnostics false;
- details toggle has no simulation side effect.

### Events

- event kind maps to expected presentation class;
- duplicate suppression;
- major event priority;
- bounded queue;
- real-time lifetime independent of simulation speed;
- event card does not modify simulation.

### Speed

- fishbowl starts 10x;
- normal launch/config remains 1x;
- Pause/1x/4x/10x use authoritative simulation speed.

### Cohorts

- five unique points;
- all walkable;
- all connected;
- minimum spacing;
- blocked fixture refuses whole cohort;
- no partial spawn;
- normal valid fixture creates five real citizen nodes.

### Development progress

- development task progress reads development project fraction;
- traversal task progress remains traversal-specific.

### Camera/presentation

- shot title derives from actual shot/event;
- camera-disabled state creates no automatic movement;
- title card has no simulation side effect.

---

## 46. Full Production Scenario

The full fishbowl scenario must remain an observer.

The harness may:

- enable fishbowl mode;
- advance production ticks;
- capture screenshots;
- inspect UI/camera state;
- record output.

It must not:

- issue Secure Water manually;
- select salvage;
- create development projects;
- spawn cohorts directly;
- inject stock;
- move citizens;
- force governor modes.

Verify the canonical autonomous chain still works.

---

## 47. Repeatability

Because cohort spawn logic changes, run at least:

> **3 consecutive fresh eight-day fishbowl scenarios**

Each should demonstrate:

- autonomous survival;
- traversal;
- salvage;
- housing;
- workshop;
- at least 65 real citizens;
- distinct valid cohort positions;
- no failed tasks caused by arrival changes;
- conserved economy.

Do not count failed retries as consecutive successes.

---

## 48. Performance

POC 4.6 should not materially degrade the simulation.

Presentation systems should avoid:

- rebuilding large UI trees every frame;
- repeatedly formatting the full event history every frame;
- expensive world scans in UI refresh;
- per-frame layout recreation;
- unbounded tween/event accumulation.

Prefer:

- reusable controls;
- event-driven updates where practical;
- modest periodic refresh for values;
- bounded toast/title queues.

Report measured impact if noticeable.

---

## 49. Accessibility / Readability

At minimum:

- high contrast text;
- no critical information communicated only by color;
- sufficiently large text for 1080p desktop viewing;
- wrap/truncate gracefully;
- avoid rapid flashing;
- avoid very short notification durations.

No formal accessibility certification is required for this POC.

---

## 50. Error Handling

If presentation data is unavailable:

- do not crash;
- omit or gracefully degrade the card;
- diagnostics may expose the underlying issue;
- do not invent placeholder state that looks authoritative.

If camera focus becomes invalid:

- return to a safe overview;
- do not teleport citizens or alter navigation.

---

## 51. Documentation

Update:

- `README.md`;
- `PROJECT_PROGRESS.md`;
- `docs/POC45_FISHBOWL.md` or create `docs/POC46_SPECTATOR.md`;
- relevant launch instructions;
- verification summary.

Document:

- fishbowl default 10x;
- auto camera behavior;
- diagnostics toggle;
- event notifications;
- project card;
- cohort arrival behavior;
- remaining presentation limits.

---

## 52. Verification Directory

Store new evidence under:

`verification/poc46/`

Suggested structure:

```text
verification/poc46/
  baseline/
  fast/
  scenario/
  repeatability/
  visuals/
  launcher/
  acceptance.md
  visual-review.md
  final-report.md
```

Do not overwrite historical POC 4.5 evidence.

---

## 53. Acceptance Criteria

### Baseline / preservation

- **AC-1** — Work begins from verified POC 4.5 baseline or descendant.
- **AC-2** — POC 4.5 fast baseline passes before modifications.
- **AC-3** — POC 4 manual regression remains green after modifications.
- **AC-4** — Normal RoomScale launch still defaults to manual/non-fishbowl behavior.
- **AC-5** — Normal launch still defaults to 1x.

### Fishbowl launch

- **AC-6** — Dedicated fishbowl launch requires no gameplay input.
- **AC-7** — Dedicated fishbowl launch defaults to 10x.
- **AC-8** — Pause/1x/4x/10x remain functional and authoritative.
- **AC-9** — Automatic camera defaults on in fishbowl.
- **AC-10** — Automatic camera can be disabled without affecting simulation.

### Default spectator UI

- **AC-11** — Fishbowl defaults to compact spectator HUD rather than dense POC dashboard.
- **AC-12** — Status bar shows day, population, shelter, food days, water days, wood, metal, and speed.
- **AC-13** — Governor state/reason is visible in concise spectator language.
- **AC-14** — Default UI does not obscure the center of the room unnecessarily.
- **AC-15** — Default spectator UI is readable at 1920×1080.
- **AC-16** — Default spectator UI is readable at 2560×1440.
- **AC-17** — Decorative UI does not block world/camera input.

### Diagnostics

- **AC-18** — Detailed diagnostics are hidden by default.
- **AC-19** — Diagnostics can be toggled during fishbowl.
- **AC-20** — Diagnostics preserve useful POC 4.5 information.
- **AC-21** — Diagnostics toggle has zero simulation side effects.
- **AC-22** — No duplicate/conflicting dense HUD remains visible in default spectator mode.

### Event presentation

- **AC-23** — Water crisis produces a readable temporary event card.
- **AC-24** — Salvage authorization produces a readable temporary event card.
- **AC-25** — Traversal completion produces a readable temporary event card.
- **AC-26** — Development start/completion produces readable temporary event cards.
- **AC-27** — Cohort arrival produces a readable temporary event card with new population.
- **AC-28** — Growth/carrying-capacity pause produces a readable reason.
- **AC-29** — Event cards derive from production event/state data.
- **AC-30** — Event presentation suppresses duplicate spam.
- **AC-31** — Event queue/history is bounded.
- **AC-32** — Event display duration uses real time and remains readable at 10x.

### Context cards

- **AC-33** — Active development project card appears only while relevant.
- **AC-34** — Project progress equals authoritative production project progress.
- **AC-35** — Project materials equal authoritative delivered/required amounts.
- **AC-36** — Traversal context appears during the initial route story and disappears after it is no longer relevant.
- **AC-37** — Development task-board progress uses development progress rather than traversal stage progress.

### Camera / title presentation

- **AC-38** — Meaningful automatic camera shots receive a concise title/subtitle.
- **AC-39** — Shot title describes the actual current focus/event.
- **AC-40** — Major events outrank routine activity.
- **AC-41** — Camera still periodically returns to an overview.
- **AC-42** — Close shots make citizens/activity visibly inspectable.
- **AC-43** — Camera/title presentation has no simulation side effects.

### HUD de-emphasis

- **AC-44** — HUD de-emphasizes/fades after a quiet real-time period.
- **AC-45** — Major events/interaction restore relevant UI visibility.
- **AC-46** — Faded HUD remains sufficiently legible for glanceable vital signs.

### Cohort arrival

- **AC-47** — Every five-person cohort receives five distinct arrival positions.
- **AC-48** — All arrival positions are walkable and connected.
- **AC-49** — Arrival positions avoid obstacles/completed structures.
- **AC-50** — Arrival positions maintain meaningful spacing.
- **AC-51** — Failure to find five valid positions blocks the entire cohort rather than creating a partial cohort.
- **AC-52** — Valid cohorts still create five real normal CitizenAgent nodes.

### Integrated behavior / verification

- **AC-53** — Full autonomous production scenario still reaches at least 65 real citizens.
- **AC-54** — Three consecutive fresh eight-day fishbowl scenarios pass.
- **AC-55** — Autonomous survival/salvage/traversal/development still use production systems with no stock injection or citizen teleportation.
- **AC-56** — Economy/resource conservation remains valid.
- **AC-57** — Rendered visual evidence covers startup, crisis, salvage, traversal, housing, workshop, cohort, expansion, diagnostics, manual camera, and quiet HUD.
- **AC-58** — Visual captures are actually inspected and documented.
- **AC-59** — No runtime LLM/API planning is introduced.
- **AC-60** — No manual Godot editor work is required from the user.

---

## 54. Definition of Done

POC 4.6 is done when:

1. the user launches `RUN_ROOM_SCALE_FISHBOWL.ps1`;
2. it starts autonomously at 10x;
3. the default screen is a clean spectator view, not a debug dashboard;
4. the colony's vital signs are understandable at a glance;
5. major autonomous decisions appear as readable temporary events;
6. the automatic camera explains important shots with unobtrusive titles;
7. construction progress appears contextually;
8. dense diagnostics remain available but hidden by default;
9. cohorts arrive as five visibly distinct real citizens;
10. the canonical autonomous simulation still grows and remains correct;
11. three fresh eight-day runs pass;
12. POC 4/manual behavior remains intact;
13. visual captures demonstrate that the result is genuinely pleasant to watch.

The intended reaction should be:

> **"I can leave this running on another monitor and understand the little civilization's story without touching anything."**

---

## 55. Anti-Fake Rule

Presentation must reflect the real simulation.

Specifically prohibited:

- UI-only fake population;
- fake resource numbers;
- fake construction percentages;
- scripted event cards unrelated to actual events;
- scripted camera timeline pretending simulation activity;
- test-only building completion;
- test-driven strategic actions;
- stock injection;
- citizen teleportation;
- fake cohort visuals that are not production citizens;
- altering simulation state merely to make a screenshot look better.

As with earlier RoomScale POCs:

> **Ugly but systemic remains preferable to polished but fake.**

POC 4.6 should make the systemic result pleasant to watch without weakening that rule.
