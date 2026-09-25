# Milestone 1 — Room and Camera

Status: **PASS**

- World convention is 1 unit = 1 inch. The generated room floor is 240 × 180 inches and the three walls are 72 inches tall.
- `scripts/pipeline_proof.gd` generates the open-front room, wood floor and seams, window and wall art, 30-inch desk, 18-inch chair, bookcase, rug, side table, desk items, plants, storage box, waste bin, lighting, and interface. Geometry and materials are created at runtime; there are no imported art assets or editor-authored nodes.
- `scripts/strategy_camera.gd` implements mouse orbit/tilt, middle-drag pan, wheel zoom, WASD/arrow pan, Q/E vertical pan, and 1/2/3 room/settlement/citizen framing presets.
- Visible launch through `RUN_ROOM_SCALE.ps1` saved `milestone1-launch-script.png`; visible log `milestone1-launch-script.log` records `ROOMSCALE_M1_VISIBLE_PASS` and successful PNG write. The image was inspected and contains the same final room capture as `milestone1-room-final.png`.
- `TEST_ROOM_SCALE.ps1` headless run passes: `milestone1-smoke.log` confirms 15 required nodes, room/furniture inch-scale dimensions, all three zoom presets, and pan/orbit/tilt/zoom state changes.

Milestone 0 and Milestone 1 are complete. No population, simulation, or gameplay systems from Milestone 2 have been started.
