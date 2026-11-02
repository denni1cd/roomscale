"""Build a presentation-only Scavenger hand-work bay."""

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


def _build(output: Path) -> tuple[int, dict[str, str]]:
    recipe_path = Path(os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", ""))
    recipe = json.loads(recipe_path.read_text(encoding="utf-8")) if recipe_path.is_file() else {}
    parameters = recipe.get("parameters", {})
    palette = parameters.get("material_palette", {})
    material_strategy = str(parameters.get("material_strategy", "broad_scale_patina"))
    use_embedded_patina_maps = material_strategy != "solid_scale_blocks"

    def texture_family(name: str) -> str:
        return f"workarea_{name}" if use_embedded_patina_maps else ""

    def color(name: str, fallback: tuple[float, float, float]) -> tuple[float, float, float]:
        return tuple(float(channel) for channel in palette.get(name, fallback))

    output.mkdir(parents=True, exist_ok=True)
    (output / "materials").mkdir(parents=True, exist_ok=True)
    production.clear_scene()

    mats = {
        "timber": salvage._material("Scavenger work bay reclaimed timber", (0.27, 0.18, 0.11), 0.0, 0.87, output / "materials", texture_family("timber"), "wood", material_strategy),
        "timber_light": salvage._material("Scavenger work bay sun-faded boards", (0.47, 0.34, 0.22), 0.0, 0.87, output / "materials", texture_family("timber_light"), "wood", material_strategy),
        "blue": salvage._material("Scavenger work bay faded blue enamel", color("enamel_blue", (0.10, 0.38, 0.55)), 0.14, 0.47, output / "materials", texture_family("enamel_blue"), "enamel", material_strategy),
        "cream": salvage._material("Scavenger work bay cream enamel", color("enamel_cream", (0.77, 0.69, 0.54)), 0.12, 0.49, output / "materials", texture_family("enamel_cream"), "enamel", material_strategy),
        "sheet": salvage._material("Scavenger work bay galvanized sheets", color("galvanized", (0.47, 0.52, 0.52)), 0.55, 0.63, output / "materials", texture_family("galvanized"), "galvanized", material_strategy),
        "rust": salvage._material("Scavenger work bay rusted repair sheets", color("rust", (0.40, 0.19, 0.11)), 0.18, 0.74, output / "materials", texture_family("rust"), "rust", material_strategy),
        "canvas": salvage._material("Scavenger work bay canvas patch", (0.56, 0.45, 0.31), 0.0, 0.93, output / "materials", texture_family("canvas"), "canvas", material_strategy),
        "iron": salvage._material("Scavenger work bay plain iron", (0.15, 0.18, 0.18), 0.68, 0.54, output / "materials", texture_family("iron"), "metal", material_strategy),
    }

    # X is width, Y is depth (front faces -Y), Z is height. Roof peaks stay
    # below 9 inches; all geometry is fitted to the 23 x 9 x 12 inch envelope.
    # Retreat the camera-facing edge to uncover the hand-work setup while
    # keeping enough depth for the ArtBrief's 12-inch bay proportion.
    roof_front_y, roof_back_y = -1.90, 7.95
    roof_front_z, roof_back_z = 7.85, 8.28
    for x in (-10.75, 10.75):
        for y, top in ((-1.52, roof_front_z - 0.16), (7.35, roof_back_z - 0.16)):
            salvage._beam("Outer work bay timber post", (x, y, 0.35), (x, y, top), 0.38, 0.42, mats["timber_light"], 0.045)
        salvage._beam("Front roof knee brace", (x, -1.50, 3.25), (x + (-0.85 if x > 0 else 0.85), -1.50, roof_front_z - 0.20), 0.25, 0.28, mats["timber"], 0.03)
        salvage._beam("Rear roof knee brace", (x, 7.30, 3.20), (x + (-0.80 if x > 0 else 0.80), 7.30, roof_back_z - 0.20), 0.24, 0.27, mats["timber_light"], 0.03)
    for y, z in ((-1.50, roof_front_z - 0.12), (7.32, roof_back_z - 0.12)):
        salvage._beam("Work bay cross header", (-10.9, y, z), (10.9, y, z), 0.38, 0.40, mats["timber"], 0.04)

    # Four overlapping sheet panels define one shallow lean-to canopy.
    for panel in range(4):
        x0 = -11.35 + panel * 5.65
        x1 = x0 + 5.86
        material = mats["sheet"] if panel in (0, 1, 3) else mats["rust"]
        salvage._roof_sheet(f"Overlapping work bay roof sheet {panel + 1}", x0, x1, roof_front_y, roof_back_y, roof_front_z, roof_back_z, material)
    for fraction in (0.0, 0.32, 0.68, 1.0):
        y = roof_front_y + (roof_back_y - roof_front_y) * fraction
        z = roof_front_z + (roof_back_z - roof_front_z) * fraction - 0.10
        salvage._beam("Roof purlin under overlapping sheets", (-11.0, y, z), (11.0, y, z), 0.18, 0.20, mats["timber"], 0.02)
    canvas_back_z = roof_front_z + (roof_back_z - roof_front_z) * (3.0 - roof_front_y) / (roof_back_y - roof_front_y) - 0.06
    salvage._roof_sheet("Small canvas canopy repair", -8.3, -4.4, roof_front_y - 0.04, 3.0, roof_front_z + 0.03, canvas_back_z, mats["canvas"])

    # A long, clearly hand-operated workbench anchors the open front.
    bench_y = -0.65
    bench_top_z = 3.62
    salvage._cube("Work bench timber top", (17.6, 2.50, 0.42), (0.0, bench_y, bench_top_z), mats["timber_light"], 0.07)
    salvage._cube("Work bench front apron", (16.8, 0.24, 0.66), (0.0, bench_y - 1.18, 3.07), mats["timber"], 0.035)
    for x in (-8.0, -4.0, 4.0, 8.0):
        for y in (bench_y - 0.92, bench_y + 0.92):
            salvage._beam("Work bench leg", (x, y, 0.50), (x, y, 3.40), 0.27, 0.30, mats["timber_light"], 0.025)
    for y in (bench_y - 0.84, bench_y + 0.84):
        salvage._beam("Work bench lower stretcher", (-8.0, y, 1.15), (8.0, y, 1.15), 0.22, 0.24, mats["timber"], 0.022)
    for x in (-7.7, 7.7):
        salvage._beam("Work bench side brace", (x, bench_y - 0.84, 1.20), (x, bench_y + 0.70, 2.85), 0.18, 0.20, mats["timber_light"], 0.02)

    # The rear board and large tool silhouettes read before small hand tools.
    salvage._cube("Broad faded enamel tool board", (14.8, 0.28, 3.15), (0.0, 4.66, 4.16), mats["blue"], 0.06)
    for x in (-7.65, 0.0, 7.65):
        salvage._beam("Tool board vertical timber frame", (x, 4.42, 2.55), (x, 4.42, 5.82), 0.25, 0.28, mats["timber_light"], 0.025)
    for z in (2.60, 5.75):
        salvage._beam("Tool board horizontal frame", (-7.65, 4.40, z), (7.65, 4.40, z), 0.25, 0.26, mats["timber"], 0.025)

    # Large recognisable hand tools hang in separated groups.
    salvage._cube("Broad hand saw blade", (0.20, 0.12, 1.75), (-4.7, 4.27, 4.35), mats["iron"], 0.018)
    salvage._cube("Hand saw wooden handle", (0.78, 0.16, 0.58), (-4.7, 4.18, 3.15), mats["timber_light"], 0.06)
    salvage._beam("Long hammer handle", (-1.2, 4.22, 3.20), (-1.2, 4.22, 5.30), 0.20, 0.22, mats["timber_light"], 0.02)
    salvage._beam("Hammer iron head", (-1.75, 4.16, 5.18), (-0.65, 4.16, 5.18), 0.34, 0.35, mats["iron"], 0.035)
    salvage._beam("Large spanner handle", (2.45, 4.18, 3.25), (2.95, 4.18, 5.15), 0.18, 0.20, mats["iron"], 0.02)
    salvage._beam("Spanner jaw lower tine", (2.92, 4.18, 5.00), (2.50, 4.18, 5.42), 0.15, 0.18, mats["iron"], 0.018)
    salvage._beam("Spanner jaw upper tine", (2.92, 4.18, 5.00), (3.46, 4.18, 5.26), 0.15, 0.18, mats["iron"], 0.018)
    salvage._cube("Large timber square stock", (0.22, 0.18, 1.25), (5.40, 4.24, 4.05), mats["timber_light"], 0.025)

    # A plain vise and two staged material groups communicate actual hand work.
    salvage._cube("Hand vise fixed base", (1.65, 0.72, 0.24), (-6.1, bench_y - 0.10, 3.96), mats["iron"], 0.035)
    salvage._cube("Hand vise jaws", (1.30, 0.28, 0.42), (-6.1, bench_y - 0.34, 4.24), mats["iron"], 0.04)
    salvage._cylinder("Hand vise screw", 0.10, 1.0, (-6.1, bench_y - 0.68, 4.20), mats["iron"], "y", 16, 0.012)
    salvage._cube("Small side parts crate", (2.8, 2.4, 2.15), (9.15, 2.20, 1.55), mats["timber"], 0.05)
    for level in (0.75, 1.35, 1.95):
        salvage._beam("Crate horizontal board", (7.76, 0.96, level), (10.54, 0.96, level), 0.16, 0.18, mats["timber_light"], 0.02)
        salvage._beam("Crate side rail", (10.55, 0.98, level), (10.55, 3.42, level), 0.16, 0.18, mats["timber"], 0.02)
    for x in (-9.3, -8.6, -7.9):
        salvage._beam("Long salvaged stock on rack", (x, 2.40, 1.50), (x, 4.10, 2.0 + (x + 9.3) * 0.15), 0.32, 0.34, mats["timber_light"], 0.03)

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    return len(meshes), {key: material.name for key, material in mats.items()}


def main(project_root: Path, output: Path) -> None:
    authored_count, material_names = _build(output)
    recipe_path = os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", "")
    recipe = json.loads(Path(recipe_path).read_text(encoding="utf-8")) if recipe_path and Path(recipe_path).is_file() else {}
    material_strategy = str(recipe.get("parameters", {}).get("material_strategy", "broad_scale_patina"))
    glb = output / "scavenger_workarea.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=True, export_apply=True, export_materials="EXPORT", export_yup=True, export_texcoords=True, export_normals=True, export_tangents=True, export_cameras=False, export_lights=False)
    record = {
        "asset_id": "scavenger_workarea",
        "method": "blender_open_handwork_salvage_bay",
        "approved_visual_target": "art/scavenger_workarea/visual_director/round-01/approved-target-r01.png",
        "envelope_inches": [23.0, 9.0, 12.0],
        "dimensions_checked_by": "Godot candidate validation; see technical-validation.json",
        "material_strategy": material_strategy,
        "material_names": material_names,
        "authored_mesh_object_count_before_material_merge": authored_count,
        "geometry_features": [
            "open hand-work bay with wide repaired timber bench and large plain hand vise",
            "broad faded enamel tool board with spaced, large hand-tool silhouettes",
            "shallow supported galvanized canopy with a small canvas repair",
            "one parts crate and a few long salvage stock pieces",
        ],
        "presentation_only": True,
        "gameplay_changes": False,
        "output": glb.name,
        "generated_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
    }
    (output / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"SCAVENGER_WORKAREA_GENERATED {glb} meshes={len([obj for obj in bpy.context.scene.objects if obj.type == 'MESH'])}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit("usage: scavenger_workarea_blender.py PROJECT_ROOT OUTPUT_DIR")
    main(Path(sys.argv[-2]).resolve(), Path(sys.argv[-1]).resolve())
