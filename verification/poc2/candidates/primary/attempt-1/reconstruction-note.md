# Primary photo reconstruction — first pass

Status: first complete M3 candidate, awaiting independent structural/runtime validation. This note records the evidence and estimates used for `room_photo_luna.json`; it is not a claim that the file has passed validation or gameplay.

## Inputs and view inventory

The four canonical files depict one room:

| Photo | Visible evidence |
| --- | --- |
| `photo_holder/Sample (1).jpg` | Two large dark-wood-cased windows meet around a green corner; a fabric hammock and black stand sit below them; a two-monitor desk is at the right edge; a floor lamp and low green stool are also visible. |
| `photo_holder/Sample (2).jpg` | The same green room and window from another angle; large dragon/fantasy wall art over the computer desk; two monitors; a wooden rocking chair; floor lamp; wood trim; carpet; green stool. |
| `photo_holder/Sample (3).jpg` | The desk continues along the green wall; a tall warm-wood glass-front display cabinet and wide multi-pane French doors are adjacent; the same low green stool is in the open floor. |
| `photo_holder/Sample (4).jpg` | The French doors and a large window appear on adjacent walls; the hammock is beneath the window; the turquoise ceiling and substantial wood crown are clear. |

The bright shapes outside the windows are not modeled as room contents. Repeated views of the desk, windows, stool, doors, and hammock are treated as the same physical objects, not duplicates.

## Coordinate frame and scale estimate

The candidate uses an approximate 18-by-16-foot rectangular floor (`216 × 192` inches), centered at `[0,0,0]`. `Y=0` is the carpet surface; negative `Z` is the wall behind the desk, and positive `X` points toward the room's right-hand/east side when facing that wall. The 100-inch wall height and opening/furniture sizes are estimates based on ordinary interior double-door, window, and desk proportions. No dimension is measured; those values have low confidence and should not be read as metrology.

In this hypothesis, the desk and dragon artwork are along the north wall, one large window is in that wall near its west end, a second window is in the west wall, and the French doors are in the east wall. The tall display cabinet sits near the desk/door corner. The hammock occupies the west-center floor area, with its rug directly below it. The rocking chair is in front of the desk. This arrangement reconciles the visible relative relationships, but image orientation and exact wall assignments are not marked in the photographs.

## Appearance and representation limits

All four views support deep green walls, a turquoise ceiling, warm wood crown/baseboard and window trim, and a pale taupe carpet. The rendered v2 ceiling is represented as a flat plane and crown as simple rectangular trim. Windows and French doors use generic openings; muntins/transom divisions and the French-door multi-pane pattern are not encoded. The renderer currently has no curved fabric-sling hammock archetype, so the hammock is represented semantically as a hammock and visually by the closest supported soft seating archetype. The rocking-chair rockers, cabinet glass panes/contents, monitor details, and dragon artwork itself are also simplified. These are renderer/contract limitations, not additional photo evidence.

The source images show enough of the shell and large-object relationships for a recognizable first approximation; no additional photograph is requested. The initial generated settlement/spawn/activity points in the JSON are simulation metadata placed in a clear southeast floor area, not claims about physical objects in the photographs. The selected gameplay target is the broad desktop, whose raised surface is directly visible in multiple views.

## Candidate provenance

- Source: direct inspection of the four images listed above while following the packaged `roomscale-room-reconstruction` skill and current v2 contract.
- Candidate: `room_photo_luna.json`, preserved as first pass without a post-generation JSON edit.
- Validation/gameplay: not run by the reconstruction worker; the independent reviewer is validating candidate files sequentially before M4 continues.
