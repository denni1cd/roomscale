# Robustness findings

Scope: one five-founder civilization per fresh production process, rectangular
supported room geometry, fixed 0.1-second simulation ticks. Final counts and gates
are in [final-report.md](final-report.md) and [campaign-summary.json](campaign-summary.json).
Earlier failing attempts remain in separate folders; they are not final pass evidence.

## Critical

No free materials, nonphysical population, premature capability, traversal bypass,
or accounting corruption was observed in the final admitted campaign. This is a
bounded empirical result, not a proof over all room definitions or concurrent civilizations.
Duplicating resource/salvage controllers for a future second civilization would
create independent ledgers for the same physical supplies; that is a critical design
risk, not an implemented or demonstrated two-civilization exploit.

## High — reproduced and repaired

| ID | Cause | Repair | Evidence |
|---|---|---|---|
| BUG-471-01 | Shelter rest slots occupy future fixed depot apron; founding stalls | Reserve future apron when selecting shelter and its activity/rest positions | Initial POS006, exact prefix reproduction, focused postfix |
| BUG-471-02 | Actual off-grid connector cuts completed shelter corner | Select a grid cell visible from the physical exterior endpoint | POS018/036, forward/reverse navigation regression |
| BUG-471-03 | Empty navigation recursively claims replacement work until stack overflow | Release failed work and retry through existing idle timer on a later tick | POC45 log, isolated unreachable-task regression |
| BUG-471-04 | A half-unit puddle is uncollectable but suppresses advanced water access forever | Floor bootstrap availability requires at least one unit, matching extraction eligibility | Fraction prefix/postfix and Full EDGE-FRACTION-01 |
| BUG-471-05 | A compatibility patrol target lies inside legal furniture | Resolve obstructed patrol anchors during empty founder configuration | Explore routing03/04/05, exact routing03 replay |
| BUG-471-06 | New safe connectors strand legal sub-grid aisle position; internal diagonals clip corners | Bounded visible corner connector fallback; require both adjacent cells clear for diagonals | POC4 sustained position/history, sampled forward/reverse aisle regression |
| BUG-471-07 | Housing completion replans active climbers as floor citizens, cutting through open space | Continue from physical point along earned deployed link, then rejoin floor route | Two failed 20-day soak prefixes and midlink fixture |

The sixth defect is a regression caused by the initial safety repair. It is counted
and documented rather than presented as a pre-existing flaw. All final founder and
shared regression evidence must follow the last production fix. See
[root-causes.md](root-causes.md) for classification, retained artifacts and commands.

## Medium — remaining architecture boundaries

- Depot position is derived from one origin with a fixed apron. Some candidate
  origins overlap existing furniture and are rejected before simulation. More
  origins do not constitute arbitrary settlement-site planning.
- Safe shelter selection searches a local lattice. Local candidate counts and
  navigation certificates show supported feasibility; they do not prove that all
  globally feasible layouts will be discovered.
- A 4-inch navigation grid cannot represent arbitrary thin passages. The bounded
  one-corner fallback handles the measured aisle; complex sub-grid mazes remain
  unsupported. Rotated furniture uses conservative axis-aligned footprints.
- Established fixture activity anchors inside initial module footprints retain
  a legacy endpoint contract. The founder observer forbids entering footprints,
  including after building completion. Legacy behavior remains technical debt.
- Resources are finite, forecasts are horizon based, and the simulation has no
  mortality. A long soak that reaches exhausted supplies with needs clamped at 1
  and paused growth is stable accounting under crisis, not healthy survival.
- The architecture has one elevated target/project, one global room start and local
  citizen/task/project namespaces. Shared world authority, site reservations,
  navigation revisions and traversal access need design work before multi-civ.
- A failed impossible route can still produce repeated retries, though stack depth
  and retained histories are bounded. The isolated regression measures this
  explicitly. Suppression/backoff policy beyond the existing idle timer was not
  added without a demonstrated valid-founder need.

## Low — diagnostics and test assumptions

ASSUMPTION-471-01: the earlier sustained regression counted time waiting available
as live task age. Claim/start simulation timestamps now measure actual reserved or
active work. The 600-second bound and zero-failed-task assertion remain unchanged.
Failure output now preserves the failed task history and observed citizen position.
Queue age remains a useful separate diagnostic in the founder observer.

Exact saved replay now locates its complete definition beside the config after
archival. Semantic fingerprints omit wall-clock timestamps and presentation state;
they include real milestones, citizens, tasks, project order, resources and ledger.

## Generalization judgment

**3. moderately robust.** The campaign deliberately varies supported inputs and
includes small increments around discovered weak points. It gives stronger evidence
than the canonical run, while fixed geometry conventions, finite throughput,
legacy anchors and world-ownership assumptions prevent a stronger claim. No
second civilization or speculative gameplay was added. The
[multi-civilization audit](multiciv-readiness.md) identifies the required boundaries.
