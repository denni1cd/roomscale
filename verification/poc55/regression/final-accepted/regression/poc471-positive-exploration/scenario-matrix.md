# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| EXP-ROUTING-00 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 140.7 | 189.1 | 340.9 | 720.0 | 1088.3 | 12 |  |
| EXP-ROUTING-01 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 140.7 | 189.1 | 329.6 | 710.0 | 1073.2 | 12 |  |
| EXP-ROUTING-02 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 140.7 | 189.1 | 329.6 | 730.0 | 1074.4 | 12 |  |
| EXP-ROUTING-03 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 156.2 | 213.0 | 330.8 | 735.0 | 1063.1 | 12 |  |
| EXP-ROUTING-04 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 171.6 | 226.6 | 377.7 | 785.0 | 1052.4 | 12 |  |
| EXP-ROUTING-05 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 171.6 | 226.6 | 377.7 | 785.0 | 1052.4 | 12 |  |
| EXP-WATER-00 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 795.0 | 568.7 | 12 |  |
| EXP-WATER-01 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 685.0 | 979.9 | 12 |  |
| EXP-WATER-02 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 685.0 | 970.9 | 12 |  |
| EXP-WATER-03 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 685.0 | 1141.1 | 12 |  |
| EXP-WATER-04 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 685.0 | 1419.8 | 12 |  |
| EXP-WATER-05 | 471001 | positive | Long Water Haul | True | PASS | 111.1 | 178.1 | 304.1 | 685.0 | 1639.9 | 12 |  |
| EXP-ORIGIN-00 | 471017 | positive | Combined layout variation | True | PASS | 120.8 | 179.8 | 314.7 | 745.0 | 1028.8 | 12 |  |
| EXP-ORIGIN-01 | 471017 | positive | Combined layout variation | True | PASS | 118.8 | 178.0 | 295.3 | 675.0 | 1035.3 | 12 |  |
| EXP-ORIGIN-02 | 471017 | positive | Combined layout variation | True | PASS | 118.9 | 239.1 | 375.4 | 750.0 | 1080.0 | 12 |  |
| EXP-ORIGIN-03 | 471017 | positive | Combined layout variation | True | PASS | 149.1 | 208.8 | 331.3 | 710.0 | 1068.9 | 12 |  |
| EXP-ORIGIN-04 | 471017 | positive | Combined layout variation | True | PASS | 123.5 | 194.8 | 311.5 | 695.0 | 1057.5 | 12 |  |
| EXP-ORIGIN-05 | 471017 | positive | Combined layout variation | True | PASS | 125.4 | 186.9 | 345.8 | 835.0 | 1053.9 | 12 |  |
| EXP-IDENTITY-00 | 471008 | positive | Traversal Distance Variation | True | PASS | 101.7 | 153.3 | 301.6 | 690.0 | 982.2 | 12 |  |
| EXP-IDENTITY-01 | 471008 | positive | Traversal Distance Variation | True | PASS | 101.7 | 153.3 | 301.6 | 690.0 | 982.2 | 12 |  |

## Timing outliers

- shelter_complete: EXP-ROUTING-04 171.6s; EXP-ROUTING-05 171.6s; EXP-ROUTING-03 156.2s
- workshop_complete: EXP-ROUTING-04 377.7s; EXP-ROUTING-05 377.7s; EXP-ORIGIN-02 375.4s
- sixth_citizen: EXP-ORIGIN-05 835.0s; EXP-WATER-00 795.0s; EXP-ROUTING-04 785.0s
- traversal_complete: EXP-WATER-05 1639.9s; EXP-WATER-04 1419.8s; EXP-WATER-03 1141.1s
