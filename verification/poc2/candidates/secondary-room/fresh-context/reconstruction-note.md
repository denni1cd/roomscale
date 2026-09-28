# Fresh-context reconstruction note

## Evidence and layout

All four permitted photos were inspected from the clean clone: `image0.jpeg` through `image3.jpeg`. `image0` shows the stone fireplace and built-in shelving at the left with two paired groups of wood-trimmed windows on the adjoining wall. `image1` confirms the large polygonal glass-top table, neutral carpet, teal sofa, and a full-height glazed opening near the sofa. `image2` shows the built-ins, broad raised stone hearth, window wall, and their shared corner from another angle. `image3` confirms the fireplace centered between wood bookcase/cabinet runs and shows blue-orange artwork on the opposite plain wall. The repeated table, fireplace, and window groups are each represented once.

The coordinate frame is an estimated rectangle: X runs along the long window wall, Z runs from that wall toward the opposite wall; north is negative Z and west is negative X. The fireplace/built-ins are placed on the west wall, four windows on the north wall, the teal sofa near the east-side full-height glass opening, and the artwork on the south wall. The central table is the target elevated surface. Temporary cardboard moving boxes and loose packing materials visible in the photos are excluded.

## Estimates and uncertainties

No known measurement appears in the evidence. The 240 by 204 inch floor, 96 inch wall height, window/opening widths, furniture dimensions, and all coordinates are plausible scale estimates based on ordinary residential proportions and relative image sizes, not measurements. The four window units are inferred as two pairs; perspective prevents exact spacing. The right-side glazing is treated as a full-height clear opening; sliding panels, blinds, hearth/firebox detailing, individual shelves, and the table's octagonal glass pattern cannot be represented faithfully by the generic shell and box/table archetypes. The renderer therefore approximates the table as a broad rectangular table and the built-ins as three blocks.

## Validation and gameplay result

Attempt 1 passed the documented validator without a repair; the root candidate is byte-identical to `attempt-1/room_hearth_living_room_fresh.json`. The final validator log at `validator.log` records structural and runtime-navigation PASS, four reachable target approaches, and a valid derived construction site. Attempt 1 and its separate validator log remain under `attempt-1/`.

The final candidate was also run with `./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/secondary-room/fresh-context/room_hearth_living_room_fresh.json -TimeoutSeconds 360 -LogPath verification/poc2/candidates/secondary-room/fresh-context/gameplay.log`. The wrapper exited 0 and the saved production log contains M2, M3, M4, M5, M6, and M8 PASS markers. No renderer or gameplay source files were changed. Clone provenance and the clean pre-input status are recorded in `provenance.md`.
