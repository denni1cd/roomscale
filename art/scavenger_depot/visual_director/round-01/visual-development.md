# Scavenger Depot — Visual Direction Review (Round 01)

Reviewer: GPT-6-Luna  
Scope: compare the three concept directions against `art/scavenger_depot/brief.json` and the current Scavenger settlement gameplay context. This is a direction recommendation only; no final target is approved.

## Evidence inspected

- [Door-slab gantry](candidates/direction-door-slab-gantry.png)
- [Patched canopy](candidates/direction-patched-canopy.png)
- [Split roof](candidates/direction-split-roof.png)
- ArtBrief: 24 × 13 × 20 inch presentation envelope; open loading face; visible roof/awning support; large readable salvage panels and storage; Scavenger identity without Clockwork cues.
- Settlement context: `verification/art_factory_production/batch-14/scavenger-room-a/settlement-scale.png`, showing the existing small timber-and-sheet settlement structures from the gameplay overview.
- Each concept was also inspected as a reduced thumbnail to judge which broad features survive at gameplay scale. This is an indicative comparison, not an in-engine 64-inch render; dimensions and exact camera projection still need production validation.

## Direction comparison

| Direction | 64-inch read and strengths | Main weakness | Scores: silhouette / identity / unloading / support / envelope |
| --- | --- | --- | --- |
| Door-slab gantry | Paired blue and cream appliance panels, mismatched roof sheets, and the centered rope hoist remain distinct when reduced. Most immediately reads as a salvage depot. The post-and-beam gantry has visible braces and a plausible path into the corner posts. | A crate and barrel occupy the mouth of the bay, interrupting the direct unloading path. The large slabs flank the opening but their hinges should read as fixed wall panels, not swinging doors across the route. | 4 / 5 / 3 / 4 / 4 |
| Patched canopy | Broad, irregular fabric roof and outside hook produce the clearest open market/loading silhouette. Timber posts and braces visibly carry the canopy and hoist. | The tarp dominates the 64-inch read; appliance identity is weaker and concentrated at the left cabinet. The hook sits at the far-right edge rather than over a clear central unloading zone. | 4 / 3 / 4 / 4 / 3 |
| Split roof | Layered roof silhouette is distinctive against the low, simple roof forms in the settlement capture. The short ramp makes the intended loading route legible, and the large salvaged side panels read well. | The multi-level roof is visually busy and partly hides the bay. No hand-pulled hoist is apparent. At thumbnail size, the open mouth is narrower than the loading ramp suggests. | 4 / 4 / 4 / 3 / 3 |

Scores are comparative art-review estimates, not technical validation. The supplied images do not prove the stated local dimensions.

## Recommendation

Develop the **door-slab gantry** direction. At reduced size it retains the strongest combination of recognizable Scavenger materials, depot function, and distinctive settlement read. Its broad mismatched sheet roof, salvaged appliance panels, timber frame, wire cage, and plain rope hoist separate it from the settlement's simpler teal-roof structures. It uses ordinary iron and rope; no decorative brass, gear, boiler, or other clear Clockwork cue appears.

Keep the loading face visibly open and refine these points before the next handoff:

1. Move the barrel and front crate to the rear corners or outside side storage so a clear, uninterrupted path runs from the sill to the back of the bay. Retain one or two large storage forms at the edges for scale and settlement readability.
2. Keep the rope hoist suspended from the front crossbeam, centered over the bay; show its beam connections into the braced posts and a parked hook clear of the sill. Avoid adding a separate unsupported jib.
3. Keep both appliance slabs bolted to side framing as fixed wall panels. Make the folded roof overlaps visibly fastened to rafters or purlins, and keep the broad roof edge within supported framing rather than extending as a free cantilever.
4. Preserve broad color blocks (blue and cream enamel, galvanized gray, timber, wire) and simplify tiny surface wear. At 64 inches the materials and panels must read before individual bolts or scratches.
5. Check the whole footprint, including the roof edges and storage, against 24 × 13 × 20 inches. The concept perspective makes height and depth ambiguous; retain the short roof profile and do not let the gantry or overhang expand the envelope.

The patched canopy is the fallback if a clearer open unloading silhouette outweighs the stronger appliance-panel identity. Do not combine all three concepts: the split roof's extra tiers would add clutter to the gantry direction. This review selects a direction for refinement only; it does not approve a final visual target.

## Refined target pixel review — door-slab gantry r01

Reviewer: GPT-6-Luna  
Status: **PASS — approve as the final visual target for 3D handoff.** This approval is for the concept image only; it is not a 3D asset or production validation.

### Evidence inspected

- Full-size pixels: `candidates/door-slab-gantry-refined-r01.png`
- Thumbnail-scale check: reduced view of the same candidate, compared with the Scavenger settlement overview noted above.
- ArtBrief criteria: faction identity, asymmetric silhouette, open loading route, visible joins/load paths, absence of Clockwork cues, and the 24 × 13 × 20 inch envelope.

### Findings

The revision addresses the prior blockers. At full size, the loading floor is clear from the front sill to the rear wall. The blue and cream appliance slabs are fixed to the side framing and no longer intrude into the opening. At thumbnail size, the central opening remains visibly empty and reads as an unloading bay; the paired appliance panels, mixed roof sheets, and central rope hoist remain legible against the settlement's simpler roofed structures.

Roof sheets overlap and visibly fasten to the timber roof frame. The front crossbeam is tied into substantial posts with diagonal braces, and the centered rope hoist hangs from that beam; its load path reads through the beam to the braced posts. The roof silhouette is broken and asymmetric without an implausible unsupported extension. Ordinary rope, wood, iron straps, and appliance enamel support Scavenger identity; there are no decorative gears, brass trim, boilers, or Clockwork machinery cues.

The image's projected proportions are plausible for 24 × 13 × 20 inches: the overall width-to-height ratio is consistent with 24:13, the roof remains within a compact low-profile structure, and the depth looks compatible with the brief. Exact dimensions cannot be proven from a perspective concept image and must still be validated on the 3D handoff.

### Decision

**Pass as the final approved visual target.** No further concept correction is needed before 3D handoff. Keep the clear center path, fixed side slabs, supported center hoist, and visible roof connections as handoff invariants. This pass does not claim that the eventual 3D asset meets the ArtBrief until its dimensions, joins, and gameplay-scale render are reviewed.
