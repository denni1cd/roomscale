# POC 4.7.1 final report

Branch: `codex/roomscale-poc471-founder-stress`.
Starting SHA: `26dfe0812fcf592e047412078cec2552e2e62b36`.
Frozen tested source SHA(s): `b11fe41b8340123a7fb6ccb022bb0ba06e23f2d3`.
Final evidence-only SHA: resolve with `git rev-parse HEAD` on this branch; it is also supplied in the delivery message. A committed report cannot embed its own commit hash. Source/harness hashes in every final result are checked against the delivered checkout.

## Execution

- Total retained campaign inputs/replays/soaks: **95**; continuously executed worlds: **92**.
- Core admitted positives: **59**. Combined positives: **79 PASS / 0 FAIL**. Generator rejections: **2**; rejected candidates are excluded.
- Named adversarial cases: all ten pass. Negatives: **5/5 expected**, 0 unexpected.
- Determinism: **6/6** identical fingerprints; three variants each have two fresh repeats.
- Final deadlocks: **0**; continuous invariant violations: **0**.
- Population min/median/max: **10/12/12** across positive eight-day worlds.
- Full founding construction success: **79/79**; physical elevated access: **79/79**.

## Long soaks

| Run | Days | Max / final population | Shelter | Projects | Retained tasks / max | Created / failed | Journal retained / sequence | Final urgent |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| SOAK-01 | 90 | 75 / 75 | 75 | 10 | 500 / 500 | 594018 / 0 | 128 / 147 | 2 |
| SOAK-02 | 60 | 55 / 55 | 55 | 8 | 500 / 500 | 273187 / 0 | 119 / 119 | 0 |
| SOAK-03 | 60 | 10 / 10 | 15 | 4 | 500 / 500 | 9337 / 0 | 50 / 50 | 10 |

Each soak runs its full target duration, including finite-resource terminal behavior. Exhaustion can produce a stable crisis; current production has no mortality system, so bounded needs at 1 and paused growth are not evidence of healthy survival. The task ledger, sources and journal remain observable. Per-day normalized creation/event rates and complete timelines are in the machine-readable summary.

## Timings

| Milestone | Min | Median | Mean | P90 | Max |
|---|---:|---:|---:|---:|---:|
| meaningful_work | 5.5 | 12.7 | 15.3 | 23.0 | 34.0 |
| first_salvage | 20.8 | 30.8 | 32.8 | 41.3 | 45.6 |
| material_haul | 28.2 | 39.4 | 40.8 | 51.3 | 55.7 |
| shelter_complete | 109.5 | 141.4 | 141.7 | 165.4 | 187.1 |
| depot_complete | 165.2 | 200.9 | 206.5 | 236.7 | 258.6 |
| workshop_complete | 295.3 | 339.2 | 348.9 | 401.2 | 414.1 |
| housing_complete | 404.8 | 451.5 | 458.9 | 504.1 | 535.2 |
| sixth_citizen | 705.0 | 755.0 | 762.7 | 805.0 | 860.0 |
| traversal_complete | 627.3 | 1200.8 | 1295.1 | 1646.7 | 1715.6 |
| elevated_territory | 744.2 | 1238.9 | 1343.0 | 1691.3 | 1759.3 |

## Findings and fixes

Seven High production bugs were reproduced and fixed: shelter rest positions blocking the future depot, off-grid connectors cutting new structure corners, synchronous retry recursion on unavailable navigation, fractional uncollectable bootstrap remnants suppressing traversal, derived founder patrol targets inside furniture, coarse-grid connectors stranding a legal narrow-aisle position, and building completion replanning active climbers through open space. The earlier sustained regression now measures active/reserved task age from simulation claim/start timestamps instead of available queue creation time; its 600-second limit is unchanged. No free-resource creation, nonphysical population or premature capability was observed. The pre-fix midlink case did leave legitimate geometry; the final rerun continuously forbids it. Root causes, pre-fix artifacts and focused commands are in [root-causes.md](root-causes.md). The first full investigation was intentionally stopped after 48 completed candidates when the corner defect was reproduced; its failures are preserved and are not the final campaign.

The production changes are limited to `settlement_development_system.gd`, `floor_navigation.gd`, `citizen_agent.gd`, `civilization_simulation.gd` `task_coordinator.gd` and `surface_navigation.gd`. No costs, timings, movement speed, canonical resources, population rules or technology gates were tuned. See `git diff --stat 26dfe0812fcf592e047412078cec2552e2e62b36 HEAD` for all changed files, and `git log --oneline 26dfe0812fcf592e047412078cec2552e2e62b36..HEAD` for implementation/evidence commits.

## Regressions and provenance

Canonical baseline passed before edits. Final POC47 Fast and three canonical repeats, POC46 Fast/scenario, POC45 Fast/survival/scenario, POC4 Fast/contract/cleanup and sustained seven-day scenario, generic RoomDefinition checks, and all three new focused regressions pass. Earlier attempted regression failures are retained and explained in root causes. Final evidence consistency errors: [].

Exact final campaign commands:

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Full -Count 60 -OutputDirectory verification/poc471/final -Workers 2
./TEST_ROOM_SCALE_POC471.ps1 -Mode Explore -OutputDirectory verification/poc471/exploration -Workers 1
python scripts/poc471_evidence.py
```

All case configs/results contain exact replay commands. Unexpected failures would retain `failure-package.json`. There are no unresolved final admitted-case failures. Bulk execution is headless; no rendered failure screenshot is claimed.

## Architectural assessment

**3. moderately robust.** The evidence supports varied origins, spawns, resource distances, material supplies, detours, target approaches and identifier changes inside the supported room topology. It does not prove arbitrary layouts or room reconstruction. The fixed depot apron, local build search lattice, compatibility activity/rest anchors, finite source assumptions, one elevated target and deterministic ordering remain boundaries. Legacy established-room targets inside initial structure footprints retain their old contract. Some candidate layouts are conservatively rejected rather than admitted as solvable.

Multi-civilization is blocked primarily by shared-world resource/salvage authority, construction reservations and navigation invalidation, in addition to ID and scene namespaces. Local economy, governor and completed-project capabilities are useful instance-level foundations, but duplicating their current services would duplicate finite physical resources. See [multiciv-readiness.md](multiciv-readiness.md). No second civilization or speculative gameplay was implemented.

See [scenario-matrix.md](scenario-matrix.md), [campaign-summary.json](campaign-summary.json), [outliers.md](outliers.md) and [findings.md](findings.md) for per-case evidence and limitations.

## Reviewed execution and performance details

The primary aggregate covers 95 inputs, 92 continuously stepped worlds and 922 simulation days (5,532,000 fixed ticks). Three extra exact performance replays also pass with identical fingerprints; they do not inflate the 79/79 positive denominator. Core positives contain 59 distinct complete inputs after removing room IDs, across all six origin regions.

Representative eight-day observer wall seconds (three host-paused originals replaced by matching fresh replays): `{'min': 20.346, 'median': 28.258, 'mean': 27.9913417721519, 'p90': 31.311, 'max': 33.789}`. Raw durations, exclusion details and Windows events are preserved in [performance-notes.md](performance-notes.md). These are concurrent observer runs, not isolated engine benchmarks.

The healthy 90-day soak ends at 75 citizens / 75 shelter / 10 projects; the healthy 60-day soak at 55 / 55 / 8. Both plateau because another housing module lacks finite safe materials. The finite-reserve 60-day soak ends at 10 / 15 / 4 with food/water exhausted and all 10 citizens urgent. That is stable accounting under crisis, not healthy survival. Full quantities and late task/event rates are in [long-soak-review.md](long-soak-review.md) and the machine summary.

AC15 cannot literally hold at the required initial 5 citizens / 0 shelter. Earned-shelter limits apply to every added citizen; the required initial founders remain the explicit exception. See [acceptance-matrix.md](acceptance-matrix.md) for all 40 criteria and qualifications.

Seven production defects were documented, including one regression introduced by the first connector safety repair. Historical physical violations include building-corner entry, patrol entry into furniture and midlink replanning through open space. Historical depot and fractional-source failures block progression; the final campaign has 0 reported strategic deadlocks and 0 continuous invariant violations. The classifier is heuristic; final milestones and reviewed supply states provide additional gates.

Implementation commits:

```text
b11fe41 Preserve active grapple geometry when construction replans citizens
801a497 Handle fractional bootstrap remnants and physically route narrow floor aisles
ba31f94 Harden physical grid connectors and bound unreachable task retries
58744d5 Reserve bootstrap depot apron when selecting founder shelter
88e4291 Add production founding robustness harness and initial campaign evidence
```

Changed code, scripts and documentation (all detailed verification artifacts live under `verification/poc471/`):

```text
.gitignore
PROJECT_PROGRESS.md
README.md
TEST_ROOM_SCALE_POC471.ps1
docs/POC471_ROBUSTNESS.md
scripts/citizen_agent.gd
scripts/civilization_simulation.gd
scripts/floor_navigation.gd
scripts/poc471_campaign.py
scripts/poc471_evidence.py
scripts/poc471_midlink_test.gd
scripts/poc471_navigation_test.gd
scripts/poc471_observer.gd
scripts/poc471_unreachable_task_test.gd
scripts/poc4_scenario_test.gd
scripts/settlement_development_system.gd
scripts/surface_navigation.gd
scripts/task_coordinator.gd
```

The final evidence-only commit follows these implementation commits. No production/harness source is edited after the final runs. See [archive-index.md](archive-index.md) for earlier attempts and replay semantics, [outlier-investigation-notes.md](outlier-investigation-notes.md) for controlled timing analysis, and [multiciv-readiness.md](multiciv-readiness.md) for the ownership audit.
