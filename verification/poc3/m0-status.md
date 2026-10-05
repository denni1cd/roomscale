# POC 3 Milestone 0

Canonical visual room: Room A, unchanged RoomDefinition. Baseline source commit:
`ec95e2d2661db8b11b804865ce9ffd894d511648`. Working branch:
`codex/roomscale-poc3-visual-fidelity`. Godot 4.7.2 standard, Compatibility renderer,
NVIDIA GeForce RTX 5090, 1280 × 720 viewport.

Functional baseline PASS: `logs/m0-fast.log` and `logs/m0-room-a.log`.
The full production scenario recorded 50 citizens, 11 material deliveries,
three construction components, an eight-segment cable at 0.07in radius,
three distinct travelers, three explorations, and two autonomous route reuses.
Every M2–M6/M8 marker passed. Simulation and navigation remain inch-based and
RoomDefinition-derived; no presentation modifications preceded this run.

The original 11-phase capture set is in `baseline/`, with camera sidecars.
Supplemental benchmark capture instrumentation adds settlement close view,
live-subject citizen/carrying close views, and completed grapple. It follows
moving subjects at the instant of capture without altering tasks, positions,
construction progress, or population. A 2in capture-only camera distance is
used because the production 22in minimum cannot show citizen detail.
Supplemental run: `logs/m0-detail-benchmarks.log` (check terminal pass markers).

Inspected original and supplemental room/citizen/settlement captures show:

- Excessive fill light washes warm surfaces toward yellow and cream.
- Citizens have oversized featureless heads; cap, face, roles, and body details
  are hard to distinguish. Existing unshaded citizen materials lack depth.
- Furniture lacks edge treatment, hardware, drawers, upholstery, and contents.
- Settlement buildings look large relative to half-inch citizens; the boiler
  and flat roof wings dominate the workshop silhouette.
- Original 22–28in citizen/detail framing is too distant and moving subjects
  can leave the frame during the capture wait.
- Shader/material response and floor surface detail are weak.

Supplemental snapshot telemetry: citizen close 60 FPS, 245 draw calls,
448,368 rendered primitives; settlement close 60 FPS, 685 draw calls,
1,373,044 primitives. These are viewport samples at a 60 FPS cap, not uncapped
GPU throughput or percentile frame timing. Sidecars record each sample.

Pre-existing failure: fast test exits 0 and passes assertions but reports
66 material, 3 shader, 86 mesh, 86 instance RID leaks, 247 ObjectDB instances,
and one resource at shutdown. Preserve diagnostics; do not report error-free
fast testing until cleanup is repaired. Full visible baseline has no script
or renderer errors.

POC 3 is not complete. M1–M10 require their own runtime and visual evidence.
