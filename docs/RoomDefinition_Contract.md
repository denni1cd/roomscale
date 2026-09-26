# RoomDefinition Contract

RoomDefinition is the text-data boundary between room reconstruction and the RoomScale simulation. The current implementation uses JSON in `rooms/`. A future photo pipeline may generate these files, but photo reconstruction is outside POC 1.5.

## Coordinate and measurement conventions

- All world distances are inches; citizen height is approximately 0.5 inch.
- `X` and `Z` span the floor plane; `Y` is vertical.
- Floor height is the walkable top of the floor. Object `position` is its floor-plane/base location; `dimensions` are width, height, and depth.
- Coordinates are world positions, not offsets from an implicit Room A origin. Floor center and dimensions define the room bounds.
- Rectangular surfaces and obstacle footprints are sufficient. Arbitrary mesh reconstruction and pathfinding are not part of this contract.

## Required room fields

| Field | Meaning |
| --- | --- |
| `schema_version` | Contract version; currently `1`. |
| `id`, `display_name` | Stable room key and user-facing label. |
| `dimensions` | `[width, depth]` of the floor in inches. |
| `floor` | `{center:[x,y,z], dimensions:[width,depth], height:y}`; dimensions must match the room. |
| `wall_height` | Positive wall height above the floor. |
| `objects` | Array of unique significant room objects. |
| `target_surface_id` | Region ID of the initially designated elevated surface. |
| `construction.depot_pickup` | Reachable floor coordinate where citizens collect project materials. |
| `landmarks` | Settlement building positions used by the production scene. |
| `activity_stations` | Valid floor work and patrol locations for autonomous citizen activity. |
| `spawn` | Center and horizontal `[width, 0, depth]` footprint for initial citizens. |
| `camera` | Initial focus and optional lighting positions for presentation. |

## Object fields

Every object has a unique `id`, a semantic `kind`, a display `name`, a 3D `position`, positive 3D `dimensions`, and `blocks_navigation`. `rotation_degrees` and `navigation_padding` are optional. Padding expands only the floor-navigation footprint; it does not change rendered bounds.

An elevated navigable surface is described by `surface`:

```json
{
  "region_id": "WORKBENCH_TOP",
  "height": 36,
  "anchor": [72, 36, -65]
}
```

The region ID must be unique and must match `target_surface_id` when it is the designated goal. `height` must agree with the top of the object and be below the room walls. `anchor` must be on the surface footprint. The current rectangular implementation derives investigation candidates from the object center, width/depth, rotation, navigation padding, safe clearance, room bounds, obstacle footprints, and floor reachability. An optional `approach_points` array may provide a validated hint/override for a future special case, but it is not required for ordinary rectangular surfaces.

Object kinds choose a generic procedural visual archetype. Unknown semantic labels remain data; adding a new visual archetype is a renderer extension, not a room-specific gameplay branch.

## Validation and runtime checks

Room loading fails with diagnostics for a missing/invalid floor, nonpositive or inconsistent dimensions, duplicate object IDs, out-of-bounds object or spawn footprints, malformed geometry, invalid surface height/anchor or optional approach hints, unknown target surface, and missing construction/activity metadata. Before citizens spawn, the active room must also yield at least two walkable and reachable geometry-derived target approaches and a reachable derived construction site.

The fast test exercises parsing, both valid room definitions, malformed cases, generated obstacles, target discovery, navigation approaches, reachable derived sites, region connectivity, and bounded task history. The full scenario verifies actual movement, hauling, construction, climbing, exploration, and route reuse for each room.

## Photo-to-RoomDefinition output contract

The future photo-reconstruction stage should provide:

1. Approximate metric scale and confidence/uncertainty for that estimate.
2. A floor center, boundary, dimensions, and height; room wall height and major wall extents.
3. Major object semantic labels and stable IDs with position, dimensions, and orientation.
4. Conservative floor-obstacle footprints and whether each object blocks floor navigation.
5. Elevated rectangular navigable surfaces with region IDs, footprint, height, and target anchor.
6. Enough elevated-surface geometry to derive reachable floor approaches; optional candidate hints may be supplied for special cases.
7. Settlement landmarks, a reachable depot pickup point, spawn region, activity stations, and camera framing metadata where these are not derived by the simulation.
8. Provenance/confidence for reconstructed fields so later tooling can distinguish measured values from defaults.

The simulation remains responsible for validating this data and deriving paths, investigation tasks, construction sites, and traversal routes. The reconstruction pipeline must not emit room-specific gameplay code or silently bypass validation.
