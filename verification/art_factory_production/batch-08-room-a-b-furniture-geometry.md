# Batch 8 — Room A/B furniture geometry and finish

## Scope and target episodes

Batch 8 continued the Room A/B furniture geometry pilot with five high-visibility Tier 1 assets: elevated workbench, assembly table, tool wardrobe, floor cabinet, and side table. Each candidate was generated from an approved Visual Director target and reviewed in production-path Godot renders at detail, gameplay, and room scale. The existing RoomDefinition dimensions, placements, surfaces, navigation, collision, and gameplay landmarks stayed authoritative.

The four round-02 targets were pixel-reviewed and approved. Workbench v004 exposed a GDScript inference error (`sections` lacked an explicit `Array[Vector2]` type); Art Factory preserved that failed attempt. I corrected the type, generated and pixel-approved a fresh round-03 workbench target, then completed two attempts under that target. No attempt counters were reset manually.

## Candidate and gate results

| Asset | Best current candidate | Technical result | Visual disposition |
|---|---|---|---|
| Elevated workbench | `room_elevated_workbench-v006` | Pass; 60 meshes, 13,472 triangles; bounds 57.8 × 36.005 × 30.475 in. | Brighter oak/walnut separation and profiled construction improve v003, but high-contrast grain repeats and the fitted shoulders/drawer relief remain weak. Strict gate fails. |
| Assembly table | `room_assembly_table-v005` | Pass; 28 meshes, 6,720 triangles; bounds 41.4 × 23.55 × 31.8 in. | The vise, drawer, breadboard ends, dog holes, and lower frame read clearly. Warmth improves over v003, but beam construction and grain remain simplified. Strict gate fails. |
| Tool wardrobe | `room_tool_wardrobe-v005` | Pass; 92 meshes, 20,480 triangles; bounds 42 × 70 × 22.4 in. | Raised door fields and the open tool bay are legible; broad door faces and repetitive grain remain procedural-looking. Strict gate fails. |
| Floor cabinet | `room_floor_cabinet-v005` | Pass; 29 meshes, 5,504 triangles; bounds 25.8 × 21.02 × 23.85 in. | Routed drawer fronts and brass pulls improve the prototype; drawer/carcass transitions and repeated grain remain too simple. Strict gate fails. |
| Side table | `room_side_table-v005` | Pass; 18 meshes, 13,024 triangles; bounds 19.8 × 19.4 × 16.8 in. | A fuller turned-leg waist and brighter finish improve v003; shallow shelf/drawer relief and synthetic streaking remain. Strict gate fails. |

All five evaluations record improved best-current candidates, not production promotions. In each case the craftsmanship checks for thickness and hardware pass; joinery, edge treatment, manufacturing detail, material response, and surface variation do not. Neutral-viewer realism also fails, and simplified/primitive style flags remain. The Art Factory and Visual Director cases preserve the current candidate, evidence, concrete backlog reason, and target-attempt history.

The workbench uses target round 03 because the failed v004 belonged to its earlier round-02 episode. The other four targets use round 02. Each active target episode ended after two recorded attempts; no unsubstantiated third attempt was added.

## Production review and integrity

Candidate-specific detail, three-quarter, gameplay-distance, Room B, and settlement-scale renders are recorded under each candidate's `render-runs` directory. The Room B review copy binds only the four furniture asset IDs to the best-current candidates; the Room A review copy binds the side table. These are review inputs and do not change canonical room data. The registered captures and evaluation evidence point to the corresponding production-path Godot renders.

No candidate passed the strict gate, so the canonical Art Factory registry and the live Room A/B appearance bindings remain unchanged. No gameplay, RoomDefinition, collision, navigation, or runtime visual-resolution code changed. The current inventory still covers 95 visible-art classes across 21 RoomDefinitions and 318 object records; this batch changes review coverage, not runtime coverage.

## Verification

- `python scripts/test_art_factory.py` — 24 tests passed.
- `python -m py_compile scripts/art_factory/cli.py scripts/art_factory/factory.py scripts/art_factory/models.py` — passed.
- Godot 4.7.2 headless editor import — passed.
- `scripts/visuals/visual_resolver_test.gd` — passed. The warnings in its output are expected negative checks for missing/unregistered test assets.
- Art Factory candidate generation and technical validation passed for all five best-current candidates. The original workbench v004 parser failure remains recorded.

## Next priority

Continue with the French-door opening, then return to the remaining Tier 1 Room A/B fallbacks and scene-wide room finishes. The door already has a best-current review candidate from Batch 6, but the target episode is exhausted and the candidate still lacks convincing hinge detail and source-like glass/environment response. A new round must use a materially different door construction approach and keep any exterior-context treatment in the review room rather than baking it into the door mesh. Keep all five Batch 8 furniture candidates review-only until a strict gate passes.
