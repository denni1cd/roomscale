# POC55 regression execution evidence

Commands run from repository root with PowerShell 7. Godot 4.7.2 from existing `.tools` junction. Existing Python used for quality gates: `C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe` (default miniforge lacks Ruff).

| Exact command | Result | Receipt |
|---|---|---|
| `./TEST_ROOM_SCALE.ps1 -Mode Fast -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/regression/core-fast` | PASS | core-fast-wrapper.log |
| `./TEST_ROOM_SCALE_POC54.ps1 -RunCount 2 -OutputDirectory verification/poc55/regression/poc54` | PASS: ownership, catalog, armory, behavior, three-party innovation conflict fresh repeatability 2/2 | poc54-wrapper.log |
| `./TEST_ROOM_SCALE_INNOVATION.ps1 -OutputDirectory verification/poc55/regression/innovation` | PASS | innovation-wrapper.log |
| `./TEST_ROOM_SCALE_EXTENSIBILITY.ps1 -RunCount 2 -OutputDirectory verification/poc55/regression/extensibility` | PASS: innovation extensibility + mixed combat, 2/2 | extensibility-wrapper.log |
| `./TEST_ROOM_SCALE_CIVILIZATIONS.ps1 -OutputDirectory verification/poc55/regression/civilizations` | PASS: definitions and Verdant rendered visual | civilizations-wrapper.log |
| `./TEST_ROOM_SCALE_INNOVATION_LIVE.ps1 -RunCount 2 -CancellationProbe -OutputDirectory verification/poc55/regression/innovation-live` | PASS: Clockwork/Verdant/Scavenger 2/2 with cancellation | innovation-live-wrapper.log |
| `./TEST_ROOM_SCALE_CONFLICT_PRESSURE.ps1 -OutputDirectory verification/poc55/regression/pressure` | PASS | pressure-wrapper.log |
| `./TEST_ROOM_SCALE_COMBAT_ROLES.ps1 -RunCount 2 -OutputDirectory verification/poc55/regression/roles` | PASS: replay 2/2 | roles-wrapper.log |
| `./TEST_ROOM_SCALE.ps1 -Mode Canonical -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/regression/canonical-final` | PASS: 3/3 fresh eight-day receipts identical | canonical-final/canonical/summary.json and determinism-summary.json |
| `./TEST_ROOM_SCALE_POC47.ps1 -Mode All -OutputDirectory verification/poc55/regression/poc47` | Initial combined attempt failed its repeatability comparison while implementation files changed concurrently; superseded by the clean final three-run canonical gate above | poc47-wrapper.log, poc47/determinism-summary.json |
| `./TEST_ROOM_SCALE.ps1 -Mode Regression -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/regression/final-accepted` | PASS: exit 0; POC46, POC45, POC4, Room A/B smoke, POC472 focused and POC471 exploration (20/20) | Child logs, summaries and campaign evidence inside `verification/poc55/EVIDENCE_BUNDLE.zip` |
| `./TEST_ROOM_SCALE_POC55.ps1 -Mode Focused -OutputDirectory verification/poc55/focused-reviewed` | PASS: 5/5 focused checks | focused-reviewed/*.log |
| `./TEST_ROOM_SCALE_POC55.ps1 -Mode Graphics -OutputDirectory verification/poc55` | PASS: real renderer UI plus fresh Priority/Random captures | `ui.json`, `graphics/*.png`, detailed trace in `EVIDENCE_BUNDLE.zip` |
| `./TEST_ROOM_SCALE_POC55.ps1 -Mode Isolation -OutputDirectory verification/poc55/isolation-final` | PASS: OFF/FOLLOW/PRIORITY/RANDOM matching digests at 1,000/3,000/6,200 ticks | `isolation-final/isolation-summary.json`, detailed snapshots in `EVIDENCE_BUNDLE.zip` |

Additional focused `poc54_behavior_test.gd` after stand-down completion fact fix: PASS, behavior-return-fix.log.

Live producer `poc55_producer_test.gd`: PASS at tick 6200, all common milestones from untouched production three-party campaign. Conditional elimination then exercised using production damage/eliminate authority after campaign. Retained `verification/poc55/live/producer-evidence.json` and `producer-conflict.json`. Original live combat digest `c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2` identical in both independent campaign runs.
