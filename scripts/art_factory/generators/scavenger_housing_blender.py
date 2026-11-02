"""Build a presentation-only paired Scavenger cottage asset."""

from __future__ import annotations

import json
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
    palette = parameters.get("material_palette", {})
    material_strategy = str(parameters.get("material_strategy", "broad_scale_patina"))

    def color(name: str, fallback: tuple[float, float, float]) -> tuple[float, float, float]:
        return tuple(float(channel) for channel in palette.get(name, fallback))

    output.mkdir(parents=True, exist_ok=True)
    (output / "materials").mkdir(parents=True, exist_ok=True)
    production.clear_scene()

    mats = {
        "timber": salvage._material("Scavenger housing reclaimed timber", (0.28, 0.18, 0.11), 0.0, 0.86, output / "materials", "housing_timber", "wood", material_strategy),
        "timber_light": salvage._material("Scavenger housing sun-faded boards", (0.47, 0.34, 0.23), 0.0, 0.87, output / "materials", "housing_timber_light", "wood", material_strategy),
        "blue": salvage._material("Scavenger housing faded blue enamel", color("enamel_blue", (0.10, 0.38, 0.55)), 0.16, 0.46, output / "materials", "housing_enamel_blue", "enamel", material_strategy),
        "cream": salvage._material("Scavenger housing cream enamel", color("enamel_cream", (0.78, 0.70, 0.55)), 0.12, 0.48, output / "materials", "housing_enamel_cream", "enamel", material_strategy),
        "sheet": salvage._material("Scavenger housing galvanized roof sheets", color("galvanized", (0.48, 0.52, 0.52)), 0.55, 0.62, output / "materials", "housing_galvanized", "galvanized", material_strategy),
        "rust": salvage._material("Scavenger housing rust patches", color("rust", (0.39, 0.18, 0.10)), 0.2, 0.73, output / "materials", "housing_rust", "rust", material_strategy),
        "canvas": salvage._material("Scavenger housing patched canvas", (0.57, 0.46, 0.31), 0.0, 0.94, output / "materials", "housing_canvas", "canvas", material_strategy),
        "iron": salvage._material("Scavenger housing plain iron straps", (0.16, 0.19, 0.19), 0.7, 0.52, output / "materials", "housing_iron", "metal", material_strategy),
        "glass": salvage._material("Scavenger housing reused window glass", (0.23, 0.34, 0.34), 0.08, 0.31, output / "materials", "housing_glass", "glass", material_strategy),
    }

    # The matched pair sits inside a 17 x 7 x 9 inch envelope. Front faces -Y.
    # Left and right roofs intentionally have different low silhouettes.
    x_centers = (-4.15, 4.15)
    front_y, back_y = -1.60, 4.10
    wall_floor, wall_top = 0.55, 4.05
    for house_index, center_x in enumerate(x_centers):
        half_width = 3.55
        left_x, right_x = center_x - half_width, center_x + half_width
        front_frame_y, rear_frame_y = -1.38, 3.92
        if house_index == 0:
            roof_front_y, roof_back_y = -2.58, 4.28
            roof_front_z, roof_back_z = 5.14, 6.52
        else:
            # The short lean-to is set back from the canopy, lower at its rear,
            # and separated from its neighbor by an open seam at the roofline.
            roof_front_y, roof_back_y = -1.25, 3.35
            roof_front_z, roof_back_z = 5.46, 4.86
        front_support_top = roof_front_z - 0.13
        rear_support_top = roof_back_z - 0.13

        # Main walls use broad repaired drawer boards with a clearly exposed frame.
        for board_index in range(12):
            x = left_x + 0.30 + board_index * 0.57
            shade = "timber_light" if board_index % 3 == 0 else "timber"
            salvage._cube("Cottage front reclaimed vertical board", (0.54, 0.22, wall_top - wall_floor), (x, front_y, (wall_top + wall_floor) * 0.5), mats[shade], 0.025)
            salvage._cube("Cottage rear reclaimed vertical board", (0.54, 0.22, wall_top - wall_floor), (x, back_y, (wall_top + wall_floor) * 0.5), mats[shade], 0.025)
        for side_x in (left_x, right_x):
            for board_index in range(10):
                y = -1.15 + board_index * 0.54
                shade = "timber_light" if board_index % 4 == 0 else "timber"
                salvage._cube("Cottage side reclaimed vertical board", (0.22, 0.50, wall_top - wall_floor), (side_x, y, (wall_top + wall_floor) * 0.5), mats[shade], 0.025)

        # Four corner posts and front/rear bearers make the roof load path legible.
        for x in (left_x, right_x):
            for y, top in ((front_frame_y, front_support_top), (rear_frame_y, rear_support_top)):
                salvage._beam("Cottage structural corner post", (x, y, wall_floor), (x, y, top), 0.36, 0.38, mats["timber_light"], 0.045)
        for y, top in ((front_frame_y, front_support_top - 0.08), (rear_frame_y, rear_support_top - 0.08)):
            salvage._beam("Cottage wall header", (left_x, y, top), (right_x, y, top), 0.34, 0.34, mats["timber"], 0.04)
        for x in (left_x + 0.18, right_x - 0.18):
            salvage._beam("Visible diagonal roof support", (x, front_frame_y, 2.45), (x + (0.62 if x < center_x else -0.62), front_frame_y, front_support_top - 0.12), 0.22, 0.24, mats["timber_light"], 0.025)
            salvage._beam("Rear roof knee brace", (x, rear_frame_y, 2.55), (x + (0.58 if x < center_x else -0.58), rear_frame_y, rear_support_top - 0.12), 0.20, 0.22, mats["timber"], 0.022)

        # A large appliance slab is the first-read faction mark on each cottage.
        door_x = center_x - 0.75 if house_index == 0 else center_x + 0.72
        door_mat = mats["blue"] if house_index == 0 else mats["cream"]
        salvage._cube("Reused appliance door dark reveal", (2.55, 0.10, 3.08), (door_x, front_y - 0.16, 2.14), mats["iron"], 0.05)
        salvage._cube("Broad salvaged appliance door slab", (2.33, 0.17, 2.91), (door_x, front_y - 0.25, 2.15), door_mat, 0.075)
        for strap_x in (door_x - 0.91, door_x + 0.91):
            for z in (1.18, 3.10):
                salvage._cube("Plain appliance door iron strap", (0.14, 0.07, 0.34), (strap_x, front_y - 0.36, z), mats["iron"], 0.018)
        salvage._cube("Simple horizontal door pull", (0.62, 0.12, 0.10), (door_x + 0.48, front_y - 0.38, 2.12), mats["iron"], 0.025)

        # Small framed reuse-glass windows stay secondary to the color-block doors.
        window_x = center_x + 2.35 if house_index == 0 else center_x - 2.35
        salvage._cube("Cottage window dark inset", (1.18, 0.11, 1.12), (window_x, front_y - 0.16, 2.70), mats["iron"], 0.04)
        salvage._cube("Cottage reuse glass pane", (0.94, 0.06, 0.88), (window_x, front_y - 0.23, 2.70), mats["glass"], 0.015)
        for side in (-1, 1):
            salvage._beam("Timber window jamb", (window_x + side * 0.60, front_y - 0.30, 2.08), (window_x + side * 0.60, front_y - 0.30, 3.32), 0.11, 0.12, mats["timber_light"], 0.018)
        for z in (2.08, 3.32):
            salvage._beam("Timber window rail", (window_x - 0.60, front_y - 0.30, z), (window_x + 0.60, front_y - 0.30, z), 0.11, 0.12, mats["timber_light"], 0.018)
        salvage._beam("Window crossbar", (window_x - 0.46, front_y - 0.32, 2.70), (window_x + 0.46, front_y - 0.32, 2.70), 0.07, 0.08, mats["timber"], 0.012)

        # Broad sheet patches follow two different, restrained roof silhouettes.
        if house_index == 0:
            salvage._roof_sheet("Left cottage tall asymmetric sheet canopy", left_x - 0.08, right_x + 0.08, roof_front_y, roof_back_y, roof_front_z, roof_back_z, mats["sheet"])
            canvas_back_z = roof_front_z + (roof_back_z - roof_front_z) * ((0.25 - roof_front_y) / (roof_back_y - roof_front_y)) - 0.04
            salvage._roof_sheet("Left cottage faded canvas roof repair", left_x + 0.12, left_x + 2.45, roof_front_y - 0.06, 0.25, roof_front_z + 0.04, canvas_back_z, mats["canvas"])
        else:
            salvage._roof_sheet("Right cottage short patched lean-to", left_x + 0.08, right_x + 0.08, roof_front_y, roof_back_y, roof_front_z, roof_back_z, mats["sheet"])
            right_patch_back_z = roof_front_z + (roof_back_z - roof_front_z) * ((0.60 - roof_front_y) / (roof_back_y - roof_front_y)) - 0.05
            salvage._roof_sheet("Right cottage enamel roof patch", center_x + 0.55, right_x, roof_front_y + 0.06, 0.60, roof_front_z + 0.02, right_patch_back_z, mats["rust"])
            right_canvas_back_z = roof_front_z + (roof_back_z - roof_front_z) * ((0.10 - roof_front_y) / (roof_back_y - roof_front_y)) - 0.08
            salvage._roof_sheet("Right cottage canvas eave repair", center_x + 1.25, right_x - 0.10, roof_front_y - 0.04, 0.10, roof_front_z + 0.02, right_canvas_back_z, mats["canvas"])

        # Crosswise purlins sit directly below the roof sheets and visibly carry them.
        for fraction in (0.0, 0.5, 1.0):
            y = roof_front_y + (roof_back_y - roof_front_y) * fraction
            z = roof_front_z + (roof_back_z - roof_front_z) * fraction - 0.08
            salvage._beam("Roof purlin beneath sheet overlap", (left_x - 0.06, y, z), (right_x + 0.06, y, z), 0.18, 0.20, mats["timber"], 0.022)

    # A single shared uneven porch is supported at its outer edge and center seam.
    for plank in range(17):
        x0 = -8.16 + plank * 0.96
        width = 0.91 if plank % 3 else 0.80
        y = -2.95 + (plank % 3) * 0.04
        salvage._cube("Shared porch reclaimed deck board", (width, 3.05, 0.20), (x0 + width * 0.5, y, 0.26), mats["timber_light" if plank % 4 == 0 else "timber"], 0.028, (0.0, 0.0, (plank % 3 - 1) * 0.008))
    for x in (-8.05, -0.05, 8.05):
        salvage._beam("Shared porch outer support post", (x, -4.05, 0.12), (x, -4.05, 1.52), 0.30, 0.32, mats["timber_light"], 0.035)
        salvage._beam("Shared porch front bearer", (x - 0.28, -4.05, 0.50), (x + 0.28, -4.05, 0.50), 0.25, 0.26, mats["timber"], 0.025)
    for x in (-7.9, -0.2, 7.9):
        salvage._beam("Shared porch diagonal brace", (x, -4.03, 0.55), (x + (0.46 if x < 0 else -0.46), -3.05, 1.40), 0.18, 0.20, mats["timber_light"], 0.02)

    # One small outer-edge crate and a plain capped vent provide domestic cues.
    for z in (0.68, 0.98, 1.28):
        salvage._beam("Small household storage crate slat", (-7.05, -2.92, z), (-5.85, -2.92, z), 0.12, 0.14, mats["timber_light"], 0.018)
    for x in (-7.02, -5.88):
        salvage._beam("Small crate corner upright", (x, -2.92, 0.55), (x, -2.92, 1.42), 0.12, 0.14, mats["timber"], 0.018)
    salvage._cylinder("Single plain household vent", 0.18, 0.86, (5.95, 2.55, 5.45), mats["iron"], "z", 16, 0.018)
    salvage._cylinder("Plain vent rain cap", 0.26, 0.10, (5.95, 2.55, 5.93), mats["sheet"], "z", 16, 0.012)

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    # Join separate boards and hardware into one mesh object while retaining
    # one surface per authored material. This keeps the detailed cottage from
    # turning every small board into an additional draw call.
    bpy.ops.object.join()
    return {"mesh_count": 1, "authored_mesh_count": len(meshes)}, {key: material.name for key, material in mats.items()}


def main(project_root: Path, output: Path) -> None:
    _, material_names = _build(output)
    recipe_path = os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", "")
    recipe = json.loads(Path(recipe_path).read_text(encoding="utf-8")) if recipe_path and Path(recipe_path).is_file() else {}
    material_strategy = str(recipe.get("parameters", {}).get("material_strategy", "broad_scale_patina"))
    glb = output / "scavenger_housing.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=True, export_apply=True, export_materials="EXPORT", export_yup=True, export_texcoords=True, export_normals=True, export_tangents=True, export_cameras=False, export_lights=False)
    record = {
        "asset_id": "scavenger_housing",
        "method": "blender_salvaged_paired_cottages",
        "approved_visual_target": "art/scavenger_housing/visual_director/round-01/approved-target-r01.png",
        "envelope_inches": [17.0, 7.0, 9.0],
        "dimensions_checked_by": "Godot candidate validation; see technical-validation.json",
        "material_strategy": material_strategy,
        "material_names": material_names,
        "geometry_features": [
            "two compact adjacent homes with distinct low roof silhouettes",
            "broad blue and cream salvaged appliance door slabs",
            "reclaimed timber walls with visible roof and porch supports",
            "one shared uneven porch, small storage crate, reuse-glass windows and plain vent",
        ],
        "presentation_only": True,
        "gameplay_changes": False,
        "output": glb.name,
        "generated_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
    }
    (output / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"SCAVENGER_HOUSING_GENERATED {glb} meshes={len([obj for obj in bpy.context.scene.objects if obj.type == 'MESH'])}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit("usage: scavenger_housing_blender.py PROJECT_ROOT OUTPUT_DIR")
    main(Path(sys.argv[-2]).resolve(), Path(sys.argv[-1]).resolve())
