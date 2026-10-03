# RoomScale POC 4.5 final report

**Overall: PASS. Milestones M0–M8 complete. All 55 acceptance criteria PASS.**

Branch: `codex/roomscale-poc45-fishbowl`, based directly on verified POC 4
`88f787b0be4a32ad4ea7a273d4f91d95eeb800c9`. No merge into main.
The final published commit SHA is returned in the completion response and Work
receipt; `git rev-parse HEAD` identifies the checkout containing this report.
Individual results and evidence: [acceptance.md](acceptance.md).

## Delivered behavior

`./RUN_ROOM_SCALE_FISHBOWL.ps1` starts a real fifty-citizen autonomous colony.
Actual launcher smoke confirmed governor=true, camera=true and `room_poc45` with
no gameplay input. The governor automatically resolves the original water problem:
needs pressure → Secure Water → real Reach investigation → traversal material
blocker → safe furniture authorization → staged citizen salvage → material hauling
→ traversal construction/climbing → finite water returned to storage. It then
requests real housing/workshop projects and admits real cohorts when safe.

Normal POC 4 launch remains manual. Governor-disabled regression creates no
autonomous directive, salvage, development or cohort. Historical room and POC 4
evidence were not overwritten or reinterpreted.

## Architecture and rules

Added `AutonomousGovernor`, `EventJournal`, `SettlementDevelopmentSystem`,
`PopulationSystem`, and `FishbowlCameraDirector`. They extend the existing citizen,
need/economy/resource/salvage, planner/simulation/coordinator, floor/surface and
traversal systems. Development uses existing CONSTRUCTION_DELIVERY/BUILD tasks
with project ownership; citizens retain ordinary movement and task selection.
The existing transactional salvage correctness fix remains intact.

The governor evaluates every five simulation seconds, enters emergency below one
reserve day, and exits when both forecasts reach two days after a thirty-second
hold. It uses High Resources/Construction, Low Exploration and High/Critical
Survival. Reasons and material/capacity evidence are journaled. Its five-day finite
source horizon and full-cost safe-material check restrain development/growth.
There is no runtime LLM/API planning, stock injection, teleportation, direct worker
assignment or automatic project completion.

Safe salvage ranks shortage yield, distance, remaining destructive work and surface
value. It rejects depleted, settlement, explicitly protected, content-source,
resource-support, traversal-support and genuinely unreachable objects. Already
approved outstanding salvage/bundles prevent unnecessary further authorization.
Candidate evaluation uses temporary navigation; failure leaves live state intact.

Housing costs 10 wood/2 metal and 90 worker-seconds, adding exactly ten shelter
places and two rest positions. Workshop costs 8 wood/4 metal and 100 worker-seconds;
its once-only effect reduces subsequent settlement construction effort by 15%
(housing becomes 76.5 worker-seconds). FOUNDATION → FRAME → SHELL → COMPLETE
presentation reflects real supplied materials and worker effort. Delivered tickets
are consumed once at completion; completed structures persist.

Sites are derived from the mean settlement landmarks and ranked on an outward
sixteen-inch candidate grid. Checks include bounds, object/structure collision,
four-inch passage clearance, traversal space, activity/rest/source targets and
connected floor paths. Proposed navigation is temporary. Completed footprints are
real obstacles; moving citizens replan and citizens are never displaced to finish
a building. Grid rebuilding explicitly clears old solids before current marking.

Cohorts are five real production CitizenAgent nodes, with 300 sustained healthy
seconds, a 600-second cooldown, whole-cohort shelter headroom and hard safety cap
150. Both forecasts must remain at least two days after admission; urgent count
must be no greater than max(3, 25% of population); survival emergencies and material
blockers prevent admission. Arrivals use a valid connected floor location, normal
needs and shared tasks, immediately increasing demand.

The HUD shows authoritative reserves, shelter, development, reasons, macro events
and speed. The journal limit is 128 with bounded duplicate suppression. The camera
reads production events/activity, holds shots at least eight real seconds, returns
wide every forty seconds and can be disabled. Camera/LOD changes do not advance
simulation or move citizens. Existing Pause/1x/4x/10x buttons were exercised against
the authoritative fixed-step clock.

See [the gameplay/system guide](../../docs/POC45_FISHBOWL.md) for continuation.

## Canonical population, structures and resources

The POC 4 room is preserved as the foundation: same original furniture, districts,
elevated water dependency and 300 food/100 water/zero construction stock. Canonical
finite contents are 40,000 food and 60,000 water; two visible ordinary packing
crates add finite material through the existing semantic yield derivation.

- Standard eight-day scenario: 50 → **80 real citizens**, four completed housing
  blocks and one functional workshop. All full-chain assertions pass.
- Sixty-day scenario: 50 → **120 real citizens**, seven housing blocks and one
  workshop; shelter equals **120**. Population reaches 100 at day **11.5**.
- Fourteen five-node cohorts join, obeying capacity/reserve/cooldown rules. Growth
  stabilizes at 120 after day 15.49 and stays there through day 60.0167.
- Finite furniture/crates yield **91 wood/24 metal**. Projects consume **82 wood/
  22 metal** including traversal; **9 wood/2 metal** remain. The remaining wood
  cannot fund another housing block, so further expansion is restrained.
- At the detailed run's endpoint: **718 food (2.9917 days)**, **1026 water (2.85
  days)**, eight urgent citizens, 13,141 meals, 19,717 drinks and 9,963 rests.
- Source accounting: food **26,432 remaining / 13,568 extracted**; water **39,320
  remaining / 20,680 extracted**. Carried/reserved/delivered quantities explain the
  distinction between extracted source stock and received depot stock. Sources never
  refill; six salvaged material objects yield once and remain depleted.

## Verification and measured bounds

M0 ran before production edits: seven POC 4 jobs all passed, including fast,
contract, cleanup, three fresh seven-day scenarios and thirty-day stability.
Room/navigation fast checks passed separately.

The release sequence passed three consecutive fresh full eight-day scenarios.
After final presentation/delivery checks, another three fresh full scenarios passed
in **48.90 / 45.57 / 45.56 seconds**. Final status, projects, cohorts, finite sources,
salvage, events and checks match exactly across those runs after excluding wall
timing (`repeatability-summary.json`). No retry is counted as a consecutive success.

Two production sixty-day runs passed: headless **629.66 seconds**, rendered **600.56
seconds** including capture/harness overhead. The detailed production observer
verifies finite needs/positions, movement speed, economy/source/bundle conservation,
actual entity count, exactly conserved project costs/effects, cooldown/cap rules,
completed navigation, no permanently stuck project and safe finite-capacity stop.
There were **zero failed citizen tasks**.

Observed maxima, sampled every ten simulation seconds: **500 task records, 39 economy
tickets, 10 bundles, 78 journal events, 120 real citizens**. Daily sampled oldest
active task was **271.2 seconds**, active development project **100 seconds**;
these sampled ages are not an exhaustive peak measurement. Maximum per-tick movement
was **0.650005 inches**, within floating-point tolerance of the production 6.5 in/s
speed at 0.1-second ticks. Governor evaluations: **7202** over 36010 seconds.

Detailed rendered-harness throughput averaged about **601 fixed ticks/second**
(approximately 1.66 ms per tick including observer work). This is a functional
production measurement under concurrent verification, not an interactive FPS claim.
Maximum tested population is 120; 150 is the configured safety cap and has targeted
cap-rule coverage, but interactive frame rate at 150 was not measured.

Final POC 4 fast/contract/cleanup passed; the full manual water-crisis scenario and
Room A → Room B → Room A production regression passed (3/3, 12.1 minutes). Final
fishbowl unit tests cover unsafe candidates, lifecycle/accounting, real growth,
navigation transaction safety, stage effects, journal, camera and actual speed
button signals. Inspected final captures include both modules' intermediate stages,
citizen work/hauling/climbing, depleted objects and the mature sixty-day settlement.

Last changes after long-run captures were rendering-only LOD/work poses, stricter
development delivery ownership validation and additional test assertions. Final
fast/full/repeatability and rendered stage evidence reran successfully. Those changes
do not change the successful long-run resource/work/growth path.

## Exact gate commands run

```powershell
./TEST_ROOM_SCALE_POC4.ps1 -Mode All -RunCount 3 -OutputDirectory verification/poc45/baseline -TimeoutSeconds 300
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc45/baseline/room-navigation.log
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc45/regression-fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Scenario -OutputDirectory verification/poc45/regression-scenario
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc45/regression-room-navigation.log
./TEST_ROOM_SCALE_POC45.ps1 -Mode All -OutputDirectory verification/poc45/release -TimeoutSeconds 1200
./TEST_ROOM_SCALE_POC45.ps1 -Mode Stability -CaptureVisuals -OutputDirectory verification/poc45/final-stability -TimeoutSeconds 1200
./TEST_ROOM_SCALE_CROSSROOM.ps1 -OutputDirectory verification/poc45/regression-cross-room -PerRunTimeoutSeconds 360 -OverallTimeoutMinutes 18
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc45/final-regression-fast
./TEST_ROOM_SCALE_POC45.ps1 -Mode Scenario -CaptureVisuals -OutputDirectory verification/poc45/final-visuals -TimeoutSeconds 600
./TEST_ROOM_SCALE_POC45.ps1 -Mode Repeatability -RunCount 3 -OutputDirectory verification/poc45/final-repeatability
./TEST_ROOM_SCALE_POC45.ps1 -Mode Fast -OutputDirectory verification/poc45/final-unit
./RUN_ROOM_SCALE_FISHBOWL.ps1
```

Early targeted runs directly invoked the bundled Godot console with
`--headless --path . --script res://scripts/poc45_survival_test.gd`,
`poc45_fast_test.gd`, and `poc45_scenario_test.gd`; diagnostic logs remain alongside
the successful gates. The initial type error and fixture initialization mistake
were fixed without weakening production assertions or adding free scenario stock.
A duplicated fast-run output directory caused a temporary file-access collision;
the final isolated `final-unit/` run passed and is the authoritative fast evidence.

## Artifact index and remaining limits

- `acceptance.md`: all 55 individual results; `milestones.md`: ordered gate history.
- `baseline/`, `final-regression-fast/`, `regression-scenario/`,
  `regression-cross-room/`: POC 4/manual/room regression.
- `final-unit/`, `final-repeatability/`, `release/`, `final-stability/`: fast,
  full-chain, repeated and long-run logs/JSON.
- `population-shelter-timeline.csv`, `health-metrics.json`,
  `development-history.json`, `governor-event-history.json`: extracted detailed
  production evidence, including stocks, source totals, entities and bounded state.
- `final-visuals/scenario-visuals/`, `final-stability/stability-60days-visuals/`,
  `visual-review.md`: actual inspected PNGs and state sidecars.
- `launcher-smoke.json` and stdout/stderr logs: actual one-command launch.

No known blocking POC 4.5 defect. Finite resources eventually exhaust; stabilization
does not imply eternal survival. No save/load, families/reproduction, death,
renewable farming, factories, interiors, free placement or runtime LLM planning was
added. Existing traversal architecture still supports its original single active
traversal project. Site search and mesh stages are deliberately conservative.
