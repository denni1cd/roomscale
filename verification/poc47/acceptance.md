# POC47 acceptance matrix

All 35 criteria pass for the canonical founder scenario. Paths below are relative
to this directory. Fast checks are in `final/`; full production evidence is in
`final/repeat-01.json` through `repeat-03.json`. Visuals are in
`final-render/scenario-visuals/`. See [final report](final-report.md) for limits.

| Criterion | Result and evidence |
| --- | --- |
| AC-01 Five founders | PASS — fast startup assertions and all fresh runs start with five real agents. |
| AC-02 No prebuilt settlement | PASS — startup checks zero structures/capabilities; empty-settlement PNG. |
| AC-03 Portable supplies only | PASS — five portable packs; 20 food/30 water, zero construction materials. |
| AC-04 1x default | PASS — actual launcher log and final-live-1x/result.json speed 1.0. |
| AC-05 Fast forward | PASS — fast checks Pause/1x/4x/10x controls. |
| AC-06 Real needs | PASS — normal CitizenAgent need state at startup and every scenario tick. |
| AC-07 Acquisition | PASS — source-backed salvage ledger and first-salvage capture. |
| AC-08 No free materials | PASS — every-tick material/source/bundle conservation and exact project consumption. |
| AC-09 Hauling | PASS — actual task movement, delivery distance and carried parcels. |
| AC-10 Shelter | PASS — completed production project at 156.3 seconds, rendered stages and live capture. |
| AC-11 Earned shelter | PASS — every-tick shelter equals completed building effects. |
| AC-12 Depot | PASS — actual supplied/worked project completes at 223.8 seconds. |
| AC-13 Workshop | PASS — actual supplied/worked project completes at 374.5 seconds. |
| AC-14 Workshop capability | PASS — fast premature-action rejection and completion-gated scenario checks. |
| AC-15 Stages | PASS — foundation/frame/shell/complete production captures for all four building types. |
| AC-16 Labor | PASS — recorded work_by_citizen, task movement and required worker seconds. |
| AC-17 Physical history | PASS — persistent building nodes, registered navigation obstacles and final settlement image. |
| AC-18 Supported growth | PASS — infrastructure, shelter, stability and reserve eligibility checks before every arrival. |
| AC-19 Small increment | PASS — every founder cohort has exactly one member. |
| AC-20 Real citizen | PASS — agent node count and population agree after every arrival. |
| AC-21 Demand scales | PASS — arrival forecasts before/after creation reflect increased demand; shelter headroom decreases. |
| AC-22 Growth pauses | PASS — negative fast cases for food/water reserve, emergency, blocked placement and shelter. |
| AC-23 Autonomous | PASS — three scenarios advance production without player strategic commands. |
| AC-24 High-level governor | PASS — source review: governor requests development/strategic work through existing systems; coordinator assigns agents. |
| AC-25 Traversal | PASS — supplied, worked grapple project deployed at 1447.5 seconds. |
| AC-26 Traversal gate | PASS — command and direct project rejection before workshop; every-tick capability checks. |
| AC-27 Physical traversal | PASS — movement limits and real climbing observations/capture. |
| AC-28 Elevated territory | PASS — actual elevated source collection at 1482.5 seconds and corresponding event. |
| AC-29 Watchability | PASS — 185.4 simulation seconds in 185.611 wall seconds; live shelter construction, plus later production-tick timing. |
| AC-30 POC46 presentation | PASS — final POC46 fast regression, full legacy scenario and rendered founder review. |
| AC-31 Narrative | PASS — founding events, singular arrival card and milestone captures. |
| AC-32 Legacy room | PASS — legacy POC46 full scenario reaches 80 agents; POC45 and POC4 regressions pass. |
| AC-33 Data-driven | PASS — room start schema, derived anchors, configurable population/cohort/speed; malformed inputs rejected. |
| AC-34 Repeatability | PASS — three consecutive fresh eight-day runs; identical production fingerprints in repeatability-summary.json. |
| AC-35 Anti-fake | PASS — production ledger/work/movement assertions and observer harness review; no injected stock, workers or milestones. |
