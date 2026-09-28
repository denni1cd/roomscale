# Second-room reconstruction — photo-derived candidate

Source: the four ordinary photographs in `photo_holder/second_room/`. This is a separate cross-room candidate; it does not replace the canonical green-room candidate or alter its gameplay record.

## Photo evidence and layout hypothesis

- The overlapping views show a carpeted living room with a broad stone fireplace and raised hearth, built-in oak shelves and lower cupboards, two large divided windows with light shades, a glazed exterior door, a central octagonal glass coffee table, and a deep green sofa near the adjoining area.
- A three-panel orange-and-blue dragon artwork is on the wall opposite the fireplace. Two small patterned floor cushions and an oak side table are visible near the window/fireplace end.
- The same fireplace, built-ins, window wall, and coffee table recur across the photographs and are represented once.
- The boxes, unpacking materials, and loose tabletop items are temporary moving clutter, so they are omitted from the stable room layout.

The candidate estimates a 300-by-264-inch floor and 108-inch wall height from ordinary furniture proportions. No known measurement was provided. It places the fireplace and built-ins on the north wall, shaded windows and a sliding glass door on the east wall, the sofa and artwork on the opposite end, and the coffee table in the open center.

## Gameplay-ready target

The coffee-table top is represented as the elevated `COFFEE_TABLE_TOP` surface. The validator derives four clear floor approaches and a reachable construction site. This is generic `RoomDefinition` data; the gameplay code was not given room-specific coordinates.

## Uncertainty and limits

The images do not show the full perimeter, opposite corners, or the exact connection between the glazed door and adjoining living area. Room dimensions and the wall-side assignments are approximate. A useful optional next view would be a wide, level shot from the fireplace side back toward the opposite wall, glass-door/entry area, and both far corners.

The renderer is deliberately geometric and stylized. The latest captures establish that the main landmarks and their relationships are present; they do not establish photo-level material, lighting, stone, furniture, or artwork similarity. The candidate passes the full M2/M3/M4/M5/M6/M8 gameplay loop (`production-full.log`). It has not yet been produced in a clean-clone/fresh-user-context run.

Candidate: [room_hearth_living_room.json](room_hearth_living_room.json). Validation evidence: [validator.log](validator.log). Screenshot capture helper: [capture_room.gd](capture_room.gd).
