# Desk Hunyuan3D 2.1 Sample (3) Challenger Review — 2026-10-28

## Disposition

`desk-v054` is a valid fresh Hunyuan3D 2.1 shape inference plus Hunyuan3D-PaintPBR run using the desk-masked Sample (3) source view. Generation and Blender packaging completed, Godot 4.7.2 imported the result without issues, and all six RoomScale production captures were recorded. The strict visual gate rejects it: the output is a broken, fragmented photo-textured shell without a recognizable standing-desk frame, realistic workmanship, or the source photograph's visual character. It is worse than retained incumbent `desk-v007`. Do not promote or alter the registry.

This is a source-view refinement within the existing Hunyuan3D 2.1 strategy, not a new method family. The earlier geometry/material attempt `desk-v028` and paint-only refinement `desk-v029` remain preserved; v054 confirms another crop/seed is not enough. Keep all Hunyuan-generated meshes, PBR maps, and renders local under the recorded Tencent license.

## Candidate and inference evidence

- Candidate: `art/desk/iterations/v054/candidate.json`; parent `desk-v053`; status `rejected` after evaluation.
- Recipe: `art/desk/iterations/v054/recipe.json`, originating from `art/desk/recipes/v054.json`.
- Generator: `scripts/art_factory/generators/hunyuan21_desk_v054.py`, reusing the pinned v026 Hunyuan implementation without altering its model or pipeline.
- Conditioning input: the alpha-masked, pixel-preserving Sample (3) desk crop at `art/desk/source_views/desk-photo-crop-v053.png`; its mask excludes the visible monitors, tablet, chair, keyboard, cables, floor, and wall. Hidden geometry remains inferred. Sample (2) remains the controlled acceptance reference.
- Seed 26054; pinned `tencent/Hunyuan3D-2.1` snapshot `0b94677654c57bb9a6b6845cd7b704ccf551d327`; Hunyuan3D-PaintPBR v2.1; 50 shape steps; octree 512; six selected paint views; 2048 render / 4096 texture resolution; no remeshing.
- Runtime: RTX 5090, SM120, Torch 2.7.0+cu128, CUDA 12.8. The full generation returned exit code 0 and generated shape, fitted shape, GLB, OBJ/MTL, and albedo/metallic/roughness maps.
- `generation-record.json` reports 223,679 raw vertices / 447,332 raw faces. The predicted oriented extents were about 1.994 × 1.154 × 0.500 before fitting and were non-uniformly scaled to the unchanged 66 × 30 × 30-inch bounds, with floor minimum Y=0.

## Technical and production integration

Godot 4.7.2 Compatibility validation passed with no import issues: one mesh, one surface, 447,326 triangles, exact 66 × 30 × 30-inch bounds, and floor contact at Y=0. RoomDefinition and gameplay geometry were unchanged.

All six production-path views completed in `art/desk/iterations/v054/render-runs/run-001/`: room-scale, settlement-scale, three-quarter, opposite three-quarter, profile, and detail. The harness sampled 33 FPS in each phase; these are unwarmed captures, not performance benchmarks. Settlement-scale reports 3,024,091 primitives.

## Strict visual gate

The actual three-quarter and detail captures show a torn, disconnected loop/sheet form, large open gaps, floating-looking fragments, and blue-green photographic color patches. A visually dense mesh and generated PBR maps do not compensate for the missing object construction.

| Required question | Answer | Evidence |
|---|---|---|
| Would a neutral viewer describe it as realistic furniture rather than stylized or low-poly game geometry? | No | It reads as a broken abstract photo-textured shell, not a desk. |
| Does it hold up at close inspection without obvious primitive construction? | No | The close view exposes large holes, broken strips, ragged boundaries, and missing assembly. |
| Are edge treatment, joins, thickness, hardware, material response, surface variation, and manufacturing detail believable? | No | All seven workmanship checks fail; no coherent glass edge, lift frame, joins, feet, hardware, or material separation is visible. |
| Where a photograph exists, does the render materially approach the photographed object character rather than only its envelope? | No | The source has a dark top and standing support frame; the render has no readable frame and unrelated blue-green fragments. |

All explicit answers and the seven craft checks are recorded in `art/desk/iterations/v054/evaluation.json`. `desk-v007` is itself still a strict-gate failure, but retains a continuous top and recognizable support silhouette; v054 is worse. Preserve the v007 incumbent and all candidate history.

## Other pilots and CI status

The direct strict-render re-audit at `verification/poc25/final/strict-incumbent-visual-gate-reaudit.json` still finds desk-v007, grapple-v006, and citizen-v007 failing the repaired visual gate. Grapple and Citizen must not be counted as PASS based on legacy promotion records.

The failure artifacts for GitHub run `40256472981` at `04e75d2` remain classified in `verification/poc25/final/ci-04e75d2-classification.md`: both are POC 2.5 regressions (Clockwork art crossing into Verdant, and Windows CRLF-sensitive registry hash behavior). The accepted repair run `40417656855` passed all six jobs. This local challenger changes no runtime integration, so no new CI run is justified by v054.

## Next action

Keep `desk-v007`; do not repeat single-image Hunyuan crop/seed/paint variations or promote v054. Compare existing materially different production evidence (including authored multipart geometry, TRELLIS.2, RecGen3D, and Pixal3D) under the same strict gate and choose a genuinely different geometry capability only if it targets the shared missing capability: coherent, separable manufactured construction paired with believable PBR response. The Desk pilot is not declared plateaued by this report. Broad migration stays gated on Desk, Grapple, and Citizen passing or an approved evidence-backed plateau.
