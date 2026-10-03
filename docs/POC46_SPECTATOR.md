# POC 4.6 spectator mode

Run `./RUN_ROOM_SCALE_FISHBOWL.ps1`. It starts the production colony at **10x**,
with automatic camera enabled and diagnostics hidden. No Godot editor work or
strategic input is needed. `./RUN_ROOM_SCALE.ps1` remains manual at **1x**.

## Watching and controls

The edge-anchored HUD shows simulated day, real population/shelter capacity,
food/water reserve days, available wood/metal, speed and a plain-language governor
summary. Population `80/90` means 80 real citizens and 90 shelter places.

- **Pause / 1x / 4x / 10x:** change the authoritative fixed-tick clock.
- **Auto camera:** disable to use the existing right-drag orbit, middle-drag pan,
  mouse-wheel zoom and WASD controls. `-ManualCamera` launches with it disabled.
- **Details / F3:** open a scrollable inspector with raw governor/planner reasons,
  directives, traversal/development state, selected object/citizen, accounting and
  the bounded event journal. Click world objects/citizens to inspect them.

Only buttons and the details scroller intercept mouse input. Decorative cards
allow world interaction. Normal RoomScale retains its original detailed HUD.

## Presentation rules

`FishbowlNarrativeAdapter` translates production values without maintaining a
second simulation. `FishbowlEventPresenter` consumes journal sequence IDs, suppresses
equivalent messages, holds at most eight pending cards and 128 suppression keys,
and serves higher-priority cards first (FIFO within each priority). A card already
being read finishes its hold: major cards last eight real seconds, others five,
with 0.35-second fade-in and 0.65-second fade-out. Simulation speed does not affect
these clocks. Event dates make delayed notifications distinguishable from current
state. No card issues gameplay orders.

Development cards use exact work/required-work and delivered/required materials.
The grapple card disappears after deployment. Development progress on the task
board now reads that same development project; traversal tasks retain their stage
progress. Costs, effort rates and completion rules are unchanged.

The camera retains eight-second minimum holds and a forty-second overview interval.
Production events take priority over routine activity. Object/building context
alternates with real worker detail when available; worker views follow actual nodes.
Cohort views follow their current centroid and widen as the five citizens disperse.
The existing camera rig interpolates position and distance. Six-second titles explain
the selected event/activity. Turning the director off stops its camera writes.

After ten quiet real seconds the status/controls fade to 76% opacity. Events,
titles, hover, speed changes and camera/details toggles restore emphasis. Information
never disappears completely. No simulation speed or need is changed by fading.

## Whole-cohort placement

Before admission, PopulationSystem searches a deterministic local set of floor-grid
centers around the housing arrival area (within 16 inches of the nearest center).
Candidates sort by distance, then z/x. It checks bounds, walkability, obstacle
footprints and an actual depot path for every point. Completed buildings are already
navigation obstacles. Five points must be at least four inches apart, matching the
existing four-inch grid. If fewer than five qualify, no node is created and the
population reason/journal explains the blocked arrival. It never relocates citizens
after spawning. Cohort records retain all five initial positions and their centroid.

## Verification

```powershell
./TEST_ROOM_SCALE_POC46.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC46.ps1 -Mode Repeatability
./TEST_ROOM_SCALE_POC46.ps1 -Mode Scenario -CaptureVisuals
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast
# Optional long stability gate, separate from All:
./TEST_ROOM_SCALE_POC46.ps1 -Mode Stability
```

`All` runs fast plus three fresh eight-day scenarios. The visual observer replays
fixed production ticks, feeding an unscaled presentation clock at the 10x ratio.
It captures both automatic shots and explicitly framed inspection views. For the
first cohort, it stops advancing fixed ticks while actual wall-clock presentation
holds finish, so the five original arrival positions can be inspected. This is an
observer capture pause, not a staged ceremony or a change to the production game.
No resources, directives, salvage decisions, projects or cohorts are injected.

Evidence and the 60-item review: [final report](../verification/poc46/final-report.md),
[acceptance](../verification/poc46/acceptance.md),
[visual review](../verification/poc46/visual-review.md).

## Limits

The room remains the existing procedural POC art. Half-inch citizens are intentionally
tiny in whole-room views; close shots reveal their details. At 10x, new arrivals
quickly leave to perform ordinary tasks. Context shots and queued event dates describe
real events, but do not guarantee every worker is still at the event's original
location by the time a shot begins. Finite resources eventually exhaust. There is
no save/load or new gameplay mechanic, and no runtime model/API planning.

## Building proportions

New development housing and workshops use the citizen's 0.5-inch body height as
reference: doors are 0.7 inches high, floors 0.9 inches high, and housing has two
floors. The 8-by-4-inch building sits inside its existing 12-by-10-inch reserved
yard. Costs, shelter capacity, work targets and navigation reservations are unchanged.
Legacy starting settlement models retain their previous geometry.

Citizen close shots follow subject displacement directly while easing the initial
framing offset. This keeps fast-moving workers in view at 10x. Activity titles hide
when the worker changes task; overview and settlement subtitles read live population.
