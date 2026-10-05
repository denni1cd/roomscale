# Baseline gate

Starting branch: codex/roomscale-poc45-fishbowl
Starting SHA: c0b93c5dd74081bc20068b7455ec9805dc5fb71d (exact match).
Production edits began only after all gates returned exit 0.

| Command | Exit | Seconds | Result |
|---|---:|---:|---|
| ./TEST_ROOM_SCALE_POC45.ps1 -Mode Fast -OutputDirectory verification/poc46/baseline/poc45-fast | 0 | 9.17 | PASS |
| ./TEST_ROOM_SCALE_POC45.ps1 -Mode Scenario -OutputDirectory verification/poc46/baseline/poc45-scenario | 0 | 69.80 | PASS |
| ./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc46/baseline/poc4-fast | 0 | 22.59 | PASS: fast, contract, cleanup |

Logs and structured results are retained in the directories above.
