# Batch 6 — Source-conditioned French door

## Selection and scope

This batch advanced the Tier 1 French-door opening after Batch 5. The existing production room has no assigned door asset, and the stale door assignment had already been removed. The goal was to test a properly sourced, fitted pair while preserving the authoritative 66 × 82 inch opening and every RoomDefinition/gameplay invariant. No candidate was installed in the canonical registry or active room.

The source is Michael Gaylard, “Interior of a room with ornate antique furniture and decorative tiling. (55253834004),” via Wikimedia Commons, licensed CC BY 4.0. Attribution, license, original Flickr link, downloaded file provenance, and the AI-generated material relationship are in [`source-attribution.json`](../../art/room_photo_french_door_production/sources/source-attribution.json). The source photograph shows the warm stained pair, divided glazing, meeting stile, and threshold; it does not clearly establish hinge details. The supplied RoomScale room photograph shows trim and windows, not a door, and was used only for room palette/context.

Visual Director approved target r01 after pixel review. It specifies two leaves, a two-column by five-row glazing grid per leaf, real rails/muntins, stepped casing, threshold, three hinges per leaf, a left round knob and right horizontal lever, and a greenery-facing glass view. Target approval evidence is in [`pixel-review-r01.md`](../../art/room_photo_french_door_production/visual_director/round-01/pixel-review-r01.md); the target and prompt are in the same `visual_director/round-01` folder.

## Candidate attempts and findings

| Candidate | Strategy and result | Disposition |
|---|---|---|
| v003, attempt 1 | Recovered after the first generator call failed because `ROOMSCALE_BLENDER_EXECUTABLE` was unset. The initial failure and successful same-candidate recovery are retained in `generation-environment-failure-001.log` and `generation-recovery-001.log`. It established the paired open-frame construction and exact envelope, but the oak grain was imperceptible, hardware was too small/dark, and the glass read blue. | Continue; technically valid and better than v002, not promoted. |
| v004, attempt 2 | Targeted correction enlarged and brightened the handles/hardware, adjusted the glazing, and added a procedural oak-grain branch. The material grain remained imperceptible in Godot; outer hinges and exterior context remained weak. | Continue; better material value and handles, not promoted. |
| v005, attempt 3 | Alternate strategy used a separately generated, pixel-reviewed oak albedo map with repeat-enabled UV sampling. Grain became visible, but the repeated cathedral figure is stronger and more regular than the target. The six hinges remain hard to identify, and the production scene still shows blue sky because there is no garden behind the opening. | Continue as best review candidate; target episode closed at attempt 3 and backlogged. |

The selected oak map is [`ai-generated-stained-oak-albedo-r01.png`](../../art/room_photo_french_door_production/sources/ai-generated-stained-oak-albedo-r01.png). Its source and edge review, including the measured non-zero edge differences, are in [`ai-generated-stained-oak-albedo-review.md`](../../art/room_photo_french_door_production/sources/ai-generated-stained-oak-albedo-review.md). It is not a crop of the Commons photograph. The alternative r02 map is retained but was not selected. Do not describe either texture as mathematically seamless.

The Visual Director evaluation for v005 is [`evaluation.json`](../../art/room_photo_french_door_production/iterations/v005/evaluation.json). Its close-inspection, craftsmanship, neutral-viewer, and photo-character gates fail on readable hinge construction, natural wood variation, and target-like exterior context. The evaluation scores scale fidelity and technical integration at 5/5, but those technical passes do not override the visual failures. Matched captures: [detail](../../art/room_photo_french_door_production/iterations/v005/render-runs/run-001/asset-detail.png), [three-quarter](../../art/room_photo_french_door_production/iterations/v005/render-runs/run-001/asset-three-quarter.png), and [room scale](../../art/room_photo_french_door_production/iterations/v005/render-runs/run-001/room-scale.png).

## Technical and runtime boundary

Godot 4.7.2 validation passed for v005: exact 66 × 82 × 4 inch bounds, six surfaces, 59,420 triangles, and no reported validation issues. The render harness used the production path with a review-only registry. Its room copy differs from the canonical `rooms/room_photo_luna.json` only by the appearance `asset_id` for the existing opening; it changes no dimensions, placement, collision, navigation, or simulation state.

The canonical registry remains at 15 IDs, and `room_photo_french_door_production` is absent. `python -m scripts.art_factory.cli verify room_photo_french_door_production` therefore reports no accepted asset, as expected. The v005 candidate is review-only; no runtime draw cost or gameplay behavior changed. Instantaneous render receipt samples varied substantially (roughly 2–46 FPS across candidate views), so this batch makes no performance claim or new benchmark. Use the existing 50-citizen production measurements as the baseline.

The refreshed full-art inventory still covers 21 RoomDefinitions, 318 room-object records, 79 unique room-object classes, 95 visual-art class rows, and 15 production IDs. Its assigned-candidate strict-result field still shows the two desk aliases; the French-door candidate remains unregistered, so its candidate-level failure is documented here rather than counted as an assigned registry result. Batch 5's six furniture failures are likewise review-candidate outcomes. This distinction keeps the inventory's registry cross-check separate from the batch evaluation record.

## Verification

`ruff check` passed for the Blender generator and inventory script; `ruff format --check` and `python -m py_compile` passed for both. `python scripts/test_art_factory.py` passed all 24 tests. Godot 4.7.2 headless editor import and `scripts/visuals/visual_resolver_test.gd` passed. The Art Factory CLI verification returned `verified: false` with “no accepted asset registered”; that is the expected result because the French door failed the visual gate and was not promoted. Candidate generation and v003–v005 technical validation logs are retained alongside each iteration. No gameplay source, production registry, RoomDefinition, or gameplay test input changed in this batch.

## Cumulative status and next priority

Batch 6 produced three evaluated candidates and no promotion. The best current French-door candidate is v005, preserved for review; the Visual Director case is backlogged. The production-art migration remains incomplete. The next priority is the Room A/B furniture geometry follow-up from Batch 5: use a genuinely stronger mesh-authoring workflow for shaped profiles and fitted joins, not another material-only loop. Keep the French door queued for a later pass that can address hinge readability and exterior context without changing gameplay or adding a synthetic backdrop to the asset.
