# POC 3 scene refinement review

The subsequent constrained cleanup is recorded in
[final-polish/review.md](final-polish/review.md), with separately saved runtime evidence.

Branch: `codex/roomscale-poc3-visual-fidelity`. This continues the existing plan
and renderer. No new POC, simulation systems, navigation rules or staged actors.
Human acceptance of AC-43 remains open; this is Codex's image review.

Reviewed all 18 final PNGs directly on 2026-10-01, after inspecting the baseline
and previous reviewed images. Final gameplay markers pass with no script/render
errors in the canonical run. Earlier iterations remain for comparison.

## Canonical evidence

Use **canonical-final/** for the final 18-phase suite. Other directories are
retained iterations; `accepted-review/` is an agent iteration name, not a claim
of human acceptance. Each PNG has a camera, runtime and actual task/state sidecar.

| Requested view | Final evidence |
| --- | --- |
| Room overview / compact HUD | [Room](canonical-final/room_a-initial-room.png) |
| Connected settlement overview | [Settlement](canonical-final/room_a-living-civilization.png) |
| Settlement close / scale references | [Workshop neighborhood](canonical-final/room_a-settlement-close.png) |
| Citizen close | [Citizen](canonical-final/room_a-citizen-close.png) |
| Builder working | [Actual builder and assembly pin](canonical-final/room_a-builder-close.png) |
| Resource carrier | [Carrier](canonical-final/room_a-resource-carry-close.png) |
| Grapple construction | [Construction](canonical-final/room_a-construction.png) |
| Grapple complete | [Machinery](canonical-final/room_a-grapple-complete.png) |
| Citizen climbing | [Climb](canonical-final/room_a-citizen-climb-close.png), [traversal detail](canonical-final/room_a-citizen-traversal-detail.png) |
| Elevated activity | [Citizen](canonical-final/room_a-elevated-citizen-close.png), [exploration detail](canonical-final/room_a-elevated-surface-exploration-detail.png) |

Compare with [previous settlement close](../final-reviewed/room_a-settlement-close.png),
[previous builder](../final-reviewed/room_a-builder-close.png) and
[previous room overview](../final-reviewed/room_a-initial-room.png).
The previous reviewed set and baseline remain unchanged.

## Ten review questions

| Question | Codex assessment |
| --- | --- |
| 1. Connected miniature civilization? | Yes: front lanes, cross connections, overhead utilities and shared work yards make housing, workshop and depot read as a neighborhood. It is still a small settlement, not a dense city. |
| 2. Extreme scale? | Yes: the human pencil and coin beside the workshop, towering chair/desk legs and small citizens establish two scales. Wide views deliberately preserve tiny citizens rather than enlarging the simulation. |
| 3. Floor supports the scene? | Yes: muted neutral timber, subtle grain and antialiased board joints remove the earlier stretched high-contrast bands and dotted seam artifacts. The settlement's warm wood/windows now separate from the room. |
| 4. Major furniture obviously primitive? | The desk, chair and bookcase now have visible construction detail: collars, pulls, moldings, stretchers, upholstery buttons, face stiles and plinth. They still use simple stylized forms; the bin, rug and generic storage box remain simpler. |
| 5. Civilization distinct from room? | Yes: teal/copper roofs, warm windows, stained paths, utility lines and lanterns form a consistent miniature palette against a neutral human floor. The room remains bright enough for gameplay. |
| 6. Tiny steampunk people? | Yes at close scale: hats, goggles, boots, brass shoulder plates and belts preserve the established figure design. |
| 7. Jobs readable? | Yes in close activity evidence: cargo identifies carriers, tool and warm chest accent identify builders, and blue accent/pack/clip identify explorers. Role accessories are modest; front views show less of the explorer pack. |
| 8. Construction looks active? | Improved enough to read: the real worker faces an assembly pin, holds an arm-driven hammer and is visible beneath the open frame with local lighting. A static screenshot proves a work pose; it does not prove smooth motion or realistic tool contact. |
| 9. Grapple remains hero object? | Yes: gears, contrasting metal groups, cable wraps and ladder remain the strongest mechanical silhouette. Frame feet support the machinery while leaving the worker accessible. A traversal clip strengthens the cable relationship; it is not hand IK. |
| 10. Substantially more game-like than previous set? | Yes as a comparative refinement: the neighborhood has visual connections, scale cues and a coherent palette, while compact UI and tracked close captures emphasize the world. This is still stylized POC art, not a claim of finished commercial production quality. |

## Iteration findings and corrections

- First pass connected the buildings, but left pale roof treatment and the large
  debug panel. Later passes added housing facades, common work areas, carts and
  consistent roofing; the compact HUD defaults on and F3 restores diagnostics.
- Thin geometric floor joints aliased into dotted lines in low citizen views.
  The final floor shader antialiases joints and fades them with distance; grain
  contrast was reduced again after screenshot inspection.
- The original solid foundation hid citizens at the authoritative work point.
  The open frame, feet and assembly block expose that point without moving the
  worker or changing task/navigation state. The work light was reduced after
  it washed out the floor in an earlier image.
- Traversal/exploration detail captures previously framed mostly empty surface.
  They now follow the live citizen at close range; context views remain separate.
- Solid human-scale props were moved into the existing reserved workshop yard,
  clear of streets and real work stations. Streets are almost flush, and utility
  lines are above citizen height. Decorative geometry adds no physics bodies.
- Street boards now use MultiMesh to avoid hundreds of extra draw calls.
- One earlier canonical iteration logged a Windows WASAPI output-device
  invalidation. Its gameplay markers passed; the warning is retained in that
  iteration rather than removed from evidence.

## Verification

The final canonical scenario is [canonical-final-room-a.log](canonical-final-room-a.log).
Room B and the accepted POC 2 room passed the same production loop in
[room-b.log](room-b.log) and [photo-room.log](photo-room.log).
The final [fast checks](final-fast.log), resolver, imported asset and production
presentation checks pass in **final-checks/**. Presentation checks also verify
that decorative streets add no collision bodies and both HUD modes remain usable.
The refined desk was regenerated and validated as a 21-mesh GLB; **asset-build/**
preserves its generation/import/bounds/material checks.

Isolated rendering measurements are in [performance.json](performance.json).
Concurrent/capped screenshot telemetry is not used for renderer throughput claims.
The benchmark uses the real scene and 50 citizens, eight seconds per camera scale.

Godot 4.7.2 Compatibility, RTX 5090, VSync disabled, isolated process:

| View | FPS | Median ms | p95 ms | Draw calls |
| --- | ---: | ---: | ---: | ---: |
| Room | 440.2 | 2.274 | 2.696 | 1087 |
| Settlement | 468.1 | 2.150 | 2.539 | 1215 |
| Citizen | 437.9 | 2.300 | 2.670 | 826 |

The extra scene detail and lighting have a measurable cost: earlier isolated
throughput was 695.2 / 782.2 / 720.9 FPS at the same three scales. This pass is
approximately 37–40% slower by that metric, while its sampled p95 frame intervals
remain below 2.7ms on this GPU. That is not a lower-end hardware guarantee.

Residual limits: some room props remain generic, role differentiation is subtle
at distance, lighting uses the existing Compatibility renderer, and animation is
procedural rather than a skeletal/IK rig. Human visual acceptance remains required.
