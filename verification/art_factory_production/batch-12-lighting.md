# Batch 12 — Room A/B Lighting and Environment

## Scope and visual direction

Batch 12 was a bounded scene-wide presentation pass on the Tier 1 **lighting_and_environment** category. Visual Director classified it as required (Tier 1, whole-frame prominence, below target). One concept was generated from the Room B production overview, pixel-inspected, and approved as a lighting-direction reference at art/lighting_and_environment/visual_director/round-01/approved-target-r01.png.

The concept is not a mesh candidate. Pixel review found that image generation added apparent wall/floor texture and unsupported window-grid shadows. Those details were explicitly excluded from the brief and implementation.

## Production change

Only the existing DirectionalLight3D, RoomFill OmniLight3D, and WorldEnvironment settings in scripts/pipeline_proof.gd changed.

| Setting | Before | Selected |
|---|---:|---:|
| Directional key color | ffffff | fff2e2 |
| Directional key energy | 0.80 | 0.92 |
| Angular distance / shadow blur / opacity | 0 / 1.00 / 1.00 | 0.50 / 1.25 / 0.82 |
| Broad room fill energy | 1.20 | 0.65 |
| Ambient energy | 0.72 | 0.56 |
| Environment background | 17212b | 43566a |
| Glow | enabled | disabled |
| Settlement lantern fill | 1.40 | 1.40 (unchanged) |

The selected profile warms the key slightly, lowers the broad wash, softens the directional shadow edge, and gives the cutaway a quieter slate exterior. The trial with glow disabled and the original dark environment made photo-room windows too dark; a low-glow trial kept them bright but barely changed the large-room backdrop. The selected slate background balances both views. No light, mesh, material, texture, or decoration was added.

## Matched whole-scene review

Before and selected profiles were captured at 1280 × 720 with the real Godot 4.7.2 GL Compatibility renderer and the canonical production registry. Each scene loaded the normal 50-citizen population. The review used the same camera focus, distance, and angle for both profiles.

| RoomDefinition | Matched views |
|---|---|
| room_a | Room overview, opposite angle, settlement gameplay at 64 inches |
| room_b | Room overview, opposite angle, settlement gameplay at 64 inches |
| room_photo_luna | Room overview, opposite angle, settlement gameplay at 64 inches, photo-room gameplay at 220 inches |

Baseline and selected images plus capture receipts are preserved under verification/art_factory_production/batch-12-lighting/captures/<room-id>/.

Pixel review found a calmer exterior, warmer highlights on room surfaces, and slightly clearer depth separation in the large room views. The photographed room keeps its window shapes and room colors; the panes read cooler and darker with the selected exterior. Broad walls, floor, and furniture remain visibly flat or primitive. This is a supporting presentation improvement, not a replacement for those Tier 1 assets. No geometry, material identity, RoomDefinition, collision, navigation, interaction, citizen autonomy, or simulation behavior changed.

## Performance

The repository benchmark ran with 50 citizens, VSync disabled, on the same RTX 5090 machine and GL Compatibility renderer. It ran once before and once after the lighting change; values are machine-specific and should be treated as comparative snapshots.

| View | Baseline FPS / median / p95 ms | Selected FPS / median / p95 ms | Draw calls | Primitives |
|---|---:|---:|---:|---:|
| Room | 466.58 / 2.106 / 2.275 | 479.76 / 2.064 / 2.203 | 971 / 971 | 497,000 / 497,000 |
| Settlement | 508.56 / 1.917 / 2.222 | 529.73 / 1.863 / 2.018 | 1,058 / 1,058 | 771,854 / 771,854 |
| Citizen | 311.22 / 3.165 / 3.863 | 324.73 / 3.037 / 3.660 | 2,812 / 2,814 | 1,271,358 / 1,271,838 |

No rendering-cost regression appeared in this comparison. The 1–2 draw-call and 480-primitive difference in the citizen view is ordinary live-scene variation; no new geometry was authored.

## Integrity and disposition

- Visual Director targets approved: 1.
- 3D candidates produced: 0; this is an environment-settings pass, not a mesh episode.
- Production registry: unchanged at 15 accepted entries.
- Promotions: 0. Rejected mesh challengers: 0.
- RoomDefinitions: 21; room records: 318; visible-art classes: 95 (48 Tier 1, 11 Tier 2, 36 Tier 3).
- Tier 1 accepted production coverage: 8 of 48; 2 additional classes link to accepted asset families.
- Runtime geometry scan: 91 builder sites in 12 scripts; unchanged.
- Art Factory integrity suite: python scripts/test_art_factory.py — 24 tests passed.
- Inventory refreshed with the implemented lighting state.

Next priority is Tier 1 room-shell architecture: source/style-specific trim and visible ceiling, while keeping RoomDefinition geometry and gameplay authority intact.
