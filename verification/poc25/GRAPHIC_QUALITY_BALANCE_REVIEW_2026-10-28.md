# RoomScale graphic-quality balance review — 2026-10-28

## User direction

The visual-quality objective covers the people and built world as well as room presentation. Source-photo fidelity remains a desk pilot requirement; it is not the sole definition of better RoomScale graphics. This review therefore checks the active citizen pilot and the existing settlement architecture using their actual RoomScale production captures.

## Citizen pilot

- Best-so-far gameplay registry entry remains `citizen-v007`. The repaired strict gate already finds the incumbent's highly simplified construction insufficient for Tier B close realism, but its distinctive Clockwork cap, twin goggles, tailored coat, and boot layers read more clearly than recent generic-human challengers.
- `citizen-v054` replaces the block-built body with a fitted MPFB2 human and adds brass/teal head hardware. Its generated asset validates at exactly 0.26 × 0.50 × 0.21 inches, but those additions remain small in the standard close view. Its detail capture rises to 713 draw calls from 457 in v053 because each accessory is a separate mesh.
- `citizen-v055` batches all added head hardware into one skinned mesh with distinct brass/glass surfaces. Godot validates eight mesh nodes, nine surfaces, 46,544 triangles, and the exact brief bounds. Seven production views render through the normal resolver; the citizen presentation retains 50 agents. The detail capture is 446 draws, close to v053 and below v054. Its capture FPS is not a matched warmed comparison and is not used as a performance claim.
- v055's face and clothing have a more natural human/material read, but the actual profile still shows an extended gait and the character reads as a suited person more than a tailored Clockwork worker. Close captures do not establish the required seams, fasteners, layered boot construction, and assembled head hardware. The candidate remains `continue`; no incumbent or registry change.

Production evidence: [v007 incumbent close](../../art/citizen/iterations/v007/render-runs/run-005/asset-detail.png), [v055 challenger close](../../art/citizen/iterations/v055/render-runs/run-001/asset-detail.png), [v055 profile](../../art/citizen/iterations/v055/render-runs/run-001/asset-profile.png), and [v055 room-scale population view](../../art/citizen/iterations/v055/render-runs/run-001/room-scale.png).

## Built architecture

The existing primary settlement structures were inspected at their recorded close production views. They are intentionally presented as miniature Clockwork/steampunk architecture, not as photo-real human-room objects.

| Asset | Current candidate | Close-view strengths | Visible quality limits |
|---|---|---|---|
| Worker housing | [`settlement_housing-v002`](../../art/settlement_housing/iterations/v002/render-runs/run-003/asset-detail.png) | Two separate domestic silhouettes; timber courses, pitched roofs, divided warm windows, door trim, and shared flue. | Broad wall/roof planes remain smooth, pane light is very bright, and small construction details fade at game distance. |
| Workshop | [`settlement_workshop-v004`](../../art/settlement_workshop/iterations/v004/render-runs/run-001/asset-detail.png) | Open roof wings keep the boiler, gauges, copper lines, bench, and flywheel readable together. | Large roof planes and some machinery remain chunky; the close camera can be obstructed by the roof edge. |
| Assembly workarea | [`settlement_workarea-v005`](../../art/settlement_workarea/iterations/v005/render-runs/run-001/asset-detail.png) | Hoist, tools, pegs, storage, gears, spindle, and trestles give it a distinct production-yard identity. | Close capture has several foreground/background overlaps; tabletop and paver surfaces still read as broad simple materials. |
| Supply depot | [`settlement_depot-v003`](../../art/settlement_depot/iterations/v003/render-runs/run-003/asset-detail.png) | Open-front shed, canopy seams, crates, barrel hoops, rail, and pulley read as a usable loading station. | Repeated boxes and broad canopy surfaces are still visually simple; the built detail is more legible close than at settlement distance. |

Their existing evaluations report material and geometric-detail scores of 4/5 and semantic-recognition scores of 4–5/5, with actual production captures recorded. Those scores support a coherent stylized miniature architecture lane, but they are not a new strict-gate re-audit under the repaired citizen/desk visual rubric. No additional architecture migration was started here: the approved work-package order keeps broad primary-asset migration behind the Desk, Grapple, and Citizen pilot gate.

## Direction for the next quality phase

Continue citizen strategy work with a character-specific path that preserves the natural human body while restoring clear Clockwork tailoring and a compact articulated live pose. After the three pilots clear their gate, prioritize a bounded architecture pass around readable joinery, richer wall/roof surface response, window glazing, and less obstructed detail views. Keep the distinct building silhouettes and RoomDefinition/gameplay ownership intact. Judge the full built environment with citizen/settlement renders alongside room renders; do not use a desk-only close render to stand in for the game's overall graphics quality.
