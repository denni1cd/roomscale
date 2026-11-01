# Reconstructed window Visual Director run

**Selection:** Tier 1 architectural opening, source-required, 96 × 68 × 4 inches. `room_photo_luna.json` and `photo_holder/Sample (1).jpg` provide the source context. Review-only `room_photo_window_production-v002` is the current 3D candidate and fails its photo-character/material gate.

**VisualBrief:** [visual-brief.json](../visual-brief.json) · **Scale schematic:** [scale-guide.svg](../reference-pack/scale-guide.svg)

## Initial directions

The [three-column direction sheet](candidates/directions-r01.png) explores small transom/sill variations. A/B/C denote left/center/right.

| Category | A | B | C | Pixel evidence |
| --- | ---: | ---: | ---: | --- |
| Semantic recognizability | 5 | 5 | 5 | All show a residential double-hung window. |
| Silhouette | 5 | 5 | 5 | Wide casing, upper transom band and paired lower sections remain clear. |
| Proportions | 4 | 4 | 4 | Plausible horizontal opening; exact 96 × 68 × 4 inches are supplied separately. |
| Construction believability | 4 | 5 | 4 | B presents the meeting rail and deeper sill most clearly; all add unsupported corner rosettes. |
| Geometric/detail richness | 4 | 4 | 4 | Sash divisions and transom muntins are readable; small latches are decorative in the first pass. |
| Material realism | 5 | 5 | 5 | Stained timber and clear glazing read separately. |
| Surface variation | 4 | 4 | 4 | Controlled glass reflections and wood grain. |
| Art-direction fit | 5 | 5 | 5 | All fit the photographed domestic window character. |
| Scale cues | 2 | 2 | 2 | No citizen or exact scale diagram is present in the generated board. |
| Gameplay-distance readability | 4 | 4 | 4 | Casing and transom survive; sash locks do not need to read from the overview. |
| Source resemblance | 5 | 5 | 5 | All preserve stained wood, an upper divided band and paired lower glass sections. |
| 3D-reference transferability | 4 | 5 | 4 | B has the clearest sash/casing relationship, although its rosettes are unsupported. |

All three options are too similar to count as broad exploration; the photo constrains the window's main design. The first board also repeats small latches along the upper transom and adds corner blocks the source does not show.

| Direction | What works | What is wrong | Why | Next action |
| --- | --- | --- | --- | --- |
| A | Clear four-light top band and broad lower sash read. | Corner rosettes and repeated transom latches are unsupported. | These details imply decorative hardware and joinery absent from the photo. | Keep as comparison only. |
| B | Deep sill and meeting rail are easiest to model; wood/glass split is clear. | Same unsupported corner blocks and transom hardware. | Good underlying assembly, but requires a targeted source-faithful correction. | Select B; remove rosettes and transom latches; retain one central lower sash latch. |
| C | Broad casing and four-light transom remain legible. | Heavier trim and repeated latches add visual mass. | They pull away from the straightforward source casing. | Preserve as rejected alternate. |

## Targeted edit and approved target

The [first selected target](target-attempt-r01.png) was edited after pixel review: **keep** B's proportions, four-light transom, projecting sill and two lower sash sections; **remove** the corner rosettes and upper transom latches; **retain** one modest lower meeting-rail latch. The [approved target](approved-target-r01.png) removes the repeated hardware and keeps the source-supported wood/glass structure. The edit improves source resemblance and hierarchy without changing the silhouette.

| Category | Score | Pixel evidence |
| --- | ---: | --- |
| Semantic recognizability | 5 | Reads as a residential double-hung window with transom. |
| Silhouette | 5 | Complete wide unit, deep casing and sill. |
| Proportions | 4 | Plausible for the opening; exact dimensions are supplied in the brief. |
| Construction believability | 5 | Four fixed transom lights sit above coherent lower sashes and meeting rails. |
| Geometric/detail richness | 4 | Muntins, sash edges and one latch are medium-scale cues. |
| Material realism | 5 | Warm oak and clear glass have distinct, restrained responses. |
| Surface variation | 5 | Glazing has soft outdoor reflections without becoming opaque. |
| Art-direction fit | 5 | Approaches the source's warm residential woodwork. |
| Scale cues | 4 | Exact dimensions and a dimension-derived 1:136 citizen schematic accompany the target. |
| Gameplay-distance readability | 4 | Transom, casing and sash split remain clear in the full-object view. |
| Source resemblance | 5 | Keeps source-visible divided transom, central division, meeting rail and stained timber. |
| 3D-reference transferability | 5 | The assembly has clear frame, transom, sash, sill and hardware assignments. |

- **Professional visual read:** Yes; the corrected image reads as polished architectural reference art.
- **Structural coherence:** Yes; rails/muntins meet the casing and the lower sash has one plausible latch.
- **Detail hierarchy:** Yes; casing, transom and lower glazing dominate; no repeated latch clutter remains.
- **3D transferability:** Yes; the component breakdown is explicit and dimensions remain authoritative.
- **Image-target decision:** PASS for 3D handoff, not production approval.

## Godot production comparison

**Source:** [`Sample (1).jpg`](../../../../photo_holder/Sample%20%281%29.jpg) · **Incumbent render:** [`room_photo_window_production-v002` three-quarter](../../iterations/v002/render-runs/run-003/asset-three-quarter.png) · **Approved target:** [transom window](approved-target-r01.png) · **Initial production pass:** [`v003` detail](../../iterations/v003/render-runs/run-002/asset-detail.png) · **Targeted correction:** [`v004` three-quarter](../../iterations/v004/render-runs/run-001/asset-three-quarter.png) · [detail](../../iterations/v004/render-runs/run-001/asset-detail.png) · [room-scale](../../iterations/v004/render-runs/run-001/room-scale.png).

Compared in the same `room_photo_luna` Godot cameras, v003 replaces v002's broad blue panel with stained casing, separate sash rails, a projecting sill and divided upper glazing. Pixel review showed its central latch was hidden behind the centre stile. The recorded diagnosis was geometry loss, so attempt 2 kept v003's frame/material work and moved only the latch assembly onto the camera-facing stile. v004 passes Godot import and the source-photo review; the target remains the same approved image throughout.

Some target information remains different in production: v004 renders five narrow upper panes where the image target shows four, the small latch is subtler than in the studio render, and clear glass picks up a cool cast from the real room's outdoor context. The photographed room itself has multiple divided window sections and an outdoor view, so the source-character gate passes without further material variants. Godot validates the candidate at 96 × 68 × 4.1 inches against the unchanged 96 × 68-inch opening.

Evaluation [v003](../../iterations/v003/evaluation.json) records the failed latch transfer and its targeted correction. Evaluation [v004](../../iterations/v004/evaluation.json) compares the actual source, target, incumbent, and corrected render; v004 is promoted as the production window. The approved target remains the concept incumbent; v004 is separately recorded as `best_3d_candidate` and `production_asset`.
