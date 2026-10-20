# RoomScale POC 5.5 hardening report

## Result

The bounded Spectator Director repair is implemented on `codex/spectator-director`. It fixes factual navigation for lost equipment, keeps mechanical ability telemetry in Armory evidence while excluding it from spectator stories, and makes Director eligibility consume cooldown durations from the event catalog. No gameplay authority or simulation outcome was added to the spectator layer.

The binding acceptance matrix is `verification/poc55/ACCEPTANCE.md`. This hardening adds evidence to AC14, AC16, AC36, AC40, AC41, EC3, EC4, EC6, and EC8. The original POC 5.5 implementation report and execution contract remain the baseline documentation.

## Findings and repairs

- `KIT_LOST` was journaled at the depot because Armory records defaulted all events to depot focus. Armory now accepts an optional factual focus and the loss producer supplies the fallen citizen’s world position. The live producer test verifies the citizen is dead and away from the depot, the event retains society and equipment identity, the fact focus and resolved navigation target are the casualty position, and navigating leaves economy, equipment, and combat unchanged. The renderer test clicks a readable KIT LOST card and checks that the camera frames an off-depot casualty location.
- `ABILITY_STATE` was mechanical telemetry that entered the spectator journal and candidate source. Armory now retains the event internally but can suppress publication to the EventJournal; Prepared Fire uses that path. Focused event and live producer checks confirm the telemetry remains in Armory evidence and cannot enter the spectator journal, recent feed, or Priority/Random event candidates. The accepted 6,200-tick attack digest remains `c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2`.
- Director candidate eligibility used a hardcoded 20-second threshold. Candidates now carry story, subject, and location durations from `spectator_event_catalog.gd`; cooldown checks use the value associated with each scope. The test checks each duration independently, checks live candidates against catalog metadata, and confirms expiry is not blocked by the former fixed threshold.

## Verification

All required gates passed on the final production changes:

- Focused POC 5.5, including events, Director, target lifecycle, live producers, and rendered UI.
- Isolation: OFF, PRIORITY, RANDOM, and FOLLOW share the same simulation digest at ticks 1,000, 3,000, and 6,200.
- Graphics: real-renderer capture and UI checks, including `graphics/kit-lost-event-focus.png`.
- POC 5.4: two repeated runs passed with identical outputs.
- Canonical: three fresh eight-day runs passed with fingerprint `6a44ed56eb40fe9e92ee89b3b3037be4a7f66124b82f79a54f2ef204127c449a` on all three runs.
- Full Regression: exit code 0, including POC 4/4.5/4.6, Room A/B production smoke, POC 4.7 placement/planner/packing checks, and all 20 positive POC 4.7.1 exploration scenarios.
- `git diff --check`: clean.

The precise receipts are included under `verification/poc55/hardening-*`; the evidence bundle contains the complete POC 5.5 verification tree. Shade independently reran Focused and Graphics and inspected the rendered captures. Shade noted that the UI click fixture uses a synthetic off-depot focus; the live producer test independently verifies the actual death-to-event focus and resolution path.

## Commands

```powershell
./TEST_ROOM_SCALE_POC55.ps1 -Mode Focused -OutputDirectory verification/poc55/hardening-focused
./TEST_ROOM_SCALE_POC55.ps1 -Mode Isolation -OutputDirectory verification/poc55/hardening-isolation
./TEST_ROOM_SCALE_POC55.ps1 -Mode Graphics -OutputDirectory verification/poc55
./TEST_ROOM_SCALE_POC54.ps1 -RunCount 2 -OutputDirectory verification/poc55/hardening-poc54
./TEST_ROOM_SCALE.ps1 -Mode Canonical -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/hardening-canonical
./TEST_ROOM_SCALE.ps1 -Mode Regression -PythonExecutable C:\Users\Zero\python_projects\ai\roomscale\.venv\Scripts\python.exe -OutputDirectory verification/poc55/hardening-regression
git diff --check
```

## Publication and review

Rules Lawyer reviewed implementation SHA `474d1f0ea77961c8201f0cd948478f1166dc2435` and returned COMPLETE for AC14/EC4; all other accepted AC/EC results remain valid. The branch remains `codex/spectator-director` and has not been merged. The final documentation/evidence refresh follows the reviewed code commit; its branch SHA is included in the delivery report.
