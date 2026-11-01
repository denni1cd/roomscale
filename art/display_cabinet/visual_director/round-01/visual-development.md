# Display cabinet Visual Director run

**Selection:** Tier 1 room furniture, instantiated in `room_photo_luna`; 33 × 76 × 18 inches. The accepted production incumbent is `display_cabinet-v002`. Its Godot render has a bright, uniformly lit interior and less convincing wood/glass depth. The source photo shows only a cropped, ambiguous timber object at the far-right edge, so its glazing and joinery are not treated as photo evidence.

**VisualBrief:** [visual-brief.json](../visual-brief.json) · **Scale schematic:** [scale-guide.svg](../reference-pack/scale-guide.svg)

## Initial directions

The [three-column direction sheet](candidates/directions-r01.png) varies the crown/plinth and wood character while keeping the existing narrow double-glass-door cabinet identity. Score order is left / center / right (A / B / C).

| Category | A | B | C | Pixel evidence |
| --- | ---: | ---: | ---: | --- |
| Semantic recognizability | 5 | 5 | 5 | Each reads as a tall glass-front display cabinet. |
| Silhouette | 4 | 5 | 5 | All preserve a tall narrow case; B/C ground the case more clearly with their crown and plinth. |
| Proportions | 4 | 4 | 4 | The brief supplies the 33 × 76 × 18-inch envelope; the images do not encode exact measurements. |
| Construction believability | 4 | 5 | 4 | B has a clear, manufacturable crown, door frame, hinge and plinth; C adds more trim. |
| Geometric/detail richness | 4 | 4 | 5 | C has extra bead detail; B retains enough useful joinery without clutter. |
| Material realism | 4 | 5 | 4 | B has the clearest walnut grain and controlled glazing. |
| Surface variation | 4 | 5 | 4 | B separates wood, clear glass and brass without bright interior lighting. |
| Art-direction fit | 5 | 5 | 4 | A/B fit restrained Human Room cabinetry; C is more decorative than needed. |
| Scale cues | 2 | 2 | 2 | None of the generated panels contains an accurate citizen or dimension card. |
| Gameplay-distance readability | 4 | 4 | 4 | All remain legible as narrow tall furniture; fine hardware is close-view only. |
| Source resemblance | N/A | N/A | N/A | The cropped source only confirms nearby timber context; it cannot establish the cabinet front or construction. |
| 3D-reference transferability | 4 | 5 | 4 | B communicates two doors, side depth, shelf spacing, hardware, crown and base most clearly. |

| Direction | What works | What is wrong | Why | Next action |
| --- | --- | --- | --- | --- |
| A | Slim frame and restrained crown. | Case reads slightly top-heavy and grain/material separation is weaker. | A modeler receives less guidance for a convincing finished base and visible depth. | Keep as alternate; do not choose it over B. |
| B | Balanced walnut case, central meeting stile, paired knobs, hinges, clear doors, three shelves and a finished plinth. | Concept alone cannot establish exact inches or separate room collectibles. | It is the clearest manufacturable direction and avoids unsupported ornament. | Select B; create an exact scale card and retain collectibles as separate room assets. |
| C | Strong plinth and crisp framed front. | Dense bead detail is more decorative and may become noise at RoomScale distance. | Small trim detail would not improve the cabinet's room-scale read. | Preserve as rejected alternate; do not carry its extra beadwork into 3D. |

## Selected target

[Approved target](approved-target-r01.png) isolates the center direction as one complete cabinet. It keeps the paired glazed doors and three empty shelves, uses dark walnut and a restrained stepped crown/plinth, and leaves contents out of the mesh.

| Category | Score | Pixel evidence |
| --- | ---: | --- |
| Semantic recognizability | 5 | Immediately reads as a glass-door display cabinet. |
| Silhouette | 5 | Tall, narrow, complete case with visible depth. |
| Proportions | 4 | Plausible for the supplied envelope; exact scale remains in the ArtBrief and SVG. |
| Construction believability | 5 | Doors, hinges, shelf supports, crown and plinth form a coherent assembly. |
| Geometric/detail richness | 4 | Rails, central stile, shelves and hinge positions provide useful medium-scale cues. |
| Material realism | 5 | Walnut grain, clear glazing and brass hardware are distinct. |
| Surface variation | 5 | Wood grain stays broad and controlled; glass remains quiet. |
| Art-direction fit | 5 | Believable restrained Human Room cabinetry. |
| Scale cues | 4 | Paired with the exact dimension-derived SVG schematic. |
| Gameplay-distance readability | 4 | Main case and paired doors remain visually dominant. |
| Source resemblance | N/A | The visible source fragment is insufficient to score cabinet construction. |
| 3D-reference transferability | 5 | Major case, doors, shelves, hardware and material assignments are explicit. |

- **Professional visual read:** Yes; no obvious malformed join or AI artifact is visible.
- **Structural coherence:** Yes; both doors are hinged to the case and shelves are supported.
- **Detail hierarchy:** Yes; door rails and shelf edges dominate over small hardware.
- **3D transferability:** Yes; 3D dimensions and gameplay ownership remain in the brief.
- **Image-target decision:** PASS for 3D handoff. This is not a production asset pass.

## Godot production comparison

**Incumbent render:** [`display_cabinet-v002` three-quarter](../../iterations/v002/render-runs/run-001/asset-three-quarter.png) · **Approved target:** [walnut cabinet](approved-target-r01.png) · **Production render:** [`display_cabinet-v003` three-quarter](../../iterations/v003/render-runs/run-001/asset-three-quarter.png) · [detail](../../iterations/v003/render-runs/run-001/asset-detail.png) · [room-scale](../../iterations/v003/render-runs/run-001/room-scale.png).

v003 transfers the target's darker walnut, paired full-height glass leaves, three visible shelves, brass knobs and hinges, and restrained stepped crown. The v002 render has a much brighter interior and heavier front rails. In the normal green-walled room capture, the target's white studio background is absent, so the unlit glass reads darker than the concept; the shelves remain visible and separate room collectibles stay outside the mesh. This is an expected lighting/context difference, not a reason to add emissive interior lighting.

Godot 4.7.2 Compatibility validation passes at 33 × 76 × 18.21 inches (the validator accepts the 0.21-inch depth tolerance); the RoomDefinition and collectible placements are unchanged. Evaluation [v003](../../iterations/v003/evaluation.json) compares the matched production renders and promotes v003. The registry hash verifies, and `approved_visual_target`, `best_3d_candidate`, and `production_asset` now point to their respective image and v003 asset records.
