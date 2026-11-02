"""Versioned Visual Director transfer strategies for cabinet, window, and workshop."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

ASSETS = {
    "display_cabinet": {"type": "display_cabinet", "dimensions": (33.0, 76.0, 18.0)},
    "room_photo_window_production": {"type": "window", "dimensions": (96.0, 68.0, 4.0)},
    "settlement_workshop": {"type": "workshop", "dimensions": (26.0, 20.0, 20.0)},
}

IN_BLENDER = False
try:
    import bpy  # type: ignore[import-not-found]
    from mathutils import Vector  # type: ignore[import-not-found]

    IN_BLENDER = True
except ImportError:
    bpy = None  # type: ignore[assignment]
    Vector = None  # type: ignore[assignment,misc]


def _production_module():
    module_path = Path(__file__).with_name("production_batch01_blender.py")
    spec = importlib.util.spec_from_file_location("roomscale_production_batch01", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load shared RoomScale Blender helpers: {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def build_display_cabinet(base, mats):
    """Transfer the approved walnut, quiet-glass, paired-door target into 3D."""
    walnut = base.pbr_material("Visual Director walnut", (0.255, 0.125, 0.058), 0.0, 0.47, "wood")
    walnut_light = base.pbr_material(
        "Visual Director inner walnut", (0.34, 0.185, 0.09), 0.0, 0.49, "wood"
    )
    glass = base.pbr_material(
        "Quiet clear cabinet glazing", (0.72, 0.78, 0.76), 0.02, 0.16, "metal", 0.075
    )
    brass = mats["brass"]
    dark_iron = mats["iron"]
    box = base.box
    cylinder = base.cylinder

    # Exact 33 x 18 footprint and a 76-inch finished top; bevels remain inside bounds.
    box("Cabinet plinth foot", (0.0, 0.0, 0.8), (31.4, 17.2, 1.6), walnut, 0.22)
    box("Cabinet full plinth", (0.0, 0.0, 3.35), (33.0, 18.0, 4.1), walnut, 0.24)
    box("Cabinet plinth upper molding", (0.0, 0.0, 5.65), (31.8, 17.0, 0.65), walnut_light, 0.10)

    case_bottom, case_top = 6.15, 70.1
    box(
        "Cabinet left case stile",
        (-15.15, 0.0, (case_bottom + case_top) * 0.5),
        (2.7, 16.4, case_top - case_bottom),
        walnut,
        0.12,
    )
    box(
        "Cabinet right case stile",
        (15.15, 0.0, (case_bottom + case_top) * 0.5),
        (2.7, 16.4, case_top - case_bottom),
        walnut,
        0.12,
    )
    box("Cabinet solid back", (0.0, 8.15, 38.0), (27.5, 0.8, 62.0), walnut_light, 0.08)
    box("Cabinet bottom panel", (0.0, 0.0, 7.25), (27.5, 15.7, 1.3), walnut_light, 0.08)
    box("Cabinet upper panel", (0.0, 0.0, 69.0), (27.5, 15.7, 2.2), walnut, 0.08)

    # Three full shelves are deliberately empty; room collectibles remain separate assets.
    for index, z in enumerate((22.0, 39.0, 56.0), start=1):
        box(
            f"Cabinet interior shelf {index}",
            (0.0, -0.05, z),
            (27.0, 15.2, 1.05),
            walnut_light,
            0.09,
        )
        box(
            f"Cabinet shelf front nosing {index}",
            (0.0, -7.55, z + 0.12),
            (27.0, 0.35, 0.32),
            walnut,
            0.055,
        )

    # Door pair: individual outer rails, full-height glazing, center meeting stiles.
    door_z = 38.0
    door_low, door_high = 8.5, 67.0
    door_h = door_high - door_low
    for side in (-1, 1):
        cx = side * 6.82
        outer_x = cx + side * 6.55
        inner_x = cx - side * 5.75
        box(
            f"Cabinet door {side} outer stile",
            (outer_x, -8.05, door_z),
            (1.15, 0.85, door_h),
            walnut,
            0.085,
        )
        box(
            f"Cabinet door {side} meeting stile",
            (inner_x, -8.08, door_z),
            (1.1, 0.9, door_h),
            walnut,
            0.08,
        )
        for z, label in ((door_low + 0.65, "bottom"), (door_high - 0.65, "top")):
            box(
                f"Cabinet door {side} {label} rail", (cx, -8.05, z), (12.5, 0.85, 1.3), walnut, 0.09
            )
        box(
            f"Cabinet door {side} clear glass",
            (cx, -7.86, door_z),
            (11.35, 0.12, door_h - 2.1),
            glass,
            0.01,
        )
        # Three visible brass hinges per leaf at the actual outer stile.
        for z in (12.0, 38.0, 64.0):
            hx = outer_x - side * 0.30
            box(f"Cabinet door {side} hinge leaf", (hx, -8.56, z), (0.56, 0.10, 2.1), brass, 0.035)
            cylinder(
                f"Cabinet door {side} hinge pin",
                (hx, -8.63, z),
                0.11,
                0.22,
                dark_iron,
                "Y",
                20,
                0.02,
            )
        # Paired, small central knobs have a separate backplate and rounded grip.
        knob_x = side * 0.72
        cylinder(
            f"Cabinet door {side} brass escutcheon",
            (knob_x, -8.62, door_z),
            0.37,
            0.13,
            brass,
            "Y",
            32,
            0.035,
        )
        cylinder(
            f"Cabinet door {side} brass knob stem",
            (knob_x, -8.78, door_z),
            0.12,
            0.26,
            brass,
            "Y",
            24,
            0.025,
        )
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=20, ring_count=12, radius=0.27, location=(knob_x, -8.94, door_z)
        )
        knob = bpy.context.object
        knob.name = f"Cabinet door {side} brass knob"
        knob.data.materials.append(brass)

    # Restrained stepped crown echoes the approved silhouette without extra bead noise.
    box("Cabinet crown lower molding", (0.0, 0.0, 71.1), (31.5, 17.4, 1.35), walnut_light, 0.12)
    box("Cabinet crown shadow course", (0.0, 0.0, 72.35), (32.2, 17.8, 0.8), walnut, 0.10)
    box("Cabinet crown cap", (0.0, 0.0, 74.0), (33.0, 18.0, 4.0), walnut_light, 0.16)


def build_window(base, mats):
    """Build a source-faithful sash with an explicit four-light transom and single latch."""
    box = base.box
    cylinder = base.cylinder
    oak = base.pbr_material(
        "Visual Director stained window oak", (0.30, 0.155, 0.072), 0.0, 0.44, "wood"
    )
    inner_oak = base.pbr_material("Sash edge warm oak", (0.39, 0.215, 0.104), 0.0, 0.43, "wood")
    glass = base.pbr_material(
        "Nearly clear residential glazing", (0.78, 0.84, 0.83), 0.01, 0.12, "metal", 0.035
    )
    brass = mats["brass"]
    steel = mats["steel"]

    # Main casing fits precisely within the 96 x 68-inch source opening.
    for side in (-1, 1):
        x = side * 45.4
        box("Window deep stained outer casing", (x, -0.22, 34.0), (5.2, 1.2, 68.0), oak, 0.16)
        box(
            "Window stepped casing bead",
            (side * 42.1, -0.92, 34.0),
            (1.05, 0.36, 62.0),
            inner_oak,
            0.06,
        )
        box("Window structural jamb", (side * 42.5, 0.30, 34.0), (2.8, 2.5, 60.0), oak, 0.10)
    box("Window head casing", (0.0, -0.22, 65.4), (85.6, 1.2, 5.2), oak, 0.16)
    box("Window head inner bead", (0.0, -0.91, 61.8), (82.0, 0.34, 0.82), inner_oak, 0.05)
    box("Window projecting stained sill", (0.0, -0.70, 1.25), (96.0, 3.7, 2.5), oak, 0.18)
    box("Window sill nosing", (0.0, -1.68, 2.45), (95.0, 1.25, 0.62), inner_oak, 0.10)
    box("Window sill underside apron", (0.0, 0.10, 3.25), (84.5, 0.75, 1.3), oak, 0.08)

    # Shared opening structure and a prominent meeting rail.
    face_y = -1.05
    box("Window centre meeting stile", (0.0, face_y, 33.5), (2.5, 1.9, 54.0), oak, 0.10)
    transom_low, transom_high = 52.0, 61.0
    box(
        "Window transom lower rail",
        (0.0, face_y - 0.08, transom_low),
        (81.0, 1.65, 1.25),
        oak,
        0.075,
    )
    box(
        "Window transom top rail", (0.0, face_y - 0.04, transom_high), (81.0, 1.65, 1.0), oak, 0.075
    )
    for x in (-30.5, -10.2, 10.2, 30.5):
        box(
            "Window transom vertical muntin",
            (x, face_y - 0.10, 56.5),
            (0.78, 1.35, 8.0),
            inner_oak,
            0.045,
        )
    for i, (a, b) in enumerate(
        ((-39.0, -31.0), (-30.0, -10.6), (-9.8, 9.8), (10.6, 30.0), (31.0, 39.0)), start=1
    ):
        pane_width = b - a
        box(
            f"Window transom clear light {i}",
            ((a + b) * 0.5, -0.05, 56.5),
            (pane_width, 0.10, 7.5),
            glass,
            0.005,
        )

    # Two clear lower sashes with a horizontal meeting line and a readable center rail.
    sash_left, sash_right = 1.25, 40.0
    lower_bottom, lower_top = 6.5, 51.6
    meeting_z = 28.5
    for side in (-1, 1):
        center_x = side * (sash_left + sash_right) * 0.5
        half_width = (sash_right - sash_left) * 0.5
        outer_x = side * (sash_right - 0.45)
        box(
            "Window sash outer stile",
            (outer_x, face_y - 0.05, (lower_bottom + lower_top) * 0.5),
            (0.95, 1.75, lower_top - lower_bottom),
            inner_oak,
            0.06,
        )
        box(
            "Window sash lower rail",
            (center_x, face_y - 0.05, lower_bottom + 0.55),
            (half_width * 2.0, 1.75, 1.1),
            inner_oak,
            0.065,
        )
        box(
            "Window sash meeting rail",
            (center_x, face_y - 0.09, meeting_z),
            (half_width * 2.0, 1.95, 1.55),
            oak,
            0.08,
        )
        box(
            "Window sash head rail",
            (center_x, face_y - 0.05, lower_top - 0.55),
            (half_width * 2.0, 1.75, 1.1),
            inner_oak,
            0.065,
        )
        for z0, z1 in ((lower_bottom + 1.2, meeting_z - 0.9), (meeting_z + 0.9, lower_top - 1.2)):
            box(
                "Window lower sash clear pane",
                (center_x, -0.12, (z0 + z1) * 0.5),
                (half_width * 2.0 - 1.4, 0.10, z1 - z0),
                glass,
                0.005,
            )

    # A single centered latch replaces the duplicated transom-side plates in the first render.
    box(
        "Window central latch backplate",
        (0.0, -1.30, meeting_z + 0.05),
        (1.45, 0.20, 0.52),
        brass,
        0.05,
    )
    cylinder(
        "Window central latch pivot",
        (0.0, -1.45, meeting_z + 0.08),
        0.16,
        0.22,
        steel,
        "Y",
        20,
        0.025,
    )
    box(
        "Window central sash latch lever",
        (0.0, -1.53, meeting_z + 0.43),
        (0.20, 0.22, 0.78),
        brass,
        0.07,
    )
    # Two small screw heads ground the latch to the sash without adding extra locks.
    for x in (-0.48, 0.48):
        cylinder(
            "Window latch fixing screw",
            (x, -1.44, meeting_z + 0.05),
            0.07,
            0.10,
            steel,
            "Y",
            16,
            0.015,
        )


def build_workshop(base, mats):
    """Retain workshop equipment while moving roof mass above the open working face."""
    base.build_workshop(mats)
    roof_tokens = (
        "Workshop roof",
        "Workshop king-post truss",
        "Workshop truss strut",
        "Workshop rear gable board",
    )
    for obj in list(bpy.context.scene.objects):
        if any(token in obj.name for token in roof_tokens):
            bpy.data.objects.remove(obj, do_unlink=True)

    # Compact raised awning over the bench only. The boiler, gauge, flywheel, and flue
    # remain uncovered in the room's high strategy view, addressing v006's occlusion.
    left = [(-10.2, 14.7), (-2.1, 18.9), (-2.1, 18.25), (-10.2, 14.05)]
    right = [(-1.9, 18.9), (2.0, 16.9), (2.0, 16.25), (-1.9, 18.25)]
    base.profile_prism(
        "Visual Director raised canopy left wing", left, -8.2, 2.0, mats["roof"], 0.045
    )
    base.profile_prism(
        "Visual Director raised canopy right wing", right, -8.2, 2.0, mats["roof"], 0.045
    )
    base.beam(
        "Visual Director canopy ridge cap",
        (-2.1, -8.3, 19.0),
        (-2.1, 2.1, 19.0),
        0.38,
        0.34,
        mats["copper"],
        0.065,
    )
    for x in (-9.0, -6.0, -3.0, -1.0, 0.8):
        z_left = 14.7 + (x + 10.2) * (4.2 / 8.1)
        start = (x, -8.25, z_left)
        end = (x, 2.05, z_left)
        base.tube("Visual Director canopy standing seam", [start, end], 0.055, mats["copper"], 2)
    for x in (-9.4, -2.6):
        for y in (-7.6, 1.2):
            base.box(
                "Visual Director raised canopy support",
                (x, y, 13.45),
                (0.48, 0.48, 2.8),
                mats["dark_wood"],
                0.08,
            )
            base.beam(
                "Visual Director canopy knee brace",
                (x, y, 12.1),
                (x * 0.72, y, 14.5),
                0.25,
                0.24,
                mats["oak"],
                0.035,
            )


def run_blender_generation(asset_id: str, output_path: Path) -> None:
    base = _production_module()
    base.clear_scene()
    mats = base.set_up_materials()
    builders = {
        "display_cabinet": lambda: build_display_cabinet(base, mats),
        "room_photo_window_production": lambda: build_window(base, mats),
        "settlement_workshop": lambda: build_workshop(base, mats),
    }
    if asset_id not in builders:
        raise ValueError(f"unsupported Visual Director asset: {asset_id}")
    builders[asset_id]()
    base.apply_modifiers_and_merge_by_material()
    bpy.ops.object.select_all(action="SELECT")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
    )
    if not output_path.is_file() or output_path.stat().st_size < 1024:
        raise RuntimeError(f"Blender did not create a usable GLB: {output_path}")
    print(
        f"ROOMSCALE_VISUAL_DIRECTOR_BATCH02_PASS asset={asset_id} path={output_path} bytes={output_path.stat().st_size}"
    )


def dispatch_to_blender() -> int:
    project_root = Path(__file__).resolve().parents[3]
    asset_id = os.environ["ROOMSCALE_ART_FACTORY_ASSET_ID"]
    output_dir = Path(os.environ["ROOMSCALE_ART_FACTORY_OUTPUT_DIR"])
    output_path = output_dir / "asset.glb"
    blender = os.environ.get("ROOMSCALE_BLENDER_EXECUTABLE", "")
    if not blender:
        raise RuntimeError(
            "ROOMSCALE_BLENDER_EXECUTABLE must point to the approved local Blender install"
        )
    result = subprocess.run(
        [
            blender,
            "--background",
            "--factory-startup",
            "--python",
            str(Path(__file__).resolve()),
            "--",
            asset_id,
            str(output_path),
        ],
        cwd=project_root,
        check=False,
    )
    if result.returncode or not output_path.is_file():
        return result.returncode or 2
    brief = json.loads(Path(os.environ["ROOMSCALE_ART_FACTORY_BRIEF"]).read_text(encoding="utf-8"))
    recipe = json.loads(
        Path(os.environ["ROOMSCALE_ART_FACTORY_RECIPE"]).read_text(encoding="utf-8")
    )
    record = {
        "asset_id": asset_id,
        "asset_type": ASSETS[asset_id]["type"],
        "method": recipe["method"],
        "tool": "Blender 5.2.3 LTS Python/bpy",
        "generator": "visual_director_batch02_blender.py",
        "output": "asset.glb",
        "dimensions_inches": brief["intended_dimensions"],
        "source_inputs": recipe.get("source_inputs", []),
        "visual_director_target": recipe["parameters"].get("visual_director_target"),
        "transfer_strategy": recipe["parameters"].get("visual_director_strategy"),
        "geometry": "target-driven modular mesh assembly with fit-for-purpose construction detail",
        "materials": "separate embedded textured timber, glass, brass, iron, copper, and roof responses as applicable",
    }
    (output_dir / "generation-record.json").write_text(
        json.dumps(record, indent=2) + "\n", encoding="utf-8"
    )
    return 0


def main() -> int:
    if IN_BLENDER:
        arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
        if len(arguments) != 2:
            raise SystemExit("Blender invocation requires <asset_id> <output.glb> after --")
        run_blender_generation(arguments[0], Path(arguments[1]))
        return 0
    return dispatch_to_blender()


if __name__ == "__main__":
    raise SystemExit(main())
