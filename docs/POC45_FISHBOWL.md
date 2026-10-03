# Autonomous Colony / Fishbowl mode

Run `./RUN_ROOM_SCALE_FISHBOWL.ps1`. The canonical room starts with 50 real citizens,
the original POC 4 water problem, zero construction stock, and the governor enabled.
No gameplay input is required. Pause / 1x / 4x / 10x remain authoritative fixed-tick
controls. Turn off **Automatic camera** to pan/orbit manually, or launch with
`-ManualCamera`. Citizen inspection remains available. `RUN_ROOM_SCALE.ps1` retains
manual POC 4 strategy; selecting the new room alone does not enable autonomy.

## Strategic control

`AutonomousGovernor` evaluates every five simulation seconds. It sets existing
planner priorities, invokes `secure_resource` and transactional `authorize_salvage`,
and requests settlement projects. Citizens continue selecting and executing their
own production tasks. There is no runtime model/API call.

Emergency entry is below one reserve day; recovery requires both reserves at least
two days and a thirty-second hold. Survival is Critical during an emergency and
High otherwise; Resources and Construction are High, Exploration Low. Directives
are idempotent. Material acquisition can remain the current objective during an
emergency; new development is suppressed until reserves recover. Approved existing
projects continue through ordinary work.

The governor includes material reservations, active traversal and development,
finite source horizon, shelter and population state. The HUD distinguishes the
governor's current objective/reason from the cohort eligibility reason.

## Safe salvage

Selection ranks useful shortage yield, distance, remaining work cost and surface
value, with object ID used only as a deterministic tie-break. It rejects depleted
objects, settlement infrastructure, explicit `resource_profile.protected: true`,
finite content sources, resource-support surfaces, active traversal support and
objects without a genuinely reachable physical edge. A RoomDefinition profile's
default protection still means manual authorization is required; fishbowl's explicit
policy may authorize it, while explicit data protection is always respected.

Candidate navigation is evaluated on a deep copy. Failure commits nothing to the
live definition, grid or planner. Authorization uses the POC 4 production interface;
on-site citizen work yields finite bundles, and physical hauling creates depot stock.
The governor waits for already authorized salvage and outstanding useful bundles
before authorizing another object.

## Development

`SettlementDevelopmentSystem` owns one active settlement project and persistent
completed project records. It does not replace the traversal ConstructionSystem.

| Module | Cost | Base worker effort | Completed effect |
| --- | --- | --- | --- |
| Housing | 10 wood, 2 metal | 90 seconds | +10 shelter, +2 rest positions |
| Workshop Annex | 8 wood, 4 metal | 100 seconds | Future settlement work costs 15% less; one bounded workshop effect |

Projects advance PLANNED → WAITING_FOR_MATERIALS → SUPPLIED → UNDER_CONSTRUCTION →
COMPLETE. FOUNDATION, FRAME, SHELL and COMPLETE meshes reflect real worker progress.
Economy tickets carry project IDs; the existing delivery task verifies ownership,
pickup location, distance travelled, carried resource and arrival. Builders use the
existing construction work task. Delivered tickets are consumed only at completion.
Effects apply once. Buildings persist for the session.

Sites are ranked by distance from the average settlement landmarks, with stable
coordinate tie-breaks, on a sixteen-inch candidate grid. Bounds, object/structure
overlap, practical four-inch clearance, traversal space, activity/rest/source
positions and connected floor paths are checked. Proposed obstacles are tested in
temporary navigation. A completed twelve-by-ten-inch footprint becomes a real
navigation obstacle and existing moving citizens replan. Citizens occupying that
footprint delay completion; they are never displaced. Rebuilding navigation clears
the old grid before marking current obstacles, preventing stale blocked cells.

Projects are requested only when remaining safe stock/bundles/salvage can fund their
entire cost. A sixty-second retry bounds repeated development searches. When finite
materials cannot fund another building, expansion pauses rather than creating an
unfundable permanent project.

## Cohorts and finite capacity

`PopulationSystem` adds five real CitizenAgent nodes after 300 sustained healthy
seconds, with a 600-second cohort cooldown and hard cap 150. A whole cohort requires
five spare shelter places, both forecasts at least two days (also after admission),
urgent count no greater than max(3, 25% of population), no survival emergency or
material blocker, and a five-day finite source horizon for the projected population.
New nodes receive normal needs, valid connected floor arrival, shared tasks and
ordinary movement/self-care/work. Forecast demand changes immediately.

The canonical room copies POC 4's objects, settlement, elevated water dependency and
starting stock. Its finite food/water contents are 40,000/60,000. Two ordinary wood
packing crates provide additional finite material. Sources never refill and furniture
never yields twice. No new renewable economy is introduced. The current canonical
material pool naturally limits expansion below the hard population cap.

## Journal, camera and verification

`EventJournal` retains 128 macro events and bounded duplicate-suppression state.
Events record simulation time, evidence, reason, target and major classification.
The camera reads events and actual activity, holds shots at least eight real seconds,
uses the existing smooth camera rig, and returns wide at forty-second intervals.
Disabling the camera leaves simulation unchanged.

```powershell
./TEST_ROOM_SCALE_POC45.ps1 -Mode All
./TEST_ROOM_SCALE_POC45.ps1 -Mode Scenario -CaptureVisuals
./TEST_ROOM_SCALE_POC45.ps1 -Mode Stability -CaptureVisuals
./TEST_ROOM_SCALE_POC4.ps1 -Mode All
./TEST_ROOM_SCALE_FAST.ps1
```

The full fishbowl test enables autonomy once, observes it and advances production
ticks. It never issues strategic decisions, injects stock or assigns workers.
Isolated fast-test fixtures initialize their own stock for targeted accounting
tests; they are separate from the canonical production scenario.
The runner rejects missing markers/results, errors, nonzero exits and timeouts.
Repeatability requires at least three fresh successes; the stability gate requires
sixty days and operation with at least 100 real entities. Reports/captures and the
55-criterion evidence matrix live under `verification/poc45/`.

Finite survival resources eventually exhaust. Save/load, death, families,
reproduction, farming, factories, free placement and runtime LLM planning remain
outside this POC. The colony can stabilize at carrying capacity, but finite resources
do not promise eternal survival.
