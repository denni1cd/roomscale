# Fresh reconstruction evidence and uncertainty — final attempt

## Evidence and coordinate frame

Used exactly `photo_holder/Sample (1).jpg` and `photo_holder/Sample (3).jpg`, showing the same green-walled, carpeted room from different sides. Sample (1) shows two adjoining-wall windows, wood trim, hammock/stand, mat and clothes/toys, a map poster, floor lamp, and part of the computer setup. Sample (3) shows the computer desk and monitors, framed wall picture, tall wood glass-front cabinet, gray tote, French doors, office chair, and the bright green low saucer seat. Repeated features such as the green seat and computer setup are represented once each.

The floor origin is its center `[0,0,0]`, `+Y` is up, and the desk/French-door wall is south (`+Z`); the adjoining windowed walls are north (`-Z`) and west (`-X`). The `180 × 168`-inch footprint and 96-inch wall height are rough estimates from typical residential door, window, and furniture proportions. **No scale measurement was supplied.**

## Uncertainty and renderer limits

The photos do not show the full floor perimeter or every wall intersection; dimensions, exact opening positions, and object coordinates are approximate. The hammock, textile, and clutter are simplified as broad procedural shapes. The desk is the initial target because the images support a broad computer work surface. The rectangular shell supports walls, openings, a flat ceiling color, and simple trim, but not divided-light profiles, fine frame details, the painting/map imagery, or hanging clutter. A wide view of each corner would help refine the estimated perimeter and opening placement, but is not necessary for this recognizable approximation.

## Repair and validation

Attempt 1 passed structural checks but failed runtime navigation with one reachable desk approach and no reachable construction site. Attempt 2 opens the desk perimeter by moving it away from the room edges, separating it from the cabinet, and clearing the chair from the target's front. Attempt 1 remains unchanged.

- Candidate: `verification/poc2/fresh-luna-final/attempt-2/fresh-luna-final.json`
- Validator command: `./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fresh-luna-final/attempt-2/fresh-luna-final.json -LogPath verification/poc2/fresh-luna-final/attempt-2/validator.log`
- Validator: repository `VALIDATE_ROOM_SCALE.ps1` via Godot 4.7.2
- Result: explicit `ROOMSCALE_VALIDATION_PASS`; structural and runtime-navigation checks passed, with two reachable approaches and a valid derived construction site at `[-36,0,78]`.
