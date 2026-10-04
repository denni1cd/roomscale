# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| POS-001 | 471000 | positive | Long Salvage Haul | True | PASS | 143.7 | 227.2 | 408.3 | 820.0 | 1466.3 | 12 |  |
| POS-002 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 1603.7 | 12 |  |
| POS-003 | 471002 | positive | Crowded Settlement Origin | True | PASS | 128.0 | 212.5 | 376.6 | 795.0 | 1174.1 | 12 |  |
| POS-004 | 471003 | positive | Alternative Founder Origin | True | PASS | 163.0 | 230.8 | 366.6 | 775.0 | 974.3 | 12 |  |
| POS-005 | 471004 | positive | Constrained Build Sites | True | PASS | 130.0 | 241.4 | 380.6 | 800.0 | 1668.5 | 12 |  |
| POS-006 | 471005 | positive | Mixed Obstacle Routing | True | FAIL | 150.9 | — | — | — | — | 5 |  Missing milestone depot_complete Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| POS-007 | 471006 | positive | Low Bootstrap Reserves | True | PASS | 177.7 | 247.7 | 383.9 | 805.0 | 960.0 | 12 |  |
| POS-008 | 471007 | positive | Resource Separation | True | PASS | 152.3 | 211.7 | 349.7 | 750.0 | 925.7 | 12 |  |
| POS-009 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 328.4 | 735.0 | 982.8 | 12 |  |
| POS-010 | 471009 | positive | Late Growth Pressure | True | PASS | 148.5 | 212.7 | 375.0 | 790.0 | 1411.9 | 10 |  |
| NEG-01 | 472000 | negative | No Reachable Water | False | PASS | — | — | — | — | — | 5 |  |
| NEG-02 | 472001 | negative | Insufficient Shelter Materials | False | PASS | — | — | — | — | — | 5 |  |
| NEG-03 | 472002 | negative | No Valid Depot Site | False | PASS | 156.8 | — | — | — | — | 5 |  |
| NEG-04 | 472003 | negative | Critical Elevated Resource Before Workshop | False | PASS | — | — | — | — | — | 5 |  |
| NEG-05 | 472004 | negative | Disconnected Spawn | False | PASS | — | — | — | — | — | — |  |

## Timing outliers

- shelter_complete: POS-007 177.7s; POS-004 163.0s; POS-008 152.3s
- workshop_complete: POS-001 408.3s; POS-007 383.9s; POS-005 380.6s
- sixth_citizen: POS-001 820.0s; POS-007 805.0s; POS-005 800.0s
- traversal_complete: POS-005 1668.5s; POS-002 1603.7s; POS-001 1466.3s
