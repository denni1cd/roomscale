# RoomScale POC 4.7 final report

**PASS: M0–M9 and AC-01–AC-35. Three fresh complete founder scenarios: 3/3 PASS.**

Branch: `codex/roomscale-poc47-founder-start`.
Baseline: `801060bd3b265e5fcb2d207b36434f9149d31e3a`.
Verified implementation commit: `792f7d08a9abc254e8011272d80dc5d1ed71d9ea`.
Documentation receipt: `aa9ddfe8d6c0784e57524b25ba40f78e112dffad`. Main was
not merged. Pre-existing changes to the historical milestone8 startup log/image were
left out of this implementation.

## Delivered production behavior

`./RUN_ROOM_SCALE_FISHBOWL.ps1` launches `room_poc47` at **1x** with exactly **five
real CitizenAgent nodes**, **no completed civilization infrastructure**, 20 food,
30 water, zero wood, zero metal and zero shelter/rest capacity. Even the unused legacy
traversal stock dictionary is emptied for founder mode. Only portable packs exist.

The same production governor, planner, needs, economy, resources, salvage, citizens,
task coordinator, development, construction and navigation systems build the colony.
The start contract supplies an origin/population/infrastructure list; legacy rooms
retain their original configuration. No separate founder simulation was introduced.

All final runs observed this progression, measured in production simulation seconds:

| Event | Seconds | Approximate 1x time |
| --- | ---: | ---: |
| First project | 5.0 | 0:05 |
| First meaningful resource work | 12.0 | 0:12 |
| First material haul | 49.3 | 0:49 |
| First shelter complete | 156.3 | 2:36 |
| Depot complete | 223.8 | 3:44 |
| Workshop complete | 374.5 | 6:15 |
| Permanent housing complete | 480.0 | 8:00 |
| Sixth real citizen | 785.0 | 13:05 |
| Grapple project | 1319.8 | 22:00 |
| Grapple deployed | 1447.5 | 24:07 |
| Physical climb observed | 1468.0 | 24:28 |
| Elevated territory reached | 1482.5 | 24:42 |

Shelter costs four salvaged wood and sixty worker-seconds. Capacity activates only
after verified material delivery and builder completion. Storage costs four wood/one
metal; workshop eight wood/four metal. Both persist and update capability state only
on completion. The storage pickup apron does not move existing goods. Permanent
housing then adds ten shelter places. The final settlement has fifteen places.

Growth adds one ordinary CitizenAgent after sustained healthy reserves, shelter,
infrastructure and cooldown checks. Every admission immediately reduces food/water
reserve days through increased demand. The workshop gate is enforced at both Reach
and traversal project creation. Traversal uses real deliveries, builder work,
deployment, navigation connections and physical climbing.

## Final gates

| Gate | Result / evidence |
| --- | --- |
| POC46 baseline fast and rendered full scenario | PASS; `baseline/`; clean dummy-audio rerun explains the host audio error |
| POC45 and POC4 baseline gates | PASS; fast, contract and cleanup receipts in `baseline/` |
| Final founder fast | PASS; `final/fast.log` |
| Three fresh eight-day founder runs | PASS; `final/repeat-01..03.json`, 14.42 / 14.96 / 14.77 wall seconds |
| Deterministic repeatability | Identical complete production results; `repeatability-summary.json` |
| Rendered full founding scenario | PASS; `final-render/scenario.json` and 24 production checkpoints |
| Actual canonical launcher | PASS; `launcher/stdout.log` reports five citizens, `room_poc47`, speed 1.0 |
| Live normal-speed opening | PASS; `final-live-1x/result.json`, normal `_process` through first shelter |
| Legacy POC46 full scenario | PASS; `regression/poc46-scenario/`, reaches 80 real citizens |
| Final POC46 presentation fast | PASS; `regression/final-poc46-fast/`, including UI, camera, controls and arrival checks |
| POC45 fast | PASS; `regression/poc45-fast/` |
| POC4 manual full scenario | PASS; `regression/poc4-scenario/` |
| POC4 fast/contract/cleanup | PASS; `regression/poc4-fast/` |
| Room/navigation/schema regression | PASS; `regression/final-navigation.log` |

Each fresh founder run ends at **12 real citizens**, **15 shelter places**, completed
shelter/depot/workshop/housing, deployed traversal and **zero failed tasks**. Every-tick
checks conserve economy, bundles, finite sources and source-backed material generation.
Checks also enforce movement speed, valid needs, earned shelter, workshop prerequisites,
real deliveries/builders, exact consumed costs, stages, growth/cooldowns and bounded
task/project age. No harness injects stock, issues strategic commands after startup,
assigns workers, spawns cohorts or moves citizens.

## Pacing and presentation

The only existing development retry tuning is for temporarily occupied essential
founder sites: retry at the next five-second governor evaluation instead of waiting
sixty seconds. This removed a four-minute depot delay without relaxing collision
checks. Existing walking, need decay, salvage, housing/workshop work and growth timers
remain unchanged. New primitive blueprints provide the hand-construction bootstrap.

The fresh live check records **185.4 simulation seconds in 185.611 wall seconds**,
with speed 1.0, eight captures, zero stderr output and a completion marker. It
observes the opening at normal wall-clock speed. Later milestones are
measured through accelerated execution of identical production ticks; this is not a
claim that the entire eight-day run was watched in real time. Speed controls remain
Pause/1x/4x/10x, and the legacy established room retains its historical 10x setting.

Founder arrival, salvage, shelter, storage, workshop, individual arrival and elevated
resource milestones feed the preserved spectator cards. The camera starts on the
actual founders and handles variable arrival group sizes. F3/details, inspection,
responsive layout and worker shots remain. See [visual review](visual-review.md).

## Limits and continuation

No blocking POC47 defect remains in the tested scenario. Finite supplies eventually
exhaust; save/load, crafting, farming, families and runtime model planning are absent.
No new sixty-day founder run or 150-citizen performance claim is made. Primitive art
is simple, and wide room views make half-inch citizens small. The live pacing sample
covers approximately three minutes; later 1x timings come from production ticks.

[Guide and exact test commands](../../docs/POC47_FOUNDERS.md) ·
[Acceptance matrix](acceptance.md) · [Milestones](milestones.md).
