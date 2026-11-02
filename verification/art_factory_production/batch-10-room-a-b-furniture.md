# Batch 10 — Room A/B Furniture Transfer

## Scope and method

Batch 10 applied the Visual Director and Art Factory to five high-impact Room A/B furniture assets: elevated workbench, assembly table, tool wardrobe, floor cabinet, and side table. The pass used source-conditioned furniture targets, scripted Blender mesh construction, location-seeded per-board UV variation, Art Factory registration, Godot production-path validation, candidate-specific evaluations, and integrated Room A/B renders. No canonical `RoomDefinition` or gameplay code was changed.

Each asset received an approved Visual Director target, reviewed by pixel inspection, then one initial transfer and one targeted correction. The initial pass produced candidates v006 for four assets and v007 for the workbench; targeted correction produced v007 for four assets and v008 for the workbench. All ten candidates were registered and evaluated. The third generation request for each asset was refused before candidate reservation because the corresponding Art Factory iteration budget was exhausted. No retry counters were changed to force a candidate through.

## Candidate outcomes

| Asset | Initial candidate | Targeted candidate and measured bounds (inches) | Current best | Strict outcome |
|---|---|---|---|---|
| Elevated workbench | v007 — depth 30.23 exceeded the 30-inch target | v008 — 58 × 36 × 30 | v008 | Continue; broad repeating grain, boxy beams, shallow hardware and drawer construction fail realism and craftsmanship |
| Assembly table | v006 — 42 × 24 × 32 | v007 — 42 × 24 × 32 | v007 | Continue; square frame, weak end vise, shallow joins and exaggerated grain fail the visual gate |
| Tool wardrobe | v006 — depth 27.88 exceeded target | v007 — 42 × 69.9 × 21.95, within 42 × 70 × 22 | v007 | Continue; blank, wide doors conceal fitted tools and hardware; grain remains repetitive |
| Floor cabinet | v006 — 26 × 24 × 21 (height/depth reversed) | v007 — 26 × 21 × 24 | v005 remains best current | Continue; v007 corrected fit but has plain drawer fronts, shallow construction and synthetic grain; it did not beat v005 overall |
| Side table | v006 — 20 × 17 × 20 (height/depth reversed) | v007 — 20 × 20 × 17 | v007 | Continue; legs, apron, drawer fittings and shelf read as simple forms; material response remains flat |

All five targeted candidates passed Godot technical validation with no import issues and the corrected envelopes shown above. Technical fit did not satisfy the visual gate. For every candidate, the registered neutral-viewer realism and close-inspection checks failed, as did craftsmanship checks for edge treatment, joins, hardware, material response, surface variation, and manufacturing detail. Evaluations are asset-specific and reference that candidate's own renders under `batch-10-room-a-b-furniture/evaluations/`.

The recorded target transfer diagnosis is consistent across the family: large looping wood bands overwhelm board direction, timber members retain block-like transitions, and shallow joinery or small hardware is not legible in production views. The wardrobe adds the specific failure that broad leaves mask its fitted tool bay. These are not color-only defects; the next useful pass needs materially different wood mapping/material authoring and deeper, readable furniture construction.

## Integrated review

The batch was placed in the production Room A and Room B review scenes. Room B used workbench v008 as the primary candidate and assembly table v007, wardrobe v007, and floor cabinet v007 as adjacent candidates. Room A used side table v007. Both room overview angles and the per-asset production phases were inspected.

The integrated scenes showed no visible production-quality gain. The furniture silhouettes remain recognizable, but broad repetitive wood waves, square construction, shallow fittings, and the wardrobe's obscured tool contents still read as prototype-level. No asset was promoted. The canonical production registry remains at 15 IDs, and all five episodes are backlogged with their best candidates preserved.

The render harness reported 2 FPS for the Room B overview (909 draw calls, 573,022 primitives) and 2 FPS for the Room A overview (947 draw calls, 496,704 primitives). Close views reported 23 FPS / 48 draw calls / 107,488 primitives for the workbench and 15 FPS / 115 draw calls / 65,600 primitives for the side table. These are one-shot capture-harness readings with the loaded review context; they are not a representative 50-citizen gameplay benchmark and should not be used as an optimization result.

## Integrity and cumulative coverage

- Canonical registry: unchanged at 15 entries; no promotion or runtime-resolution change.
- RoomDefinitions: 21 scanned (2 playable and 19 candidate/scenario files), 318 room object records; no RoomDefinition edits.
- Inventory: refreshed at 95 visible-art classes, including 48 Tier 1, 11 Tier 2, and 36 Tier 3 classes. Eight Tier 1 classes currently have accepted production entries; the rest include best-current review art, linked families, or unregistered/procedural presentation.
- Runtime geometry scan: 91 builder sites across 12 scripts. This batch added no gameplay/runtime geometry.
- Automated Art Factory integrity suite: 24 tests passed (`python scripts/test_art_factory.py`). Generator lint and compilation checks also passed.

## Disposition and next priority

Five assets were attempted, five targeted corrections were rendered and technically validated, zero assets were promoted, and all five remain backlog items. Best-current candidates are preserved rather than passed through the gate. The next batch should target the highest-impact uncovered live-room presentation identified by the refreshed inventory, while avoiding a third same-strategy loop on these exhausted furniture episodes. See the current priority and cumulative status in [production-art-backlog.md](production-art-backlog.md).
