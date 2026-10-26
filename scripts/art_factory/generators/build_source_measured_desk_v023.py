"""Build a source-measured, component-authored standing desk in Blender."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[3]
TARGET_BOUNDS = (66.0, 30.0, 30.0)
TEXTURE_SIZE = 1024


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bake_surface_maps(output_root: Path, seed: int) -> dict[str, dict[str, str]]:
    rng = np.random.default_rng(seed)
    maps: dict[str, dict[str, str]] = {}
    for name, base, roughness, albedo_sigma, roughness_sigma, grain in (
        ("smoked-glass", (78, 85, 89), 0.085, 0.7, 0.006, 0.0),
        ("graphite-metal", (56, 61, 64), 0.31, 2.2, 0.028, 1.0),
    ):
        size = TEXTURE_SIZE
        broad = rng.normal(0.0, 0.35, (64, 64)).astype(np.float32)
        broad_img = Image.fromarray(np.uint8(np.clip(127 + broad * 24, 0, 255)), mode="L")
        broad_noise = np.asarray(
            broad_img.resize((size, size), Image.Resampling.BICUBIC), dtype=np.float32
        )
        fine = rng.normal(0.0, albedo_sigma, (size, size)).astype(np.float32)
        albedo = np.empty((size, size, 3), dtype=np.uint8)
        for channel, value in enumerate(base):
            albedo[:, :, channel] = np.uint8(
                np.clip(value + fine + (broad_noise - 127.0) * 0.025, 0, 255)
            )

        rough_fine = rng.normal(0.0, roughness_sigma * 0.25, (size, size)).astype(np.float32)
        rough_broad = (broad_noise - 127.0) * (roughness_sigma / 18.0)
        rough = np.clip(roughness + rough_fine + rough_broad, 0.035, 0.92)

        if grain:
            # Fine, low-contrast horizontal brushing is visible only in highlights.
            streaks = np.zeros((size, size), dtype=np.float32)
            for y in rng.integers(0, size, size // 3):
                x0 = int(rng.integers(0, size // 3))
                x1 = min(size, x0 + int(rng.integers(size // 8, size // 2)))
                streaks[y, x0:x1] = rng.uniform(-0.8, 0.8)
            for channel, value in enumerate(base):
                albedo[:, :, channel] = np.uint8(
                    np.clip(albedo[:, :, channel].astype(np.float32) + streaks * grain, 0, 255)
                )
            rough = np.clip(rough + streaks * 0.0015, 0.035, 0.92)

        albedo_path = output_root / f"{name}-albedo.png"
        roughness_path = output_root / f"{name}-roughness.png"
        normal_path = output_root / f"{name}-normal.png"
        Image.fromarray(albedo, mode="RGB").save(albedo_path)
        Image.fromarray(np.uint8(rough * 255.0), mode="L").save(roughness_path)
        height_low = rng.normal(0.0, 0.12 if grain else 0.01, (128, 128)).astype(np.float32)
        height = np.asarray(
            Image.fromarray(np.uint8(np.clip(127.0 + height_low * 70.0, 0, 255)), mode="L").resize(
                (size, size), Image.Resampling.BICUBIC
            ),
            dtype=np.float32,
        )
        if grain:
            # Fine anisotropic brushing follows the long axis of the frame.
            for y in rng.integers(0, size, size // 2):
                x0 = int(rng.integers(0, size // 4))
                x1 = min(size, x0 + int(rng.integers(size // 12, size // 3)))
                height[y, x0:x1] += rng.uniform(-1.8, 1.8)
        slope_y, slope_x = np.gradient(height)
        normal_strength = 0.02 if grain else 0.0
        normal = np.stack(
            (-slope_x * normal_strength, -slope_y * normal_strength, np.full_like(height, 1.0)),
            axis=-1,
        )
        normal /= np.maximum(np.linalg.norm(normal, axis=-1, keepdims=True), 1e-6)
        normal_rgb = np.uint8(np.clip((normal * 0.5 + 0.5) * 255.0, 0, 255))
        Image.fromarray(normal_rgb, mode="RGB").save(normal_path)
        maps[name] = {
            "albedo": albedo_path.name,
            "albedo_sha256": sha256(albedo_path),
            "roughness": roughness_path.name,
            "roughness_sha256": sha256(roughness_path),
            "normal": normal_path.name,
            "normal_sha256": sha256(normal_path),
        }
    return maps


def make_material(bpy, name: str, base, metallic: float, roughness: float, texture=None):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*base, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if name == "Smoked Glass PBR":
        coat = principled.inputs.get("Coat Weight")
        if coat:
            coat.default_value = 0.48
        coat_roughness = principled.inputs.get("Coat Roughness")
        if coat_roughness:
            coat_roughness.default_value = 0.08
        ior = principled.inputs.get("IOR")
        if ior:
            ior.default_value = 1.50
    if texture:
        base_image = bpy.data.images.load(str(texture[0]))
        rough_image = bpy.data.images.load(str(texture[1]))
        normal_image = bpy.data.images.load(str(texture[2]))
        rough_image.colorspace_settings.name = "Non-Color"
        normal_image.colorspace_settings.name = "Non-Color"
        base_node = material.node_tree.nodes.new("ShaderNodeTexImage")
        base_node.image = base_image
        rough_node = material.node_tree.nodes.new("ShaderNodeTexImage")
        rough_node.image = rough_image
        normal_node = material.node_tree.nodes.new("ShaderNodeTexImage")
        normal_node.image = normal_image
        tangent_normal = material.node_tree.nodes.new("ShaderNodeNormalMap")
        material.node_tree.links.new(base_node.outputs["Color"], principled.inputs["Base Color"])
        material.node_tree.links.new(rough_node.outputs["Color"], principled.inputs["Roughness"])
        material.node_tree.links.new(normal_node.outputs["Color"], tangent_normal.inputs["Color"])
        material.node_tree.links.new(tangent_normal.outputs["Normal"], principled.inputs["Normal"])
        base_image.pack()
        rough_image.pack()
        normal_image.pack()
    return material


def beveled_box(bpy, name, center, dimensions, bevel, material, segments=4):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Manufactured edge radii", "BEVEL")
    modifier.width = bevel
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    modifier.harden_normals = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = len(polygon.vertices) <= 4
    normal = obj.modifiers.new("Weighted face normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True
    bpy.ops.object.modifier_apply(modifier=normal.name)
    return obj


def cylinder(bpy, name, center, radius, depth, material, vertices=24, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        end_fill_type="NGON",
        location=center,
        rotation=rotation or (0.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("Turned edge radius", "BEVEL")
    bevel.width = min(radius * 0.18, depth * 0.12)
    bevel.segments = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = len(polygon.vertices) == 4
    return obj


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--seed", type=int, default=231019)
    args = parser.parse_args()
    output_root = Path(args.output).resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(PROJECT_ROOT / ".tools" / "bpy-site"))
    import bpy
    from mathutils import Vector

    bpy.ops.wm.read_factory_settings(use_empty=True)
    map_manifest = bake_surface_maps(output_root, args.seed)
    glass_map = map_manifest["smoked-glass"]
    metal_map = map_manifest["graphite-metal"]
    materials = {
        "glass": make_material(
            bpy,
            "Smoked Glass PBR",
            (0.075, 0.085, 0.09),
            0.0,
            0.085,
            (
                output_root / glass_map["albedo"],
                output_root / glass_map["roughness"],
                output_root / glass_map["normal"],
            ),
        ),
        "graphite": make_material(
            bpy,
            "Graphite Powder Coat PBR",
            (0.032, 0.038, 0.042),
            0.66,
            0.31,
            (
                output_root / metal_map["albedo"],
                output_root / metal_map["roughness"],
                output_root / metal_map["normal"],
            ),
        ),
        "steel": make_material(bpy, "Satin Steel Hardware", (0.29, 0.32, 0.33), 0.84, 0.28),
        "rubber": make_material(bpy, "Molded Rubber Feet", (0.012, 0.015, 0.017), 0.0, 0.82),
        "edge": make_material(bpy, "Smoked Edge Laminate", (0.018, 0.024, 0.028), 0.24, 0.20),
    }

    objects = []
    # One thin, radiused glass plane; dimensions and floor datum match RoomDefinition.
    objects.append(
        beveled_box(
            bpy, "GlassTop", (0.0, 29.78, 0.0), (65.8, 0.44, 29.8), 0.06, materials["glass"], 3
        )
    )
    objects.append(
        beveled_box(
            bpy, "GlassEdgeBand", (0.0, 29.54, 0.0), (66.0, 0.18, 30.0), 0.055, materials["edge"], 3
        )
    )

    leg_x = (-22.5, 22.5)
    for side_index, x in enumerate(leg_x, start=1):
        # Telescoping steel legs use two independently modeled nested sections.
        objects.append(
            beveled_box(
                bpy,
                f"LiftColumnOuter_{side_index}",
                (x, 9.4, 0.0),
                (3.4, 15.9, 2.35),
                0.22,
                materials["graphite"],
                5,
            )
        )
        objects.append(
            beveled_box(
                bpy,
                f"LiftColumnInner_{side_index}",
                (x, 22.60, 0.0),
                (2.62, 11.60, 1.78),
                0.16,
                materials["graphite"],
                5,
            )
        )
        objects.append(
            beveled_box(
                bpy,
                f"ColumnSleeve_{side_index}",
                (x, 17.0, 0.0),
                (3.58, 0.52, 2.52),
                0.12,
                materials["graphite"],
                5,
            )
        )
        # Broad depth-spanning T-feet with radiused ends and concealed rubber pads.
        objects.append(
            beveled_box(
                bpy,
                f"TFootRail_{side_index}",
                (x, 0.92, 0.0),
                (4.25, 1.05, 25.8),
                0.36,
                materials["graphite"],
                8,
            )
        )
        for end_index, z in enumerate((-11.7, 11.7), start=1):
            objects.append(
                beveled_box(
                    bpy,
                    f"FootEndCap_{side_index}_{end_index}",
                    (x, 0.90, z),
                    (4.05, 0.74, 1.7),
                    0.32,
                    materials["edge"],
                    8,
                )
            )
            cylinder(
                bpy,
                f"Leveler_{side_index}_{end_index}",
                (x, 0.15, z),
                0.64,
                0.30,
                materials["rubber"],
                vertices=32,
                rotation=(math.radians(90.0), 0.0, 0.0),
            )
        # Top flanges and eight seated steel fasteners per lift assembly.
        objects.append(
            beveled_box(
                bpy,
                f"TopFlange_{side_index}",
                (x, 28.55, 0.0),
                (6.5, 0.30, 5.7),
                0.16,
                materials["graphite"],
                4,
            )
        )
        objects.append(
            beveled_box(
                bpy,
                f"MountPlate_{side_index}",
                (x, 28.80, 0.0),
                (5.4, 0.20, 4.5),
                0.12,
                materials["steel"],
                3,
            )
        )
        objects.append(
            beveled_box(
                bpy,
                f"TopSpacer_{side_index}",
                (x, 29.14, 0.0),
                (4.8, 0.55, 3.8),
                0.16,
                materials["graphite"],
                4,
            )
        )
        objects.append(
            beveled_box(
                bpy,
                f"GlassIsolationPad_{side_index}",
                (x, 29.48, 0.0),
                (4.7, 0.16, 3.7),
                0.10,
                materials["rubber"],
                4,
            )
        )
        for bolt_index, (dx, dz) in enumerate(
            ((-1.8, -1.35), (-1.8, 1.35), (1.8, -1.35), (1.8, 1.35)), start=1
        ):
            cylinder(
                bpy,
                f"MountBolt_{side_index}_{bolt_index}",
                (x + dx, 28.94, dz),
                0.19,
                0.15,
                materials["steel"],
                vertices=20,
                rotation=(math.radians(90.0), 0.0, 0.0),
            )

    # Under-top cross-support and a separate open ladder-style cable pan.
    objects.append(
        beveled_box(
            bpy,
            "RearCrossRail",
            (0.0, 28.55, 5.0),
            (46.0, 1.15, 2.0),
            0.18,
            materials["graphite"],
            5,
        )
    )
    objects.append(
        beveled_box(
            bpy,
            "FrontCrossRail",
            (0.0, 28.55, -5.0),
            (46.0, 1.15, 2.0),
            0.18,
            materials["graphite"],
            5,
        )
    )
    objects.append(
        beveled_box(
            bpy,
            "CableTraySideRailLeft",
            (0.0, 27.62, -1.75),
            (31.0, 0.52, 0.42),
            0.14,
            materials["graphite"],
            4,
        )
    )
    objects.append(
        beveled_box(
            bpy,
            "CableTraySideRailRight",
            (0.0, 27.62, 1.75),
            (31.0, 0.52, 0.42),
            0.14,
            materials["graphite"],
            4,
        )
    )
    for slat_index, x in enumerate(np.linspace(-14.0, 14.0, 9), start=1):
        objects.append(
            beveled_box(
                bpy,
                f"CableTrayCrossSlat_{slat_index}",
                (float(x), 27.62, 0.0),
                (0.32, 0.48, 3.20),
                0.10,
                materials["graphite"],
                3,
            )
        )

    # Small front-mounted lift switch, two raised buttons, and a strain-relief lead.
    objects.append(
        beveled_box(
            bpy,
            "LiftControllerHousing",
            (24.0, 28.88, -14.42),
            (7.2, 0.78, 0.62),
            0.26,
            materials["graphite"],
            8,
        )
    )
    objects.append(
        beveled_box(
            bpy,
            "ControllerBezel",
            (24.0, 29.05, -14.48),
            (5.5, 0.20, 0.38),
            0.12,
            materials["edge"],
            5,
        )
    )
    for button_index, x in enumerate((22.9, 25.1), start=1):
        cylinder(
            bpy,
            f"LiftButton_{button_index}",
            (x, 29.18, -14.49),
            0.24,
            0.12,
            materials["steel"],
            vertices=20,
            rotation=(math.radians(90.0), 0.0, 0.0),
        )
    objects.append(
        beveled_box(
            bpy,
            "CableStrainRelief",
            (27.3, 28.50, -13.4),
            (0.42, 0.65, 1.8),
            0.18,
            materials["rubber"],
            4,
        )
    )

    # Apply a consistent UV layout, preserve the separate material slots, and
    # join the assembly into one efficient renderable mesh with disconnected parts.
    component_names = [obj.name for obj in objects]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    assembly = bpy.context.view_layer.objects.active
    assembly.name = "DeskAssembly_ComponentAuthored"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(67.0), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    for polygon in assembly.data.polygons:
        polygon.use_smooth = len(polygon.vertices) <= 4

    root = bpy.data.objects.new("DeskAsset", None)
    bpy.context.collection.objects.link(root)
    assembly.parent = root
    assembly.matrix_parent_inverse = root.matrix_world.inverted()
    root.location = (0.0, 0.0, 0.0)
    # Component coordinates above use RoomScale's Y-up convention. Blender's
    # scene basis is Z-up, so rotate the assembly into Blender's basis before
    # glTF export; otherwise a horizontal tabletop is exported vertically.
    root.rotation_euler[0] = math.radians(90.0)

    wrapper_path = output_root / "desk_reflection_wrapper.gd"
    wrapper_path.write_text(
        "extends Node3D\n\n"
        "func _ready() -> void:\n"
        '\tfor item in find_children("*", "MeshInstance3D", true, false):\n'
        "\t\t(item as MeshInstance3D).layers = 2\n",
        encoding="utf-8",
    )
    glb_path = output_root / "desk.glb"
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    assembly.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )

    minimum = Vector((-33.0, 0.0, -15.0))
    maximum = Vector((33.0, 30.0, 15.0))
    metrics = {
        "method": "source-measured component-authored Blender PBR assembly",
        "axis_convention": "RoomScale X=width, Y=height, Z=depth; transformed from Y-up authoring into Blender Z-up before glTF export",
        "target_bounds_inches": {
            "min": list(minimum),
            "max": list(maximum),
            "dimensions": list(maximum - minimum),
        },
        "component_names": component_names,
        "component_count_before_join": len(objects),
        "joined_mesh_count": 1,
        "triangle_count": sum(max(len(poly.vertices) - 2, 1) for poly in assembly.data.polygons),
        "uv_mapped": bool(assembly.data.uv_layers),
        "materials": {
            "glass": "smoked glass with exported albedo and roughness textures; dielectric clearcoat",
            "frame": "graphite powder-coated steel with exported albedo and roughness textures",
            "hardware": "satin steel metallic-roughness PBR",
            "feet": "high-roughness molded rubber PBR",
        },
        "material_maps": map_manifest,
        "glb_sha256": sha256(glb_path),
    }
    metrics_path = output_root / "model-metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")
    manifest_path = output_root / "pbr-material-manifest.json"
    manifest_path.write_text(json.dumps(map_manifest, indent=2) + "\n", encoding="utf-8")

    scene_path = output_root / "desk.tscn"
    scene_relative = "res://" + output_root.relative_to(PROJECT_ROOT).as_posix()
    scene_path.write_text(
        "[gd_scene load_steps=3 format=3]\n\n"
        f'[ext_resource type="PackedScene" path="{scene_relative}/desk.glb" id="1_glb"]\n'
        f'[ext_resource type="Script" path="{scene_relative}/desk_reflection_wrapper.gd" id="2_script"]\n\n'
        '[node name="DeskAsset" instance=ExtResource("1_glb")]\n'
        'script = ExtResource("2_script")\n\n'
        '[node name="RoomReflectionProbe" type="ReflectionProbe" parent="."]\n'
        "position = Vector3(0, 15, 0)\n"
        "size = Vector3(90, 70, 90)\n"
        "intensity = 1.5\n"
        "box_projection = true\n"
        "cull_mask = 1\n"
        "update_mode = 0\n",
        encoding="utf-8",
    )

    record = {
        "method": "source_measured_component_authored_blender_pbr",
        "tool": "Blender Python/bpy local DCC plus RoomScale Godot Art Factory",
        "tool_version": "bpy 5.2.3; source model built without third-party generative weights",
        "seed": args.seed,
        "source_photo": "photo_holder/Sample (2).jpg",
        "target_bounds_inches": [66.0, 30.0, 30.0],
        "component_count_before_join": len(objects),
        "component_names": component_names,
        "geometry": {
            "triangles": metrics["triangle_count"],
            "glb_sha256": metrics["glb_sha256"],
        },
        "material_maps": map_manifest,
        "runtime_dependencies": "none; Blender authoring code is development-time only",
    }
    (output_root / "generation-record.json").write_text(
        json.dumps(record, indent=2) + "\n", encoding="utf-8"
    )
    print("ROOMSCALE_SOURCE_MEASURED_DESK_GENERATION_PASS " + json.dumps(record))


if __name__ == "__main__":
    main()
