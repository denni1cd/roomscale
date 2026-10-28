"""Generate a rigged, fitted-clothing Citizen using MPFB2 and CC0 MakeHuman assets."""

from __future__ import annotations

import hashlib
import importlib
import json
import math
import shutil
import sys
from datetime import UTC, datetime
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def _install_mpfb(project_root: Path):
    user_data = project_root / ".tools/mpfb-user-data"
    extension_repo = project_root / ".tools/mpfb-extension-repo"
    user_data.mkdir(parents=True, exist_ok=True)
    original_extension_path_user = bpy.utils.extension_path_user

    def extension_path_user(package: str, **kwargs):
        if package.endswith(".mpfb"):
            target = user_data / kwargs.get("path", "")
            if kwargs.get("create"):
                target.mkdir(parents=True, exist_ok=True)
            return str(target)
        return original_extension_path_user(package, **kwargs)

    bpy.utils.extension_path_user = extension_path_user
    bpy.ops.preferences.extension_repo_add(
        name="MPFB Local",
        remote_url="",
        use_custom_directory=True,
        custom_directory=str(extension_repo),
        type="LOCAL",
    )
    repo = bpy.context.preferences.extensions.repos[-1]
    package = importlib.import_module(f"bl_ext.{repo.module}.mpfb")
    asset_root = project_root / ".tools/makehuman_system_assets-data"

    def preference(name: str):
        return {
            "mpfb_user_data": str(user_data),
            "mpfb_second_root": str(asset_root),
            "mpfb_shelf_label": "RoomScale Art Factory",
            "mh_user_data": "",
            "mh_auto_user_data": False,
        }.get(name)

    package.get_preference = preference
    package.register()
    return package, importlib.import_module(f"bl_ext.{repo.module}.mpfb.services.humanservice").HumanService


def _image(path: Path, *, non_color: bool = False):
    image = bpy.data.images.load(str(path), check_existing=True)
    if non_color:
        image.colorspace_settings.name = "Non-Color"
    return image


def _save_map(path: Path, pixels: np.ndarray) -> Path:
    height, width, channels = pixels.shape
    image = bpy.data.images.new(path.stem, width=width, height=height, alpha=channels == 4, float_buffer=False)
    image.pixels.foreach_set(np.asarray(pixels, dtype=np.float32).ravel())
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    return path


def _derive_worksuit_pbr_maps(project_root: Path, output_dir: Path) -> tuple[Path, Path]:
    """Use the CC0 coverall normal map and a restrained fabric roughness map."""
    worksuit_dir = project_root / ".tools/makehuman_system_assets-data/clothes/male_worksuit01"
    normal_path = output_dir / "materials/workcoat_normal.png"
    normal_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(worksuit_dir / "male_worksuit01_normal.png", normal_path)

    diffuse = _image(worksuit_dir / "male_worksuit01_diffuse.png")
    width, height = (int(v) for v in diffuse.size)
    rgb = np.asarray(diffuse.pixels[:], dtype=np.float32).reshape(height, width, 4)[..., :3]
    luma = rgb[..., 0] * 0.25 + rgb[..., 1] * 0.60 + rgb[..., 2] * 0.15
    rough_value = np.clip(0.82 - (luma - 0.35) * 0.10, 0.72, 0.91)
    roughness = np.repeat(rough_value[..., None], 3, axis=2)
    roughness = np.concatenate((roughness, np.ones((*roughness.shape[:2], 1), dtype=np.float32)), axis=-1)
    roughness_path = output_dir / "materials/workcoat_roughness.png"
    _save_map(roughness_path, roughness)
    diffuse.pack()
    return normal_path, roughness_path


def _make_workwear_maps(output_dir: Path) -> dict[str, Path]:
    """Write deterministic, modest-scale leather/canvas PBR maps for the authored garments."""
    output = output_dir / "materials"
    output.mkdir(parents=True, exist_ok=True)
    height = width = 512
    rng = np.random.default_rng(58031)
    coarse = np.repeat(np.repeat(rng.normal(0.0, 0.035, (32, 32)), 16, axis=0), 16, axis=1)
    fine = rng.normal(0.0, 0.012, (height, width))
    fiber = (np.sin(np.arange(height, dtype=np.float32)[:, None] * 0.47) * 0.004)
    grain = coarse + fine + fiber
    paths: dict[str, Path] = {}
    for name, base in (("apron", (0.52, 0.34, 0.145)), ("leather", (0.105, 0.052, 0.026)), ("helmet", (0.25, 0.105, 0.036)), ("coverall", (0.024, 0.105, 0.135))):
        color = np.empty((height, width, 4), dtype=np.float32)
        for channel, component in enumerate(base):
            color[..., channel] = np.clip(component + grain * (0.7 + component), 0.0, 1.0)
        color[..., 3] = 1.0
        albedo_path = output / f"workwear_{name}_albedo.png"
        _save_map(albedo_path, color)
        paths[f"{name}_albedo"] = albedo_path

        roughness = np.empty((height, width, 4), dtype=np.float32)
        rough_value = np.clip((0.76 if name != "helmet" else 0.68) + coarse * 0.5 + fine * 0.2, 0.42, 0.96)
        roughness[..., :3] = rough_value[..., None]
        roughness[..., 3] = 1.0
        roughness_path = output / f"workwear_{name}_roughness.png"
        _save_map(roughness_path, roughness)
        paths[f"{name}_roughness"] = roughness_path

        normal = np.empty((height, width, 4), dtype=np.float32)
        gy, gx = np.gradient(grain)
        normal[..., 0] = np.clip(0.5 - gx * 1.4, 0.0, 1.0)
        normal[..., 1] = np.clip(0.5 - gy * 1.4, 0.0, 1.0)
        normal[..., 2] = 0.995
        normal[..., 3] = 1.0
        normal_path = output / f"workwear_{name}_normal.png"
        _save_map(normal_path, normal)
        paths[f"{name}_normal"] = normal_path
    return paths


def _derive_clockwork_workcoat(project_root: Path, output_dir: Path) -> Path:
    """Recolor the fitted CC0 denim coveralls to durable Clockwork teal."""
    source_path = project_root / ".tools/makehuman_system_assets-data/clothes/male_worksuit01/male_worksuit01_diffuse.png"
    source = _image(source_path)
    width, height = (int(value) for value in source.size)
    pixels = np.asarray(source.pixels[:], dtype=np.float32).reshape(height, width, 4).copy()
    rgb = pixels[..., :3]
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    target = rgb.copy()
    denim_mask = (blue > red * 1.16) & (blue > green * 1.08) & (blue > 0.12)
    denim_luma = np.clip((red * 0.25 + green * 0.60 + blue * 0.15) / 0.27, 0.46, 1.24)
    target[denim_mask] = np.stack((0.024 * denim_luma[denim_mask], 0.105 * denim_luma[denim_mask], 0.135 * denim_luma[denim_mask]), axis=-1)
    shirt_mask = (np.min(rgb, axis=-1) > 0.48) & ((np.max(rgb, axis=-1) - np.min(rgb, axis=-1)) < 0.16)
    shirt_value = np.clip((rgb[..., 0] * 0.25 + rgb[..., 1] * 0.60 + rgb[..., 2] * 0.15) / 0.80, 0.72, 1.12)
    target[shirt_mask] = np.stack((0.035 * shirt_value[shirt_mask], 0.145 * shirt_value[shirt_mask], 0.165 * shirt_value[shirt_mask]), axis=-1)
    pixels[..., :3] = target
    pixels[..., 3] = 1.0
    output = output_dir / "materials/workcoat_albedo.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    _save_map(output, pixels)
    source.pack()
    return output


def _pbr_material(name: str, albedo: Path, roughness: float, metallic: float = 0.0,
                   normal: Path | None = None, roughness_map: Path | None = None):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (0.25, 0.22, 0.18, 1.0)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    material.node_tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    color_node = nodes.new("ShaderNodeTexImage")
    color_node.image = _image(albedo)
    material.node_tree.links.new(color_node.outputs["Color"], shader.inputs["Base Color"])
    if roughness_map is not None and roughness_map.is_file():
        roughness_node = nodes.new("ShaderNodeTexImage")
        roughness_node.image = _image(roughness_map, non_color=True)
        material.node_tree.links.new(roughness_node.outputs["Color"], shader.inputs["Roughness"])
    if normal is not None and normal.is_file():
        normal_node = nodes.new("ShaderNodeTexImage")
        normal_node.image = _image(normal, non_color=True)
        normal_map = nodes.new("ShaderNodeNormalMap")
        material.node_tree.links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
        material.node_tree.links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
    return material


def _assign_material(obj, material) -> None:
    if obj.type != "MESH":
        return
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.material_index = 0
        polygon.use_smooth = True


def _attach_to_bone(obj, rig, bone_weights: dict[str, float]) -> None:
    world = obj.matrix_world.copy()
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.matrix_world = world
    armature = obj.modifiers.new("MPFB fitted accessory skin", "ARMATURE")
    armature.object = rig
    vertices = list(range(len(obj.data.vertices)))
    for bone_name, weight in bone_weights.items():
        if weight <= 0:
            continue
        group = obj.vertex_groups.new(name=bone_name)
        group.add(vertices, weight, "REPLACE")


def _attach_to_head(obj, rig) -> None:
    _attach_to_bone(obj, rig, {"head": 1.0})


def _attach_to_reference_skin(obj, rig, reference, fallback: str = "spine_03") -> None:
    """Copy each accessory vertex's nearest fitted-surface skin weights."""
    world = obj.matrix_world.copy()
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.matrix_world = world
    armature = obj.modifiers.new("MPFB reference fitted skin", "ARMATURE")
    armature.object = rig

    reference_world = [reference.matrix_world @ vertex.co for vertex in reference.data.vertices]
    tree = KDTree(len(reference_world))
    for index, point in enumerate(reference_world):
        tree.insert(point, index)
    tree.balance()
    source_weights = []
    for vertex in reference.data.vertices:
        source_weights.append([
            (reference.vertex_groups[group.group].name, group.weight)
            for group in vertex.groups
        ])
    groups = {}
    for vertex in obj.data.vertices:
        point = obj.matrix_world @ vertex.co
        _nearest_point, source_index, _distance = tree.find(point)
        weights = source_weights[source_index]
        if not weights:
            if fallback == "foot":
                bone = "foot_l" if point.x < 0 else "foot_r"
            else:
                bone = fallback
            weights = [(bone, 1.0)]
        for bone_name, weight in weights:
            group = groups.get(bone_name)
            if group is None:
                group = obj.vertex_groups.new(name=bone_name)
                groups[bone_name] = group
            group.add([vertex.index], weight, "REPLACE")


def _join_reference_skinned(objects, rig, reference, name: str, fallback: str = "spine_03"):
    if not objects:
        raise RuntimeError(f"No geometry was generated for {name}")
    for obj in objects:
        for modifier in list(obj.modifiers):
            if modifier.type != "ARMATURE":
                bpy.context.view_layer.objects.active = obj
                obj.select_set(True)
                bpy.ops.object.modifier_apply(modifier=modifier.name)
                obj.select_set(False)
        if not any(modifier.type == "ARMATURE" and modifier.object == rig for modifier in obj.modifiers):
            _attach_to_reference_skin(obj, rig, reference, fallback)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    combined = bpy.context.view_layer.objects.active
    combined.name = name
    return combined


def _mesh_object(name, vertices, faces, material, *, smooth=False):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    uv_layer = mesh.uv_layers.new(name="RoomScale_Projected_Garment_UV")
    xs = [vertex[0] for vertex in vertices]
    zs = [vertex[2] for vertex in vertices]
    x_span = max(max(xs) - min(xs), 1e-6)
    z_span = max(max(zs) - min(zs), 1e-6)
    for loop in mesh.loops:
        x, _y, z = vertices[loop.vertex_index]
        uv_layer.data[loop.index].uv = ((x - min(xs)) / x_span, (z - min(zs)) / z_span)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if smooth:
        for polygon in mesh.polygons:
            polygon.use_smooth = True
    return obj


def _tube_surface(name, centers, radii, material, segments=24):
    """Create an open-ended fitted sleeve/cuff tube through a 3D centerline."""
    centers = [Vector(center) for center in centers]
    vertices = []
    for ring_index, center in enumerate(centers):
        tangent = (centers[min(ring_index + 1, len(centers) - 1)] - centers[max(ring_index - 1, 0)]).normalized()
        reference = Vector((0.0, 0.0, 1.0))
        if abs(tangent.dot(reference)) > 0.92:
            reference = Vector((0.0, 1.0, 0.0))
        axis_x = tangent.cross(reference).normalized()
        axis_y = tangent.cross(axis_x).normalized()
        radius = radii[ring_index]
        for segment in range(segments):
            angle = segment * 2.0 * math.pi / segments
            offset = axis_x * (math.cos(angle) * radius) + axis_y * (math.sin(angle) * radius)
            vertices.append(tuple(center + offset))
    faces = []
    for ring in range(len(centers) - 1):
        for segment in range(segments):
            following = (segment + 1) % segments
            a = ring * segments + segment
            b = ring * segments + following
            c = (ring + 1) * segments + following
            d = (ring + 1) * segments + segment
            faces.append((a, b, c, d))
    return _mesh_object(name, vertices, faces, material, smooth=True)


def _weighted_bone_radius(mesh, rig, bone_name: str, start: Vector, end: Vector, fallback: float) -> float:
    group = next((group for group in mesh.vertex_groups if group.name == bone_name), None)
    if group is None:
        return fallback
    segment = end - start
    if segment.length <= 1e-6:
        return fallback
    direction = segment.normalized()
    distances = []
    for vertex in mesh.data.vertices:
        if not any(influence.group == group.index and influence.weight >= 0.15 for influence in vertex.groups):
            continue
        point = mesh.matrix_world @ vertex.co
        along = (point - start).dot(direction) / segment.length
        if 0.18 <= along <= 0.82:
            closest = start + direction * (along * segment.length)
            distances.append((point - closest).length)
    if len(distances) < 12:
        return fallback
    return max(fallback * 0.82, float(np.percentile(distances, 88))) + 0.003


def _add_fitted_work_sleeves(rig, human, coverall_material, leather_material):
    objects = []
    bpy.context.view_layer.update()
    for side in ("l", "r"):
        upper = rig.data.bones.get(f"upperarm_{side}")
        lower = rig.data.bones.get(f"lowerarm_{side}")
        if upper is None or lower is None:
            raise RuntimeError(f"MPFB game_engine rig is missing the {side} arm chain")
        shoulder = rig.matrix_world @ upper.head_local
        elbow = rig.matrix_world @ upper.tail_local
        wrist = rig.matrix_world @ lower.tail_local
        upper_radius = _weighted_bone_radius(human, rig, upper.name, shoulder, elbow, 0.044)
        lower_radius = _weighted_bone_radius(human, rig, lower.name, elbow, wrist, 0.034)
        centers = [
            shoulder.lerp(elbow, 0.06),
            shoulder.lerp(elbow, 0.52),
            elbow,
            elbow.lerp(wrist, 0.46),
            elbow.lerp(wrist, 0.88),
        ]
        radii = [upper_radius * 1.12, upper_radius * 1.10, max(upper_radius, lower_radius) * 1.10, lower_radius * 1.12, lower_radius * 1.06]
        sleeve = _tube_surface(f"RoomScale.ClockworkWorkSleeve_{side}", centers, radii, coverall_material, 24)
        _attach_to_reference_skin(sleeve, rig, human, upper.name)
        objects.append(sleeve)
        cuff_centers = [elbow.lerp(wrist, 0.78), elbow.lerp(wrist, 0.91)]
        cuff_radius = lower_radius * 1.16
        cuff = _tube_surface(f"RoomScale.ReinforcedWorkCuff_{side}", cuff_centers, [cuff_radius, cuff_radius], leather_material, 24)
        _attach_to_reference_skin(cuff, rig, human, lower.name)
        objects.append(cuff)
    return objects


def _elliptical_band(name, center, outer_rx, outer_ry, inner_rx, inner_ry, z_height, material, segments=32):
    cx, cy, cz = center
    vertices = []
    for z in (cz - z_height * 0.5, cz + z_height * 0.5):
        for rx, ry in ((outer_rx, outer_ry), (inner_rx, inner_ry)):
            for i in range(segments):
                angle = (2.0 * math.pi * i) / segments
                vertices.append((cx + math.cos(angle) * rx, cy + math.sin(angle) * ry, z))
    faces = []
    base = segments * 4
    for i in range(segments):
        j = (i + 1) % segments
        # Top, bottom, outer wall, inner wall.
        faces.append((2 * segments + i, 2 * segments + j, 3 * segments + j, 3 * segments + i))
        faces.append((i, segments + i, segments + j, j))
        faces.append((i, j, 2 * segments + j, 2 * segments + i))
        faces.append((segments + i, 3 * segments + i, 3 * segments + j, segments + j))
    return _mesh_object(name, vertices, faces, material, smooth=True)


def _rounded_box(name, location, dimensions, material, bevel):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel > 0:
        modifier = obj.modifiers.new("Soft manufactured edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.profile = 0.5
        obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def _cylinder_between(name, start, end, radius, material, vertices=32, bevel=0.0):
    start, end = Vector(start), Vector(end)
    delta = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(delta.normalized())
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    if bevel > 0:
        modifier = obj.modifiers.new("Machined end radii", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def _add_gear_on_x(name, center, radius, thickness, material, teeth=16):
    cx, cy, cz = center
    outline = []
    for tooth in range(teeth):
        for step, radial in enumerate((0.84, 0.84, 1.0, 1.0)):
            angle = (tooth + step / 4.0) * (2.0 * math.pi / teeth)
            outline.append((math.sin(angle) * radius * radial, math.cos(angle) * radius * radial))
    count = len(outline)
    vertices = []
    for x in (cx - thickness * 0.5, cx + thickness * 0.5):
        vertices.extend((x, cy + dy, cz + dz) for dy, dz in outline)
    faces = [tuple(range(count)), tuple(range(count, count * 2))]
    for i in range(count):
        j = (i + 1) % count
        faces.append((i, j, j + count, i + count))
    gear = _mesh_object(name, vertices, faces, material)
    bevel = gear.modifiers.new("Machined gear edge", "BEVEL")
    bevel.width = radius * 0.035
    bevel.segments = 2
    gear.modifiers.new("Gear face normals", "WEIGHTED_NORMAL")
    return gear


def _ellipsoid(name, center, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def _polyline_tube(name, points, radius, material):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 8
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coordinate in zip(spline.points, points):
        point.co = (*coordinate, 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def _formed_helmet_shell(center_y, top_z, material):
    """Build a smooth formed shell from cross-sections, with no hat brim."""
    segments = 32
    # A broader pressure-operator shell gives the head a protective silhouette
    # at half-inch scale. The crown rises above the MPFB scalp and carries the
    # visor/optics as face protection rather than cap decoration.
    profile = [
        (-0.073, 0.078, 0.088), (-0.052, 0.101, 0.108),
        (-0.021, 0.116, 0.121), (0.016, 0.120, 0.120),
        (0.056, 0.109, 0.107), (0.093, 0.087, 0.083),
        (0.124, 0.057, 0.056), (0.142, 0.025, 0.027),
        (0.146, 0.006, 0.008),
    ]
    vertices = []
    for z_offset, radius_x, radius_y in profile:
        for segment in range(segments):
            angle = segment * 2.0 * math.pi / segments
            vertices.append((math.cos(angle) * radius_x, center_y + math.sin(angle) * radius_y, top_z + z_offset))
    faces = []
    for ring in range(len(profile) - 1):
        for segment in range(segments):
            following = (segment + 1) % segments
            a = ring * segments + segment
            b = ring * segments + following
            c = (ring + 1) * segments + following
            d = (ring + 1) * segments + segment
            faces.append((a, b, c, d))
    faces.append(tuple(reversed(range(segments))))
    faces.append(tuple(range((len(profile) - 1) * segments, len(profile) * segments)))
    return _mesh_object("RoomScale.MachinistHelmetShell", vertices, faces, material, smooth=True)


def _add_clockwork_helmet_and_goggles(rig, fedora, glasses, leather, brass, gunmetal, glass):
    """Replace generic fedora/glasses with a fitted machinist helmet and sealed twin lenses."""
    head = next((obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj.name == "Human"), None)
    if head is None:
        raise RuntimeError("MPFB head mesh is missing")
    head_world = [head.matrix_world @ vertex.co for vertex in head.data.vertices]
    top_z = max(point.z for point in head_world)
    center_y = (min(point.y for point in head_world) + max(point.y for point in head_world)) * 0.5
    helmet_objects = []

    # The ring-section shell has a reinforced lower edge, raised dome,
    # protective temple plates, and a short front visor, with no brim.
    # A dark formed metal shell separates the manufactured helmet from hair,
    # leather straps, and the brown canvas apron at every capture distance.
    helmet_objects.append(_formed_helmet_shell(center_y, top_z, gunmetal))
    helmet_objects.append(_elliptical_band(
        "RoomScale.HelmetCrownBinding", (0.0, center_y + 0.005, top_z - 0.050),
        0.128, 0.130, 0.119, 0.121, 0.016, brass,
    ))
    helmet_objects.append(_rounded_box(
        "RoomScale.HelmetTopRidge", (0.0, center_y + 0.004, top_z + 0.121),
        (0.046, 0.218, 0.030), brass, 0.010,
    ))
    for side in (-1, 1):
        helmet_objects.append(_rounded_box(
            f"RoomScale.HelmetTemplePlate_{side}",
            (side * 0.086, center_y + 0.006, top_z - 0.048),
            (0.052, 0.150, 0.130), gunmetal, 0.016,
        ))
        helmet_objects.append(_ellipsoid(
            f"RoomScale.HelmetTempleRivet_{side}",
            (side * 0.092, center_y - 0.010, top_z - 0.044),
            (0.009, 0.005, 0.009), brass,
        ))
    helmet_objects.append(_rounded_box(
        "RoomScale.HelmetOccipitalGuard",
        (0.0, center_y + 0.078, top_z - 0.055),
        (0.135, 0.036, 0.090), gunmetal, 0.014,
    ))
    brow_z = top_z - 0.052
    helmet_objects.append(_rounded_box("RoomScale.HelmetWorkVisor", (0.0, -0.147, brow_z), (0.235, 0.072, 0.027), gunmetal, 0.009))
    helmet_objects.append(_rounded_box("RoomScale.HelmetBrowInlay", (0.0, -0.187, brow_z), (0.230, 0.016, 0.014), brass, 0.004))
    # Matched crown rails run from the visor to the rear binding as structural
    # ribs; their paired silhouette survives farther away than decorative screws.
    for x in (-0.050, 0.050):
        helmet_objects.append(_polyline_tube(
            f"RoomScale.HelmetCrownSeam_{x:+.3f}",
            [(x, -0.132, top_z - 0.025), (x * 0.88, -0.091, top_z + 0.052), (x * 0.66, -0.032, top_z + 0.112), (x * 0.38, 0.034, top_z + 0.112)],
            0.0100, brass,
        ))

    # A mechanically credible goggle strap wraps the skull behind deep, layered
    # housings. The paired optical barrels are intentionally large at game scale.
    glasses_world = [glasses.matrix_world @ Vector(corner) for corner in glasses.bound_box]
    glasses_min = Vector((min(p.x for p in glasses_world), min(p.y for p in glasses_world), min(p.z for p in glasses_world)))
    glasses_max = Vector((max(p.x for p in glasses_world), max(p.y for p in glasses_world), max(p.z for p in glasses_world)))
    lens_z = (glasses_min.z + glasses_max.z) * 0.5
    # The previous baseline put the far barrel beyond the face projection.
    # Keep both optical centers over the eye line so they survive 3/4 renders.
    lens_spacing = 0.070
    lens_radius = 0.050
    face_sample = _front_surface_sampler(head)
    centers = (-lens_spacing, lens_spacing)
    # A common forward plane avoids the far optic falling behind the near one
    # because each cheek has a different sampled depth. Increased spacing and
    # a controlled lens diameter leave a visible projected gap in 3/4 views.
    shared_front_y = min(face_sample(center_x, lens_z) for center_x in centers) - 0.075
    strap_points = [
        (-0.095, -0.145, lens_z), (-0.118, -0.112, lens_z - 0.002),
        (-0.132, -0.064, lens_z - 0.004), (-0.130, -0.010, lens_z - 0.004),
        (-0.120, 0.025, lens_z - 0.003), (-0.090, 0.043, lens_z - 0.002),
        (0.0, 0.049, lens_z - 0.002), (0.090, 0.043, lens_z - 0.002),
        (0.120, 0.025, lens_z - 0.003), (0.130, -0.010, lens_z - 0.004),
        (0.132, -0.064, lens_z - 0.004), (0.118, -0.112, lens_z - 0.002),
        (0.095, -0.145, lens_z),
    ]
    helmet_objects.append(_polyline_tube("RoomScale.GoggleLeatherStrap", strap_points, 0.006, leather))
    helmet_objects.append(_ellipsoid(
        "RoomScale.HelmetRearStrapPad",
        (0.0, center_y + 0.095, lens_z + 0.022),
        (0.055, 0.016, 0.048), leather,
    ))
    # Structural upper support is sized to the paired assembly so the goggles
    # attach to the shell as functional equipment instead of floating jewelry.
    helmet_objects.append(_rounded_box(
        "RoomScale.GoggleStructuralBrow",
        (0.0, shared_front_y + 0.020, lens_z + lens_radius * 1.34),
        (lens_spacing * 2.0 + lens_radius * 1.72, 0.030, 0.021), brass, 0.007,
    ))
    # A real central hinge separates two adjacent optical cells and connects
    # the face cage mechanically; it is broad enough to read at miniature scale.
    helmet_objects.append(_rounded_box(
        "RoomScale.GoggleCentralHinge",
        (0.0, shared_front_y - 0.006, lens_z),
        (0.026, 0.034, 0.038), brass, 0.006,
    ))
    for side in (-1, 1):
        helmet_objects.append(_polyline_tube(
            f"RoomScale.GoggleLoadStrut_{side}",
            [
                (side * (lens_spacing + lens_radius * 0.72), shared_front_y + 0.020, lens_z + lens_radius * 1.26),
                (side * 0.112, center_y - 0.111, lens_z + 0.044),
                (side * 0.084, center_y - 0.102, top_z - 0.065),
            ],
            0.0090, brass,
        ))
    for side, center_x in enumerate(centers):
        goggle_front_y = shared_front_y
        # Keep each machined barrel perpendicular to the same optical plane;
        # a common orientation prevents lens depth staggering in perspective.
        cup_back = (center_x, goggle_front_y + 0.050, lens_z)
        cup_front = (center_x, goggle_front_y - 0.018, lens_z)
        helmet_objects.append(_cylinder_between(f"RoomScale.GoggleIronBarrel{side + 1}", cup_back, cup_front, lens_radius * 1.10, gunmetal, 32, lens_radius * 0.14))
        bpy.ops.mesh.primitive_torus_add(
            major_segments=32, minor_segments=8,
            major_radius=lens_radius * 1.04, minor_radius=lens_radius * 0.32,
            location=(center_x, goggle_front_y - 0.013, lens_z),
            rotation=(math.pi * 0.5, 0.0, 0.0),
        )
        rim = bpy.context.object
        rim.name = f"RoomScale.BrassGoggleBezel{side + 1}"
        rim.data.materials.append(brass)
        for polygon in rim.data.polygons:
            polygon.use_smooth = True
        helmet_objects.append(rim)
        helmet_objects.append(_cylinder_between(
            f"RoomScale.TealOpticalLens{side + 1}",
            (center_x, goggle_front_y - 0.020, lens_z),
            (center_x, goggle_front_y - 0.030, lens_z),
            lens_radius * 0.83, glass, 32, 0.001,
        ))
        # Four retaining screws per barrel make the housing read as manufactured.
        for screw_index, (dx, dz) in enumerate(((0, lens_radius * 0.94), (0, -lens_radius * 0.94), (lens_radius * 0.94, 0), (-lens_radius * 0.94, 0))):
            helmet_objects.append(_ellipsoid(
                f"RoomScale.GoggleRetainer{side + 1}_{screw_index + 1}",
                (center_x + dx, goggle_front_y - 0.033, lens_z + dz),
                (0.0038, 0.0028, 0.0038), brass,
            ))

    bridge_y = shared_front_y - 0.029
    helmet_objects.append(_cylinder_between("RoomScale.GoggleBridge", (-lens_spacing, bridge_y, lens_z), (lens_spacing, bridge_y, lens_z), 0.009, brass, 24, 0.002))
    for side in (-1, 1):
        # Side cups hold the band adjusters. The right-side ratchet is the single
        # visible clockwork mechanism and also tensions the goggle strap.
        # Broad leather temple guard under the metal ear cup, sized to read as
        # helmet protection rather than a decorative dot.
        helmet_objects.append(_ellipsoid(
            f"RoomScale.MachinistTempleGuard_{side}",
            (side * 0.074, center_y + 0.012, lens_z + 0.008),
            (0.024, 0.051, 0.055), leather,
        ))
        x = side * 0.156
        helmet_objects.append(_cylinder_between(
            f"RoomScale.EarCupHousing_{side}",
            (x - side * 0.007, -0.035, lens_z + 0.015),
            (x + side * 0.007, -0.035, lens_z + 0.015),
            0.036, gunmetal, 40, 0.0025,
        ))
    gear_center = (0.185, -0.030, lens_z + 0.016)
    helmet_objects.append(_add_gear_on_x("RoomScale.GoggleStrapRatchet", gear_center, 0.032, 0.009, brass, teeth=16))
    helmet_objects.append(_cylinder_between(
        "RoomScale.RatchetHub", (0.1895, gear_center[1], gear_center[2]), (0.197, gear_center[1], gear_center[2]), 0.010, gunmetal, 32, 0.0015,
    ))
    helmet_objects.append(_cylinder_between(
        "RoomScale.RatchetAxle", (0.197, gear_center[1], gear_center[2]), (0.202, gear_center[1], gear_center[2]), 0.0045, brass, 24, 0.001,
    ))
    helmet_objects.append(_cylinder_between(
        "RoomScale.GoggleStrapTensioner", (0.185, -0.030, lens_z + 0.016), (0.145, -0.070, lens_z), 0.0042, brass, 20, 0.0008,
    ))
    bpy.data.objects.remove(fedora, do_unlink=True)
    bpy.data.objects.remove(glasses, do_unlink=True)
    return helmet_objects


def _front_surface_sampler(suit):
    vertices = [suit.matrix_world @ vertex.co for vertex in suit.data.vertices]
    polygons = [tuple(polygon.vertices) for polygon in suit.data.polygons]
    tree = BVHTree.FromPolygons(vertices, polygons)
    def sample(x, z):
        hit, _normal, _face, _distance = tree.ray_cast(Vector((x, -1.0, z)), Vector((0.0, 1.0, 0.0)), 3.0)
        if hit is not None:
            return hit.y
        closest = min(vertices, key=lambda p: abs(p.x - x) + abs(p.z - z) * 0.7)
        return closest.y
    return sample


def _back_surface_sampler(suit):
    vertices = [suit.matrix_world @ vertex.co for vertex in suit.data.vertices]
    polygons = [tuple(polygon.vertices) for polygon in suit.data.polygons]
    tree = BVHTree.FromPolygons(vertices, polygons)
    def sample(x, z):
        hit, _normal, _face, _distance = tree.ray_cast(Vector((x, 1.0, z)), Vector((0.0, -1.0, 0.0)), 3.0)
        if hit is not None:
            return hit.y
        closest = min(vertices, key=lambda p: abs(p.x - x) + abs(p.z - z) * 0.7)
        return closest.y
    return sample


def _double_sided_panel(name, sampler, rows, material, offset=0.012, thickness=0.006, columns=12, center_x=0.0):
    vertices = []
    for z, half_width in rows:
        for column in range(columns + 1):
            u = (column / columns) * 2.0 - 1.0
            x = center_x + u * half_width
            y = sampler(x, z) - offset
            vertices.append((x, y, z))
    front_count = len(vertices)
    vertices.extend((x, y + thickness, z) for x, y, z in vertices[:front_count])
    stride = columns + 1
    faces = []
    for row in range(len(rows) - 1):
        for column in range(columns):
            a = row * stride + column
            b = a + 1
            c = a + stride + 1
            d = a + stride
            faces.append((a, b, c, d))
            faces.append((front_count + d, front_count + c, front_count + b, front_count + a))
    # Close the visible hem, neckline, and side edges with true garment thickness.
    for row in (0, len(rows) - 1):
        for column in range(columns):
            a = row * stride + column
            b = a + 1
            faces.append((a, front_count + a, front_count + b, b))
    for row in range(len(rows) - 1):
        for column in (0, columns):
            a = row * stride + column
            b = a + stride
            faces.append((a, b, front_count + b, front_count + a))
    return _mesh_object(name, vertices, faces, material, smooth=True)


def _ribbon(name, sampler, points_xz, width, material, offset=0.018, thickness=0.004):
    edge_points = []
    for index, (x, z) in enumerate(points_xz):
        previous = Vector(points_xz[max(0, index - 1)])
        following = Vector(points_xz[min(len(points_xz) - 1, index + 1)])
        direction = (following - previous).normalized()
        side = Vector((-direction.y, direction.x)) * width * 0.5
        pair = []
        for sign in (-1.0, 1.0):
            px, pz = Vector((x, z)) + side * sign
            pair.append((px, sampler(px, pz) - offset, pz))
        edge_points.append(pair)
    front = [point for pair in edge_points for point in pair]
    back = [(x, y + thickness, z) for x, y, z in front]
    vertices = front + back
    count = len(front)
    faces = []
    for index in range(len(edge_points) - 1):
        a = index * 2
        b = a + 1
        c = a + 3
        d = a + 2
        faces.append((a, b, c, d))
        faces.append((count + d, count + c, count + b, count + a))
        faces.extend(((a, d, count + d, count + a), (b, count + b, count + c, c)))
    faces.extend(((0, count, count + 1, 1), (len(front) - 2, len(front) - 1, count + len(front) - 1, count + len(front) - 2)))
    return _mesh_object(name, vertices, faces, material, smooth=True)


def _add_buckle(name, center, width, height, material, dark_material):
    x, y, z = center
    outer = _rounded_box(name + "Frame", (x, y, z), (width, 0.007, height), material, min(width, height) * 0.12)
    inset = _rounded_box(name + "Inset", (x, y + 0.0042, z), (width * 0.58, 0.003, height * 0.48), dark_material, min(width, height) * 0.08)
    pin = _cylinder_between(name + "Pin", (x - width * 0.32, y - 0.004, z), (x + width * 0.32, y - 0.004, z), height * 0.06, material, 16)
    return [outer, inset, pin]


def _add_clockwork_workwear(suit, rig, shoe_mesh, human, coverall_material, apron_material, leather_material, thread_material, brass_material, iron_material, rubber_material):
    sample = _front_surface_sampler(suit)
    back_sample = _back_surface_sampler(suit)
    def waist_profile(z):
        points = [suit.matrix_world @ vertex.co for vertex in suit.data.vertices]
        band = [point for point in points if abs(point.z - z) <= 0.035 and abs(point.x) <= 0.20]
        if not band:
            raise RuntimeError(f"Could not measure fitted suit waist at z={z}")
        return (
            min(point.x for point in band), max(point.x for point in band),
            min(point.y for point in band), max(point.y for point in band),
        )
    torso = []
    # The fitted overalls leave both upper arms exposed. Add true sleeves and
    # leather cuffs to the arm bones using local body skin weights.
    torso.extend(_add_fitted_work_sleeves(rig, human, coverall_material, leather_material))
    # A shaped, thick apron bib/skirt covers the necktie and establishes the
    # workshop-worker torso silhouette while following the fitted body surface.
    apron_rows = [(0.765, 0.108), (0.785, 0.126), (0.91, 0.132), (1.055, 0.137), (1.20, 0.141), (1.325, 0.132), (1.372, 0.104), (1.392, 0.065)]
    apron = _double_sided_panel("RoomScale.FittedMachinistApron", sample, apron_rows, apron_material, offset=0.014, thickness=0.010, columns=20)
    torso.append(apron)
    # A fitted stand collar and shoulder yoke make the base read as a work
    # garment assembled around the torso instead of uninterrupted coveralls.
    torso.append(_ribbon(
        "RoomScale.MachinistWorkcoatCollar", sample,
        [(-0.118, 1.386), (-0.108, 1.414), (-0.072, 1.438), (0.0, 1.448), (0.072, 1.438), (0.108, 1.414), (0.118, 1.386)],
        0.045, leather_material, offset=0.029, thickness=0.009,
    ))
    torso.append(_ribbon(
        "RoomScale.MachinistCoatShoulderYoke", sample,
        [(-0.150, 1.367), (-0.126, 1.398), (-0.075, 1.418), (0.0, 1.424), (0.075, 1.418), (0.126, 1.398), (0.150, 1.367)],
        0.062, apron_material, offset=0.031, thickness=0.012,
    ))
    torso.append(_ribbon(
        "RoomScale.RearMachinistShoulderYoke", back_sample,
        [(-0.150, 1.367), (-0.126, 1.398), (-0.075, 1.418), (0.0, 1.424), (0.075, 1.418), (0.126, 1.398), (0.150, 1.367)],
        0.062, apron_material, offset=-0.026, thickness=0.012,
    ))
    for side in (-1, 1):
        torso.append(_ribbon(
            f"RoomScale.RearPackShoulderStrap_{side}", back_sample,
            [(side * 0.105, 1.408), (side * 0.083, 1.350), (side * 0.066, 1.260), (side * 0.052, 1.175)],
            0.024, leather_material, offset=-0.030, thickness=0.008,
        ))
    # Broad X harness straps and deliberate top and side seams are readable
    # construction, not small decorative gear scatter.
    torso.append(_ribbon("RoomScale.LeftCrossHarness", sample, [(-0.092, 1.37), (-0.056, 1.29), (-0.010, 1.17), (0.050, 1.045), (0.085, 0.965)], 0.040, leather_material, offset=0.022))
    torso.append(_ribbon("RoomScale.RightCrossHarness", sample, [(0.092, 1.37), (0.056, 1.29), (0.010, 1.17), (-0.050, 1.045), (-0.085, 0.965)], 0.040, leather_material, offset=0.026))
    for side in (-1, 1):
        # Reinforced apron edge stitching follows the actual fitted surface.
        torso.append(_ribbon(f"RoomScale.ApronSeam_{side}", sample, [(side * 0.105, 0.79), (side * 0.124, 0.91), (side * 0.118, 1.08), (side * 0.119, 1.24), (side * 0.105, 1.34)], 0.0022, thread_material, offset=0.023, thickness=0.0012))
        # Folded pocket and cover flap; these are sized as working garment parts.
        px, pz = side * 0.077, 0.86
        torso.append(_double_sided_panel(
            f"RoomScale.ToolPouch_{side}", sample,
            [(pz - 0.045, 0.031), (pz - 0.036, 0.038), (pz + 0.027, 0.038), (pz + 0.037, 0.031)],
            leather_material, offset=0.031, thickness=0.010, columns=6, center_x=px,
        ))
        torso.append(_rounded_box(f"RoomScale.PouchFlap_{side}", (px, sample(px, pz + 0.029) - 0.039, pz + 0.029), (0.074, 0.012, 0.024), apron_material, 0.004))
        torso.append(_ellipsoid(f"RoomScale.PouchSnap_{side}", (px, sample(px, pz + 0.029) - 0.047, pz + 0.029), (0.004, 0.002, 0.004), brass_material))
    # Functional strap adjusters, placed high enough to remain apart from the
    # independently attached role badge and carried tools.
    torso.extend(_add_buckle("RoomScale.HarnessBuckleLeft", (-0.046, sample(-0.046, 1.19) - 0.028, 1.19), 0.036, 0.029, brass_material, iron_material))
    torso.extend(_add_buckle("RoomScale.HarnessBuckleRight", (0.046, sample(0.046, 1.19) - 0.031, 1.19), 0.036, 0.029, brass_material, iron_material))
    # A wide waist belt, keeper loop, and side-mounted tool socket read as kit.
    min_x, max_x, min_y, max_y = waist_profile(0.982)
    belt_rx = max(abs(min_x), abs(max_x)) + 0.006
    belt_center_y = (min_y + max_y) * 0.5
    belt_ry = (max_y - min_y) * 0.5 + 0.005
    torso.append(_elliptical_band("RoomScale.WorkBelt", (0.0, belt_center_y, 0.982), belt_rx, belt_ry, belt_rx - 0.008, belt_ry - 0.008, 0.025, leather_material, 32))
    torso.extend(_add_buckle("RoomScale.WorkBeltBuckle", (0.0, min_y - 0.010, 0.982), 0.044, 0.035, brass_material, iron_material))
    torso.append(_cylinder_between("RoomScale.TapeMeasureCase", (belt_rx * 0.82, belt_center_y - 0.012, 0.97), (belt_rx * 0.92, belt_center_y - 0.012, 0.97), 0.019, brass_material, 36, 0.002))
    torso.append(_cylinder_between("RoomScale.TapeMeasureFace", (belt_rx * 0.93, belt_center_y - 0.012, 0.97), (belt_rx * 0.96, belt_center_y - 0.012, 0.97), 0.012, iron_material, 32, 0.001))
    torso.append(_rounded_box("RoomScale.ToolLoop", (-belt_rx * 0.9, belt_center_y - 0.012, 0.968), (0.020, 0.016, 0.064), brass_material, 0.004))
    # A compact twin-reservoir pressure/tool pack gives the worker a readable
    # profession-specific rear profile. The paired vessels, manifold, gauge,
    # and hose are functional equipment shapes, not scattered gear decoration.
    tank_centers = (-0.050, 0.050)
    pack_y = back_sample(0.0, 1.055) + 0.040
    for side, x in enumerate(tank_centers):
        tank_y = back_sample(x, 1.055) + 0.039
        torso.append(_cylinder_between(
            f"RoomScale.PressureReservoir_{side + 1}",
            (x, tank_y, 0.875), (x, tank_y, 1.230), 0.038, brass_material, 24, 0.005,
        ))
        for ring_index, z in enumerate((0.900, 1.205)):
            torso.append(_elliptical_band(
                f"RoomScale.ReservoirFerrule_{side + 1}_{ring_index + 1}",
                (x, tank_y, z), 0.041, 0.041, 0.035, 0.035, 0.014, brass_material, 24,
            ))
        for strap_index, z in enumerate((1.000, 1.105)):
            torso.append(_elliptical_band(
                f"RoomScale.ReservoirRetainingStrap_{side + 1}_{strap_index + 1}",
                (x, tank_y, z), 0.043, 0.043, 0.037, 0.037, 0.015, leather_material, 24,
            ))
        torso.append(_rounded_box(
            f"RoomScale.PackFrameRail_{side + 1}",
            (x * 1.80, pack_y + 0.012, 1.050), (0.016, 0.022, 0.362), leather_material, 0.005,
        ))
    for z in (0.890, 1.220):
        torso.append(_rounded_box(
            f"RoomScale.PackFrameCrossbar_{z:.3f}",
            (0.0, pack_y + 0.012, z), (0.181, 0.022, 0.018), brass_material, 0.005,
        ))
    gauge_y = back_sample(0.0, 1.235) + 0.080
    torso.append(_cylinder_between("RoomScale.PressureGaugeHousing", (0.0, gauge_y - 0.014, 1.235), (0.0, gauge_y + 0.014, 1.235), 0.032, brass_material, 24, 0.0025))
    torso.append(_cylinder_between("RoomScale.PressureGaugeFace", (0.0, gauge_y + 0.014, 1.235), (0.0, gauge_y + 0.016, 1.235), 0.024, iron_material, 24, 0.0015))
    torso.append(_polyline_tube(
        "RoomScale.PressureGaugeNeedle",
        [(0.0, gauge_y + 0.018, 1.235), (0.014, gauge_y + 0.018, 1.245)], 0.0021, brass_material,
    ))
    manifold_y = pack_y + 0.043
    torso.append(_polyline_tube(
        "RoomScale.PressurePackManifold",
        [(-0.050, manifold_y, 1.225), (-0.050, manifold_y, 1.260), (0.0, manifold_y, 1.260), (0.050, manifold_y, 1.260), (0.050, manifold_y, 1.225)],
        0.0050, brass_material,
    ))
    torso.append(_polyline_tube(
        "RoomScale.PressureToolHose",
        [(0.075, pack_y + 0.025, 1.18), (0.091, pack_y + 0.038, 1.115), (0.098, pack_y + 0.052, 1.015), (0.080, belt_center_y + 0.020, 0.972)],
        0.0045, leather_material,
    ))
    for obj in torso:
        for index, material in enumerate(obj.data.materials):
            if material == thread_material:
                obj.data.materials[index] = apron_material
    body_mesh = _join_reference_skinned(torso, rig, suit, "RoomScale.ClockworkWorkshopClothing")

    # Replace dress-shoe reads with thick, layered rubber soles and fitted ankle
    # gaiters. Each side remains weighted to the actual lower-leg bone.
    lower_body = []
    for side in (-1, 1):
        x = side * 0.188
        lower_body.append(_elliptical_band(f"RoomScale.BootGaiter_{side}", (x, -0.015, 0.155), 0.048, 0.056, 0.040, 0.047, 0.025, leather_material, 24))
        lower_body.append(_elliptical_band(f"RoomScale.BootCuffRim_{side}", (x, -0.015, 0.17), 0.049, 0.057, 0.046, 0.053, 0.005, brass_material, 24))
        # Two riveted toe/instep straps clarify the boot assembly at close range.
        lower_body.append(_rounded_box(f"RoomScale.BootInstepStrap_{side}", (x, -0.088, 0.041), (0.097, 0.020, 0.015), leather_material, 0.004))
        lower_body.append(_rounded_box(f"RoomScale.BootToeGuard_{side}", (x, -0.177, 0.043), (0.082, 0.011, 0.024), iron_material, 0.009))
        # Full padded outsoles close against the existing footwear instead of
        # the open ellipse outlines that floated under the first challenger.
        lower_body.append(_ellipsoid(f"RoomScale.BootOutsole_{side}", (x, -0.078, -0.028), (0.055, 0.125, 0.012), rubber_material))
    _join_reference_skinned(lower_body, rig, shoe_mesh, "RoomScale.ClockworkBootConstruction", fallback="foot")
    return body_mesh


def _join_attached(objects, rig, name: str, weights: dict[str, float]):
    if not objects:
        raise RuntimeError(f"No geometry was generated for {name}")
    weighted = []
    for entry in objects:
        if isinstance(entry, tuple):
            obj, bone_weights = entry
        else:
            obj, bone_weights = entry, weights
        for modifier in list(obj.modifiers):
            if modifier.type != "ARMATURE":
                bpy.context.view_layer.objects.active = obj
                obj.select_set(True)
                bpy.ops.object.modifier_apply(modifier=modifier.name)
                obj.select_set(False)
        _attach_to_bone(obj, rig, bone_weights)
        weighted.append(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in weighted:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = weighted[0]
    bpy.ops.object.join()
    combined = bpy.context.view_layer.objects.active
    combined.name = name
    return combined


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1 :]
    project_root = Path(args[0]).resolve()
    output_dir = Path(args[1]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    _clear_scene()
    _package, HumanService = _install_mpfb(project_root)

    asset_root = project_root / ".tools/makehuman_system_assets-data"
    human = HumanService.create_human(mask_helpers=True, detailed_helpers=True, extra_vertex_groups=True)
    skin = asset_root / "skins/young_caucasian_male/young_caucasian_male.mhmat"
    HumanService.set_character_skin(str(skin), human, skin_type="GAMEENGINE")
    rig = HumanService.add_builtin_rig(human, "game_engine", import_weights=True)
    if rig is None:
        raise RuntimeError("MPFB2 did not produce its standard game-engine skeleton")

    clothing = [
        ("clothes/male_worksuit01/male_worksuit01.mhclo", "Clothes"),
        ("clothes/toigo_gloves_medium/toigo_gloves_medium.mhclo", "Clothes"),
        ("clothes/shoes03/shoes03.mhclo", "Clothes"),
        ("clothes/toigo_round_glasses_leopard/toigo_round_glasses_leopard.mhclo", "Clothes"),
        ("clothes/fedora01/fedora01.mhclo", "Clothes"),
        ("eyes/high-poly/high-poly.mhclo", "Eyes"),
    ]
    imported = []
    for relative, asset_type in clothing:
        file = asset_root / relative
        if not file.is_file():
            raise FileNotFoundError(file)
        imported.append(HumanService.add_mhclo_asset(
            str(file), human, asset_type=asset_type, subdiv_levels=0,
            material_type="GAMEENGINE", set_up_rigging=True, interpolate_weights=True,
            import_subrig=True, import_weights=True,
        ))

    workcoat_normal, workcoat_roughness = _derive_worksuit_pbr_maps(project_root, output_dir)
    workcoat_albedo = _derive_clockwork_workcoat(project_root, output_dir)
    textures = {
        "human": (asset_root / "skins/young_caucasian_male/young_lightskinned_male_diffuse.png", 0.62, 0.0, None, None),
        "male_worksuit01": (workcoat_albedo, 0.82, 0.0, workcoat_normal, workcoat_roughness),
        "toigo_gloves_medium": (asset_root / "clothes/toigo_gloves_medium/Gloves02UV.png", 0.57, 0.0, None, None),
        "shoes03": (asset_root / "clothes/shoes03/shoes03_diffuse.png", 0.43, 0.0, None, None),
        "toigo_round_glasses_leopard": (asset_root / "clothes/toigo_round_glasses_leopard/Glasses-leopard.png", 0.23, 0.68, None, None),
        "fedora": (asset_root / "clothes/fedora01/fedora_diffuse.png", 0.72, 0.0, asset_root / "clothes/fedora01/fedora_normal.png", None),
        "high-poly": (asset_root / "eyes/materials/blue_eye.png", 0.28, 0.0, None, None),
    }
    pbr_materials = {}
    for token, (albedo, roughness, metallic, normal, roughness_map) in textures.items():
        if albedo.is_file():
            pbr_materials[token] = _pbr_material(
                f"RoomScale_{token}_PBR", albedo, roughness, metallic, normal, roughness_map
            )

    brass = bpy.data.materials.new("RoomScale_Aged_Brass_PBR")
    brass.use_nodes = True
    brass_bsdf = next(node for node in brass.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    brass_bsdf.inputs["Base Color"].default_value = (0.64, 0.39, 0.12, 1.0)
    brass_bsdf.inputs["Metallic"].default_value = 0.72
    brass_bsdf.inputs["Roughness"].default_value = 0.25
    gunmetal = bpy.data.materials.new("RoomScale_Blackened_Steel_PBR")
    gunmetal.use_nodes = True
    iron_bsdf = next(node for node in gunmetal.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    iron_bsdf.inputs["Base Color"].default_value = (0.055, 0.075, 0.078, 1.0)
    iron_bsdf.inputs["Metallic"].default_value = 0.78
    iron_bsdf.inputs["Roughness"].default_value = 0.34
    glass = bpy.data.materials.new("RoomScale_Teal_Optical_Glass_PBR")
    glass.use_nodes = True
    glass_bsdf = next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    glass_bsdf.inputs["Base Color"].default_value = (0.055, 0.35, 0.29, 1.0)
    glass_bsdf.inputs["Metallic"].default_value = 0.12
    glass_bsdf.inputs["Roughness"].default_value = 0.13
    if "Emission Color" in glass_bsdf.inputs:
        glass_bsdf.inputs["Emission Color"].default_value = (0.012, 0.12, 0.085, 1.0)
        glass_bsdf.inputs["Emission Strength"].default_value = 0.20
    if "Coat Weight" in glass_bsdf.inputs:
        glass_bsdf.inputs["Coat Weight"].default_value = 0.5
        glass_bsdf.inputs["Coat Roughness"].default_value = 0.09
    thread = bpy.data.materials.new("RoomScale_Cream_Coat_Stitching")
    thread.diffuse_color = (0.72, 0.53, 0.28, 1.0)
    thread.use_nodes = True
    thread_bsdf = next(node for node in thread.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    thread_bsdf.inputs["Base Color"].default_value = (0.72, 0.53, 0.28, 1.0)
    thread_bsdf.inputs["Roughness"].default_value = 0.78
    rubber = bpy.data.materials.new("RoomScale_Boot_Sole_Rubber")
    rubber.diffuse_color = (0.025, 0.033, 0.031, 1.0)
    rubber.use_nodes = True
    rubber_bsdf = next(node for node in rubber.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    rubber_bsdf.inputs["Base Color"].default_value = (0.025, 0.033, 0.031, 1.0)
    rubber_bsdf.inputs["Roughness"].default_value = 0.86

    workwear_maps = _make_workwear_maps(output_dir)
    apron_material = _pbr_material(
        "RoomScale_Oiled_Canvas_WorkApron", workwear_maps["apron_albedo"], 0.76, 0.0,
        workwear_maps["apron_normal"], workwear_maps["apron_roughness"],
    )
    leather_material = _pbr_material(
        "RoomScale_Burnished_WorkLeather", workwear_maps["leather_albedo"], 0.72, 0.0,
        workwear_maps["leather_normal"], workwear_maps["leather_roughness"],
    )
    helmet_material = _pbr_material(
        "RoomScale_Oilcloth_Machinist_Helmet", workwear_maps["helmet_albedo"], 0.68, 0.0,
        workwear_maps["helmet_normal"], workwear_maps["helmet_roughness"],
    )
    coverall_material = _pbr_material(
        "RoomScale_Teal_Work_Coverall_Cloth", workwear_maps["coverall_albedo"], 0.80, 0.0,
        workwear_maps["coverall_normal"], workwear_maps["coverall_roughness"],
    )
    fedora = next((obj for obj in imported if "fedora" in obj.name.lower()), None)
    if fedora is None:
        raise RuntimeError("MPFB2 did not return the fitted fedora object")
    glasses = next((obj for obj in imported if "glasses" in obj.name.lower()), None)
    if glasses is None:
        raise RuntimeError("MPFB2 did not return the fitted glasses object")
    suit = next((obj for obj in imported if "male_worksuit01" in obj.name.lower()), None)
    if suit is None:
        raise RuntimeError("MPFB2 did not return the fitted work-coverall base mesh")
    shoe_mesh = next((obj for obj in imported if "shoes03" in obj.name.lower()), None)
    if shoe_mesh is None:
        raise RuntimeError("MPFB2 did not return the fitted shoe mesh needed to skin the work boots")
    head_details = _add_clockwork_helmet_and_goggles(rig, fedora, glasses, helmet_material, brass, gunmetal, glass)
    head_detail_names = [obj.name for obj in head_details]
    head_hardware = _join_attached(head_details, rig, "RoomScale.ClockworkMachinistHelmet", {"head": 1.0})
    workwear_mesh = _add_clockwork_workwear(suit, rig, shoe_mesh, human, coverall_material, apron_material, leather_material, apron_material, brass, gunmetal, rubber)

    mesh_stats = []
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            continue
        match = next((token for token in pbr_materials if token != "human" and token.lower() in obj.name.lower()), None)
        if obj == human:
            match = "human"
        if match:
            _assign_material(obj, pbr_materials[match])
        mesh_stats.append({"name": obj.name, "vertices": len(obj.data.vertices), "triangles": sum(len(face.vertices) - 2 for face in obj.data.polygons)})

    # Build a second skin-weighted level from the same source meshes. The detailed
    # geometry remains untouched for close inspection; Godot swaps to LOD1 past 5 in.
    lod_ratios = {
        "Human": 0.20,
        "Human.male_worksuit01": 0.30,
        "Human.toigo_gloves_medium": 0.30,
        "Human.shoes03": 0.30,
        "Human.high-poly": 0.30,
        "RoomScale.ClockworkMachinistHelmet": 0.25,
        "RoomScale.ClockworkWorkshopClothing": 0.25,
        "RoomScale.ClockworkBootConstruction": 0.30,
    }
    lod_stats = []
    source_meshes = {obj.name: obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj.name in lod_ratios}
    if set(source_meshes) != set(lod_ratios):
        raise RuntimeError(f"LOD source mesh set mismatch: expected {sorted(lod_ratios)}, found {sorted(source_meshes)}")
    for source_name, ratio in lod_ratios.items():
        source_obj = source_meshes[source_name]
        lod_obj = source_obj.copy()
        lod_obj.data = source_obj.data.copy()
        lod_obj.name = source_name + "_LOD1"
        lod_obj.data.name = lod_obj.name + "_Mesh"
        bpy.context.scene.collection.objects.link(lod_obj)
        # MPFB's main body carries facial shape keys; the far LOD keeps its full
        # weighted skeleton but omits tiny facial morphs that are subpixel at 5+ in.
        if lod_obj.data.shape_keys is not None:
            bpy.ops.object.select_all(action="DESELECT")
            lod_obj.select_set(True)
            bpy.context.view_layer.objects.active = lod_obj
            bpy.ops.object.shape_key_remove(all=True)
            lod_obj.select_set(False)
        decimate = lod_obj.modifiers.new("RoomScale distance LOD1 budget", "DECIMATE")
        decimate.ratio = ratio
        armature_index = next((index for index, modifier in enumerate(lod_obj.modifiers) if modifier.type == "ARMATURE"), None)
        if armature_index is not None:
            lod_obj.modifiers.move(len(lod_obj.modifiers) - 1, armature_index)
        bpy.ops.object.select_all(action="DESELECT")
        lod_obj.select_set(True)
        bpy.context.view_layer.objects.active = lod_obj
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        lod_obj.select_set(False)
        lod_triangles = sum(len(face.vertices) - 2 for face in lod_obj.data.polygons)
        lod_stats.append({"name": lod_obj.name, "source_mesh": source_name, "ratio": ratio, "vertices": len(lod_obj.data.vertices), "triangles": lod_triangles})

    for image in bpy.data.images:
        if image.source == "FILE":
            try:
                image.pack()
            except RuntimeError:
                pass

    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and (obj == human or obj.parent == rig or obj.parent == human or obj in imported):
            obj.select_set(True)
    bpy.context.view_layer.update()
    output = output_dir / "citizen.glb"
    result = bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB", use_selection=True,
        export_apply=True, export_materials="EXPORT", export_skins=True,
        export_animations=False,
    )
    if "FINISHED" not in result or not output.is_file():
        raise RuntimeError(f"Blender glTF export failed: {result}")

    record = {
        "candidate_id": "citizen-v076",
        "strategy_identity": "MPFB2_fitted_rig_with_authored_machinist_helmet_and_silhouette_scale_workwear",
        "method": "MPFB2 anatomical basemesh and 53-bone rig + authored fitted helmet/twin optical barrels + front-sampled thick machinist apron, crossed harness, working pockets, belt, and layered boot construction",
        "tool_versions": {"blender": bpy.app.version_string, "mpfb2": str(_package.VERSION)},
        "created_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
        "assets": [entry[0] for entry in clothing],
        "skin_asset": "skins/young_caucasian_male/young_caucasian_male.mhmat",
        "license": "MPFB2 GPL-3.0 generator; all selected MakeHuman system, coveralls, glasses, gloves, shoes, and eyes assets are marked CC0 by their asset pack terms.",
        "rig": {"name": "game_engine", "bones": [bone.name for bone in rig.data.bones]},
        "meshes": mesh_stats,
        "distance_lod": {
            "switch_distance_inches": 5.0,
            "high_detail_triangles": sum(mesh["triangles"] for mesh in mesh_stats),
            "lod1_triangles": sum(mesh["triangles"] for mesh in lod_stats),
            "lod1_meshes": lod_stats,
            "shared_skeleton": True,
        },
        "pbr_maps": [
            "materials/workcoat_normal.png", "materials/workcoat_roughness.png", "materials/workcoat_albedo.png",
            "materials/workwear_apron_albedo.png", "materials/workwear_apron_normal.png", "materials/workwear_apron_roughness.png",
            "materials/workwear_leather_albedo.png", "materials/workwear_leather_normal.png", "materials/workwear_leather_roughness.png",
            "materials/workwear_helmet_albedo.png", "materials/workwear_helmet_normal.png", "materials/workwear_helmet_roughness.png",
            "materials/workwear_coverall_albedo.png", "materials/workwear_coverall_normal.png", "materials/workwear_coverall_roughness.png",
        ],
        "clockwork_cap_details": [name for name in head_detail_names if "Helmet" in name or "Ratchet" in name],
        "clockwork_goggle_details": [name for name in head_detail_names if "Goggle" in name or "Optical" in name or "EarCup" in name],
        "batched_head_hardware_mesh": head_hardware.name,
        "batched_workwear_mesh": workwear_mesh.name,
        "batched_boot_mesh": "RoomScale.ClockworkBootConstruction",
        "output": {"path": "citizen.glb", "bytes": output.stat().st_size, "sha256": _sha256(output)},
    }
    (output_dir / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print("ROOMSCALE_MPFB_CITIZEN_V076_GENERATION_PASS", json.dumps({"mesh_count": len(mesh_stats), "high_detail_triangles": sum(m["triangles"] for m in mesh_stats), "lod1_triangles": sum(m["triangles"] for m in lod_stats), "glb_bytes": output.stat().st_size, "batched_head_hardware": head_hardware.name}))


if __name__ == "__main__":
    main()
