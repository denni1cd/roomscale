# Outlier investigation notes

These explanations use final frozen-source evidence, not hypothetical balance
changes. Complete rankings and route measurements are generated in [outliers.md](outliers.md).

Long Salvage Haul (POS001) finishes workshop at414.1s and first housing at523.9s;
first growth follows at825.0s. Its safe salvage approach lengths are94.1–149.5in.
The sequence records actual salvage, material hauling, delivery and work. Growth
is301.1s after housing completion, consistent with the300s stability policy plus
planner evaluation ticks. It is a slower successful founding sequence, not an idle
or free-material success.

Constrained Build Sites (POS005) deploys traversal at1707.0s, with start1505.2s.
Floor-water exhaustion is recorded1479.99999999975s; the project begins about25s
later. Actual start-to-deployment is201.8s. Most startup delay precedes project
creation and follows the founder policy to use bootstrap floor water first. The
complete input and legal site certificate remain available beside its result.

Low Bootstrap Reserves (POS007) has the slowest shelter among the early core
results (175.9s), yet earlier traversal (967.0s). Floor water exhausts840s and
traversal starts860.6s. Needs interruptions, worker choices and material movements
matter separately from total source reserves. Timings are not assumed monotonic
across different random layouts and supplies.

The Explore water sweep changes only the long-water variant's finite floor water
amounts (30,37.5,45,52.5,60,75). Obstacle increments0–5 probe the mixed-routing
seed; origins move in4-inch increments around the previously failing shelter
corner; object/target IDs are renamed and registration order is reversed. Every
probe is a fresh physical simulation. These controlled variations separate local
placement and policy sensitivity from broad random coverage. They produced the
patrol-anchor defect during the earlier attempt; final probes pass after repair.

The measured successful core examples above have zero failed tasks and no strategic
stall windows. Final rankings can include later slower variants and should be
read from the aggregate. No timer, speed, canonical source or project requirement
was changed to make an outlier pass. Accounting, real construction, population and
physical traversal remain required continuously.

## Controlled water sweep

| Floor water units | Traversal start (s) | Deployment (s) | Physical project duration (s) |
|---:|---:|---:|---:|
| 30 | 437.4 | 627.3 | 189.9 |
| 37.5 | 773.1 | 974.6 | 201.5 |
| 45 | 802.0 | 1001.0 | 199.0 |
| 52.5 | 969.3 | 1165.9 | 196.6 |
| 60 | 1284.0 | 1512.6 | 228.6 |
| 75 | 1499.4 | 1705.7 | 206.3 |

Source: `exploration/EXP-WATER-00` through `EXP-WATER-05` configs and results.
The same saved layout/seed is used; only the finite floor water input changes.
