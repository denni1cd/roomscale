# RoomScale — Production Reconciliation and 3D Art Quality Checkpoint

**Date:** 2026-11-09
**Review checkout:** `codex/roomscale-production-reconciliation` at pushed base `f27b6d1fecca4af11369f1663e3cd9d8a7f8c392`
**Factorium branch reviewed:** `feat/art-foundry-v1-20261108`, commit `4be0f1027f56f30032aafe7cf9a48e625c7bd95c`

## Decision

Choose **2. Augment RoomScale with selected Factorium capabilities**. Use its incremental evidence inventory, explicit feasibility checks, and two independent reviewers for major method recommendations. Keep RoomScale’s Visual Director, Art Factory, registry, and gameplay acceptance gates authoritative. Do not rewrite the existing Art Factory to imitate Factorium.

A separate, **bounded TRELLIS.2 trial** is justified for selected rigid, opaque, textured props. The tests do not justify replacing RoomScale’s 3D backend or resuming broad migration. The bookcase is a clear integrated visual improvement in a review-only production-scene capture. The desk is a technical pass that fails its glass-material target. Neither candidate is a production replacement.

Factorium’s two skills and handoff document were read from the requested branch: [art-investigator](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/skills/art-investigator/SKILL.md), [art-factory](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/skills/art-factory/SKILL.md), and [WORK_ART_FACTORY_HANDOFF](https://github.com/denni1cd/factorium/blob/feat/art-foundry-v1-20261108/docs/WORK_ART_FACTORY_HANDOFF.md). This report makes no merge claim and treats skill capabilities as unvalidated. The reviewed skills support 2D concept work, incremental inventories, verified tool availability, evidence states, and adversarial review. They do not supply a mesh generator, multiview reconstruction system, material repair, rigging, or Godot packaging.

## Checkpoint and pushed-state reconciliation

The last pushed production-deployment base is `origin/codex/art-factory-production-deployment` at `f27b6d1`. The new review worktree starts exactly there. Its canonical registry remains unchanged at 15 entries. No candidate was promoted.

| Existing checkout | HEAD / upstream state | Uncommitted state at checkpoint | Checkpoint |
|---|---|---|---|
| Root `codex/poc25-art-factory-review` | `333cee7`, 2 commits behind pushed `1e111d3` | 20 modified, 1 deleted, 0 staged, 6,661 recursive untracked files. The tracked diff is 1,278 insertions / 313 deletions. | `poc25/status.txt`, diff, and untracked manifest saved. |
| `codex/art-factory-production-deployment` | `388ed7e`; 22 ahead and 22 behind pushed `f27b6d1` | 7 normalized tracked diffs plus 753 `.import` status-only/line-ending entries; 2,451 recursive untracked files. The committed tree differs from remote in `.gitattributes` plus five generated scene files (292 insertions / 17 deletions). | `art-deployment-local/status.txt`, diff, and untracked manifest saved. |
| `poc25-final-verification` detached checkout | Pushed `1e111d3` | 757 `.import`/import-sidecar status modifications with no normalized content diff; 163 untracked (120 `.import`, 29 `.uid`, 14 `.png`). | Full status/diff/manifests saved. |
| `poc56-stabilization`, `roomscale-stabilization`, `spectator-director` | Detached at `1d7388f` | Each has one deletion: `verification/poc3/aphrael-session.json`. | Status and patch saved for each. |
| Temporary POC56 baseline and fast-full checkouts | Both detached at `b4a0f75` | Each reports 4,978 tracked deletions (5,362,780 deleted lines); no untracked files. These checkouts were left untouched; manifests and base SHAs were saved, and the deleted content is recoverable from each base commit. |
| `poc2-exterior-data` | Detached at `1d7388f` | Clean. | No changes. |
| New `codex/roomscale-production-reconciliation` | Exactly pushed base `f27b6d1` | No normalized tracked content diff. Git status reports 971 modified tracked `.import` sidecars (no normalized content difference) and 2,438 untracked files: 2,298 `.import`, 97 `.png`, 39 `.uid`, and 4 `.glb`. Default porcelain collapses the files under two verification directories, so it displays 2,416 untracked path entries. The PNGs include extracted/generated material textures and review images. Test assets and review outputs are uncommitted and noncanonical. | Status/diff/manifests saved. |

The initial root and local-deployment checkpoints were saved before the tests. Additional worktree manifests are in `C:/Users/Zero/.codex/checkpoints/roomscale-2026-11-09-pre-reconciliation/worktree-census/`. Originals remain in their existing worktrees; no reset, clean, stash, rebase, or force push was performed. Exact path lists are in the checkpoint files.

### Existing production inventory

The pushed deployment registry contains 15 canonical entries. The existing project inventory records 95 art classes across 21 RoomDefinitions and 318 object records; 48 Tier 1, 11 Tier 2, and 36 Tier 3; 70 classes remain procedural/programmer art. The previous Desk/Citizen/Grapple histories recorded 134 generated model outputs, 101 technical passes, 92 evaluation files, 926 render PNGs, and zero strict accepted replacements. These counts are the prior baseline; the current experiment adds two model generations.

Current canonical IDs remain: `citizen-v007`, `desk-v007`, `display_cabinet-v003`, `grapple-v006`, `hammock_with_stand-v005`, `office_chair-v003`, `rocking_chair-v003`, `room_bookcase_production-v001`, `room_photo_window_production-v004`, `room_shell_floor-v003`, `room_shell_wall_finish-v002`, `settlement_depot-v005`, `settlement_housing-v004`, `settlement_workarea-v005`, `settlement_workshop-v004`.

## Representative production-method test

Both approved RoomScale targets were sent to the live Microsoft `microsoft/TRELLIS.2` Space, revision `ebf60b20fc5a4607f90a1c11c0aab0ceeda5429d`, reported `zero-a10g`. No local inference was started. The run path was `/preprocess_image` → `/image_to_3d` → `/extract_glb`. TRELLIS.2 and the hosted execution—not Factorium—provided 3D inference.

| Asset | Approved image | Raw generation | Blender finish | Godot technical check | Visual result at gameplay distance |
|---|---|---|---|---|---|
| Room A household bookcase | `art/bookcase/visual_director/round-01/candidate-bookcase-r01.png` | 70.521 s end to end; 40.713 s shape/material inference; 97,001 triangles | Full output plus 25% decimation: one mesh, 24,250 triangles, two embedded 2048² PBR textures converted WebP→PNG, exact 32×63×17 in envelope, 8.11 MB. The 10% variant is 9,700 triangles and visibly damages the side panels. | Full, 10%, and 25% variants all pass Godot 4.7.2 validation. The selected 25% variant: one mesh/surface, 24,250 triangles, exact bounds. | At matched 73.08 in in Room A, the 25% candidate reads as a more complete bookcase than the procedural incumbent: framed side panels, crown/plinth, shelves and varied books. Improvement is visible in the Godot production scene. Review-only; not promoted. |
| Dark glass computer desk | `art/desk/visual_director/round-01/incumbent-edit-r01.png` | 52.625 s total; 24.281 s inference; 99,687 triangles; raw GLB 3.86 MB | 10% decimation to 9,968 triangles; one mesh/material; 2048² PBR textures converted to PNG; 65.956×30×29.875 in before RoomScale normalization. The resolver fits the registered 66×30×30 in envelope. | Godot 4.7.2 passes: one mesh/surface, 9,968 triangles, no technical issues. | At matched 72.18 in, candidate is black without the incumbent v007’s visible glass highlight. At 50.21 in, both read nearly black; the candidate does not improve the approved smoked-glass material. Review-only; not promoted. |

The desk raw GLB has `alphaMode: OPAQUE`, one material, and one mesh. The material has base-color and metallic/roughness textures, but Blender/Godot carry only one surface across the glass and frame. That preserves a PBR texture handoff; it does not preserve the required glass/graphite material hierarchy or reliable glass appearance.

The saved desk run script and console log retain a static `03-trellis2-bookcase.glb` filename even though the desk run record and hash refer to the renamed `03-trellis2-desk.glb`. The GLB and input hashes are recorded, and Blender used that hashed desk GLB, but the filename mismatch is a reproducibility caveat. Do not treat this run as a fully clean automated receipt.

## Matched Godot evidence and progress

All gameplay-distance captures are 1280×720, Godot 4.7.2, Compatibility renderer, in the real RoomScale production scene through a temporary `review_showcase` registry. The candidate outputs are visible in production-scene review renders; **neither is in canonical gameplay**, because neither was promoted.

| Matched phase | Candidate | Incumbent | Change |
|---|---:|---:|---:|
| Bookcase, 73.08 in | 26 draw calls; 73,026 primitives; 45 FPS | 109; 16,788; 45 FPS | 76% fewer draw calls, 4.35× primitives, same single-capture FPS. |
| Bookcase, 330 in room view | 925; 510,662; 2 FPS | 964; 494,092; 2 FPS | 4% fewer draw calls; 3.4% more primitives; same reported FPS. |
| Desk, 72.18 in | 483; 239,308; 25 FPS | 521; 219,388; 19 FPS | Fewer draw calls, 9% more primitives; snapshot FPS differs. No controlled performance conclusion. |
| Desk, 50.21 in | 222; 112,898; 30 FPS | 260; 83,394; 36 FPS | Fewer draw calls, 35% more primitives; candidate capture FPS is lower. |

These are render-harness snapshots, not a controlled performance benchmark. The decisive production progress is **2 new model generations, 2 asset-level Godot technical passes (4 finished-variant validation passes), 1 of 2 asset families with a clear integrated visual improvement, 0 canonical promotions, and 0 newly accepted production replacements**. This is more useful evidence than another 2D concept, but not evidence for a dependable replacement backend.

## Focused capability findings

- **Direct image-to-3D:** Fresh single-image inference succeeded for both inputs. The bookcase demonstrates a candidate that survives Blender and Godot and improves the actual integrated asset. The desk demonstrates the limit: acceptable geometry and a technical pass did not make the glass material read correctly.
- **Multiview reconstruction:** Not exercised in this test. RoomScale’s existing inventory already records multiview Pixal3D (`desk-v047`) and RecGen3D (`desk-v043`) failures, alongside earlier single-image TRELLIS.2, TripoSG, TripoSR, Hunyuan3D, and SUPRA-Tex failures. There is no new evidence that a multi-view path is production-ready.
- **Material transfer:** PBR textures survive the GLB→Blender→Godot handoff. Semantic separation does not: the desk is an opaque, single-material mesh and fails the glass target. The bookcase’s generated wood/material read is visibly acceptable at 73 in, but that does not establish generalized material transfer.
- **Blender finishing:** Tested real Blender 5.2.3 import, axis/scale normalization, grounding, texture conversion, decimation, and GLB export. It did not repair semantic geometry, create material regions, or author a glass response. The 10% decimation experiment shows that aggressive triangle reduction can introduce visible surface damage.
- **Godot gameplay-distance rendering:** Verified with the production resolver and same-room incumbent captures at 73 in for the bookcase and 72/50 in for the desk. Candidate registry mode was `review_showcase`; these captures are not canonical runtime acceptance.

## Independent feasibility reviews

Both independent reviewers examined the actual mesh, run path, Godot captures, and matched incumbents. Both answered **“Is this realistic?” — Conditional.**

- The production reviewer supports a narrow pilot for rigid opaque textured props, identifies the bookcase as a visible win, the desk as a material-transfer failure, and rejects backend replacement/broad migration.
- The technical reviewer independently supports a narrow pilot and noted the increased primitive counts, noncontrolled FPS readings, and desk filename-provenance inconsistency. A screenshot attribution discrepancy was checked against file hashes; the corrected comparison is: the candidate lacks the 72-inch incumbent highlight, and both are dark at 50 inches.

Neither reviewer recommends promoting either sample. The bookcase is promising, but still has no formal accepted rating, canonical registration, or normal-gameplay demonstration. The desk is not an improvement.

## Unresolved tests and release gates

1. No multiview reconstruction or cross-seed repeatability test was run. Existing multiview samples in the inventory failed.
2. No authored material transfer/repair was tested on the generated desk; its opaque single material fails the glass target. A candidate with a separate authored glass surface would need both 72- and 50-inch comparison against v007.
3. The bookcase needs a formal quality rating, a controlled performance comparison, and canonical/gameplay validation before promotion. The 25% mesh costs 4.35× the incumbent’s gameplay-view primitive count; the 10% version shows side-panel damage.
4. Neither candidate was promoted, exercised in normal canonical gameplay, or included in a release build. Strict accepted replacement count remains zero.
5. The existing broader validation items in `verification/poc25/FACTORIUM_REVIEW_2026-11-09.md` remain unresolved: Fast test stopped at Ruff with 327 existing lint findings; prior 50-citizen smoke had gameplay markers but failed its wrapper on headless null-material errors; current Verdant smoke was incomplete; POC3 hero sequence/style review is pending; POC3 runner and uncommitted POC5/combat-role changes lack a complete current regression receipt; POC56 independent review is pending. Prior Art Factory tests (20 unit tests and 11/11 canonical hashes) do not clear these runtime/art gates.

## Production gate classification

| Gate | Bookcase 25% | Desk 10% |
|---|---|---|
| Model generated by selected method | Pass | Pass |
| Blender finish and GLB export | Pass | Pass |
| RoomScale technical validation | Pass | Pass |
| Visually reviewed through production resolver at relevant distance | Pass, review-only | Pass, review-only |
| Clear improvement over incumbent | Yes at 73.08 in | No; glass read is lost at 72.18 in; no gain at 50.21 in |
| Canonical registry promotion | No | No |
| Visible in canonical gameplay | No | No |
| Successful production replacement | No | No |

**Final recommendation:** Option **2**. Adopt selected Factorium evidence/review practices alongside RoomScale’s existing infrastructure. Keep TRELLIS.2 as a bounded trial for opaque static props, require incumbent comparison in Godot, and keep both tested assets review-only. Do not replace the 3D backend or restart broad art migration.
