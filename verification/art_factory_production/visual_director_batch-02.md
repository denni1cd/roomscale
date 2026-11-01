# Visual Director Batch 2 — desk concept-to-production run

## Scope and baseline

This batch applies the new RoomScale Visual Director skill to the highest-priority photographed, instantiated desk in `rooms/room_photo_luna.json`. The supplied room photographs show the desk, hammock, and display cabinet; they do not show a sofa or fireplace. This run does not change POC 2.5 evidence, reopen its acceptance result, rewrite visible-art inventory, or repeat Batch 0 inventory/material work.

## Workflow artifact

- Reusable project workflow: [RoomScale Visual Director skill](../../skills/roomscale-visual-director/SKILL.md).
- Integration notes: [Art Factory workflow integration](../../docs/ART_FACTORY_VISUAL_DIRECTOR.md).
- Desk VisualBrief, concept rounds, scorecards, scale attempts, and concept-to-production comparison: [desk visual-development record](../../art/desk/visual_director/round-01/visual-development.md).

The process used three initial image directions, reviewed their pixels, ran targeted edits on A and C, rejected two failed generated scale studies by measuring the figures in the images, and supplied an exact dimension-derived SVG schematic. The selected edited image passed as an appearance target only.

## Production outcome

Three Art Factory challengers (desk-v059, v060, and v061) retained the same component-authored desk geometry, passed technical validation at exact 66 × 30 × 30-inch bounds, and were reviewed in actual Godot Compatibility captures. The first two attempts tested GLTF material factors; v061 switched to candidate-local native Godot material overrides. The repeated material failure is documented in each evaluation. v061's registered evaluation rejects it because its glass edge, broad reflection, and glass/frame/fitting distinctions still collapse toward near-black. The desk-v007 production candidate and stable registry remain unchanged.

This is a material/render-stage plateau for the tested desk route, not a concept failure or a production promotion. A future desk attempt requires a controlled comparison of effective v007/v061 materials and scene response before further parameter variants. The report records what survived geometry transfer, what was lost in the real Godot pixels, and the limit of the current diagnosis.

## Carried forward

- Keep desk-v007 as incumbent.
- Treat the edited concept and scale SVG as appearance references, not production proof or gameplay dimensions.
- Preserve Batch 0 as the baseline; use this skill on later high-impact assets selected from actual room/source evidence.
