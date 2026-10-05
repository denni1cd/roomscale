# Long-soak review

Final-source results are reviewed for macro supply state, material capacity,
retained versus cumulative task counts, source accounting, journal behavior and
physical progression. Complete day snapshots remain in each result.

## SOAK02 — Mixed obstacles,60days

PASS;55 real citizens,55 earned shelter,8 completed projects. Final inventories
hold330 food,484 water,4 wood and5 metal. Finite sources still hold45520 food and
62416 elevated water. The site reason is“Finite safe materials cannot fund another
housing”. Population stops for shelter headroom because the next module lacks
materials; this is not food/water exhaustion or a navigation deadlock.

Retained tasks max500, live max55, tickets max19, bundles max6. Cumulative task
creation is273187 with0 failed. Projects stop at8. Journal retains119 events with
sequence119 and103 suppression keys, below the128/256 caps. All movement remains
within0.65000535in per0.1s tick, within the documented floating tolerance. The
maximum creation age of a live task is123.3s and all recorded strategic plateaus
are completed progression. No invariant violation or actual strategic deadlock.

| Day | Population | Projects | Tasks created cumulatively | Journal sequence |
|---:|---:|---:|---:|---:|
| 10 | 14 | 5 | 7730 | 56 |
| 20 | 24 | 6 | 29145 | 70 |
| 30 | 34 | 7 | 66098 | 88 |
| 40 | 44 | 8 | 119825 | 106 |
| 50 | 54 | 8 | 191287 | 117 |
| 60 | 55 | 8 | 273187 | 119 |

Cumulative work rises with population and elapsed time; normalized per-citizen-day
rates and final intervals are used to distinguish this from runaway retention.
The last day can be absent from regular day snapshots by less than a microsecond
of fixed-step accumulation, so the separately recorded final state supplies the
last interval. Simulation duration remains60days within0.001s tolerance.

## SOAK03 — Late finite reserves,60days

PASS under stable exhausted-supply semantics, not healthy survival. Population10,
shelter15,4 completed projects; available and source food/water are all0. Food
consumed200 equals initial20 plus extracted/delivered180; water consumed360
equals initial30 plus extracted/delivered330. Construction/material accounts remain
conserved. Governor stays SURVIVAL, all10citizens urgent, growth reason“Survival
reserves unsafe”, food/water needs1. Current production has no mortality model.

Tasks created9337, completed9312, cancelled14, failed0; retained500. Live max10,
tickets max14, bundles max3. Journal retains50 events, sequence50, suppression38.
No new project inflation or accounting violation. Strategic stalls are49 emergency
supply diagnoses and3 finite-carrying-capacity diagnoses; all mandatory founding
and physical elevated milestones occurred before exhaustion.

## SOAK01 — Long salvage haul, 90 days

PASS; 75 real citizens, 75 earned shelter, 10 completed projects. Final inventories
hold 450 food and 644 water with small reserved consumption tickets; sources retain
20,864 food and 46,512 elevated water. Forecasts are 3.0 food days and 2.8622 water
days. One wood and one metal remain, and the next housing module cannot be funded.
The healthy plateau is finite building-material scarcity, with no additional projects.

Tasks created 594,018, completed 593,927, cancelled 4, failed 0; retained 500, live
max 75, tickets max 20, bundles max 7. Journal reaches its 128-event retention cap
with cumulative sequence 147 and 131 suppression keys, below the 256-key limit.
Maximum live task creation age is 193.7s. Fifteen macro plateaus are recorded as
completed progression; all mandatory physical milestones and continuous invariants
pass. The 90-day observer takes 892.817 wall seconds after the host resumes.

## Late rate review

Over the final ten intervals, normalized task creation averages about 152.0 tasks
per citizen-day in SOAK01 and 149.4 in SOAK02. SOAK03 averages 1.74 under depleted
supplies. Late journal rates approach zero or a few events per day. The machine
summary retains distributions and complete timelines. Cumulative creation is large
because real routine/care work continues; task, ticket, bundle and journal retention
remain bounded. No late runaway project creation, failed navigation or ledger drift
was observed.
