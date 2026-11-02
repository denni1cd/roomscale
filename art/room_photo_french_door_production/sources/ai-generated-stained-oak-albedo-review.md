# Stained-oak albedo review

Both square 1254 × 1254 variants were generated from the approved Visual Director target, not cropped from the Wikimedia photograph. The first tile (`ai-generated-stained-oak-albedo-r01.png`) was selected because it retains stronger long-grain and cathedral figure at the target's warm reddish-brown value. The second edit (`ai-generated-stained-oak-albedo-r02.png`) is slightly brighter and more uniform, so it was not selected for this transfer.

Pixel inspection showed continuous-looking grain in both images, but neither is an exact pixel-periodic tile. Mean absolute edge differences are 12.5/255 left-to-right and 8.1/255 top-to-bottom for r01, versus 11.3/255 and 10.8/255 for r02. The material uses the repeating image sampler; the final Godot render must be checked for seams. This record does not claim mathematical seamlessness.

The chosen source texture is review-only input for Art Factory v005. The target texture, geometry, and production room are kept as separate assets and states. The source photograph and its CC BY 4.0 attribution remain unchanged.
