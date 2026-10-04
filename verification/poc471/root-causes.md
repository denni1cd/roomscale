# Production failure investigations

## BUG-471-01 — Shelter rest apron permanently blocks bootstrap depot (High)

Classification: C, production placement bug. Reproducer: POS-006, seed 471005,
Mixed Obstacle Routing. The definition passes schema, production navigation,
reachable finite material and primitive shelter/depot feasibility checks. The
initial campaign completes shelter at 150.9s at `(0,0,14)`, with its work/housing
anchor at `(0,0,23)`. No depot project is ever created in 4800s.

Production `select_site` reserves 22 inches around the future depot center
`(0,0,37)` before choosing shelter, but does not reserve space for the *future
rest slots* created by that shelter. Completion sets housing_station to the
shelter target and raises rest_capacity to five. Rest slots derived at approximately
z=39 intersect the depot's required clear apron. `valid_site` then correctly
rejects the depot on every retry. This is permanent geometry, not a passing
citizen, material shortage, insufficient worker labor, or slow hauling.

The initial snapshot proves the fixed depot was valid before shelter completion.
Final diagnostics show one real completed shelter, no active project, an
observable site refusal, and eventual water crisis. Conservation remains intact.
Adding food/water would only delay the same failure.

Implemented minimal repair: exclude primitive shelter candidates whose prospective
housing/rest anchors occupy the already reserved bootstrap depot apron. Retain
the actual depot pickup, inventory, physical delivery, material costs and timers.
No citizens or inventory are relocated and no infrastructure is granted. The
focused seed now completes the whole founder sequence. POC47 Fast plus three
fresh complete canonical scenarios pass; POC46 Fast, POC45 Fast, and POC4 Fast,
contract and cleanup regressions pass. Full campaign results are retained separately.

The enhanced pre-fix observer detects this as actual strategic deadlock at 1820s,
before reserve exhaustion obscures its cause. Relevant evidence is under
`prefix-reproduction/` and `postfix-regression/`.

Exact pre-fix reproducer:

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/initial/POS-006/config.json -OutputDirectory verification/poc471/prefix-reproduction -Workers 1
```

## BUG-471-02 — Grid entry after rebuild cuts a completed structure corner (High)

Classification: C, production navigation bug. POS-018, seed 471017. The scenario
passes production navigation, origin connectivity, material and initial site
checks. Shelter completes at `(4,0,24)` at 141.8s. A nearby patrol citizen is outside
the real footprint, but its rounded start cell is now solid. Repath selects the
first nearby walkable cell `(6,0,16)`. The straight segment from the actual citizen
position to that cell cuts the shelter corner. At 141.9s the citizen enters the
footprint at `(9.664463,0,19.15223)` and the continuous invariant stops execution.

`FloorNavigation.path_between` only validates grid cells. Its initial connection
from the real start position, and final append to the real destination, do not
check physical obstacle intersection. A* itself is not teleporting; the citizen
moves at the correct bounded speed along an invalid connector.

A small production-navigation fixture reproduces this without needing the full
simulation: one completed-sized obstacle, a legal start beside its corner, and a
legal finish. It also tests the reverse connector. The test calls the real
`FloorNavigation.path_between` API.

Implemented repair: choose a nearby walkable cell with a physically clear connector
to a legal exterior endpoint. Preserve grid size, walking speed, citizen positions,
A* topology and fixed tick timing. The original seed now completes the whole
founder sequence with no footprint or movement violations.

Regression-driven scope correction: an initial broader patch also refused all
obstacle endpoints. Existing POC45/46 fixtures exposed established-room housing
anchors intentionally inside prebuilt module footprints; rejecting those anchors
made the existing site-validation contract unusable. That broader change was
removed. The accepted repair preserves the established interior-anchor behavior
and only makes exterior connectors physically safe. Founder campaign invariants
still forbid citizens inside obstacles, including after every completion. The
legacy interior-anchor assumption is documented as architectural debt rather
than silently weakening the founder assertions.

```powershell
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/poc471_navigation_test.gd
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/campaign-1/POS-018/config.json -OutputDirectory verification/poc471/navigation-regression
```

## BUG-471-03 — Failed navigation immediately recurses into another task (High)

Classification: C, latent production failure handling exposed by the safer connector
checks. POC45 Fast reports its logical checks as PASS but the process log contains
stack overflow in `Citizen._navigate_to -> _assign_next_task -> _navigate_to`.
The batch runner correctly rejects this despite the printed PASS marker.

When a path is unavailable, `_navigate_to` marks the task failed. The coordinator
adds replacement routine work. The citizen immediately claims that work recursively
in the same call stack. If replacement routes are also unavailable, there is no
tick boundary or termination condition; task history grows and GDScript overflows.
Returning a safe empty path is allowed production navigation behavior and must not
cause a crash. This issue existed before the connector repair but unsafe snapping
masked some failures.

Focused reproducer uses the real FloorNavigation, TaskCoordinator and CitizenAgent
on an isolated blocked floor fixture. It supplies no economy, materials, capabilities
or project progress. The end-to-end campaign never mutates a live grid or assigns
citizen work. The unit fixture checks that one failed navigation creates one failed
task plus one replacement, then ten existing idle retries remain bounded and do
not move the citizen.

Implemented minimal repair: after recording unavailable navigation, enter existing
IDLE behavior and let its ordinary 0.5s retry run on subsequent ticks. Do not recurse,
teleport, relax path safety or change task selection priorities.

```powershell
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/poc471_unreachable_task_test.gd
./TEST_ROOM_SCALE_POC45.ps1 -Mode Fast -OutputDirectory verification/poc471/regressions-complete/poc45-fast
```

## BUG-471-04 — Uncollectable fractional floor reserve blocks traversal (High)

Classification C. EDGE-FRACTION-01 adds a valid finite 0.5-unit floor puddle to a
passing Long Water Haul input. The main floor source contains 69 water and the
elevated source 60000, with enough reachable finite salvage and building space.
The complete founder infrastructure and growth occur legitimately. Main bootstrap
water is fully extracted, but the extra 0.5 water remains forever: production work
options require at least one available unit. `plan` nevertheless treats *any*
positive floor remaining amount as usable bootstrap supply and never requests
advanced traversal. The final state is a survival crisis despite reachable-by-
legitimate-technology elevated water. This is not finite-resource scarcity: a
completed workshop and sufficient finite salvage can construct the route.

Minimal repair: floor-bootstrap suppression uses the same minimum one-unit
collection condition, preserving already reserved collectable water until actual
extraction. The fractional source is neither refilled nor magically extracted.
Add this exact input to the reusable full matrix and re-run the complete campaign.

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/fraction-prefix/EDGE-FRACTION-01/config.json -OutputDirectory verification/poc471/fraction-postfix -Workers 1
```

## BUG-471-05 — Derived founder patrol anchors can be inside furniture (High)

Classification D, unsupported origin-neighborhood assumption with a narrow
configuration repair. EXP-ROUTING-03/04/05 retain legal, connected founder spawns,
sources, enough safe salvage and shelter/depot sites. An ordinary protected box
at `(-12,0,60)` covers the compatibility patrol anchor `(-12,0,58)`, which is derived
from the founder origin. The first patron reaches that illegal target at 2.2s;
the observer detects entry into its footprint before construction even starts.

This is not a sealed-off or resource-impossible room. The production task initializer
should choose a legal floor patrol point when deriving activity targets from an
arbitrary safe origin. Minimal repair: only obstructed/out-of-bounds founder patrol
anchors are resolved to the production navigator's nearest walkable position during
coordinator configuration. Inventory, depot pickup, citizens and completed structures
are untouched. Clear existing patrol anchors retain exact coordinates.

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/exploration-before-fraction/EXP-ROUTING-03/config.json -OutputDirectory verification/poc471/patrol-postfix -Workers 1
```

## ASSUMPTION-471-01 — Available-queue age counted as live execution age

Classification B, incorrect earlier regression assumption. POC4 sustained reaches
4997.1s with conserved food/water/materials. An ordinary patrol task was *created*
at 4371.2s but waited available while survival work took precedence. It was claimed
and activated only immediately before the final sample (`started_at=58989` versus
end around `59034` wall milliseconds). The test measures 625.9s from creation as
if this were 625.9s of active/reserved work and fails its unchanged 600s limit. The
citizen is physically moving and the case is not stuck.

Repair observability, not the threshold: record simulation-time claim/activation
timestamps in the production coordinator. The earlier regression uses live age
from these timestamps, retaining the 600s limit, movement limit, history bounds,
conservation and zero-failed-task assertions. The robustness observer continues
to report total creation age as a separate diagnostic and detects attributable
progress. Fix the earlier failure-message formatting so an empty audit error array
does not hide the actual limit that failed.

## BUG-471-06 — Legal narrow aisle has no directly visible grid cell (High)

Classification C; a regression introduced by the first connector repair, exposed
by the complete POC 4 sustained run after correcting its live-age assumption.
One citizen interrupts routine work at `(-16.84314,0,54.03841)` between the
workshop upper padded edge (z54) and housing lower padded edge (z54.5).
This half-inch legal aisle has no 4-inch grid centers. Every direct connector
crosses one footprint, so the new physical check correctly refuses the old unsafe
snap but leaves the citizen unable to move. Retained history records 1,310 failed
NEED_EAT retries for citizen29 starting4382.4s; accounting remains conserved.

`task-failure-position-valid/sustained-7days.log` retains the exact position, task
and reason. The focused navigation test adds these two production-sized obstacles,
checks forward and reverse routes, and samples each segment for intersection.

Narrow repair: only if an exterior endpoint cannot directly see any grid cell,
try a physically clear obstacle corner and then a clear connector to A*. The same focused fixture also exposed an internal diagonal cutting the padded
workshop corner. A* now permits diagonals only when both adjacent cells are
clear; the previous at-least-one-clear policy allowed corner clipping. No
teleport, grid-size change, obstacle exception, movement-speed change or task
assertion relaxation is used. The ordinary direct connectors remain unchanged.
This one-corner fallback is bounded and does not promise general sub-grid mazes.

```powershell
./TEST_ROOM_SCALE_POC4.ps1 -Mode Sustained -OutputDirectory verification/poc471/narrow-aisle-postfix -TimeoutSeconds 400
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/poc471_navigation_test.gd
```
