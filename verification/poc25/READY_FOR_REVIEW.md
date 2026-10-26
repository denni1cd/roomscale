# RoomScale POC 2.5 — READY FOR REVIEW

**Review state:** READY FOR REVIEW
**Baseline:** `1d7388f` on `main` (recorded before POC 2.5 implementation)
**Engine:** Godot 4.7.2, Compatibility renderer
**Scope note:** Strategerium, Adeptus Necroneerium, the approval gate, work-package hierarchy, and Rules Lawyer review were used as existing execution infrastructure. They are not RoomScale POC 2.5 technology or acceptance targets. The product under review is the RoomScale Art Factory and its production asset workflow.

## Delivered Art Factory

The repository now has a local, deterministic authoring pipeline under `scripts/art_factory/` for briefs, recipes, candidates, technical validation, production-path Godot renders, evidence-backed evaluations, stable-ID promotion, and registry hash verification. Generated `.tscn` assets are ordinary RoomScale content; gameplay does not call an art-generation service.

The desk, grapple, and citizen pilots retain challenger histories and production captures. Four settlement structures and four major room-furniture assets were also promoted after measured bounds checks and rendered evaluation. The workshop v004 roof revision exposes the boiler; workarea v005 restores the missing tool rack, bins, and lathe details. The accepted registry now resolves eleven assets: desk v007, grapple v006, citizen v007, workshop v004, depot v003, housing v002, workarea v005, office chair v003, rocking chair v003, hammock-with-stand v005, and display cabinet v002.

## Acceptance Criteria Evidence Map

| Criterion | Status | Evidence / notes |
|---|---|---|
| AC-01 Approved Execution Contract | Satisfied by prior workflow | User authorized implementation with “Okay go for it” after the prior contract-review step. Contract workflow was not recreated here. |
| AC-02 Baseline Preserved | PASS | `baseline/RoomScale_POC_2.5_Baseline.md`; baseline commit, fast suite, Room A/B, canonical room, screenshots, and the known pre-existing graphical-launch redirect failure are recorded. |
| AC-03 No Manual Art Requirement | PASS | Candidates are produced by recorded local Godot recipes and scripts; see candidate `recipe.json` and `generation.log` files under `art/`. No user modeling, texturing, rigging, or cleanup is required. |
| AC-04 Art Factory Exists | PASS | `scripts/art_factory/` and `scripts/test_art_factory.py`; 14 unit tests passed, including the zero-exit GDScript error regression. |
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
| AC-15 Hard Anti-Blockiness Gate | PASS for promoted assets | Promotion validation rejects below-threshold scores and hard-fail reasons. Accepted pilot/structure evaluations contain no hard visual fails. Broader room migration remains open under AC-29. |
| AC-16 Desk Pilot Pass | PASS | `art/desk/iterations/v007/evaluation.json`, validation, final `render-runs/run-003/`, and `final/room-a-smoke.log` / canonical smoke. Desk dimensions and gameplay data remain RoomDefinition-owned. |
| AC-17 Grapple Pilot Pass | PASS | `art/grapple/iterations/v006/evaluation.json`; final `render-runs/run-003/` includes construction, deployment, and completed views. Room A, Room B, and canonical smoke prove the real cable traversal. |
| AC-18 Citizen Pilot Pass | PASS | `art/citizen/iterations/v007/evaluation.json`; final `render-runs/run-005/` includes gameplay-distance and detail views after promotion. Presentation test confirms all 50 production citizens use the accepted asset and animated pivots. |
| AC-19 Factory Generality | PASS | Evidence spans photo-derived furniture, steampunk traversal machinery, miniature citizens, four settlement structures, and four major room-furniture types using shared factory contracts and production resolution. |
| AC-20 Realistic Materials | PASS for promoted assets | Desk, grapple, citizen, structures, and furniture evaluations document distinct glass, cloth, wood, iron, brass, copper, stone, and glazing responses in production renders. |
| AC-21 Scale Fidelity | PASS | Godot bounds reports and accepted registry dimensions preserve all eleven asset brief envelopes; the rocking-chair runner bottom measures 0.032 inches above the floor, and the 50-citizen presentation smoke checks the half-inch limit. |
| AC-22 Source Resemblance | PASS for desk | Desk v007 evaluation cites canonical source evidence and scores source resemblance 4/5, preserving the standing desk silhouette, dark glass, and T-frame. |
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
| AC-39 Independent Completion Review | READY FOR REVIEW | This report stops at READY FOR REVIEW. No self-declared completion is made. |
| AC-40 No Fake Pass | PASS | Promotion requires technical validation, recorded evaluation, registered production render, and passing rubric; smoke tests verify resolved candidate IDs and live gameplay behavior. |

## Final Verification Results

- Art Factory unit tests: **14 passed** (`final/art-factory-unittest.log`).
- Repository fast deterministic suite: **PASS** (`final/fast-rerun/` and `final/fast-suite-rerun.log`). It was rerun after the Art Factory runtime-error guard was added, using the existing `.venv` Python because the shell's default Python does not have Ruff installed.
- Visual resolver and presentation gates: **PASS** (`final/visual-resolver-test.log`, `final/presentation-test.log`).
- Room A, Room B, canonical reconstructed room: **PASS** (`final/room-a-smoke.log`, `final/room-b-smoke.log`, `final/canonical-room-smoke.log`).
- Accepted registry hashes: **11/11 verified** (`final/verify-*.log`).
- Final accepted captures: desk v007, grapple v006, citizen v007 (final production run-005), four settlement assets, and the four major room-furniture assets have production renders and recorded evaluations. `final/render-citizen-v007-final.log` records the post-promotion canonical-room capture.

## Known Review Items

1. AC-29 is partial because broad room surfaces and several other props have not been migrated through accepted Art Factory assets.
2. AC-28 needs independent judgment: lighting and anti-aliasing were changed and final views captured, but strong hard shadows and the live green construction marker remain visible.
3. Performance is hardware- and scene-dependent. On the test RTX 5090, both runs exceed 60 FPS and all p95 frame times are below 5 ms; the standard Room A citizen view reports 3,092 draws while the canonical furnished-room citizen view reports 1,059. Their different scene and view configurations prevent a direct comparison, and these numbers do not establish performance on other hardware.
4. The baseline report records a pre-existing graphical-launch redirect failure. It was not attributed to POC 2.5 and remains separate from the passing production smoke evidence.

**Requested external disposition:** `COMPLETE`, `REPAIR REQUIRED`, `BLOCKED`, or `CONTRACT DEFECT`.
