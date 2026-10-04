# POC 4.7.2 final report

Branch: `codex/roomscale-poc472-settlement-planner`.
Baseline: `923e8e600e43a892a21b846e908c9036194e0747`.
Frozen tested production/harness commit: `9a7df235a80ea5df03fa37826cc727bc6da64afd`.
Production implementation commit: `2c0f74e24b01904d0e31563d1135dce4b0ce9024`; the later commit only corrected the retained-input loader. All 65 GDScript hashes are identical.
Final branch SHA is supplied in the delivery message; `git rev-parse HEAD` resolves the evidence commit. A committed report cannot contain its own commit hash.

## Outcome

General founder placement now chooses connected geometry-based sites, all four work sides and a complete shelter/depot/workshop/first-housing reservation before approving the first shelter. Permanent rest points are chosen with the future layout. Completion revalidates current occupants/access. Real citizens, extraction, hauling, construction stages, tickets, growth gates, traversal gates and fixed ticks remain production behavior. Costs, movement speed, finite quantities and consumption were not loosened.

## Counts and classification

- Main campaign: **127/127 expected outcomes**, including **112/112 declared positive cases**.
- Previously admitted positives: **79/79 PASS**. Former exclusions **POS-023 and POS-029 both PASS** on byte-identical definitions.
- New placements: **31/31 main cases**, plus **1/1 supplemental narrow pocket**, totaling **32 newly generated feasible layouts**.
- Across main and supplemental evidence: **114 feasible case runs PASS** (113 declared positives plus the physically feasible former negative NEG-03), **five genuine impossible inputs handled correctly**, six deterministic repeats and three soaks: **128 input/replay/soak results**.
- Genuine negatives are NEG-01, NEG-02, NEG-04, NEG-05 and NEG-PLACEMENT-01. NEG-05 is correctly rejected before stepping for disconnected spawn. Other impossible cases stop safely without bypassing prerequisites.
- Original NEG-03 blocks only the previous fixed depot apron. Its unchanged world now completes all normal milestones. Preserving its old expected storage failure would contradict the requested general planner; it is explicitly counted as feasible. The harness retains its legacy negative label and asserts successful physical founding.
- Generator exclusions among final positive inputs: **0**. Correct pre-tick physical input rejections: **1** (NEG-05). Prototype generator rejections are archived separately.
- Final strategic deadlocks: **0**. Continuous invariant violations: **0**.
- Main campaign: **1,194 simulation days / 7,164,000 production ticks** across 126 continuously stepped cases. Supplemental adds eight days / 48,000 ticks, for **1,202 days / 7,212,000 ticks**. Controls and shared regressions are additional and excluded from these counts.

## Determinism and observer independence

All six fresh repeats match their corresponding full final fingerprints. A POS-001 control without startup planner certificate queries or continuous invariant checks has exactly the same semantic fingerprint as the fully observed run. The focused unit additionally produces identical plans from identical initial state and checks that preview/selection do not move citizens, alter resources or mutate room/navigation geometry.

## Long soaks

| Case | Days | Population / shelter | Projects | Retained tasks | Failed tasks | Retained journal | Final state |
|---|---:|---:|---:|---:|---:|---:|---|
| SOAK-01 | 90 | 75 / 75 | 10 | 500 | 0 | 128 | STABLE |
| SOAK-02 | 60 | 55 / 55 | 8 | 500 | 0 | 119 | STABLE |
| SOAK-03 | 60 | 10 / 15 | 4 | 500 | 0 | 50 | SURVIVAL |

Both non-exhaustion soaks reach finite-material/shelter expansion plateaus with usable food/water remaining. SOAK-03 consumes exactly 200 food and 360 water, including initial portable stocks, and ends with all usable food/water sources and inventories at zero. Ten citizens remain in a stable critical-needs crisis and growth is paused. This is expected current gameplay with no mortality, not healthy survival or an architectural failure. No replenishment, renewable resource or emergency injection was added.

## Previously excluded and constrained inputs

| Input | Shelter | Depot | Workshop | Housing | Sixth citizen | Traversal | Elevated territory |
|---|---:|---:|---:|---:|---:|---:|---:|
| POS-023 | 91.4 | 141.8 | 282.4 | 355.2 | 660.0 | 1469.7 | 1535.1 |
| POS-029 | 97.9 | 153.5 | 264.4 | 334.3 | 635.0 | 1094.0 | 1126.5 |
| NEG-03 | 145.3 | 255.6 | 435.7 | 514.0 | 815.0 | 1471.3 | 1503.7 |
| PLACE-031 | 153.6 | 225.9 | 389.8 | 512.8 | 815.0 | 1460.6 | 1495.2 |

Times are actual production simulation seconds. Every retained POC471 definition is byte-identical. The compact PLACE-031 pocket provides a verified feasible arrangement while several nearer individually legal choices cannot fit the complete chain. It selects shelter rank 9 after rejecting downstream combinations. The separate 30-inch-wide pocket completes the chain, grows real citizens and reaches elevated territory at 1,777.0 seconds. The original unchanged packing prototype also passes a full eight-day replay on the frozen code; it is not counted as another new layout.

## Search and performance

The deterministic score is squared origin distance with ascending z/x ties, including work-side selection. Search uses actual floor cells and geometry edges, with 96 branches/depth and 2,048 navigation trials per development decision. Compact-domain apron coverage is a necessary rejection bound; acceptance always requires production navigation proof.

The main campaign records **498 accepted decisions**, **430 reusing cached founding layouts**. The maximum recorded search is **76 navigation trials**, well below the bound. There is no full spatial search every simulation tick. Soak wall times were 1,064.609 / 548.842 / 268.135 seconds under a three-worker campaign, with other test processes overlapping part of the run. These are observer-inclusive timings, not isolated engine benchmarks or a claimed apples-to-apples speedup over POC471.

## Defects and regressions

The fixed depot relationship, founder lattice and independent downstream/rest placement assumptions were replaced. Valid wall-adjacent origins exposed out-of-room derived patrol targets; preparation now bounds those targets. The new constrained test exposed phantom protected-furniture salvage targets; the planner now preserves only legitimate useful activity access. A compact packing bound and a completion-time connectivity guard address downstream waste and changing occupants. The initial baseline replay loader omitted the separately stored exploration folder; it was corrected before the authoritative rerun. Root causes, prototype failures and unchanged-input replays are documented in `root-causes.md` and `archive-index.md`.

POC47 fast plus three fresh canonical runs, POC46 fast/scenario, POC45 fast/survival/scenario, POC4 fast/contract/cleanup and seven-day sustained recovery, generic RoomDefinition validation, corner/narrow-aisle, bounded unreachable retry, mid-grapple continuity, planner immutability/determinism and constrained packing tests all pass. `regressions/commands.json` records 15 expanded commands. The fractional-remnant and derived-patrol campaign coverage also passes, preserving all seven prior fixes.

## Robustness assessment

**4 — robust within the demonstrated founder topology classes.** The increase from the POC471 rating of 3 is supported by removal of the fixed apron/lattice dependency, complete downstream reservations, two recovered feasible exclusions, unchanged prior positives, alternate wall/furniture origins, irregular obstacles, separated open areas, constrained multi-site combinations and a 30-inch building pocket, with continuous physical/accounting checks and full long soaks. It is not a general proof for arbitrary room topology.

Remaining assumptions:

- Rectangular floor, conservative rotated obstacle bounds, fixed axis-aligned 12x10 yards and four-inch access margins; one elevated target.
- Candidate discretization and bounded search can miss a feasible arrangement. A failed certificate at a bound is not a physical infeasibility proof. Arbitrary mazes below grid resolution are not demonstrated.
- Legacy established settlements retain their prior placement/activity contract; arrival selection still uses existing local navigation rules.
- Stored goods remain at the original pickup coordinate. Choosing a depot elsewhere does not model relocating stocked goods or moving the civilization to a different inventory anchor.
- Current room/navigation/resource ownership remains shared and scoped to one civilization.
- Only the mandatory first founding chain is reserved in advance. Subsequent housing requires its own feasible site and finite budget; material or spatial saturation can legitimately stop expansion.
- Finite resource exhaustion and a stable crisis remain possible. No later expansion mechanic is implemented.

## Reproduction and integrity

Exact final commands and earlier verification invocations are in `commands.md`; expanded shared commands are in `regressions/commands.json`; every case contains its portable replay command. The final engine is Godot `4.7.2.stable.official.ed1daf0bf`. Run the evidence-only audit with:

```powershell
python verification/poc472/gather_evidence.py
```

The successful audit verifies all 127 results, all requested durations, every retained definition byte-for-byte, source/harness hashes, all six repeat fingerprints, observer-control equality, required regression markers, finite terminal crisis and canonical resource/stage/stock preservation for new layouts. `audit.json`, `freeze-manifest.json`, `acceptance-matrix.md`, `final/scenario-matrix.md` and complete raw result/log bundles provide the underlying evidence. No main merge was performed.
