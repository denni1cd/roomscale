"""Build a presentation-only, faction-specific Scavenger settlement depot."""

from __future__ import annotations

import json
import math
import os
import sys
from datetime import UTC, datetime
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))

import production_batch01_blender as production
import scavenger_workshop_blender as salvage


def _build(output: Path) -> tuple[dict[str, int], dict[str, str]]:
    recipe_path = Path(os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", ""))
    recipe = json.loads(recipe_path.read_text(encoding="utf-8")) if recipe_path.is_file() else {}
    parameters = recipe.get("parameters", {})
    palette_config = parameters.get("material_palette", {})
    style_mode = str(parameters.get("material_strategy", "broad_scale_patina"))
    layout_mode = str(parameters.get("layout_strategy", "segmented_bay"))
    layout_mode = str(parameters.get("layout_strategy", "segmented_bay"))

    def color(name: str, fallback: tuple[float, float, float]) -> tuple[float, float, float]:
        return tuple(float(channel) for channel in palette_config.get(name, fallback))

    output.mkdir(parents=True, exist_ok=True)
    (output / "materials").mkdir(parents=True, exist_ok=True)
    production.clear_scene()

    mats = {
        "timber": salvage._material(
            "Scavenger depot reclaimed timber", (0.31, 0.20, 0.12), 0.0, 0.82,
            output / "materials", "depot_timber", "wood"
        ),
        "timber_light": salvage._material(
            "Scavenger depot sun-faded boards", (0.46, 0.32, 0.20), 0.0, 0.84,
            output / "materials", "depot_timber_light", "wood"
        ),
        "enamel_blue": salvage._material(
            "Scavenger depot faded blue enamel", color("enamel_blue", (0.13, 0.34, 0.40)),
            0.20, 0.43, output / "materials", "depot_enamel_blue", "enamel", style_mode
        ),
        "enamel_cream": salvage._material(
            "Scavenger depot chipped cream enamel", color("enamel_cream", (0.72, 0.66, 0.51)),
            0.18, 0.44, output / "materials", "depot_enamel_cream", "enamel", style_mode
        ),
        "enamel_ochre": salvage._material(
            "Scavenger depot ochre enamel patch", color("enamel_ochre", (0.55, 0.28, 0.12)),
            0.16, 0.50, output / "materials", "depot_enamel_ochre", "enamel", style_mode
        ),
        "sheet": salvage._material(
            "Scavenger depot mismatched galvanized sheets", color("galvanized", (0.39, 0.45, 0.45)),
            0.58, 0.57, output / "materials", "depot_galvanized", "galvanized", style_mode
        ),
        "canvas": salvage._material(
            "Scavenger depot patched olive canvas", (0.34, 0.37, 0.26), 0.0, 0.92,
            output / "materials", "depot_canvas", "canvas"
        ),
        "iron": salvage._material("Scavenger depot blackened iron", (0.10, 0.13, 0.14), 0.66, 0.62, output / "materials"),
        "rust": salvage._material("Scavenger depot oxide fasteners", (0.43, 0.20, 0.10), 0.38, 0.75, output / "materials"),
        "concrete": salvage._material("Scavenger depot broken concrete feet", (0.34, 0.34, 0.31), 0.0, 0.93, output / "materials"),
    }

    # The fitted depot uses Blender X=width, Y=depth, Z=height. The open loading
    # face is at negative Y, matching the existing settlement asset orientation.
    for x in (-10.6, 10.6):
        for y in (-8.35, 8.25):
            salvage._cube("Cracked concrete post foot", (2.1, 1.7, 0.75), (x, y, 0.42), mats["concrete"], 0.16)
            salvage._cube("Timber post shoe", (1.45, 1.35, 0.38), (x, y, 0.98), mats["timber_light"], 0.10)
    salvage._cube("Reclaimed sill under open bay", (21.0, 0.72, 0.48), (0.0, -8.45, 1.18), mats["timber"], 0.08)
    salvage._cube("Rear timber sill", (21.0, 0.72, 0.48), (0.0, 8.30, 1.18), mats["timber_light"], 0.08)
    for side in (-1, 1):
        salvage._cube("Side foundation runner", (0.72, 16.1, 0.48), (side * 10.65, 0.0, 1.18), mats["timber"], 0.07)

    front_y, rear_y = -8.25, 8.10
    front_top, rear_top = 10.35, 11.65
    wide_bay_layout = layout_mode in ("wide_single_bay", "open_gantry")
    support_xs = (-10.65, 10.65) if wide_bay_layout else (-10.65, -5.7, 5.7, 10.65)
    for x in support_xs:
        for y, top in ((front_y, front_top), (rear_y, rear_top)):
            salvage._beam("Bolted reclaimed frame post", (x, y, 1.35), (x, y, top), 0.78, 0.84, mats["timber"], 0.09)
            for z in (1.65, top - 0.70):
                production.box("Large iron post bracket", (x, y - 0.44, z), (0.95, 0.16, 0.82), mats["iron"], 0.05)
                for dx in (-0.27, 0.27):
                    salvage._cylinder("Visible bracket bolt", 0.095, 0.14, (x + dx, y - 0.54, z), mats["rust"], "y", 16, 0.008)

    # Continuous crossbeams and braces carry the roof and the centered hand hoist.
    salvage._beam("Front hoist crossbeam", (-11.1, front_y, front_top), (11.1, front_y, front_top), 0.82, 0.92, mats["timber_light"], 0.10)
    salvage._beam("Rear roof bearer", (-11.1, rear_y, rear_top), (11.1, rear_y, rear_top), 0.72, 0.82, mats["timber"], 0.09)
    for x in (-10.4, 10.4):
        for y0, y1, z0, z1 in ((front_y + 0.2, -3.8, 5.0, 10.0), (rear_y - 0.2, 3.7, 6.1, 11.25)):
            salvage._beam("Visible diagonal roof knee", (x, y0, z0), (x, y1, z1), 0.54, 0.60, mats["timber_light"], 0.065)
    for y, t in ((front_y, 0.0), (-3.2, 0.31), (2.4, 0.66), (rear_y, 1.0)):
        z = front_top + (rear_top - front_top) * t + 0.30
        salvage._beam("Roof purlin under sheet overlaps", (-11.35, y, z), (11.35, y, z), 0.45, 0.54, mats["timber"], 0.055)

    # Broad uneven rear boards keep the front and unloading route visually open.
    for index in range(19):
        x = -10.7 + index * 1.19
        height = 7.1 + (index % 4) * 0.36
        z = 1.35 + height * 0.5
        salvage._cube("Repaired drawer-board rear wall", (1.04, 0.38, height), (x, 8.54, z), mats["timber_light" if index % 3 == 0 else "timber"], 0.045, (0.0, 0.0, (index % 3 - 1) * 0.012))
    for x in (-10.2, -5.1, 0.0, 5.1, 10.2):
        salvage._beam("Rear wall vertical splice", (x, 8.29, 1.45), (x, 8.29, 9.15), 0.28, 0.30, mats["timber_light"], 0.025)
    salvage._cube("Rear door-slab repair patch", (4.8, 0.23, 3.2), (1.0, 8.28, 5.25), mats["enamel_ochre"], 0.10)

    # Half-height side rails and one fixed door slab on each side frame the bay.
    for side in (-1, 1):
        x = side * 10.72
        for z in (2.15, 3.20):
            salvage._beam("Side lower slat wall", (x, -6.8, z), (x, 7.2, z), 0.30, 0.32, mats["timber_light" if z < 2.5 else "timber"], 0.035)
        salvage._beam("Side wall top rail", (x, -6.7, 4.35), (x, 7.4, 4.35), 0.36, 0.40, mats["timber"], 0.045)
        salvage._beam("Side rail front brace", (x, -6.4, 2.1), (x, -3.9, 4.25), 0.24, 0.28, mats["timber_light"], 0.025)

    # Wide mismatched roof sheets use an asymmetric shallow slope and overlap.
    roof_front_y, roof_back_y = (-6.85, 9.25) if layout_mode == "open_gantry" else (-9.35, 9.25)
    for index in range(4):
        x0 = -11.75 + index * 5.82
        x1 = x0 + 6.15
        offset = (0.18, -0.10, 0.28, 0.0)[index]
        material = mats["sheet"] if index in (0, 3) else (mats["enamel_blue"] if index == 1 else mats["enamel_ochre"])
        salvage._roof_sheet(
            f"Large mismatched depot roof sheet {index + 1}", x0, x1, roof_front_y, roof_back_y,
            10.35 + offset, 11.68 + offset, material
        )
    front_purlin_y = roof_front_y + 0.65
    purlin_rows = ((front_purlin_y, 0.04), (-3.2, 0.34), (2.4, 0.65), (8.65, 0.97))
    for x in (-11.25, -5.7, 0.0, 5.7, 11.25):
        for y, t in purlin_rows:
            z = 10.35 + (11.68 - 10.35) * t + 0.31
            salvage._cylinder("Roof seam iron washer", 0.095, 0.10, (x, y, z + 0.08), mats["iron"], "z", 16, 0.006)
    salvage._beam("Front roof drip edge", (-11.55, roof_front_y, 10.45), (11.55, roof_front_y, 10.45), 0.23, 0.38, mats["sheet"], 0.035)

    # Fixed enamel appliance slabs flank the opening; hinges attach to frame posts.
    if layout_mode == "open_gantry":
        door_specs = [(-7.35, 6.40, 8.05, mats["enamel_blue"], "Faded blue refrigerator door"), (7.35, 6.40, 7.55, mats["enamel_cream"], "Chipped cream appliance door")]
    elif layout_mode == "wide_single_bay":
        door_specs = [(-7.65, 5.25, 7.35, mats["enamel_blue"], "Faded blue refrigerator door"), (7.65, 5.25, 6.90, mats["enamel_cream"], "Chipped cream appliance door")]
    else:
        door_specs = [(-8.25, 3.55, 6.75, mats["enamel_blue"], "Faded blue refrigerator door"), (8.20, 3.65, 6.10, mats["enamel_cream"], "Chipped cream appliance door")]
    for x, width, height, door_mat, door_name in door_specs:
        center_z = 1.45 + height * 0.5
        door_y = -8.96 if layout_mode == "open_gantry" else -8.88
        door_depth = 0.38 if layout_mode == "open_gantry" else 0.30
        salvage._cube(door_name, (width, door_depth, height), (x, door_y, center_z), door_mat, 0.16 if layout_mode == "open_gantry" else 0.13)
        for hinge_z in (center_z - height * 0.34, center_z + height * 0.34):
            strap_width = 0.32 if wide_bay_layout else 0.18
            strap_height = 1.65 if wide_bay_layout else 1.35
            salvage._cube("Fixed door iron strap", (strap_width, 0.12, strap_height), (x - width * 0.38, door_y - 0.20, hinge_z), mats["iron"], 0.045)
            if wide_bay_layout:
                for z in (hinge_z - 0.48, hinge_z + 0.48):
                    salvage._cube("Door strap square bolt", (0.16, 0.10, 0.16), (x - width * 0.38, door_y - 0.29, z), mats["rust"], 0.025)
            else:
                salvage._cylinder("Fixed door hinge barrel", 0.13, 0.68, (x - width * 0.49, -9.10, hinge_z), mats["rust"], "z", 18, 0.018)
                for z in (hinge_z - 0.43, hinge_z + 0.43):
                    salvage._cylinder("Door strap bolt", 0.075, 0.10, (x - width * 0.38, -9.17, z), mats["iron"], "y", 14, 0.006)
        patch_mat = mats["enamel_ochre"] if door_mat == mats["enamel_blue"] else mats["enamel_blue"]
        patch_size = (width * 0.64, 0.14, 1.30) if layout_mode == "open_gantry" else (width * 0.68, 0.12, 0.72)
        salvage._cube("Appliance panel broad repair patch", patch_size, (x + 0.22, door_y - 0.22, 2.35), patch_mat, 0.07)
        salvage._cube("Appliance panel pull handle", (0.22, 0.18, 1.10 if layout_mode == "open_gantry" else 0.92), (x + width * 0.22, door_y - 0.31, center_z), mats["iron"], 0.06)

    # A bold, simple hanging tackle keeps the central loading route readable
    # at the settlement camera without a gear-like focal silhouette.
    salvage._cube("Hoist saddle plate", (1.65, 0.38, 0.26), (0.0, front_y - 0.02, 10.82), mats["iron"], 0.055)
    if wide_bay_layout:
        hoist_y = -8.70 if layout_mode == "open_gantry" else -8.58
        block_mat = mats["enamel_cream"] if layout_mode == "open_gantry" else mats["timber_light"]
        block_size = (1.72, 0.80, 1.48) if layout_mode == "open_gantry" else (1.42, 0.72, 1.28)
        salvage._cube("Readable timber rope block", block_size, (0.0, hoist_y, 9.35), block_mat, 0.15)
        salvage._cube("Rope block iron cheek plate", (1.52, 0.12, 0.72), (0.0, hoist_y - 0.40, 9.35), mats["iron"], 0.07)
        for x in (-0.52, 0.52):
            salvage._cube("Rope block square rivet", (0.14, 0.08, 0.14), (x, hoist_y - 0.47, 9.35), mats["rust"], 0.025)
        rope_radius = 0.16 if layout_mode == "open_gantry" else 0.14
        production.tube("Visible hand rope above open bay", [(0.0, hoist_y, 10.52), (0.0, hoist_y, 9.15), (0.0, hoist_y + 0.05, 7.55), (0.0, hoist_y + 0.10, 6.25)], rope_radius, mats["timber_light"], 3)
        production.tube("Large plain unloading hook", [(0.0, hoist_y + 0.10, 6.25), (0.0, hoist_y + 0.10, 5.60), (0.18, hoist_y + 0.10, 5.30), (0.52, hoist_y + 0.10, 5.34), (0.66, hoist_y + 0.10, 5.62), (0.60, hoist_y + 0.10, 5.90)], 0.14, mats["iron"], 3)
    else:
        for x in (-0.56, 0.56):
            salvage._cylinder("Hoist pulley wheel", 0.62, 0.38, (x, -8.20, 9.82), mats["timber_light"], "y", 28, 0.035)
            salvage._torus("Iron pulley rim", 0.54, 0.075, (x, -8.42, 9.82), mats["iron"], "y")
            salvage._cylinder("Pulley axle", 0.16, 0.62, (x, -8.42, 9.82), mats["iron"], "y", 20, 0.02)
        production.tube("Hoist rope over loading bay", [(0.0, -8.45, 10.0), (0.0, -8.15, 9.4), (0.0, -8.10, 7.5), (0.0, -8.05, 6.2)], 0.12, mats["timber_light"], 3)
        production.tube("Parked forged unloading hook", [(0.0, -8.05, 6.25), (0.0, -8.05, 5.8), (0.26, -8.05, 5.55), (0.38, -8.05, 5.90), (0.34, -8.05, 6.15)], 0.11, mats["iron"], 3)

    # Storage sits to the side edges; the center floor from sill to rear stays open.
    crate_x, crate_y = -8.8, 3.4
    salvage._cube("Side storage crate base", (3.8, 3.1, 0.42), (crate_x, crate_y, 1.45), mats["timber"], 0.07)
    for x in (crate_x - 1.75, crate_x + 1.75):
        for y in (crate_y - 1.42, crate_y + 1.42):
            salvage._beam("Side crate corner post", (x, y, 1.55), (x, y, 4.25), 0.26, 0.26, mats["timber_light"], 0.025)
    for row in range(4):
        z = 1.95 + row * 0.58
        for y in (crate_y - 1.42, crate_y + 1.42):
            salvage._cube("Slatted crate end board", (3.5, 0.18, 0.45), (crate_x, y, z), mats["timber_light" if row % 2 else "timber"], 0.025)
    if layout_mode == "open_gantry":
        # Broad, presentation-only deck boards make the empty route visible
        # from the gameplay camera; they add no collision or work data.
        for index, x in enumerate((-3.15, -1.05, 1.05, 3.15)):
            salvage._cube(
                "Wide center unloading route board %d" % index,
                (1.92, 10.8, 0.18),
                (x, -1.05, 1.52),
                mats["timber_light"] if index in (0, 3) else mats["timber"],
                0.035,
            )
    basket_x, basket_y = 8.55, 3.0
    bx, by, bz = 3.5, 3.6, 4.1
    for x in (basket_x - bx * 0.5, basket_x + bx * 0.5):
        for y in (basket_y - by * 0.5, basket_y + by * 0.5):
            salvage._rod("Wire basket upright", (x, y, 1.45), (x, y, bz), 0.08, mats["iron"])
    for z in (1.55, 2.0, 2.75, 3.50, 4.05):
        for x0, x1 in ((basket_x - bx * 0.5, basket_x + bx * 0.5),):
            for y in (basket_y - by * 0.5, basket_y + by * 0.5):
                salvage._rod("Wire basket horizontal rail", (x0, y, z), (x1, y, z), 0.055, mats["iron"])
        for x in (basket_x - bx * 0.5, basket_x + bx * 0.5):
            for y0, y1 in ((basket_y - by * 0.5, basket_y + by * 0.5),):
                salvage._rod("Wire basket side rail", (x, y0, z), (x, y1, z), 0.055, mats["iron"])

    # Small patched canvas piece is fastened to the quiet rear roof edge.
    salvage._cube("Rear roof canvas repair", (4.2, 0.22, 0.10), (-6.1, 6.3, 12.03), mats["canvas"], 0.04, (0.05, 0.0, 0.10))
    for x in (-8.1, -6.0, -4.0):
        salvage._cube("Canvas repair batten", (0.16, 0.30, 0.22), (x, 6.28, 12.08), mats["timber_light"], 0.025)

    object_counts: dict[str, int] = {}
    for material in list(bpy.data.materials):
        objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and any(slot.material == material for slot in obj.material_slots)]
        if not objects:
            continue
        object_counts[material.name] = len(objects)
    production.apply_modifiers_and_merge_by_material()
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    return object_counts, {key: material.name for key, material in mats.items()}


def main(project_root: Path, output: Path) -> None:
    _, material_names = _build(output)
    recipe_path = os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", "")
    recipe = json.loads(Path(recipe_path).read_text(encoding="utf-8")) if recipe_path and Path(recipe_path).is_file() else {}
    glb = output / "scavenger_depot.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(glb), export_format="GLB", use_selection=True, export_apply=True,
        export_materials="EXPORT", export_yup=True, export_texcoords=True,
        export_normals=True, export_tangents=True, export_cameras=False, export_lights=False,
    )
    record = {
        "asset_id": "scavenger_depot",
        "method": "blender_salvage_door_slab_gantry_depot",
        "approved_visual_target": "art/scavenger_depot/visual_director/round-01/approved-target-r01.png",
        "envelope_inches": [24.0, 13.0, 20.0],
        "dimensions_checked_by": "Godot candidate validation; see technical-validation.json",
        "material_strategy": recipe.get("parameters", {}).get("material_strategy", "broad_scale_patina"),
        "material_names": material_names,
        "geometry_features": [
            "wide open loading bay with clear center floor and fixed paired appliance side slabs",
            "asymmetric overlapped sheet roof supported by timber posts, braces, bearers and purlins",
            "centered simple rope block and plain unloading hook carried by the front crossbeam",
            "repaired drawer-board rear wall, side crate and wire basket bay",
            "broad faded enamel, galvanized patches, rough timber, iron and a small rear canvas repair",
        ],
        "presentation_only": True,
        "gameplay_changes": False,
        "output": glb.name,
        "generated_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
    }
    (output / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"SCAVENGER_DEPOT_GENERATED {glb} meshes={len([obj for obj in bpy.context.scene.objects if obj.type == 'MESH'])}")


if __name__ == "__main__":
    if len(os.sys.argv) < 3:
        raise SystemExit("usage: scavenger_depot_blender.py PROJECT_ROOT OUTPUT_DIR")
    main(Path(os.sys.argv[-2]).resolve(), Path(os.sys.argv[-1]).resolve())
