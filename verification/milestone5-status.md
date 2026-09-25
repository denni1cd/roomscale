# Milestone 5 — Grapple Deployment and Traversal

Status: **PASS**

- FLOOR and DESK remain disconnected through base, winch, and launcher construction. The completed launcher then creates a 13-segment visible cable from the launcher head to an anchor offset from the desk landing point.
- Deployment registers a FLOOR–DESK connection whose route contains the floor launcher approach, tower ascent, interpolated cable points, and desk landing. Smoke queries from the actual M3 investigation position and checks the prepended floor A* route joins cable points with no gap over 8in.
- Cable deployment assigns one citizen a production `GRAPPLE_TRAVERSAL` task. That citizen follows floor A*, climbs the tower, and traverses the cable with continuous 3D movement at the normal 6.5in/s walking speed. Arrival is validated at the desk position, height, active task, deployed connection, and walked route distance; the citizen remains `ON_DESK`.
- Player feedback displays cable/link state and the traversal task status and walked distance.
- Latest wrapper: `TEST_ROOM_SCALE.ps1 -LogPath verification/milestone5-smoke.log` — exit 0; M2/M3/M4 regressions and M5 PASS. Cable/link stayed absent until construction completed. It then exposed 13 cable segments and a 63-point route. Citizen18 reached `(-58, 30, -52)`, walking 162.1in on a 160.4in route in 24.40s; the largest sampled step was 1.34in.
- Fresh visible evidence was generated through the production desk-selection and Reach/Explore APIs and inspected: `milestone5-deployed-cable.png` shows the cable spanning the launcher to desk edge; `milestone5-citizen-on-desk.png` shows the 0.5in citizen standing on the desk at an 8in evidence camera distance, clear of the HUD. The normal camera zoom minimum is unchanged.

AC-13, AC-14, and AC-15 pass. AC-16 desk exploration and later integration criteria remain future work. M6 is next; do not start it in this change.
