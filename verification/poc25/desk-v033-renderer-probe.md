# Desk v033 renderer capability probe

This is a bounded diagnostic of the current candidate mesh/material through the normal RoomScale production render harness. It does not change project settings or establish a renderer migration.

- Candidate: `desk-v033`.
- Godot: 4.7.2 official.
- Project renderer: remains `gl_compatibility`.
- Probe renderer: command-line override `--rendering-method forward_plus`.
- Output: `art/desk/iterations/v033/renderer-probes/forward-plus-run-001/`.
- Compatibility acceptance capture: `art/desk/iterations/v033/render-runs/run-001/`.
- Both receipts verify `production_path: true` and resolve `desk-v033`.
- Visual observation: Forward+ retains the same near-black tabletop and isolated ring highlights; it does not materially improve broad glass reflections, edge character, or support joins.
- Detail capture: 50 FPS / 313,378 primitives under Forward+ versus 48 FPS / 313,378 primitives under Compatibility. Initial room/settlement captures report 1 FPS during cold shader/renderer setup and are not treated as steady-state performance measurements.
- Result: current evidence points to the dark base-color/material and under-resolved construction rather than renderer choice alone. No global renderer change is justified by this probe.

The project keeps its configured Compatibility renderer. See the official [Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) for current feature availability.
