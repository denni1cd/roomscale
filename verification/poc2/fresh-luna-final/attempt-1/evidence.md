# Fresh reconstruction evidence and uncertainty — attempt 1

## Evidence inspected

Only `photo_holder/Sample (1).jpg` and `photo_holder/Sample (3).jpg` were used. They show the same furnished room from substantially different viewpoints.

- **Sample (1):** dark green walls, brown crown and baseboard trim, carpet, two large framed multi-pane windows on adjoining walls, a long striped hammock and support stand, a dark mat with clothing/toys, a framed map near a corner, a floor lamp, and the edge of a computer desk with several monitors. A bright green low saucer seat is in the foreground.
- **Sample (3):** the same green walls and carpet, a large wall picture above a wide computer desk with multiple monitors, a tall warm-wood glass-front cabinet, gray storage tote, French doors with wood frames, a dark office chair, and the same bright green low saucer seat. This view makes a broad clear central floor area apparent.

## Coordinate frame and scale

The floor origin is its center at `[0,0,0]`, with `+Y` up. The desk and French-door wall is south (`+Z`); the adjoining windowed walls are north (`-Z`) and west (`-X`). The `180 × 168`-inch room and 96-inch wall height are rough residential estimates inferred from typical door, window, and furniture proportions. **No scale measurement was supplied**, and none was treated as measured.

## Approximation and uncertainty

The photos do not reveal the full floor perimeter or all wall-to-wall relationships, so room dimensions, opening widths, and exact object positions are approximate. The hammock, floor textile, and bright clutter are simplified into procedural shapes. The desk is the elevated target because both views support a wide computer work surface; monitors are visual-only objects on it. The room shell can show rectangular walls, flat ceiling color, windows, doors, and simple trim, but cannot represent divided-light profiles, fine frame details, hanging clutter, or the map/painting imagery. No additional photograph is needed for a recognizable, navigable approximation; wide views of each corner would improve dimensions and opening placement.

## Validation record

- Candidate: `verification/poc2/fresh-luna-final/attempt-1/fresh-luna-final.json`
- Attempt: 1, preserved unchanged after generation
- Validator command: `./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fresh-luna-final/attempt-1/fresh-luna-final.json -LogPath verification/poc2/fresh-luna-final/attempt-1/validator.log`
- Validator: repository `VALIDATE_ROOM_SCALE.ps1` via Godot 4.7.2
- Result: structural validation passed; runtime-navigation validation failed. The validator reported one reachable target approach and no clear reachable construction point near the target. Full diagnostics are in `validator.log`.
