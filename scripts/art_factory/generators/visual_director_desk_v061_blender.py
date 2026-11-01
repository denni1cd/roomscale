"""Build the Visual Director desk target as a component-authored Blender GLB."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[3]
BLENDER_EXE = Path(
    r"C:\Users\Zero\python_projects\ai\roomscale\.tools\blender-5.2.3\blender-5.2.3-windows-x64\blender.exe"
)
try:
    import bpy  # type: ignore[import-not-found]
    IN_BLENDER = True
except ImportError:
    bpy = None  # type: ignore[assignment]
    IN_BLENDER = False


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _material(name: str, color: tuple[float, float, float], metallic: float, roughness: float,
              alpha: float = 1.0, clearcoat: float = 0.0) -> "bpy.types.Material":
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, alpha)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Alpha"].default_value = alpha
    coat = shader.inputs.get("Coat Weight")
    if coat:
        coat.default_value = clearcoat
    coat_roughness = shader.inputs.get("Coat Roughness")
    if coat_roughness:
        coat_roughness.default_value = min(roughness, 0.12)
    ior = shader.inputs.get("IOR")
    if ior and name == "Smoked Glass":
        ior.default_value = 1.5
    return mat


def _beveled_box(name: str, center: tuple[float, float, float],
                 dimensions: tuple[float, float, float], radius: float,
                 material: "bpy.types.Material", segments: int = 4):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Manufactured radiused edges", "BEVEL")
    bevel.width = min(radius, min(dimensions) * 0.45)
    bevel.segments = segments
    bevel.limit_method = "ANGLE"
    bevel.harden_normals = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    normal = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True
    bpy.ops.object.modifier_apply(modifier=normal.name)
    for poly in obj.data.polygons:
        poly.use_smooth = len(poly.vertices) <= 4
    obj.data.materials.append(material)
    return obj


def _cylinder(name: str, center: tuple[float, float, float], radius: float,
              depth: float, material: "bpy.types.Material", vertices: int = 24,
              axis: str = "Y"):
    # Cylinders default to Blender's Z axis; turn the levelers onto RoomScale Y.
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=center,
        rotation=(math.radians(90.0), 0.0, 0.0) if axis == "Y" else (0.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("Soft turned rim", "BEVEL")
    bevel.width = min(radius * 0.16, depth * 0.18)
    bevel.segments = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for poly in obj.data.polygons:
        poly.use_smooth = len(poly.vertices) == 4
    return obj


def _build(output_dir: Path, reference: Path) -> None:
    from mathutils import Vector

    bpy.ops.wm.read_factory_settings(use_empty=True)
    # The first Godot render showed that the darker GLTF base factors became
    # unreadable in RoomScale's Compatibility renderer. Match the proven v007
    # values for the same material classes while retaining v059's new geometry.
    glass = _material("Smoked Glass", (0.1882353, 0.227451, 0.239216), 0.08, 0.08, 0.58, 0.98)
    graphite = _material("Graphite Powder-Coated Steel", (0.1411765, 0.164706, 0.172549), 0.82, 0.28)
    satin = _material("Satin Steel Fittings", (0.572549, 0.615686, 0.635294), 0.85, 0.24)
    rubber = _material("Black Rubber Levelers", (0.066667, 0.078431, 0.086275), 0.02, 0.82)

    parts = []
    # RoomScale axis convention: X width, Y height, Z depth; inches are retained.
    parts.append(_beveled_box("Continuous smoked-glass desktop", (0.0, 29.75, 0.0),
                              (66.0, 0.50, 30.0), 0.10, glass, 5))
    # One slim width rail makes the top support and both columns a coherent assembly.
    parts.append(_beveled_box("Slim under-glass support rail", (0.0, 28.76, 0.0),
                              (46.0, 1.30, 1.25), 0.18, graphite, 5))

    for index, x in enumerate((-22.0, 22.0), start=1):
        # Two nested rectangular stages with a short overlap sleeve.
        parts.append(_beveled_box(f"Lift column lower stage {index}", (x, 8.80, 0.0),
                                  (3.35, 15.10, 2.50), 0.22, graphite, 5))
        parts.append(_beveled_box(f"Lift column upper stage {index}", (x, 22.12, 0.0),
                                  (2.70, 14.10, 1.95), 0.15, graphite, 5))
        parts.append(_beveled_box(f"Telescoping overlap collar {index}", (x, 16.24, 0.0),
                                  (3.60, 0.62, 2.74), 0.12, graphite, 4))

        # Compact underside saddle and isolation pad; no fitting breaks the top glass plane.
        parts.append(_beveled_box(f"Underside column saddle {index}", (x, 29.28, 0.0),
                                  (5.80, 0.24, 5.20), 0.12, graphite, 4))
        parts.append(_beveled_box(f"Glass isolation pad {index}", (x, 29.44, 0.0),
                                  (4.70, 0.08, 4.30), 0.07, rubber, 3))
        # Two small fasteners are on the front-facing saddle, entirely below the glass.
        for bolt_index, dx in enumerate((-1.75, 1.75), start=1):
            bolt = _cylinder(f"Underside saddle fastener {index}-{bolt_index}",
                             (x + dx, 29.28, -2.64), 0.13, 0.08, satin, 20, axis="Z")
            parts.append(bolt)

        # Each broad low T-foot spans desk depth and carries two concealed levelers.
        parts.append(_beveled_box(f"Perpendicular T-foot rail {index}", (x, 0.82, 0.0),
                                  (3.45, 0.96, 24.0), 0.34, graphite, 7))
        for end_index, z in enumerate((-10.65, 10.65), start=1):
            parts.append(_cylinder(f"Rubber foot leveler {index}-{end_index}",
                                   (x, 0.18, z), 0.50, 0.36, rubber, 28))

    # Export as a Y-up GLB with the mesh components retained as separate scene nodes.
    root = bpy.data.objects.new("RoomScale Desk", None)
    bpy.context.collection.objects.link(root)
    for part in parts:
        part.parent = root
        part.matrix_parent_inverse = root.matrix_world.inverted()
    root.rotation_euler[0] = math.radians(90.0)

    output_dir.mkdir(parents=True, exist_ok=True)
    glb = output_dir / "desk.glb"
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(glb),
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
    if not glb.is_file() or glb.stat().st_size < 1024:
        raise RuntimeError(f"Blender did not write a usable GLB: {glb}")

    scene_path = output_dir / "desk.tscn"
    relative = "res://" + output_dir.relative_to(PROJECT_ROOT).as_posix()
    wrapper_path = output_dir / "desk_review_wrapper.gd"
    wrapper_source = """extends Node3D

func _ready() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1882353, 0.227451, 0.239216, 0.58)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.08
	glass.roughness = 0.08
	glass.rim_enabled = true
	glass.rim = 0.38
	glass.rim_tint = 0.8
	glass.clearcoat_enabled = true
	glass.clearcoat = 0.98
	glass.clearcoat_roughness = 0.08

	var graphite := StandardMaterial3D.new()
	graphite.albedo_color = Color(0.1411765, 0.164706, 0.172549)
	graphite.metallic = 0.82
	graphite.roughness = 0.28

	var satin := StandardMaterial3D.new()
	satin.albedo_color = Color(0.572549, 0.615686, 0.635294)
	satin.metallic = 0.85
	satin.roughness = 0.24

	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.066667, 0.078431, 0.086275)
	rubber.metallic = 0.02
	rubber.roughness = 0.82

	var assigned := 0
	for item in find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		var label := mesh.name.to_lower().replace("_", " ")
		mesh.layers = 2
		if label.contains("desktop") or label.contains("smoked glass"):
			mesh.material_override = glass
		elif label.contains("leveler") or label.contains("isolation pad"):
			mesh.material_override = rubber
		elif label.contains("fastener"):
			mesh.material_override = satin
		else:
			mesh.material_override = graphite
		assigned += 1
	if assigned != 22:
		push_error("Visual Director material assignment expected 22 meshes, found %d" % assigned)
	else:
		print("ROOMSCALE_VISUAL_DIRECTOR_NATIVE_MATERIALS_PASS meshes=%d" % assigned)
"""
    wrapper_path.write_text(wrapper_source.lstrip(), encoding="utf-8")
    scene_path.write_text(
        "[gd_scene load_steps=3 format=3]\n\n"
        f'[ext_resource type="PackedScene" path="{relative}/desk.glb" id="1_glb"]\n'
        f'[ext_resource type="Script" path="{relative}/desk_review_wrapper.gd" id="2_script"]\n\n'
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

    # Verify the authored-space envelope before export accounting.
    world_corners = [obj.matrix_world @ Vector(corner) for obj in parts for corner in obj.bound_box]
    minimum = [min(getattr(point, axis) for point in world_corners) for axis in ("x", "y", "z")]
    maximum = [max(getattr(point, axis) for point in world_corners) for axis in ("x", "y", "z")]
    extent = [round(maximum[i] - minimum[i], 4) for i in range(3)]
    if any(abs(extent[i] - expected) > 0.05 for i, expected in enumerate((66.0, 30.0, 30.0))):
        raise RuntimeError(f"authored mesh envelope {extent} does not match [66, 30, 30]")
    triangles = sum(max(len(poly.vertices) - 2, 1) for obj in parts for poly in obj.data.polygons)
    record = {
        "candidate_id": os.environ.get("ROOMSCALE_ART_FACTORY_CANDIDATE", "desk-v060"),
        "method": "visual_director_source_constrained_multipart_blender_model",
        "tool": "Blender Python/bpy",
        "tool_version": bpy.app.version_string,
        "visual_target": "art/desk/visual_director/round-01/incumbent-edit-r01.png",
        "source_photo": "photo_holder/Sample (2).jpg",
        "target_bounds_inches": extent,
        "component_count": len(parts),
        "triangle_count": triangles,
        "materials": {
            "top": "smoked dielectric glass with restrained clearcoat",
            "frame": "graphite metallic-roughness powder-coated steel",
            "fittings": "satin steel metallic-roughness PBR",
            "levelers": "high-roughness black rubber",
        },
        "glb_sha256": _sha256(glb),
        "runtime_geometry_authority": "RoomDefinition remains authoritative; asset presentation only",
    }
    (output_dir / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    (output_dir / "model-metrics.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print("ROOMSCALE_VISUAL_DIRECTOR_DESK_GENERATION_PASS " + json.dumps(record))


def main() -> int:
    if IN_BLENDER:
        args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
        parser = argparse.ArgumentParser()
        parser.add_argument("--output", required=True)
        parser.add_argument("--reference", required=True)
        parsed = parser.parse_args(args)
        _build(Path(parsed.output), Path(parsed.reference))
        return 0

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    parser.add_argument("--reference", required=True)
    parser.add_argument("--blender", type=Path, default=BLENDER_EXE)
    parsed = parser.parse_args()
    if not parsed.blender.is_file():
        raise SystemExit(f"Blender executable not found: {parsed.blender}")
    output_dir = Path(parsed.output).resolve()
    reference = Path(parsed.reference).resolve()
    if not reference.is_file():
        raise SystemExit(f"approved visual target is missing: {reference}")
    command = [
        str(parsed.blender), "--background", "--factory-startup", "--python", str(Path(__file__).resolve()),
        "--", "--output", str(output_dir), "--reference", str(reference),
    ]
    result = subprocess.run(command, cwd=PROJECT_ROOT, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
