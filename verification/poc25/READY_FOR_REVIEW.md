# RoomScale POC 2.5 — READY FOR REVIEW

**Review state:** READY FOR REVIEW
**Pilot disposition:** Three-pilot acceptance is not satisfied. The independent review returned REPAIR REQUIRED; the evaluator and CI defects below have been repaired for follow-up review, while desk/citizen visual acceptance remains open.
**Baseline:** `1d7388f` on `main` (recorded before POC 2.5 implementation)
**Engine:** Godot 4.7.2, Compatibility renderer
**Scope note:** Strategerium, Adeptus Necroneerium, the approval gate, work-package hierarchy, and Rules Lawyer review were used as existing execution infrastructure. They are not RoomScale POC 2.5 technology or acceptance targets. The product under review is the RoomScale Art Factory and its production asset workflow.

## Delivered Art Factory

The repository now has a local, deterministic authoring pipeline under `scripts/art_factory/` for briefs, recipes, candidates, technical validation, production-path Godot renders, evidence-backed evaluations, stable-ID promotion, and registry hash verification. Generated `.tscn` assets are ordinary RoomScale content; gameplay does not call an art-generation service.

The desk, grapple, and citizen pilots retain challenger histories and production captures. Four settlement structures and four major room-furniture assets were also promoted after measured bounds checks and rendered evaluation. The workshop v004 roof revision exposes the boiler; workarea v005 restores the missing tool rack, bins, and lathe details. The accepted registry now resolves eleven assets: desk v007, grapple v006, citizen v007, workshop v004, depot v003, housing v002, workarea v005, office chair v003, rocking chair v003, hammock-with-stand v005, and display cabinet v002.

## Independent-review repair follow-up

The POC 2.5 hard visual gate now requires explicit answers and production-render evidence for: realistic-furniture read; close-inspection construction; edge treatment, joins, thickness, hardware, material response, surface variation, and manufacturing detail; plus source-photo character when a photograph exists. Unapproved low-poly, blocky, placeholder, primitive, simplified programmer-art, materially flat, or substantially stylized descriptions/flags block PASS unless the brief explicitly opts into stylization with a rationale. The three pilot briefs do not opt in.

Retroactive records are in `art/desk/iterations/v007/visual-gate-reassessment.json`, `art/grapple/iterations/v006/visual-gate-reassessment.json`, and `art/citizen/iterations/v007/visual-gate-reassessment.json`. `desk-v007` remains the best-so-far registry incumbent, but fails the repaired gate. The materially different CAD-like, 136-mesh/38,160-triangle PBR desk challenger `desk-v009` was production-rendered and rejected: its dark top reads flat/noisy, the photographed glass reflection character is not approached, and much of its added join/hardware detail is occluded. It is preserved as a failed challenger and did not replace v007. The eight-challenger desk budget is exhausted; `art/desk/iterations/v009/iteration-budget-disposition.json` records the cap and stop decision. Do not claim desk acceptance or create a ninth challenger without an approved budget change. `grapple-v006` passes the reassessed visual gate. `citizen-v007` remains in the registry but fails because its evaluation describes intentional stylization and its close render still reads as simplified block-form geometry. Keep incumbents and all history intact. No broad asset migration has begun.

The GitHub run `40256472981` for `04e75d2842346ff7262ca9268c37cdb2c4d75807` is classified in `final/ci-04e75d2-classification.md`. It exposed a Verdant/Clockwork citizen-art integration regression and a Windows CRLF registry-hash portability regression; both have code repairs and local regression coverage. Local rerun logs are in `final/repair-rerun/`.

## Acceptance Criteria Evidence Map

| Criterion | Status | Evidence / notes |
|---|---|---|
| AC-01 Approved Execution Contract | Satisfied by prior workflow | User authorized implementation with “Okay go for it” after the prior contract-review step. Contract workflow was not recreated here. |
| AC-02 Baseline Preserved | PASS | `baseline/RoomScale_POC_2.5_Baseline.md`; baseline commit, fast suite, Room A/B, canonical room, screenshots, and the known pre-existing graphical-launch redirect failure are recorded. |
| AC-03 No Manual Art Requirement | PASS | Candidates are produced by recorded local Godot recipes and scripts; see candidate `recipe.json` and `generation.log` files under `art/`. No user modeling, texturing, rigging, or cleanup is required. |
| AC-04 Art Factory Exists | PASS | `scripts/art_factory/` and `scripts/test_art_factory.py`; 18 unit tests pass after the visual-gate repair, including low-poly, blocky, and placeholder description/flag regressions. |
| AC-05 Durable Art Brief | PASS | Briefs are preserved under `art/` for the desk, grapple, citizen, four settlement structures, office chair, rocking chair, `hammock_with_stand`, and display cabinet. The hammock ID matches its stable RoomDefinition semantic identity. |
| AC-06 Recipe Preservation | PASS | Candidate-local `recipe.json` files preserve method, instructions, tool/version, parameters, inputs, and import settings. Failed and blocked attempts remain in iteration folders. |
| AC-07 Production Integration | PASS | `scripts/art_factory/render_harness.gd` resolves candidates through the production scene and records the exact path/candidate in receipts. |
| AC-08 Standardized Render Evidence | PASS | Candidate `render-runs/` folders contain room, settlement, profile, alternate interior, and detail captures; citizen and grapple include their gameplay/deployment views. The hammock uses a second interior oblique because a true opposite camera would leave the wall-side object outside the production room. |
| AC-09 Render Inspection | PASS | Production images were visually inspected before evaluation/promotion; see each accepted `evaluation.json` and referenced PNGs. |
| AC-10 Specific Diagnosis | PASS | Continued candidates record visible defects, likely causes, and targeted recipe changes; examples: workshop v002 and workarea v003 evaluations. |
| AC-11 Iterative Refinement | PASS | Desk, grapple, and citizen show multi-version recipe refinement; settlement workshop and workarea also preserve matched challenger cycles. |
| AC-12 Challenger vs Incumbent | PASS | Pilot evaluations identify best-so-far candidates; workshop v004 is compared with v002 and workarea v005 with v003 under equivalent current renderer/camera settings. Technically failed/blocked candidates are not mislabeled as visual incumbents. |
| AC-13 Best-So-Far Preservation | PASS | `scripts/art_factory/factory.py` gates promotion against the registry incumbent, comparison result, and score regressions; rejected/blocked candidate folders remain. |
| AC-14 Evidence-Based Scoring | PASS | Accepted and continued `evaluation.json` records provide an observation for each applicable rubric score and link registered production renders. |
| AC-15 Hard Anti-Blockiness Gate | REPAIRED; pilot gate unresolved | Evaluator now requires explicit neutral-read, close-inspection, craftsmanship, and photo-character answers and blocks unapproved style flags or affirmative style descriptions. Reassessment: grapple passes; desk and citizen fail. |
| AC-16 Desk Pilot Pass | FAIL — repair required | Preserve `desk-v007` as best-so-far. `desk-v009` is the distinct CAD/PBR challenger; its matched production renders and evaluation show no visual pass and score source resemblance 2/5. Eight challenger attempts are exhausted. Gameplay geometry remains RoomDefinition-owned. |
| AC-17 Grapple Pilot Pass | PASS — visual gate reassessed | `art/grapple/iterations/v006/visual-gate-reassessment.json` records affirmative answers across the visual gate with matched close/deployment evidence. Production traversal is exercised by the recorded smoke evidence and current Room A/Room B reruns. |
| AC-18 Citizen Pilot Pass | FAIL — repair required | `art/citizen/iterations/v007/visual-gate-reassessment.json` rejects the unapproved stylized/block-form read. Preserve the current registry entry and history; the pilot does not pass visual acceptance. |
| AC-19 Factory Generality | PASS | Evidence spans photo-derived furniture, steampunk traversal machinery, miniature citizens, four settlement structures, and four major room-furniture types using shared factory contracts and production resolution. |
| AC-20 Realistic Materials | PARTIAL — pilot repair required | Grapple passes its reassessment. Desk v009 glass reads materially flat and citizen v007 still reads stylized; neither pilot may pass on material polish or polish scores alone. |
| AC-21 Scale Fidelity | PASS | Godot bounds reports and accepted registry dimensions preserve all eleven asset brief envelopes; the rocking-chair runner bottom measures 0.032 inches above the floor, and the 50-citizen presentation smoke checks the half-inch limit. |
| AC-22 Source Resemblance | FAIL for desk | The repaired reassessment and `desk-v009` matched render comparison show silhouette similarity without the source photo's reflected glass character; v009 scores source resemblance 2/5. |
| AC-23 Gameplay Geometry Independence | PASS | Room A, Room B, and canonical smokes verify navigation, target surfaces, deliveries, construction, traversal, and citizen motion while generated visual scenes remain presentation-only. |
| AC-24 No Room-Specific Gameplay Hack | PASS | Stable semantic IDs resolve through the general visual layer; the same production checks pass in Room A, Room B, and the reconstructed room. |
| AC-25 Asset Resolution | PASS | `art/registry.json`; `final/presentation-test.log` confirms four settlement assets and the four canonical-room furniture assets resolve by stable ID and candidate ID. |
| AC-26 Failure Visibility | PASS | `final/visual-resolver-test.log` proves a missing accepted asset reports required failure without invoking fallback. Presentation test asserts accepted settlement and furniture art paths/candidate IDs with no fallback. |
| AC-27 Reversible Promotion | PASS | Promotion changes a stable registry entry while retaining all candidate files and legacy presentation paths; accepted scene files are not embedded in gameplay logic. |
| AC-28 Rendering Upgrade | PARTIAL — review | `scripts/pipeline_proof.gd` applies bounded key/fill, shadow, glow, tonemap, and 4× MSAA settings; final room/settlement/citizen captures and performance data are present. Hard shadows and the live green construction marker remain visible; the captures do not establish a clean improvement at every room scale. |
| AC-29 Full Major-Asset Upgrade | PARTIAL — review | The desk/grapple/citizen pilots, four settlement structures, office chair, rocking chair, hammock-with-stand, and display cabinet now resolve accepted Art Factory assets. Broad room surfaces and other props such as the floor lamp, floor seat, and collectibles remain on the existing detail path, so a complete room-wide migration is not proven. |
| AC-30 50 Citizens Remain Functional | PASS | Room A, Room B, canonical smoke, and `final/presentation-test.log` all report 50 production citizens. |
| AC-31 Navigation Regression | PASS | `final/room-a-smoke.log`, `final/room-b-smoke.log`, `final/canonical-room-smoke.log`, plus fast RoomDefinition/navigation suite. |
| AC-32 Construction Regression | PASS | Same smoke logs show 11 physically delivered units, all three construction stages, 100% progress, and builder return to normal work. |
| AC-33 Traversal Regression | PASS | Same smoke logs record visible partial deployment, live floor-to-target connection, citizen traversal, and follow-on exploration. |
| AC-34 Room Portability Regression | PASS | Room A and Room B smoke logs pass independently with their different dimensions, obstacles, targets, and routes. |
| AC-35 Reconstructed Room Regression | PASS | `final/canonical-room-smoke.log` loads the canonical `room_photo_luna` RoomDefinition and passes navigation, construction, grapple traversal, and 50-citizen activity. |
| AC-36 Runtime AI Independence | PASS | Runtime loads the accepted local `.tscn` scenes through `art/registry.json`; generation scripts and authoring tools are not runtime dependencies. |
| AC-37 Performance Evidence | PASS with review note | Two real Godot 4.7.2 Compatibility-renderer runs with VSync disabled are recorded: standard Room A in `final/final-performance.json` and the furnished canonical `room_photo_luna` in `final/canonical-performance.json`. Each measured room, settlement, and citizen view with 50 citizens. Room A: 322/351/261 FPS, 1,091/1,243/3,092 draws, 469k/641k/1.18m primitives, and 3.743/3.421/4.714 ms p95 frame times. Canonical furnished room: 273/331/362 FPS, 1,397/1,560/1,059 draws, 620k/809k/698k primitives, and 4.347/3.523/3.392 ms p95. These are different scenes and camera/view configurations, so the counts are not a direct before/after comparison. Both runs stayed above 60 FPS on the test machine. |
| AC-38 Durable History | PASS | `art/` preserves briefs, recipes, candidates, technical reports, renders, evaluations, registry, and rejected/blocked attempts, including the furniture scale, canvas, and parser failures. `final/` holds regression and performance logs. |
| AC-39 Independent Completion Review | READY FOR REVIEW | Follow-up review is requested after the repairs recorded here. Desk and citizen remain unresolved; no self-declared completion is made. |
| AC-40 No Fake Pass | PASS | Promotion requires technical validation, recorded evaluation, registered production render, and passing rubric; smoke tests verify resolved candidate IDs and live gameplay behavior. |

## Final Verification Results

- Art Factory unit tests: **18 passed** after the repair (`final/repair-rerun/` test invocation; prior 14-test baseline log retained).
- Repository fast deterministic suite: **PASS** (`final/fast-rerun/` and `final/fast-suite-rerun.log`). It was rerun after the Art Factory runtime-error guard was added, using the existing `.venv` Python because the shell's default Python does not have Ruff installed.
- Visual resolver including Windows CRLF canonical hashing: **PASS** (`final/repair-rerun/visual-resolver.log`).
- Room A, Room B, canonical reconstructed room: **PASS** (`final/room-a-smoke.log`, `final/room-b-smoke.log`, `final/canonical-room-smoke.log`).
- Accepted registry hashes: **11/11 verified** after line-ending normalization (`final/repair-rerun/registry-verify.log`).
- Final accepted captures: desk v007, grapple v006, citizen v007 (final production run-005), four settlement assets, and the four major room-furniture assets have production renders and recorded evaluations. `final/render-citizen-v007-final.log` records the post-promotion canonical-room capture.

## Known Review Items

1. AC-29 is partial because broad room surfaces and several other props have not been migrated through accepted Art Factory assets.
2. AC-28 needs independent judgment: lighting and anti-aliasing were changed and final views captured, but strong hard shadows and the live green construction marker remain visible.
3. Performance is hardware- and scene-dependent. On the test RTX 5090, both runs exceed 60 FPS and all p95 frame times are below 5 ms; the standard Room A citizen view reports 3,092 draws while the canonical furnished-room citizen view reports 1,059. Their different scene and view configurations prevent a direct comparison, and these numbers do not establish performance on other hardware.
4. The baseline report records a pre-existing graphical-launch redirect failure. It was not attributed to POC 2.5 and remains separate from the passing production smoke evidence.

**Requested external disposition:** `COMPLETE`, `REPAIR REQUIRED`, `BLOCKED`, or `CONTRACT DEFECT`.

### Repair rerun results

- Art Factory unit suite: **18 passed**; Ruff checks pass after the explicit-answer and style-language gate changes.
- Fast deterministic Godot suite: **PASS** (`final/repair-rerun/fast.log`).
- Civilization definitions and Verdant presentation contract: **PASS** (`final/repair-rerun/civilizations/`).
- Clockwork Room A smoke: **PASS**, 50 citizens, navigation, deliveries, construction, grapple traversal, and M6 exploration (`final/repair-rerun/smoke-room_a-clockwork.log`).
- Verdant Room A smoke: **FAIL — prerequisite/out-of-scope dirty POC 3/5 worktree issue**, not a POC 2.5 regression. The modified construction code deploys to `current_project.destination_position` while the Verdant visual anchor follows `target_anchor`; CI run 40256472981 was on committed `04e75d2`, whose construction system does not contain that divergence. See `final/ci-04e75d2-classification.md`. The unrelated edits remain untouched.
- Clockwork Room B smoke: rerun underway at report preparation; result will be recorded after completion.
- GitHub remote rerun on the repair commit: required after push; not yet observed.
