# Milestone 3 — Surface Navigation and Goal

Status: **PASS**

- Added explicit `FLOOR` and `DESK` navigation regions at 0in and 30in. The regions begin disconnected, and a cross-region route request returns a deterministic reason.
- The desk has a collision surface for screen-ray picking, a visible selection outline, and a Reach / Explore UI action. The production mouse-ray selection API is exercised by the smoke test using the projected desk-top screen coordinate.
- Reach / Explore checks the missing FLOOR-to-DESK route, chooses the two closest citizens with valid routes, supersedes their prior assignments, and gives them distinct floor A* investigation points beside the desk. Both positions are outside major-obstacle footprints.
- Barrier recognition happens only after both assigned explorers physically arrive; the coordinator retries the region route and records the disconnected pair, route failure reason, investigators, and approach location. No construction project, resource delivery, equipment, or traversal link is created in M3.
- Latest wrapper run: `milestone3-smoke.log` — M2 checks PASS; M3 checks PASS, two of two investigators arrived in 16.25s and confirmed the missing link.
- Parent verified the live window end to end: desk click selected the surface, Enter issued Reach / Explore, explorers traveled, and the barrier status appeared after arrival.
- Fresh visible captures generated from the production scene and public pick/goal APIs: `milestone3-startup.png`, `milestone3-target-selected.png`, and `milestone3-desk-investigation.png`, each with a matching log. The target-selected capture shows the clickable Reach / Explore control; the investigation capture shows the confirmed barrier and two explorers.

M0–M3 are complete. AC-08 and AC-09 pass. AC-10 and later construction/traversal criteria remain future scope. Do not start M4 in this change.
