# POC 4.5 milestone evidence

Work is isolated on `codex/roomscale-poc45-fishbowl`, created directly from verified
POC 4 commit `88f787b0be4a32ad4ea7a273d4f91d95eeb800c9`. No merge into main.

| Milestone | Gate/evidence |
| --- | --- |
| M0 | `baseline/summary.json`: all seven jobs pass before production edits: fast, contract, cleanup, three fresh seven-day scenarios, thirty-day stability. `baseline/room-navigation.log` also passes. |
| M1 | Deterministic five-second governor, hysteresis/hold, bounded journal; targeted final fast tests. |
| M2 | `survival-attempt1.log`: zero-input recovery through the original room and traversal/salvage/haul chain. Final `release/survival.log` repeats it with integrated systems. |
| M3 | Real delivery/work and exactly-once housing/workshop tests in `final-fast/fast.log`; observer captures and project history. |
| M4 | Real five-node cohort, needs, demand, cooldown/cap and self-care checks; full cohort timelines. |
| M5 | Eight-day production scenarios reach 80 real citizens, four housing blocks and one workshop, with additional finite salvage. |
| M6 | Fishbowl launcher, readable HUD and inspectable macro feed; eight-second event/state camera with disable control; real captures. |
| M7 | Three consecutive fresh release runs; sixty-day headless and rendered stability; actual entity counts, conserved costs, finite sources, bounded histories and movement metrics. Final result in final report. |
| M8 | Gameplay/architecture guide, README/progress/contract updates, 55 individual criteria, reports and inspected captures; final commit/push recorded separately. |

## Failures retained and repaired

- First integrated attempt failed to compile because a dynamically accessed spawn
  value lacked an explicit Vector3 type. Fixed in PopulationSystem; no simulation
  behavior was weakened. Diagnostic log retained.
- First fast fixture reset inventory after reservations existed, invalidating its
  accounting baseline. Moved isolated fixture initialization before any reservation.
  Production EconomySystem and scenario stock were not altered to mask the failure.
- Navigation rebuild now explicitly clears prior solids; failed site evaluations
  still leave the live definition, obstacle rectangles and every grid cell unchanged.
- Population/material exhaustion is handled by state-based expansion restraint,
  not by giving the test free stock. The added canonical crates are visible ordinary
  finite room objects, with yields derived by the same production material rules.

Historical POC 4 evidence remains untouched. New baseline and regression artifacts
are retained separately in this directory.
