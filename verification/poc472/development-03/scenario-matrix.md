# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| NEG-03 | 472002 | negative | No Valid Depot Site | True | PASS | 145.3 | 255.6 | 435.7 | 815.0 | 1471.3 | 12 |  |
| POS-001 | 471000 | positive | Long Salvage Haul | True | PASS | 157.1 | 204.3 | 343.7 | 780.0 | 1443.5 | 12 |  |
| POS-006 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 140.7 | 189.1 | 337.8 | 715.0 | 1141.7 | 12 |  |
| POS-018 | 471017 | positive | Combined layout variation | True | PASS | 118.8 | 178.0 | 295.3 | 675.0 | 1035.3 | 12 |  |
| POS-023 | 471022 | positive | Combined layout variation | True | PASS | 91.4 | 141.8 | 282.4 | 660.0 | 1469.7 | 12 |  |
| POS-029 | 471028 | positive | Combined layout variation | True | PASS | 97.9 | 153.5 | 264.4 | 635.0 | 1094.0 | 12 |  |
| PLACE-001 | 472000 | positive | Wall-adjacent founders | True | PASS | 160.1 | 246.9 | 396.6 | 790.0 | 1516.1 | 12 |  |
| PLACE-002 | 472001 | rejected | Wall-adjacent founders | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-003 | 472002 | positive | Wall-adjacent founders | True | PASS | 174.9 | 239.5 | 388.1 | 785.0 | 1463.0 | 12 |  |
| PLACE-004 | 472003 | rejected | Wall-adjacent founders | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-005 | 472004 | rejected | Wall-adjacent founders | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-006 | 472005 | positive | Large furniture beside origin | True | PASS | 122.9 | 175.4 | 300.9 | 695.0 | 1387.5 | 12 |  |
| PLACE-007 | 472006 | rejected | Large furniture beside origin | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-008 | 472007 | rejected | Large furniture beside origin | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-009 | 472008 | positive | Large furniture beside origin | True | PASS | 193.0 | 251.9 | 408.6 | 800.0 | 1467.9 | 12 |  |
| PLACE-010 | 472009 | positive | Large furniture beside origin | True | PASS | 161.6 | 216.0 | 331.6 | 720.0 | 1428.9 | 12 |  |
| PLACE-011 | 472010 | positive | Narrow legal settlement corridor | True | PASS | 132.4 | 210.7 | 343.0 | 775.0 | 1473.7 | 12 |  |
| PLACE-012 | 472011 | positive | Narrow legal settlement corridor | True | PASS | 132.4 | 184.0 | 317.2 | 695.0 | 1334.0 | 12 |  |
| PLACE-013 | 472012 | rejected | Narrow legal settlement corridor | False | REJECTED | — | — | — | — | — | — | Generator invalid: navigation/connectivity |
| PLACE-014 | 472013 | positive | Narrow legal settlement corridor | True | PASS | 148.8 | 195.3 | 380.7 | 760.0 | 1465.9 | 12 |  |
| PLACE-015 | 472014 | positive | Narrow legal settlement corridor | True | PASS | 148.8 | 194.8 | 319.1 | 870.0 | 1473.3 | 12 |  |
| PLACE-016 | 472015 | positive | Separated open areas with legal connecting gaps | True | PASS | 168.9 | 244.0 | 388.0 | 780.0 | 1420.3 | 12 |  |
| PLACE-017 | 472016 | positive | Separated open areas with legal connecting gaps | True | PASS | 167.7 | 224.2 | 365.5 | 750.0 | 1477.5 | 12 |  |
| PLACE-018 | 472017 | positive | Separated open areas with legal connecting gaps | True | PASS | 175.2 | 236.3 | 367.5 | 745.0 | 1427.8 | 12 |  |
| PLACE-019 | 472018 | positive | Separated open areas with legal connecting gaps | True | PASS | 167.2 | 223.5 | 344.7 | 720.0 | 1444.9 | 12 |  |
| PLACE-020 | 472019 | positive | Separated open areas with legal connecting gaps | True | PASS | 174.4 | 225.4 | 354.0 | 725.0 | 1453.0 | 12 |  |
| PLACE-021 | 472020 | positive | Irregular obstacle arrangement | True | PASS | 159.7 | 232.9 | 363.8 | 755.0 | 1430.3 | 12 |  |
| PLACE-022 | 472021 | positive | Irregular obstacle arrangement | True | PASS | 133.5 | 192.1 | 298.8 | 710.0 | 1396.6 | 12 |  |
| PLACE-023 | 472022 | positive | Irregular obstacle arrangement | True | PASS | 142.5 | 204.4 | 293.2 | 715.0 | 1432.1 | 12 |  |
| PLACE-024 | 472023 | positive | Irregular obstacle arrangement | True | PASS | 145.9 | 208.8 | 306.1 | 700.0 | 1420.7 | 12 |  |
| PLACE-025 | 472024 | positive | Irregular obstacle arrangement | True | PASS | 130.4 | 207.0 | 316.7 | 695.0 | 1389.6 | 12 |  |
| PLACE-026 | 472025 | positive | Nearest legal site threatens downstream combinations | True | PASS | 159.3 | 209.5 | 370.6 | 830.0 | 1480.5 | 12 |  |
| PLACE-027 | 472026 | positive | Nearest legal site threatens downstream combinations | True | PASS | 159.3 | 209.5 | 370.6 | 830.0 | 1480.5 | 12 |  |
| PLACE-028 | 472027 | positive | Nearest legal site threatens downstream combinations | True | PASS | 159.3 | 263.8 | 425.6 | 820.0 | 1476.0 | 12 |  |
| PLACE-029 | 472028 | positive | Nearest legal site threatens downstream combinations | True | PASS | 159.3 | 209.2 | 363.8 | 760.0 | 1456.3 | 12 |  |
| PLACE-030 | 472029 | positive | Nearest legal site threatens downstream combinations | True | PASS | 159.3 | 209.2 | 363.8 | 760.0 | 1456.3 | 12 |  |

## Timing outliers

- shelter_complete: PLACE-009 193.0s; PLACE-018 175.2s; PLACE-003 174.9s
- workshop_complete: PLACE-028 425.6s; PLACE-009 408.6s; PLACE-001 396.6s
- sixth_citizen: PLACE-015 870.0s; PLACE-026 830.0s; PLACE-027 830.0s
- traversal_complete: PLACE-001 1516.1s; PLACE-026 1480.5s; PLACE-027 1480.5s
