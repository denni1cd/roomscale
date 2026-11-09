# RoomScale 3D production reconciliation — online review packet

## Review request

Please independently assess whether the evidence supports the bounded TRELLIS.2 trial and the recommendation to augment RoomScale with selected Factorium evidence/review practices. In particular, assess whether the bookcase is a meaningful integrated visual improvement at RoomScale gameplay distances, whether its geometry cost is acceptable, and whether the desk result invalidates broader claims about image-to-3D material transfer.

This is a review-only experiment. Both candidates are staged under `review_showcase`; neither was promoted to the canonical art registry or included in normal gameplay. The selected meshes are supplied here so a reviewer can inspect the actual outputs rather than rely on concept images or workflow claims.

## Checkpoint

- RoomScale review branch base and last pushed commit: `f27b6d1fecca4af11369f1663e3cd9d8a7f8c392`.
- Factorium branch reviewed: `feat/art-foundry-v1-20261108`, commit `4be0f1027f56f30032aafe7cf9a48e625c7bd95c`.
- Full evidence and unresolved-test inventory: [REPORT.md](REPORT.md).
- Factorium source docs: [Art Investigator](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/skills/art-investigator/SKILL.md), [Art Factory](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/skills/art-factory/SKILL.md), [handoff](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/docs/WORK_ART_FACTORY_HANDOFF.md). No merge or capability-validation claim is made.

## Execution path

Both approved RoomScale target images were processed through Microsoft's hosted `microsoft/TRELLIS.2` Space, revision `ebf60b20fc5a4607f90a1c11c0aab0ceeda5429d`, using `/preprocess_image` → `/image_to_3d` → `/extract_glb`. Inference ran on the Space's reported `zero-a10g` runtime; no local inference was run. Blender 5.2.3 performed scale/orientation handling, texture conversion, decimation, and GLB export. Godot 4.7.2 Compatibility renderer then imported each candidate through RoomScale's production resolver in review-only `review_showcase` mode and captured matched candidates/incumbents.

## Bookcase — positive visual result, review-only

- Raw generated GLB: [trellis2-generated.glb](bookcase/trellis2-generated.glb), SHA-256 `893e1a2fc3ee273165b1fb887c4df87c0ee11f8be0eb2920f194ac3ad53b05eb`.
- Finished candidate: [trellis2-roomscale-025.glb](bookcase/trellis2-roomscale-025.glb), 24,250 triangles, exact 32×63×17-inch registered envelope, SHA-256 `0c46883f0ddd53a4dd44ed0586cd41865388fd699ccc4f24fda3b6ae10ad1cfb`.
- At 73.08 inches in the production scene: [candidate](bookcase/candidate-render-025/asset-gameplay-distance.png) · [procedural incumbent](bookcase/incumbent-render/asset-gameplay-distance.png).
- At 330 inches: [candidate](bookcase/candidate-render-025/room-scale.png) · [incumbent](bookcase/incumbent-render/room-scale.png).
- Receipts and validation: [candidate Godot receipt](bookcase/candidate-render-025/receipt.json), [incumbent receipt](bookcase/incumbent-render/receipt.json), [technical validation](bookcase/trellis2-technical-validation-025.json), [Blender finish receipt](bookcase/trellis2-roomscale-025.blender-finish.json), [generation record](bookcase/run-record.json).
- The 73-inch snapshot reports 26 draw calls / 73,026 primitives / 45 FPS for the candidate and 109 / 16,788 / 45 for the incumbent. These are not controlled performance benchmarks. The 10% decimation variant visibly damaged the side panels; it is excluded from the selected candidate.

## Desk — technical pass, material-transfer failure

- Raw generated GLB: [03-trellis2-desk.glb](desk/trellis2-run/03-trellis2-desk.glb), SHA-256 `0d62e85b807abe77a821c3fa730937893e48f97de848f0ab31ab4904cc4198f4`.
- Finished candidate: [trellis2-desk-010.glb](desk/trellis2-desk-010.glb), 9,968 triangles, SHA-256 `336b42b86d712a2deb9125ed113e2896461223f0ceefc48fb49ea2dfc76a65b6`.
- At 72.18 inches: [candidate](desk/candidate-render-matched/asset-three-quarter.png) · [desk-v007 incumbent](desk/incumbent-render/asset-three-quarter.png).
- At 50.21 inches: [candidate](desk/candidate-render-matched/asset-detail.png) · [incumbent](desk/incumbent-render/asset-detail.png).
- Receipts and validation: [candidate Godot receipt](desk/candidate-render-matched/receipt.json), [incumbent receipt](desk/incumbent-render/receipt.json), [technical validation](desk/trellis2-technical-validation.json), [Blender finish receipt](desk/trellis2-desk-010.blender-finish.json), [generation record](desk/trellis2-run/run-record.json).
- The GLB imports as a single opaque material surface across glass and frame; the candidate loses the incumbent's tabletop highlight at 72 inches and does not improve the dark glass read at 50 inches.
- Provenance caveat: the saved desk run script/log retain the static filename `03-trellis2-bookcase.glb`, while the desk run record and hashed output use `03-trellis2-desk.glb`.

## Decision state

Two independent feasibility reviewers examined the actual outputs and execution path. Both asked **“Is this realistic?”** and answered **Conditional**. Their findings support a bounded trial for selected rigid opaque props; they do not support replacing the backend or resuming broad migration. The production recommendation is Option 2: augment RoomScale with selected Factorium evidence/review practices while leaving RoomScale's Visual Director, Art Factory, registry, and acceptance gates authoritative.

Current strict outcome: 2 generated assets, 2 asset-level Godot technical passes, 2 visually reviewed in production-scene captures, 1 clear integrated visual improvement, 0 canonical promotions, 0 new accepted replacements, 0 candidates in normal canonical gameplay.
