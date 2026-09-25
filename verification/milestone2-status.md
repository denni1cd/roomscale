# Milestone 2 — Living Settlement

Status: **PASS**

- The code-generated settlement includes a clockwork workshop with boiler, chimney, gauge, exposed work bay and gear; a depot with resource crates and parts barrel; two canvas homes; and a labeled work yard.
- The floor pathfinder is a 4-inch A* grid over the M1 room. It marks the desk, chair, bookcase, table, storage box, major props, walls and settlement footprints as blocked, leaving approaches at the task stations. The smoke run found a 146.9-inch route around the desk where the straight route is 80 inches and confirmed every path point stays outside obstacle footprints.
- Exactly 50 separate procedural citizen nodes spawn on the floor. Each figure’s recorded height is 0.5 inches. Citizens follow A* waypoints, visibly walk/work, and carry parcels on deterministic depot-run tasks.
- A shared task coordinator maintains available, reserved, active, complete and failed task records. On capture there were 50 active tasks, 5 available, 1 complete and 0 failed.
- Current settlement-scale capture: `milestone2-settlement-final.png` (132-inch strategy camera distance). Close character inspection: `milestone2-citizen-close-final.png` (11-inch view following Citizen 24). Both logs record `ROOMSCALE_M2_VISIBLE_PASS`; both captures were generated from the committed M2 scene code and visually inspected.
- Latest `TEST_ROOM_SCALE.ps1` run: `milestone2-smoke.log` reports `ROOMSCALE_M2_SMOKE_PASS`, 50 citizens, 50 moving, three camera presets, and obstacle detour checks.

Milestones 0–2 are complete. M3 target selection/barrier detection and all later gameplay are not started.
