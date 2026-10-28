# Desk v033 review — TRELLIS.2 material and renderer diagnosis

**Disposition:** continue. Preserve `desk-v033`; `desk-v007` remains the incumbent.

## Strategy record

- **Strategy identity:** TRELLIS.2 4B single-image geometry and native O-Voxel PBR, refined with photo-derived/region-separated PBR materials.
- **Strategy classification:** `v031`–`v033` are one materially different strategy with packaging and material refinements. v032 fixed the candidate package; v033 changed PBR material assignment and reduced the mesh budget. Neither packaging nor PBR-map refinements are counted as a new geometry-generation strategy.
- **Credible basis:** the DINOv3-conditioned 4B model generated a dense 298,779-triangle standing-desk mesh, native PBR attributes, and a recognizable form. The v033 material pass divided it into four named surfaces, retained the visual envelope, and reduced the mesh to 64,999 triangles.
- **Toolchain:** pinned Microsoft TRELLIS.2 4B, DINOv3 ViT-L/16, public BiRefNet, local PyTorch SDPA adapter, Blender 5.2.3 material reconstruction, Godot 4.7.2, RoomScale Art Factory renderer.
- **Candidates:** `desk-v031` preserved the first inference but failed primary-file ordering; `desk-v032` corrected packaging and passed technical/render integration; `desk-v033` added region-specific PBR and geometry reduction and also passed technical/render integration.
- **Production captures:** [v033 Compatibility run](../../art/desk/iterations/v033/render-runs/run-001/receipt.json) and the six PNG captures beside it.
- **Renderer probe:** [same-scene Forward+ run](../../art/desk/iterations/v033/renderer-probes/forward-plus-run-001/receipt.json), launched with the unchanged production harness and a CLI renderer override; no project renderer setting was changed.
- **Best result:** v033 is the most efficient generated-mesh refinement so far (64,999 triangles versus 298,779 in v032), but it does not beat v007 visually.
- **Visual gate:** failed. Neutral desk recognition passes. Close inspection, craftsmanship, material response, surface variation, and source-photo character fail. The tabletop is near-black in both renderer captures; broad glass reflections, a finished edge, and clear support joins are absent.
- **Performance comparison:** the standard detail view reports 313,378 primitives and 48 FPS for v033 versus 57,330 primitives and 48 FPS for v007. v033 has not demonstrated a performance improvement.
- **Limiting factor:** very dark generated base color and missing readable product construction. A low roughness value and a renderer-method change did not produce the expected glass response. The high-density single-view mesh does not supply the missing mounts and joins.
- **Status:** the tested TRELLIS.2 single-image/material path has not passed. A distinct sparse multi-view reconstruction-guided strategy remains credible and is the next desk approach; the pilot is not plateaued.

The supplementary renderer check is not acceptance evidence and does not change the project's Compatibility renderer. Godot's current documentation lists reflection probes as supported in Compatibility (up to two probes per mesh) and identifies screen-space reflections as unavailable there; see [renderer feature matrix](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) and [ReflectionProbe limits](https://docs.godotengine.org/en/latest/tutorials/3d/global_illumination/reflection_probes.html). The Forward+ capture retained the near-black appearance, so renderer limitations alone do not explain this result.
