# Pixel review — Scavenger Depot v001

Reviewer: GPT-6-Luna  
Method: direct pixel inspection of the approved visual target and requested Godot production captures, including a close crop of the 64-inch settlement view.

## Evidence inspected

- Approved target: `art/scavenger_depot/visual_director/round-01/approved-target-r01.png`
- Gameplay/settlement view (64 inches): `art/scavenger_depot/iterations/v001/render-runs/run-001/settlement-scale.png`
- Close three-quarter view: `art/scavenger_depot/iterations/v001/render-runs/run-001/asset-three-quarter.png`
- Room overview (330 inches): `art/scavenger_depot/iterations/v001/render-runs/run-001/room-scale.png`
- Technical bounds from the candidate record: `23.63 × 12.18 × 18.72 inches`, within the requested `24 × 13 × 20` envelope.

## Findings

The approved image has one unmistakable open loading bay: a clear sill-to-back-floor route, broad fixed blue and cream appliance panels at the sides, and a centered rope hoist on a braced timber crossbeam. In the 64-inch Godot capture, the candidate instead reads as a compact cluster of small roofed stalls. The paired broad appliance panels and single central opening are no longer the first read; roof planes and a dark central cylinder dominate. Compared with the approved target, the depot function and asymmetric gantry silhouette are weak at gameplay scale, and the asset does not noticeably improve the repeated settlement read.

The close three-quarter capture shows timber posts and perimeter beams under a roof of mismatched sheets, so the basic roof support is plausible. However, the load path for the approved centered gantry/hoist is not clearly readable from this view, and the candidate's roof reads as a simpler set of adjacent covers rather than the approved shallow asymmetric roof carried over one wide bay.

The dark cylindrical center assembly has bright gold bands and nearby gear-like shapes. These details pull the faction read toward Clockwork and are especially conspicuous against the muted timber and teal roof at 64 inches. The target's plain rope tackle and large enamel slabs are not prominent enough to counter that cue. The model does retain timber and mixed sheet materials, but they do not establish the intended Scavenger identity on their own.

At 330 inches, the depot is too small in the room view for its opening or material details to register; this capture does not show a scale-level improvement. The recorded bounds do fit the requested envelope, so scale is not the blocker.

| Criterion | Score |
| --- | ---: |
| Silhouette/readability at 64 inches | 2/5 |
| Scavenger identity | 2/5 |
| Open unloading path | 2/5 |
| Roof support plausibility | 3/5 |
| Material separation | 3/5 |
| Envelope fit | 5/5 |
| Visual craft against target | 2/5 |

## Decision — alternate strategy

Do not pass v001 and do not try to fix it with a small surface-detail edit. The candidate's main structure and faction focal points have drifted from the approved target. Rebuild from the approved wide gantry composition: one broad, uninterrupted center loading route; two large fixed appliance panels at the side posts; one central rope hoist visibly hung from a crossbeam supported by diagonal-braced posts; and a single shallow asymmetric roof with clear sheet-to-rafter attachments. Remove the dark brass-banded cylinder and gear-like center details. Keep useful crates, barrel, or wire storage outside the unloading lane and use ordinary iron/rope fasteners only. The next 64-inch capture should make the open bay and paired enamel slabs read before the roof panels, with no Clockwork-coded focal object.
