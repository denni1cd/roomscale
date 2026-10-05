# RoomDefinition Contract

`RoomDefinition` is the text-data boundary between room producers and the RoomScale simulation. The production loader consumes JSON files under `rooms/`; the reconstruction AI produces the same data format as any other room author. The current validator accepts legacy schema version `1` and appearance-capable schema version `2`.

## Coordinate and measurement conventions

- All world distances are inches; citizens are approximately `0.5` inch tall.
- `X` and `Z` span the floor plane; `Y` is vertical.
- `floor.height` is the walkable floor top. `floor.center` uses that same Y coordinate. Floor objects' `position` is their base center on the floor; `dimensions` are `[width,height,depth]`. Elevated visual objects can use a higher base Y when `blocks_navigation` is false.
- Coordinates are world positions, not offsets from an implicit Room A origin. The rectangular floor's center and dimensions define its bounds.
- Keep every floor placement and footprint at least 1 inch inside the floor perimeter. The validator applies this clearance to object bounds (including rotated, padded footprints), spawn footprint, landmark/station/depot points, and approach points.
- Object `rotation_degrees` is a yaw around `Y`. Optional `navigation_padding` is a nonnegative three-number vector `[x,y,z]`, defaulting to `[0,0,0]`. X/Z padding expands the object's local horizontal footprint before rotation; Y is accepted but ignored by floor/surface navigation. Padding changes navigation bounds, not rendered bounds.
- Rectangular surfaces and footprints are sufficient. RoomScale derives floor navigation and traversal; RoomDefinition does not contain paths or gameplay scripts.

## Required root fields

| Field | Type and meaning |
| --- | --- |
| `schema_version` | Integer `1` or `2`. Version 1 keeps existing rooms working. New photo-generated rooms should use version 2. |
| `id`, `display_name` | Nonempty room key and user-facing label. Room IDs start with a letter or digit and use only letters, digits, underscores, or hyphens. `id` is also the room JSON filename without its `.json` suffix. |
| `dimensions` | Positive `[width,depth]` in inches. |
| `floor` | `{center:[x,y,z], dimensions:[width,depth], height:y}`; `center.y` equals `height`, and dimensions match the room. |
| `wall_height` | Positive wall height above the floor. |
| `objects` | Nonempty array of room-object records. |
| `target_surface_id` | Unique elevated surface region ID selected as the initial goal. |
| `construction.depot_pickup` | Reachable floor position inside the room where citizens collect project materials. The construction site is derived from target geometry. |
| `landmarks` | Positions inside the floor bounds for the simulation-generated `workshop`, `depot`, `housing`, and `work_area`. |
| `activity_stations` | A `workshop` point list, one `housing` point, one `work_area` point, and at least four `patrol` points, all inside the floor bounds. |
| `spawn` | `{ "center":[x,y,z], "dimensions":[width,0,depth] }`; center is 3D, X/Z footprint dimensions must be positive, and the footprint must stay within the 1-inch floor-edge clearance. The middle dimension is a zero vertical placeholder and is ignored for horizontal placement. |
| `room_shell` | Required for version 2; omitted in legacy version 1. Defines wall runs/openings and shell appearance. An opening may optionally carry an `exterior_scene`. |
| `camera` | Optional framing and lighting overrides. Defaults are derived from the room when omitted. |

All world positions for spawn, landmarks, activity stations, and depot pickup use the walkable floor Y coordinate. Keep the generated settlement clear of major reconstructed objects.

## Room objects

Every object requires a unique nonempty `id`, nonempty semantic `kind`, 3D `position`, positive `[width,height,depth]` `dimensions`, and a boolean `blocks_navigation`. `name` is an optional display label; navigation uses the object ID when it is absent. `rotation_degrees` and `navigation_padding` are optional. If provided, `navigation_padding` must be three finite nonnegative numbers in `[x,y,z]` order; omit it or use `[0,0,0]` for no padding. X/Z expand the local horizontal footprint before rotation, while Y does not affect 2D navigation. Object bounds and expanded navigation footprints must fit within the floor with the 1-inch interior clearance, including rotation, and the object's vertical bounds must stay between the walkable floor and room ceiling. Objects with `blocks_navigation:true` are floor-bound and their base Y must equal `floor.height`. Elevated visual objects such as hanging decorations may use a higher base Y only when `blocks_navigation:false`.

Legacy version 1 can use `color` as an optional base-color string. Version 2 should put appearance in the `appearance` object:

```json
"appearance": {
  "archetype": "table",
  "base_color": "81593e",
  "accent_color": "b7955b",
  "material": "wood",
  "transparency": 0.0
}
```

Supported material categories are `wood`, `metal`, `fabric`, `glass`, `stone`, `plastic`, `ceramic`, `paint`, `plant`, and `other`. Appearance fields are optional: `archetype`, `base_color`, `accent_color`, `glass_color`, `material`, and `transparency`. The colors are HTML colors (3, 4, 6, or 8 hexadecimal digits, with an optional `#`); transparency ranges from `0` opaque to `1` transparent. Colors default to legacy `color` and then a generic value. Materials select visual appearance and, when no explicit resource profile is supplied, contribute to the default finite salvage profile. Explicit resource metadata controls authored yields and stages.

The renderer recognizes these generic object archetypes: `rug`, `table`, `desk`, `workbench`, `chair`, `rocking_chair`, `office_chair`, `hammock`, `monitor`, `monitor_pair`, `display_cabinet`, `floor_lamp`, `floor_seat`, `triptych_art`, `wall_emblem`, `framed_map`, `fabric_pile`, `blanket_pile`, `boxed_collectibles`, `octagonal_glass_table`, `stone_fireplace`, `cabinet`, `bookcase`, `built_in_bookcase`, `wardrobe`, `shelf`, `dresser`, `bed`, `sofa`, `cylinder`, `plant`, and `box_with_lid`. `dragon_triptych` and `dragon_emblem` remain accepted as compatibility aliases for the generic `triptych_art` and `wall_emblem` geometry; neither alias draws dragon-specific forms. `simple`, `box`, and unknown archetypes use a generic styled box while retaining the object's semantic `kind`.

The semantic `kind` labels the real object. `appearance.archetype` selects a general procedural shape. They need not be identical: for example, kind `desk` may use archetype `table`. Do not encode behavior or room-specific game code in either field.

## Elevated surfaces

Describe a useful raised top with an object's `surface`:

```json
"surface": {
  "region_id": "WORKTABLE_TOP",
  "height": 30,
  "anchor": [0, 30, 0]
}
```

`region_id` must be unique and must match root `target_surface_id` for the selected goal. `height` equals object base Y plus object height and remains below the wall height. `anchor` lies on the rotated object top. The simulation derives reachable approaches and construction site from the object footprint, yaw, navigation padding, room bounds, obstacles, and reachability. Optional `approach_points` are floor-space hints, not route instructions, and require at least two valid points.

## Version 2 room shell and openings

`room_shell` carries the visible architectural shell without changing gameplay navigation. Its rectangular perimeter edges are:

- `north`: negative Z, progressing from west to east;
- `south`: positive Z, progressing from west to east;
- `west`: negative X, progressing from north to south;
- `east`: positive X, progressing from north to south.

Example:

```json
"room_shell": {
  "wall_thickness": 2,
  "baseboard_height": 3,
  "baseboard_appearance": {"base_color":"76583f", "material":"wood"},
  "ceiling_appearance": {"base_color":"38a6a1", "material":"paint"},
  "crown_molding_height": 4,
  "crown_molding_appearance": {"base_color":"b58650", "material":"wood"},
  "floor_appearance": {"base_color":"795b43", "material":"wood"},
  "walls": [
    {"id":"north-wall", "side":"north", "appearance":{"base_color":"d9c9aa", "material":"paint"},
     "openings":[
       {"id":"north-window", "kind":"window", "offset":72, "width":44, "bottom":30, "height":36,
        "appearance":{"base_color":"99bac4", "accent_color":"f0ead8", "material":"glass", "transparency":0.32},
        "exterior_scene":{"elements":[
          {"shape":"box", "position":[0,0,80], "dimensions":[80,50,1], "appearance":{"base_color":"7eaeb2", "material":"paint"}},
          {"shape":"sphere", "position":[24,8,44], "dimensions":[16,18,14], "appearance":{"base_color":"3b6240", "material":"plant"}}
        ]}}
     ]}
  ]
}
```

Each side may have at most one wall record. Side values must use lowercase `north`, `south`, `east`, or `west`; opening kinds must use lowercase `door`, `window`, or `opening`. Omit a side only when that wall is absent or open in the photographed room. A wall uses root `wall_height`; shell `wall_thickness` defaults to 2 inches. `baseboard_height` defaults to 3 inches and may be zero to omit trim. Baseboard segments leave a gap anywhere an opening begins below the trim height. Wall, baseboard, floor, ceiling, and crown appearances use the same generic appearance fields as objects.

`ceiling_appearance` is optional. When present, it renders a flat visual ceiling at `floor.height + wall_height`; an empty object uses the generic warm-white paint defaults. Its one-sided surface preserves the open overhead room view. Omit it for a room that should remain open from every camera angle. `crown_molding_height` defaults to zero, so crown molding is off unless a positive height is supplied. The optional `crown_molding_appearance` defaults to the generic warm trim color; crown segments continue around the wall corners, project 0.75 inches beyond the interior wall face, and stop where an opening reaches into the crown band. Ceiling and crown geometry is visual-only and has no navigation or collision effect. Vaulted or sloped ceilings are not represented by this rectangular v2 shell.

Opening `offset` and `width` are inches along the named side from that side's start point; their total must not exceed the side length. `bottom` is the opening's vertical distance above the floor, and `height` is its vertical size; the opening must fit inside `wall_height`. Kinds are `door`, `window`, and `opening`. Door bottom is zero. A window renders a translucent pane and frame; a door renders a panel and frame; an `opening` is a clear cutout. `appearance.base_color` colors window glazing or a solid door panel, `accent_color` colors the wood frame/muntins, `glass_color` colors glazed doors, and `transparency` applies to glazing. Window archetypes `transomed_window` and `shaded_window` add generic muntins or a roller shade; door archetypes `french_door` and `sliding_glass_door` add generic glazing and framing. Unknown opening archetypes fall back to the plain pane/frame or opaque panel/frame for the opening kind.

There is no automatic outdoor scenery. Add optional `exterior_scene` only when the photos show scenery worth representing. Its required `elements` array contains at most 64 generic visual primitives. Each element has `shape` (`box`, `sphere`, or vertical `cylinder`), `position` `[along, up, outward]`, and positive `dimensions` `[along, vertical, outward]`, measured in inches. The origin is the center of the opening on the outer wall face; `along` follows increasing offset on the wall, `up` is world `+Y`, and positive `outward` points away from the room. For cylinders, the two radial dimensions must match. An element may include the same optional `appearance` fields as an object. Position offsets are limited to 2,000 inches in magnitude and dimensions to 2,000 inches per axis. The field is optional, ignored when absent, and has no collision or gameplay effect; without it a window produces no deck, rail, tree, or foliage geometry.

The renderer creates actual wall segments around every opening rather than placing a prop over a solid wall. Openings and exterior-scene primitives are visual shell features; citizens use floor bounds and furniture obstacles for navigation.

For an unobstructed default room view, optional `camera.cutaway_wall_id` hides one wall from the initial room composition while preserving its data and openings in RoomDefinition. Choose a wall whose removal best exposes the photographed layout. The camera can orbit to inspect the remaining shell. Optional `camera.focus`, `yaw_degrees`, `fill_position`, and `lantern_position` override derived presentation defaults.

## Validation and runtime

`scripts/room_definition.gd` validates structure and field ranges before the population starts. Validation includes version, required metadata, finite geometry, rotated floor bounds, elevated visual-object bounds, appearance colors/materials/transparency, ceiling/crown appearance types and crown height, lowercase wall sides/opening kinds, opening extents/overlap, exterior-scene shape/size/count limits, cutaway references, surface geometry, and target references. Runtime navigation validation then requires at least two walkable, reachable target approaches and a reachable derived construction site.

The loader selects any safe room ID under `rooms/`, or a project-local `.json` path through `ROOMSCALE_ROOM_FILE`. `RUN_ROOM_SCALE.ps1` and `TEST_ROOM_SCALE.ps1 -Room` accept either a room ID or a project-local JSON path. For a file path, the filename without `.json` must match `id`; paths outside the project are rejected.

The fast test exercises both legacy rooms, malformed input, schema v2 fixtures, room-shell openings, generic appearances, rotated geometry, nonzero floor elevation, project-local candidate loading, geometry-derived obstacles/targets/approaches/sites, navigation connectivity, and bounded task history. Full production scenarios verify movement, hauling, construction, climbing, exploration, and route reuse. A valid JSON parse is not equivalent to passing either validator or full gameplay.

The reconstruction skill records uncertainty separately from the JSON. The RoomDefinition remains inspectable; no AI state or room-specific gameplay logic is required at runtime.

## Optional POC 4 civilization economy

An ordinary schema 1 or 2 RoomDefinition can enable the production needs/economy simulation with:

```json
"civilization": {
  "stock": {"food":300, "water":100, "wood":0, "metal":0},
  "shelter_capacity":50,
  "rest_capacity":12,
  "economy_construction":true
}
```

Stock is finite and nonnegative. Capacities are finite nonnegative integers. This metadata does not change object geometry, spawn, stations or surface requirements. Existing room files remain valid without it. Economy construction uses the existing grapple stages and route system, with four wood and four metal supplied through actual reservations/pickups/deliveries.

Objects can provide optional `resource_profile` metadata:

```json
"resource_profile": {
  "contents":{"water":25000},
  "region_id":"WORKTABLE_TOP",
  "work_seconds":2
}
```

This represents a finite survival resource. The object position is the citizen extraction point and must lie in its navigation region. A floor source uses `FLOOR`; a source on a table uses the table surface region and sits at its height. Extraction reserves content, requires on-site citizen work, then creates a carried bundle. Depot inventory changes only after the return trip. No source automatically refills.

Furniture salvage derives conservative stages from semantic/material data. Wooden chair/table/desk/workbench/bookcase/box/crate defaults can infer wood; explicit `appearance.material` takes precedence. Unknown non-material objects remain non-harvestable. Explicit resource_profile fields can override `harvestable`, `protected`, `work_seconds`, and `stages`:

```json
"resource_profile": {
  "harvestable":true,
  "protected":true,
  "stages":[
    {"name":"STRIPPED", "work":8, "yields":{"metal":2}},
    {"name":"PARTIAL", "work":12, "yields":{"wood":5,"metal":2}},
    {"name":"FRAME", "work":12, "yields":{"wood":3}},
    {"name":"DEPLETED", "work":10, "yields":{"wood":5}}
  ]
}
```

Every destructive object still requires explicit civilization-level authorization. Stages are finite, work-driven, once-only and session-persistent; presentation uses predetermined geometry. No object ID or canonical coordinates select a resource rule. Active infrastructure/source-support surfaces are protected against unsafe dismantling. See [POC 4 gameplay](POC4_GAMEPLAY.md) for scoring, consumption and verification commands.
# POC 4.5 canonical configuration note

`rooms/room_poc45.json` derives from the POC 4 definition without a schema change.
It keeps the elevated water source and zero starting construction material, adjusts
finite food/water contents, and adds two ordinary crates. Fishbowl activation is an
explicit launch setting (`ROOMSCALE_FISHBOWL=1`), not inferred from a room ID.
Explicit `resource_profile.protected: true` prevents autonomous salvage; inferred
default protection retains the ordinary manual-authorization rule. Runtime settlement
obstacles are derived from development projects, never hand-authored housing sites.
See `docs/POC45_FISHBOWL.md` for the generalized policy and project contract.
