# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| EXP-ROUTING-00 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 155.6 | 223.0 | 368.8 | 765.0 | 1074.2 | 12 |  |
| EXP-ROUTING-01 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 155.6 | 223.0 | 368.8 | 765.0 | 1074.2 | 12 |  |
| EXP-ROUTING-02 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 155.6 | 223.0 | 368.8 | 765.0 | 1074.2 | 12 |  |
| EXP-ROUTING-03 | 471005 | positive | Mixed Obstacle Routing | True | FAIL | — | — | — | — | — | 5 | Citizen inside navigation obstacle: (-9.08322, 0.0, 57.02774) citizen=3 task=FLOOR_PATROL Missing milestone shelter_complete Missing milestone depot_complete Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| EXP-ROUTING-04 | 471005 | positive | Mixed Obstacle Routing | True | FAIL | — | — | — | — | — | 5 | Citizen inside navigation obstacle: (-9.08322, 0.0, 57.02774) citizen=3 task=FLOOR_PATROL Missing milestone shelter_complete Missing milestone depot_complete Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| EXP-ROUTING-05 | 471005 | positive | Mixed Obstacle Routing | True | FAIL | — | — | — | — | — | 5 | Citizen inside navigation obstacle: (-9.08322, 0.0, 57.02774) citizen=3 task=FLOOR_PATROL Missing milestone shelter_complete Missing milestone depot_complete Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| EXP-WATER-00 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 820.0 | 599.0 | 12 |  |
| EXP-WATER-01 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 981.5 | 12 |  |
| EXP-WATER-02 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 977.0 | 12 |  |
| EXP-WATER-03 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 1164.5 | 12 |  |
| EXP-WATER-04 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 1553.4 | 12 |  |
| EXP-WATER-05 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 1687.7 | 12 |  |
| EXP-ORIGIN-00 | 471017 | positive | Combined layout variation | True | PASS | 144.6 | 197.6 | 323.8 | 730.0 | 1045.1 | 12 |  |
| EXP-ORIGIN-01 | 471017 | positive | Combined layout variation | True | PASS | 141.8 | 246.0 | 380.5 | 785.0 | 1037.1 | 12 |  |
| EXP-ORIGIN-02 | 471017 | positive | Combined layout variation | True | PASS | 138.5 | 188.9 | 317.0 | 735.0 | 1042.5 | 12 |  |
| EXP-ORIGIN-03 | 471017 | positive | Combined layout variation | True | PASS | 141.6 | 192.0 | 324.2 | 735.0 | 1047.6 | 12 |  |
| EXP-ORIGIN-04 | 471017 | positive | Combined layout variation | True | PASS | 144.5 | 200.5 | 336.8 | 745.0 | 1041.1 | 12 |  |
| EXP-ORIGIN-05 | 471017 | positive | Combined layout variation | True | PASS | 149.9 | 208.7 | 342.0 | 745.0 | 1042.5 | 12 |  |
| EXP-IDENTITY-00 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 328.4 | 735.0 | 982.8 | 12 |  |
| EXP-IDENTITY-01 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 328.4 | 735.0 | 982.8 | 12 |  |

## Timing outliers

- shelter_complete: EXP-ROUTING-00 155.6s; EXP-ROUTING-01 155.6s; EXP-ROUTING-02 155.6s
- workshop_complete: EXP-ORIGIN-01 380.5s; EXP-ROUTING-00 368.8s; EXP-ROUTING-01 368.8s
- sixth_citizen: EXP-WATER-00 820.0s; EXP-ORIGIN-01 785.0s; EXP-ROUTING-00 765.0s
- traversal_complete: EXP-WATER-05 1687.7s; EXP-WATER-04 1553.4s; EXP-WATER-03 1164.5s
