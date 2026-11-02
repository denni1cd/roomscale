"""Locate local Blender and run the deterministic Scavenger workshop maker."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def find_blender(project_root: Path) -> Path:
    candidates = [
        Path(os.environ["ROOMSCALE_BLENDER_EXECUTABLE"]) if os.environ.get("ROOMSCALE_BLENDER_EXECUTABLE") else None,
        project_root / ".tools/blender-5.2.3/blender-5.2.3-windows-x64/blender.exe",
        Path.home() / "python_projects/ai/roomscale/.tools/blender-5.2.3/blender-5.2.3-windows-x64/blender.exe",
        Path("C:/Program Files/Blender Foundation/Blender 4.5/blender.exe"),
    ]
    for candidate in candidates:
        if candidate is not None and candidate.is_file():
            return candidate.resolve()
    located = shutil.which("blender")
    if located:
        return Path(located).resolve()
    raise FileNotFoundError("Set ROOMSCALE_BLENDER_EXECUTABLE or install Blender 4.5+.")


def main(project_root: Path, output: Path) -> int:
    blender = find_blender(project_root)
    script = project_root / "scripts/art_factory/generators/scavenger_workshop_blender.py"
    command = [
        str(blender),
        "--background",
        "--factory-startup",
        "--python-exit-code",
        "1",
        "--python",
        str(script),
        "--",
        str(project_root),
        str(output),
    ]
    print(f"SCAVENGER_WORKSHOP_BLENDER {blender}", flush=True)
    result = subprocess.run(command, cwd=project_root, text=True, capture_output=True, check=False)
    print(result.stdout, end="", flush=True)
    print(result.stderr, end="", file=sys.stderr, flush=True)
    return result.returncode


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: scavenger_workshop_pipeline.py PROJECT_ROOT OUTPUT_DIR")
    raise SystemExit(main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()))
