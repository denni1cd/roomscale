"""Run the MPFB2 character build and package it through the Godot Art Factory path."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> None:
    result = subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True, check=False)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.returncode:
        raise SystemExit(result.returncode)


def main() -> None:
    project_root = Path(sys.argv[1]).resolve()
    output_dir = Path(sys.argv[2]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    blender = project_root / ".tools/blender-5.2.3/blender-5.2.3-windows-x64/blender.exe"
    godot = project_root / ".tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
    source_script = project_root / "scripts/art_factory/generators/mpfb_citizen_v053_blender.py"
    pack_script = "res://scripts/art_factory/generators/write_mpfb_citizen_scene_v053.gd"
    if not blender.is_file() or not godot.is_file() or not source_script.is_file():
        raise SystemExit("MPFB2, Blender 5.2.3, and Godot 4.7.2 must be installed locally")

    local_tools = output_dir / "tooling"
    local_licenses = output_dir / "licenses"
    local_tools.mkdir(parents=True, exist_ok=True)
    local_licenses.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_script, local_tools / source_script.name)
    shutil.copy2(
        project_root / "scripts/art_factory/generators/write_mpfb_citizen_scene_v053.gd",
        local_tools / "write_mpfb_citizen_scene_v053.gd",
    )
    shutil.copy2(
        project_root / "scripts/art_factory/generators/mpfb_citizen_pivots_v053.gd",
        local_tools / "mpfb_citizen_pivots_v053.gd",
    )
    shutil.copy2(Path(__file__), local_tools / Path(__file__).name)
    shutil.copy2(project_root / ".tools/MPFB2/LICENSE.CODE.md", local_licenses / "MPFB2-LICENSE")
    shutil.copy2(
        project_root / ".tools/MPFB2/LICENSE.ASSETS.md",
        local_licenses / "MakeHuman-CC0-assets-license.md",
    )

    run(
        [
            str(blender),
            "--background",
            "--factory-startup",
            "--python",
            str(source_script),
            "--",
            str(project_root),
            str(output_dir),
        ],
        cwd=project_root,
    )

    glb_relative = (output_dir / "citizen.glb").relative_to(project_root).as_posix()
    tscn_relative = (output_dir / "citizen.tscn").relative_to(project_root).as_posix()
    env = os.environ.copy()
    env["ROOMSCALE_MPFB_CITIZEN_GLB_PATH"] = "res://" + glb_relative
    env["ROOMSCALE_MPFB_CITIZEN_TSCN_PATH"] = "res://" + tscn_relative
    run([str(godot), "--headless", "--editor", "--path", str(project_root), "--import"], cwd=project_root, env=env)
    run([str(godot), "--headless", "--path", str(project_root), "--script", pack_script], cwd=project_root, env=env)


if __name__ == "__main__":
    main()
