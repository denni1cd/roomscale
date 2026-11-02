# Room Shell Trim — Visual Director Round 01

## VisualBrief

- ArtBrief: `art/room_shell_trim/brief.json`
- VisualBrief draft: `art/room_shell_trim/visual_director/visual-brief-draft.json`
- RoomDefinition: `rooms/room_photo_luna.json`
- Source photograph: `photo_holder/Sample (1).jpg`
- Incumbent production geometry: RoomDefinition-driven cuboid baseboard and crown segments; no registered trim candidate.
- Review method: direct multimodal pixel inspection by Codex. No separate Luna reviewer tool is exposed in this task; reviewer provenance is recorded accurately.

## Round 01

### Initial concept directions

1. **Direction A — stepped bead and cap.** The source palette and material separation are strong. Pixel inspection shows a decorative square block at the window head that is unsupported by the photograph, plus overly heavy casing. Reject this direction.
2. **Direction B — flat-stock Craftsman.** Joins and simple planar construction read clearly. The casing and head cap become too broad and squared relative to the source trim, and the wood grain has strong high-contrast streaking. Keep as a useful profile alternative, not the incumbent.
3. **Direction C — shallow ogee and bead.** The room corner, crown, baseboard and casing form a coherent traditional set. The profile is more ornate than the photograph supports, and the timber highlights are too bright. Reject as incumbent.
4. **Direction D — simple cove/reveal.** This is the closest fit to the photographed room: plain green walls, muted carpet, dark stained wood, and modest dimensional casing. The first image has pronounced striped grain and hot highlights, so it needs a material-only correction.

### Targeted edit 01

- Candidate image: `candidates/trim-direction-d-edit01.png`
- Prompt: Preserve Direction D's room composition, shallow cove/reveal profile, existing window proportions, clean corner and domestic style. Reduce the high-contrast striped grain and glossy highlights; keep dark warm stained wood, deep green paint, subdued carpet, and the plain source-supported architecture.
- Pixel result: Grain contrast and bright specular streaks are visibly reduced. The baseboard and crown remain broad enough to read, while the window casing and room remain recognizable. The edited image is clearer and more source-appropriate than Direction D.
- Incumbent comparison: clearly better than the initial Direction D; retain the edit.

### Rubric for edited candidate

| Category | Score | Pixel evidence |
| --- | ---: | --- |
| Semantic recognizability | 5 | Baseboard, crown and window casing are distinct in the lower wall, ceiling corner and window surround. |
| Silhouette | 4 | The shallow cove/reveal profile is visible without ornate protrusions. |
| Proportions | 4 | The broad trim is plausible for the source; the exact hidden profile is not measurable in the photograph and remains an assumption. |
| Construction believability | 4 | The visible corner and casing returns meet cleanly; no disconnected pieces are apparent. |
| Geometric/detail richness | 4 | Multiple profile transitions create a visible edge hierarchy beyond a plain box. |
| Material realism | 4 | The edit reduces glossy streaks and keeps restrained stained-wood grain. |
| Surface variation | 4 | Grain remains visible but no longer dominates the broad faces. |
| Art-direction fit | 4 | The dark wood and green wall preserve the photographed domestic character. |
| Scale cues | 4 | The accompanying schematic records the 5-inch RoomDefinition trim envelope against a 0.5-inch citizen; the diagram is explicitly schematic. |
| Gameplay-distance readability | 4 | Crown and baseboard remain distinct against the green wall in the room-scale composition. |
| Source resemblance | 4 | Color, sheen and plain residential construction align with visible source evidence; the precise profile is uncertain. |
| 3D-reference transferability | 4 | The edited perspective shows the installed relationships; the profile scale card supplies measurable envelopes and construction hypotheses. |

- Professional visual read: Yes; it reads as a plausible architectural trim study, with no obvious malformed geometry.
- Structural coherence: Yes; the crown follows the corner, the baseboard follows the floor, and window casing remains a separate frame.
- Detail hierarchy: Yes; broad wood faces and shallow profile transitions carry the detail.
- 3D transferability: Yes with the accompanying schematic; the source photo does not reveal an exact molding cross-section.
- Hard failures/artifacts: No obvious disconnected geometry or impossible join in the reviewed view. Exact molding section and hidden returns are not source-evidenced and must remain conservative.
- Disposition: PASS as an appearance target for a modest profile study; production still requires a separate Godot candidate review.

## Art Factory / Godot handoff

- Approved target: `art/room_shell_trim/visual_director/round-01/approved-target-r01.png`
- Profile/scale reference: `art/room_shell_trim/visual_director/reference-pack/trim-profile-scale.svg`
- Production candidate: pending.
- Production render evidence: pending.
- Promotion decision: pending production comparison. The target alone is not a production-art success.
