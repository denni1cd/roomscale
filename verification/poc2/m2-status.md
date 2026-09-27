# Milestone 2 — Visual Contract Extension

Status: **PASS**

The shared RoomDefinition contract and production renderer now support generic version 2 visual appearance and room-shell geometry while continuing to load version 1 Room A and Room B with their original fallback visuals. No canonical photo-derived room data was created during this milestone.

## Generalized implementation

- `scripts/room_definition.gd` accepts schema versions 1 and 2, validates malformed nested values before casts, validates camera defaults/overrides, validates exact lowercase wall-side and opening-kind values, checks rotated object bounds, and accepts safe project-local candidate JSON files as well as IDs.
- Version 2 `room_shell` supports per-wall/floor/ceiling appearance, baseboards, wall-local openings, crown molding, and cutaway selection. The renderer creates wall segments around real openings; door, window, and clear openings are generic renderer features. Baseboards leave a gap where an opening begins below the trim height. An explicitly present empty `ceiling_appearance` uses the documented default material.
- Optional crown molding is generated as visual-only trim along each wall, continues into corners, leaves the crown band clear where an opening reaches it, and projects 0.75 inches past the room-facing wall plane while remaining flush at the exterior plane. It does not add collision geometry or affect navigation.
- Generic object `appearance` supports renderer archetypes, colors, materials, and transparency. Unknown archetypes use a generic simple shape. Version 1 continues to use the existing semantic-kind renderer and legacy color defaults.
- Rotated footprint padding, exploration candidate generation, elevated collision surfaces, and route checks use a consistent local-object frame and the configured floor elevation. Optional object labels fall back to the object ID. Elevated nonblocking visual objects are allowed inside the room's vertical bounds; floor navigation blockers stay based on the floor.
- `RUN_ROOM_SCALE.ps1` and `TEST_ROOM_SCALE.ps1 -Room` accept safe room IDs or project-local candidate paths. The smoke route assertion starts from the derived floor construction site, and height-based capture thresholds are relative to floor-to-target elevation.

## Passing verification

| Check | Evidence | Result |
| --- | --- | --- |
| Fast deterministic validator/navigation/renderer regression | `m2-fast-crown-ceiling-final.log` | PASS: Room A/B legacy validation, schema v2 fixture, 26 malformed cases, candidate-file path guard, rotated bounds/padding/approaches, elevated floor/collider, wall openings/baseboard clearance, default ceiling appearance, crown extrusion on all four wall orientations with no shell collision objects, generic appearance, runtime navigation, and bounded task history. |
| Full production Room A after ceiling/crown renderer changes | `m2-room-a-crown-ceiling-final.log` | PASS: M2, M3, M4, M5, M6, and M8 markers. |
| Full production Room B after ceiling/crown renderer changes | `m2-room-b-crown-ceiling-final.log` | PASS: M2, M3, M4, M5, M6, and M8 markers. |
| Full production v2 fixture at floor Y=5 after ceiling/crown renderer changes | `m2-candidate-crown-ceiling-final.log` | PASS: M2, M3, M4, M5, M6, and M8 markers; verifies nonzero floor-relative movement/captures, ceiling/crown rendering, and arbitrary project-local candidate selection. |
| Standalone valid v2 candidate validator | `m2-validator-crown-ceiling.log` | PASS: structural and runtime navigation; 11 generated blockers, 2 reachable approaches, construction site `[6,5,-68]`. |
| Standalone malformed v2 candidate validator | `m2-validator-crown-ceiling-invalid.log` | Expected failure: nonzero exit with one actionable lowercase wall-side diagnostic. |

Commands used:

```powershell
.\TEST_ROOM_SCALE_FAST.ps1 -TimeoutSeconds 90 -LogPath verification\poc2\m2-fast-crown-ceiling-final.log
.\TEST_ROOM_SCALE.ps1 -Room room_a -TimeoutSeconds 360 -LogPath verification\poc2\m2-room-a-crown-ceiling-final.log
.\TEST_ROOM_SCALE.ps1 -Room room_b -TimeoutSeconds 360 -LogPath verification\poc2\m2-room-b-crown-ceiling-final.log
.\TEST_ROOM_SCALE.ps1 -Room verification\poc2\fixtures\m2_fixture.json -TimeoutSeconds 360 -LogPath verification\poc2\m2-candidate-crown-ceiling-final.log
.\VALIDATE_ROOM_SCALE.ps1 -Room verification\poc2\fixtures\m2_fixture.json -LogPath verification\poc2\m2-validator-crown-ceiling.log
.\VALIDATE_ROOM_SCALE.ps1 -Room verification\poc2\fixtures\m2_invalid.json -LogPath verification\poc2\m2-validator-crown-ceiling-invalid.log
python C:\Users\Zero\.codex\skills\.system\skill-creator\scripts\quick_validate.py skills\roomscale-room-reconstruction
```

The passing arbitrary-file validation result reports structural and runtime-navigation PASS, 11 generated blockers, two reachable approaches, and the derived site `[6,5,-68]` in `m2-validator-crown-ceiling.log`. The malformed candidate result is retained in `m2-validator-crown-ceiling-invalid.log`; its only diagnostic is `room_shell wall south-wall side must be lowercase north, south, east, or west`, and the command exits nonzero. Both candidate file paths are project-local and each filename matches its JSON `id`. The packaged skill passes `quick_validate.py` after its v2 contract reference was refreshed.

## Triage notes

- Early fast-test iterations caught JSON integer values arriving as floating-point variants, too few exploration candidates around a rotated footprint, and a brittle test lookup for the production target collider. These were corrected and the final fast log above passes. The fast wrapper reused `m2-fast.log`, so the raw early stdout was not retained separately; this chronology records the non-passing iterations without reconstructing their output.
- The preserved failed candidate full-run log `m2-candidate-full.log` records `session infrastructure failed to preserve a usable traversal route` at the final harness assertion. M6 can leave the named citizen on the elevated surface, so it was an invalid floor-region start. The harness now tests the floor-to-target route from the derived floor construction site. `m2-candidate-full-retry.log` is the corrected passing run.
- A review caught uppercase wall/opening values that validation previously accepted but the renderer interpreted differently. The contract now rejects non-lowercase values with explicit diagnostics, covered in the final fast run.
- Photo review identified the turquoise ceiling and substantial warm-wood crown molding in all four views. The optional generic ceiling/crown extension was implemented and reviewed separately before canonical candidate generation.
- Review of the first extension caught a recessed crown box and an empty-but-present ceiling appearance that did not render. Crown geometry now projects 0.75 inches past every interior wall face while staying flush outside; an empty appearance uses defaults. A first fast assertion also produced a GDScript static-type parse error, retained at `m2-fast-crown-ceiling-parse-fail.log`; after correcting the assertion, the final fast suite and fresh full Room A, Room B, and elevated-floor fixture regressions pass.

## Scope boundary

This milestone proves the generic rendering/schema extension against a deterministic synthetic v2 fixture and legacy regressions. The first photo-derived candidate is a separate M3 artifact; this milestone's fixture is not used as canonical room input. AI validation/repair, visual review, and fresh-context/second-model tests remain later milestones.
