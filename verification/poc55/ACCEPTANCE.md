# POC 5.5 acceptance evidence

Evidence references are repository-relative and resolve against the branch. Focused final command: `./TEST_ROOM_SCALE_POC55.ps1 -Mode Focused -OutputDirectory verification/poc55/focused-reviewed` (PASS, all five component checks). See `docs/POC55_EXECUTION_CONTRACT.md` for the full wording and binding supplementary EC1–EC10 requirements.

| ID | Status | Executed evidence and source |
|---|---|---|
| AC01 | PASS | Rendered labels in `graphics/*.png`; `docs/SPECTATOR_DIRECTOR.md`; `scripts/fishbowl_hud.gd`. |
| AC02 | PASS | `focused-reviewed/poc55_ui_test.log`; `focused-reviewed/poc55_director_test.log`; four-mode control screenshots. |
| AC03 | PASS | UI test runs OFF through 600 real seconds while events continue; `focused-reviewed/poc55_ui_test.log`, `ui.json`. |
| AC04 | PASS | Mixed-priority ordering and cadence trace; `focused-reviewed/poc55_director_test.log`, `cadence.json`. |
| AC05 | PASS | Seeded quiet-colony trace includes routine work and activity classes; `focused-reviewed/poc55_director_test.log`. |
| AC06 | PASS | Live citizen movement plus project, site, and conflict Follow; `target-lifecycles.json`, `focused-reviewed/poc55_target_lifecycle_test.log`. |
| AC07 | PASS | Ended project/conflict/site exits to OFF with no replacement; `target-lifecycles.json`. |
| AC08 | PASS | Real keyboard and mouse input in all active modes; `ui.json` checks and `focused-reviewed/poc55_ui_test.log`. |
| AC09 | PASS | Manual OFF persists through 600 real seconds and events; `ui.json`. |
| AC10 | PASS | Programmatic framing keeps Director active; `ui.json`. |
| AC11 | PASS | Existing bounded journal, detached source snapshots and retention tests; `focused-reviewed/poc55_events_test.log`; `scripts/event_journal.gd`, `scripts/spectator_sources.gd`. |
| AC12 | PASS | Schema, monotonic IDs, focus validity, malformed record and snapshot isolation; `focused-reviewed/poc55_events_test.log`; `scripts/event_journal.gd`. |
| AC13 | PASS | Producer-policy audit and fixtures reject camera/editorial fields; `focused-reviewed/poc55_events_test.log`; producer sources listed in EC5/EC6. |
| AC14 | PASS | Generic catalog, narrative adapter, extension docs, and hardening assertions that event candidates carry catalog policy values; `hardening-focused/poc55_events_test.log`, `hardening-focused/poc55_director_test.log`; `scripts/spectator_event_catalog.gd`, `scripts/fishbowl_narrative_adapter.gd`. |
| AC15 | PASS | Unknown and malformed event consumers degrade safely; `focused-reviewed/poc55_events_test.log`. |
| AC16 | PASS | 300-event retention, bounded presenter queues, suppression/milestone fixtures, and separate story/subject/place cooldown eligibility checks against catalog policy; `focused-reviewed/poc55_events_test.log`, `hardening-focused/poc55_director_test.log`; `scripts/fishbowl_event_presenter.gd`. |
| AC17 | PASS | Four priority levels and rendered feed; `focused-reviewed/poc55_events_test.log`, `graphics/event-feed-priorities.png`. |
| AC18 | PASS | Critical mappings for combat and survival classes; `focused-reviewed/poc55_events_test.log`; `scripts/spectator_event_catalog.gd`. |
| AC19 | PASS | High mappings for deployment, conflict, completion and traversal; `focused-reviewed/poc55_events_test.log`. |
| AC20 | PASS | Medium mappings for equipment, muster, cohorts and starts; `focused-reviewed/poc55_events_test.log`. |
| AC21 | PASS | Routine event mappings remain feed-only; quiet-colony trace; `focused-reviewed/poc55_director_test.log`. |
| AC22 | PASS | Persistent bounded feed with multiple visible stories; `ui.json`, `graphics/event-feed-priorities.png`. |
| AC23 | PASS | Rendered priority, day/time, headline and narrative without debug dictionary; `graphics/event-feed-priorities.png`, `graphics/priority-major-event.png`. |
| AC24 | PASS | World event society-to-civilization resolution is asserted by the event suite; three-society feed reviewed in `graphics/combat-mobilization-framing.png` and `graphics/multi-civilization-feed.png`; the production trace is in `EVIDENCE_BUNDLE.zip` (`graphics-priority.json`). |
| AC25 | PASS | Viewport click on actual feed row; `ui.json`, `focused-reviewed/poc55_ui_test.log`. |
| AC26 | PASS | Click enters OFF and camera stays on player-selected focus; `ui.json`. |
| AC27 | PASS | Real physical convergence for citizen, project, site and conflict; `target-lifecycles.json`, `ui.json`. |
| AC28 | PASS | Removed live target resolves to valid stored historical focus; `ui.json`, `scripts/poc55_target_lifecycle_test.gd`. |
| AC29 | PASS | Invalid event has no fabricated focus; event remains readable; `ui.json`. |
| AC30 | PASS | Marker appears, follows, expires and has no gameplay collision authority; `ui.json`, `graphics/click-to-focus-highlight.png`. |
| AC31 | PASS | Eight-second normal dwell and five-second critical minimum; `focused-reviewed/poc55_director_test.log`, `cadence.json`. |
| AC32 | PASS | Priority and Random traces match at 1x/4x/10x; `cadence.json`, `ui.json`. |
| AC33 | PASS | Deterministic newest-unseen tie choice without RNG; `focused-reviewed/poc55_director_test.log`. |
| AC34 | PASS | Dedicated Director RNG and four-mode state digest match; `EVIDENCE_BUNDLE.zip` (`isolation-final/isolation-*.json`), `scripts/fishbowl_camera_director.gd`. |
| AC35 | PASS | Repeated fixed-seed Random sequence; `focused-reviewed/poc55_director_test.log`, `EVIDENCE_BUNDLE.zip` (`isolation-final/isolation-random.json`). |
| AC36 | PASS | Story/subject/location cooldown and repeated-state checks use each candidate’s catalog durations; hardening tests show no legacy fixed 20-second gate; `hardening-focused/poc55_director_test.log`. |
| AC37 | PASS | Overview cadence and sustained-conflict exception; `focused-reviewed/poc55_director_test.log`, `docs/SPECTATOR_DIRECTOR.md`. |
| AC38 | PASS | StrategyCamera owns physical transforms; rendered framing and source audit; `graphics/*.png`, `scripts/strategy_camera.gd`. |
| AC39 | PASS | 21 live civilian milestones across accepted scenarios; `civilian-coverage.json`, `scripts/event_fact_context.gd`. |
| AC40 | PASS | Three-party live production covers 38 spectator fact kinds and conditional elimination; `ABILITY_STATE` remains in Armory internals and is excluded from the spectator journal, feed, and event candidates; `hardening-focused/producers.json`, `hardening-focused/poc55_events_test.log`, `live/producer-evidence.json`, `live/producer-conflict.json`. |
| AC41 | PASS | 6,200-tick attack-order digest remains `c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2` while journal milestone kinds exclude mechanical ability telemetry; `hardening-focused/producers.json`, `scripts/poc55_producer_test.gd`. |
| AC42 | PASS | Priority/Random live military framing, Follow conflict target and rendered frame; `EVIDENCE_BUNDLE.zip` (`isolation-final/isolation-*.json`), `target-lifecycles.json`, `graphics/combat-mobilization-framing.png`. |
| AC43 | PASS | Clockwork/Verdant/Scavenger identities in three-party producer trace, world-event identity assertions and final feed capture; `live/producer-evidence.json`, `focused-reviewed/poc55_events_test.log`, `graphics/combat-mobilization-framing.png`. |
| AC44 | PASS | Fresh production snapshots match across all modes at 1,000/3,000/6,200 ticks; `EVIDENCE_BUNDLE.zip` (`isolation-final/isolation-*.json`); snapshot scope documented in `docs/SPECTATOR_DIRECTOR.md`. |
| AC45 | PASS | Exact matching hashes across OFF/FOLLOW/PRIORITY/RANDOM at three checkpoints; `EVIDENCE_BUNDLE.zip` (`isolation-final/isolation-*.json`). |
| AC46 | PASS | POC 4.6 Fast/Scenario plus real inputs and selection path; `regression/accepted-wrapper.log`, `ui.json`. |
| AC47 | PASS | Real F3 diagnostics toggle and rendered normal narrative; `ui.json`, `graphics/event-feed-priorities.png`. |
| AC48 | PASS | Seven final renderer captures, visually reviewed after society-label and role-label repairs; `graphics/*.png`, `ui.json`, and fresh Priority/Random traces in `EVIDENCE_BUNDLE.zip`. |
| AC49 | PASS | Canonical three-run repeatability passes in `regression/canonical-final/canonical/`; the full accepted Regression wrapper completed with exit 0, with its child receipts in `EVIDENCE_BUNDLE.zip` (`regression/final-accepted/regression/`). This includes POC 4/4.5/4.6, Room A/B smoke, POC 4.7.2 focused placement and 20/20 positive exploration scenarios. |
| AC50 | PASS | User and developer docs, implementation report and this evidence matrix; `docs/SPECTATOR_DIRECTOR.md`, `docs/POC55_EXECUTION_CONTRACT.md`. |

## Exact POC 5.5 commands

```powershell
./TEST_ROOM_SCALE_POC55.ps1 -Mode Focused -OutputDirectory verification/poc55/focused-reviewed
./TEST_ROOM_SCALE_POC55.ps1 -Mode Isolation -OutputDirectory verification/poc55/isolation
./TEST_ROOM_SCALE_POC55.ps1 -Mode Graphics -OutputDirectory verification/poc55
./TEST_ROOM_SCALE.ps1 -Mode Canonical -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/regression/canonical-final
./TEST_ROOM_SCALE.ps1 -Mode Regression -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/regression/final-accepted
./TEST_ROOM_SCALE_POC46.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC46.ps1 -Mode Scenario
git diff --check
```

The final focused and isolation receipts are retained with the branch. Existing regression commands and results are enumerated in `regression/REGRESSION_RESULTS.md`.

## Supplementary execution criteria

| ID | Status | Evidence |
|---|---|---|
| EC1 | PASS | User-approved contract v1.0 and “go ahead” authorization are preserved in the contract appendix; `FINAL_REVIEW.md` records verified branch publication and no-merge state. |
| EC2 | PASS | `focused-reviewed/poc55_target_lifecycle_test.log`, `ui.json`, and `docs/SPECTATOR_DIRECTOR.md` cover physical camera ownership, valid identity, live resolution, and manual input. |
| EC3 | PASS | Event and producer suites verify journal schema and society-local context; `ABILITY_STATE` remains in Armory evidence without being published to the journal/feed/candidate source; `hardening-focused/poc55_events_test.log`, `hardening-focused/producers.json`, `EVIDENCE_BUNDLE.zip`. |
| EC4 | PASS | Director tests verify story/subject/location eligibility uses catalog durations; fresh isolation receipt verifies mode equality at ticks 1000/3000/6200; `hardening-focused/poc55_director_test.log`, `hardening-isolation/isolation-summary.json`, `cadence.json`. |
| EC5 | PASS | `civilian-coverage.json` has 21 live accepted-scenario milestone records and source receipts. |
| EC6 | PASS | Live 6,200-tick production validates two KIT_LOST records against their dead citizens’ casualty positions and confirms event navigation, economy, Armory, and combat state; `hardening-focused/producers.json`, `hardening-focused/poc55_producer_test.log`, `live/producer-evidence.json`, `live/producer-conflict.json`. |
| EC7 | PASS | `regression/REGRESSION_RESULTS.md`, canonical summary files, and `EVIDENCE_BUNDLE.zip` retain accepted gameplay and determinism results. |
| EC8 | PASS | Renderer evidence includes a readable KIT LOST card and post-click camera frame at the off-depot casualty location; `graphics/kit-lost-event-focus.png`, `ui.json`, `hardening-focused/poc55_ui_test.log`. |
| EC9 | PASS | Milestone-to-commit table in `docs/POC55_IMPLEMENTATION_REPORT.md`, feature branch history, and exact evidence paths. |
| EC10 | PASS | `FINAL_REVIEW.md` records Rules Lawyer COMPLETE at hardening code SHA `474d1f0ea77961c8201f0cd948478f1166dc2435`; all AC01–AC50 and EC1–EC10 remain accepted and the 568-entry archive manifest/checksum were verified. |
