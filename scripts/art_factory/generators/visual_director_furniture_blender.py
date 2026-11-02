"""Blender-authored Room A/B furniture with fitted joinery and embedded PBR."""

from __future__ import annotations

import importlib.util
import json
import math
import os
import subprocess
import sys
from pathlib import Path

ASSETS = {
    "bookcase": {"type": "household_bookcase", "dimensions": (32.0, 63.0, 17.0)},
    "room_elevated_workbench": {"type": "workbench", "dimensions": (58.0, 36.0, 30.0)},
    "room_assembly_table": {"type": "assembly_table", "dimensions": (42.0, 24.0, 32.0)},
    "room_tool_wardrobe": {"type": "tool_wardrobe", "dimensions": (42.0, 70.0, 22.0)},
    "room_floor_cabinet": {"type": "floor_cabinet", "dimensions": (26.0, 21.0, 24.0)},
    "room_side_table": {"type": "side_table", "dimensions": (20.0, 20.0, 17.0)},
}

IN_BLENDER = False
try:
    import bpy  # type: ignore[import-not-found]
    from mathutils import Vector  # type: ignore[import-not-found]

    IN_BLENDER = True
except ImportError:
    bpy = None  # type: ignore[assignment]
    Vector = None  # type: ignore[assignment,misc]


def _base_module():
    module_path = Path(__file__).with_name("production_batch01_blender.py")
    spec = importlib.util.spec_from_file_location("roomscale_furniture_blender_base", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load shared Blender geometry helpers: {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def dispatch_to_blender() -> int:
    project_root = Path(__file__).resolve().parents[3]
    output_dir = Path(os.environ["ROOMSCALE_ART_FACTORY_OUTPUT_DIR"])
    asset_id = os.environ["ROOMSCALE_ART_FACTORY_ASSET_ID"]
    asset = ASSETS[asset_id]
    output_file = output_dir / "asset.glb"
    recipe_path = Path(os.environ["ROOMSCALE_ART_FACTORY_RECIPE"])
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    generation_variant = str(recipe.get("parameters", {}).get("generation_variant", ""))
    blender = os.environ.get("ROOMSCALE_BLENDER_EXECUTABLE", "")
    if not blender:
        raise RuntimeError(
            "ROOMSCALE_BLENDER_EXECUTABLE must point to the approved local Blender install"
        )
    command = [
        blender,
        "--background",
        "--factory-startup",
        "--python",
        str(Path(__file__).resolve()),
        "--",
        asset["type"],
        str(output_file),
        generation_variant,
    ]
    result = subprocess.run(command, cwd=project_root, check=False)
    if result.returncode or not output_file.is_file():
        return result.returncode or 2
    generation_record = {
        "asset_id": asset_id,
        "asset_type": asset["type"],
        "method": recipe["method"],
        "tool": "Blender 5.2.3 LTS Python/bpy",
        "output": "asset.glb",
        "dimensions_inches": list(asset["dimensions"]),
        "source_inputs": recipe.get("source_inputs", []),
        "geometry": "individually authored joinery, shaped panels, and fitted hardware; no gameplay geometry",
        "materials": "embedded oak, walnut, iron, steel, and brass PBR with deterministic per-board UV variation",
        "generation_variant": generation_variant,
    }
    (output_dir / "generation-record.json").write_text(
        json.dumps(generation_record, indent=2) + "\n", encoding="utf-8"
    )
    return 0


def _materials(base, generation_variant=""):
    if generation_variant.startswith("bookcase_household_r01_alternate"):
        wood_grain = "bookcase_oak_fine"
    else:
        wood_grain = "french_oak" if "_targeted" in generation_variant else "french_oak_soft"
    targeted_bookcase = generation_variant.startswith("bookcase_household_r01_targeted")
    alternate_bookcase = generation_variant.startswith("bookcase_household_r01_alternate")
    if targeted_bookcase or alternate_bookcase:
        # The first Room A render lost the target's dark stained wood in the
        # production light, and its softer grain did not survive at gameplay scale.
        oak_color = (0.26, 0.145, 0.070)
        oak_light_color = (0.34, 0.205, 0.105)
        walnut_color = (0.105, 0.050, 0.025)
        oak_roughness, oak_light_roughness, walnut_roughness = 0.52, 0.54, 0.56
    else:
        oak_color = (0.40, 0.255, 0.135)
        oak_light_color = (0.49, 0.325, 0.185)
        walnut_color = (0.20, 0.105, 0.052)
        oak_roughness, oak_light_roughness, walnut_roughness = 0.43, 0.46, 0.48
    return {
        "oak": base.pbr_material(
            "Room furniture quarter-sawn oak", oak_color, 0.0, oak_roughness, wood_grain
        ),
        "oak_light": base.pbr_material(
            "Room furniture light oak", oak_light_color, 0.0, oak_light_roughness, wood_grain
        ),
        "walnut": base.pbr_material(
            "Room furniture smoked walnut", walnut_color, 0.0, walnut_roughness, wood_grain
        ),
        "brass": base.pbr_material(
            "Room furniture aged brass", (0.53, 0.36, 0.13), 0.78, 0.29, "metal"
        ),
        "iron": base.pbr_material(
            "Room furniture forged iron", (0.055, 0.078, 0.083), 0.82, 0.37, "metal"
        ),
        "steel": base.pbr_material(
            "Room furniture brushed steel", (0.28, 0.32, 0.32), 0.86, 0.28, "metal"
        ),
        "leather": base.pbr_material(
            "Room furniture vise leather", (0.17, 0.07, 0.042), 0.0, 0.68, "fabric"
        ),
    }


def _box(base, name, center, size, material, bevel=0.055, rotation=None):
    return base.box(name, center, size, material, bevel, rotation)


def _cylinder(base, name, center, radius, depth, material, axis="Z", vertices=24):
    return base.cylinder(name, center, radius, depth, material, axis, vertices, 0.025)


def _dovetail_marks(base, name, x, front_y, z, width, height, material):
    """Small exposed drawer tails on the visible end of a drawer side."""
    for index in range(3):
        center_z = z - height * 0.32 + index * height * 0.32
        half_h = min(0.18, height * 0.12)
        half_w = min(0.22, width * 0.035)
        base.profile_prism(
            f"{name} dovetail {index + 1}",
            [
                (-half_w, center_z - half_h),
                (half_w, center_z - half_h),
                (half_w * 0.68, center_z + half_h),
                (-half_w * 0.68, center_z + half_h),
            ],
            front_y,
            front_y + 0.12,
            material,
            0.018,
        ).location.x = x


def _drawer(base, mats, name, cx, front_y, z, width, height, depth, open_amount=0.35):
    """Open drawer box with a routed front, visible side joinery, and cup pull."""
    front = front_y - open_amount
    _box(
        base, f"{name} solid drawer front", (cx, front, z), (width, 0.72, height), mats["oak"], 0.10
    )
    face_y = front - 0.40
    inset_w = width - 0.9
    inset_h = height - 0.55
    _box(
        base,
        f"{name} routed inset field",
        (cx, face_y, z),
        (inset_w, 0.12, inset_h),
        mats["oak_light"],
        0.045,
    )
    for x in (cx - inset_w * 0.5 - 0.12, cx + inset_w * 0.5 + 0.12):
        _box(
            base,
            f"{name} front stile",
            (x, face_y - 0.055, z),
            (0.22, 0.16, height - 0.12),
            mats["oak"],
            0.025,
        )
    for zz in (z - inset_h * 0.5 - 0.12, z + inset_h * 0.5 + 0.12):
        _box(
            base,
            f"{name} front rail",
            (cx, face_y - 0.055, zz),
            (width - 0.25, 0.16, 0.22),
            mats["oak"],
            0.025,
        )
    drawer_y = front_y + depth * 0.48 - open_amount * 0.25
    side_x = cx - width * 0.5 + 0.32
    _box(
        base,
        f"{name} drawer side left",
        (side_x, drawer_y, z),
        (0.48, depth, height - 0.25),
        mats["walnut"],
        0.025,
    )
    _box(
        base,
        f"{name} drawer side right",
        (cx + width * 0.5 - 0.32, drawer_y, z),
        (0.48, depth, height - 0.25),
        mats["oak"],
        0.025,
    )
    _box(
        base,
        f"{name} drawer bottom",
        (cx, drawer_y + 0.18, z - height * 0.5 + 0.16),
        (width - 0.55, depth - 0.35, 0.20),
        mats["walnut"],
        0.02,
    )
    _dovetail_marks(
        base, name, cx - width * 0.5 + 0.31, front - 0.05, z, width, height, mats["oak_light"]
    )
    _box(
        base,
        f"{name} brass bail pull backplate",
        (cx, face_y - 0.13, z - 0.08),
        (1.65, 0.18, 0.62),
        mats["brass"],
        0.16,
    )
    for dx in (-0.55, 0.55):
        _cylinder(
            base,
            f"{name} bail pull pivot",
            (cx + dx, face_y - 0.25, z - 0.12),
            0.11,
            0.16,
            mats["brass"],
            "Y",
            24,
        )
        _cylinder(
            base,
            f"{name} bail pull arm",
            (cx + dx, face_y - 0.31, z - 0.35),
            0.075,
            0.42,
            mats["brass"],
            "Z",
            20,
        )
    _cylinder(
        base,
        f"{name} brass bail grip",
        (cx, face_y - 0.34, z - 0.56),
        0.08,
        1.18,
        mats["brass"],
        "X",
        24,
    )


def _cut_vertical_hole(base, obj, name, x, y, z, radius, depth):
    bpy = base.bpy
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=(x, y, z))
    cutter = bpy.context.object
    cutter.name = name + " cutter"
    modifier = obj.modifiers.new(name, "BOOLEAN")
    modifier.operation = "DIFFERENCE"
    modifier.solver = "EXACT"
    modifier.object = cutter
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter, do_unlink=True)


def _tenon_pegs(base, name, x, y, z, count, spacing, material):
    for index in range(count):
        dx = (index - (count - 1) * 0.5) * spacing
        _cylinder(
            base,
            f"{name} exposed hardwood peg {index + 1}",
            (x + dx, y, z),
            0.12,
            0.08,
            material,
            "Y",
            16,
        )


def build_workbench(base, mats):
    width, depth, height = 58.0, 30.0, 36.0
    top_thickness = 3.6
    top_z = height - top_thickness * 0.5
    top = _box(
        base,
        "Workbench joined oak top",
        (0.0, 0.0, top_z),
        (width, depth, top_thickness),
        mats["oak"],
        0.18,
    )
    for x in (-22.0, -11.0, 0.0, 11.0, 22.0):
        for y in (-9.0, 0.0, 9.0):
            _cut_vertical_hole(
                base, top, "Workbench dog hole", x, y, top_z, 0.48, top_thickness + 0.5
            )
    for side in (-1, 1):
        for fore_aft in (-1, 1):
            x, y = side * 25.0, fore_aft * 12.0
            _box(
                base, "Workbench square oak leg", (x, y, 16.2), (4.0, 4.0, 32.4), mats["oak"], 0.14
            )
            _box(
                base,
                "Workbench leg foot chamfer",
                (x, y, 1.1),
                (4.2, 4.1, 1.5),
                mats["oak_light"],
                0.18,
            )
    for y in (-12.0, 12.0):
        _box(base, "Workbench long apron", (0.0, y, 25.0), (48.0, 2.0, 7.0), mats["walnut"], 0.12)
        for x in (-20.0, 20.0):
            _box(
                base,
                "Workbench apron through tenon shoulder",
                (x, y - 1.05, 25.0),
                (3.3, 0.16, 5.8),
                mats["oak_light"],
                0.045,
            )
            _tenon_pegs(base, "Workbench apron peg", x, y - 1.16, 25.0, 2, 1.1, mats["walnut"])
    for x in (-25.0, 25.0):
        _box(base, "Workbench end apron", (x, 0.0, 25.0), (2.0, 20.0, 7.0), mats["oak"], 0.1)
    _box(
        base,
        "Workbench lower front stretcher",
        (0.0, -12.0, 5.0),
        (47.0, 2.0, 3.2),
        mats["oak_light"],
        0.10,
    )
    _box(
        base,
        "Workbench lower rear stretcher",
        (0.0, 12.0, 5.0),
        (47.0, 2.0, 3.2),
        mats["oak"],
        0.10,
    )
    for x in (-20.5, 20.5):
        _box(base, "Workbench end stretcher", (x, 0.0, 5.0), (2.0, 20.0, 3.2), mats["oak"], 0.08)
    _box(
        base,
        "Workbench front stretcher wedge key left",
        (-20.0, -13.08, 5.0),
        (0.65, 0.18, 2.0),
        mats["walnut"],
        0.035,
    )
    _box(
        base,
        "Workbench front stretcher wedge key right",
        (20.0, -13.08, 5.0),
        (0.65, 0.18, 2.0),
        mats["walnut"],
        0.035,
    )
    drawer_specs = [(-16.0, 10.0, 2.4), (0.0, 12.0, 2.4), (17.0, 15.0, 2.8)]
    for index, (x, drawer_w, drawer_h) in enumerate(drawer_specs, start=1):
        _drawer(
            base,
            mats,
            f"Workbench dovetail drawer {index}",
            x,
            -13.75,
            29.0,
            drawer_w,
            drawer_h,
            9.0,
            0.55 if index == 3 else 0.25,
        )
    # Separate forged plates, screw, guide bars, and wooden moving jaw.
    _box(
        base,
        "Workbench vise iron cheek plate",
        (-22.0, -14.15, 20.5),
        (5.0, 0.38, 6.5),
        mats["iron"],
        0.10,
    )
    _box(
        base,
        "Workbench vise leather jaw",
        (-22.0, -14.38, 20.5),
        (4.5, 0.18, 5.7),
        mats["leather"],
        0.07,
    )
    _cylinder(base, "Workbench vise screw", (-22.0, -13.6, 20.5), 0.43, 1.2, mats["steel"], "Y", 32)
    _cylinder(
        base, "Workbench vise crossbar", (-22.0, -14.35, 20.5), 0.16, 3.2, mats["brass"], "X", 24
    )
    for x in (-23.9, -20.1):
        _cylinder(
            base,
            "Workbench vise fixing bolt",
            (x, -14.48, 22.7),
            0.17,
            0.10,
            mats["brass"],
            "Y",
            20,
        )


def _tapered_square_leg(base, name, x, y, height, bottom_width, top_width, material):
    bottom_half = bottom_width * 0.5
    top_half = top_width * 0.5
    vertices = [
        (-bottom_half, -bottom_half, 0.0),
        (bottom_half, -bottom_half, 0.0),
        (bottom_half, bottom_half, 0.0),
        (-bottom_half, bottom_half, 0.0),
        (-top_half, -top_half, height),
        (top_half, -top_half, height),
        (top_half, top_half, height),
        (-top_half, top_half, height),
    ]
    faces = [(3, 2, 1, 0), (4, 5, 6, 7)]
    faces.extend((index, (index + 1) % 4, (index + 1) % 4 + 4, index + 4) for index in range(4))
    mesh = bpy.data.meshes.new(name + " tapered profile")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, y, 0.0)
    bevel = obj.modifiers.new(name + " eased arris", "BEVEL")
    bevel.width = 0.08
    bevel.segments = 2
    return obj


def build_assembly_table(base, mats):
    width, depth, height = 42.0, 32.0, 24.0
    top_thickness = 3.0
    top_z = height - top_thickness * 0.5
    top = _box(
        base,
        "Assembly table solid oak top",
        (0.0, 0.0, top_z),
        (width, depth, top_thickness),
        mats["oak"],
        0.16,
    )
    for x in (-15.0, -7.5, 0.0, 7.5, 15.0):
        for y in (-10.0, 0.0, 10.0):
            _cut_vertical_hole(
                base, top, "Assembly table dog hole", x, y, top_z, 0.42, top_thickness + 0.5
            )
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 17.3, sy * 13.3
            _tapered_square_leg(
                base, "Assembly table tapered oak leg", x, y, 21.0, 3.5, 2.8, mats["oak"]
            )
    for y in (-13.3, 13.3):
        _box(
            base,
            "Assembly table long apron",
            (0.0, y, 18.2),
            (34.5, 1.8, 4.8),
            mats["walnut"],
            0.10,
        )
        for x in (-15.0, 15.0):
            _box(
                base,
                "Assembly table mortise tenon shoulder",
                (x, y - 0.95, 18.2),
                (2.8, 0.14, 3.5),
                mats["oak_light"],
                0.035,
            )
            _tenon_pegs(
                base, "Assembly table exposed tenon peg", x, y - 1.05, 18.2, 2, 0.9, mats["walnut"]
            )
    for x in (-17.3, 17.3):
        _box(base, "Assembly table end apron", (x, 0.0, 18.2), (1.8, 24.0, 4.8), mats["oak"], 0.08)
        _box(
            base,
            "Assembly table breadboard end",
            (x * 1.16, 0.0, top_z),
            (1.7, 29.0, top_thickness),
            mats["oak_light"],
            0.10,
        )
        for y in (-10.0, 0.0, 10.0):
            _cylinder(
                base,
                "Assembly table breadboard peg",
                (x * 1.16, y, height - 0.3),
                0.13,
                0.08,
                mats["walnut"],
                "X",
                16,
            )
    _box(
        base, "Assembly table lower shelf", (0.0, 0.0, 6.0), (30.5, 22.0, 1.0), mats["walnut"], 0.10
    )
    _box(
        base,
        "Assembly table shelf front edge",
        (0.0, -10.8, 6.0),
        (30.0, 0.45, 1.6),
        mats["oak_light"],
        0.08,
    )
    for y in (-13.3, 13.3):
        _box(
            base,
            "Assembly table lower long stretcher",
            (0.0, y, 3.4),
            (31.0, 1.4, 2.4),
            mats["oak_light"],
            0.08,
        )
    for x in (-17.3, 17.3):
        _box(
            base,
            "Assembly table lower end stretcher",
            (x, 0.0, 3.4),
            (1.4, 24.0, 2.4),
            mats["oak"],
            0.08,
        )
    _drawer(base, mats, "Assembly table dovetailed drawer", 0.0, -14.2, 18.5, 18.0, 3.2, 7.0, 0.22)
    # End vise is distinct from the oak jaw and the steel guide rods.
    _box(
        base,
        "Assembly table end vise plate",
        (20.1, -2.0, 18.6),
        (0.25, 5.6, 4.8),
        mats["iron"],
        0.08,
    )
    _box(
        base,
        "Assembly table vise wood jaw",
        (19.8, -2.0, 18.6),
        (0.6, 5.2, 4.2),
        mats["oak_light"],
        0.06,
    )
    _cylinder(
        base, "Assembly table vise screw", (20.35, -2.0, 18.6), 0.38, 1.2, mats["steel"], "X", 28
    )
    _cylinder(
        base, "Assembly table vise handle", (20.55, -2.0, 18.6), 0.14, 2.8, mats["brass"], "Y", 20
    )


def _turned_leg(base, name, x, y, height, material, scale=1.0):
    profile = [
        (0.00, 0.72),
        (0.05, 0.78),
        (0.11, 0.70),
        (0.18, 0.48),
        (0.28, 0.42),
        (0.36, 0.56),
        (0.43, 0.78),
        (0.56, 0.92),
        (0.69, 0.76),
        (0.76, 0.48),
        (0.83, 0.42),
        (0.90, 0.54),
        (0.96, 0.64),
        (1.00, 0.62),
    ]
    segments = 32
    vertices = []
    for fraction, radius in profile:
        z = fraction * height
        r = radius * scale
        for segment in range(segments):
            angle = math.tau * segment / segments
            vertices.append((x + math.cos(angle) * r, y + math.sin(angle) * r, z))
    faces = []
    faces.append(tuple(range(segments - 1, -1, -1)))
    for ring in range(len(profile) - 1):
        for segment in range(segments):
            a = ring * segments + segment
            b = ring * segments + (segment + 1) % segments
            c = (ring + 1) * segments + (segment + 1) % segments
            d = (ring + 1) * segments + segment
            faces.append((a, b, c, d))
    faces.append(tuple((len(profile) - 1) * segments + i for i in range(segments)))
    mesh = bpy.data.meshes.new(name + " turned profile")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    return obj


def _local_box(base, name, hinge, theta, dx, dy, z, size, material, bevel=0.04):
    hx, hy = hinge
    c, s = math.cos(theta), math.sin(theta)
    center = (hx + dx * c - dy * s, hy + dx * s + dy * c, z)
    obj = _box(base, name, center, size, material, bevel, (0.0, 0.0, theta))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return obj


def build_tool_wardrobe(base, mats):
    front_y = -3.0
    # Thick carcass stiles, panels, fitted shelves, back, and a stepped cornice.
    _box(
        base,
        "Tool wardrobe left carcass stile",
        (-20.0, 4.15, 35.0),
        (2.0, 14.9, 66.0),
        mats["oak"],
        0.10,
    )
    _box(
        base,
        "Tool wardrobe right carcass stile",
        (20.0, 4.15, 35.0),
        (2.0, 14.9, 66.0),
        mats["oak"],
        0.10,
    )
    _box(
        base,
        "Tool wardrobe solid fitted back",
        (0.0, 11.0, 35.0),
        (38.0, 1.2, 64.0),
        mats["walnut"],
        0.08,
    )
    _box(
        base,
        "Tool wardrobe base panel",
        (0.0, 4.15, 4.0),
        (38.0, 14.9, 2.0),
        mats["oak_light"],
        0.08,
    )
    _box(
        base,
        "Tool wardrobe lower plinth",
        (0.0, 4.15, 1.8),
        (42.0, 14.9, 3.6),
        mats["walnut"],
        0.16,
    )
    _box(
        base,
        "Tool wardrobe crown lower molding",
        (0.0, 3.6, 66.6),
        (40.0, 16.0, 1.2),
        mats["oak_light"],
        0.11,
    )
    _box(base, "Tool wardrobe crown cap", (0.0, 3.6, 68.7), (42.0, 16.0, 2.4), mats["oak"], 0.18)
    for x in (-10.5, 10.5):
        _box(
            base,
            "Tool wardrobe full height bay divider",
            (x, 4.15, 35.0),
            (1.25, 14.0, 62.0),
            mats["oak"],
            0.07,
        )
    for z in (18.0, 31.0, 46.0, 59.5):
        _box(
            base,
            "Tool wardrobe fitted shelf",
            (0.0, 4.0, z),
            (20.0, 13.0, 1.25),
            mats["oak_light"],
            0.07,
        )
    # Broad doors swing open in front of the bays while staying inside the exact depth.
    for side in (-1, 1):
        hinge_x = side * 19.0
        theta = -math.radians(21.5) if side < 0 else math.radians(21.5)
        direction = 1 if side < 0 else -1
        door_w, door_h = 18.0, 58.0
        _local_box(
            base,
            "Wardrobe open frame and panel door",
            (hinge_x, front_y),
            theta,
            direction * door_w * 0.5,
            -0.35,
            35.0,
            (door_w, 1.0, door_h),
            mats["oak"],
            0.12,
        )
        for dx in (direction * 0.45, direction * (door_w - 0.45)):
            _local_box(
                base,
                "Wardrobe door vertical stile",
                (hinge_x, front_y),
                theta,
                dx,
                -0.56,
                35.0,
                (0.62, 0.18, door_h - 0.2),
                mats["oak_light"],
                0.045,
            )
        for z in (7.0, 20.0, 49.0, 63.0):
            _local_box(
                base,
                "Wardrobe door cross rail",
                (hinge_x, front_y),
                theta,
                direction * door_w * 0.5,
                -0.56,
                z,
                (door_w - 0.2, 0.18, 0.72),
                mats["oak_light"],
                0.04,
            )
        for z in (15.0, 35.0, 55.0):
            _local_box(
                base,
                "Wardrobe door recessed floating panel",
                (hinge_x, front_y),
                theta,
                direction * door_w * 0.5,
                -0.54,
                z,
                (door_w - 1.25, 0.16, 17.0),
                mats["walnut"],
                0.045,
            )
        for hinge_z in (11.0, 35.0, 59.0):
            _local_box(
                base,
                "Wardrobe brass hinge leaf",
                (hinge_x, front_y),
                theta,
                0.0,
                -0.60,
                hinge_z,
                (0.28, 0.18, 4.2),
                mats["brass"],
                0.035,
            )
            _cylinder(
                base,
                "Wardrobe hinge barrel",
                (hinge_x, front_y - 0.72, hinge_z),
                0.16,
                4.5,
                mats["brass"],
                "Z",
                20,
            )
        _local_box(
            base,
            "Wardrobe brass pull backplate",
            (hinge_x, front_y),
            theta,
            direction * (door_w - 1.2),
            -0.61,
            35.0,
            (0.8, 0.18, 4.2),
            mats["brass"],
            0.10,
        )
        _local_box(
            base,
            "Wardrobe pull handle",
            (hinge_x, front_y),
            theta,
            direction * (door_w - 1.2),
            -0.82,
            35.0,
            (0.35, 0.28, 2.7),
            mats["brass"],
            0.14,
        )
    # Work tools use varied handles, ferrules, and steel blades, mounted within the bay.
    for index, x in enumerate((-7.8, -5.4, -3.0, -0.6, 1.8, 4.2, 6.6), start=1):
        z_top = 51.0 - (index % 2) * 2.0
        _cylinder(
            base,
            f"Wardrobe chisel oak handle {index}",
            (x, front_y + 3.0, z_top - 2.5),
            0.32,
            3.4,
            mats["walnut"],
            "Z",
            20,
        )
        _cylinder(
            base,
            f"Wardrobe chisel brass ferrule {index}",
            (x, front_y + 3.0, z_top - 4.0),
            0.28,
            0.38,
            mats["brass"],
            "Z",
            20,
        )
        _box(
            base,
            f"Wardrobe chisel steel blade {index}",
            (x, front_y + 3.0, z_top - 8.0),
            (0.32, 0.22, 4.2),
            mats["steel"],
            0.035,
        )
    for x in (-6.4, 1.0, 6.0):
        _box(
            base,
            "Wardrobe fitted hand plane body",
            (x, front_y + 3.4, 42.0),
            (5.4, 2.3, 2.0),
            mats["walnut"],
            0.25,
        )
        _box(
            base,
            "Wardrobe hand plane iron cap",
            (x, front_y + 3.4, 43.1),
            (1.4, 1.0, 0.22),
            mats["steel"],
            0.08,
        )
        _cylinder(
            base,
            "Wardrobe plane front knob",
            (x, front_y + 3.4, 44.0),
            0.44,
            1.3,
            mats["oak_light"],
            "Z",
            24,
        )
    _drawer(base, mats, "Wardrobe lower fitted drawer", 0.0, -2.6, 9.2, 16.2, 4.5, 6.0, 0.25)


def build_floor_cabinet(base, mats):
    _box(
        base,
        "Floor cabinet left side panel",
        (-11.7, 0.0, 12.0),
        (2.0, 22.0, 18.0),
        mats["oak"],
        0.10,
    )
    _box(
        base,
        "Floor cabinet right side panel",
        (11.7, 0.0, 12.0),
        (2.0, 22.0, 18.0),
        mats["oak"],
        0.10,
    )
    _box(
        base, "Floor cabinet back panel", (0.0, 11.0, 10.5), (22.0, 1.0, 17.5), mats["walnut"], 0.06
    )
    _box(base, "Floor cabinet bottom", (0.0, 0.0, 3.9), (22.5, 22.0, 1.4), mats["oak_light"], 0.08)
    _box(base, "Floor cabinet solid top", (0.0, 0.0, 19.8), (26.0, 24.0, 2.4), mats["oak"], 0.20)
    _box(
        base, "Floor cabinet plinth base", (0.0, 0.0, 1.7), (25.2, 23.2, 3.4), mats["walnut"], 0.18
    )
    _box(
        base,
        "Floor cabinet plinth bead",
        (0.0, 0.0, 3.5),
        (24.0, 22.4, 0.7),
        mats["oak_light"],
        0.09,
    )
    for z in (11.0, 18.0):
        _box(
            base,
            "Floor cabinet face frame rail",
            (0.0, -11.0, z),
            (23.0, 0.85, 0.75),
            mats["oak_light"],
            0.06,
        )
    for x in (-11.15, 11.15):
        _box(
            base,
            "Floor cabinet face frame stile",
            (x, -11.0, 12.0),
            (0.9, 0.85, 18.0),
            mats["oak_light"],
            0.06,
        )
    _drawer(
        base, mats, "Floor cabinet upper dovetail drawer", 0.0, -9.4, 17.2, 20.7, 5.4, 7.0, 0.35
    )
    _drawer(base, mats, "Floor cabinet lower dovetail drawer", 0.0, -9.4, 8.8, 20.7, 6.0, 7.0, 0.35)


def build_side_table(base, mats):
    width, depth, height = 20.0, 17.0, 20.0
    top_thickness = 1.35
    _box(
        base,
        "Side table beveled solid oak top",
        (0.0, 0.0, height - top_thickness * 0.5),
        (width, depth, top_thickness),
        mats["oak"],
        0.28,
    )
    for sx in (-1, 1):
        for sy in (-1, 1):
            _turned_leg(
                base,
                "Side table turned bead and cove leg",
                sx * 8.3,
                sy * 7.0,
                15.0,
                mats["oak"],
                0.78,
            )
    for y in (-7.0, 7.0):
        _box(
            base,
            "Side table fitted long apron",
            (0.0, y, 16.4),
            (15.8, 1.4, 3.1),
            mats["oak_light"],
            0.10,
        )
        for x in (-6.0, 6.0):
            _tenon_pegs(
                base, "Side table apron joint peg", x, y - 0.78, 16.4, 1, 0.6, mats["walnut"]
            )
    for x in (-8.3, 8.3):
        _box(
            base, "Side table fitted end apron", (x, 0.0, 16.4), (1.4, 13.4, 3.1), mats["oak"], 0.08
        )
    _drawer(
        base, mats, "Side table through dovetail drawer", 0.0, -7.5, 16.6, 11.7, 2.45, 5.8, 0.20
    )
    _box(
        base,
        "Side table tenoned walnut shelf",
        (0.0, 0.0, 4.2),
        (16.6, 16.6, 1.1),
        mats["walnut"],
        0.16,
    )
    for x in (-7.7, 7.7):
        for y in (-7.7, 7.7):
            _box(
                base,
                "Side table shelf tenon shoulder",
                (x, y, 4.2),
                (1.25, 1.25, 1.3),
                mats["oak_light"],
                0.12,
            )


def build_household_bookcase(base, mats):
    """Build the Room A domestic bookcase, distinct from the Room B parts rack."""
    width, depth = 32.0, 17.0
    front = -depth * 0.5
    inner_width = 27.2

    # The four feet meet the broad plinth; the outer case dimensions remain exact.
    for x in (-13.2, 13.2):
        for y in (-6.7, 6.7):
            _box(
                base,
                "Household bookcase shaped foot",
                (x, y, 1.1),
                (3.0, 2.5, 2.2),
                mats["walnut"],
                0.34,
            )
    _box(
        base,
        "Household bookcase recessed plinth",
        (0.0, 0.0, 2.0),
        (width, depth, 3.6),
        mats["walnut"],
        0.24,
    )
    _box(
        base,
        "Household bookcase plinth oak bead",
        (0.0, front + 0.28, 3.2),
        (width - 1.1, 0.56, 0.54),
        mats["oak_light"],
        0.13,
    )

    case_bottom, case_top = 4.1, 59.2
    side_height = case_top - case_bottom
    for side in (-1, 1):
        side_x = side * 15.25
        _box(
            base,
            "Household bookcase solid oak side panel",
            (side_x, 0.0, (case_bottom + case_top) * 0.5),
            (1.35, depth - 1.1, side_height),
            mats["oak"],
            0.16,
        )
        # Recessed-looking fields and narrow walnut rails expose the panel build.
        outside_x = side * 15.88
        for panel_bottom, panel_top in ((7.0, 30.1), (32.0, 56.2)):
            _box(
                base,
                "Household bookcase inset side field",
                (outside_x, 0.0, (panel_bottom + panel_top) * 0.5),
                (0.10, 12.4, panel_top - panel_bottom),
                mats["oak_light"],
                0.045,
            )
            for rail_y in (-6.3, 6.3):
                _box(
                    base,
                    "Household bookcase side panel stile",
                    (outside_x + side * 0.035, rail_y, (panel_bottom + panel_top) * 0.5),
                    (0.12, 0.42, panel_top - panel_bottom + 0.18),
                    mats["walnut"],
                    0.055,
                )
            for rail_z in (panel_bottom, panel_top):
                _box(
                    base,
                    "Household bookcase side panel rail",
                    (outside_x + side * 0.035, 0.0, rail_z),
                    (0.12, 12.9, 0.42),
                    mats["walnut"],
                    0.055,
                )

    # A single fitted back and face-frame stiles keep the open book bays structural.
    _box(
        base,
        "Household bookcase recessed oak back",
        (0.0, 7.95, (case_bottom + case_top) * 0.5),
        (inner_width, 0.82, side_height),
        mats["walnut"],
        0.10,
    )
    for x in (-14.0, 14.0):
        _box(
            base,
            "Household bookcase walnut face-frame stile",
            (x, front + 0.38, (case_bottom + case_top) * 0.5),
            (2.05, 0.62, side_height),
            mats["walnut"],
            0.13,
        )
        _box(
            base,
            "Household bookcase oak stile bead",
            (x + (-0.52 if x < 0.0 else 0.52), front + 0.03, (case_bottom + case_top) * 0.5),
            (0.28, 0.18, side_height - 0.6),
            mats["oak_light"],
            0.07,
        )

    shelf_levels = [4.55, 15.25, 26.0, 36.75, 47.5]
    for index, z in enumerate(shelf_levels):
        shelf_material = mats["oak"] if index % 2 == 0 else mats["oak_light"]
        _box(
            base,
            f"Household bookcase fitted shelf {index + 1}",
            (0.0, 0.0, z),
            (inner_width, depth - 2.0, 0.86),
            shelf_material,
            0.12,
        )
        _box(
            base,
            f"Household bookcase solid shelf nosing {index + 1}",
            (0.0, front + 0.72, z + 0.16),
            (inner_width - 0.08, 0.54, 0.56),
            mats["walnut"] if index in (1, 3) else mats["oak_light"],
            0.12,
        )
        for x in (-12.9, 12.9):
            base.cylinder(
                f"Household bookcase brass shelf pin {index + 1}",
                (x, front + 1.1, z - 0.62),
                0.075,
                0.16,
                mats["brass"],
                "Y",
                16,
                0.012,
            )

    # Layered crown rails and top cap are joined to the side panels and back.
    _box(
        base,
        "Household bookcase crown lower rail",
        (0.0, 0.0, 59.6),
        (width - 0.4, depth - 0.5, 1.15),
        mats["walnut"],
        0.14,
    )
    _box(
        base,
        "Household bookcase crown ogee band",
        (0.0, front + 0.38, 60.55),
        (width - 0.15, 0.76, 1.05),
        mats["oak_light"],
        0.20,
    )
    _box(
        base,
        "Household bookcase solid crown cap",
        (0.0, 0.0, 62.15),
        (width, depth, 1.7),
        mats["oak"],
        0.27,
    )

    book_materials = [
        base.pbr_material(
            "Household bookcase forest cloth bindings", (0.10, 0.18, 0.15), 0.0, 0.72, "fabric"
        ),
        base.pbr_material(
            "Household bookcase navy cloth bindings", (0.08, 0.13, 0.19), 0.0, 0.70, "fabric"
        ),
        base.pbr_material(
            "Household bookcase oxblood leather bindings", (0.27, 0.09, 0.065), 0.0, 0.63, "fabric"
        ),
        base.pbr_material(
            "Household bookcase russet cloth bindings", (0.39, 0.22, 0.11), 0.0, 0.72, "fabric"
        ),
        base.pbr_material(
            "Household bookcase olive linen bindings", (0.31, 0.30, 0.18), 0.0, 0.76, "fabric"
        ),
    ]
    gilt = base.pbr_material(
        "Household bookcase aged gold spine tooling", (0.56, 0.39, 0.17), 0.62, 0.39, "metal"
    )
    page_material = base.pbr_material(
        "Household bookcase warm ivory page edges", (0.70, 0.62, 0.45), 0.0, 0.82, "paper"
    )

    # Each compartment has a distinct book grouping, leaving visible shelf space.
    patterns = [
        [
            (0.00, 0.94, 6.3, 0),
            (1.02, 1.20, 7.2, 1),
            (2.30, 0.88, 5.9, 3),
            (3.27, 1.16, 6.8, 2),
            (4.50, 1.05, 6.1, 4),
        ],
        [
            (-1.4, 0.88, 6.5, 2),
            (-0.45, 1.05, 7.0, 3),
            (0.70, 1.20, 6.1, 4),
            (2.00, 0.94, 7.4, 0),
            (3.05, 1.12, 6.7, 1),
            (4.25, 0.98, 5.8, 2),
        ],
        [
            (-5.4, 0.98, 6.7, 4),
            (-4.35, 1.20, 7.1, 0),
            (-3.06, 0.88, 6.0, 1),
            (-2.12, 1.10, 7.5, 2),
            (-0.95, 0.96, 6.4, 3),
        ],
        [
            (-1.8, 1.00, 7.2, 1),
            (-0.73, 0.90, 6.3, 0),
            (0.25, 1.18, 7.6, 4),
            (1.50, 1.02, 6.5, 2),
            (2.60, 1.15, 7.0, 3),
            (3.82, 0.96, 6.2, 1),
        ],
        [
            (-5.9, 0.92, 6.0, 3),
            (-4.9, 1.12, 6.6, 2),
            (-3.7, 0.97, 7.2, 4),
            (-2.65, 1.16, 6.5, 0),
            (-1.4, 0.94, 6.9, 1),
        ],
    ]
    for row, books in enumerate(patterns):
        shelf_z = shelf_levels[row]
        for book_index, (x, book_width, book_height, color_index) in enumerate(books):
            book_depth = 3.7 + (book_index % 3) * 0.22
            book_y = -4.35 + (book_index % 2) * 0.30
            book_z = shelf_z + 0.43 + book_height * 0.5
            cover = book_materials[color_index]
            _box(
                base,
                f"Household bookcase clothbound volume r{row + 1} b{book_index + 1}",
                (x, book_y, book_z),
                (book_width, book_depth, book_height),
                cover,
                0.10,
            )
            _box(
                base,
                f"Household bookcase ivory page block r{row + 1} b{book_index + 1}",
                (x, book_y + 0.24, book_z),
                (book_width * 0.74, book_depth * 0.84, book_height * 0.88),
                page_material,
                0.045,
            )
            for band_z in (book_z - book_height * 0.34, book_z + book_height * 0.34):
                _box(
                    base,
                    f"Household bookcase gilt spine band r{row + 1} b{book_index + 1}",
                    (x, book_y - book_depth * 0.5 - 0.03, band_z),
                    (book_width * 0.8, 0.055, 0.10),
                    gilt,
                    0.022,
                )


def _run_in_blender(asset_type: str, output_file: Path, generation_variant: str = "") -> None:
    base = _base_module()
    base.clear_scene()
    mats = _materials(base, generation_variant)
    builders = {
        "household_bookcase": build_household_bookcase,
        "workbench": build_workbench,
        "assembly_table": build_assembly_table,
        "tool_wardrobe": build_tool_wardrobe,
        "floor_cabinet": build_floor_cabinet,
        "side_table": build_side_table,
    }
    builder = builders.get(asset_type)
    if builder is None:
        raise ValueError(f"unsupported furniture asset type: {asset_type}")
    builder(base, mats)
    bpy.context.view_layer.update()
    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in bpy.context.scene.objects
        if obj.type == "MESH"
        for corner in obj.bound_box
    ]
    if corners:
        minimum = Vector(tuple(min(point[i] for point in corners) for i in range(3)))
        maximum = Vector(tuple(max(point[i] for point in corners) for i in range(3)))
        extent = maximum - minimum
        print(
            f"ROOMSCALE_BATCH10_GEOMETRY_BOUNDS_BLENDER min={tuple(round(v, 3) for v in minimum)} max={tuple(round(v, 3) for v in maximum)} extent={tuple(round(v, 3) for v in extent)}"
        )
    base.apply_modifiers_and_merge_by_material(randomize_furniture_wood_uvs=True)
    bpy.ops.object.select_all(action="SELECT")
    output_file.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_file),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
    )
    if not output_file.is_file() or output_file.stat().st_size < 1024:
        raise RuntimeError(f"Blender did not create a usable GLB: {output_file}")
    print(
        f"ROOMSCALE_BATCH10_BLENDER_PASS type={asset_type} path={output_file} bytes={output_file.stat().st_size}"
    )


def main() -> int:
    if IN_BLENDER:
        arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
        if len(arguments) not in (2, 3):
            raise SystemExit(
                "Blender invocation requires <asset_type> <output.glb> [generation_variant] after --"
            )
        generation_variant = arguments[2] if len(arguments) == 3 else ""
        _run_in_blender(arguments[0], Path(arguments[1]), generation_variant)
        return 0
    return dispatch_to_blender()


if __name__ == "__main__":
    raise SystemExit(main())
