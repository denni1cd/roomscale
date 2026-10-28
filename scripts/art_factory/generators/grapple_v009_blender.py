"""Create a high-detail hard-surface miniature grapple challenger in Blender."""

from __future__ import annotations

import json
import math
import os
import random
import sys
from array import array
from datetime import UTC, datetime
from pathlib import Path

import bpy
from mathutils import Vector


def material(name: str, color: tuple[float, float, float, float], metal: float, rough: float):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metal
    principled.inputs["Roughness"].default_value = rough
    return mat


def group_root(name: str):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    root = bpy.data.objects.new(name, None)
    collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    return collection, root


def adopt(obj, collection, root, mat=None):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = root
    if mat is not None:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    return obj


def bevel(obj, width: float, segments: int = 3):
    if width > 0:
        mod = obj.modifiers.new("machined edge radii", "BEVEL")
        mod.width = width
        mod.segments = segments
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(22)
        normal = obj.modifiers.new("weighted hard-surface normals", "WEIGHTED_NORMAL")
        normal.keep_sharp = True
        normal.weight = 45


def cube(collection, root, name, dims, loc, mat, radius=0.025, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    if rot is not None:
        obj.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    adopt(obj, collection, root, mat)
    bevel(obj, radius)
    return obj


def cylinder(collection, root, name, radius, depth, loc, mat, rot=(0, 0, 0), verts=64, edge=0.01):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot
    )
    obj = bpy.context.object
    obj.name = name
    adopt(obj, collection, root, mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    bevel(obj, edge, 3)
    return obj


def torus(collection, root, name, major, minor, loc, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major,
        minor_radius=minor,
        major_segments=64,
        minor_segments=16,
        location=loc,
        rotation=rot,
    )
    obj = bpy.context.object
    obj.name = name
    adopt(obj, collection, root, mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def rod(collection, root, name, start, end, radius, mat, verts=32):
    a, b = Vector(start), Vector(end)
    delta = b - a
    obj = cylinder(
        collection,
        root,
        name,
        radius,
        delta.length,
        (a + b) * 0.5,
        mat,
        delta.to_track_quat("Z", "Y").to_euler(),
        verts,
        radius * 0.22,
    )
    return obj


def poly_curve(collection, root, name, points, radius, mat, resolution=8):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.resolution_u = resolution
    data.bevel_depth = radius
    data.bevel_resolution = 3
    spline = data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points, strict=True):
        point.co = (*co, 1.0)
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.parent = root
    obj.data.materials.append(mat)
    return obj


def bolt(collection, root, name, at, radius, mat, axis="z"):
    x, y, z = at
    rot = (0, 0, 0)
    if axis == "y":
        rot = (-math.pi / 2, 0, 0)
    elif axis == "x":
        rot = (0, math.pi / 2, 0)
    cylinder(
        collection,
        root,
        name + " shank",
        radius * 0.47,
        radius * 0.9,
        (x, y, z),
        mat,
        rot,
        16,
        radius * 0.08,
    )
    # A six-sided forged head with a small chamfer reads as a fastener at macro scale.
    head = cylinder(
        collection,
        root,
        name + " hex head",
        radius,
        radius * 0.48,
        (x, y, z),
        mat,
        rot,
        6,
        radius * 0.08,
    )
    return head


def gear(collection, root, name, center, root_radius, tip_radius, teeth, thickness, mat):
    x0, y0, z0 = center
    pitch = math.tau / teeth
    outline = []
    profile = [
        (-0.50, root_radius),
        (-0.34, root_radius),
        (-0.25, tip_radius),
        (-0.17, tip_radius),
        (0.17, tip_radius),
        (0.25, tip_radius),
        (0.34, root_radius),
        (0.50, root_radius),
    ]
    for tooth in range(teeth):
        base_angle = tooth * pitch
        for fraction, radius in profile:
            angle = base_angle + fraction * pitch
            outline.append((x0 + math.cos(angle) * radius, z0 + math.sin(angle) * radius))
    count = len(outline)
    vertices = [(x, y0 - thickness * 0.5, z) for x, z in outline]
    vertices.extend((x, y0 + thickness * 0.5, z) for x, z in outline)
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    for i in range(count):
        j = (i + 1) % count
        faces.append((i, j, j + count, i + count))
    mesh = bpy.data.meshes.new(name + " involute-like profile")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.parent = root
    bevel(obj, min(0.025, thickness * 0.16), 3)
    return obj


def add_material_microtexture(mat, seed: int, resolution: int = 512):
    """Bake subtle tileable albedo and roughness variation for glTF PBR export."""
    principled = mat.node_tree.nodes.get("Principled BSDF")
    base = tuple(mat.diffuse_color[:3])
    base_image = bpy.data.images.new(
        f"{mat.name} microtexture", resolution, resolution, alpha=False
    )
    base_image.colorspace_settings.name = "sRGB"
    rough_image = bpy.data.images.new(
        f"{mat.name} roughness variation", resolution, resolution, alpha=False
    )
    rough_image.colorspace_settings.name = "Non-Color"
    randomizer = random.Random(seed)
    base_pixels = array("f")
    rough_pixels = array("f")
    rough_base = principled.inputs["Roughness"].default_value
    for y in range(resolution):
        v = y / resolution
        for x in range(resolution):
            u = x / resolution
            wave = (
                math.sin(math.tau * (5 * u + 0.7 * math.sin(math.tau * 3 * v))) * 0.028
                + math.sin(math.tau * (17 * u + 2 * v)) * 0.012
                + math.sin(math.tau * (7 * v - 3 * u)) * 0.01
            )
            noise = randomizer.uniform(-0.035, 0.035)
            factor = min(1.12, max(0.82, 1.0 + wave + noise))
            for channel in base:
                linear = min(1.0, max(0.0, channel * factor))
                srgb = (
                    12.92 * linear if linear <= 0.0031308 else 1.055 * linear ** (1 / 2.4) - 0.055
                )
                base_pixels.append(srgb)
            base_pixels.append(1.0)
            rough = min(1.0, max(0.02, rough_base + wave * 0.7 + noise * 0.45))
            rough_pixels.extend((rough, rough, rough, 1.0))
    base_image.pixels.foreach_set(base_pixels)
    rough_image.pixels.foreach_set(rough_pixels)
    base_image.pack()
    rough_image.pack()
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    base_node = nodes.new("ShaderNodeTexImage")
    base_node.name = f"{mat.name} baked base color"
    base_node.image = base_image
    rough_node = nodes.new("ShaderNodeTexImage")
    rough_node.name = f"{mat.name} baked roughness"
    rough_node.image = rough_image
    links.new(base_node.outputs["Color"], principled.inputs["Base Color"])
    links.new(rough_node.outputs["Color"], principled.inputs["Roughness"])


def batch_group_by_material(collection, root):
    """Convert curves, smart-unwrap, and join parts within each stage/PBR region."""
    objects = [obj for obj in collection.objects if obj != root]
    if not objects:
        return
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.convert(target="MESH")
    meshes = [obj for obj in collection.objects if obj != root and obj.type == "MESH"]
    buckets = {}
    for obj in meshes:
        if not obj.data.materials:
            raise RuntimeError(f"unassigned PBR material on {obj.name}")
        mat = obj.data.materials[0]
        buckets.setdefault(mat.name, []).append(obj)
    for mat_name, parts in buckets.items():
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.select_set(True)
        active = parts[0]
        bpy.context.view_layer.objects.active = active
        if len(parts) > 1:
            bpy.ops.object.join()
        active = bpy.context.view_layer.objects.active
        active.name = f"{root.name}_{mat_name.replace(' ', '_')}"
        active.parent = root
        active.matrix_parent_inverse = root.matrix_world.inverted()
        bpy.ops.object.select_all(action="DESELECT")
        active.select_set(True)
        bpy.context.view_layer.objects.active = active
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(island_margin=0.004)
        bpy.ops.object.mode_set(mode="OBJECT")


def export_group(output: Path, collection, root):
    batch_group_by_material(collection, root)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )


def main(output: Path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    output.mkdir(parents=True, exist_ok=True)
    mats = {
        "wood": material("Oiled walnut hardwood", (0.12, 0.05, 0.02, 1), 0.05, 0.58),
        "iron": material("Forged charcoal iron", (0.045, 0.061, 0.068, 1), 0.82, 0.29),
        "steel": material("Machined satin steel", (0.31, 0.36, 0.38, 1), 0.9, 0.22),
        "brass": material("Aged machined brass", (0.58, 0.36, 0.12, 1), 0.82, 0.25),
        "copper": material("Aged copper pipework", (0.43, 0.16, 0.085, 1), 0.74, 0.3),
        "rope": material("Twisted hemp rope", (0.16, 0.075, 0.028, 1), 0.0, 0.94),
        "enamel": material("Warm ivory gauge enamel", (0.83, 0.77, 0.61, 1), 0.08, 0.28),
        "black": material("Blackened steel", (0.018, 0.024, 0.028, 1), 0.78, 0.24),
    }
    for index, mat in enumerate(mats.values(), 1):
        add_material_microtexture(mat, 27009 + index)
    foundation, foundation_root = group_root("FoundationDetails")
    machine, machine_root = group_root("MachineryDetails")
    launcher, launcher_root = group_root("LauncherDetails")

    # Timber skid and steel shoes: radiused, layered load-bearing construction.
    for index, x in enumerate((-3.78, 3.78)):
        cube(
            foundation,
            foundation_root,
            f"walnut skid {index}",
            (0.74, 6.9, 0.45),
            (x, 0, 0.54),
            mats["wood"],
            0.11,
        )
        cube(
            foundation,
            foundation_root,
            f"forged skid shoe {index}",
            (1.14, 7.5, 0.12),
            (x, 0, 0.06),
            mats["iron"],
            0.055,
        )
        for y in (-3.22, 3.22):
            cube(
                foundation,
                foundation_root,
                f"shoe end cap {index}-{y}",
                (0.68, 0.24, 0.16),
                (x + (0.22 if index else -0.22), y, 0.12),
                mats["steel"],
                0.06,
            )
            bolt(
                foundation,
                foundation_root,
                f"shoe fastener {index}-{y}",
                (x + (0.22 if index else -0.22), y, 0.255),
                0.105,
                mats["steel"],
            )
        for y in (-2.5, -1.25, 0, 1.25, 2.5):
            bolt(
                foundation,
                foundation_root,
                f"skid lag bolt {index}-{y}",
                (x, y, 0.772),
                0.075,
                mats["black"],
            )
    for index, y in enumerate((-2.85, 2.85)):
        cube(
            foundation,
            foundation_root,
            f"cross bearer {index}",
            (6.9, 0.48, 0.34),
            (0, y, 0.64),
            mats["wood"],
            0.075,
        )
    cube(
        foundation,
        foundation_root,
        "winch mounting bed",
        (5.9, 3.9, 0.2),
        (0, 0.05, 0.91),
        mats["black"],
        0.07,
    )
    for x in (-2.7, -1.35, 1.35, 2.7):
        for y in (-1.55, 1.55):
            bolt(
                foundation,
                foundation_root,
                f"bed anchor {x}-{y}",
                (x, y, 1.025),
                0.095,
                mats["brass"],
            )

    # Winch cradle, pillow blocks, turned drum, side plates and a true rope helix.
    for x in (-1.55, 1.55):
        cube(
            machine,
            machine_root,
            f"bearing pedestal {x}",
            (0.52, 2.05, 1.85),
            (x, -0.1, 1.95),
            mats["iron"],
            0.12,
        )
        cube(
            machine,
            machine_root,
            f"bearing cap {x}",
            (0.72, 2.1, 0.24),
            (x, -0.1, 2.95),
            mats["steel"],
            0.085,
        )
        for y in (-0.82, 0.62):
            bolt(
                machine,
                machine_root,
                f"bearing cap bolt {x}-{y}",
                (x, y, 3.09),
                0.095,
                mats["brass"],
            )
    cylinder(
        machine,
        machine_root,
        "turned winch drum",
        0.88,
        2.82,
        (0, -0.1, 2.72),
        mats["wood"],
        (0, math.pi / 2, 0),
        96,
        0.045,
    )
    for x in (-1.46, 1.46):
        cylinder(
            machine,
            machine_root,
            f"drum side plate {x}",
            1.12,
            0.16,
            (x, -0.1, 2.72),
            mats["iron"],
            (0, math.pi / 2, 0),
            96,
            0.04,
        )
        cylinder(
            machine,
            machine_root,
            f"drum flange rim {x}",
            1.03,
            0.045,
            (x + (0.095 if x > 0 else -0.095), -0.1, 2.72),
            mats["steel"],
            (0, math.pi / 2, 0),
            96,
            0.02,
        )
        cylinder(
            machine,
            machine_root,
            f"drum hub {x}",
            0.32,
            0.34,
            (x + (0.18 if x > 0 else -0.18), -0.1, 2.72),
            mats["brass"],
            (0, math.pi / 2, 0),
            64,
            0.025,
        )
        for bolt_index in range(12):
            angle = math.tau * bolt_index / 12
            bolt(
                machine,
                machine_root,
                f"flange bolt {x}-{bolt_index}",
                (
                    x + (0.12 if x > 0 else -0.12),
                    -0.1 + 0.94 * math.cos(angle),
                    2.72 + 0.94 * math.sin(angle),
                ),
                0.052,
                mats["steel"],
                "x",
            )
    helix = []
    for step in range(801):
        t = step / 800
        angle = math.tau * 12.5 * t
        helix.append(
            (-1.28 + 2.56 * t, -0.1 + 0.99 * math.cos(angle), 2.72 + 0.99 * math.sin(angle))
        )
    strands = [[], [], []]
    for step, center in enumerate(helix):
        t = step / 800
        theta = math.tau * 12.5 * t
        radial = (math.cos(theta), math.sin(theta))
        perpendicular = (-math.sin(theta), math.cos(theta))
        phase = math.tau * 34 * t
        for strand in range(3):
            strand_phase = phase + math.tau * strand / 3
            offset_a = 0.022 * math.cos(strand_phase)
            offset_b = 0.022 * math.sin(strand_phase)
            strands[strand].append(
                (
                    center[0],
                    center[1] + radial[0] * offset_a + perpendicular[0] * offset_b,
                    center[2] + radial[1] * offset_a + perpendicular[1] * offset_b,
                )
            )
    for strand_index, points in enumerate(strands):
        poly_curve(
            machine,
            machine_root,
            f"braided hemp strand {strand_index}",
            points,
            0.026,
            mats["rope"],
        )

    # An involute-like bevelled gear and guarded drive linkage replace crude square teeth.
    gear(
        machine,
        machine_root,
        "twenty tooth drive gear",
        (2.05, -0.48, 2.86),
        0.91,
        1.12,
        20,
        0.19,
        mats["brass"],
    )
    cylinder(
        machine,
        machine_root,
        "drive gear hub",
        0.31,
        0.28,
        (2.05, -0.65, 2.86),
        mats["steel"],
        (-math.pi / 2, 0, 0),
        64,
        0.035,
    )
    torus(
        machine,
        machine_root,
        "drive hub collar",
        0.24,
        0.045,
        (2.05, -0.82, 2.86),
        mats["brass"],
        (-math.pi / 2, 0, 0),
    )
    for x in (1.65, 2.45):
        cube(
            machine,
            machine_root,
            f"gear guard cheek {x}",
            (0.18, 0.9, 1.48),
            (x, -0.76, 2.9),
            mats["iron"],
            0.07,
        )
    for z in (2.2, 3.55):
        bolt(
            machine,
            machine_root,
            f"gear cover screw {z}",
            (2.45, -1.23, z),
            0.08,
            mats["steel"],
            "y",
        )

    # Copper pressure pot, rolled seam rings, lid clamps and face-mounted gauges.
    cylinder(
        machine,
        machine_root,
        "copper pressure vessel",
        0.52,
        2.28,
        (-2.82, 0.1, 2.15),
        mats["copper"],
        (0, 0, 0),
        96,
        0.065,
    )
    cylinder(
        machine,
        machine_root,
        "vessel lower foot",
        0.58,
        0.18,
        (-2.82, 0.1, 1.04),
        mats["iron"],
        (0, 0, 0),
        96,
        0.035,
    )
    cylinder(
        machine,
        machine_root,
        "vessel domed head",
        0.49,
        0.24,
        (-2.82, 0.1, 3.38),
        mats["brass"],
        (0, 0, 0),
        96,
        0.06,
    )
    for z in (1.31, 2.86):
        torus(
            machine,
            machine_root,
            f"rolled vessel seam {z}",
            0.505,
            0.038,
            (-2.82, 0.1, z),
            mats["brass"],
        )
        for i in range(12):
            angle = math.tau * i / 12
            bolt(
                machine,
                machine_root,
                f"vessel clamp {z}-{i}",
                (-2.82 + 0.535 * math.cos(angle), 0.1 + 0.535 * math.sin(angle), z),
                0.039,
                mats["steel"],
            )

    for index, x in enumerate((-3.25, -2.28)):
        z = 4.02 + index * 0.57
        y = -0.9
        cylinder(
            machine,
            machine_root,
            f"gauge case {index}",
            0.39,
            0.2,
            (x, y, z),
            mats["black"],
            (-math.pi / 2, 0, 0),
            72,
            0.025,
        )
        cylinder(
            machine,
            machine_root,
            f"enamel gauge face {index}",
            0.325,
            0.045,
            (x, y - 0.13, z),
            mats["enamel"],
            (-math.pi / 2, 0, 0),
            72,
            0.015,
        )
        torus(
            machine,
            machine_root,
            f"turned brass gauge bezel {index}",
            0.335,
            0.055,
            (x, y - 0.17, z),
            mats["brass"],
            (-math.pi / 2, 0, 0),
        )
        for tick in range(12):
            angle = math.tau * tick / 12
            tx = x + 0.246 * math.cos(angle)
            tz = z + 0.246 * math.sin(angle)
            marker = cube(
                machine,
                machine_root,
                f"gauge index {index}-{tick}",
                (0.025, 0.018, 0.055),
                (tx, y - 0.164, tz),
                mats["black"],
                0.005,
            )
            marker.rotation_euler.y = -angle
        poly_curve(
            machine,
            machine_root,
            f"gauge needle {index}",
            [(x, y - 0.205, z), (x + 0.12, y - 0.21, z + 0.13)],
            0.016,
            mats["copper"],
            4,
        )
        cylinder(
            machine,
            machine_root,
            f"gauge pivot {index}",
            0.05,
            0.03,
            (x, y - 0.22, z),
            mats["brass"],
            (-math.pi / 2, 0, 0),
            32,
            0.01,
        )
        # Three small case screws and a lower feed fitting make the instrument assembled.
        for screw in range(3):
            a = math.tau * screw / 3 + math.pi / 2
            bolt(
                machine,
                machine_root,
                f"gauge case screw {index}-{screw}",
                (x + 0.345 * math.cos(a), y - 0.19, z + 0.345 * math.sin(a)),
                0.034,
                mats["steel"],
                "y",
            )
        cylinder(
            machine,
            machine_root,
            f"gauge feed nut {index}",
            0.09,
            0.16,
            (x, y, z - 0.45),
            mats["brass"],
            (-math.pi / 2, 0, 0),
            12,
            0.015,
        )

    # Continuous formed copper pipework and compression unions.
    for pipe_index, points in enumerate(
        (
            [(-2.82, -0.7, 3.2), (-2.82, -0.78, 3.65), (-3.25, -0.78, 3.65), (-3.25, -0.88, 3.82)],
            [(-2.82, -0.7, 3.2), (-2.5, -0.74, 3.55), (-2.28, -0.82, 3.55), (-2.28, -0.88, 3.8)],
            [(-2.82, 0.1, 3.38), (-1.9, 0.0, 3.55), (-1.7, 0.0, 3.9), (-1.0, 0.0, 3.9)],
        )
    ):
        poly_curve(
            machine,
            machine_root,
            f"formed copper line {pipe_index}",
            points,
            0.045,
            mats["copper"],
            6,
        )
        for point in (points[0], points[-1]):
            cylinder(
                machine,
                machine_root,
                f"compression union {pipe_index}-{point}",
                0.095,
                0.13,
                point,
                mats["brass"],
                (0, 0, 0),
                12,
                0.015,
            )

    # A small six-spoke operating handwheel and exposed valve stem.
    wheel_center = (-2.0, -1.7, 4.5)
    torus(
        machine,
        machine_root,
        "valve handwheel rim",
        0.39,
        0.045,
        wheel_center,
        mats["brass"],
        (-math.pi / 2, 0, 0),
    )
    for spoke in range(6):
        angle = math.tau * spoke / 6
        rod(
            machine,
            machine_root,
            f"handwheel spoke {spoke}",
            wheel_center,
            (
                wheel_center[0] + 0.37 * math.cos(angle),
                wheel_center[1],
                wheel_center[2] + 0.37 * math.sin(angle),
            ),
            0.027,
            mats["steel"],
            20,
        )
    cylinder(
        machine,
        machine_root,
        "valve stem",
        0.105,
        0.6,
        (-2.0, -1.36, 4.5),
        mats["steel"],
        (-math.pi / 2, 0, 0),
        48,
        0.02,
    )
    cylinder(
        machine,
        machine_root,
        "valve union",
        0.16,
        0.13,
        (-2.0, -1.15, 4.5),
        mats["brass"],
        (-math.pi / 2, 0, 0),
        12,
        0.02,
    )

    # Round-tube launcher mast, fitted collars, diagonal bracing, rungs and top sheave.
    mast_y = -2.48
    for side in (-1, 1):
        x = side * 0.72
        cylinder(
            launcher,
            launcher_root,
            f"mast tube {side}",
            0.115,
            10.1,
            (x, mast_y, 6.57),
            mats["iron"],
            (0, 0, 0),
            48,
            0.025,
        )
        for z in (1.65, 3.2, 4.75, 6.3, 7.85, 9.4, 10.75):
            torus(
                launcher,
                launcher_root,
                f"mast join collar {side}-{z}",
                0.122,
                0.031,
                (x, mast_y, z),
                mats["steel"],
            )
            bolt(
                launcher,
                launcher_root,
                f"collar pin {side}-{z}",
                (x + side * 0.13, mast_y, z),
                0.048,
                mats["brass"],
                "x",
            )
        rod(
            launcher,
            launcher_root,
            f"mast diagonal brace {side}",
            (side * 0.72, mast_y - 0.02, 1.6),
            (0, mast_y - 0.02, 7.8),
            0.055,
            mats["steel"],
        )
    for rung, z in enumerate(
        (1.72, 2.35, 2.98, 3.61, 4.24, 4.87, 5.5, 6.13, 6.76, 7.39, 8.02, 8.65, 9.28, 9.91, 10.54)
    ):
        rod(
            launcher,
            launcher_root,
            f"round ladder rung {rung}",
            (-0.72, mast_y, z),
            (0.72, mast_y, z),
            0.052,
            mats["brass"],
            24,
        )
        for x in (-0.72, 0.72):
            torus(
                launcher,
                launcher_root,
                f"rung ferrule {rung}-{x}",
                0.066,
                0.014,
                (x, mast_y, z),
                mats["steel"],
                (0, math.pi / 2, 0),
            )

    # Forked pulley bracket, grooved sheave, axle, retaining plates and locknuts.
    for side in (-1, 1):
        cube(
            launcher,
            launcher_root,
            f"pulley fork plate {side}",
            (0.18, 0.42, 0.86),
            (side * 0.27, mast_y, 10.98),
            mats["iron"],
            0.055,
        )
        bolt(
            launcher,
            launcher_root,
            f"pulley fork bolt {side}",
            (side * 0.27, mast_y - 0.24, 10.98),
            0.075,
            mats["brass"],
            "y",
        )
    pulley_center = (0, mast_y, 10.98)
    cylinder(
        launcher,
        launcher_root,
        "pulley axle",
        0.105,
        1.02,
        pulley_center,
        mats["steel"],
        (0, math.pi / 2, 0),
        64,
        0.02,
    )
    cylinder(
        launcher,
        launcher_root,
        "grooved pulley sheave",
        0.43,
        0.36,
        pulley_center,
        mats["black"],
        (0, math.pi / 2, 0),
        96,
        0.035,
    )
    torus(
        launcher,
        launcher_root,
        "rope groove lip near",
        0.405,
        0.045,
        (-0.2, mast_y, 10.98),
        mats["steel"],
        (0, math.pi / 2, 0),
    )
    torus(
        launcher,
        launcher_root,
        "rope groove lip far",
        0.405,
        0.045,
        (0.2, mast_y, 10.98),
        mats["steel"],
        (0, math.pi / 2, 0),
    )
    for side in (-1, 1):
        cylinder(
            launcher,
            launcher_root,
            f"pulley axle locknut {side}",
            0.16,
            0.12,
            (side * 0.54, mast_y, 10.98),
            mats["brass"],
            (0, math.pi / 2, 0),
            12,
            0.022,
        )

    # The top housing reaches the brief's measured vertical envelope; no gameplay line is embedded.
    cube(
        launcher,
        launcher_root,
        "mast crown cap",
        (0.42, 0.38, 0.11),
        (0, mast_y, 11.615),
        mats["brass"],
        0.045,
    )
    for group in (
        (foundation, foundation_root),
        (machine, machine_root),
        (launcher, launcher_root),
    ):
        export_group(output / f"{group[1].name}.glb", *group)

    candidate_id = os.environ.get("ROOMSCALE_ART_FACTORY_CANDIDATE", "grapple-v007")
    version_dir = f"v{candidate_id.split('-v')[-1]}"
    scene_path = output / "grapple.tscn"
    scene_resources = []
    scene_nodes = ['[node name="GrappleCandidate" type="Node3D"]']
    for index, group_name in enumerate(
        ("FoundationDetails", "MachineryDetails", "LauncherDetails"), 1
    ):
        scene_resources.append(
            f'[ext_resource type="PackedScene" path="res://art/grapple/iterations/{version_dir}/generated/{group_name}.glb" id="{index}"]'
        )
        scene_nodes.append(f'[node name="{group_name}" parent="." instance=ExtResource("{index}")]')
    scene_text = "\n".join(
        ["[gd_scene load_steps=4 format=3]", "", *scene_resources, "", *scene_nodes, ""]
    )
    scene_path.write_text(scene_text, encoding="utf-8")

    record = {
        "method": "blender_component_level_hard_surface_miniature_grapple",
        "candidate_id": candidate_id,
        "created_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
        "geometry_source": "modeled from the RoomScale grapple brief and strict v006 render diagnosis; no primitive scene fallback",
        "reference_candidate": "grapple-v006",
        "bounds_target_inches": [8.7, 11.67, 7.5],
        "components": ["FoundationDetails", "MachineryDetails", "LauncherDetails"],
        "features": [
            "radiused timber skids and steel shoes",
            "turned winch drum with three-strand helical hemp winding",
            "bevelled twenty-tooth drive gear",
            "pillow blocks and fasteners",
            "seamed copper pressure vessel",
            "two enamel gauges with raised indices and needles",
            "formed pipework and compression unions",
            "round tube mast with collars and braces",
            "round ladder rungs",
            "grooved sheave and axle locknuts",
            "candidate-local baked base-color and roughness microtexture",
            "stage meshes batched by PBR material",
        ],
        "material_variation": "512px packed candidate-local sRGB albedo and non-color roughness textures with subtle tileable procedural variation",
        "mesh_batching": "one exported mesh per unique PBR material within each construction-stage group",
        "gameplay_geometry_changed": False,
        "dynamic_cable_embedded": False,
        "materials": {
            k: {
                "base_color_rgba": list(v.diffuse_color),
                "metallic": v.node_tree.nodes.get("Principled BSDF")
                .inputs["Metallic"]
                .default_value,
                "roughness": v.node_tree.nodes.get("Principled BSDF")
                .inputs["Roughness"]
                .default_value,
            }
            for k, v in mats.items()
        },
    }
    (output / "modeling-record.json").write_text(
        json.dumps(record, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    main(Path(args[0]))
