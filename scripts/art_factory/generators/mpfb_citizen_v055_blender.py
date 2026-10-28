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
import numpy as np
from mathutils import Vector


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


def _derive_pbr_maps(project_root: Path, output_dir: Path) -> tuple[Path, Path]:
    suit_dir = project_root / ".tools/makehuman_system_assets-data/clothes/toigo_male_suit_3"
    specular_source = _image(suit_dir / "NewSuit3-spec.png", non_color=True)
    normal_path = output_dir / "materials/suit_normal.png"
    normal_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(suit_dir / "NewSuit3-norm.png", normal_path)

    spec_width, spec_height = (int(v) for v in specular_source.size)
    spec = np.asarray(specular_source.pixels[:], dtype=np.float32).reshape(spec_height, spec_width, 4)[..., :3].mean(axis=2)
    roughness = np.clip(1.0 - np.sqrt(np.maximum(spec, 0.0)), 0.25, 0.95)
    roughness = np.repeat(roughness[..., None], 3, axis=2)
    roughness = np.concatenate((roughness, np.ones((*roughness.shape[:2], 1), dtype=np.float32)), axis=-1)
    roughness_path = output_dir / "materials/suit_roughness.png"
    _save_map(roughness_path, roughness)
    specular_source.pack()
    return normal_path, roughness_path


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


def _attach_to_head(obj, rig) -> None:
    world = obj.matrix_world.copy()
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.matrix_world = world
    armature = obj.modifiers.new("MPFB head skin", "ARMATURE")
    armature.object = rig
    head = obj.vertex_groups.new(name="head")
    head.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")


def _add_clockwork_cap_details(rig, fedora, brass_material) -> list[object]:
    bpy.context.view_layer.update()
    bounds = [fedora.matrix_world @ Vector(corner) for corner in fedora.bound_box]
    minimum = Vector((min(v.x for v in bounds), min(v.y for v in bounds), min(v.z for v in bounds)))
    maximum = Vector((max(v.x for v in bounds), max(v.y for v in bounds), max(v.z for v in bounds)))
    dimensions = maximum - minimum
    center = (maximum + minimum) * 0.5
    radius = min(dimensions.x, dimensions.y) * 0.36
    band_z = minimum.z + dimensions.z * 0.69

    bpy.ops.mesh.primitive_torus_add(
        major_segments=48,
        minor_segments=8,
        major_radius=radius,
        minor_radius=max(radius * 0.075, dimensions.z * 0.025),
        location=(center.x, center.y, band_z),
    )
    band = bpy.context.object
    band.name = "RoomScale.ClockworkCapBand"
    band.data.materials.append(brass_material)
    _attach_to_head(band, rig)

    # The v053 gear disappears at the two-inch inspection view. Increase its
    # diameter and add a machined hub so the Clockwork silhouette reads as
    # purpose-built hardware rather than a brass dot.
    gear_radius = min(dimensions.x, dimensions.y) * 0.18
    thickness = gear_radius * 0.22
    gear_center = Vector((maximum.x - dimensions.x * 0.25, center.y + dimensions.y * 0.18, band_z))
    outline: list[tuple[float, float]] = []
    teeth = 12
    for tooth in range(teeth):
        for step, radial in enumerate((0.82, 0.82, 1.0, 1.0)):
            angle = (tooth + step / 4.0) * (2.0 * math.pi / teeth)
            outline.append((math.sin(angle) * gear_radius * radial, math.cos(angle) * gear_radius * radial))
    count = len(outline)
    vertices: list[tuple[float, float, float]] = []
    for x in (gear_center.x - thickness * 0.5, gear_center.x + thickness * 0.5):
        vertices.extend((x, gear_center.y + dy, gear_center.z + dz) for dy, dz in outline)
    faces: list[tuple[int, ...]] = [tuple(range(count)), tuple(range(count, count * 2))]
    for index in range(count):
        following = (index + 1) % count
        faces.append((index, following, following + count, index + count))
    mesh = bpy.data.meshes.new("Clockwork cap gear")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(brass_material)
    gear = bpy.data.objects.new("RoomScale.ClockworkCapGear", mesh)
    bpy.context.collection.objects.link(gear)
    bevel = gear.modifiers.new("Machined gear edge", "BEVEL")
    bevel.width = gear_radius * 0.025
    bevel.segments = 2
    _attach_to_head(gear, rig)

    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=24,
        ring_count=12,
        radius=gear_radius * 0.24,
        location=(gear_center.x + thickness * 0.57, gear_center.y, gear_center.z),
    )
    hub = bpy.context.object
    hub.name = "RoomScale.ClockworkCapGearHub"
    hub.data.materials.append(brass_material)
    for polygon in hub.data.polygons:
        polygon.use_smooth = True
    _attach_to_head(hub, rig)
    return [band, gear, hub]


def _add_clockwork_goggles(rig, glasses, brass_material) -> list[object]:
    """Add oversized fitted brass rims, glass lenses, a bridge, and temples.

    Placement derives from the fitted MPFB glasses bounds, so the metalwork is
    aligned to the generated face instead of relying on a guessed head pose.
    """
    bpy.context.view_layer.update()
    bounds = [glasses.matrix_world @ Vector(corner) for corner in glasses.bound_box]
    minimum = Vector((min(v.x for v in bounds), min(v.y for v in bounds), min(v.z for v in bounds)))
    maximum = Vector((max(v.x for v in bounds), max(v.y for v in bounds), max(v.z for v in bounds)))
    span = maximum - minimum
    lens_radius = min(span.x * 0.205, span.z * 0.57)
    lens_spacing = span.x * 0.24
    lens_z = (minimum.z + maximum.z) * 0.5
    rim_y = minimum.y - lens_radius * 0.10
    centers = (-lens_spacing, lens_spacing)
    details: list[object] = []

    glass = bpy.data.materials.new("RoomScale_Dark_Teal_Goggle_Glass")
    glass.use_nodes = True
    glass_bsdf = next(node for node in glass.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    glass_bsdf.inputs["Base Color"].default_value = (0.018, 0.095, 0.105, 1.0)
    glass_bsdf.inputs["Metallic"].default_value = 0.18
    glass_bsdf.inputs["Roughness"].default_value = 0.13
    if "Coat Weight" in glass_bsdf.inputs:
        glass_bsdf.inputs["Coat Weight"].default_value = 0.45
        glass_bsdf.inputs["Coat Roughness"].default_value = 0.08

    for side, center_x in enumerate(centers):
        bpy.ops.mesh.primitive_torus_add(
            major_segments=48,
            minor_segments=12,
            major_radius=lens_radius,
            minor_radius=lens_radius * 0.15,
            location=(center_x, rim_y, lens_z),
            rotation=(math.pi * 0.5, 0.0, 0.0),
        )
        rim = bpy.context.object
        rim.name = f"RoomScale.BrassGoggleRim{side + 1}"
        rim.data.materials.append(brass_material)
        for polygon in rim.data.polygons:
            polygon.use_smooth = True
        _attach_to_head(rim, rig)
        details.append(rim)

        bpy.ops.mesh.primitive_cylinder_add(
            vertices=48,
            radius=lens_radius * 0.82,
            depth=lens_radius * 0.075,
            location=(center_x, rim_y + lens_radius * 0.12, lens_z),
            rotation=(math.pi * 0.5, 0.0, 0.0),
        )
        lens = bpy.context.object
        lens.name = f"RoomScale.TealGoggleLens{side + 1}"
        lens.data.materials.append(glass)
        bevel = lens.modifiers.new("Polished lens edge", "BEVEL")
        bevel.width = lens_radius * 0.035
        bevel.segments = 2
        _attach_to_head(lens, rig)
        details.append(lens)

    def add_temple(start: Vector, end: Vector, name: str, radius: float) -> object:
        direction = end - start
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=radius,
            depth=direction.length,
            location=(start + end) * 0.5,
        )
        temple = bpy.context.object
        temple.name = name
        temple.rotation_mode = "QUATERNION"
        temple.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())
        temple.data.materials.append(brass_material)
        bevel = temple.modifiers.new("Rounded temple ends", "BEVEL")
        bevel.width = radius * 0.45
        bevel.segments = 2
        _attach_to_head(temple, rig)
        return temple

    add_temple(
        Vector((-lens_spacing - lens_radius, rim_y, lens_z)),
        Vector((-span.x * 0.43, minimum.y * 0.54, lens_z - lens_radius * 0.12)),
        "RoomScale.LeftGoggleTemple",
        lens_radius * 0.095,
    )
    add_temple(
        Vector((lens_spacing + lens_radius, rim_y, lens_z)),
        Vector((span.x * 0.43, minimum.y * 0.54, lens_z - lens_radius * 0.12)),
        "RoomScale.RightGoggleTemple",
        lens_radius * 0.095,
    )
    details.extend(
        obj for obj in bpy.context.scene.objects
        if obj.name in {"RoomScale.LeftGoggleTemple", "RoomScale.RightGoggleTemple"}
    )
    return details


def _join_head_hardware(objects: list[object]):
    """Keep the fitted clockwork additions to one skinned mesh draw per citizen."""
    if not objects:
        raise RuntimeError("Clockwork head hardware was not generated")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    combined = bpy.context.view_layer.objects.active
    combined.name = "RoomScale.ClockworkHeadHardware"
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
        ("clothes/toigo_male_suit_3/toigo_male_suit_3.mhclo", "Clothes"),
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

    suit_normal, suit_roughness = _derive_pbr_maps(project_root, output_dir)
    textures = {
        "human": (asset_root / "skins/young_caucasian_male/young_lightskinned_male_diffuse.png", 0.62, 0.0, None, None),
        "toigo_male_suit_3": (asset_root / "clothes/toigo_male_suit_3/NewSuit3.png", 0.72, 0.0, suit_normal, suit_roughness),
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
    brass_bsdf.inputs["Base Color"].default_value = (0.52, 0.29, 0.075, 1.0)
    brass_bsdf.inputs["Metallic"].default_value = 0.82
    brass_bsdf.inputs["Roughness"].default_value = 0.28
    fedora = next((obj for obj in imported if "fedora" in obj.name.lower()), None)
    if fedora is None:
        raise RuntimeError("MPFB2 did not return the fitted fedora object")
    cap_details = _add_clockwork_cap_details(rig, fedora, brass)
    glasses = next((obj for obj in imported if "glasses" in obj.name.lower()), None)
    if glasses is None:
        raise RuntimeError("MPFB2 did not return the fitted glasses object")
    goggle_details = _add_clockwork_goggles(rig, glasses, brass)
    cap_detail_names = [obj.name for obj in cap_details]
    goggle_detail_names = [obj.name for obj in goggle_details]
    head_hardware = _join_head_hardware(cap_details + goggle_details)

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
        "candidate_id": "citizen-v055",
        "strategy_identity": "MPFB2_fitted_character_with_batched_clockwork_head_hardware_and_compact_leg_animation_mapping",
        "method": "MPFB2 human basemesh + fitted CC0 garments + verified suit PBR + one head-weighted brass/glass hardware mesh + reduced leg pivot gain with unchanged arm/equipment motion",
        "tool_versions": {"blender": bpy.app.version_string, "mpfb2": str(_package.VERSION)},
        "created_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
        "assets": [entry[0] for entry in clothing],
        "skin_asset": "skins/young_caucasian_male/young_caucasian_male.mhmat",
        "license": "MPFB2 GPL-3.0 generator; all selected MakeHuman system, suits, glasses, gloves, shoes, and eyes assets are marked CC0 by their asset pack terms.",
        "rig": {"name": "game_engine", "bones": [bone.name for bone in rig.data.bones]},
        "meshes": mesh_stats,
        "pbr_maps": ["materials/suit_normal.png", "materials/suit_roughness.png"],
        "clockwork_cap_details": cap_detail_names,
        "clockwork_goggle_details": goggle_detail_names,
        "batched_head_hardware_mesh": head_hardware.name,
        "output": {"path": "citizen.glb", "bytes": output.stat().st_size, "sha256": _sha256(output)},
    }
    (output_dir / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print("ROOMSCALE_MPFB_CITIZEN_V055_GENERATION_PASS", json.dumps({"mesh_count": len(mesh_stats), "total_triangles": sum(m["triangles"] for m in mesh_stats), "glb_bytes": output.stat().st_size, "batched_head_hardware": head_hardware.name}))


if __name__ == "__main__":
    main()
