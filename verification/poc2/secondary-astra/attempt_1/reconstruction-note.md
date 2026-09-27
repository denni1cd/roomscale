# Independent Astra reconstruction — attempt 1

Candidate: `verification/poc2/secondary-astra/attempt_1/astra_room.json`.

## Evidence and orientation

Only the current portable reconstruction skill, its three linked references, and the four original JPEG photographs were consulted. No other room candidates, verification results, game source, or project-plan content were used.

The floor origin is the room center; +Y is up. North (negative Z) is the hammock window wall, east (+X) is the second window and floor-lamp wall, south (+Z) is the desk/dragon-art wall, and west (-X) is the French-door wall. These are convenient model directions, not geographic bearings.

| Image | Visible evidence used |
| --- | --- |
| Sample (1) | The two adjacent window walls, hammock and stand, map near the window corner, floor lamp, dark desk and two monitors, pale carpet, low green seat, green walls, teal ceiling, and wood trim. |
| Sample (2) | Desk positioned away from its back wall with office chair behind it; wood rocking chair and computer tower toward the second window; broad dragon artwork; equipment and gray bin beside the desk. |
| Sample (3) | Same desk and chairs; tall wood/glass cabinet beside the French doors; boxed collectibles on the cabinet; gray bin; center-floor green seat. |
| Sample (4) | French-door wall adjoins the hammock wall; striped hammock spans that window, with a pale plush pile toward the door corner and a bright blanket on its dark mat. The teal ceiling and wood crown trim are clearly visible. |

The two monitors, rocking chair, cabinet, and doors are each represented once across views. The purple figures beyond the windows are outdoors and are excluded.

## Estimates and simplifications

The room is estimated at 156 by 144 inches with a 108-inch ceiling, using familiar door, desk, and cabinet proportions. No measured scale was supplied. Window dimensions, furniture footprints, clearances, and all heights are approximate; the door leaves are represented by one 66-inch opening. The cabinet is placed against the door wall beside its southern end, based on its front alignment with the doors in image 3. Exact wall lengths and the under-desk space are partly occluded.

The broad desk top is the selected elevated target. Its surface includes simplified monitor props; its anchor is on the visibly more open front part of the tabletop. Citizen spawn, depot, and settlement points occupy the open floor between the door wall and center seat, with a work area toward the desk. These are simulation metadata rather than photographed furnishings.

The procedural archetypes cannot reproduce the curved suspended hammock, thin stand tubing, rocking runners, concave green seat, lamp stem/shade profile, cabinet glazing, French-door glass grids, window transoms, dragon silhouettes, art images, or blanket folds. The hammock uses a bed-shaped bounding approximation, the seat and lamp use cylinders, and artwork/collectibles use colored blocks. The floor lamp's cylinder is especially coarse. Those limitations should be considered during visual review. Small cables, keyboards, outlets, trim profiles, and clutter are omitted or grouped.

No photo gap blocks a coherent first approximation. A measured wall length and an unobstructed view from the French doors toward the desk would refine scale and desk/rocker spacing, but are optional.

## Validation status

**Unvalidated candidate.** Structural validation and gameplay were explicitly deferred because another regression is running. Neither validator nor game was started, and no pass is claimed. The next authorized step is:

`./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/secondary-astra/attempt_1/astra_room.json -LogPath verification/poc2/secondary-astra/attempt_1/validator.log`

Attempt number: 1. Validator version/result/evidence: not yet available. Preserve this candidate unchanged when collecting diagnostics; repairs should be written as subsequent attempts.
