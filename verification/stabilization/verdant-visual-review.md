# Verdant visual review — 2026-10-07

Final executable source: `79d549bda5b31432a1d3540edeb5d1edc9c7af6e` on
`feature/verdant-civilization`, updating [PR #3](https://github.com/denni1cd/roomscale/pull/3).
The initial clean checkout was on `main`. `git fetch origin`, tracking-branch switch,
and `git pull --ff-only origin feature/verdant-civilization` completed before review.
The synchronized branch contained the requested `a9af7a88d788944fb52d8a7383e953474bd09dd3`.

## Review scope and rendering

The initial Verdant founder fishbowl was reviewed in the real Windows graphical game
with manual camera at room, settlement and citizen presets. Ordinary 10× controls
advanced the colony through earned structures and population growth; the selected
before image records Day 7.96 and 12 citizens. The user then requested headless local
work to keep using the computer. Review-created game windows were closed and desktop
input stopped.

Final comparison captures use the same production main scene on an isolated GitHub
Ubuntu virtual display, Godot 4.7.2 and Mesa software OpenGL. This is real rendered
gameplay, distinct from Godot's dummy headless renderer. The observer uses normal
wall-clock processing, the ordinary fishbowl 10× button, and the ordinary established
room Reach / Explore action. It uses the ordinary Pause control briefly for stable
founder images, then resumes the previous speed. It does not assign resources, stages,
poses, citizen positions, task outcomes or navigation links.

Renderer review: all four scenarios passed in
[the final source-specific run](https://github.com/denni1cd/roomscale/actions/runs/37688360891).
Final images were inspected at room, settlement and citizen scales, including earned
structures, all three real carried materials, active construction, the completed vine,
a real climbing citizen and reclamation on the traversed surface. Earlier rendered
matrices exposed the face, climber and capture-readiness problems corrected below.

## Issues found and production changes

- The production Overlay is a CanvasLayer. Casting it to Control made banner creation
  dereference null. The presenter now waits for ready scene/UI ownership, retries
  normally, and marks the scene applied only after creating the scene-owned banner.
  Identity survives diagnostic toggles and scene replacement without duplication.
- The canonical earned structures were rectangular buildings with green roofs and tiny
  leaves. Verdant now grows rooted twig frames, woven shelter/cache forms, round pod
  homes, and a branching tree nursery. Real FOUNDATION, FRAME, SHELL and COMPLETE
  metadata governs these visual changes. Established nurseries use bark trunks,
  clustered crowns, hanging seeds and emissive blossoms; cultivation has saplings.
- Steam mains, utility wires and distribution machinery remained around the established
  grove. Those industrial presentation nodes are retained but hidden for Verdant.
  Human pencil/coin scale props and production building identities remain intact.
- The vine renderer compared subdivided route segments against a coarse deployment
  cursor. It now maps every subdivision to its actual production cable section, so
  growth follows the real cursor instead of popping the remaining route at completion.
  A connected bloom stem meets the real launcher tip. Twining fibers and leaves give
  the route a living silhouette; growth spores appear only with actual active work.
- Reclamation was nearly invisible at broad views, and upper decoration could extend
  beyond its support. Occupied groves receive larger bounded patches; founders receive
  a small initial footprint. Completed traversal adds supported moss/fungi at the actual
  anchors. Surface bounds, rotations, floor limits, rugs and blocking furniture constrain
  presentation placement. Mushrooms start at the actual supporting surface height.
- Shared LOD could revive hidden Clockwork goggles and shoulder plates close to Verdant
  citizens. Only those ornaments are removed from the LOD visual list; the original rig,
  limbs, boots, tool/pack references and animation remain. Woodland coats now vary in
  color, and small eyes/ears/noses make the folk recognizable as people. Plants remain
  infrastructure. Carried bundles and real remaining stock use fiber/resin/spore forms.
  Rendered inspection then exposed an overhanging conical cap and an overly thick vine:
  the cap is now a rounded acorn form, the real climbing axis is thin enough to leave
  bodies visible, and leaves sit to the side. Connected supported moss/root runners
  replace the appearance of unrelated green dots around occupied groves.
- Fishbowl, normal simulation, manual project UI, captions and diagnostics leaked Wood,
  Metal, Winch, Launcher and Grapple terminology. Verdant labels now use the profile's
  vocabulary while Clockwork retains its existing wording.
- Citizen zoom used the room's 22-inch minimum, making an inward wheel step jump out
  from the 11-inch citizen preset. Citizen mode now permits inspection down to 1.5 inches;
  room/settlement limits and preset distances remain unchanged.
- The production smoke harness added the scene without making it current_scene, so
  civilization autoloads did not run there. It now verifies the actual selected scene
  presentation, route endpoints, progressive visibility and absence of Verdant residue
  in Clockwork. An atomic presentation refresh must leave production status, route,
  cursor and connectivity unchanged.
- A pure rotated-surface support contract uses the room's actual 3D rotation basis.
  It caught and corrected a reversed 2D rotation convention in decoration containment.
  Captures now refresh the citizen's public visual LOD after camera cuts, wait for all
  earned modules to receive their ordinary Verdant styling, and record real carried
  material identities. No late blue Clockwork module or stale detail mode is accepted
  as final Verdant evidence.

## Verification

All recorded local verification commands exited **0**. Compact source-specific receipts and hashes are in
[verdant-review-summary.json](verdant-review-summary.json); raw successful logs remain
under ignored `verification/stabilization/runs/verdant-review/`.

| Command | Exact result |
|---|---|
| `./TEST_ROOM_SCALE_CIVILIZATIONS.ps1 -OutputDirectory verification/stabilization/runs/verdant-review/final-support/contracts` | Definition PASS, Verdant production visual contract PASS, checks PASS; close LOD, inward zoom, rotated support, UI toggles, scene reload and Room POC4 vocabulary verified. |
| `./TEST_ROOM_SCALE.ps1 -Mode Fast -PythonExecutable ./.venv/Scripts/python.exe -OutputDirectory verification/stabilization/runs/verdant-review/render-polish` | `ROOMSCALE_CATEGORY_PASS category=Fast`; Ruff check/format, 14 tooling tests, startup/schema, founder fast, evidence/core and six focused navigation/placement commands passed. |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization clockwork -LogPath verification/stabilization/runs/verdant-review/final-clockwork-room-a.log` | M2, M3, M4, M5, M6, M8 and Civilization smoke PASS; no engine/script errors. |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization verdant -LogPath verification/stabilization/runs/verdant-review/final-verdant-room-a.log` | Same seven PASS markers; real vine endpoints/cursor and presentation read-only state verified. |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_b -Civilization clockwork -LogPath verification/stabilization/runs/verdant-review/final-clockwork-room-b.log` | Same seven PASS markers; no Verdant residue, no engine/script errors. |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_b -Civilization verdant -LogPath verification/stabilization/runs/verdant-review/final-verdant-room-b.log` | Same seven PASS markers; real vine endpoints/cursor and presentation read-only state verified. |

Each final smoke earned 11 deliveries, all three construction stages, physical traversal,
three arrivals, three explorations and two autonomous reuses by three distinct travelers.
The shared 6.5-inch/second movement cap remained verified. The first Fast attempt could
not import Ruff from the host Python; installing the repository-pinned dependency in the
ignored local virtual environment resolved that environment issue. No check was bypassed.

The local four-room matrix records source `ba9f428`. The face, vine-thickness and groundcover
refinements were followed by fresh local contract/Fast runs and hosted Windows Fast plus
all four production smokes on `4c87a8f` and `f503063`; both hosted matrices passed.
The final observer-only commit `79d549b` passed the complete
[hosted Windows matrix](https://github.com/denni1cd/roomscale/actions/runs/37688360747):
Fast (including civilization contracts) and all four production smokes succeeded.
Production services were not edited between these sources. The final observer passed
the headless Godot parse check before dispatch. The subsequent evidence-only commit
retains these exact executable sources.

## Authority and artifact policy

RoomDefinition, CivilizationSimulation, citizen task/movement logic, needs, economy,
construction progression, development capabilities and navigation authority were not
changed. Internal `wood`, `metal`, `mechanical_parts`, `base`, `winch` and `launcher`
remain compatibility seams. New flora, magic and route presentation add no physics or
navigation authority and consume real production state. No PR merge was performed.

Historical startup captures overwritten by launch were restored. Raw imports, runtimes,
virtual environments and runs remain ignored. Godot script UIDs are source metadata.
Only 16 deliberately selected images (9.24 MiB) and compact provenance are retained
permanently following [the existing artifact policy](artifact-review.md). The 52 raw
final renderer captures remain in ignored run directories. The before capture was
saved by the desktop API as JPEG bytes and is correctly named `.jpg`.

## Visual acceptance

The factions now have distinct silhouettes and material language: Clockwork workshops,
metal roofs, pipes, goggles and machinery versus Verdant branching nurseries, seed pods,
woven structures, foliage, living traversal and humanoid woodland folk. The citizens
remain people rather than plant bodies. Furniture and the pencil retain the giant-room
scale. The earned grove has no late industrial module, and close citizen evidence has
the correct current detail mode. Real resource portraits show tied fiber, amber resin
and pale spore pods. A climbing citizen remains readable beside the thin vine.

Recommend merging this procedural presentation milestone. It is not final art or a
complete room-wide ecosystem. Remaining visual concerns:

- Reclamation still reads as separate small groves at room scale. Connecting larger
  regions as occupation advances is future art work.
- Flat moss lobes, radial roots and round crowns look schematic; more organic shapes
  and varied surface detail would improve them.
- Nature-magic blossoms/spores are subdued in bright room lighting, and distant vines
  are difficult to identify from the whole-room view.
- Decorative construction roots can be partly occluded by a rug edge. The real project
  site, supported geometry and gameplay remain intact.
- Still captures do not establish animation quality by themselves. The initial live
  review and production traversal tests supplement them; shared animation logic was
  preserved.

## Selected evidence

All final PNGs come from source `79d549b`; the before JPEG comes from the synchronized
`a9af7a8` review. [The manifest](verdant-renderer-evidence.json) retains file hashes,
capture state and source-specific receipts.

| Image | What it demonstrates |
|---|---|
| [Before founder settlement](../verdant-review/evidence/before-founder-settlement.jpg) | Initial live review, Day 7.96, population 12. |
| [Verdant room](../verdant-review/evidence/verdant-room.png) | Giant human room, identity banner, bounded established growth. |
| [Verdant settlement](../verdant-review/evidence/verdant-settlement.png) | Organic structures and supported connected groundcover. |
| [Verdant nursery](../verdant-review/evidence/verdant-nursery.png) | Branching tree, crowns, hanging seeds and roots. |
| [Verdant citizen](../verdant-review/evidence/verdant-citizen.png) | Humanoid face, acorn cap and woodland clothing. |
| [Active construction](../verdant-review/evidence/verdant-construction.png) | Actual work state, growth lattice and nature-magic spores. |
| [Completed vine](../verdant-review/evidence/verdant-vine.png) | Whole real production route and bloom anchor. |
| [Real climber](../verdant-review/evidence/verdant-climber.png) | Actual citizen traversing the living route. |
| [Upper reclamation](../verdant-review/evidence/verdant-reclamation.png) | Supported moss/fungi earned at the traversed surface. |
| [Earned founder grove](../verdant-review/evidence/verdant-earned-grove.png) | Normally developed modules after final Verdant styling. |
| [Living Fiber](../verdant-review/evidence/verdant-living-fiber.png) | Real carried wood identity, tied fiber presentation. |
| [Resin](../verdant-review/evidence/verdant-resin.png) | Real carried metal identity, amber pod presentation. |
| [Growth Spores](../verdant-review/evidence/verdant-growth-spores.png) | Real carried mechanical_parts identity, spore pods. |
| [Clockwork settlement](../verdant-review/evidence/clockwork-settlement.png) | Retained industrial comparison. |
| [Clockwork workshop](../verdant-review/evidence/clockwork-workshop.png) | Machinery, metal roofs and steam. |
| [Clockwork citizen](../verdant-review/evidence/clockwork-citizen.png) | Correct close-detail goggles, plates and boots. |
