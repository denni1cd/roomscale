# Controlled visual comparison — amended acceptance criterion 8

**Finding: the matched room overview does not establish a material scene-wide improvement.** This is an evidence finding, not a strict asset-gate result and not a COMPLETE disposition.

## Controlled conditions

| Setting | Baseline | Final best-current review |
|---|---|---|
| RoomDefinition | `room_photo_luna`, `verification/poc2/candidates/primary/attempt-7/room_photo_luna.json` (SHA-256 `4e96a537f8415f2e987d27740de59f97c8cb349473a5c41636664a3b477b4d3b`; unchanged from baseline source) | Same file and SHA-256 |
| Civilization/context | Clockwork | Clockwork, 50 production citizens |
| View | 1280×720, target `(0, 0, 0)`, distance 330, tilt 52°, yaw 0°, FOV 55° | Same values; confirmed in `final-capture-receipt.json` |
| Renderer/engine | Godot 4.7.2 Compatibility; original capture metadata | Godot 4.7.2 Compatibility; actual graphical production render |
| Art configuration | Pre-POC programmer-art baseline; original capture records the desk source and procedural fallbacks for other room props | Explicit `review_showcase` registry; desk-v007, grapple-v006, citizen-v089 remain review-only |
| Overlay/framing | Visible; original baseline capture | Visible; matched capture |

`baseline-matched.png` is the preserved pre-POC initial-room capture with the original camera metadata. `final-matched.png` was captured from the Godot production scene with the v089 review registry; it was not composited or painted over. No art or RoomDefinition was changed to improve this comparison. The original baseline metadata did not record FOV, but the baseline camera implementation sets it to 55°, matching the final receipt.

The capture's [Godot run log](final-capture-run.log) records the actual graphical render and review-only registry selection. Registry SHA-256 is `3f70eb60dc394759c7533fe996e7c0d08049b3ef1c5b27d5ac2f1c6f06f2241c`; the tested runtime source `scripts/citizen_agent.gd` has SHA-256 `7a7f47d50cdcfab0db7edb739c8304d60313795c4a089768c80a2534b62d2a82`.

SHA-256: `baseline-matched.png` `ac3d92ea84d1bfb0b6d2d5bc9c2ad14927ba4666a9a99cee72c03a3220214cb1`; `final-matched.png` `0cd33168544ad9b92c3ceeef4ec2ce20438a05dcef66d779d01e6c9c39ac8e4b`; `final-capture-receipt.json` `15e8f7dc8238303879cc36702e8a038d835dfcbb52a55295abd0855e215657c6`.

## Findings by visual area

| Area | What the matched pair establishes |
|---|---|
| Citizen presentation | Citizens are too small at this overview to compare anatomy, workwear, or Clockwork readability. The separate v089 production-distance/close views show its improvements, but this pair does not establish them against baseline. |
| Settlement architecture | Settlement buildings are outside this room-focused framing. Existing final settlement captures provide current-state evidence only, not a matched baseline comparison. |
| Important furniture | The desk, hammock, and surrounding room furnishings remain small in frame. No clear scene-scale material improvement is visible; desk-v007 remains a strict visual failure. |
| Traversal/art machinery | The captured initial-room state has no deployed grapple route. Gameplay logs prove function, but this image pair does not compare its visual presentation. |
| Material/detail richness | At this distance, broad surfaces and large color fields dominate. Added geometry and materials are not legible enough here to establish a material increase in richness. |
| Overall room-scale coherence | The two images look substantially similar at this fixed overview. The final capture does not visibly demonstrate a material improvement over the programmer-art baseline. |

## Disposition

The controlled evidence does **not** support a PASS claim for amended criterion 8. It also cannot establish that no individual asset or close-view presentation improved; it shows that those improvements are not materially apparent in this room-scale comparison. Citizen-v089 remains `continue`; desk-v007 and grapple-v006 retain their documented strict failures. No candidate was promoted, and the acceptance amendment was not changed.

AC-8 is therefore **unresolved for independent review**. A decision to accept this evidence, request a different bounded comparison, or revise the POC disposition is separate from the strict asset gate. This package does not authorize more asset iteration by itself.
