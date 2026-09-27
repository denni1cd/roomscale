---
name: roomscale-room-reconstruction
description: Turn ordinary photographs of one room into an inspectable RoomScale RoomDefinition using the repository's schema and validation workflow.
---

# RoomScale room reconstruction

Use this skill when asked to create or revise a RoomScale room from photographs. RoomScale is a small 3D civilization simulation in which half-inch citizens explore room floors, investigate elevated surfaces, build traversal infrastructure, and travel to newly reachable surfaces. A `RoomDefinition` is the ordinary text-data input that describes a room to the simulation. The reconstruction AI authors that data; it is not part of the running game.

Read these references before authoring:

- [RoomDefinition contract](references/roomdefinition-contract.md) for the exact current schema, units, fields, and renderer behavior.
- [Reconstruction rules](references/reconstruction-rules.md) for evidence handling, cross-view reasoning, geometry, appearance, and uncertainty.
- [Validation and repair](references/validation-and-repair.md) before claiming an output is valid.

## Inputs and output

Use every supplied photograph that appears to show the same room. Any photo count is acceptable. A known measurement or user description may help, but neither is required. The four images in `photo_holder/` are only the repository's canonical test set.

Produce:

1. one complete JSON `RoomDefinition` using the repository's current contract;
2. a short reconstruction note that separates visible evidence from estimates and records material ambiguity;
3. validator output or an explicit statement that validation was unavailable or failed.

Keep the JSON as the game input. Do not encode gameplay behavior, AI reasoning, or unsupported schema fields in it. Read the validation reference for the repository command and candidate-file location. Preserve each failed candidate and its validator output during repair.

## Workflow

1. Inspect each photo, make a short view inventory, and reconcile the views as one physical room. Associate repeated or partly occluded objects across views instead of duplicating them.
2. Decide whether any missing view prevents a coherent, recognizable, playable approximation. Approximate and report uncertain details when that is sufficient. If a materially important feature cannot be inferred, request a specific view and explain what it would resolve.
3. Establish one floor coordinate frame and estimate the room shell and major object layout from the images. Use a supplied scale reference if available; otherwise keep proportions plausible and describe the scale estimate as approximate.
4. Encode major room features and objects with stable IDs, semantic kinds, positions, dimensions, orientation, obstacle behavior, appearance, and elevated-surface data when supported by the evidence. Include the general gameplay metadata required by the contract, placing it in clear floor areas without displacing photographed objects. For spawn data, use a 3D `center` and a 3-number `dimensions` vector with positive X/Z footprint sizes (normally `[width,0,depth]`). Optional `navigation_padding` must be a nonnegative `[x,y,z]` vector and defaults to `[0,0,0]`; leave at least 1 inch between floor placements/footprints and the room edge.
5. Check that object identity and placement remain consistent across the photos, the room is recognizable from its large shapes and color relationships, and the selected elevated goal is broad and coherent enough for tiny citizens.
6. Run the repository validator. Give its structured errors and the exact failed JSON back to the reconstruction model, make the smallest supported correction, preserve the prior candidate, and validate again. Never ask the user to edit JSON or move objects in Godot.
7. Report the output path, validation result, important assumptions, and any unresolved evidence gap. Do not call an unvalidated file complete.

## Evidence and scope rules

- Treat the photographs as evidence, not as a prompt to invent a generic room. Use visible landmarks and relative relationships to place major items.
- Do not use coordinates, layout hints, or copied room geometry from existing RoomScale examples as a description of the photographed room. Existing definitions may be consulted only to understand the schema and validator.
- Do not manually model the room in Godot, alter generated furniture after rendering, bypass the validator, or add photo-specific gameplay logic.
- Prefer recognizability, major layout, proportions, architectural landmarks, object placement, and major colors over exact measurements.
- Do not fabricate a door, window, wall opening, crown trim, ceiling, or object as observed when the images do not show it. Schema version 2 represents rectangular wall runs, door/window/clear openings, and optional flat ceiling/crown trim appearance; disclose any relevant detail the generic schema or renderer cannot represent instead of inventing a JSON field.
- A syntactically valid JSON file is not proof of a valid or playable room. Follow the validation and runtime workflow in the references.
