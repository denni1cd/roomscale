---
name: roomscale-visual-director
description: Develop, critique, iterate, and approve image-led visual targets for high-impact RoomScale assets before 3D production, then compare the Godot result to the approved target.
---

# RoomScale Visual Director

Use this production skill when a high-impact RoomScale asset would benefit from visual development before 3D work: Tier 1 furniture, room-shell components, faction-defining settlement assets, major machinery, or hero citizens/equipment. Do not spend this workflow on low-visibility clutter.

## Roles and invariants

- Luna is the art director, critic, and production decision-maker.
- The image generator is a concept artist and visual-development worker.
- TRELLIS, Pixal3D, Hunyuan, Blender, Godot, and other tools are production workers.
- Judge the actual image pixels. A generator's description, prompt-compliance claim, filename, or successful job is not visual evidence.
- `RoomDefinition` remains authoritative for dimensions, position, collision, navigation, traversal, and gameplay. A concept image is a visual target, never gameplay geometry.
- Keep existing Art Factory candidates, review history, and Batch 0 inventory/material work. Do not alter POC 2.5 acceptance evidence as part of production visual development.

## Invocation and Art Factory handoff

Start after the asset's existing `ArtBrief` and incumbent/inventory review, and before choosing a 3D backend or running `roomscale-art generate`. The sequence is:

`ArtBrief` → `VisualBrief` → 3–4 concept directions → pixel review/selection → targeted image edits → approved target and optional reference pack → Art Factory 3D challenger → Godot production render → concept comparison/refinement → promotion or backlog.

For an existing source photograph, inspect it and the matching `RoomDefinition`. Do not invent furniture or construction details the photograph contradicts. If a proposed asset is not instantiated in any applicable room, say so and select an instantiated high-impact target instead. Preserve the Art Factory stable ID and incumbent; add challengers through the existing Art Factory candidate flow. The visual target and critique are additional production evidence, not changes to runtime contracts or a replacement Art Factory design.

### Automatic Art Factory gate

Art Factory reads `ArtBrief.priority_tier`, `screen_space_importance`, `source_photo_required`, `faction_defining`, and `current_quality` (with category/dimension defaults for unclassified briefs). A high-impact candidate without a current, approved target is blocked before a candidate version is reserved. The gate automatically creates a VisualBrief draft and case file; it does not treat a generated image or unreviewed draft as approved.

Use `roomscale-art visual-director status <asset-id>` to inspect policy, target, best 3D candidate, production asset, and case state. `prepare` opens/scaffolds the case; after actual image pixel review, `approve --target <project-relative-image> --review <project-relative-review>` records the target hash. Recipes for gated assets must list that target in `source_inputs` and set `parameters.visual_director_strategy`.

One approved target allows at most three 3D attempts: `initial`, `targeted_correction`, then `alternate_strategy`. Attempt 2 must reference a prior candidate evaluation with a recorded `visual_transfer_diagnosis`; attempt 3 must change the backend/tool or material method. Every target-driven evaluation records causes, lost visual information, preserved components, and the corrective action. Keep `approved_visual_target`, `best_3d_candidate`, and `production_asset` separate. If an episode should stop before the attempt limit, use `visual-director backlog <asset-id> --reason <specific-defect>`; it preserves the approved target and current incumbents. Minor props may bypass the gate.

## VisualBrief

Create one concise brief per asset. Use [the VisualBrief schema](references/visual-brief-schema.json) and retain its source paths and uncertainty notes. It must state:

- semantic identity and intended function;
- real-world dimensions in inches and the scale relationship to a 0.5-inch citizen;
- silhouette and recognizability requirements at gameplay distance;
- construction and material hierarchy;
- art-direction/faction fit;
- source-photo constraints and visual-reference provenance, when applicable;
- prohibited failure modes and features owned by separate RoomDefinition objects.

Keep backend implementation details out of image prompts unless they change appearance. Do not merge separately defined room props (such as monitors) into the asset concept.

## Concept exploration and critique

Do not start from one image. Generate 3–4 meaningfully different candidates when useful, varying silhouette, proportions, construction language, or material hierarchy. For photographed objects, vary only ambiguous or supportable details and stay anchored to the source. For fictional civilization assets, explore broader alternatives. Preserve all candidates and their prompts for provenance.

Inspect every candidate image. Record per candidate: **what works**, **what is wrong**, **why**, and an exact **next action**. Avoid vague requests such as “add detail” or “make it better.” Score the actual image 1–5 on every applicable category in [the Visual Director rubric](references/director-rubric.md):

1. semantic recognizability;
2. silhouette;
3. proportions;
4. construction believability;
5. geometric/detail richness;
6. material realism;
7. surface variation;
8. art-direction fit;
9. scale cues;
10. gameplay-distance readability;
11. source resemblance, when applicable;
12. 3D-reference transferability.

Also answer the rubric's four professional-read questions and explicitly call out malformed geometry, impossible joins, inconsistent perspective, disconnected parts, AI artifacts, or nonsensical detail. Do not infer image quality from generator text or from technical job success.

Choose the strongest actual image as the incumbent. Keep rejected candidates. A later image becomes incumbent only if it visibly improves the result; otherwise retain the current incumbent and label the new image marginal, equivalent, or worse. Do not average unrelated candidates into a new design.

## Targeted editing and stopping

Do not restart from scratch when the incumbent is broadly right. Each edit round must state:

1. what must remain unchanged;
2. exactly what must change;
3. which rubric deficiencies the change is expected to fix and why.

Use image editing on the selected visual target, then inspect its pixels again and record the rubric deltas and incumbent/challenger outcome. If a defect persists, change the method: edit rather than prompt again, change camera or composition, improve/crop the source, make a material or construction study, add a focused component reference, use a coherent multi-view sheet, or choose a genuinely new direction. Do not repeat essentially the same prompt.

Stop at **PASS** only when semantic recognizability is 5, art-direction fit is at least 4, construction coherence is at least 4, 3D transferability is at least 4, no applicable score is below 4, and no obvious AI-artifact hard failure remains. The professional-read questions must not reveal an unresolved structural hard failure.

Otherwise record an **evidence-backed plateau** only after multiple targeted edits, at least one materially different correction strategy, actual pixel inspection after each, the same important deficiencies persisting, and recent rounds no longer materially improving the result. Time spent or number of generations alone is not a plateau. Keep the best incumbent and continue, or backlog it with the failure evidence.

## Reference pack

After approval, make a compact reference pack when it helps 3D production: hero three-quarter, side/profile, opposite/rear, construction/detail, material close-up, or a 0.5-inch-citizen scale view. Prefer one coherent multi-view sheet when the same design can be kept consistent. Inspect every view for design drift before treating it as evidence. A schematic scale card may supplement a generated image when the generator cannot maintain the exact ratio; label it as a schematic and derive it from the brief's dimensions, never present it as generated photographic evidence.

Record the approved target path, source/provenance, candidate prompts, selected incumbent ID, scorecard, and edit history. The target guides 3D appearance only.

## 3D production comparison

Pass the approved target and VisualBrief to the chosen Art Factory backend. After producing a 3D challenger, validate/import it and render the actual asset through RoomScale's normal Godot production path. Inspect the rendered pixels, then compare them to the approved target for:

- silhouette loss and proportion drift;
- missing medium-scale forms;
- construction/join errors;
- material and color response loss;
- detail hierarchy loss;
- faction identity loss;
- source-resemblance loss, when applicable.

Name the lost visual information and the evidence view where it occurs. Diagnose the cause as concept ambiguity, backend geometry, UV/material generation, import, lighting/rendering, scale, or LOD. Refine the responsible stage; do not keep editing concept art to compensate for a 3D backend limitation, or blame the backend for an incoherent concept.

Promote only through the existing Art Factory criteria and registry flow after the production render passes. Generated concept art alone is never a production-art success. Preserve failed/challenger renders and record the disposition as promoted, continue, reject, or backlog. Use [the round-review template](templates/round-review.md) for every application.
