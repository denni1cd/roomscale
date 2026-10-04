# POC 4.7.1 acceptance evidence

Final status is confirmed only after the aggregate evidence review succeeds.

| Criterion | Evidence / interpretation |
|---|---|
| AC01 — POC 4.7 baseline remains green | Baseline Fast/canonical at required SHA; final POC47 Fast + three canonical repeats. |
| AC02 — deterministic scenario generator exists | poc471_campaign.py deterministic transformations; repeated generation assertions; retained complete definitions. |
| AC03 — generated scenarios are validated before execution | Each config/result contains schema, runtime navigation, reachable quantities, safe salvage and site certificate. |
| AC04 — at least 30 valid founder variants execute | Final core positive count in campaign-summary.json; rejected inputs excluded. |
| AC05 — meaningful settlement-origin variation is tested | Six origin regions plus Explore six local origin probes; matrix input table. |
| AC06 — meaningful resource-placement variation is tested | Floor food/water placements and finite supplies saved in complete definitions. |
| AC07 — meaningful obstacle/navigation variation is tested | Named crowded/constrained/mixed cases; six incremental routing probes; continuous physical obstacle checks. |
| AC08 — construction-material availability variation is tested | Finite salvage yield multipliers with original staged work; exact material gates and source reconciliation. |
| AC09 — resource-distance variation is tested | Per-case floor-resource/salvage path lengths; long-haul named cases. |
| AC10 — all valid scenarios continuously enforce economy conservation | Every fixed tick calls economy.audit and resources.audit; source-generation reconciliation. |
| AC11 — no valid scenario creates free construction resources | Source extraction + earned salvage equals generated; delivered equals received; project consumed exact once. |
| AC12 — all completed structures require real materials and labor | Exact delivered blueprint amounts, actual labor IDs/work and distance, visible FRAME/SHELL witness. |
| AC13 — settlement capabilities remain completion-gated | Completed project counts determine storage/workshop and shelter; effects require completion. |
| AC14 — founder growth remains one real citizen at a time | Entity count, unique IDs, cohort +1, real arrival positions and increased demand checked each tick. |
| AC15 — population never exceeds earned shelter | Growth cannot exceed earned shelter. Initial five unsheltered founders are the explicit canonical startup exception; see qualification below. |
| AC16 — workshop remains required for advanced traversal | Traversal project requires completed workshop continuously. |
| AC17 — elevated access always requires legitimate traversal | Every elevated citizen lies on deployed link or target region; material/labor/deployment gates witnessed. |
| AC18 — citizen movement remains physically bounded | Every tick position delta <= production speed *0.1s plus floating tolerance; no world-bound or footprint violation. |
| AC19 — no valid scenario creates duplicate or invalid citizens | Unique IDs, real scene entity count, valid owner IDs and legal arrival positions continuously. |
| AC20 — task-system growth is monitored and bounded | Live/retained task limits every tick; cumulative counts, rates, oldest creation ages and strategic witnesses. |
| AC21 — deadlock detection distinguishes legitimate scarcity from simulation failure | Strategic signature excludes routine/self-care; scarcity, emergency, completed state and feasible unfinished sequence distinguished; final milestone gate also catches masked stalls. |
| AC22 — at least five intentional impossible scenarios fail safely | Five impossible cases: four execute and stop safely; disconnected spawn is rejected before ticks. |
| AC23 — impossible scenarios never trigger cheating behavior | Same continuous resource/entity/capability/traversal checks apply to executed negatives. |
| AC24 — at least three 60-day founder soaks execute or reach documented stable finite-resource terminal states | Three full fresh 90/60/60-day soaks, with terminal supply/needs/growth and timeline review. |
| AC25 — long soaks show no accounting corruption | Continuous ledger/source audit, earned yields, bundles and exact project consumption in all soaks. |
| AC26 — long soaks show no runaway task/project creation | Per-day task/journal rates, bounded history and project/site/material limits; final long-soak review. |
| AC27 — deterministic replay is confirmed for selected seeds | Three selected seeds, two fresh repeats each; identical semantic fingerprints. |
| AC28 — every unexpected failure produces reproducible artifacts | Unexpected campaign failures retain config, complete definition, result, engine log and failure-package.json; moved bundles replay from sibling definition. |
| AC29 — genuine discovered bugs receive documented root causes | Seven documented production root causes plus one corrected earlier test assumption, with exact saved failures. |
| AC30 — production fixes are minimal and regression-tested | Six production files narrowly changed; focused regressions and complete shared suites rerun after last fix. |
| AC31 — the final campaign is rerun after the last production fix | All final/ and exploration/ source receipts use the final frozen source; consistency checker compares normalized source/harness hashes. |
| AC32 — existing POC 4.7 acceptance remains intact | regressions-complete/poc47 summary and logs: Fast + three canonical repeats. |
| AC33 — shared earlier POC regressions remain intact if shared production code changes | POC46 Fast/scenario; POC45 Fast/survival/scenario; POC4 Fast/contract/cleanup/sustained; RoomDefinition checks and all three focused units. |
| AC34 — campaign summary and scenario matrix are committed | Aggregate JSON and matrix committed with all retained per-case evidence. |
| AC35 — remaining weaknesses are documented honestly | findings.md, root-causes.md and multiciv-readiness.md describe fixed geometry, finite sources, legacy endpoints and ownership boundaries. |
| AC36 — meaningful performance/outlier statistics are produced | Per-case wall durations, milestone min/median/mean/P90/max, path lengths, population and task/event rates; concurrent-runtime caveat. |
| AC37 — unusually slow passing scenarios are investigated | outliers.md plus controlled water sweep and outlier-investigation-notes.md. |
| AC38 — multi-civilization readiness audit is completed without implementing multi-civ | 21 assumptions, code paths, difficulty and direct ownership/instance answers in multiciv-readiness.md; no second civ. |
| AC39 — no speculative gameplay feature is introduced | Production changes are geometry/failure/policy consistency fixes and simulation-time diagnostics only. |
| AC40 — final reported evidence represents the final committed code state | Final source/harness hashes verified against delivered checkout; report identifies tested source commit and delivery gives evidence-only HEAD. |

## AC15 qualification

The request requires five founders with zero initial shelter, so the literal phrase
“population never exceeds earned shelter” cannot hold at startup: 5 > 0. The
harness preserves that required initial condition and enforces earned shelter for
all population growth beyond the initial five, with every growth event checked
against available headroom. This is an explicit interpretation of the stated
growth intent, not a changed production rule or a hidden tolerance.

## Coverage limits

The strategic deadlock classifier is heuristic and distinguishes emergency supply
from feasible unfinished progression. It does not prove arbitrary policy fairness
or healthy post-exhaustion survival. Required milestones are still mandatory at
the final positive/soak gate, and all final stalls/timelines are reviewed. The
architectural audit is static; no multi-civilization experiment was performed.
