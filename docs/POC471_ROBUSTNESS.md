# POC 4.7.1 founding robustness

This milestone tests the five-founder production simulation under deterministic
RoomDefinition variations and long runs. It adds validation infrastructure and
narrow bug fixes, not new gameplay. The canonical 4.7 baseline was verified before
production edits and preserved under `verification/poc471/baseline/`.

## Architecture and execution

`TEST_ROOM_SCALE_POC471.ps1` resolves the installed Godot runtime and invokes the
standard-library-only Python campaign runner. `scripts/poc471_campaign.py` copies
`rooms/room_poc47.json`, applies seed-driven transformations, writes a complete
definition/configuration pair, and launches a fresh Godot process for each case.
`scripts/poc471_observer.gd` loads the actual production scene, disables its
wall-clock driver, and calls the existing `CivilizationSimulation.step()` at the
unchanged 0.1s step. Camera/HUD processing is paused for bulk headless observation.
Production rendering nodes are still built; there is no alternate simulation.

The observer does not authorize salvage, issue Reach, assign work, reserve stock,
complete projects, relocate citizens, refill sources, or create population. The
production governor, coordinator, economy, resource/salvage systems, citizens,
construction and navigation perform all of that work normally. Focused isolated
unit fixtures separately exercise floor-route and failed-task behavior; they are
not counted as end-to-end founding scenarios.

Every execution records the complete input, deterministic seed, generator version,
mutation parameters, input hashes, starting commit and normalized source hashes.
Reproduction uses the retained complete definition rather than assuming a future
generator version will produce identical input. Processes have a 1200s timeout;
the Windows engine is launched directly so killing it cannot orphan the console
launcher's child process. Two workers are the default; each world is independent.

## Generator and validation

The first ten cases are individually named adversarial cases. Combined variants
cover six founder-origin regions, spawn widths/offsets, finite resource quantities,
food/water separation, furniture movements, salvage yield budgets and translated
target geometry. Objects remain supported production types and floor resources
are conservatively sampled away from obstacles and the depot apron. Positive
salvage profiles vary legitimate finite stage yields while retaining real labor.

Godot validates the schema and derived navigation before the scene starts. Additional
checks require a legal origin, spawn-to-origin connectivity, reachable floor
resources, a production-valid shelter/depot site, and safe reachable salvage
totalling at least 30 wood / 11 metal (shelter, depot, workshop, housing, grapple).
Food and bootstrap water must meet a conservative finite survival horizon. The
certificate establishes reasonable feasibility, not a proof that the autonomous
policy will choose a successful sequence. That difference is exactly what the
campaign tests. Individual citizens, distinct IDs and legal initial positions are
checked at startup and every subsequent tick.

Rejected inputs are retained with validation reasons and classified `REJECTED`;
they are excluded from valid pass/fail counts. They never run normal positive
ticks. The Full command requires at least 30 admitted positives and all ten named
adversarial passes, even if some generated candidates are rejected. More candidates
provide coverage and make conservative rejection visible rather than disguising
invalid inputs as production bugs.

Five impossible cases cover missing water, only three legitimate wood for the
first shelter, blocked fixed depot site, inaccessible elevated water before
workshop, and disconnected spawn. The disconnected case must be rejected by
navigation/connectivity validation. Other negatives run ordinary production ticks
and pass only if the intended crisis/blockage remains observable without resource,
capability, entity or traversal cheating. They are not positive founding failures.

## Continuous invariants and diagnostics

Every fixed tick checks:

- finite bounded needs and positions, physical movement at most 6.5 × 0.1 inches,
  world bounds, floor footprint exclusion, and legitimate elevated surface/link
  geometry;
- unique IDs, real entity/population agreement, +1 growth events, earned shelter,
  workshop/storage gates, stable/cooldown intervals, immediate increased demand,
  healthy forecasts, emergency suppression and finite carrying capacity;
- production economy/resource audits and generation reconciliation against initial
  stock, source extraction, salvage stages/work and interrupted-delivery exports;
- completion material/labor/delivery witnesses, real citizen labor IDs, visible
  FRAME/SHELL stages, exact once-only project consumption and completion-derived
  capabilities/navigation obstacles;
- traversal workshop gating, physical stage delivery gates and real deployment;
- live task owner validity and bounds on retained/live tasks and journal history.

Whenever navigation geometry changes, connectivity from the depot to floor sources
and housing is recorded. Milestones include first work/salvage/haul, all first
structures, sixth citizen, grapple start/deployment, physical climb and elevation.
Timeline samples retain cumulative task counters, journal sequence and bounded
retention, population/needs/resource state, governor/growth reasons and citizen
state distributions. Final snapshots include the oldest live tasks, complete
development/growth history, source state, salvage, ledger, connections and journal.

Stall checks separate *strategic* progress from patrol/self-care: legitimate material
acquisition, project delivery/work/stages, traversal and arrivals reset the signal.
A 1200s inactive window is diagnostic, not an automatic speed requirement. Missing
progress before required milestones is classified as deadlock only when feasibility
and carrying capacity remain, and no survival emergency explains the stall. Scarcity,
expected impossibility and stable completed/finite progression are recorded separately.
Old strategic tasks are checked for attributable worker movement/work rather than
failing solely on age. Failure packages contain the full input plus all final
diagnostics and an exact reproduction command. Engine errors are failures even
if a test printed PASS earlier.

## Commands

```powershell
# Ten named positives plus five negatives; useful during development
./TEST_ROOM_SCALE_POC471.ps1 -Mode Short -OutputDirectory verification/poc471/short

# Final campaign: 60 generated candidates, five negatives, six repeats,
# and three fresh founder soaks (90/60/60 days)
./TEST_ROOM_SCALE_POC471.ps1 -Mode Full -Count 60 -OutputDirectory verification/poc471/final -Workers 2

# The same three independent long soaks by themselves
./TEST_ROOM_SCALE_POC471.ps1 -Mode Soak -OutputDirectory verification/poc471/soaks

# Additional incremental routing, reserve, origin, ID and ordering probes
./TEST_ROOM_SCALE_POC471.ps1 -Mode Explore -OutputDirectory verification/poc471/exploration

# Exact retained input reproduction; copy the command from its result/config
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/final/POS-018/config.json -OutputDirectory verification/poc471/reproduced

# Generate inputs without running the simulation
./TEST_ROOM_SCALE_POC471.ps1 -Mode Generate -Count 60 -OutputDirectory verification/poc471/generated

# Recover a matrix/summary from finished results of an interrupted campaign
./TEST_ROOM_SCALE_POC471.ps1 -Mode Review -OutputDirectory verification/poc471/final

# Focused production navigation and failure-handling regressions
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/poc471_navigation_test.gd
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/poc471_unreachable_task_test.gd
```

Short, Full and Soak require all admitted cases to pass. Deterministic repeats
compare semantic simulation fingerprints including milestones, project ordering,
population, sources, ledger, tasks, traversal and final citizen state. Wall-clock
timestamps and presentation state are omitted because they do not participate in
production decisions; no simulation tolerances are loosened.

## Evidence and limits

`verification/poc471/campaign-summary.json`, `scenario-matrix.md`, `findings.md`,
`root-causes.md`, `multiciv-readiness.md` and `final-report.md` summarize the final
campaign. Baseline, initial failures, focused regressions, prior attempts and final
per-case artifacts remain separate. The final report identifies the tested source
commit and the later evidence-only commit can be resolved with `git rev-parse HEAD`.

This is variation of a supported rectangular-room topology with one elevated
target, not a proof over arbitrary room reconstruction, heights, scales, disconnected
worlds or multiple civilizations. The fixed depot apron, generated activity anchors,
finite transport throughput and initial-infrastructure legacy behavior remain
important boundaries. The audit explicitly covers shared-world resource ownership
and namespaces without implementing a second civilization.
