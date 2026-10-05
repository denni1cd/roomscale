# POC 3 final constrained polish

Continues `codex/roomscale-poc3-visual-fidelity` and the existing POC 3 plan.
Baseline: `../accepted-review/`, with `../review.md` and its canonical captures
also inspected. Prior evidence is preserved. This pass changes six source files;
the simulation, room definitions, navigation and asset resolver are unchanged.

## Changes and visual comparison

| Area | Baseline rough spot | Final result |
| --- | --- | --- |
| Builder | Small hammer held beside the assembly block; weak sense of contact | Larger contrasting hammer head, repeated lift/contact motion fitted to the actual assembly pin, hands fitted to the handle and workpiece, slight body lean. The close camera includes the citizen and work plate. |
| Utilities | Diagonal lines crossed the commons and looked like route overlays | Wires connect poles around the settlement perimeter. Insulators, pole feet and small distribution boxes establish infrastructure attachments without adding new systems. |
| Floor | Quiet but nearly uniform surface | Low-amplitude broad wear variation in color and roughness. Existing restrained grain and antialiased seams remain. No extra geometric marks or high-contrast texture. |
| Settlement | Central cable crossings obscured the relationship between paths | The existing paths, building positions, storage and pencil remain; the clear central area makes the connected layout easier to read. |
| Blueprint | Its top face shared the rug's exact .12in height, producing stripes in low-angle views | A thinner visual sheet clears the rug. The site and physical construction coordinates remain fixed. |
| Strong shots | Citizen, cargo, grapple and climb views already worked | Their framing and design are retained. Live actors and cargo vary between runs; these are actual task captures. |

The builder is the largest improvement: the tool now reaches a visible workpiece,
rather than reading as an accessory hanging beside the citizen. The pose is
stylized and uses stretched procedural arm segments, not anatomical elbows or
hand IK. The close frame intentionally shows the workpiece beneath the larger
machinery; the separate grapple shot provides the full structure context.

Utility lines still become thin silhouettes at room scale, but the perimeter
topology and physical fittings give them a consistent purpose. The climb cable
and its deployment behavior are untouched. Floor wear is deliberately subtle;
it supports the miniature scene rather than becoming another focal point.

## Evidence

Use **cleared-blueprint/** for final captures; the parent directory preserves
the iteration that exposed coplanar blueprint/rug faces. All captures are from
the actual runtime at 1280×720. Camera fitting follows live
subjects. The builder capture waits up to 700ms for a natural contact phase;
it does not pause the simulation, move an actor, or set an evidence-only pose.
PNG sidecars retain camera, renderer, asset sources and task/state information.
All 18 final PNGs were inspected directly on 2026-10-02 and the seven priority
views compared against the requested baseline. `capture-manifest.json` records
the final image hashes and sidecar contents.

- [Connected settlement](cleared-blueprint/room_a-living-civilization.png)
- [Settlement close](cleared-blueprint/room_a-settlement-close.png)
- [Builder at work](cleared-blueprint/room_a-builder-close.png)
- [Resource hauling](cleared-blueprint/room_a-resource-carry-close.png)
- [Citizen close](cleared-blueprint/room_a-citizen-close.png)
- [Completed grapple](cleared-blueprint/room_a-grapple-complete.png)
- [Citizen climbing](cleared-blueprint/room_a-citizen-climb-close.png)

The full 18-image suite includes overview, investigation, construction,
deployment, traversal and elevated exploration evidence alongside those seven.

## Verification and stopping point

Fast room/schema/navigation checks and resolver, imported asset and presentation
checks pass. Room B's production loop passes investigation, all eleven deliveries,
three construction stages, deployment, traversal and three surface explorations
with two autonomous reuses. The final Room A run in
`cleared-blueprint/room-a.log` passes those same gates and all 18 visual captures,
with no script/render errors. Room B was checked before the final presentation-only
blueprint clearance; its navigation and construction coordinates are unchanged.

`interrupted-room-a.log` retains the earlier interrupted run: all images were
captured, but final gameplay pass markers were absent and Godot emitted shutdown
diagnostics. It is not successful regression evidence.

The isolated 50-citizen renderer benchmark passes (`performance.json` and
`performance.log`): room / settlement / citizen views measured 419.9 / 458.1 /
429.1 FPS, with p95 intervals 2.874 / 2.711 / 2.874ms. This is roughly 2–5% lower
throughput than the preceding refinement sample; the room sample also includes
one 53.3ms maximum interval. These short measurements on an RTX 5090 do not
establish lower-end hardware performance or eliminate occasional hitches.

The direct image comparison supports stopping this constrained pass: working
contact is clearer, central cable crossings are gone, floor variation is quiet,
and citizen/cargo/grapple/climb presentation is preserved. Remaining stylization
and generic room props do not justify another broad polish cycle. Final human
acceptance under AC-43 remains open; this review is the agent's assessment.
