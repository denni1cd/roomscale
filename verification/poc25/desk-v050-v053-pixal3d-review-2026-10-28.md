# Desk Pixal3D Source-Photo Challenger Review — 2026-10-28

## Disposition

`desk-v052` completed the intended Pixal3D single-image source-photo pipeline, passed Godot technical validation, and produced all six RoomScale production captures. A targeted source-view and FOV refinement in `desk-v053` used a clearer photo of the same desk, then completed the same inference, validation, and six-view production review. Both candidates are rejected by the repaired strict visual gate and are worse than the retained `desk-v007` incumbent. v053 has a more visible textured top, but it remains a warped slab with fragmented supports and no believable manufactured frame; neither render is a near-pass.

No registry entry, gameplay geometry, prior candidate, or incumbent was changed. Preserve `desk-v007` and all four attempts below. The source-photo Pixal3D strategy is not evidence of a Desk pass or plateau.

## Append-only attempt history

| Candidate | Result | Evidence |
|---|---|---|
| `desk-v050` | Blocked before inference because the generator pointed to `.tools/blender-5.2.3/blender.exe`, while the installed executable is nested under `blender-5.2.3-windows-x64`. | `art/desk/iterations/v050/candidate.json`, `generation.log` |
| `desk-v051` | Pixal3D inference completed and Blender packaged the GLB, but the generator then failed while writing final evidence because `fov_estimate_caveat` was absent from the inference record. No validation or visual result was assigned to this attempt. | `art/desk/iterations/v051/candidate.json`, `generation.log`, `generated/pixal3d_raw_desk.glb`, `generated/desk.glb` |
| `desk-v052` | Generation and packaging passed; Godot import/technical validation passed; six production views were captured; strict evaluation rejected the asset. | `art/desk/iterations/v052/candidate.json`, `technical-validation.json`, `render-runs/run-001/receipt.json`, `evaluation.json` |
| `desk-v053` | A geometry-focused refinement used the less-occluded `Sample (3).jpg` view, a documented desk-only mask, a crop-width-scaled FOV estimate, and a fresh seed. Generation/packaging, Godot validation, and all six production captures passed; strict evaluation still rejected the malformed geometry and weak source resemblance. | `art/desk/iterations/v053/candidate.json`, `technical-validation.json`, `render-runs/run-001/receipt.json`, `evaluation.json` |

The follow-on attempts use versioned generator/recipe files, so the v050 and v051 failures remain intact. The v051 fix changed the Blender path; the v052 fix added the explicit FOV caveat and used a fresh seed. The v053 crop is reproduced by `scripts/art_factory/generators/prepare_pixal3d_desk_v053_input.py`; the FOV uncertainty is explicit.

## Pinned method and inputs

- Model: TencentARC Pixal3D, pinned to `b0cb2e1b794cab9aa0ac38a95d794a4d9337437f` and official source commit `f7cf38429b0bd264f1995f0f8743a88b1c728b94`.
- Method: official single-image pixel-aligned geometry with generated O-Voxel PBR attributes; 1536 cascade, 12 steps for sparse structure, both shape stages, and texture, seed `50052`.
- Conditioning: v052 used a direct pixel crop from `photo_holder/Sample (2).jpg` with 8.07% desk mask coverage and an estimated 0.35-radian FOV. v053 used a less-occluded view of the same desk from `photo_holder/Sample (3).jpg`; its hand-authored mask retains visible desktop, column, and T-foot pixels at 9.348% coverage and excludes monitors and separate props. The 0.53-radian FOV scales the previous crop estimate by crop width; neither source image has focal-length or sensor metadata.
- Conditioner: Pixal3D's configured DINOv3 projection conditioner, pinned to `camenduru/dinov3-vitl16-pretrain-lvd1689m@3c276edd87d6f6e569ff0c4400e086807d0f3881`; no newer encoder was substituted. Separately, the TRELLIS.2 source-photo candidate `desk-v048` used its intended Facebook DINOv3 backbone and no encoder substitution.
- Model weights, generated meshes, texture maps, and captures remain local.

## Integration and production evidence

`desk-v052` generated a 13,019,884-byte raw GLB and a 13,094,240-byte packaged GLB. `desk-v053` packages 298,541 triangles into one mesh/surface with 4K generated textures and exact 66 × 30 × 30-inch bounds. Both pass Godot 4.7.2 Compatibility import with no reported issues and floor contact at Y=0. RoomDefinition and gameplay geometry are unchanged.

The production harness captured `room-scale`, `settlement-scale`, `asset-three-quarter`, `asset-opposite-three-quarter`, `asset-profile`, and `asset-detail` under each candidate's `render-runs/run-001/`. v052 reports 14 FPS for room/settlement and 44 FPS for detail; v053 reports 2 FPS for room/settlement and 40 FPS for asset views. The v053 settlement capture reports 2,644,446 primitives. These are harness observations, not warmed performance benchmarks.

Visual review of the actual captures finds:

- **Realistic furniture:** No. The output does not read as a manufactured desk; wide dark sheets, jagged fragments, and dangling forms dominate.
- **Close inspection:** No. The detail and profile views expose malformed edges, fused surfaces, and incoherent supports.
- **Manufacturing and material quality:** No. A coherent glass edge, tabletop thickness, top-to-column joins, lift hardware, T-feet, fasteners, or distinct glass/graphite material response are absent.
- **Photographic character:** No. The source has a thin smoked-glass top on a distinct standing frame. The production render does not approach that object character.

`art/desk/iterations/v052/evaluation.json` and `v053/evaluation.json` record the explicit gate answers, failed craft checks, score observations, all six registered production renders, and reject decisions versus `desk-v007`. v052 is nearly black; v053 has more visible surface texture but visibly warped, fragmented geometry and supports. Both fail realistic-furniture read, close inspection, workmanship, and photo-character. See the `asset-detail.png` files under each candidate's `render-runs/run-001/` folder.

## Other independent method evidence

- Hunyuan3D 2.1 image-conditioned geometry plus PaintPBR is already represented by `desk-v028` and a text-guided material refinement `desk-v029`. Both have technical and production evidence but fail strict realism, workmanship, and photo-character gates. A shader-only or caption-only repeat is not justified.
- RecGen3D `desk-v043` completed multi-view reconstruction and production capture, but fails the realistic-glass/source-character and tabletop-anchor checks.
- Pixal3D multiview `desk-v047` completed production review and also failed construction, material, source-character, and performance criteria.
- Step1X-3D remains a character-specific preflight item, not a Desk substitute. Its host build prerequisites and rig-integration gap are recorded in `step1x-3d-preflight-2026-10-28.md`.

The relevant earlier CI report remains `final/ci-04e75d2-classification.md`: the failures on run `40256472981` are classified as the Clockwork-to-Verdant integration regression and Windows line-ending-sensitive registry-hash regression, with Windows checkout behavior as the trigger for the latter. Both repairs are covered by accepted all-six-job run `40417656855`. These local generated asset attempts did not change runtime integration code, so they provide no new CI-regression evidence.

## Next step

Keep `desk-v007` as incumbent. The less-occluded source crop/FOV refinement did not repair Pixal3D geometry, so do not spend another attempt on a minor crop, clearcoat, rim, or other shader-only tuning. Compare materially different geometry capabilities and existing Hunyuan3D 2.1/RecGen3D evidence before choosing the next challenger. Desk is not declared plateaued, and broad migration remains gated on all three pilots passing.
