# Clockwork workshop Visual Director run

**Selection:** Tier 1 Clockwork settlement structure, 26 × 20 × 20 inches, faction-defining and below target in the current production batch. The accepted baseline is `settlement_workshop-v004`; v006's roof-heavy challenger hides too much machinery in the production view.

**VisualBrief:** [visual-brief.json](../visual-brief.json) · **Scale schematic:** [scale-guide.svg](../reference-pack/scale-guide.svg)

## Initial directions

The [three-column direction sheet](candidates/directions-r01.png) explores three roof solutions while preserving the same open-front machinery set. A/B/C denote left/center/right.

| Category | A | B | C | Pixel evidence |
| --- | ---: | ---: | ---: | --- |
| Semantic recognizability | 5 | 5 | 5 | Boiler, flywheel and bench make each read as a workshop. |
| Silhouette | 4 | 4 | 5 | C's raised ridge canopy is distinct while keeping open bays. |
| Proportions | 4 | 4 | 4 | Compact miniature proportions fit the brief but are not metrically encoded in the image. |
| Construction believability | 4 | 3 | 4 | A/C show understandable posts and braces; B's split roof joins are less clearly supported. |
| Geometric/detail richness | 5 | 5 | 5 | Boilers, pipes, gauges, flywheels, tool rail and bench are present. |
| Material realism | 5 | 5 | 5 | Oak, stone, iron and copper are separated with convincing response. |
| Surface variation | 5 | 5 | 5 | Boards, seams and metal details remain controlled. |
| Art-direction fit | 5 | 5 | 5 | All fit Clockwork miniature industry. |
| Scale cues | 2 | 2 | 2 | No accurately dimensioned citizen is in the generated concepts. |
| Gameplay-distance readability | 4 | 4 | 5 | C leaves the boiler, gauge, wheel and workbench most open to the front. |
| Source resemblance | N/A | N/A | N/A | This fictional asset has no source photograph. |
| 3D-reference transferability | 4 | 3 | 5 | C defines a coherent raised canopy and usable front opening; B's split roof is hard to join. |

| Direction | What works | What is wrong | Why | Next action |
| --- | --- | --- | --- | --- |
| A | Simple low gable with machinery visible. | Roof and rear wall visually dominate the boiler; tool details compete. | It risks repeating the current roof-heavy legibility problem. | Keep as rejected alternate. |
| B | Two distinct roof wings expose the stack. | Split-wing junctions are ambiguous and may not be weather-tight or supported. | A 3D worker cannot infer a robust roof join confidently. | Do not use its roof structure. |
| C | Raised ridge canopy, open front, stable trusses, and the full machine/workbench set read together. | The canopy must remain inside the 20-inch envelope and not grow in the 3D version. | It best solves the prior roof/machinery occlusion while preserving Clockwork identity. | Select C and make the roof height/envelope explicit in the brief. |

## Selected target

[Approved target](approved-target-r01.png) uses direction C: raised ridge canopy on visible trusses, open front and side bays, an exposed boiler/gauge/flywheel, and an equipped workbench. The 26 × 20 × 20-inch envelope remains a hard brief constraint. It adds no gameplay or construction state.

| Category | Score | Pixel evidence |
| --- | ---: | --- |
| Semantic recognizability | 5 | Boiler, flywheel, pipework and workbench immediately read as workshop machinery. |
| Silhouette | 5 | Compact plinth, raised canopy and open bays form a distinctive structure. |
| Proportions | 4 | Major masses fit the stated miniature scale; exact envelope is in the brief/SVG. |
| Construction believability | 4 | Trusses support the raised roof and the front remains open; validate hidden rear joinery in 3D. |
| Geometric/detail richness | 5 | Machinery, board walls, roof seams and work tools provide coherent medium-scale forms. |
| Material realism | 5 | Iron, copper/brass, stone and wood are distinct. |
| Surface variation | 5 | Grain, plinth seams and metal response are controlled. |
| Art-direction fit | 5 | Strong Clockwork miniature industrial identity. |
| Scale cues | 4 | Paired with a dimension-derived 0.5-inch citizen schematic. |
| Gameplay-distance readability | 5 | Stack, boiler, gauge, wheel and bench stay visible through the open face. |
| Source resemblance | N/A | No photographed source applies. |
| 3D-reference transferability | 5 | Roof supports, open face, component hierarchy and material assignments are legible. |

- **Professional visual read:** Yes; no obvious malformed parts or nonsensical joins in the hero image.
- **Structural coherence:** Yes in visible views; canopy bears on trusses/posts and the machinery sits on the plinth.
- **Detail hierarchy:** Yes; boiler, flywheel and bench dominate over smaller tools.
- **3D transferability:** Yes; the target and exact scale schematic describe shape and envelope separately.
- **Image-target decision:** PASS for 3D handoff; Godot production still decides asset acceptance.

## Godot production comparison

**Accepted incumbent:** [`settlement_workshop-v004` three-quarter](../../iterations/v004/render-runs/run-001/asset-three-quarter.png) · **Prior failed challenger:** [`v006` three-quarter](../../iterations/v006/render-runs/run-001/asset-three-quarter.png) · **Approved target:** [raised-canopy workshop](approved-target-r01.png) · **New candidate:** [`v007` three-quarter](../../iterations/v007/render-runs/run-001/asset-three-quarter.png) · [detail](../../iterations/v007/render-runs/run-001/asset-detail.png) · [settlement-scale](../../iterations/v007/render-runs/run-001/settlement-scale.png).

v007 is a real Art Factory Blender candidate, and Godot 4.7.2 import, dimensions, and production capture all pass technically. It removes the roof mass that hides the boiler in v006 and keeps the boiler, flywheel, flue, and bench visible. The visual transfer diagnosis is geometry loss and proportion drift: the selected target's broad, supported ridge canopy becomes an undersized one-sided awning, and the close view does not show a continuous truss-to-post load path. Against accepted v004, that weakens the roof silhouette and construction read, while v004 already keeps a central machine opening.

Evaluation [v007](../../iterations/v007/evaluation.json) therefore keeps v004 as both `best_3d_candidate` and `production_asset`. The case is explicitly backlogged with the unresolved target-transfer reason; the approved image is preserved. A later attempt should model a continuous supported ridge canopy with an open machine lane, without moving RoomDefinition landmarks or machinery gameplay positions.
