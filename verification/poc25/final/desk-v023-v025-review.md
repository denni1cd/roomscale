# Desk Challenger Review: V023–V025

## Decision

Keep `desk-v007` as the current best-so-far incumbent. Do not promote V023, V024, or V025. The source-measured Blender assembly is a credible third production strategy, but its production renders still fail the unchanged realism, close-inspection, craftsmanship, and source-character gates.

## Method and evidence

V023 tested source-measured, component-authored Blender geometry with UV-mapped PBR materials as a materially different approach from learned image-to-mesh generation. Its generator builds 38 named parts before joining them into one mesh, including a smoked-glass top, telescoping columns, T-feet, support rails, cable tray, controls, and hardware.

Godot 4.7.2 imported V023 successfully: one mesh, five material surfaces, 17,368 triangles, and no import issues. All six standardized RoomScale production captures were produced. Visual inspection revealed a coordinate-basis defect: the top exported vertically, so the render read as a divider. V023 fails all four visual acceptance questions. Preserve it as a failed challenger.

V024 added the missing Y-up to Blender Z-up transform. Godot then measured a 66 × 29.605 × 30-inch asset with no import issues; the floor bound remained Y=0.395 inches. All six equivalent RoomScale captures showed a recognizable desk, but close inspection exposed broad boxed supports and feet, weakly legible hardware and joins, and a nearly uniform dark top. The result reads as simplified/blocky game geometry instead of realistic manufactured furniture.

V025 refined the top chamfer and added material-specific albedo, roughness, and tangent-space normal maps. Godot imported one mesh with five material surfaces and 15,800 triangles. The same six RoomScale production views were captured. The frame normal response appears mottled rather than like coherent powder-coated steel; broad glass reflections and manufactured details remain weak, and Godot still measures the 0.395-inch floor gap. V025 is not a pass.

## Repaired visual gate — V025

| Required question | Answer | Evidence |
|---|---|---|
| Would a neutral viewer describe it as realistic furniture rather than low-poly/stylized game geometry? | **No** | Three-quarter and detail views show a dark slab on broad box columns and rectangular feet. Style flags: blocky, materially flat, primitive, simplified programmer art, and substantially stylized. |
| Does it hold up at close inspection without obvious primitive construction? | **No** | The detail view exposes generic column transitions, limited visible hardware, a featureless top, and patchy metal response. |
| Are edge treatment, joins, thickness, hardware, material response, surface variation, and manufacturing detail believable? | **No** | Edge treatment: yes; thickness: yes; joins: no; hardware: no; material response: no; surface variation: no; manufacturing detail: no. |
| When a photograph exists, does the render approach the photographed object's visual character rather than only its bounding-box silhouette? | **No** | The render matches the broad desk envelope and dark palette, but not the source's broad glass/window reflections, detailed supports, feet, and hardware character. |

The evidence and explicit gate responses are recorded in `art/desk/iterations/v023/evaluation.json`, `art/desk/iterations/v024/evaluation.json`, and `art/desk/iterations/v025/evaluation.json`. No incumbent promotion occurred.

## Production-path captures

V023: `art/desk/iterations/v023/render-runs/run-001/`

V024: `art/desk/iterations/v024/render-runs/run-001/`

V025: `art/desk/iterations/v025/render-runs/run-001/`

V025's harness captured 30 FPS in the close-view frame with 235 draw calls and 107,574 primitives. This is a standardized capture value, not a warmed representative performance benchmark.

## Next work

The next desk cycle should address the remaining construction and material causes directly: replace the primitive-looking profiles with higher-fidelity manufactured forms, establish floor contact at Y=0, and make the local reflection capture and material response coherent with the actual room window. Re-render through the same RoomScale path and preserve `desk-v007` unless every gate passes.

Citizen remains unresolved. Grapple's repaired-gate pass does not satisfy the three-pilot gate while Desk and Citizen still fail. Broad asset migration remains blocked.
