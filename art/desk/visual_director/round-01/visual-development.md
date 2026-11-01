# RoomScale Visual Director — desk visual-development record

**Batch:** production-deployment next high-impact replacement work  
**Asset:** `desk` / `computer-desk`  
**Status:** image target passed for 3D handoff; v059/v060 remain historical continues, while v061 was rejected after the material route plateaued; no new 3D candidate is approved  
**Incumbent:** `desk-v007` remains the current production asset and stable registry entry.  
**Authority:** RoomDefinition `rooms/room_photo_luna.json` remains unchanged.

## Why this asset

The deployment backlog names room foundation and large human-room furniture as the top gap. The inventory marks the desk Tier 1 and its strict production result as `fail`. Sample (2) visibly contains the dark glass standing desk, although monitors obscure part of its top and underframe. `rooms/room_photo_luna.json` instantiates a 66 × 30 × 30-inch desk at `(30, 0, 47)`.

The same image set does **not** show a sofa or fireplace, and the current room definition does not instantiate them. The Visual Director therefore starts with the photographed, instantiated desk rather than treating those backlog labels as source-observed furniture. This is new production art work; it does not modify POC 2.5 acceptance evidence or the existing Batch 0 inventory/material work.

## VisualBrief

Saved at [visual-brief.json](../visual-brief.json). In short: preserve the dark smoked-glass top, two distinct graphite lift columns and T-feet at the exact 66 × 30 × 30-inch envelope. The source does not expose the full underframe, so its rail/joint arrangement is explicitly treated as an assumption. Monitors, chair, keyboard, cables, room shell, surface anchor, collision, and navigation remain separate/authoritative.

## Initial concept exploration

All three candidates used the source photo and a neutral product-study camera. The photograph constrains the main silhouette; candidate differences therefore explore hidden support construction rather than unrelated styles. B is recorded as too close to A to count as a strong independent direction.

| Category | A | B | C | Pixel evidence |
| --- | ---: | ---: | ---: | --- |
| Semantic recognizability | 5 | 5 | 5 | Every image reads immediately as a standing computer desk. |
| Silhouette | 5 | 5 | 5 | Wide thin top, open knee space, paired columns, and T-feet remain clear. |
| Proportions | 4 | 4 | 4 | The known envelope is plausible, but the image itself does not prove exact 66 × 30 × 30-inch proportions. |
| Construction believability | 4 | 4 | 5 | C exposes the rail and column plates most clearly; A/B leave the load path less explicit. |
| Geometric/detail richness | 4 | 4 | 4 | Two-stage columns, mounts, edge, and feet give useful medium-scale information. |
| Material realism | 5 | 5 | 4 | A/B separate smoked glass and metal cleanly; C's heavier apron obscures that hierarchy. |
| Surface variation | 4 | 4 | 3 | A/B have controlled variation; C adds four distracting top pucks and more under-top mass. |
| Art-direction fit | 5 | 5 | 4 | A/B fit restrained contemporary domestic furniture; C's hardware treatment is more assertive than the photo supports. |
| Scale cues | 2 | 2 | 2 | None of the hero images includes a citizen or dimensioned scale view, so the pixels alone do not establish 1:60. |
| Gameplay-distance readability | 4 | 4 | 4 | The major desk identity survives the full-object view, but small details are not gameplay-scale evidence. |
| Source resemblance | 5 | 4 | 4 | A best matches the visible glass top and standing frame; B/C add more unsupported visible construction. |
| 3D-reference transferability | 4 | 4 | 5 | C's underside is easiest to translate; A is the clearest overall source-faithful target. |

| Candidate | What works | What is wrong | Why it matters | Exact next action |
| --- | --- | --- | --- | --- |
| [A](candidates/candidate-a.png) | Smoked-glass plane, paired square columns, T-feet, and a polished glass/steel split; closest to the visible source character. | Four small surface pucks look unexplained; the rail and mounts need a clearer load path; no image scale cue. | The pucks invent surface hardware and the partly hidden mounts make the support connection uncertain. | Use as image incumbent; remove only the pucks and retain a slim rail and mounts beneath the glass. Add a dimension-derived scale schematic separately. |
| [B](candidates/candidate-b.png) | Bolted clamp plates and two-stage column seams are readable. | Near-duplicate silhouette/material direction to A; top pucks and underframe ambiguity remain. | This direction adds little new decision information, so it is weak independent exploration. | Preserve as equivalent/rejected provenance; do not average with A or run another whole-object prompt in this direction. |
| [C](candidates/candidate-c.png) | Strongest visible underside connection; rail, column plates, and feet are easy to infer. | Prominent apron and four pucks add unsupported mass and surface clutter. | Better construction visibility comes at the cost of matching the photographed thin tabletop and restrained frame. | Run one targeted edit to remove top pucks, reduce apron thickness, and move mounting plates below the glass; compare directly with A. |

Initial pixel inspection: all images read as polished furniture concept references, and their large pieces connect plausibly. A is the best source-faithful starting point; C is the strongest construction challenger. The exploration exposed that source-constrained prompt variants can become too similar, so the next photo-based asset should vary camera/component evidence rather than issue several near-identical whole-object prompts.

## Targeted edits and incumbent history

### C challenger edit R01

- **Remain unchanged:** C's dimensions, glass slab, paired columns, T-feet, camera, palette, framing, and neutral studio ground.
- **Change:** remove the raised circular top hardware; reduce the apron and make mounting plates sit below the glass.
- **Why:** remove invented surface clutter and keep C's more visible load path.
- **Pixel result:** [challenger C edit R01](challenger-c-edit-r01.png) removes the large pucks, but dark mount shapes still read ambiguously through the glass. It is not clearly better than source-faithful A; A remains the incumbent. C is retained as provenance.

### Incumbent A edit R01

- **Remain unchanged:** A's wide thin top, paired square columns, T-feet, envelope, camera, framing, studio ground, and graphite palette.
- **Change:** remove its four unexplained pucks; keep all mounting plates and the slim support rail below the glass edge; maintain one continuous edge highlight.
- **Why:** clarify the glass plane and the connection/load path without changing the photographed desk's silhouette.
- **Pixel result:** [incumbent A edit R01](incumbent-edit-r01.png) has a smooth uninterrupted top, a clean thin green-black edge, paired connected columns, and no raised surface fittings. Compared with A it is **clearly better** on construction clarity and source resemblance without losing silhouette or material read. It becomes the best image target.

### Scale-view attempts

- The first [profile scale study](scale-profile-attempt-failed.png) made the citizen about 40 px tall against a roughly 750 px desk (about 1:19 instead of 1:60) and collapsed the paired supports in the view. Reject it.
- The second [three-quarter scale study](scale-three-quarter-attempt-failed.png) still made the figure about 46 px tall against an approximately 860 px desk (about 1:19). The prompt's stated 12 px target was ignored. Reject it; generator text/prompt intent does not override the pixels.
- **Method change:** create a dimension-derived vector schematic rather than treating a generated person as accurate scale evidence. The [scale guide](../reference-pack/scale-guide.svg) draws a 0.5-inch citizen exactly 1/60 of the 30-inch desk height and is labeled as schematic. The failed generated studies remain preserved here.

## Approved concept rubric

Scores describe the approved hero image plus its exact dimension-derived scale schematic. The generated scale views do not contribute to the scores.

| Category | Score | Pixel evidence |
| --- | ---: | --- |
| Semantic recognizability | 5 | Broad work surface, two lift columns, and T-feet immediately read as a standing desk. |
| Silhouette | 5 | One thin wide plane, open knee area, paired vertical supports, perpendicular low feet. |
| Proportions | 4 | Hero proportions plausibly match the 66 × 30 × 30-inch brief; hidden feet/rail details remain assumptions. |
| Construction believability | 4 | Paired posts meet a slim under-glass support; feet connect to posts; unseen cross-frame remains a modeling decision to validate. |
| Geometric/detail richness | 4 | Two-stage columns, glass edge, slim rail, clamp interfaces, and levelers provide useful medium-scale forms. |
| Material realism | 5 | Smoky transparent glass has edge/reflection cues distinct from powder-coated metal and rubber. |
| Surface variation | 4 | Glass, frame, pads, and fittings remain distinct without noisy decoration. |
| Art-direction fit | 5 | Restrained contemporary domestic-office furniture fits Human Room. |
| Scale cues | 4 | The approved target pack includes a dimension-derived 1:60 schematic; the AI scale views were rejected. |
| Gameplay-distance readability | 4 | Paired supports and tabletop remain readable in a full-object three-quarter frame; verify in Godot room render. |
| Source resemblance | 4 | Dark glass and paired standing frame match Sample (2); details hidden behind monitors are not asserted as source evidence. |
| 3D-reference transferability | 5 | Major mesh groups, proportions, and material assignments are legible; exact 66 × 30 × 30-inch bounds remain in the brief. |

- **Professional visual read:** Yes. The hero reads as a polished product concept; no obvious AI artifact or nonsensical detail remains in the selected edit.
- **Structural coherence:** Yes in the visible view. The rail and two posts meet, and the posts connect to stable T-feet. Validate hidden joints in 3D.
- **Detail hierarchy:** Yes. Glass edge, columns, rail, feet, and small levelers read at medium scale; no top-surface noise.
- **3D transferability:** Yes. The generated target is an appearance guide; the scale SVG and VisualBrief supply exact bounds and warn that underframe dimensions are estimated.
- **Pass/plateau:** **Image-target PASS for 3D handoff.** All applicable scores meet the visual target threshold. This is not an Art Factory asset pass; Godot rendering and concept-to-3D comparison are still required.

## Reference pack and next production step

- Hero visual target: `incumbent-edit-r01.png`.
- Accurate scale reference: `../reference-pack/scale-guide.svg`.
- A coherent generated side/profile sheet was not accepted; do not use either failed scale attempt for modeling evidence.
- The 3D follow-through and disposition are recorded below; a concept-target pass did not approve a production asset.

## 3D production comparison and disposition

Three component-authored Blender challengers preserved the same 22-mesh geometry, 8,712 triangles, and exact 66 × 30 × 30-inch envelope. All three passed technical validation and were rendered through the real `room_photo_luna` Godot Compatibility path. v059 used the initial GLTF material factors; v060 matched v007's visible PBR factors; v061 applied candidate-local native Godot `StandardMaterial3D` overrides. Each was reviewed from the actual PNG captures.

| Candidate | Material strategy | Pixel result | Disposition |
| --- | --- | --- | --- |
| desk-v059 | Initial GLTF PBR factors | [Three-quarter](../../iterations/v059/render-runs/run-001/asset-three-quarter.png) and [detail](../../iterations/v059/render-runs/run-001/asset-detail.png) show the glass and frame collapsing toward near-black; edge reflection and hardware separation are lost. | Continue record led to a targeted v060 factor change; v007 stayed incumbent. |
| desk-v060 | GLTF factors aligned to v007 | [Three-quarter](../../iterations/v060/render-runs/run-001/asset-three-quarter.png) is slightly more translucent, but still near-black; the [room view](../../iterations/v060/render-runs/run-001/room-scale.png) is not better than v007. | Continue record led to the distinct native-override v061 strategy; v007 stayed incumbent. |
| desk-v061 | Native Godot overrides matching v007 values | [Three-quarter](../../iterations/v061/render-runs/run-001/asset-three-quarter.png), [profile](../../iterations/v061/render-runs/run-001/asset-profile.png), and [detail](../../iterations/v061/render-runs/run-001/asset-detail.png) show the silhouette but leave the top edge, broad glass response, frame, and fittings nearly black. | [Reject evaluation](../../iterations/v061/evaluation.json); v007 remains incumbent. |

**Concept-to-production comparison:** the broad thin top, paired posts, T-feet, and under-glass rail transfer into the 3D geometry, and the measured bounds remain exact. What is lost in Godot is the visual material hierarchy: the target has a readable green-black glass edge and reflective glass plane separated from graphite, satin fittings, and rubber; the v061 close views render most of that as one very dark mass. The [v061 room-scale view](../../iterations/v061/render-runs/run-001/room-scale.png) preserves the desk silhouette but does not restore the material read. The [matched v007 three-quarter](../../iterations/v007/render-runs/run-001/asset-three-quarter.png) and [detail](../../iterations/v007/render-runs/run-001/asset-detail.png) captures have a more legible top and brighter material highlights, so v007 remains the incumbent despite its own gap from the approved image target.

The evidence localizes the remaining defect to the production material/render stage, not the concept silhouette, outer scale, or basic mesh assembly. Both exported GLTF factors and the native override strategy fail in the same Compatibility scene. The renders do not isolate a proven single Godot cause; effective material assignment/response and available scene lighting/reflections still need a controlled reproduction before another desk candidate is warranted. Stop generic desk material iteration here rather than claim that exact parameter copying fixed the issue.

- **Professional visual read:** No for v061's actual close production renders; the dark merged response does not read as a finished smoked-glass workstation.
- **Structural coherence:** Yes at the major-shape level; the posts and feet are present and connected, while small joins are obscured by material darkness.
- **Detail hierarchy:** No; the top, supports, and hardware do not separate clearly in the close render.
- **3D transferability:** Yes for geometry and exact envelope; no for the image target's material response, which did not transfer through the tested paths.
- **Production decision:** **Plateau this desk material route; none of v059–v061 is approved, and v061 is rejected.** v059/v060 remain historical continue records that led to the next targeted material strategy. Keep desk-v007 and its stable registry unchanged. Reopen only with a controlled material/render diagnosis, not another unsupported furniture or shader variant.
