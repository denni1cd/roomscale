"""Attempt 2: expose the sash latch in front of the centre meeting stile."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path


IN_BLENDER = False
try:
    import bpy  # type: ignore[import-not-found]
    from mathutils import Vector  # type: ignore[import-not-found]

    IN_BLENDER = True
except ImportError:
    bpy = None  # type: ignore[assignment]
    Vector = None  # type: ignore[assignment,misc]


def _load_strategy():
    path = Path(__file__).with_name("visual_director_batch02_blender.py")
    spec = importlib.util.spec_from_file_location("roomscale_visual_director_batch02", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load initial Visual Director strategy: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _corrected_window(base, mats):
    strategy = _load_strategy()
    strategy.build_window(base, mats)
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith("Window central latch") or obj.name.startswith("Window latch fixing screw"):
            bpy.data.objects.remove(obj, do_unlink=True)

    # The v003 lock was placed at the right X/Z coordinate but behind the wide
    # central stile. Move the complete latch onto its front face so it reads in
    # the actual Godot close capture.
    brass = mats["brass"]
    steel = mats["steel"]
    base.box("Window central latch backplate", (0.0, -2.16, 28.62), (1.56, 0.16, 0.58), brass, 0.045)
    base.cylinder("Window central latch pivot", (0.0, -2.28, 28.66), 0.17, 0.22, steel, "Y", 20, 0.025)
    base.box("Window central sash latch lever", (0.0, -2.35, 29.06), (0.22, 0.22, 0.80), brass, 0.07)
    for x in (-0.52, 0.52):
        base.cylinder("Window latch fixing screw", (x, -2.28, 28.62), 0.075, 0.10, steel, "Y", 16, 0.015)


def run_blender_generation(output_path: Path) -> None:
    strategy = _load_strategy()
    strategy.build_window = _corrected_window
    strategy.run_blender_generation("room_photo_window_production", output_path)


def dispatch_to_blender() -> int:
    project_root = Path(__file__).resolve().parents[3]
    output_dir = Path(os.environ["ROOMSCALE_ART_FACTORY_OUTPUT_DIR"])
    output_path = output_dir / "asset.glb"
    blender = os.environ.get("ROOMSCALE_BLENDER_EXECUTABLE", "")
    if not blender:
        raise RuntimeError("ROOMSCALE_BLENDER_EXECUTABLE must point to the approved local Blender install")
    result = subprocess.run(
        [blender, "--background", "--factory-startup", "--python", str(Path(__file__).resolve()), "--", str(output_path)],
        cwd=project_root,
        check=False,
    )
    if result.returncode or not output_path.is_file():
        return result.returncode or 2
    brief = json.loads(Path(os.environ["ROOMSCALE_ART_FACTORY_BRIEF"]).read_text(encoding="utf-8"))
    recipe = json.loads(Path(os.environ["ROOMSCALE_ART_FACTORY_RECIPE"]).read_text(encoding="utf-8"))
    record = {
        "asset_id": "room_photo_window_production",
        "asset_type": "window",
        "method": recipe["method"],
        "tool": "Blender 5.2.3 LTS Python/bpy",
        "generator": "visual_director_window_r02_blender.py",
        "output": "asset.glb",
        "dimensions_inches": brief["intended_dimensions"],
        "source_inputs": recipe.get("source_inputs", []),
        "visual_director_target": recipe["parameters"].get("visual_director_target"),
        "transfer_strategy": recipe["parameters"].get("visual_director_strategy"),
        "geometry": "target-driven double-hung sash assembly with corrected front-mounted latch visibility",
        "materials": "embedded stained-oak PBR and restrained clear-glass response",
    }
    (output_dir / "generation-record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return 0


def main() -> int:
    if IN_BLENDER:
        arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
        if len(arguments) != 1:
            raise SystemExit("Blender invocation requires <output.glb> after --")
        run_blender_generation(Path(arguments[0]))
        return 0
    return dispatch_to_blender()


if __name__ == "__main__":
    raise SystemExit(main())
