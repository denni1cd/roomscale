# RoomScale Visual Director

RoomScale Visual Director is a project skill layered into the existing Art Factory workflow. Invoke it for a high-impact asset when image-led visual development can improve the 3D result; skip low-visibility clutter.

## Integration point

The skill starts after Art Factory's existing `ArtBrief`, stable asset inventory, and incumbent review, but before the backend recipe is selected or `roomscale-art generate` is run:

`ArtBrief` → `VisualBrief` → image candidates and Luna's pixel review → targeted edits → approved visual target → Art Factory 3D candidate → existing Godot validation/render → concept comparison → existing evaluation/promotion or backlog.

This adds a visual-development evidence layer. It does not change the `ArtFactory`, registry, `RoomDefinition`, gameplay geometry, or POC 2.5 acceptance contract. The target image guides appearance only. Store the brief, image prompts, candidate images, edit history, scorecards, and 3D comparison alongside the asset's `art/<asset-id>/visual_director/` evidence or the applicable verification batch. Use the skill's `roomscale-art` CLI integration by recording the approved target in the downstream recipe's `source_inputs`; still create, validate, render, and evaluate the 3D candidate through Art Factory's existing flow.

## Invoke

Use the skill when the asset is Tier 1/high impact, a photographed object with clear source evidence, or a defining piece of a room/faction. Read the existing `ArtBrief`, RoomDefinition, visible-art inventory/backlog, all supplied source images, and best-current production renders first. If a suggested object is not instantiated in any target room, do not treat it as a source-observed replacement asset.

Follow [the skill](../skills/roomscale-visual-director/SKILL.md), [VisualBrief schema](../skills/roomscale-visual-director/references/visual-brief-schema.json), and [round review template](../skills/roomscale-visual-director/templates/round-review.md). Maintain the explicit PASS/plateau gate and the incumbent/challenger history. A generator's text response never counts as visual review.

## Scene/style anchors

Maintain one compact reference set per language as high-impact assets are approved: Human Room (believable domestic architecture/materials), Clockwork (miniature industrial construction), Verdant (organic/biological construction), and Scavenger (salvaged/reused construction). Reuse shared color/material/construction principles without making every asset identical. Keep the source for every anchor and recheck it when later assets drift.

## Production proof

Generated concept art is a visual target, not a production success. For each accepted design, inspect the actual Godot production render for silhouette, proportions, medium-scale form, construction, materials, detail hierarchy, faction identity, and source resemblance. Diagnose the stage that lost the information; update the responsible stage and retain the incumbent when a challenger is worse. Promote only through the existing Art Factory production criteria.

## Current application

The first applied run is [Visual Director Batch 2](../verification/art_factory_production/visual_director_batch-02.md), with its desk-level image scorecards and concept-to-Godot production comparison in the [desk record](../art/desk/visual_director/round-01/visual-development.md). [Batch 3](../verification/art_factory_production/visual_director_batch-03.md) applies the integrated flow to a cabinet, photographed window, and Clockwork workshop: the cabinet and window improved and promoted; the workshop target was compared, diagnosed, and backlogged with accepted v004 preserved.
