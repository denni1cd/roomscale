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
