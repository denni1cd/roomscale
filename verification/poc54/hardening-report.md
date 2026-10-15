# POC 5.4 pre-merge hardening

Review baseline: `c148f84fb81c4c6fce91565c01303971e0d01358`.
Implementation/test source: `428afeb73b6f73d2d2e45ebb9e1543bef3fb50f7`.
Branch: `codex/poc54-military-doctrine`. No merge to main.

## Reservation ownership contract and caller audit

All six EconomySystem reservation transitions now require `expected_owner: String`:
`pickup(id, expected_owner)`, `deliver(id, expected_owner)`,
`consume(id, expected_owner, project=false)`, `release(id, expected_owner)`,
`drop(id, expected_owner)`, `recover_delivered(id, expected_owner)`.
Release now returns a success boolean. Exact owner matching precedes any mutation.
Legal states remain reserved -> pickup, in_transit -> deliver/drop,
reserved/delivered -> consume, delivered -> recover_delivered, and any of the
three live states -> release. Correct-owner accounting and transitions are unchanged.
No default, wildcard, or ticket-derived bypass owner was introduced.

All production mutation callers were audited and migrated:

| Caller | Expected reservation owner |
|---|---|
| ArmorySystem partial-order release and completed consumption | equipment project id; existing armory preflight retained |
| ConstructionSystem pickup/delivery/completion | existing `traversal` owner |
| SettlementDevelopmentSystem pickup/delivery/completion | active development project id |
| InnovationRuntime pickup/delivery/completion | active innovation project id |
| InnovationRuntime cancellation recovery/release | cancelled innovation project id |
| ProductionRecipeRegistry fabrication consumption | task.fabrication_owner |
| CivilizationSimulation self-care consumption | citizen:<real citizen id> |
| CivilizationSimulation interrupted-task drop/release | same task-derived citizen/fabrication/project/traversal owner used at reservation |
| Existing POC4 fast economic fixture | its original project/cancelled-care/traversal owners |

`economy_ownership_test.gd` checks all six operations from each of the three states.
Project A cannot mutate Project B's reservation. Rejections compare full snapshots,
tickets, consumed/project-consumed/exported totals and next-ticket id. Correct-owner
legal and illegal transitions, unknown tickets, project consumption, and audit
conservation are checked. The standard POC54 aggregate runs this new focused test.
Current construction, innovation, fabrication and armory flows are exercised by the
historical gates and zero-stock live POC54 suite.

## Prepared Fire

MilitaryAbilities reads eligible roles, seconds, tolerance and interval multiplier
from MilitaryCatalog.CAPABILITIES.PREPARED_FIRE. Citizen inspection uses the same
interval handler. Production values are unchanged: Ranged/Artillery, 2.0s, 0.25in,
0.85 interval. A duplicated local definition with Line/0.6s/0.1in/0.7 proves that
all four fields drive the handler without editing the production catalog. Existing
exact approved-value boundaries and real 11-/30-tick attack cadence assertions pass.
Source search found no remaining production Prepared Fire literal duplication;
matching numbers in role grades, visual geometry and unrelated workshop bonuses
are unrelated data, and explicit expected numbers remain in verification assertions.

## Demobilization review

A missing return route was a real safe-failure gap: assign_combat_duty returned
false while leaving previous military duty/route/arrival intact. All four relevant
call sites request the same RETREAT duty: readiness cancellation, CombatSystem
stand_down, morale retreat, and post-capture return. A failed return now stops the
old route, sets RETREAT/RETURN_BLOCKED, clears arrival, retains position and kit,
and retries existing navigation once per native simulation step. Existing geometry
replans preserve military duty rather than entering the ordinary task failure path.
A permanent disconnection remains inspectably blocked indefinitely.

Focused tests obstruct the depot connection during equipped cancellation, battle
stand-down, retreat and actual SECURE-to-COMPLETE victory. They verify no movement,
no premature stock return, preserved kit/citizen mapping, pending cancellation,
then restored ordinary navigation and actual physical arrival before stock return.
Each battle fixture also fails a mid-return replan. Three fresh processes produce
identical focused evidence. Armory return/loss/reservation checks are retained:
reserved unissued kits can be released, issued kits require the living mapped
citizen at the depot, casualty kits become terminal LOST without refunds.

## Verification and scope

Commands run from repository root (PowerShell 7):

```powershell
./TEST_ROOM_SCALE_POC54.ps1 -RunCount 3 -OutputDirectory verification/stabilization/runs/poc54-hardening/final-poc54
./TEST_ROOM_SCALE_COMBAT_ROLES.ps1 -RunCount 3 -OutputDirectory verification/stabilization/runs/poc54-hardening/roles
./TEST_ROOM_SCALE_CONFLICT.ps1 -RunCount 3 -OutputDirectory verification/stabilization/runs/poc54-hardening/conflict
./TEST_ROOM_SCALE_CONFLICT_PRESSURE.ps1 -OutputDirectory verification/stabilization/runs/poc54-hardening/pressure
./TEST_ROOM_SCALE_INNOVATION.ps1 -OutputDirectory verification/stabilization/runs/poc54-hardening/innovation
./TEST_ROOM_SCALE.ps1 -Mode Fast -PythonExecutable .venv/Scripts/python.exe -OutputDirectory verification/stabilization/runs/poc54-hardening
./TEST_ROOM_SCALE.ps1 -Mode Canonical -PythonExecutable .venv/Scripts/python.exe -OutputDirectory verification/stabilization/runs/poc54-hardening
./TEST_ROOM_SCALE.ps1 -Mode Regression -PythonExecutable .venv/Scripts/python.exe -OutputDirectory verification/stabilization/runs/poc54-hardening
```

The final harness-only addition of the victory failure fixture was independently
run three fresh times using Invoke-RoomScaleProcess with the same behavior script,
result paths and a 60s timeout; full JSON equality was checked afterward. Gameplay
source was unchanged during the gates. Initial focused testing caught an unsupported
GDScript bool(Dictionary) test conversion, which was corrected before final runs.

[Replay summary](hardening-replay-summary.json) records exact equality of all live
and ordinary conflict fingerprint fields against the prior accepted evidence,
including military/economic state. Live capture remains tick 4339 with attack digest
`c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2`;
ordinary capture remains tick 2255. Armory and behavior replays each pass 3/3;
Canonical passes three identical founder starts. No balance, recipes, grades,
doctrine, resource availability, capture/morale rules or campaign behavior changed.
Raw runs remain under ignored verification/stabilization/runs/poc54-hardening/.

All requested gates **PASS**, including full Regression: 20/20 exploration worlds,
zero invariant violations and zero deadlocks. Fast includes Ruff and 14 Python
tooling tests; Canonical includes three identical eight-day founder runs. Regression
also includes POC4/4.5/4.6, seven-day sustained operation, Room A/B smoke and focused
navigation/placement. [Gate receipts](hardening-regression-summary.json) retain
hashed pass logs. The final tracked state is clean after documentation/evidence
commit; pre-existing unrelated untracked files are preserved. The completion message
identifies the final published commit, which includes this report.
