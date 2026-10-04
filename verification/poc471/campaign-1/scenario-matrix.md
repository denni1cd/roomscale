# POC 4.7.1 scenario matrix

Times are production simulation seconds. Missing milestones are shown as —.

| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|
| POS-001 | 471000 | positive | Long Salvage Haul | True | PASS | 143.7 | 227.2 | 408.3 | 820.0 | 1466.3 | 12 |  |
| POS-002 | 471001 | positive | Long Water Haul | True | PASS | 130.3 | 197.0 | 327.3 | 735.0 | 1603.7 | 12 |  |
| POS-003 | 471002 | positive | Crowded Settlement Origin | True | PASS | 128.0 | 212.5 | 376.6 | 795.0 | 1174.1 | 12 |  |
| POS-004 | 471003 | positive | Alternative Founder Origin | True | PASS | 163.0 | 230.8 | 366.6 | 775.0 | 974.3 | 12 |  |
| POS-005 | 471004 | positive | Constrained Build Sites | True | PASS | 130.0 | 241.4 | 380.6 | 800.0 | 1668.5 | 12 |  |
| POS-006 | 471005 | positive | Mixed Obstacle Routing | True | PASS | 155.6 | 223.0 | 368.8 | 765.0 | 1074.2 | 12 |  |
| POS-007 | 471006 | positive | Low Bootstrap Reserves | True | PASS | 177.7 | 247.7 | 383.9 | 805.0 | 960.0 | 12 |  |
| POS-008 | 471007 | positive | Resource Separation | True | PASS | 152.3 | 211.7 | 349.7 | 750.0 | 925.7 | 12 |  |
| POS-009 | 471008 | positive | Traversal Distance Variation | True | PASS | 122.0 | 184.5 | 328.4 | 735.0 | 982.8 | 12 |  |
| POS-010 | 471009 | positive | Late Growth Pressure | True | PASS | 148.5 | 212.7 | 375.0 | 790.0 | 1411.9 | 10 |  |
| POS-011 | 471010 | positive | Combined layout variation | True | PASS | 122.1 | 180.9 | 299.3 | 720.0 | 1363.3 | 12 |  |
| POS-012 | 471011 | positive | Combined layout variation | True | PASS | 110.4 | 164.9 | 295.8 | 700.0 | 1073.4 | 12 |  |
| POS-013 | 471012 | positive | Combined layout variation | True | PASS | 127.0 | 182.4 | 318.8 | 725.0 | 1657.5 | 12 |  |
| POS-014 | 471013 | positive | Combined layout variation | True | PASS | 150.4 | 206.7 | 339.7 | 750.0 | 1531.4 | 12 |  |
| POS-015 | 471014 | positive | Combined layout variation | True | PASS | 138.6 | 206.1 | 320.7 | 720.0 | 1554.9 | 12 |  |
| POS-016 | 471015 | positive | Combined layout variation | True | PASS | 118.6 | 195.5 | 357.8 | 780.0 | 1676.8 | 12 |  |
| POS-017 | 471016 | positive | Combined layout variation | True | PASS | 121.7 | 185.2 | 299.0 | 720.0 | 1354.7 | 12 |  |
| POS-018 | 471017 | positive | Combined layout variation | True | FAIL | 141.8 | — | — | — | — | 5 | Citizen inside navigation obstacle: (9.664463, 0.0, 19.15223) citizen=4 task=FLOOR_PATROL Missing milestone depot_complete Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| POS-019 | 471018 | positive | Combined layout variation | True | PASS | 146.9 | 203.6 | 341.0 | 750.0 | 1606.0 | 12 |  |
| POS-020 | 471019 | positive | Combined layout variation | True | PASS | 119.5 | 176.3 | 323.6 | 740.0 | 1628.8 | 12 |  |
| POS-021 | 471020 | positive | Combined layout variation | True | PASS | 167.5 | 222.0 | 356.0 | 755.0 | 1627.2 | 12 |  |
| POS-022 | 471021 | positive | Combined layout variation | True | PASS | 165.4 | 221.1 | 371.3 | 795.0 | 1482.2 | 12 |  |
| POS-023 | 471022 | rejected | Combined layout variation | False | REJECTED | — | — | — | — | — | 5 | Generator invalid: insufficient feasibility certificate |
| POS-024 | 471023 | positive | Combined layout variation | True | PASS | 146.2 | 207.4 | 327.3 | 735.0 | 889.8 | 12 |  |
| POS-025 | 471024 | positive | Combined layout variation | True | PASS | 152.4 | 209.4 | 359.8 | 755.0 | 1424.1 | 12 |  |
| POS-026 | 471025 | positive | Combined layout variation | True | PASS | 154.2 | 211.5 | 340.2 | 750.0 | 1075.9 | 12 |  |
| POS-027 | 471026 | positive | Combined layout variation | True | PASS | 162.7 | 217.6 | 339.9 | 740.0 | 1623.2 | 12 |  |
| POS-028 | 471027 | positive | Combined layout variation | True | PASS | 167.2 | 228.0 | 356.4 | 785.0 | 1655.6 | 12 |  |
| POS-029 | 471028 | rejected | Combined layout variation | False | REJECTED | — | — | — | — | — | 5 | Generator invalid: insufficient feasibility certificate |
| POS-030 | 471029 | positive | Combined layout variation | True | PASS | 138.5 | 190.7 | 319.6 | 725.0 | 876.7 | 12 |  |
| POS-031 | 471030 | positive | Combined layout variation | True | PASS | 151.8 | 217.6 | 362.3 | 765.0 | 947.0 | 12 |  |
| POS-032 | 471031 | positive | Combined layout variation | True | PASS | 154.5 | 229.6 | 361.4 | 765.0 | 1544.5 | 12 |  |
| POS-033 | 471032 | positive | Combined layout variation | True | PASS | 128.1 | 188.3 | 311.9 | 710.0 | 982.5 | 12 |  |
| POS-034 | 471033 | positive | Combined layout variation | True | PASS | 165.7 | 235.3 | 367.0 | 790.0 | 1621.1 | 12 |  |
| POS-035 | 471034 | positive | Combined layout variation | True | PASS | 125.4 | 192.1 | 306.7 | 720.0 | 1371.0 | 12 |  |
| POS-036 | 471035 | positive | Combined layout variation | True | FAIL | 116.0 | 178.1 | — | — | — | 5 | Citizen inside navigation obstacle: (9.664463, 0.0, -4.847773) citizen=2 task=FLOOR_PATROL Missing milestone workshop_complete Missing milestone housing_complete Missing milestone sixth_citizen Missing milestone traversal_complete Missing milestone physical_climb Missing milestone elevated_territory |
| POS-037 | 471036 | positive | Combined layout variation | True | PASS | 152.1 | 202.0 | 352.1 | 760.0 | 1626.8 | 12 |  |
| POS-038 | 471037 | positive | Combined layout variation | True | PASS | 154.3 | 212.4 | 338.3 | 740.0 | 1568.1 | 12 |  |
| POS-039 | 471038 | positive | Combined layout variation | True | PASS | 139.3 | 197.4 | 317.0 | 730.0 | 1082.0 | 12 |  |
| POS-040 | 471039 | positive | Combined layout variation | True | PASS | 114.9 | 176.9 | 332.9 | 745.0 | 1562.3 | 12 |  |
| POS-041 | 471040 | positive | Combined layout variation | True | PASS | 124.7 | 205.5 | 328.1 | 745.0 | 1490.8 | 12 |  |
| POS-042 | 471041 | positive | Combined layout variation | True | PASS | 109.5 | 172.8 | 299.9 | 710.0 | 912.4 | 12 |  |
| POS-043 | 471042 | positive | Combined layout variation | True | PASS | 132.9 | 189.5 | 325.1 | 735.0 | 980.9 | 12 |  |
| POS-044 | 471043 | positive | Combined layout variation | True | PASS | 112.8 | 187.2 | 330.2 | 740.0 | 1129.8 | 12 |  |
| POS-045 | 471044 | positive | Combined layout variation | True | PASS | 159.9 | 212.0 | 337.5 | 745.0 | 1556.8 | 12 |  |
| POS-046 | 471045 | positive | Combined layout variation | True | PASS | 181.4 | 253.8 | 403.9 | 805.0 | 1655.5 | 12 |  |
| POS-047 | 471046 | positive | Combined layout variation | True | PASS | 123.0 | 185.5 | 301.9 | 715.0 | 873.2 | 12 |  |
| POS-048 | 471047 | positive | Combined layout variation | True | PASS | 140.3 | 189.1 | 322.0 | 735.0 | 1556.7 | 12 |  |

## Timing outliers

- shelter_complete: POS-046 181.4s; POS-007 177.7s; POS-021 167.5s
- workshop_complete: POS-001 408.3s; POS-046 403.9s; POS-007 383.9s
- sixth_citizen: POS-001 820.0s; POS-007 805.0s; POS-046 805.0s
- traversal_complete: POS-016 1676.8s; POS-005 1668.5s; POS-013 1657.5s
