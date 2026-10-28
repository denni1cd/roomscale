"""Package one externally generated SUPRA-Tex desk GLB as a RoomScale challenger."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import struct
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_glb(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("GLB is shorter than its header and JSON chunk")
    magic, version, declared_length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or declared_length != len(data):
        raise ValueError("download is not a complete glTF 2.0 binary file")
    json_length, json_type = struct.unpack_from("<I4s", data, 12)
    if json_type != b"JSON" or 20 + json_length > len(data):
        raise ValueError("GLB JSON chunk header is invalid")
    return json.loads(data[20 : 20 + json_length])


def _model_bounds(document: dict[str, Any]) -> tuple[list[float], list[float], int, int]:
    accessors = document.get("accessors", [])
    bounds: list[tuple[list[float], list[float]]] = []
    vertex_count = 0
    triangle_count = 0
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            position_index = primitive.get("attributes", {}).get("POSITION")
            if position_index is None:
                raise ValueError("mesh primitive has no POSITION accessor")
            position = accessors[position_index]
            minimum = position.get("min")
            maximum = position.get("max")
            if not isinstance(minimum, list) or not isinstance(maximum, list):
                raise ValueError("mesh POSITION accessor has no declared bounds")
            bounds.append((minimum, maximum))
            vertex_count += int(position.get("count", 0))
            indices_index = primitive.get("indices")
            if indices_index is None:
                vertex_count_for_primitive = int(position.get("count", 0))
                triangle_count += vertex_count_for_primitive // 3
            else:
                triangle_count += int(accessors[indices_index].get("count", 0)) // 3
    if not bounds:
        raise ValueError("GLB contains no indexed mesh geometry")
    minimum = [min(bound[0][axis] for bound in bounds) for axis in range(3)]
    maximum = [max(bound[1][axis] for bound in bounds) for axis in range(3)]
    if any(maximum[axis] <= minimum[axis] for axis in range(3)):
        raise ValueError("GLB bounds must be positive on all three axes")
    return minimum, maximum, vertex_count, triangle_count


def main() -> int:
    output_dir = Path(os.environ["ROOMSCALE_ART_FACTORY_OUTPUT_DIR"])
    recipe_path = Path(os.environ["ROOMSCALE_ART_FACTORY_RECIPE"])
    candidate_id = os.environ["ROOMSCALE_ART_FACTORY_CANDIDATE"]
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    parameters = recipe["parameters"]
    source = Path(parameters["downloaded_glb"])
    expected_sha = str(parameters["downloaded_glb_sha256"]).lower()
    if not source.is_file():
        raise FileNotFoundError(f"downloaded SUPRA-Tex GLB is missing: {source}")
    actual_sha = _sha256(source)
    if actual_sha != expected_sha:
        raise ValueError(f"download hash mismatch: expected {expected_sha}, got {actual_sha}")

    document = _read_glb(source)
    for node in document.get("nodes", []):
        if any(key in node for key in ("matrix", "translation", "rotation", "scale")):
            raise ValueError(
                "SUPRA-Tex GLB node transforms need explicit composition before packaging"
            )
    minimum, maximum, vertex_count, triangle_count = _model_bounds(document)
    target = [float(value) for value in parameters["target_dimensions_inches_xyz"]]
    source_size = [maximum[axis] - minimum[axis] for axis in range(3)]
    scale = [target[axis] / source_size[axis] for axis in range(3)]
    translation = [-minimum[axis] * scale[axis] for axis in range(3)]

    output_dir.mkdir(parents=True, exist_ok=True)
    glb_output = output_dir / "supra-tex.glb"
    shutil.copy2(source, glb_output)
    version = candidate_id.rsplit("-v", 1)[1]
    generated_scene = (
        "[gd_scene load_steps=2 format=3]\n\n"
        f'[ext_resource type="PackedScene" path="res://art/desk/iterations/v{version}/generated/supra-tex.glb" id="1_mesh"]\n\n'
        '[node name="DeskAsset" instance=ExtResource("1_mesh")]\n'
        "position = Vector3(%s, %s, %s)\n"
        "scale = Vector3(%s, %s, %s)\n"
        % tuple(format(value, ".10g") for value in (*translation, *scale))
    )
    (output_dir / "desk.tscn").write_text(generated_scene, encoding="utf-8")

    record = {
        "candidate_id": candidate_id,
        "method": recipe["method"],
        "recorded_at_utc": datetime.now(UTC).isoformat(timespec="seconds"),
        "remote_space": parameters["remote_space"],
        "space_revision": parameters["space_revision"],
        "gpu": parameters["gpu"],
        "seed": parameters["seed"],
        "remote_run_timestamp_local": parameters["remote_run_timestamp_local"],
        "remote_upload_id": parameters.get("remote_upload_id", "not surfaced by demo UI"),
        "remote_job_id": parameters.get("remote_job_id", "not surfaced by demo UI"),
        "conditioning_image": parameters["conditioning_image"],
        "conditioning_image_sha256": parameters["conditioning_image_sha256"],
        "conditioning_image_provenance": parameters["conditioning_image_provenance"],
        "downloaded_glb_sha256": actual_sha,
        "downloaded_glb_bytes": source.stat().st_size,
        "materials": len(document.get("materials", [])),
        "embedded_images": len(document.get("images", [])),
        "source_bounds": {"minimum": minimum, "maximum": maximum, "size": source_size},
        "normalized_bounds_inches": {
            "minimum": [0.0, 0.0, 0.0],
            "maximum": target,
            "per_axis_scale": scale,
            "translation": translation,
        },
        "vertex_count": vertex_count,
        "triangle_count": triangle_count,
        "visual_evaluation": "pending actual RoomScale production renders",
    }
    (output_dir / "generation-record.json").write_text(
        json.dumps(record, indent=2) + "\n", encoding="utf-8"
    )
    print("ROOMSCALE_SUPRA_TEX_PACKAGE " + json.dumps(record, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
