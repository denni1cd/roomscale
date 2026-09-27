# Fresh-Luna reconstruction note — attempt 1

## View inventory and coordinate frame

- `photo_holder/Sample (1).jpg`: corner with two high windows, dark green walls, striped freestanding hammock, floor lamp, floor clutter, and the edge of the computer workstation.
- `photo_holder/Sample (2).jpg`: office setup with two monitors and a dark desk, gray rug, brown rocking chair, gray bin, tall lamp, green walls, and a large dragon triptych. One large window is visible on the adjacent wall.
- `photo_holder/Sample (3).jpg`: reverse angle confirms the workstation and rocking chair; also shows a tall glass-front wooden display cabinet, figures on top, and the glass-panel double doors.
- `photo_holder/Sample (4).jpg`: opposite corner confirms the double doors, one large window, green walls, carpet, hammock, and office equipment in the foreground.

Coordinates use X west-to-east and Z north-to-south, with the origin at the room center and floor Y=0. I place the office wall at the south edge, the two window walls on north and west, and the French doors on the south wall. The cutaway exposes the office side. This wall assignment is a consistent approximation from the overlapping views; no dimension is measured.

## Evidence and estimates

Visible anchors are deep green walls, turquoise ceiling, wood crown/base trim, gray carpet, adjacent large windows, a striped hammock/frame, low bright-green saucer chair, dark computer workstation and monitors, gray desk rug, brown rocking chair, floor lamp, tall wood/glass curio, gray storage bin, dragon triptych, and glass-panel double doors. The clear floor area is broad relative to the desk, cabinet, chair, and door widths. The 192 by 168 inch footprint, 96 inch wall height, object sizes, and exact opening offsets are estimates based on familiar furniture and proportions only.

The desk is selected as the broad elevated target because the photos show a substantial work surface and clear floor in front of it. The rectangular hammock proxy simplifies its suspended cloth and frame into one obstacle. Window count and exact location are somewhat uncertain: two adjacent windows are visible across the views, but perspective and bright exterior light obscure the full window runs and spacing. Photos do not show the full fourth wall, and no additional photo is required for a recognizable playable approximation.

The schema/procedural renderer cannot reproduce detailed monitor content, glass reflections, the individual objects inside/on the curio, the hammock's sagging fabric geometry, or the outdoor view. Wall color is represented as solid green; the observed turquoise ceiling is not represented by the current room-shell contract.

Validation attempt: `VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fresh-luna/attempt_1/fresh_luna_room.json -LogPath verification/poc2/fresh-luna/attempt_1/validator.log`.
## Validation record

- Attempt: 1 (original candidate, unchanged after authoring)
- Validator: repository `VALIDATE_ROOM_SCALE.ps1`; Godot 4.7.2.stable.official.ed1daf0bf
- Command: `VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fresh-luna/attempt_1/fresh_luna_room.json -LogPath verification/poc2/fresh-luna/attempt_1/validator.log`
- Result: `ROOMSCALE_VALIDATION_PASS`; structural and runtime-navigation validation both passed. The validator found four reachable approaches and a valid construction site at `[30, 0, 58]`.
- Candidate: `verification/poc2/fresh-luna/attempt_1/fresh_luna_room.json`
- Complete diagnostics: `verification/poc2/fresh-luna/attempt_1/validator.log`
