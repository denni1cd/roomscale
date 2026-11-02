# Batch 9 - French-door opening transfer

## Scope and target episode

Batch 9 continued the source-conditioned French-door transfer through the Visual Director and Art Factory. A fresh round-02 image target was approved after the earlier target episode reached its bounded limit. The target uses two columns by four rows of clear glazing per leaf, readable brass butt hinges, warm stained oak, and a garden view. The door brief budget was extended from four to seven so the fresh target could receive three recorded attempts; no attempt counter was reset.

The door mesh remains separate from exterior context. The review used a copy of the reconstructed room with the door asset bound for evidence only. The canonical RoomDefinition and production asset bindings were not changed.

## Attempt and candidate results

| Target attempt | Candidate | Result |
|---|---|---|
| 1 | `room_photo_french_door_production-v006` | Blocked before Blender because the approved executable environment variable was missing. No mesh was produced; the slot remains counted. |
| 2 | `room_photo_french_door_production-v007` | Blocked before Blender because the configured executable path did not resolve. No mesh was produced; the slot remains counted. |
| 3 | `room_photo_french_door_production-v008` | Alternate procedural oak and physically modeled hinge strategy generated successfully, validated in Godot, and rendered. It failed the strict visual gate. |

v008 matches the target's four-row light layout per leaf and exact 66 x 82 x 4 inch envelope. Godot 4.7.2 reports six surfaces, 59,188 triangles, and no technical issues. The close and three-quarter renders show the six hinges as tiny marks, and the oak reads nearly flat. The in-room panes appear pale blue because the review room has a blank blue exterior behind this opening; that image does not prove whether the glazing itself reproduces the target garden view. Do not add foliage to the door mesh.

The comparison is rated `same`: v008 improves the target-matching pane layout and reduces v005's repeated grain, but its material is too flat. Keep v005 as the best current review candidate. v008 remains an evaluated challenger and is not promoted. The round-02 Visual Director episode is closed to backlog after three recorded attempts.

## Whole-scene, runtime, and performance

The standardized room capture shows no integrated improvement because no candidate passed for production. The canonical registry, reconstructed room, RoomDefinition dimensions, collision, navigation, selection, and simulation are unchanged. No runtime code or gameplay presentation was modified.

The capture harness reported 15 FPS for room-scale and settlement-scale views and 35 FPS for the close detail capture at 1280 x 720. These capture readings are not a representative 50-citizen gameplay benchmark; no such benchmark was run in this batch.

## Verification

- Art Factory candidate generation, Godot import/validation, and production-path review captures completed for v008.
- `python scripts/test_art_factory.py` - 24 tests passed, including the blocked-generation status correction.
- `ruff check scripts/art_factory/factory.py scripts/art_factory/generators/production_batch01_blender.py` - passed.
- Python compilation for both edited Python modules - passed.
- Visual inventory refreshed: 21 RoomDefinitions, 318 room object records, 95 asset classes, 15 canonical registry entries, and 91 runtime geometry builder sites.
- No full CI workflow or 50-citizen benchmark was run in this batch.

## Backlog and next priority

Keep the door as review-only. The next priority is the remaining Room A/B Tier 1 furniture fallbacks, selected from inventory evidence. A new furniture pass must use a materially stronger joinery/material workflow; do not repeat the parameter-only geometry tweaks from earlier batches. Desk transfer and room-shell construction remain later priorities.

Cumulative coverage remains 48 Tier 1 asset classes among 95 catalogued classes. Eight Tier 1 classes currently point to accepted canonical registry entries; the rest remain mixed, unregistered, or below target. This batch adds no promotion and does not change those counts.
