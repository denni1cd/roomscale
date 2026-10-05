# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| EXP-ROUTING-00 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 156.5 | 234.1 | 401.2 | 795.0 | 1066.6 | 12 |  |
| EXP-ROUTING-01 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 156.5 | 234.1 | 401.2 | 795.0 | 1066.6 | 12 |  |
| EXP-ROUTING-02 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 156.5 | 234.1 | 401.2 | 795.0 | 1066.6 | 12 |  |
| EXP-ROUTING-03 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 156.0 | 220.6 | 404.6 | 820.0 | 1068.3 | 12 |  |
| EXP-ROUTING-04 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 187.1 | 252.2 | 413.4 | 840.0 | 1067.8 | 12 |  |
| EXP-ROUTING-05 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 187.1 | 249.2 | 398.5 | 820.0 | 1065.0 | 12 |  |
| EXP-WATER-00 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 860.0 | 627.3 | 12 |  |
| EXP-WATER-01 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 745.0 | 974.6 | 12 |  |
| EXP-WATER-02 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 745.0 | 1001.0 | 12 |  |
| EXP-WATER-03 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 745.0 | 1165.9 | 12 |  |
| EXP-WATER-04 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 745.0 | 1512.6 | 12 |  |
| EXP-WATER-05 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 198.2 | 336.4 | 745.0 | 1705.7 | 12 |  |
| EXP-ORIGIN-00 | 471017 | positive | Combined layout variation | True | PASS | 148.0 | 202.8 | 329.3 | 725.0 | 1044.8 | 12 |  |
| EXP-ORIGIN-01 | 471017 | positive | Combined layout variation | True | PASS | 141.4 | 258.6 | 399.6 | 805.0 | 1045.4 | 12 |  |
| EXP-ORIGIN-02 | 471017 | positive | Combined layout variation | True | PASS | 139.6 | 192.9 | 324.9 | 740.0 | 1051.0 | 12 |  |
| EXP-ORIGIN-03 | 471017 | positive | Combined layout variation | True | PASS | 144.2 | 198.6 | 328.5 | 735.0 | 1050.2 | 12 |  |
| EXP-ORIGIN-04 | 471017 | positive | Combined layout variation | True | PASS | 144.8 | 204.6 | 343.8 | 750.0 | 1068.9 | 12 |  |
| EXP-ORIGIN-05 | 471017 | positive | Combined layout variation | True | PASS | 150.7 | 202.8 | 338.8 | 740.0 | 1057.3 | 12 |  |
| EXP-IDENTITY-00 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 335.8 | 750.0 | 990.0 | 12 |  |
| EXP-IDENTITY-01 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 335.8 | 750.0 | 990.0 | 12 |  |

## Timing outliers

- shelter_complete: EXP-ROUTING-04 187.1s; EXP-ROUTING-05 187.1s; EXP-ROUTING-00 156.5s
- workshop_complete: EXP-ROUTING-04 413.4s; EXP-ROUTING-03 404.6s; EXP-ROUTING-00 401.2s
- sixth_citizen: EXP-WATER-00 860.0s; EXP-ROUTING-04 840.0s; EXP-ROUTING-03 820.0s
- traversal_complete: EXP-WATER-05 1705.7s; EXP-WATER-04 1512.6s; EXP-WATER-03 1165.9s
