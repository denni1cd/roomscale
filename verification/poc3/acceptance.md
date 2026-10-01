# POC 3 acceptance record

Implementation branch: `codex/roomscale-poc3-visual-fidelity`.
The POC is **not declared complete**: AC-43 and final human visual acceptance
remain open. Read the images, not just pass markers.

## Milestones

| Milestone | Status / evidence |
| --- | --- |
| M0 baseline | PASS: `m0-status.md`, `logs/m0-fast.log`, `logs/m0-room-a.log`, `logs/m0-detail-benchmarks.log`, `baseline/` |
| M1 architecture | PASS: `m1-status.md`, `logs/m1-resolver.log`, `logs/m1-room-a.log` |
| M2 materials / lighting | Implemented; full scenario PASS (`logs/m2-room-a.log`), inspected `m2/`; subjective quality is part of final review |
| M3 furniture | Implemented and inspected; bevelled desk/side table, chair cushions/supports, filled bookcase; `m3-room-overview.png`, `m4/`, `final-reviewed/` |
| M4 automated asset experiment | PASS: original AI-authored procedural desk exported to GLB, imported, bounds/material/yaw/scale validation, runtime resolver use; `logs/asset-*.log`, `logs/m4-room-a.log`, `assets/generated/writing_desk.provenance.json` |
| M5 citizens | Production population and half-inch envelope PASS (`logs/presentation-test.log`); goggles, shoulder plates, boots, role pack/tool, carrying/building/climbing poses; inspected close images |
| M6 settlement | Implemented: windows, frame posts/rivets, roof seams, boiler plumbing, piston/flywheel, crate braces, tent ridges, station benches; inspected `final-reviewed/room_a-settlement-close.png` |
| M7 grapple | Implemented; integrated gameplay PASS: progress-driven foundation/machinery/launcher detail groups, bearing stands, cable spool, drive gears, pressure vessel, ladder, endpoint pulley, working steam. Connection activates after attachment and 0.5s settling |
| M8 integration | PASS: `logs/final-room-a.log`, `logs/final-room-b.log`, `logs/final-photo-room.log`, `logs/final-revised-room-a.log`; full real delivery/build/deploy/climb/explore/reuse |
| M9 performance | Measurements and distance strategy implemented; isolated measurement results are in `performance.json`; capped/concurrent samples are not an uncapped performance claim |
| M10 benchmarks | Baseline 15 views preserved; canonical final set is `final-benchmark/` (18 phases). Earlier `final-reviewed/` and `hero-corrected/` remain for iteration history. Human acceptance remains open |

## Criterion evidence

| Criteria | Status / basis |
| --- | --- |
| AC-01, 21, 30, 33, 34, 42 | Functional PASS: 50 citizens; A, B, accepted primary photo attempt 7; deliveries, construction, continuous movement, three explorations and autonomous reuse |
| AC-02–05 | PASS: semantic resolver/catalog; fallback checks; no render-mesh navigation or collision input |
| AC-06–11 | Implemented and captured; material/lighting/furniture/scale quality require visual judgment |
| AC-12–16, 40 | PASS: `BUILD_ROOM_SCALE_ASSETS.ps1`, original recipe/provenance, GLB header and import checks, transformed mesh bounds, material resolution, rotated/scaled wrapper checks; no manual artist work |
| AC-17–20 | Implemented and tested: lit modular citizens; role accessories driven by actual task; close screenshots inspect quality |
| AC-22–25 | Implemented and captured: clockwork buildings/machinery, real carried plank bundles/ingots/component crates, task station benches, ambient gear/piston motion |
| AC-26–29, 31 | Implemented, tested and captured: staged machinery and real deployment, fixed cable endpoints/scale, pressure steam only while working/deploying; human hero-sequence judgment pending |
| AC-32 | Runtime PASS across three camera scales; production zoom retains its existing 22in minimum; benchmark-only close fitting uses 2in |
| AC-35–38 | PASS for real automated captures: camera sidecars, actual production state and subject metadata; no fake citizens, teleports, or staged construction |
| AC-39 | Functional stalls not observed; see isolated performance results and measurement caveats below |
| AC-41 | PASS: `docs/POC3_VISUALS.md`, source catalog/material definitions, repeatable asset build and test instructions |
| AC-43 | **REVIEW REQUIRED**: a human must judge whether settlement/citizen presentation now reads as an intentional stylized game |

## Failures and corrections

- M0 found fast-test shutdown leaks. A ceiling renderer fixture was never
  freed. The one-line fixture cleanup preserves assertions and eliminates
  those errors (`logs/cleanup-fast.log`). Original failing logs remain intact.
- Initial settlement visual scaling at 0.35 made buildings too small in the
  fixed 42in close view. Revised scale is 0.6, independent of gameplay
  footprints. First and revised images are preserved.
- An integrated close-view sample was 42 FPS with three simultaneous scenario
  processes, versus the capped baseline's 60 FPS. Small citizen details now
  disappear beyond 12in, shared low-segment sphere/capsule/cylinder meshes
  replace redundant high-resolution meshes. Do not infer isolated performance
  from concurrent samples. Revised concurrent sample: 933 draw calls and
  506,920 primitives versus 1,393 calls and 596,044 primitives before LOD.
- Presentation test attempts 1/2 used brittle literal names for formatted
  float-suffixed goggle nodes. It now verifies exactly two goggle mesh nodes by
  prefix; production roles and half-inch geometry pass. Failed logs retained.
- `logs/hero-close-room-a.log` failed because filtered close phases were
  incorrectly nested under disabled legacy phase flags. Close-climb now has
  an independent flag; elevated captures account for all enabled related
  phases. This was a capture bug, not failed gameplay.
- The first close climb was captured at 85% target height, placing its camera
  inside the desk top. The corrected close view uses 40% climb height and
  follows the real traveler. `final-reviewed/` retains the obstructed image;
  use `hero-corrected/` for hero close review. Close subjects are viewed from a
  reproducible front-quarter offset relative to their actual orientation.
- Mid-climb inspection showed the original 0.07in cable radius dominated the
  citizen silhouette. The final visual radius is 0.035in, within the existing
  test bounds. Navigation still follows the same centerline; final evidence is
  in `final-benchmark/` and its full scenario log.
- The performance runner's first diagnostic print formatted an array as
  multiple format arguments. It was corrected and the failed log preserved.
  The initial 360-frame window was too short at uncapped throughput, so the
  final benchmark uses at least eight seconds and 360 frames per view. The
  short-window JSON/log remain explicitly named for diagnosis.

## Known limits

- This is a procedural art vertical slice, not production art. Ambient
  occlusion/reflections specific to Forward+ were not enabled in the existing
  Compatibility renderer. No external neural text-to-3D provider was used;
  the genuine AI-assisted experiment is an AI-authored local modeling recipe
  exported/imported as GLB, with reproducible original content.
- Imported furniture uses nonuniform bounds fitting; aspect ratios far from
  the canonical source can stretch details. Unknown photo archetypes keep
  existing procedural rendering where no preferred semantic mapping applies.
- Settlement render buildings use a 0.6 visual scale while conservative
  gameplay footprints retain their prior dimensions. Benches are placed at
  actual activity stations; there are no new navigation rules.
- Citizen animation is procedural and lightweight, without a skeleton.
  Accessories follow task state; it is not a realistic rig or hand IK system.
- Resource/citizen/settlement fallbacks remain intentionally limited. The rug,
  bin, storage box, plant and many photo-derived props retain generic recipes.
- Performance samples on the RTX 5090 do not establish lower-end GPU support.
- Human visual acceptance is outstanding; no assertion substitutes for it.
