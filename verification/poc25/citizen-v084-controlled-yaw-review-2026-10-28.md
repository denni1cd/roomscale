# Citizen v084 controlled gameplay-orientation review — 2026-10-28

## Evidence

Art Factory render run `art/citizen/iterations/v084/render-runs/run-002/` retains the seven normal live production captures and adds four explicitly supplemental stills at 12 inches. The same instantiated RoomScale production scene contains all 50 citizens; after the live captures, the scene is paused and only the selected figure's facing is changed while the camera remains at a fixed world yaw. These stills diagnose front/profile/back role cues. They do not replace live gameplay evidence and are not performance measurements.

The receipt records the selected citizen, fixed camera yaw, actor world position, and subject-facing angles. The four files are `asset-gameplay-yaw-000.png`, `asset-gameplay-yaw-090.png`, `asset-gameplay-yaw-180.png`, and `asset-gameplay-yaw-270.png`.

## Finding

The orientation sweep confirms a weak gameplay-distance cue across the tested facings. The v084 figure remains a small, mostly dark silhouette with a warm torso accent; the paired lenses, machined helmet construction, and pressure equipment cannot be identified consistently at this pixel footprint. The 0-degree three-quarter presentation is readable as a worker when enlarged, but this does not satisfy the 12-inch 50-citizen recognition gate. The prior live gameplay capture remains the evidence for in-motion visibility.

No candidate was promoted. `citizen-v007` remains the best-so-far gameplay incumbent. The next justified Citizen challenger should alter a broad, functional workwear cue visible on the torso and legs, rather than add helmet triangles or small decorative mechanisms. A split, leg-weighted workshop apron with a more legible deep teal cloth palette is a bounded geometry/material test; preserve anatomy, all rig/pivot and equipment contracts, exact bounds, RoomDefinition, and citizen behavior.

## Captures

- [v084 live 12-inch gameplay capture](../../art/citizen/iterations/v084/render-runs/run-002/asset-gameplay-distance.png)
- [v084 0-degree controlled facing](../../art/citizen/iterations/v084/render-runs/run-002/asset-gameplay-yaw-000.png)
- [v084 90-degree controlled facing](../../art/citizen/iterations/v084/render-runs/run-002/asset-gameplay-yaw-090.png)
- [v084 180-degree controlled facing](../../art/citizen/iterations/v084/render-runs/run-002/asset-gameplay-yaw-180.png)
- [v084 270-degree controlled facing](../../art/citizen/iterations/v084/render-runs/run-002/asset-gameplay-yaw-270.png)
- [v084 run-002 receipt](../../art/citizen/iterations/v084/render-runs/run-002/receipt.json)
