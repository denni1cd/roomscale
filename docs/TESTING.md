# RoomScale verification

Use PowerShell 7 and Python 3.13 with requirements-dev installed. Commands resolve
output paths against the repository root; absolute output paths are accepted by the
PowerShell wrappers. Python campaign output must remain project-local for RoomDefinition
safety. Set up/import Godot once for a fresh checkout, then run repeatable gates:

```powershell
./SETUP_ROOM_SCALE.ps1
python -m ruff check .
python -m ruff format --check .
./TEST_ROOM_SCALE.ps1 -Mode Fast
./TEST_ROOM_SCALE.ps1 -Mode Canonical
./TEST_ROOM_SCALE.ps1 -Mode Regression
```

| Mode | Coverage | Intended use |
|---|---|---|
| Fast (default) | Ruff check/format; Python provenance/process tests; PowerShell quoting/encoding/env/exit/timeout; RoomDefinition; founder fast; corner/narrow-aisle, unreachable retry, midlink route; core and artifact-write fixtures; POC472 planner immutability/determinism and protected-pocket packing | Every meaningful local change; no long simulation soaks |
| Canonical | Three fresh eight-day five-founder production scenarios with deterministic state/checkpoint comparison | Behavior/timing confirmation |
| Regression | POC46 Fast/scenario; POC45 Fast/survival/scenario; POC4 Fast/contract/cleanup and seven-day sustained; complete Room A and B M2-M6/M8 smoke; 20 retained POC471 exploration cases | Before accepting runtime or harness changes |
| Robustness | POC472 Development: five retained positive worlds, the now-feasible former NEG-03 and 31 placement worlds | A practical placement campaign with 37 expected successful worlds |
| Soak | POC472 retained founder 90/60/60-day scenarios | Explicit expensive retention/exhaustion gate |
| All | All five categories above | Full local acceptance; expensive, not per-commit CI |
| Smoke | Original arbitrary-room production M2-M6/M8 scenario | Room reconstruction and legacy compatibility |

```powershell
./TEST_ROOM_SCALE.ps1 -Mode Robustness -Workers 2
./TEST_ROOM_SCALE.ps1 -Mode Soak -Workers 2
./TEST_ROOM_SCALE.ps1 -Mode All
./TEST_ROOM_SCALE.ps1 -Mode Smoke -Room room_b
# Omitted Mode with explicit legacy room/capture/log arguments retains smoke behavior.
./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360
./VALIDATE_ROOM_SCALE.ps1 -Room rooms/room_poc47.json
```

Activate .venv so `python` resolves to its installed tooling. `-PythonExecutable` can
select an explicit Python executable for top-level/campaign/tooling checks. Default
outputs live in ignored `verification/stabilization/runs/<category>/`. Fast duration
is measured in stabilization final-report; it excludes expensive founder campaigns.

## Specialized and replay commands

Specialized scripts keep their existing modes and assertions; the top runner delegates
rather than duplicating scenario implementation. Historical `All` semantics differ:
POC46 excludes Stability, POC47 runs fast plus repeats, while POC4/45 include more gates.
Use the top-level categories for a clear current hierarchy. No historical coverage is
deleted or silently weakened.

```powershell
# Complete current campaign: 95 exact retained inputs plus 31 placements and one layout negative
./TEST_ROOM_SCALE_POC472.ps1 -Mode Full -Workers 2 -OutputDirectory verification/stabilization/runs/full
# Separate retained probes, including resource/origin/identifier/order boundaries
./TEST_ROOM_SCALE_POC471.ps1 -Mode Explore -Workers 2 -OutputDirectory verification/stabilization/runs/exploration
# Exact retained definition/config replay; no regeneration or resource edits
./TEST_ROOM_SCALE_POC472.ps1 -Mode Reproduce -Scenario verification/poc472/final/POS-001/config.json -OutputDirectory verification/stabilization/runs/replay
# RoomDefinition structural + runtime navigation gate
./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-7/room_photo_luna.json
```

Bulk campaigns observe real fixed production ticks. They report rejected generator
inputs separately from admitted positives, expected negatives separately from success,
and finite exhaustion honestly. They use real extraction, salvage, deliveries, labor,
construction, capability and admission. Focused fixtures may directly configure local
objects/links/inventory to isolate a boundary; their markers do not claim earned gameplay.

The current production baseline is completed POC472. Its Full campaign has 127 expected
outcomes: 112 declared positives, six legacy/new negative labels, six deterministic
repeats and three soaks. NEG-03 retains its historical negative label but now must earn
all normal founding/traversal milestones: its obstacle blocks only the old fixed depot
apron. The five genuine impossible inputs include NEG-05, which is rejected for a
disconnected spawn before stepping. The separate supplemental narrow-pocket evidence
brings historical final evidence to 128 results; it is not an extra default Full case.
POC471 Short/Full retain their older fixed-depot expectation and are not current
acceptance gates; use POC472 Full or exact replay for those retained worlds.

The POC472 observer runs ordinary production steps and checks actual delivery segments,
disjoint settlement aprons, connected work/rest/activity targets and future reservations
on separate navigation grids. Planner/packing fixtures assert immutability, deterministic
selection, bounded trials and feasible downstream geometry without claiming earned
construction. `poc472_unobserved.gd` skips startup planner feasibility queries and per-tick
invariant checks; it still samples milestones and checks connectivity on geometry changes.
Its retained POS-001 control matches the observed physical state and semantic fingerprint.
That single-world control supports observer independence for the demonstrated case.

```powershell
./TEST_ROOM_SCALE_POC472.ps1 -Mode Placement -Workers 2 -OutputDirectory verification/stabilization/runs/placement
./TEST_ROOM_SCALE_POC472.ps1 -Mode Control -OutputDirectory verification/stabilization/runs/control
# Expanded focused and historical regression wrapper
./TEST_ROOM_SCALE_POC472_REGRESSIONS.ps1 -OutputDirectory verification/stabilization/runs/poc472-regressions
```

## Failure handling and evidence

The shared PowerShell process helper uses ArgumentList, asynchronous UTF-8 stdout/stderr
capture, bounded timeout/kill waits, root-relative paths and child-only environment.
It strips inherited ROOMSCALE overrides before setting the explicit scenario values;
parent configuration is preserved. Wrappers require nonzero failure propagation, expected
PASS markers, JSON success where relevant, and no script/engine errors. Campaign reruns
remove prior result/failure files. Timeout/nonzero exit/error logs override a JSON PASS;
a failed provenance audit preserves previously accepted reports and publishes diagnostics.

Python unittest fixtures verify stale PASS rejection, process/engine failure, UTF-8/env
isolation and audit publication. PowerShell tooling tests verify real child quoting,
Unicode, error exit and captured partial timeout output. New Godot core fixtures verify
startup roster integrity, original canonical placements, invalid resource profiles,
raw-ID room lookup and disconnected floor exits. The evidence I/O fixture checks actual
PNG/JSON round trips and rejected unwritable destinations.

Windows CI installs pinned Ruff, imports the existing pinned Godot engine/assets and
runs Fast. It excludes multi-hour campaigns/soaks and subjective visual review. The
workflow itself is locally inspected; only an actual GitHub Actions run can confirm
remote CI execution. Functional headless gates do not claim new visual acceptance.

Keep compact final reports/manifests and required fixtures. Raw local logs/results and
screenshots remain ignored unless deliberately reviewed for publication. Historical
receipt hashes describe their historical source, not the cleanup source. Final cleanup
receipts record the frozen tested SHA and normalized production/harness hashes. If any
executable source changes after verification, invalidate that freeze and rerun its gates.
