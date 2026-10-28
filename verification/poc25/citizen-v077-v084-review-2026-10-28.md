# Citizen challengers v077–v084 — 2026-10-28

## Disposition

`citizen-v007` remains the stable gameplay incumbent. No candidate in this range passes the strict Clockwork role/readability and controlled-performance gates, and none was promoted. The 50-citizen production bridge, half-inch envelope, five pivots, and 53-bone rig were preserved in the successful candidates.

## Candidate evidence

| Candidate | Result | Evidence and finding |
|---|---|---|
| v077 | Blocked | MPFB2 generation emitted nine high-detail and nine distance meshes, but the candidate scene writer still required 8+8. Preserved as a packaging failure; no visual claim. |
| v078 | Continue | Fixed the writer count and passed Godot validation at 0.26 × 0.50 × 0.21 inches; seven RoomScale production views. The overhead pressure dial is hidden by the head/torso in gameplay views. |
| v079 | Continue | Raised and widened the functional twin pressure pack. Exact bounds, 18 meshes, 42 surfaces, 82,162 triangles, 53 bones and five pivots; seven production captures. Rear/profile kit is stronger, but the 12-inch view still shows a small figure without unmistakable Clockwork role recognition. |
| v080 | Blocked | First feature-preserving LOD attempt retained an output list that declared v079 tooling names while the generator produced v080 files. Art Factory preserved the block; do not overwrite. |
| v081 | Blocked | Repeated the same output-declaration defect because the v079 names were nested in `parameters.outputs`; preserved as a second block. |
| v082 | Continue | Repaired output declarations in a fresh recipe and increased helmet/goggle LOD reduction ratio from 25% to 65%. Godot validates exact bounds, 18 meshes, 42 surfaces, and 90,814 triangles; seven production captures show no clear gameplay-readability improvement. |
| v083 | Continue | One bounded ceiling test retains the helmet/goggle mesh at 100% in LOD1. Godot validates exact bounds, 18 meshes, 42 surfaces, and 98,386 triangles; seven production captures. The 12-inch figure remains small and its Clockwork role is not unmistakable. Stop increasing helmet LOD density. |
| v084 | Continue | Adds a concept-matched swept optical brim with reinforced lip and integrated ventilated ear guards to the full MPFB citizen. Godot validates exact bounds, 18 meshes, 42 surfaces, and 102,146 triangles; seven production captures. Close/profile helmet construction improves, but the 12-inch view still does not make the role unmistakable. |

The v079, v082, v083, and v084 evaluations are registered in the Art Factory with explicit strict-gate answers and all seven capture paths:

- `art/citizen/iterations/v079/evaluation.json`
- `art/citizen/iterations/v082/evaluation.json`
- `art/citizen/iterations/v083/evaluation.json`
- `art/citizen/iterations/v084/evaluation.json`

## Visual review

The actual 12-inch views show a half-inch citizen at roughly 40 pixels tall in a 1280 × 720 capture. v079's raised warm-metal reservoir kit survives on the rear/profile silhouette. v082's 65% and v083's 100% helmet LOD increase mesh density without an obvious role-readability gain at this pixel footprint. v084 then changes the projected helmet construction: its close/profile captures show a broad swept optical brim, reinforced leading edge, vented side guards, attached paired brass-rimmed goggles, layered workwear, and a connected functional pressure pack. The actual 12-inch crowd view still does not make the role unmistakable, so close-view quality alone does not satisfy the gameplay role gate.

The 12-inch captures across independent runs select changing citizen positions/orientations, so they are not a matched A/B comparison. The run receipts report 10–25 FPS while user ComfyUI/LM Studio model workloads were resident. Do not treat these values as isolated candidate performance. Do not close those applications for benchmarking.

The supplemental [v084 controlled-yaw review](citizen-v084-controlled-yaw-review-2026-10-28.md) adds four 12-inch stills from the same production scene. With the selected figure facing four directions and the camera fixed, the helmet, twin lenses, and pack still do not identify the Clockwork role consistently at the gameplay pixel footprint. The normal live gameplay capture remains intact; the supplemental stills are not gameplay or performance evidence.

## Next experiment

Stop adding helmet LOD triangles. The controlled sweep confirms that the remaining readability gap is broad role presentation at miniature scale. Test one fitted, split workshop-apron silhouette over the upper legs with a more legible deep teal cloth response; do not add random gears or change gameplay/camera. Keep v007 incumbent until every visual, gameplay, technical, and controlled-performance gate passes.
