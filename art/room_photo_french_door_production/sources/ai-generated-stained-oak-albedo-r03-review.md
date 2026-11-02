# Stained-oak albedo r03 review

Generated as a flat square base-color tile from the selected r01 texture. Pixel inspection shows a slightly less red chestnut tone and lower luminance contrast than r01; the large repeated cathedral arches are reduced, while fine longitudinal grain remains visible. Measured at 1254 × 1254 px: mean RGB = (0.483, 0.246, 0.099); luminance standard deviation = 0.045. Mean absolute edge difference is 9.6/255 left-to-right and 9.3/255 top-to-bottom, compared with 12.5/255 and 8.1/255 for r01. It remains a repeating texture rather than an exactly pixel-periodic tile.

**Decision: use for a candidate render, with seam review required.** Its color and lower contrast better match the round-02 target. The corresponding Blender recipe varies the UV repeat phase and scale per timber member to reduce repeated figure. This review does not claim that the exported texture or final mapped material is seam-free.

Generation tool: built-in ImageGen. Prompt: square seamless diffuse albedo for a warm stained-oak French-door game material, guided by r01 color but with substantially reduced cathedral arches, quiet quarter-sawn straight grain, fine pores, gentle board-level variation, neutral even lighting, no shading or geometry, and no knots or labels.
