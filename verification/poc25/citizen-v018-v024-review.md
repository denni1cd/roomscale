# Citizen — v018 result and TRELLIS.2 Strategy 3 access investigation

**Historical disposition:** Strategy 2 failed its visual gate. Strategy 3 was initially blocked by gated DINOv3 access, which was later authorized. The history below remains unchanged; post-access candidates are summarized at the end. Preserve `citizen-v007` as the best-so-far incumbent.

## Strategy 2 — Hunyuan3D 2.1 plus PaintPBR, v012–v018

The materially distinct method replaced citizen-v007's primitive body construction with a generated single-image Hunyuan3D 2.1 mesh, painted PBR maps, and candidate-local rig packaging. v012–v017 record fit, paint, topology, and coordinate/split iterations. v017's actual production renders remained fragmented, so v018 tested a specific axis hypothesis: normalize the Z-up painted mesh to RoomScale Y-up before fitting and six-region rig splitting.

v018 passed Godot integration and the required dimensional check (approximately 0.2613 × 0.5018 × 0.2099 inches), retained six mesh parts, and contained 73,015 triangles. The standard production render completed in `art/citizen/iterations/v018/render-runs/run-001/`. The detail, three-quarter, and gameplay-distance views still show fragments and detached rectangular sheets, rather than a coherent clockwork worker. The recorded evaluation is `art/citizen/iterations/v018/evaluation.json` and rejects v018 as worse than v007.

Topology inspection found 82,000 connected components. The two largest components are near-full-height thin rectangular sheets spanning about 0.258 × 0.500 inches and only 0.0048–0.0055 inches thick. Axis normalization fixed the orientation but cannot remove image/backdrop sheet geometry embedded in the source mesh. Additional axis or shader changes would not address this cause. Keep the v018 source mesh, generated maps, production captures, and diagnostic render local: the Hunyuan3D 2.1 model license restricts distribution of model outputs. Paths and findings are recorded here without including those binary outputs in a public review package.

## Strategy 3 — TRELLIS.2, v019–v024

TRELLIS.2 was selected as a materially different image-to-3D geometry and joint-PBR generation capability, with a target of preserving the Citizen's six-pivot runtime contract. The pinned TRELLIS.2 source and 4B model are available locally. The default image conditioner, `facebook/dinov3-vitl16-pretrain-lvd1689m`, is gated and returned HTTP 401 before inference in v019.

The following attempts tested whether the blocked conditioner could be replaced with public DINOv2 while retaining public BiRefNet for background removal:

| Candidate | Investigation | Result |
|---|---|---|
| v019 | Default DINOv3 and Bria pipeline | Blocked before inference by gated DINOv3 access (HTTP 401). |
| v020 | Public DINOv2 and BiRefNet configuration | Pipeline import reached public BiRefNet but stopped because `timm` was missing. |
| v021 | Installed `timm` in the ignored local environment and retried | Sparse-structure sampling began; failed because `flash_attn` was unavailable. |
| v022 | Tried xFormers attention on RTX 5090 / SM 12.0 | Backend unsupported by installed Torch/GPU; removed the incompatible local package. |
| v023 | Added local padded-window PyTorch SDPA adapter to preserve sparse window isolation | Sparse-structure stage completed; the shape stage then failed in TRELLIS.2's `VarLenTensor.to_dense()` list/tuple implementation. |
| v024 | Patched adapter to invoke the base dense conversion implementation | Sparse-structure sampling completed, but the shape sampler received empty sparse coordinates and failed with `max(): Expected reduction dim ... input.numel() == 0`. No mesh was produced. |

The progression confirms the local attention and setup obstacles can be repaired, but DINOv2 conditioning is not compatible with the trained TRELLIS.2 shape conditioner: the pipeline generates an empty structure/shape representation. v020–v024 therefore do not constitute a viable visual challenger or separate successful strategy. No candidate in v019–v024 has a generated Citizen mesh, RoomScale integration, or production render.

## Historical external access boundary

The same missing DINOv3 access prevents both Desk v030 and Citizen Strategy 3 from proceeding. A Hugging Face account holder must open [the DINOv3 model page](https://huggingface.co/facebook/dinov3-vitl16-pretrain-lvd1689m), review the gated-model terms, submit the request, and wait for approval if the authors require it. Once approved, authenticate locally with `hf auth login` so the TRELLIS.2 Python environment can download the model. Hugging Face documents browser-based requests for gated models and local authentication for scripted downloads ([gated-model access instructions](https://huggingface.co/docs/hub/models-gated), [CLI authentication](https://huggingface.co/docs/huggingface_hub/en/guides/cli)). Do not send an access token in chat. The public BiRefNet substitute is configured; separate Bria gated access is not needed.

After the DINOv3 model is accessible, continue with a fresh monotonic Citizen candidate ID, preserve the five-pivot rig, and evaluate actual production captures against `citizen-v007`. This was the remaining action when this investigation was first written; it has since been completed.

## Post-access continuation — Citizen v025–v028

DINOv3 access and local authentication were verified on 2026-10-27. Fresh `citizen-v025` completed DINOv3-conditioned TRELLIS.2 inference and exported a mesh, but the fitter failed on a Trimesh-versus-Scene API assumption. Fresh `citizen-v026` repaired that postprocessor, generated a coherent unsplit body (167,103 triangles), passed Godot validation, and produced actual RoomScale captures. Its six-region package rendered as separated head/hat, torso, arms, and boots because the candidate root applied a 90-degree X basis conversion while `CitizenAgent` resets named pivot positions in RoomScale Y-up coordinates. The full production evaluation is `art/citizen/iterations/v026/evaluation.json` and rejects the package while identifying this rig-space mismatch as repairable.

Fresh `citizen-v027` placed the basis conversion on visual children under direct named pivot nodes. Generation succeeded, but Godot validation rejected the six empty `MeshInstance3D` pivot nodes required by the existing adapter. The attempt is preserved at `art/citizen/iterations/v027/`.

Fresh `citizen-v028` bakes the basis conversion into vertex, normal, and tangent arrays while keeping the five named `MeshInstance3D` pivots unrotated in RoomScale Y-up space. Godot 4.7.2 validates six mesh surfaces, 36,500 triangles, and 0.26046 × 0.50085 × 0.21089 inch bounds. The production render harness verifies all 50 active citizens use `citizen-v028`; the actual figure remains coherent in the room, settlement, gameplay-distance, and close captures. Its evaluation (`art/citizen/iterations/v028/evaluation.json`) is `continue`, comparison `better` than v007, because irregular shoulder/cuff/belt edges, mottled material response, and unclear face/goggle finish fail the close craftsmanship gate. Preserve `citizen-v007`; do not promote v028.

This resolves the access boundary but not the Citizen pilot. TRELLIS.2 Strategy 3 has produced a viable integrated figure, so the earlier shredded-mesh failures do not establish an evidence-backed plateau. Continue with a fresh candidate using a method that improves close facial, hardware, join, and garment fidelity. Keep generated TRELLIS.2/DINOv3 outputs local pending license/publication review.
