"""Build a presentation-only, faction-defining Scavenger repair workshop."""

from __future__ import annotations

import json
import math
import os
import random
import sys
from datetime import UTC, datetime
from pathlib import Path

import bpy
from mathutils import Vector


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)


def _rgba(color: tuple[float, float, float], alpha: float = 1.0) -> tuple[float, ...]:
    return (color[0], color[1], color[2], alpha)


def _periodic_wave(u: float, v: float, terms: list[tuple[int, int, float, float]]) -> float:
    return sum(amplitude * math.sin(math.tau * (a * u + b * v) + phase)
               for a, b, amplitude, phase in terms)


def _write_texture(path: Path, pixels: list[float], size: int = 384) -> bpy.types.Image:
    image = bpy.data.images.new(path.stem, width=size, height=size, alpha=False, float_buffer=False)
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    image.pack()
    image.filepath = f"//materials/{path.name}"
    return image


def _texture_family(
    output: Path,
    family: str,
    base: tuple[float, float, float],
    kind: str,
    size: int = 384,
    style_mode: str = "tile_detail",
) -> tuple[bpy.types.Image, bpy.types.Image, bpy.types.Image]:
    """Create seamless color, tangent-normal, and roughness maps for GLB PBR."""
    color_pixels: list[float] = []
    height_values: list[float] = []
    rough_values: list[float] = []
    seed = sum(ord(character) for character in family) * 0.0031
    terms = [
        (2, 3, 0.23, seed),
        (3, 7, 0.15, seed * 1.3),
        (5, 13, 0.09, seed * 1.7),
        (9, 23, 0.045, seed * 2.1),
        (17, 41, 0.023, seed * 2.7),
        (31, 67, 0.012, seed * 3.2),
    ]
    for y in range(size):
        v = y / size
        for x in range(size):
            u = x / size
            low = _periodic_wave(u, v, terms[:3])
            fine = _periodic_wave(u, v, terms[3:])
            micro = _periodic_wave(u, v, [(73, 137, 0.5, seed), (109, 53, 0.5, seed + 2.2)])
            edge = min(u, 1.0 - u, v, 1.0 - v)
            color_override: tuple[float, float, float] | None = None

            if kind == "wood":
                grain = 0.58 * math.sin(math.tau * (v * 34.0 + 0.11 * math.sin(math.tau * (u * 3.0 + seed))))
                knot = math.exp(-(((u - 0.31) / 0.08) ** 2 + ((v - 0.57) / 0.16) ** 2))
                variation = grain * 0.11 + low * 0.085 + fine * 0.035 - knot * 0.14
                height = 0.5 + grain * 0.22 + low * 0.11 - knot * 0.22
                rough = 0.77 + 0.10 * (0.5 + low)
            elif kind == "enamel":
                if style_mode == "broad_scale_patina":
                    field = _periodic_wave(u, v, [(1, 2, 0.42, seed), (2, 5, 0.23, seed + 1.7), (3, 1, 0.14, seed + 3.1)])
                    wear = max(0.0, min(0.68, (field + 0.31 + max(0.0, 0.11 - edge) * 2.8) * 0.78))
                    oxide = (0.35, 0.16, 0.075)
                    color_override = tuple(base[channel] * (1.0 - wear) + oxide[channel] * wear for channel in range(3))
                    variation = 0.011 * fine + 0.006 * micro
                    height = 0.48 + 0.04 * low - 0.09 * wear
                    rough = 0.34 + 0.45 * wear
                else:
                    corrosion = low * 0.95 + fine * 0.52 + micro * 0.22 + (0.07 - edge) * 1.8
                    chips = corrosion > 0.57
                    scratch = abs(math.sin(math.tau * (u * 41.0 + v * 2.0 + seed))) > 0.992 and low < 0.1
                    variation = (0.014 * low + 0.009 * fine) if not chips else (-0.22 + 0.10 * fine)
                    if scratch:
                        variation = -0.13
                    height = 0.48 + (0.09 * low if not chips else -0.14 + 0.03 * fine)
                    rough = 0.32 + (0.38 if chips else 0.0) + 0.05 * abs(fine)
            elif kind == "galvanized":
                if style_mode == "broad_scale_patina":
                    oxidized = max(0.0, min(0.34, (_periodic_wave(u, v, terms[:2]) + 0.05 + max(0.0, 0.04 - edge) * 2.0) * 0.42))
                    dark_metal = (0.19, 0.23, 0.235)
                    color_override = tuple(base[channel] * (1.0 - oxidized) + dark_metal[channel] * oxidized for channel in range(3))
                    variation = 0.018 * fine + 0.008 * micro
                    height = 0.50 + 0.05 * fine + 0.025 * oxidized
                    rough = 0.58 + 0.2 * oxidized
                else:
                    variation = 0.055 * low + 0.028 * fine + 0.012 * micro
                    corrosion = low * 0.8 + fine * 0.4 + (0.035 - edge) * 1.3
                    if corrosion > 0.8:
                        variation -= 0.13
                    height = 0.50 + 0.07 * fine + (0.025 if corrosion > 0.8 else 0.0)
                    rough = 0.56 + 0.08 * abs(low)
            elif kind == "canvas":
                weave = math.sin(math.tau * u * 88.0) * math.sin(math.tau * v * 88.0)
                variation = 0.04 * low + 0.025 * fine + 0.025 * weave
                height = 0.48 + 0.05 * weave + 0.04 * fine
                rough = 0.9
            else:
                variation = 0.035 * low + 0.015 * fine
                height = 0.5 + 0.035 * fine
                rough = 0.7

            if kind in {"enamel", "galvanized"} and ((x * 17 + y * 29 + int(seed * 1000)) % 8191 == 0):
                variation -= 0.12
            color_base = color_override if color_override is not None else base
            color_pixels.extend((
                max(0.0, min(1.0, color_base[0] + variation)),
                max(0.0, min(1.0, color_base[1] + variation)),
                max(0.0, min(1.0, color_base[2] + variation)),
                1.0,
            ))
            height_values.append(height)
            rough_values.append(max(0.0, min(1.0, rough)))

    normal_pixels: list[float] = []
    rough_pixels: list[float] = []
    for y in range(size):
        ym = (y - 1) % size
        yp = (y + 1) % size
        for x in range(size):
            xm = (x - 1) % size
            xp = (x + 1) % size
            center = y * size + x
            dx = (height_values[y * size + xp] - height_values[y * size + xm]) * 3.0
            dy = (height_values[yp * size + x] - height_values[ym * size + x]) * 3.0
            normal = Vector((-dx, -dy, 1.0)).normalized()
            normal_pixels.extend((normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0))
            rough = rough_values[center]
            rough_pixels.extend((rough, rough, rough, 1.0))

    color_image = _write_texture(output / f"{family}_basecolor.png", color_pixels, size)
    normal_image = _write_texture(output / f"{family}_normal.png", normal_pixels, size)
    rough_image = _write_texture(output / f"{family}_roughness.png", rough_pixels, size)
    return color_image, normal_image, rough_image


def _material(
    name: str,
    base: tuple[float, float, float],
    metallic: float,
    roughness: float,
    output: Path,
    family: str = "",
    kind: str = "solid",
    style_mode: str = "tile_detail",
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = _rgba(base)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    principled = nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = _rgba(base)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if family:
        color_image, normal_image, rough_image = _texture_family(output, family, base, kind, style_mode=style_mode)
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = f"{family} color"
        tex.image = color_image
        tex.interpolation = "Linear"
        links.new(tex.outputs["Color"], principled.inputs["Base Color"])
        normal_tex = nodes.new("ShaderNodeTexImage")
        normal_tex.name = f"{family} tangent normal"
        normal_tex.image = normal_image
        normal_tex.image.colorspace_settings.name = "Non-Color"
        normal_map = nodes.new("ShaderNodeNormalMap")
        links.new(normal_tex.outputs["Color"], normal_map.inputs["Color"])
        links.new(normal_map.outputs["Normal"], principled.inputs["Normal"])
        rough_tex = nodes.new("ShaderNodeTexImage")
        rough_tex.name = f"{family} roughness"
        rough_tex.image = rough_image
        rough_tex.image.colorspace_settings.name = "Non-Color"
        links.new(rough_tex.outputs["Color"], principled.inputs["Roughness"])
    return mat


def _adopt(obj: bpy.types.Object, material: bpy.types.Material, bevel_width: float = 0.025) -> bpy.types.Object:
    obj.data.materials.clear()
    obj.data.materials.append(material)
    obj["presentation_only"] = True
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = False
        if bevel_width > 0:
            mod = obj.modifiers.new("worn hand-finished edges", "BEVEL")
            mod.width = bevel_width
            mod.segments = 3
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(28)
            mod.harden_normals = True
            normal = obj.modifiers.new("weighted panel normals", "WEIGHTED_NORMAL")
            normal.keep_sharp = True
            normal.weight = 35
    return obj


def _cube(name: str, dims: tuple[float, float, float], at: tuple[float, float, float], material: bpy.types.Material, bevel: float = 0.04, rotation: tuple[float, float, float] | None = None) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    if rotation is not None:
        obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _adopt(obj, material, bevel)


def _beam(name: str, start: tuple[float, float, float], end: tuple[float, float, float], width: float, depth: float, material: bpy.types.Material, bevel: float = 0.04) -> bpy.types.Object:
    a, b = Vector(start), Vector(end)
    delta = b - a
    obj = _cube(name, (width, depth, delta.length), tuple((a + b) * 0.5), material, bevel)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return obj


def _cylinder(name: str, radius: float, depth: float, at: tuple[float, float, float], material: bpy.types.Material, axis: str = "z", vertices: int = 32, bevel: float = 0.012) -> bpy.types.Object:
    rotation = (0.0, 0.0, 0.0)
    if axis == "y":
        rotation = (math.pi * 0.5, 0.0, 0.0)
    elif axis == "x":
        rotation = (0.0, math.pi * 0.5, 0.0)
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=at, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return _adopt(obj, material, bevel)


def _rod(name: str, start: tuple[float, float, float], end: tuple[float, float, float], radius: float, material: bpy.types.Material) -> bpy.types.Object:
    a, b = Vector(start), Vector(end)
    delta = b - a
    obj = _cylinder(name, radius, delta.length, tuple((a + b) * 0.5), material, "z", 24, radius * 0.18)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return obj


def _torus(name: str, major: float, minor: float, at: tuple[float, float, float], material: bpy.types.Material, axis: str = "y") -> bpy.types.Object:
    rotation = (math.pi * 0.5, 0.0, 0.0) if axis == "y" else (0.0, 0.0, 0.0)
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=24, minor_segments=8, location=at, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return _adopt(obj, material, 0.0)


def _roof_sheet(
    name: str,
    x0: float,
    x1: float,
    front_y: float,
    back_y: float,
    front_z: float,
    back_z: float,
    material: bpy.types.Material,
) -> bpy.types.Object:
    """Corrugated thin-gauge sheet following the single-slope lean-to roof."""
    nx, ny = 42, 12
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, ...]] = []
    for j in range(ny + 1):
        t = j / ny
        y = front_y + (back_y - front_y) * t
        z = front_z + (back_z - front_z) * t
        for i in range(nx + 1):
            u = i / nx
            x = x0 + (x1 - x0) * u
            z_corrugation = 0.115 * math.sin((x - x0) * math.tau / 1.22)
            vertices.append((x, y, z + z_corrugation))
    for j in range(ny):
        for i in range(nx):
            a = j * (nx + 1) + i
            b = a + 1
            c = b + nx + 1
            d = a + nx + 1
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="SalvageRoofUV")
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex_index = mesh.loops[loop_index].vertex_index
            row, column = divmod(vertex_index, nx + 1)
            uv_layer.data[loop_index].uv = (column / nx, row / ny)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    solid = obj.modifiers.new("rolled sheet thickness", "SOLIDIFY")
    solid.thickness = 0.065
    solid.offset = 0.0
    bevel = obj.modifiers.new("soft folded edges", "BEVEL")
    bevel.width = 0.018
    bevel.segments = 2
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    obj["presentation_only"] = True
    return obj


def _join_by_material() -> dict[str, int]:
    counts: dict[str, int] = {}
    materials = list(bpy.data.materials)
    for material in materials:
        objects = [
            obj
            for obj in bpy.context.scene.objects
            if obj.type == "MESH" and any(slot.material == material for slot in obj.material_slots)
        ]
        if not objects:
            continue
        for obj in objects:
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            # Realize only the small component-level bevels before merging; this
            # preserves chamfers while avoiding a second bevel on roof ribbing.
            for modifier in list(obj.modifiers):
                if modifier.type in {"BEVEL", "WEIGHTED_NORMAL", "SOLIDIFY"}:
                    bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        merged = bpy.context.view_layer.objects.active
        merged.name = f"Scavenger_{material.name.replace(' ', '_')}"
        merged["presentation_only"] = True
        counts[material.name] = len(objects)
    return counts


def _build(output: Path) -> tuple[dict[str, int], dict[str, str]]:
    random.seed(20261102)
    recipe_path = os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", "")
    recipe: dict = {}
    if recipe_path and Path(recipe_path).is_file():
        recipe = json.loads(Path(recipe_path).read_text(encoding="utf-8"))
    parameters = recipe.get("parameters", {})
    roof_config = parameters.get("roof", {})
    material_strategy = parameters.get("material_strategy", "tile_detail")
    palette_config = parameters.get("material_palette", {})

    def palette_color(name: str, fallback: tuple[float, float, float]) -> tuple[float, float, float]:
        value = palette_config.get(name, fallback)
        return tuple(float(channel) for channel in value)

    roof_front_y = float(roof_config.get("front_y", -9.75))
    roof_back_y = float(roof_config.get("back_y", 9.45))
    roof_front_z = float(roof_config.get("front_z", 18.55))
    roof_back_z = float(roof_config.get("back_z", 14.5))

    def roof_height(y: float) -> float:
        t = (y - roof_front_y) / (roof_back_y - roof_front_y)
        return roof_front_z + (roof_back_z - roof_front_z) * t

    mats: dict[str, bpy.types.Material] = {}
    mats["timber"] = _material("Reclaimed cedar and drawer wood", (0.30, 0.19, 0.11), 0.0, 0.82, output, "timber", "wood")
    mats["timber_light"] = _material("Sun-faded drawer wood", (0.39, 0.27, 0.16), 0.0, 0.84, output, "timber_light", "wood")
    enamel_style = "broad_scale_patina" if material_strategy == "broad_scale_patina" else "tile_detail"
    mats["enamel_cream"] = _material("Chipped cream appliance enamel", palette_color("enamel_cream", (0.72, 0.67, 0.54)), 0.28, 0.39, output, "enamel_cream", "enamel", enamel_style)
    mats["enamel_teal"] = _material("Chipped blue-green appliance enamel", palette_color("enamel_teal", (0.14, 0.29, 0.32)), 0.30, 0.40, output, "enamel_teal", "enamel", enamel_style)
    mats["enamel_ochre"] = _material("Faded red appliance enamel", palette_color("enamel_ochre", (0.47, 0.20, 0.12)), 0.28, 0.42, output, "enamel_ochre", "enamel", enamel_style)
    mats["sheet"] = _material("Weathered galvanized roofing", palette_color("galvanized", (0.38, 0.43, 0.43)), 0.62, 0.56, output, "galvanized", "galvanized", enamel_style)
    mats["canvas"] = _material("Patched olive canvas", (0.31, 0.34, 0.23), 0.0, 0.92, output, "canvas", "canvas")
    mats["iron"] = _material("Blackened salvaged iron", (0.095, 0.115, 0.12), 0.68, 0.58, output)
    mats["rust"] = _material("Oxide red fastener heads", (0.31, 0.13, 0.075), 0.45, 0.76, output)
    mats["concrete"] = _material("Pitted concrete blocks", (0.28, 0.29, 0.27), 0.02, 0.94, output)

    # Lifted plank deck: open gaps make the assembly read as a repaired platform.
    for index in range(10):
        x = -11.8 + index * 2.62
        depth = 18.0 - (index % 3) * 0.3
        _cube(f"Deck salvage plank {index:02d}", (2.32, depth, 0.38), (x, 0.0, 0.63 + (index % 2) * 0.025), mats["timber" if index % 3 else "timber_light"], 0.075)
    for x in (-10.7, 10.7):
        for y in (-7.2, 7.2):
            _cube("Rough concrete foot", (2.2, 2.0, 1.0), (x, y, 0.54), mats["concrete"], 0.13)
            _cube("Timber sill over foot", (1.2, 1.7, 0.45), (x, y, 1.23), mats["timber_light"], 0.09)

    # Frame and supports: visible knees and brackets carry the off-center canopy.
    front_support_y = roof_front_y + 0.25
    rear_support_y = min(7.6, roof_back_y - 1.0)
    for x in (-11.2, -4.0, 4.0, 11.2):
        for y in (front_support_y, rear_support_y):
            top = roof_height(y) - 0.42
            _beam("Load-bearing reclaimed post", (x, y, 1.0), (x, y, top), 0.7, 0.75, mats["timber"], 0.075)
            _cube("Post shoe angle plate", (0.95, 0.9, 0.26), (x, y, 1.6), mats["iron"], 0.035)
            for dx in (-0.28, 0.28):
                _cylinder("Shoe bolt", 0.11, 0.14, (x + dx, y - 0.39, 1.58), mats["rust"], "y", 16)
    for y in (front_support_y, (front_support_y + rear_support_y) * 0.5, rear_support_y):
        z = roof_height(y) - 0.3
        _beam("Canopy cross bearer", (-11.45, y, z), (11.45, y, z), 0.55, 0.7, mats["timber_light"], 0.06)
    for x in (-10.65, 10.65):
        _beam("Side load brace", (x, front_support_y + 0.2, 8.3), (x, front_support_y + 4.4, roof_height(front_support_y + 4.4) - 0.6), 0.44, 0.48, mats["timber"], 0.055)
        _beam("Rear diagonal brace", (x, rear_support_y - 0.5, 8.0), (x * 0.76, rear_support_y - 5.0, roof_height(rear_support_y - 5.0) - 0.6), 0.42, 0.48, mats["timber_light"], 0.055)
    for x in (-11.0, -4.0, 4.0, 11.0):
        for y in (front_support_y, rear_support_y):
            z = roof_height(y) - 0.28
            _cube("Forged roof bracket", (0.9, 0.34, 0.52), (x, y, z), mats["iron"], 0.035)
            for dx in (-0.23, 0.23):
                _cylinder("Roof bracket rivet", 0.075, 0.1, (x + dx, y - 0.2, z + 0.13), mats["rust"], "y", 16, 0.008)

    # Asymmetric lean-to roof with discrete overlapping sheets and folded seams.
    for index in range(4):
        left, right = -11.7 + index * 5.9, -5.55 + index * 5.9
        material = mats["sheet"] if index in (0, 2) else mats["enamel_teal"]
        _roof_sheet(f"Overlap roof panel {index + 1}", left, right, roof_front_y, roof_back_y, roof_front_z, roof_back_z, material)
    roof_purlin_y = [
        roof_front_y + 0.15,
        roof_front_y + (roof_back_y - roof_front_y) * 0.34,
        roof_front_y + (roof_back_y - roof_front_y) * 0.67,
        roof_back_y - 0.3,
    ]
    for y in roof_purlin_y:
        z = roof_height(y)
        _beam("Roof purlin beneath sheet", (-11.5, y, z - 0.15), (11.5, y, z - 0.15), 0.34, 0.42, mats["timber"], 0.035)
        for x in range(-10, 11, 2):
            _cylinder("Roof seam rivet", 0.055, 0.1, (float(x), y, z + 0.05), mats["iron"], "z", 12, 0.006)
    # A rolled galvanized drip edge makes the overhang end on the front frame.
    _beam("Front rolled drip edge", (-11.8, roof_front_y, roof_front_z), (11.8, roof_front_y, roof_front_z), 0.23, 0.42, mats["sheet"], 0.035)
    for x in (-10.7, 10.7):
        _beam("Rain chain support", (x, roof_front_y, roof_front_z), (x, roof_front_y + 0.4, roof_front_z - 1.75), 0.09, 0.09, mats["iron"], 0.01)

    # Rear work wall uses separate uneven boards and a salvaged pegboard.
    for index in range(17):
        x = -10.0 + index * 1.25
        height = 8.0 + (index % 4) * 0.75
        _cube("Uneven rear wall board", (1.1, 0.32, height), (x, 8.45, 1.0 + height * 0.5), mats["timber" if index % 3 else "timber_light"], 0.055, (0.0, 0.0, (index % 3 - 1) * 0.012))
    _cube("Pegboard made from drawer backs", (13.8, 0.3, 5.1), (1.2, 8.15, 8.65), mats["timber_light"], 0.055)
    for z in (6.2, 7.0, 11.1):
        _cube("Back wall tool rail", (13.2, 0.26, 0.18), (1.2, 7.82, z), mats["iron"], 0.035)
    for x, width, depth, z in ((-6.7, 4.5, 1.55, 9.8), (7.0, 4.4, 1.55, 9.5), (-5.8, 3.2, 1.2, 6.0)):
        _cube("Reused kitchen shelf", (width, depth, 0.42), (x, 6.7, z), mats["timber_light"], 0.07)
        for support in (-width * 0.42, width * 0.42):
            _beam("Shelf angle support", (x + support, 7.25, z - 0.18), (x + support, 6.55, z - 1.05), 0.11, 0.12, mats["iron"], 0.015)

    # Salvaged appliance fronts define the faction silhouette at the open face.
    _cube("Ivory refrigerator door surround", (4.7, 0.66, 10.1), (-8.15, -8.95, 6.05), mats["iron"], 0.16)
    _cube("Cream appliance door face", (4.28, 0.28, 9.68), (-8.15, -9.32, 6.05), mats["enamel_cream"], 0.22)
    _cube("Lower refrigerator service panel", (4.15, 0.18, 1.28), (-8.15, -9.48, 1.15), mats["enamel_teal"], 0.09)
    for x in (-9.45, -6.85):
        _cylinder("Appliance hinge barrel", 0.12, 0.76, (x, -9.54, 6.2), mats["iron"], "z", 24)
        for z in (4.2, 8.2):
            _cylinder("Appliance hinge screw", 0.075, 0.12, (x, -9.53, z), mats["rust"], "y", 16, 0.006)
    for z in (3.6, 8.4):
        _rod("Bent tubular pull handle", (-9.65, -9.79, z), (-9.65, -9.79, z + 1.0), 0.12, mats["iron"])
        for dz in (0.08, 0.92):
            _cylinder("Handle escutcheon", 0.19, 0.13, (-9.65, -9.67, z + dz), mats["enamel_ochre"], "y", 24)
    # Louvered lower vent on the cream door is immediately readable in close view.
    for row in range(5):
        _beam("Appliance vent louver", (-9.38, -9.54, 1.15 + row * 0.23), (-6.92, -9.54, 1.15 + row * 0.23), 0.08, 0.13, mats["iron"], 0.018)
    _cube("Blue enamel side locker surround", (3.7, 0.68, 8.1), (10.65, -5.4, 5.2), mats["iron"], 0.17)
    _cube("Blue enamel side locker", (3.35, 0.3, 7.72), (10.65, -5.8, 5.2), mats["enamel_teal"], 0.20)
    _cube("Red enamel locker patch", (1.25, 0.17, 2.15), (11.25, -5.98, 4.1), mats["enamel_ochre"], 0.11, (0.0, 0.0, 0.07))
    _cylinder("Locker latch", 0.13, 0.16, (10.2, -6.0, 5.3), mats["iron"], "y", 24)
    for z in range(2, 9, 2):
        _cube("Locker repair strap", (3.4, 0.12, 0.16), (10.65, -6.0, float(z)), mats["iron"], 0.025)

    # Open-front repair bench and recognizably reused drawer carcass.
    _cube("Heavy scarred bench top", (12.5, 3.5, 0.72), (1.5, -3.15, 6.2), mats["timber_light"], 0.14)
    for x in (-3.7, 6.7):
        _beam("Bench trestle leg", (x, -4.1, 1.2), (x, -4.1, 5.9), 0.48, 0.54, mats["timber"], 0.055)
        _beam("Bench rear leg", (x, -2.05, 1.2), (x, -2.05, 5.9), 0.44, 0.48, mats["timber"], 0.05)
        _beam("Bench side stretcher", (x, -4.05, 2.1), (x, -2.08, 2.1), 0.25, 0.32, mats["timber_light"], 0.03)
    _cube("Tool drawer cabinet carcass", (3.8, 2.2, 5.0), (-5.6, -2.8, 3.55), mats["timber"], 0.10)
    for row in range(4):
        z = 1.55 + row * 1.12
        face_material = mats["enamel_teal"] if row % 2 else mats["enamel_cream"]
        _cube("Mismatched enamel drawer front", (3.55, 0.22, 0.91), (-5.6, -4.0, z), face_material, 0.08, (0.0, 0.0, (row % 2 - 0.5) * 0.018))
        _cube("Drawer pull back plate", (0.85, 0.1, 0.28), (-5.6, -4.16, z), mats["iron"], 0.04)
        _rod("Drawer pull", (-5.92, -4.3, z), (-5.28, -4.3, z), 0.07, mats["rust"])
    _cube("Small red parts drawer", (2.8, 1.6, 2.3), (3.1, -2.4, 2.4), mats["enamel_ochre"], 0.09)
    for z in (1.8, 2.45, 3.0):
        _cube("Parts drawer seam", (2.65, 0.12, 0.08), (3.1, -3.23, z), mats["iron"], 0.02)

    # Bench vise, used tins, tool silhouettes, and mismatched practical kit.
    _cube("Vise cast base", (1.65, 1.15, 0.45), (-1.4, -3.0, 6.78), mats["iron"], 0.09)
    _cube("Vise fixed jaw", (1.2, 0.6, 0.48), (-1.4, -3.35, 7.25), mats["rust"], 0.10)
    _cube("Vise sliding jaw", (1.05, 0.58, 0.38), (-0.2, -3.35, 7.20), mats["iron"], 0.08)
    _rod("Vise lead screw", (-1.4, -3.75, 6.92), (0.65, -3.75, 6.92), 0.09, mats["iron"])
    for i, (x, y, z, radius, height) in enumerate(((-8.4, 6.1, 10.7, 0.45, 1.0), (-5.2, 6.1, 10.6, 0.55, 1.2), (8.2, 6.1, 10.4, 0.52, 1.05), (5.9, 6.2, 7.1, 0.36, 0.8))):
        _cylinder(f"Household parts tin {i}", radius, height, (x, y, z), mats["enamel_teal" if i % 2 else "enamel_ochre"], "z", 40, 0.03)
        _cylinder(f"Tin rim {i}", radius * 1.04, 0.1, (x, y, z + height * 0.5), mats["iron"], "z", 40, 0.012)
    # Hanging wrenches: ring heads plus long, slightly angled shafts.
    for index, x in enumerate((-2.0, 0.2, 2.1, 4.4, 6.5)):
        z = 8.2 + (index % 2) * 0.3
        _rod("Hanging wrench shaft", (x, 7.55, z - 1.25), (x + 0.12, 7.55, z + 0.48), 0.09, mats["iron"])
        _torus("Wrench ring jaw", 0.27, 0.075, (x + 0.12, 7.55, z + 0.62), mats["iron"], "y")
        _cylinder("Peg hook", 0.07, 0.35, (x, 7.38, z + 0.55), mats["rust"], "y", 16, 0.008)
    for index, x in enumerate((-7.2, -5.7, 5.3, 7.1)):
        _cube("Small tool box", (1.2, 0.8, 0.9), (x, 6.2, 11.2 + (index % 2) * 0.2), mats["enamel_ochre" if index % 2 else "enamel_teal"], 0.10)
        _cube("Toolbox lid seam", (1.22, 0.83, 0.08), (x, 6.2, 11.7 + (index % 2) * 0.2), mats["iron"], 0.025)

    # Wire parts basket and stacked scrap lean against the side of the bench.
    basket_x, basket_y, basket_z = 8.8, 0.3, 2.2
    for xsign in (-1, 1):
        for ysign in (-1, 1):
            _rod("Wire basket upright", (basket_x + xsign * 1.25, basket_y + ysign * 0.78, basket_z), (basket_x + xsign * 1.0, basket_y + ysign * 0.65, basket_z + 3.1), 0.065, mats["iron"])
    for z in (0.55, 1.1, 1.8, 2.45, 3.0):
        scale = 1.0 - max(0.0, z - 1.0) * 0.10
        for ysign in (-1, 1):
            _rod("Wire basket weave", (basket_x - 1.2 * scale, basket_y + ysign * 0.7 * scale, basket_z + z), (basket_x + 1.2 * scale, basket_y + ysign * 0.7 * scale, basket_z + z), 0.045, mats["iron"])
        for xsign in (-1, 1):
            _rod("Wire basket weave", (basket_x + xsign * 1.2 * scale, basket_y - 0.7 * scale, basket_z + z), (basket_x + xsign * 1.2 * scale, basket_y + 0.7 * scale, basket_z + z), 0.045, mats["iron"])
    for index, x in enumerate((7.2, 9.4, 11.4)):
        _cube("Leaned reclaimed side board", (0.42, 0.55, 7.0 - index * 0.45), (x, 3.8, 4.1), mats["timber_light" if index == 1 else "timber"], 0.055, (0.0, (index - 1) * 0.08, 0.0))

    # Patched canvas fly sheet on the quieter left rear corner.
    _cube("Canvas side patch", (4.2, 0.22, 3.9), (-10.75, 3.8, 11.5), mats["canvas"], 0.12, (0.0, 0.0, -0.04))
    for index in range(5):
        _cube("Canvas patch seam", (0.12, 0.12, 3.75), (-12.45 + index * 0.82, 3.65, 11.5), mats["timber_light"], 0.025)
    for index in range(8):
        x = -12.3 + index * 0.72
        _cylinder("Canvas eyelet", 0.085, 0.08, (x, 3.61, 9.72), mats["iron"], "y", 16, 0.006)
    _beam("Canvas tie cord", (-12.2, 3.48, 9.55), (-5.2, 3.48, 9.55), 0.08, 0.08, mats["rust"], 0.008)

    # A few fasteners in high-contrast clusters make the salvaged joins legible.
    for x in (-11.2, 11.2, -4.0, 4.0):
        for z in (3.0, 7.0, 11.0):
            _cylinder("Post through-bolt", 0.09, 0.18, (x, -8.62, z), mats["rust"], "y", 16, 0.008)
            _cylinder("Bolt washer", 0.17, 0.055, (x, -8.7, z), mats["iron"], "y", 24, 0.006)

    object_counts = _join_by_material()
    # Clear leftover empties or non-rendering helpers; only the merged visual
    # meshes are exported. There are no collision or gameplay nodes in the GLB.
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    return object_counts, {name: mat.name for name, mat in mats.items()}


def main(project_root: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    (output / "materials").mkdir(parents=True, exist_ok=True)
    _clear_scene()
    object_counts, material_names = _build(output / "materials")
    recipe_path = os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", "")
    recipe: dict = {}
    if recipe_path and Path(recipe_path).is_file():
        recipe = json.loads(Path(recipe_path).read_text(encoding="utf-8"))
    roof_config = recipe.get("parameters", {}).get("roof", {})
    glb = output / "scavenger_workshop.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(glb),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
        export_cameras=False,
        export_lights=False,
    )
    record = {
        "asset_id": "scavenger_workshop",
        "method": "blender_household_salvage_repair_workshop",
        "visual_director_target": "art/scavenger_workshop/visual_director/round-01/approved-target-r01.png",
        "approved_target_sha256": "195305d30975089a5658c794b537f4b946601a5ec0223fa129c06c2a39582547",
        "envelope_inches": [26.0, 20.0, 20.0],
        "roof_profile_blender_xzy": {
            "front_y": float(roof_config.get("front_y", -9.75)),
            "back_y": float(roof_config.get("back_y", 9.45)),
            "front_height": float(roof_config.get("front_z", 18.55)),
            "back_height": float(roof_config.get("back_z", 14.5)),
        },
        "source_component_count_by_material": object_counts,
        "joined_drawable_count": len(object_counts),
        "material_names": material_names,
        "material_texture_families": ["timber", "timber_light", "enamel_cream", "enamel_teal", "enamel_ochre", "galvanized", "canvas"],
        "geometry_features": [
            "asymmetric single-slope corrugated lean-to roof",
            "visible timber posts, diagonal knees, purlins, and bolted angle shoes",
            "open work face with a chipped cream appliance door and blue side locker",
            "reclaimed drawer workbench, vise, household tins, tool wall, and wire basket",
            "uneven rear wall planks, galvanized patch panels, and stitched canvas patch",
        ],
        "gameplay_changes": False,
        "output": glb.name,
        "generated_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
    }
    (output / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"SCAVENGER_WORKSHOP_GENERATED {glb} meshes={len(object_counts)} objects={sum(object_counts.values())}")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(args) != 2:
        raise SystemExit("usage: blender --background --python scavenger_workshop_blender.py -- PROJECT_ROOT OUTPUT_DIR")
    main(Path(args[0]), Path(args[1]))
