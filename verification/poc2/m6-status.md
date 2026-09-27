# Milestone 6 — Gameplay Integration

Status: **PASS — the canonical photo-based candidate completes the full production loop.**

## Final canonical run

The final candidate remained byte-for-byte unchanged from M4. It was run through the production scene and gameplay systems with the normal smoke harness, without room-specific gameplay source branches.

```powershell
.\TEST_ROOM_SCALE.ps1 -Room verification\poc2\candidates\primary\attempt-2\room_photo_luna.json -TimeoutSeconds 1200 -LogPath verification\poc2\canonical-primary-full-final.log
```

The wrapper stopwatch is appended to `verification/poc2/canonical-primary-full-final.log` as `ROOMSCALE_WRAPPER_WALL_SECONDS`. The final log is the evidence of record for M2–M6/M8 assertions, route budgets, sampled speed and distance intervals, and wall time.

The loop verifies the reconstructed desk target, two target investigators, barrier detection, 11 resource deliveries, completion of three build gates, live segmented cable, one physical surface traversal, three subsequent target arrivals, three explorations, and two autonomous route reuses by three distinct travelers. The final headless log reports M5 `max_step=1.34in` over `0.207s`, `max_sample_speed=6.50in/s` over `0.201s`, and M6 combined maximum `1.34in` over `0.207s`; the 6.5-inch/second cap and existing 0.25-inch per-sample tolerance remain in force. M5/M6 elapsed values are 12.60s and 171.00s, with an M6 dynamic budget of 366.69s. The wrapper wall time is 289.91s. Distances and elapsed intervals are reported together because screenshots and longer waits can span more than one nominal 0.2-second sample.

## General harness changes and retained failures

- `scripts/task_coordinator.gd` snapshots completed M6 task results just before bounded-history trimming. Task history remains capped at 500; the smoke test checks compact snapshots rather than dereferencing aged-out task IDs.
- M6 wait budget is derived from each observed route length and the exploration work time. It logs every added task budget and reports task/citizen/route diagnostics if the loop times out.
- M4's inventory assertion uses resource conservation at first observation and allows workers already to have picked up material; it still verifies all required resources, zero delivery before the gate, and the expected delivery stage.
- Citizen movement checks compare positions against each citizen's accumulated `_process(delta)` time. Wall-clock timing was unsuitable because the Godot run can advance simulation faster or slower than wall time. The 6.5-inch/second cap and 0.25-inch tolerance remain in force.

Earlier failures remain preserved as triage evidence: the 150-second M6 timeout (`canonical-primary-full-headless.log` and `canonical-primary-full-diagnostic.log`), task-history lookup failure after all task counters had advanced (`canonical-primary-full-budget-conservation.log.stdout.tmp`), strict initial-stockpile timing assertion (`canonical-primary-full-budget-1200.log`), and initial wall-time/sample assumptions in `canonical-primary-m5-visual-detail.log` and `canonical-primary-m5-visual-detail-v2.log`. Those failures exposed harness timing/history assumptions; no candidate geometry repair was needed after attempt 2.

## Cross-room regression

After the final smoke behavior changes, both existing room definitions were run as separate full production scenarios:

| Room | Command | Evidence |
| --- | --- | --- |
| Room A | `./TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 1200 -LogPath verification/poc2/final-room-a-full.log` | M2–M6/M8 all PASS. M5/M6 max observed step 1.34in; max sampled speed 6.50in/s. |
| Room B | `./TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 1200 -LogPath verification/poc2/final-room-b-full.log` | M2–M6/M8 all PASS. M5/M6 max observed step 1.34in; max sampled speed 6.50in/s. Wrapper wall time 256.38s is recorded in the log. |

The Room A/B logs were produced immediately before the final output-format correction that reports the sample duration for the maximum distance separately from the duration for the maximum speed. The movement assertion and its measured simulation-time bound were unchanged; the final canonical log uses the corrected metric labels. `verification/poc2/m6-snapshot-fast-final.log` passes after the final harness changes. The M5 final visual capture log predates this format-only correction; the visual files remain valid, while the headless final log is the source for paired movement metrics.
