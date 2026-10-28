# Desk Strategy 3 — TRELLIS.2 v030

**Historical disposition:** `desk-v030` was blocked before inference by a gated-model access requirement. This candidate remains preserved as historical evidence; Hugging Face DINOv3 access was later authorized.

## Strategy identity

`strategy_3_trellis2_4b_o_voxel_joint_image_to_3d_and_pbr_generation` uses Microsoft's TRELLIS.2 4B image-to-3D cascade to generate detailed geometry and base-color, metallic, roughness, and alpha attributes together, then exports O-Voxel output to a PBR GLB. This is materially different from Strategy 1's source-measured Blender assembly from boxes/cylinders and Strategy 2's Hunyuan3D 2.1 mesh followed by a separate PaintPBR stage. It has a credible chance to improve geometry continuity and material correspondence because both are generated from the source-conditioned view by the same model family.

## Candidate and evidence

- Candidate: `desk-v030`, parent `desk-v029`; preserve `desk-v007` as incumbent.
- Durable recipe: `art/desk/iterations/v030/recipe.json` and `art/desk/recipes/v030.json`.
- Generator: `scripts/art_factory/generators/trellis2_desk_v030.py`.
- Candidate record: `art/desk/iterations/v030/candidate.json`.
- Generation log: `art/desk/iterations/v030/generation.log`.
- Local TRELLIS.2 source revision: `75fbf0183001ed9876c8dbb35de6b68552ee08bd`.
- Pinned 4B model snapshot: `af44b45f2e35a493886929c6d786e563ec68364d`, downloaded locally.
- Hardware: RTX 5090 (SM 12.0), Windows Python 3.12, Torch 2.10.0+cu130. CUDA inference/export imports and the O-Voxel CUDA runtime dependency had been resolved before this run.

The generator loaded the TRELLIS.2 pipeline and failed while loading its required `facebook/dinov3-vitl16-pretrain-lvd1689m` image conditioner. Hugging Face returned HTTP 401 for the model's `config.json` and reported that the repository is gated and requires access plus authentication. The failure occurs before image conditioning, geometry inference, or export. The Art Factory recorded `desk-v030` as blocked; it has no generated mesh, technical integration result, standardized production renders, or visual evaluation.

## Gate result and next step

No visual gate score is assigned because there is no production candidate to inspect. Strategies 1 and 2 remain the two failed visual strategies. Strategy 3 is pending the exact external prerequisite; therefore Desk has not reached its three-strategy plateau and is not PASS.

To resume: while logged into Hugging Face, open [the DINOv3 model page](https://huggingface.co/facebook/dinov3-vitl16-pretrain-lvd1689m), review the gated-model terms, submit the access request, and wait for approval if required. Then authenticate locally with `hf auth login` so the TRELLIS.2 process can use the granted access. Hugging Face requires a signed-in user to request gated access and a local authenticated session for script downloads; approval may be manual ([gated-model access instructions](https://huggingface.co/docs/hub/models-gated), [CLI authentication](https://huggingface.co/docs/huggingface_hub/en/guides/cli)). Do not send a token in chat.

## Post-access continuation — v031 and v032

Hugging Face DINOv3 access was authorized and verified locally on 2026-10-27. Fresh `desk-v031` completed the pinned TRELLIS.2 4B 1024-cascade generation using the intended DINOv3 conditioner, public BiRefNet, the local SDPA compatibility adapter, and seed 26031. It produced a 298,779-triangle mesh and native O-Voxel PBR output. The first technical-validation command failed because the recipe listed `conditioning-preprocessed.png` before `desk.tscn`, and Art Factory treated the first output as the primary asset. Preserve the failed package unchanged at `art/desk/iterations/v031/`.

Fresh `desk-v032` is a packaging-only repair: it reuses the exact v031 generated mesh/PBR data, puts `desk.tscn` first, and rewrites GLB and wrapper references to the v032 folder. Godot 4.7.2 validates one mesh, one surface, 298,779 triangles, exact 66 × 30 × 30 inch bounds, and no issues. Six standard RoomScale production captures are in `art/desk/iterations/v032/render-runs/run-001/`.

The visual result is a recognizable full-size sit-stand desk with a broad thin top and support frame, but the tabletop renders nearly black and materially flat, with only isolated ring-like highlights. The top's broad environmental reflections, finished glass edge, frame mounts, and support joins do not approach the source photograph. The recorded evaluation in `art/desk/iterations/v032/evaluation.json` is `continue`, comparison `worse` than `desk-v007`; it does not pass the repaired gate. Preserve `desk-v007`, do not promote v032, and continue with a new monotonic challenger that addresses both source-conditioned construction and measured glass/graphite PBR response. No pilot plateau is established.

Generated TRELLIS.2/DINOv3 weights and candidate outputs remain local pending license/publication review; do not publish them by default.
