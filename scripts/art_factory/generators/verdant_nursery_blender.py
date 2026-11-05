"""Build a presentation-only, gameplay-readable Verdant growth nursery."""

from __future__ import annotations

import json
import math
import os
import sys
from datetime import UTC, datetime
from pathlib import Path

import bpy
from mathutils import Vector


def _clear() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in bpy.data.materials:
        bpy.data.materials.remove(material)


def _material(name: str, color: tuple[float, float, float], roughness: float = 0.82,
              metallic: float = 0.0) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Roughness"].default_value = roughness
    principled.inputs["Metallic"].default_value = metallic
    return material


def _mesh(name: str, vertices: list[tuple[float, float, float]], faces: list[tuple[int, ...]],
          material: bpy.types.Material) -> bpy.types.Object:
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(material)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    for polygon in data.polygons:
        polygon.use_smooth = True
    return obj


def _beam(name: str, a: Vector, b: Vector, radius_a: float, radius_b: float,
          material: bpy.types.Material, sides: int = 9) -> bpy.types.Object:
    direction = (b - a).normalized()
    reference = Vector((0, 1, 0)) if abs(direction.dot(Vector((0, 1, 0)))) < 0.92 else Vector((1, 0, 0))
    axis_u = direction.cross(reference).normalized()
    axis_v = direction.cross(axis_u).normalized()
    vertices: list[tuple[float, float, float]] = []
    for center, radius in ((a, radius_a), (a.lerp(b, 0.34), radius_a * 0.83 + radius_b * 0.17),
                           (a.lerp(b, 0.72), radius_a * 0.35 + radius_b * 0.65), (b, radius_b)):
        for index in range(sides):
            angle = math.tau * index / sides
            point = center + radius * (math.cos(angle) * axis_u + math.sin(angle) * axis_v)
            vertices.append(tuple(point))
    faces: list[tuple[int, ...]] = []
    for ring in range(3):
        for index in range(sides):
            faces.append((ring * sides + index, ring * sides + (index + 1) % sides,
                          (ring + 1) * sides + (index + 1) % sides, (ring + 1) * sides + index))
    faces.append(tuple(range(sides - 1, -1, -1)))
    faces.append(tuple(3 * sides + index for index in range(sides)))
    return _mesh(name, vertices, faces, material)


def _box(name: str, dimensions: tuple[float, float, float], position: tuple[float, float, float],
         material: bpy.types.Material, bevel: float = 0.04) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel > 0:
        modifier = obj.modifiers.new("Soft grown edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def _leaf(name: str, center: Vector, length: float, width: float, yaw: float,
          top: bpy.types.Material, underside: bpy.types.Material, edge: bpy.types.Material,
          tilt: float = 0.0, arch: float = 0.42, vein_material: bpy.types.Material | None = None,
          pitch: float = 0.0) -> None:
    direction = Vector((math.cos(yaw) * math.cos(pitch), math.sin(yaw) * math.cos(pitch), math.sin(pitch)))
    lateral = Vector((-math.sin(yaw), math.cos(yaw), 0.0))
    normal = direction.cross(lateral).normalized()
    along, across = 10, 6
    upper: list[Vector] = []
    lower: list[Vector] = []
    for row in range(along + 1):
        u = -1.0 + 2.0 * row / along
        fullness = max(0.025, math.sin(math.pi * (u + 1.0) * 0.5) ** 0.82)
        row_center = center + direction * (u * length * 0.5)
        row_center += normal * (arch * math.sin(math.pi * (u + 1.0) * 0.5))
        row_center.z += tilt * u + arch * math.sin(math.pi * (u + 1.0) * 0.5)
        for column in range(across + 1):
            v = -1.0 + 2.0 * column / across
            point = row_center + lateral * (v * width * 0.5 * fullness)
            point += normal * (0.16 * (1.0 - v * v) * fullness)
            upper.append(point + normal * 0.055)
            lower.append(point - normal * 0.055)
    row_size = across + 1
    verts = [tuple(point) for point in upper + lower]
    faces: list[tuple[int, ...]] = []
    material_indices: list[int] = []
    count = len(upper)
    for row in range(along):
        for column in range(across):
            i = row * row_size + column
            faces.append((i, i + 1, i + row_size + 1, i + row_size))
            material_indices.append(0)
            j = count + i
            faces.append((j + row_size, j + row_size + 1, j + 1, j))
            material_indices.append(1)
    for row in range(along):
        for column in (0, across):
            i = row * row_size + column
            faces.append((i, i + row_size, count + i + row_size, count + i))
            material_indices.append(2)
    for column in range(across):
        for row in (0, along):
            i = row * row_size + column
            faces.append((i, i + 1, count + i + 1, count + i))
            material_indices.append(2)
    leaf = _mesh(name, verts, faces, top)
    for mat in (underside, edge):
        leaf.data.materials.append(mat)
    for polygon, material_index in zip(leaf.data.polygons, material_indices):
        polygon.material_index = material_index
    if vein_material is not None:
        # A narrow raised central vein catches light at close range while the
        # broad green/plum surfaces stay readable at the 64-inch camera.
        for vein in (-0.45, -0.12, 0.2, 0.48):
            v = vein
            tip = center + lateral * (v * width * 0.38) + normal * 0.14
            start = center - direction * (length * 0.34) + lateral * (v * width * 0.10)
            start += normal * 0.18
            _beam(f"{name} raised side vein", start, tip, 0.025, 0.012, vein_material, sides=5)
        start = center - direction * (length * 0.42)
        end = center + direction * (length * 0.42)
        start += normal * 0.20
        end += normal * (0.20 + tilt)
        _beam(f"{name} central midrib", start, end, 0.045, 0.018, vein_material, sides=6)


def _pod(name: str, center: Vector, scale: tuple[float, float, float],
         material: bpy.types.Material, fleck: bpy.types.Material) -> None:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, location=center)
    pod = bpy.context.object
    pod.name = name
    pod.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    pod.data.materials.append(material)
    for polygon in pod.data.polygons:
        polygon.use_smooth = True
    # A few large raised seed marks make the pods feel grown and harvested.
    for index in range(3):
        angle = math.tau * index / 3.0
        point = center + Vector((math.cos(angle) * scale[0] * 0.76,
                                 math.sin(angle) * scale[1] * 0.76,
                                 0.0))
        _beam(f"{name} seed ridge", point, point + Vector((0.04, 0.03, scale[2] * 0.64)),
              0.045, 0.022, fleck, sides=5)


def _build(output: Path) -> tuple[int, dict[str, str]]:
    recipe_path = Path(os.environ.get("ROOMSCALE_ART_FACTORY_RECIPE", ""))
    recipe = json.loads(recipe_path.read_text(encoding="utf-8")) if recipe_path.is_file() else {}
    parameters = recipe.get("parameters", {})
    seed = int(recipe.get("deterministic_seed", 20261109))
    depth_scale = float(parameters.get("depth_scale", 1.0))
    height_scale = float(parameters.get("height_scale", 0.53))
    approved_target = str(parameters.get(
        "approved_visual_target",
        "art/verdant_nursery/visual_director/round-01/approved-target-r01.png",
    ))
    output.mkdir(parents=True, exist_ok=True)
    _clear()

    mats = {
        "wood": _material("Warm living rootwood", (0.14, 0.065, 0.025), 0.91),
        "wood_light": _material("Sunlit bark and platform", (0.28, 0.16, 0.055), 0.86),
        "wood_dark": _material("Deep bark joins", (0.075, 0.025, 0.012), 0.94),
        "leaf": _material("Deep natural leaf green", (0.035, 0.12, 0.018), 0.84),
        "leaf_light": _material("Leaf upper growth", (0.085, 0.20, 0.03), 0.80),
        "plum": _material("Plum leaf undersides", (0.14, 0.028, 0.105), 0.89),
        "edge": _material("Leaf edge and veins", (0.38, 0.25, 0.075), 0.81),
        "pod": _material("Harvest ochre seed pods", (0.47, 0.23, 0.025), 0.77),
        "pod_light": _material("Seed pod flecks", (0.72, 0.45, 0.09), 0.73),
        "basket": _material("Woven harvest basket", (0.24, 0.11, 0.035), 0.92),
    }

    # Envelope: 24 x 9.4 x 18 inches. Front is -Y; no roof or wall closes
    # the ground-level work bay. A real ladder leads to the raised growing deck.
    for index in range(12):
        y = -0.85 + index * 0.39
        _box("Rear root platform plank", (11.1, 0.33, 0.28), (0, y, 1.52), mats["wood_light"], 0.065)
    for x in (-5.05, 0.0, 5.05):
        _beam("Platform cross-root", Vector((x, -0.95, 1.33)), Vector((x, 3.75, 1.33)),
              0.24, 0.17, mats["wood"], 8)

    # Open front approach and ladder, with a small work surface under the canopy.
    _box("Open nursery potting surface", (6.9, 1.15, 0.25), (0, -2.95, 1.23), mats["wood_light"], 0.09)
    for x in (-3.05, 3.05):
        _beam("Potting table leg", Vector((x, -3.0, 0.12)), Vector((x, -3.0, 1.18)), 0.15, 0.12, mats["wood"], 7)
    for side in (-1, 1):
        _beam("Entry ladder rail", Vector((side * 0.72, -4.65, 0.08)), Vector((side * 0.72, -0.35, 1.72)),
              0.14, 0.11, mats["wood"], 7)
    for index in range(7):
        y = -4.1 + index * 0.55
        z = 0.24 + index * 0.19
        _beam("Entry ladder rung", Vector((-0.72, y, z)), Vector((0.72, y, z)), 0.075, 0.075, mats["wood_light"], 7)

    # Low woven trays and harvest baskets occupy only the rear half of the deck.
    for x in (-3.65, 0.0, 3.65):
        _box("Seed tray", (2.3, 1.1, 0.16), (x, 2.55, 1.76), mats["basket"], 0.06)
        for index in range(3):
            _pod("Nursery seedling pod", Vector((x - 0.58 + index * 0.58, 2.38, 2.16)),
                 (0.22, 0.20, 0.34), mats["pod_light"], mats["edge"])

    # A single asymmetrical trunk forks above the entrance. Tapered, curved
    # branches leave the work bay clear and carry distinct leaf clusters.
    trunk_points = [Vector((0.0, 1.65, 1.25)), Vector((-0.50, 1.55, 4.7)),
                    Vector((0.35, 1.35, 8.25)), Vector((0.9, 1.15, 12.3)),
                    Vector((1.35, 1.05, 17.25))]
    trunk_radii = [1.18, 1.02, 0.72, 0.48, 0.21]
    for index in range(len(trunk_points) - 1):
        _beam("Twisted nursery trunk", trunk_points[index], trunk_points[index + 1],
              trunk_radii[index], trunk_radii[index + 1], mats["wood"], 12)
        # A close spiral companion root gives the trunk a braided, cultivated join.
        if index < 3:
            offset = Vector((0.48 if index % 2 == 0 else -0.48, 0.12, 0.0))
            _beam("Braided trunk strand", trunk_points[index] + offset,
                  trunk_points[index + 1] - offset * 0.35,
                  trunk_radii[index] * 0.22, trunk_radii[index + 1] * 0.18, mats["wood_light"], 7)

    root_endpoints = [Vector((-11.6, -1.9, 0.13)), Vector((11.6, -1.9, 0.13)),
                      Vector((-10.9, 4.3, 0.13)), Vector((10.9, 4.3, 0.13)),
                      Vector((-7.3, -4.55, 0.12)), Vector((7.3, -4.55, 0.12))]
    for index, end in enumerate(root_endpoints):
        start = trunk_points[0] + Vector((0.0, 0.0, 0.15))
        mid = Vector((end.x * 0.55, end.y * 0.42 + 1.4, 0.55))
        _beam("Splayed anchoring root", start, mid, 0.54, 0.30, mats["wood"], 10)
        _beam("Tapered root tip", mid, end, 0.30, 0.075, mats["wood_light"], 9)

    # Two separated living supports frame the entry without closing it.
    for side in (-1.0, 1.0):
        _beam("Open work-bay side support", Vector((side * 3.3, -3.4, 0.15)),
              Vector((side * 2.1, -1.8, 5.5)), 0.42, 0.23, mats["wood"], 9)

    # Curved horizontal boughs establish an irregular tree silhouette. Individual
    # thick leaves have separate plum undersides; no leaf cards or sphere crown.
    clusters = [
        # (center, radius, leaf count, base length, base width, phase, tier)
        (Vector((-6.0, 1.2, 8.8)), 3.7, 3, 5.2, 1.55, 0.18, 0),
        (Vector((6.4, 1.45, 9.6)), 3.8, 3, 5.4, 1.60, 0.62, 1),
        (Vector((0.4, 1.1, 13.0)), 4.4, 4, 4.9, 1.55, 0.28, 2),
        (Vector((1.9, 1.0, 16.0)), 2.5, 3, 3.8, 1.35, 0.75, 3),
    ]
    pod_points: list[Vector] = []
    for cluster_index, (center, radius, leaf_count, length, width, phase, tier) in enumerate(clusters):
        for leaf_index in range(leaf_count):
            angle = math.tau * leaf_index / leaf_count + phase
            radial = Vector((math.cos(angle), math.sin(angle), 0.0))
            tip = center + radial * radius
            tip.z += 0.35 * math.sin(angle * 2.0 + phase)
            _beam("Canopy branch", center + Vector((0, 0, -0.55)), tip,
                  0.31 if tier < 2 else 0.23, 0.105, mats["wood_light"], 8)
            leaf_center = center + radial * (radius * 0.56) + Vector((0.0, 0.0, 0.17))
            _leaf("Thick individual nursery leaf", leaf_center,
                  length * (0.90 + 0.10 * math.sin(leaf_index * 2.7 + tier)),
                  width * (0.88 + 0.12 * math.cos(leaf_index * 1.9)), angle,
                  mats["leaf"] if (leaf_index + tier) % 2 else mats["leaf_light"],
                  mats["plum"], mats["wood_dark"], tilt=0.22 * math.sin(angle + tier),
                  arch=0.52 + 0.12 * math.cos(angle * 2.0), vein_material=mats["edge"],
                  pitch=-0.70 if math.sin(angle) > 0.25 else 0.10)
            if leaf_index == leaf_count - 1:
                # Face harvest clusters toward the front approach and leave a
                # readable gap between pod silhouettes and the green canopy.
                pod_points.extend([tip + Vector((-0.42, -0.24, -1.10)),
                                   tip + Vector((0.42, -0.24, -1.10))])

    for index, point in enumerate(pod_points):
        # One or two prominent pods per branch cluster; their ochre is broad
        # enough to survive the settlement view without turning into a fringe.
        _beam("Seed pod stem", point + Vector((0.0, 0.0, 0.86)), point,
              0.055, 0.04, mats["wood_dark"], 6)
        _pod("Large hanging harvest pod", point - Vector((0, 0, 0.84)),
             (0.53, 0.48, 1.52), mats["pod"], mats["pod_light"])

    # Retain one visible flower accent at the crown; it is static presentation art.
    for petal_index in range(5):
        angle = math.tau * petal_index / 5.0
        _leaf("Small plum crown bloom", Vector((1.35, 1.0, 17.1)) + Vector((0, 0, 0.0)),
              1.25, 0.72, angle, mats["plum"], mats["leaf"], mats["edge"],
              tilt=0.52, arch=0.32)

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    # Blender authors in X(width), Y(depth), Z(height), while RoomDefinition
    # stores Godot X(width), Y(height), Z(depth). Keep this living structure
    # inside the workshop's real 26 x 10 x 18 inch presentation volume.
    for obj in meshes:
        obj.location.y *= depth_scale
        obj.location.z *= height_scale
        for vertex in obj.data.vertices:
            vertex.co.y *= depth_scale
            vertex.co.z *= height_scale
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    authored_mesh_count = len(meshes)
    bpy.ops.object.join()
    joined = bpy.context.object
    joined.name = "Verdant Growth Nursery"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    glb_path = output / "verdant_nursery.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb_path), export_format="GLB", use_selection=True,
                              export_apply=True, export_materials="EXPORT", export_yup=True,
                              export_texcoords=True, export_normals=True, export_tangents=True,
                              export_cameras=False, export_lights=False)
    material_names = {material.name: material.name for material in joined.data.materials}
    record = {
        "asset_id": "verdant_nursery",
        "method": "asymmetrical_branched_cultivation_tree_with_thick_individual_leaves",
        "approved_visual_target": approved_target,
        "envelope_inches": [24.0, 9.3, 16.8],
        "presentation_only": True,
        "gameplay_changes": False,
        "deterministic_seed": seed,
        "material_names": material_names,
        "authored_mesh_object_count_before_merge": authored_mesh_count,
        "geometry_features": [
            "asymmetrical braided trunk with six splayed support roots",
            "four separated tiers of curved individually thick leaves with plum undersides",
            "large ochre hanging seed pods and restrained crown bloom",
            "open ground-level front work bay with potting surface, raised rear platform and entry ladder",
        ],
        "output": glb_path.name,
        "generated_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
    }
    (output / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"VERDANT_NURSERY_GENERATED {glb_path} source_meshes={authored_mesh_count} joined_meshes=1")
    return authored_mesh_count, material_names


def main(output: Path) -> None:
    _build(output)


if __name__ == "__main__":
    main(Path(sys.argv[-1]).resolve())
