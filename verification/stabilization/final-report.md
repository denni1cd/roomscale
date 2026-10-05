# RoomScale stabilization final report

**Merged and pushed to main after all required local gates passed.** Normal merge
`167e80b13396bae6830460819158a22de443a074` was verified remotely; Fast and import
passed from that main revision. The primary checkout is on main and frozen source
remains unchanged. `main-merge.md` records delivery. Remote GitHub CI remains queued,
so its execution is unverified; no CI PASS is claimed.

- Selected baseline: completed POC 4.7.2, `efa5950e4a03a318bf030eb0217e6cb184714053`.
- POC 4.7.2 is included, with its complete accepted history and evidence.
- Stabilization branch: `codex/roomscale-stabilization`.
- Frozen production and test-harness SHA: `ef5ebd325351ae6c3702a7ab8d89266aafed59ea`.
- Existing mainline `305573651b52b4472250736431d091d821ca3c17` was reviewed and integrated before freeze.
- Final delivery SHA is the documentation/evidence commit containing this report; a
  committed report cannot embed its own SHA. Exact delivery/main SHAs accompany delivery.

## Review scope and findings

The full active repository review preceded broad cleanup. The initial review read all
60 active GDScripts, two Python programs, 16 PowerShell entry points, scenes, project
settings, authored rooms, visual catalogs, assets, reconstruction contracts, documents
and evidence policies. Completed 4.7.2 and existing-main deltas received supplemental
reviews before integration and fixes. Final active source has 68 GDScripts and six Python
programs. Historical source snapshots remain evidence rather than active programs.
Ruff is used for Python; GDScript received its own manual review and runtime verification.

**37 findings: 0 Critical, 2 High, 25 Medium, 10 Low.** Both High findings are fixed;
no unresolved Critical or High threatens current correctness. Of the 37 findings,
31 are fully fixed, two partially fixed with explicit remainder, and four deferred.
`code-review.md` preserves finding-level evidence and review chronology.

| IDs | Final disposition |
|---|---|
| H01, H02 | Fixed: stale PASS reuse; incomplete/sparse startup rosters. |
| M01, M02, M03, M13 | Fixed: argument quoting, bounded process lifecycle, UTF-8 logs, root-relative paths, child-only environment isolation. |
| M04, M05, M06, M11, M14, M15, M18 | Fixed: current runner, Python quality, fail-before-publish audit, checked evidence writes, current guides/artifact policy, complete canonical comparison. |
| M07, M08, M09, M17 | Fixed: disconnected elevated return, material case mismatch, unusable effective harvest stages, raw authored-ID lookup. |
| M19–M25 | Fixed: transient planner-cache identity, complete campaign/duration gates, bounded focused runs, active linted audit, argument/Python selection, shared evidence logic, fixture cleanup. |
| M10, M12 | Deferred: broader legacy observer inheritance and camera private API redesign. |
| M16 | Partially fixed: explicit stepping/replan/refresh contracts; raw task dictionary mutation remains debt. |
| L01, L02, L04, L05, L07, L09, L10 | Fixed: dead soak branch, import machinery, proven unused methods, dead camera branch, duplicate PNGs, trial accounting, art motif bounds. |
| L03, L06 | Deferred: trivial geometry/constants duplication and asset readiness delay. |
| L08 | Partially fixed: unused composition helpers removed; large scene composition remains debt. |

## Architecture and substantive cleanup

Simulation owns the 0.1-second clock and deterministic tick order. Citizens own physical
motion/work; Coordinator owns task lifecycle; Economy owns transactional inventory;
Resource/Salvage own finite stock and stages; Development owns actual projects and
benefits. SettlementSitePlanner chooses bounded connected reservations/rest targets
using cloned navigation. Population creates real legal entities after admission.
Presentation consumes production snapshots and events.

Public `advance_simulation`, `advance_elapsed_time`, `replan_current_route` and
`refresh_navigation` contracts replace external private/engine callback calls while
preserving the original bodies and tick order. Broader typed task/domain boundaries
are deliberately deferred. Startup validates a complete distinct connected roster
before construction, preserves accepted five/50-citizen positions and contiguous IDs,
and rejects impossible larger rosters atomically. Compact legacy photo spawn regions
retain their established seed contract; both actual photo inputs are covered now.

Object roots are keyed by raw authored IDs rather than fragile sanitized NodePaths.
Material derivation now matches case-insensitive validation; harvestable profiles
must have usable effective stages. Elevated return paths reject disconnected floor
exits. Planner failure-cache identity includes transient bundles, occupants, rest and
planning state: a controlled real bundle collection/delivery fixture verifies retry
without a geometry change. Trial accounting includes terminal validation clones,
with search and validation counts distinguished; site choice is unchanged.

The substantially refactored modules are `civilization_simulation.gd`,
`citizen_agent.gd`, `construction_system.gd`, `floor_navigation.gd`,
`development_system.gd`, `surface_navigation.gd`, `resource_system.gd`,
`room_definition.gd`, `pipeline_proof.gd`, `settlement_site_planner.gd`, active
campaign/audit Python and launch/test PowerShell. The shared bounded process helper
and checked evidence I/O replace consequential duplicate blocks. No general framework,
mass file moves, gameplay additions or economic rebalance were introduced.

Reference searches established no consumers before removing citizen travelled-distance,
surface investigation-route, construction traversal-arrival and unused pipeline
spawn-overlap/surface-selection/book-stack helpers. Existing mainline exterior
primitives remain; art motif centers/bounds and a leaking test fixture were corrected.

## Final verification

Pinned Godot 4.7.2 `ed1daf0bf`, Python 3.13.12 and Ruff 0.15.20 are used.
Ruff check and format pass for all active Python, including the evidence audit.
All 14 meaningful tooling tests pass under ordinary and optimized Python. Controlled
failure fixtures are expected test inputs, not hidden simulation failures.

| Gate | Result |
|---|---|
| Fast | PASS: quality, PowerShell process boundaries, schema, founder/core, checked evidence, navigation/retry/midlink, planner/packing. |
| Canonical | PASS: three fresh eight-day production runs; all 15 compared fields identical across repeats and baseline. |
| Full current 4.7.2 | PASS: all 127 expected outcomes, 112 declared positives, prior 79 positives, 31 new placement positives. |
| Supplemental / original packing prefix | PASS: narrow pocket and unchanged PLACE-031 prototype replay; 32 new placement positives including supplemental. |
| Former exclusions | POS-023 and POS-029 PASS. NEG-03 is physically feasible and completes eight days; it is not counted as a genuine negative. |
| Genuine negatives | Five expected outcomes; NEG-05 correctly rejects disconnected spawn before simulation. No generator exclusions or unexpected outcomes. |
| Determinism / observer control | Six fresh matching repeat fingerprints; observer control identical. |
| Soaks | Full 90/60/60 days PASS, wall times 1259.313/766.300/431.397 seconds under concurrent campaign/regression load. |
| Shared historical/current regressions | All 15 commands PASS, covering meaningful POC4/4.5/4.6/4.7 and focused navigation/planner/packing checks. |
| Legacy rooms | Room A, Room B, primary photo and secondary photo: structural/navigation validation and full M2–M6/M8 smoke PASS with 50 real citizens each. |
| Renderer | PASS and clean log; actual 1920×1080 PNG and camera-state JSON inspected. |
| Strict evidence audit | PASS: all receipts/durations/logs, 95 preserved definitions, repeats, control, packing, planner constraints and frozen source/harness hashes. |
| Integrity / hygiene | All 188 active-file hashes unchanged; added-source key/credential/user-path scan clean; whitespace check clean. |

All 127 campaign fingerprints match accepted 4.7.2; NEG-05 has matching expected
pre-tick rejection and no simulation fingerprint. Zero invariant violations or deadlocks
occurred. The main campaign covers 1,194 simulated days / 7,164,000 fixed ticks;
including the supplemental case, 1,202 days / 7,212,000 ticks. Separate controls,
canonical repeats, prefix replay and legacy tests add coverage without inflating those totals.

The exhausted 60-day world ends with zero food and water in both sources and inventory,
an active emergency, population 10 and no deadlock. The other soaks end at populations
75 and 55. All retain at most 500 task-history records; journals remain bounded.
Finite exhaustion remains valid gameplay. No free resources, teleportation, manually
completed projects or unearned capability progression were added to integration paths.

The top-level Fast/Canonical/Regression/Robustness/Soak/All modes delegate existing
specialized gates; legacy omitted-Mode room calls preserve Smoke. Robustness covers
37 current development worlds. Full 4.7.2 covers the whole 127-input corpus. Historical
4.7.1 Short/Full are not current gates because their NEG-03 expectation is obsolete;
all meaningful retained positive exploration inputs remain in current coverage.
`commands.md` documents reproducible commands and exact-source receipt rules.

## Performance and deterministic behavior

Fresh sequential isolated canonical timings: baseline 12.56/12.11/12.10 seconds,
final 12.13/12.01/12.00 seconds; mean change −1.71%. All 15 production fields and
checkpoints match baseline, fingerprint
`9e5d72c7ad85163815358ea3906dda5e39563ded78c4e0d20c6f30da02180183`.
Representative POS-001: baseline 20.159, final 20.444 seconds (+1.41%), with identical
semantic fingerprint `ec52a9fbb90c4b5550c6b6d5faff3522abc90c660197c45a65f8170582770876`.

These are small-sample same-host observer-inclusive measurements with no competing
Godot processes, not a statistical speedup claim. No material unexplained performance
regression was measured. Campaign and soak wall times overlap other verification and
are not isolated benchmarks. Narrow bug fixes have focused fixtures; accepted
canonical/current-campaign production outcomes remain deterministic.

## Repository and documentation hygiene

Only 20 SHA-256-identical PNG copies were removed: 11,324,795 bytes (10.80 MiB).
`artifact-manifest.json` identifies every retained replacement; their hashes were
rechecked. No unique image, definition, seed/config, independent receipt or historical
report was removed, and Git history remains intact. The selected milestone contained
4,403 tracked verification files / 432,169,032 bytes; unique mainline evidence remains.

Raw future campaigns, caches, environments and local runtime output are ignored.
Compact reviewed reports/manifests and authored fixtures remain addable.
`verification/.gdignore` prevents import scanning while allowing fixture FileAccess.
README, architecture, testing and artifact-policy documentation describe completed
4.7.2; obsolete plans/status files are explicitly historical.

Windows CI performs Python quality, import and Fast only. Expensive campaigns/soaks
and subjective visuals stay explicit local gates. Remote CI status is recorded after
push; local PASS is not presented as remote CI PASS.

## Failed and superseded attempts

The initial 4.7.1 candidate was stopped after 46 receipts when strict process handling
misclassified two legitimate pre-tick exclusions. Real retained fixtures and adversarial
tests corrected that protocol. An early validation call used unsupported OutputPath;
all four final validations reran with the actual LogPath interface.

The def2515 freeze was invalidated after full photo smoke exposed the compact-seed
fallback regression. Corrected roster fixtures and all full room smoke tests now pass.
The replacement 0c26873 campaign had 127 passing engine cases, but aggregate acceptance
failed because NEG-03 ended at 4799.99999999993 seconds against an exact 4800 boundary.
The harness now uses the existing 0.001-second tolerance, less than one 0.1-second tick;
a focused test accepts roundoff and rejects a missing tick. That harness change also
invalidated its freeze. The complete campaign and every required gate were rerun on
final ef5ebd3; no old receipts were restamped or accepted for the changed revision.

Automatic approval review rejected an early candidate push because gates were incomplete
and the destination was unverified. No push ran. The configured public repository was
then verified as `https://github.com/denni1cd/roomscale`; delivery follows completed gates.

## Deferred debt and delivery gates

Remaining debt: broader scenario-observer inheritance, camera private APIs, raw task
mutation boundaries, large scene composition, trivial geometry/constants duplication
and asset readiness delay. These are explicit scoped follow-ups, not unresolved
Critical/High correctness blockers.

AC01–AC32 pass locally with the evidence linked above and in `main-merge.md`. The
clean documentation/evidence commit preceded the conditional normal merge; remote
main was verified and its Fast smoke passed. Only documentation/evidence commits
follow frozen ef5ebd3; all 188 manifest hashes are verified at main delivery. Remote
CI is explicitly pending hosted-runner execution, rather than an asserted pass.

No release tag or historical branch deletion is performed. Recommend the user-selected
future tag `roomscale-founder-stable` (or `v0.1.0` if adopting versioned releases).
