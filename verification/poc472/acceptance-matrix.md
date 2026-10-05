# POC 4.7.2 acceptance evidence

Final counts, durations and source checks are verified by `gather_evidence.py` into `audit.json`. Development prefixes and input-generator failures are separate from the final campaign.

| Requirement | Production behavior | Evidence |
|---|---|---|
| Five founders, no starting settlement | Existing founder startup, no capability grants or initial structures | POC47 fast and every campaign initial snapshot |
| General geometry-based sites | Floor-grid cells and actual boundary/obstacle edges; four work sides | Planner decisions in every final result |
| Future-aware first shelter | Simultaneous shelter/depot/workshop/housing certificate | Three future reservations plus seven future rest points at first shelter acceptance |
| No fixed depot apron | Depot placement comes from the same spatial search | POS-023, POS-029 and unchanged former NEG-03 complete physically |
| Strategically bad locally legal sites rejected | Bounded downstream search and necessary apron-area bound | PLACE-031 chooses rank 9; earlier legal sites cannot preserve the full chain |
| Infeasible placement handled honestly | No structure when protected connected aisles cannot contain an apron | NEG-PLACEMENT-01, zero site candidates and geometric tiling proof |
| Deterministic score and tie-break | Squared origin distance, ascending z, ascending x; same for work sides | Six full repeats, focused identical-state test, decision metadata |
| Bounded decision-time search | 96 branches/depth and 2,048 navigation trials; cached reservations | Decision trial counts, reused decisions and unchanged governor timing |
| No citizen in blocking geometry | Existing movement and obstacle checks | Every production tick in prior observer |
| No forbidden planned/completed overlap | Geometry/apron rejection and cloned future grids | New observer checks all accepted/project/reserved footprints at each relevant change |
| Future reservations disjoint | Complete layout requires non-overlapping aprons | New observer and focused planner test |
| Reachable work targets | Every proposed prefix/full layout retains exterior connected access | New observer checks work paths and physical segments |
| Physically valid construction deliveries | Existing real ticket pickup/haul/delivery | Every tick of construction delivery movement checked against blocking rectangles |
| Construction preserves settlement connectivity | Certificate at acceptance and current state checked before completion | New observer checks citizens, required anchors and future layout on each navigation change |
| Valid activity and rest targets | Derived patrol bounded to floor; stable rest cells selected with reservations | New observer checks earned targets and all reserved rest points |
| Earned capability gates | Existing shelter/storage/workshop completion gates | Parent observer, POC47 fast, shared regressions |
| Resource conservation | Existing finite ledgers, real extraction, real delivered tickets and once-only consumption | Continuous economy/resource audits; byte-identical retained inputs; new inputs preserve canonical stocks, source contents and existing salvage stages |
| No resource/world mutation from planning | Trials own separate navigation definitions and grids | Focused physical-state snapshots around preview and selection |
| No planning teleportation | Planning cannot assign citizen positions | Focused mutation test and per-tick movement limit |
| Verification does not alter play | Diagnostics are unconditional planner metadata | Fully observed POS-001 versus control without startup planner queries/invariant checks |
| All prior positive inputs retained | Both core and exploration retained folders loaded | 95 byte-identical definitions; all 79 formerly admitted positives in final audit |
| All prior negative inputs revisited | Four remain blocked/rejected; fixed-apron case now physically solvable | Five original negative records, with explicit NEG-03 classification correction |
| Long-soak durations | Full requested fixed-tick duration | SOAK-01 90 days, SOAK-02/03 60 days; actual seconds checked against configuration |
| Finite exhaustion accepted | No mortality/replenishment/new mechanics | SOAK-03 exhausts usable food/water and remains in a legitimate bounded crisis |
| Shared regressions | Legacy established room contract retained | POC47, POC46, POC45, POC4 and generic definition suite |
| Production frozen before final evidence | Production commit 2c0f74e; final input-loader freeze 9a7df23 | All 65 GDScript hashes checked against final checkout; all final campaign receipts use 9a7df23 |
| No main merge | Dedicated requested branch | Git branch/commit receipt in final delivery |

The seven prior fixes retain focused corner/narrow-aisle, unreachable-retry and mid-grapple tests; fractional water and patrol cases remain in the continuous campaign. Initial five founders having zero shelter is the intended startup, not a growth exception: every added citizen requires earned shelter and normal reserve/stability/cooldown gates.
