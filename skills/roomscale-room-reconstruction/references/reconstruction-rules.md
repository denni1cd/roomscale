# Photograph-to-room reconstruction rules

## Review the evidence

Use all supplied images as views of the same room unless the user says otherwise. For each image, note which walls/corners, openings, large furniture, floor, and useful surfaces are visible. Associate the same furniture across views by shape, color, nearby landmarks, occlusion, and relative ordering. A partially hidden object remains one object when multiple views support that identity.

Separate direct observation from inference. Do not count a repeated object twice because it appears in multiple views. Do not infer an opening from a dark patch alone when the view is ambiguous. If the view set leaves a major floor area unseen, use a conservative coherent approximation and report it; request a specific additional view only when the missing information materially affects a recognizable, playable result.

## Choose a coordinate frame and scale

Choose a floor origin and horizontal axes that make the room easy to describe. Document the chosen image-to-world orientation in the reconstruction note. Use the visible floor outline, wall intersections, door widths, furniture proportions, and any supplied known measurement to estimate a rectangular floor footprint. No scale reference is required. If scale is inferred from familiar objects, label it an estimate and avoid false precision.

For each major floor object, estimate one stable floor-plane base position, width, height, depth, and yaw. A visual object above the floor may use an elevated base only when `blocks_navigation:false`; keep its vertical bounds within the room. Prefer rough geometry that preserves relative size and arrangement. Keep footprints within the room. Treat orientation as a relationship to the walls and nearby furniture, not a separate duplicate per photograph.

## Reconstruct identity and appearance

Prioritize the room's visual anchors: room proportions; prominent wall and ceiling colors; doors and windows; distinctive large furniture; significant crown/baseboard trim; object layout; and strong color/material contrasts. Describe only supported colors and material categories. Preserve useful shape cues through the closest supported semantic kind and renderer archetype. Ignore small clutter unless it is unusually distinctive or affects safe floor movement.

The room data must describe the photographed environment. Simulation-generated settlement structures, spawn, depot, activity stations, and camera metadata are additional RoomScale content requirements: place them in available clear areas, away from major photographed objects and openings. Do not let that generated content replace, relocate, or hide the major photographed landmarks.

## Navigation and elevated territory

Mark large floor objects that citizens should walk around with `blocks_navigation:true`. Rugs and other walkable floor treatments can be nonblocking. Represent an elevated navigable surface only when the photos support a broad, coherent tabletop, cabinet top, dresser top, or shelf. Its surface height must match the object's top. Select a target with enough usable area to support an interesting traversal; the simulation derives approach points, site, construction, and route from the geometry.

Choose a reachable spawn footprint, depot pickup point, settlement landmarks, and activity stations on clear floor. These are required RoomDefinition metadata, not evidence about existing physical objects. Do not place them inside an obstacle, block all routes, or put settlement buildings over the room's major visual features.

## Uncertainty notes

Provide a short sidecar note with:

- the coordinate orientation and approximate scale basis;
- major visible features and the images that support them;
- estimates or occluded details that could change the layout;
- any visible features the generic RoomDefinition or procedural renderer still cannot encode;
- any additional photograph that would resolve an important ambiguity.

Use ordinary language or a small table. Do not claim an estimate was measured. Keep uncertain values plausible and internally consistent. A note is not a license to put unsupported fields in the JSON. Version 2 can describe rectangular wall runs, door/window/clear openings, optional flat ceiling appearance, and optional crown molding; use those fields only when the photos support them. Sloped/vaulted ceilings and decorative trim profiles are not modeled.
