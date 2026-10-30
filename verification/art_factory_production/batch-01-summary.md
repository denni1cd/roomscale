# Art Factory Production Deployment — Initial Broad Pass

**Status:** Work in progress. This report records an initial scene-wide deployment pass; it does not claim production completion or reopen POC 2.5.

- **Base:** POC 2.5 closure `1e111d37325e7ad00030266efec201796b7fc07d`
- **Branch:** `codex/art-factory-production-deployment`
- **Date:** 2026-10-30

## Inventory

The generated [full visible-art inventory](visual_inventory.md) and [machine-readable inventory](visual_inventory.json) cover 20 RoomDefinitions (2 playable rooms and 18 candidate/scenario rooms), 294 room-object records across 79 object classes, 95 catalogued asset/presentation classes, and 79 procedural geometry-builder sites in 12 runtime scripts. The scan records 11 canonical registry entries, 10 visual catalog entries, and 17 material categories. It includes unregistered and runtime-built geometry, not only existing Art Factory assets.

The highest-impact gaps remain room shell/material response, major furniture, and coherent faction art. Existing strict pilot results are retained: desk and grapple remain failures; citizen-v089 remains best-current review art with `continue`. No failed candidate was promoted.

## Initial production work

- Added shared fabric, paint, wood, and organic surface response, including a plank-and-grain floor shader and bounded material variation for room walls and fallback citizens.
- Added presentation-only Scavenger salvage cladding and a faction-specific fallback workwear variant.
- Gave the Verdant nursery a branching structure and spread leaf arrangement rather than a single sphere-like crown; broad leaf cards remain visible at close range.
- Preserved MPFB PBR maps while applying faction color adaptation. Citizen-v089 is used for non-Clockwork factions only in `review_showcase`; canonical registry routing and production promotion remain unchanged.
- Kept all new civilization dressing presentation-only. RoomDefinition remains authoritative for room dimensions, collision, navigation, construction, and traversal.

These are bounded visual improvements, not a claim that the room shell, Scavenger, Verdant, or fallback citizen art meets production quality. The inventory and backlog retain those deficiencies for subsequent higher-impact batches.

## Production-render evidence

Real Godot captures used the review-only v089 showcase registry. The Scavenger, Verdant, Clockwork Room A, and reconstructed `room_photo_luna` capture campaigns completed their view sets. The curated examples are:

- [Clockwork citizen, close view](clockwork-citizen.png)
- [Clockwork settlement, gameplay distance](clockwork-settlement.png)
- [Scavenger citizen, close view](scavenger-citizen.png)
- [Verdant citizen, close view](verdant-citizen.png)
- [Verdant nursery, close view](verdant-nursery.png)
- [Reconstructed-room desk, production view](room-photo-desk.png)

Visual review finds Clockwork's faction equipment legible, but the Scavenger and Verdant MPFB variants still read as generic workwear at close range. Verdant foliage remains flat-card geometry. The reconstructed-room desk remains dark and visually flat. These are backlog findings, not promoted passes.

## Gameplay regression evidence

The saved Room A, Room B, and reconstructed-room smoke logs report M2/M3/M4/M5/M6/M8 passes with 50 citizens in each room. Each completed 11 resource deliveries and construction; actual traversal reached 30 in, 36 in, and 30 in respectively. M6 reports three arrivals, three explorations, and two reused routes in each room. The smoke results preserve the existing gameplay contract; the citizen and settlement appearance adaptations do not change RoomDefinition gameplay geometry.

Evidence logs: [Room A smoke](room-a-smoke.log), [Room B smoke](room-b-smoke.log), and [reconstructed-room smoke](room-photo-luna-smoke.log).

## Population performance

`performance.json` records a real-renderer, 50-citizen run on Godot 4.7.2, OpenGL Compatibility, and an RTX 5090 workstation with v-sync disabled. Room, settlement, and citizen-close views measured 379.5, 397.7, and 304.2 FPS; their p95 frame times were 3.09, 2.99, and 4.31 ms. Draw-call counts were 791, 1,041, and 2,053; primitive counts were 272,084, 509,300, and 724,878. This is a workstation measurement, not a target-hardware guarantee. It is recorded alongside the earlier lower shared-desktop capture in the production-art backlog.

## Boundaries and next work

- Canonical asset registry and POC 2.5 strict acceptance results are unchanged.
- Citizen-v089 stays review-only. No art candidate was promoted by this pass.
- No matched POC-closure/best-current visual comparison was performed here; this evidence does not establish the production phase success criterion of clear scene-wide improvement.
- Next priority remains scene foundation and major furniture, then the Clockwork settlement core. Citizen faction clothing and Verdant leaf construction remain follow-up items, not reasons to continue citizen iteration ahead of the broader scene.
