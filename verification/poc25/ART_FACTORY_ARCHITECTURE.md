# RoomScale Art Factory — Architecture and Backend Boundary

## Reusable Art Factory layer

The shared orchestration is in scripts/art_factory/:

- models.py defines ArtBrief, ArtRecipe, candidate state, evaluation rubric, and the explicit strict visual gate.
- factory.py saves briefs and recipes, starts and records candidates, preserves outputs and provenance, records validation/render/evaluation evidence, compares against incumbents, and controls promotion.
- registry.py owns stable asset IDs, content hashes, atomic records, and promotion history.
- cli.py exposes the offline authoring workflow.
- godot_bridge.py is the Godot boundary for importing, measuring, validating, and rendering candidate assets through the actual RoomScale production scene.

The production runtime boundary is in scripts/visuals/:

- asset_registry.gd resolves project-local visual assets by stable semantic ID and hash.
- visual_resolver.gd attaches imported scenes to presentation nodes only. It does not supply collision, navigation, or gameplay geometry.
- The explicit poc25_best_current_showcase mode is read-only and review-only. It allows best_current_review entries only when ROOMSCALE_ART_REGISTRY_MODE=review_showcase is explicitly set. The default remains art/registry.json; normal production mode rejects review-only entries.
- The standardized scripts/art_factory/render_harness.gd and grapple_render_harness.gd render in scenes/pipeline_proof.tscn, exercise production resolution, and record camera, candidate, renderer, and capture receipts.

## Backend-specific worker layer

Each ArtRecipe supplies the backend command, seed, parameters, source inputs, material/import method, and declared outputs. Backend code is isolated in a versioned worker under scripts/art_factory/generators/; candidate-local copies, licenses, generated assets, and records are preserved in art/<asset>/iterations/vNNN/.

The factory has exercised materially different workers:

- Godot/Python procedural construction and scripted Blender component modeling.
- TRELLIS.2 with its intended pinned DINOv3 conditioning weights.
- Pixal3D single-image and multi-view production, with separate geometry/material packaging.
- Hunyuan3D 2.1 and RecGen3D image/reconstruction-guided asset workflows.
- SUPRA-Tex hosted generation for the Desk.
- MPFB2 anatomical human generation and rigging for the Citizen.
- Blender-authored, skinned, fitted Clockwork garments and mechanical accessories.

These workers produce ordinary project-local .tscn, .glb, material, and evidence files. Runtime gameplay does not call the generation backend or an AI service.

## Replaceable-backend workflow

1. The asset brief states identity, dimensions, visual gates, gameplay invariants, and references.
2. A recipe selects a worker and records its command, tool version, inputs, seed, parameters, outputs, and import configuration.
3. The factory creates a new immutable candidate folder. Failures remain visible.
4. Godot imports and checks bounds, scene structure, rig, and other asset-specific technical requirements.
5. The candidate is resolved and rendered inside the live RoomScale scene using a temporary review registry; it is not promoted.
6. The actual images and receipt are inspected. The evaluator records explicit strict-gate answers, evidence, defects, likely causes, and a targeted next action.
7. A challenger is compared with the incumbent. It can be refined, rejected, or switched to a different worker. Only a passing evaluation can be promoted through the canonical registry.
8. Promotion is reversible; all candidates, comparisons, and the prior incumbent remain in history.

Changing from MPFB2 to another character generator, or from TRELLIS.2 to a future Desk worker, changes the recipe/worker and possibly the asset-specific adapter. It does not require changes to RoomDefinition, gameplay systems, the stable semantic resolver, or the Art Factory evidence lifecycle.

## Gameplay boundary

RoomDefinition remains authoritative for room surfaces, collision, navigation, construction targets, dimensions, and placement. Art scenes affect presentation only. art/registry.json is the sole default production registry. Candidate and best-current showcase registries require explicit review mode and cannot silently fall back to procedural art when a registered asset fails.
