# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| PLACE-031 | 472030 | positive | Only some legal apron combinations fit the founding chain | True | PASS | 153.6 | 225.9 | 389.8 | 815.0 | 1460.6 | 12 |  |
| NEG-PLACEMENT-01 | 472999 | negative | No Complete Founding Layout | False | PASS | — | — | — | — | — | 5 |  |
| POS-001 | 471000 | positive | Long Salvage Haul | True | PASS | 157.1 | 204.3 | 343.7 | 780.0 | 1443.5 | 12 |  |
| POS-023 | 471022 | positive | Combined layout variation | True | PASS | 91.4 | 141.8 | 282.4 | 660.0 | 1469.7 | 12 |  |

## Timing outliers

- shelter_complete: POS-001 157.1s; PLACE-031 153.6s; POS-023 91.4s
- workshop_complete: PLACE-031 389.8s; POS-001 343.7s; POS-023 282.4s
- sixth_citizen: PLACE-031 815.0s; POS-001 780.0s; POS-023 660.0s
- traversal_complete: POS-023 1469.7s; PLACE-031 1460.6s; POS-001 1443.5s
