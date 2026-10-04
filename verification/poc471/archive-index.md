# Campaign evidence index

Only `final/`, `exploration/` and `regressions-complete/` feed the final aggregate.
They execute after the last production fix. Other folders preserve investigation
history and must not be combined into the final pass/fail denominator.

| Folder | Purpose / result |
|---|---|
| baseline/ | Required starting SHA, Fast and canonical PASS before edits |
| initial/ and prefix-reproduction/ | Shelter rest/apron founding deadlock |
| postfix-regression/ | First depot-apron repair reproduction |
| campaign-1/ | Initial broader campaign; stopped after48 completed candidates when physical corner clipping was reproduced |
| navigation-regression/ and navigation-regression-second/ | Exact exterior connector reproductions |
| regressions-nav/ and regressions-final/ | Earlier shared regression failures exposing legacy interior-anchor contract and recursive unreachable work |
| focused-final/ and focused-final-mixed/ | Focused corner/depot cases after early fixes |
| final-before-fraction/ | Interrupted intermediate campaign before fractional/patrol/narrow-aisle corrections |
| exploration-before-fraction/ | Obstacle increments expose blocked patrol target; other probes retained |
| regressions-complete-before-fraction/ | Earlier complete-suite attempt; sustained task age test failure retained |
| fraction-prefix/ | Exact half-unit puddle prevents traversal |
| fraction-postfix/ and fraction-grid-postfix/ | Saved half-unit scenario passes after repair |
| patrol-postfix/ | Saved additional-detour scenario passes after anchor repair |
| task-age-postfix/, task-failure-investigation/, task-failure-position-valid/ | Corrected live age reveals1,310 failed navigation retries for one citizen in sub-grid aisle |
| task-failure-position/ | Short failed diagnostic attempt with a GDScript type-inference error; not production evidence |
| narrow-aisle-postfix/ and narrow-aisle-grid-postfix/ | Seven-day sustained run passes after aisle and diagonal corrections |
| pre-freeze-poc47/ | Fast + three canonical repeats after first six repairs |
| final-before-link-repath/ | Core variants and negatives pass; first two soaks fail at about20days when housing replans active climbers |
| exploration-before-link-repath/ | All20 probes pass before last midlink repair; rerun still required |
| regressions-complete-before-link-repath/ | Earlier green suites, superseded by suites after last fix |
| midlink-unit-pre/ | Isolated navigation fixture fails against retained801a497 source; this is test geometry, not an earned production link |
| link-prefix-input/ and link-postfix-1/2/ | Same two saved soak definitions, each21days, beyond failure times; repair passes |
| midlink-pre-freeze-poc47/ | Fast + three canonical repeats after midlink repair |
| final/ | Final core candidates, fractional regression, five negatives, three soaks and six repeats |
| exploration/ | Final20 controlled probes |
| regressions-complete/ | Final shared suites and all three focused units |

## Replaying archived evidence

Archived configs preserve their original receipt hashes and paths. Where an original
stored command refers to a reused `final/` path, pass the config in its archived
folder explicitly. Reproduce locates the complete definition beside that config,
so the original absolute `room_file` does not need rewriting. For example:

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/final-before-link-repath/SOAK-01/config.json -OutputDirectory verification/poc471/reproduced -Workers 1
```

This replays the input against the currently checked-out production code. Reproducing
a pre-fix failure additionally requires that recorded source commit; final-source
replay is expected to demonstrate the repair. Root causes give specific commands.
Historical receipts from uncommitted focused patches also include normalized source
hashes; they are diagnostic evidence and are not the frozen final-source manifest.
No unrelated accepted historical verification artifact was rewritten.
