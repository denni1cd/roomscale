"""Blender authoring backend for the bounded Art Factory production batch 1.

The generator creates complete presentation assets, not runtime box recipes. Meshes
are authored as assembled building/furniture parts, receive bevels and UVs, and
export with embedded base-colour, roughness, and tangent-normal PBR maps.
"""

from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from pathlib import Path

import numpy as np


ASSETS = {
    # dimensions are expressed in Godot order (width, height, depth). Blender's
    # mesh constructors use X=width, Y=depth, Z=height.
    "settlement_workshop": {"type": "workshop", "dimensions": (26.0, 20.0, 20.0), "blender_size": (26.0, 20.0, 20.0)},
    "settlement_depot": {"type": "depot", "dimensions": (24.0, 13.0, 20.0), "blender_size": (24.0, 20.0, 13.0)},
    "settlement_housing": {"type": "housing", "dimensions": (17.0, 7.0, 9.0), "blender_size": (17.0, 9.0, 7.0)},
    "settlement_workarea": {"type": "workarea", "dimensions": (23.0, 9.0, 12.0), "blender_size": (23.0, 12.0, 9.0)},
    "room_bookcase_production": {"type": "bookcase", "dimensions": (40.0, 52.0, 20.0), "blender_size": (40.0, 20.0, 52.0)},
    "room_photo_window_production": {"type": "window", "dimensions": (96.0, 68.0, 4.0), "blender_size": (96.0, 4.0, 68.0)},
    "room_photo_french_door_production": {"type": "french_door", "dimensions": (66.0, 82.0, 4.0), "blender_size": (66.0, 4.0, 82.0)},
}

IN_BLENDER = False
try:
    import bpy  # type: ignore[import-not-found]
    from mathutils import Vector  # type: ignore[import-not-found]

    IN_BLENDER = True
except ImportError:
    bpy = None  # type: ignore[assignment]
    Vector = None  # type: ignore[assignment,misc]


def dispatch_to_blender() -> int:
    project_root = Path(__file__).resolve().parents[3]
    output_dir = Path(os.environ["ROOMSCALE_ART_FACTORY_OUTPUT_DIR"])
    asset_id = os.environ["ROOMSCALE_ART_FACTORY_ASSET_ID"]
    asset = ASSETS[asset_id]
    output_file = output_dir / "asset.glb"
    blender = os.environ.get("ROOMSCALE_BLENDER_EXECUTABLE", "")
    if not blender:
        raise RuntimeError("ROOMSCALE_BLENDER_EXECUTABLE must point to the approved local Blender install")
    command = [
        blender,
        "--background",
        "--factory-startup",
        "--python",
        str(Path(__file__).resolve()),
        "--",
        asset["type"],
        str(output_file),
    ]
    result = subprocess.run(command, cwd=project_root, check=False)
    if result.returncode or not output_file.is_file():
        # Blender's background Python runner can print an uncaught script
        # exception and still return zero on some Windows builds.
        return result.returncode or 2
    recipe_path = Path(os.environ["ROOMSCALE_ART_FACTORY_RECIPE"])
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    generation_record = {
        "asset_id": asset_id,
        "asset_type": asset["type"],
        "method": recipe["method"],
        "tool": "Blender 5.2.3 LTS Python/bpy",
        "output": "asset.glb",
        "dimensions_inches": list(asset["dimensions"]),
        "source_inputs": recipe.get("source_inputs", []),
        "geometry": "authored modular mesh assemblies with bevelled edges, framed openings, and fit-for-purpose component detail",
        "materials": "embedded PBR base-colour, roughness, and tangent-normal textures for wood, stone, iron, copper, and paper as applicable",
    }
    (output_dir / "generation-record.json").write_text(
        json.dumps(generation_record, indent=2) + "\n", encoding="utf-8"
    )
    return 0


def build_workshop(mats):
    width, depth = 26.0, 20.0
    box("Workshop stone and timber raft", (0.0, 0.0, 0.42), (25.5, 19.2, 0.84), mats["stone"], 0.2)
    stone_course(25.0, 0.75, -9.25, 0.97, 0.58, mats, 21)
    stone_course(25.0, 0.75, 9.25, 0.97, 0.58, mats, 22)
    for side in (-1, 1):
        for row in range(2):
            box("Workshop ashlar return", (side * 12.35, 0.0, 0.95 + row * 0.53), (0.65, 18.2, 0.46), mats["stone"], 0.13)
    # Four oak corner posts, tied by sill, plate and cross-bracing.
    for x in (-11.5, 11.5):
        for y in (-8.7, 8.7):
            box("Workshop mortised corner post", (x, y, 6.2), (0.82, 0.82, 10.6), mats["dark_wood"], 0.11)
            for z in (1.55, 10.8):
                box("Workshop post collar", (x, y, z), (1.02, 1.02, 0.20), mats["brass"] if z < 2 else mats["oak"], 0.045)
    for y in (-8.7, 8.7):
        beam("Workshop front and rear plate", (-12.0, y, 11.25), (12.0, y, 11.25), 0.62, 0.66, mats["oak"], 0.09)
    # Weatherboard enclosure is concentrated on the back and end bays; the work face stays open.
    plank_wall(width - 2.1, 8.35, 1.45, 10.8, mats, "Workshop rear")
    for side in (-1, 1):
        for row in range(12):
            z = 1.65 + row * 0.75
            box("Workshop side-board return", (side * 11.45, 0.0, z), (0.34, 17.1, 0.61), mats["oak"] if row % 3 else mats["dark_wood"], 0.04)
        beam("Workshop side diagonal brace", (side * 11.0, -8.0, 2.0), (side * 11.0, -1.2, 9.6), 0.38, 0.32, mats["dark_wood"], 0.055)
        beam("Workshop side diagonal brace", (side * 11.0, 1.2, 9.6), (side * 11.0, 8.0, 2.0), 0.38, 0.32, mats["dark_wood"], 0.055)
    # Roof trusses, copper standing seams and shaped eaves are visible from the settlement camera.
    gable_roof(width - 1.0, depth - 1.8, 12.2, 19.7, mats, "Workshop roof", 10)
    for y in (-8.0, 0.0, 8.0):
        beam("Workshop king-post truss", (0.0, y, 18.9), (0.0, y, 12.1), 0.42, 0.38, mats["dark_wood"], 0.065)
        for side in (-1, 1):
            beam("Workshop truss strut", (0.0, y, 13.2), (side * 9.6, y, 12.1), 0.32, 0.33, mats["oak"], 0.055)
    profile_prism("Workshop rear gable board", [(-12.0, 11.2), (12.0, 11.2), (0.0, 19.0)], 8.2, 8.65, mats["oak"], 0.04)
    # Boiler station: riveted pressure shell, collars, face plate, flywheel and live pipe run.
    boiler_x, boiler_y = 6.0, -2.0
    cylinder("Workshop riveted firebox", (boiler_x, boiler_y, 4.15), 2.15, 5.6, mats["iron"], "Z", 48, 0.11)
    for z in (1.55, 2.05, 5.8, 6.28):
        cylinder("Workshop copper pressure collar", (boiler_x, boiler_y, z), 2.24, 0.19, mats["copper"], "Z", 48, 0.035)
    cylinder("Workshop bolted firedoor", (boiler_x, boiler_y - 2.18, 3.55), 1.12, 0.24, mats["steel"], "Y", 48, 0.055)
    cylinder("Workshop firedoor glass", (boiler_x, boiler_y - 2.33, 3.55), 0.48, 0.10, mats["glass"], "Y", 32, 0.02)
    gear("Workshop flywheel", (boiler_x, boiler_y - 2.5, 5.65), 0.92, 0.19, 14, mats["brass"])
    cylinder("Workshop gauge housing", (boiler_x + 1.8, boiler_y - 2.22, 6.15), 0.54, 0.20, mats["brass"], "Y", 40, 0.035)
    cylinder("Workshop gauge glass", (boiler_x + 1.8, boiler_y - 2.34, 6.15), 0.42, 0.08, mats["glass"], "Y", 36, 0.018)
    tube("Workshop copper pressure line", [(boiler_x + 1.8, boiler_y - 2.28, 6.15), (boiler_x + 1.8, boiler_y - 2.6, 7.1), (boiler_x + 2.4, boiler_y - 2.6, 7.65), (boiler_x + 4.0, boiler_y - 2.2, 7.65)], 0.16, mats["copper"], 4)
    for z in (7.0, 13.0, 18.9):
        cylinder("Workshop flue ferrule", (8.5, 4.6, z), 0.72 if z < 18 else 0.93, 0.20, mats["copper"], "Z", 32, 0.035)
    cylinder("Workshop flue stack", (8.5, 4.6, 13.0), 0.56, 11.8, mats["iron"], "Z", 36, 0.07)
    cylinder("Workshop flue rain cap", (8.5, 4.6, 19.75), 0.98, 0.18, mats["steel"], "Z", 36, 0.035)
    # A joinery bench, iron vise and tool rail establish the actual workshop function.
    box("Workshop end-grain bench top", (-5.7, -2.3, 4.25), (8.3, 3.5, 0.62), mats["oak"], 0.18)
    for x in (-9.0, -2.5):
        for y in (-3.45, -1.15):
            box("Workshop turned bench leg", (x, y, 2.47), (0.48, 0.48, 3.3), mats["dark_wood"], 0.11)
    box("Workshop bench apron", (-5.7, -2.3, 3.45), (7.2, 0.55, 0.8), mats["dark_wood"], 0.09)
    box("Workshop vise body", (-9.0, -4.2, 4.75), (1.6, 0.45, 0.55), mats["iron"], 0.09)
    cylinder("Workshop vise screw", (-8.7, -4.45, 4.58), 0.11, 1.0, mats["steel"], "X", 20, 0.025)
    for i in range(5):
        cylinder("Workshop tool handle", (-7.8 + i * 0.72, -6.5, 5.0), 0.12, 1.25, mats["dark_wood"], "Z", 20, 0.025)
        cylinder("Workshop tool ferrule", (-7.8 + i * 0.72, -6.5, 5.58), 0.15, 0.12, mats["steel"], "Z", 20, 0.02)
    beam("Workshop hanging tool rail", (-9.8, -6.55, 6.0), (-3.8, -6.55, 6.0), 0.24, 0.25, mats["iron"], 0.045)
    for x in (-9.4, -7.9, -6.4, -4.9):
        hardware_pin("Workshop plate rivet", x, -8.94, 10.7, mats["brass"], 0.11)


def build_depot(mats):
    width, depth, height = 24.0, 20.0, 13.0
    box("Depot cut-stone sill course", (0.0, 0.0, 0.50), (23.4, 19.2, 1.0), mats["stone"], 0.22)
    for side in (-1, 1):
        for x in (-10.6, -7.8, 7.8, 10.6):
            box("Depot foundation quoin", (x, side * 9.35, 0.93), (2.45, 0.65, 0.62), mats["mortar"], 0.14)
    # The end walls have framed gable shoulders. Front loading bay remains a real opening.
    clad_front(width - 1.2, -9.0, 1.0, 8.1, [(-0.1, 4.1, 8.8, 5.8), (-8.2, 5.4, 3.0, 3.0), (8.0, 5.4, 3.0, 3.0)], mats, "Depot front")
    plank_wall(width - 1.2, 8.55, 1.0, 8.1, mats, "Depot rear")
    for side in (-1, 1):
        for row in range(9):
            z = 1.45 + row * 0.78
            box("Depot side cladding", (side * 11.15, 0.0, z), (0.40, 17.5, 0.68), mats["oak"] if row % 4 else mats["dark_wood"], 0.055)
        for y in (-7.8, 0.0, 7.8):
            box("Depot framed vertical buttress", (side * 11.52, y, 4.6), (0.58, 0.65, 7.2), mats["dark_wood"], 0.075)
    for x in (-11.1, 11.1):
        box("Depot front corner post", (x, -9.1, 4.5), (0.72, 0.72, 7.3), mats["dark_wood"], 0.1)
    framed_opening(-0.1, -9.16, 4.05, 8.8, 5.8, 1.7, mats, "Depot loading portal", False)
    # Twin freight leaves with diagonal braces, a rail latch and wrought-iron strap hinges.
    for side in (-1, 1):
        cx = -0.1 + side * 2.12
        leaf_w = 4.15
        box("Depot double freight leaf", (cx, -9.35, 4.0), (leaf_w, 0.42, 5.45), mats["dark_wood"], 0.12)
        for i in range(5):
            x = cx - leaf_w * 0.40 + i * leaf_w * 0.20
            box("Depot individual vertical door board", (x, -9.61, 4.0), (leaf_w * 0.17, 0.10, 5.2), mats["oak"] if i % 2 else mats["dark_wood"], 0.045)
        beam("Depot door brace", (cx - leaf_w * 0.42, -9.78, 1.65), (cx + leaf_w * 0.42, -9.78, 6.35), 0.32, 0.16, mats["steel"], 0.035)
        for z in (2.0, 5.9):
            box("Depot strap hinge", (cx + side * leaf_w * 0.37, -9.82, z), (leaf_w * 0.72, 0.14, 0.36), mats["iron"], 0.045)
            for x in (cx + side * leaf_w * 0.08, cx + side * leaf_w * 0.34):
                hardware_pin("Depot hinge rivet", x, -9.92, z, mats["brass"], 0.085)
    box("Depot receiving sill", (-0.1, -9.75, 1.22), (9.0, 1.45, 0.32), mats["steel"], 0.06)
    box("Depot loading ramp", (-0.1, -10.4, 0.63), (8.8, 1.5, 0.42), mats["dark_wood"], 0.08)
    for x in (-3.6, -1.8, 0.0, 1.8, 3.6):
        box("Depot anti-slip ramp cleat", (x, -10.5, 0.87), (0.18, 1.2, 0.10), mats["iron"], 0.02)
    framed_opening(-8.2, -9.16, 5.35, 3.0, 3.0, 1.2, mats, "Depot clerestory")
    framed_opening(8.0, -9.16, 5.35, 3.0, 3.0, 1.2, mats, "Depot clerestory east")
    gable_roof(width - 1.0, depth - 1.0, 8.25, 12.8, mats, "Depot roof", 9)
    for y in (-8.4, -3.0, 3.0, 8.4):
        beam("Depot roof truss tie", (-10.8, y, 8.15), (10.8, y, 8.15), 0.26, 0.28, mats["dark_wood"], 0.04)
    for side in (-1, 1):
        tube("Depot copper downspout", [(side * 11.5, -8.4, 8.2), (side * 11.65, -8.4, 3.7), (side * 11.2, -8.4, 1.0)], 0.12, mats["copper"], 3)
    box("Depot maker plaque", (0.0, -9.72, 7.52), (3.2, 0.18, 0.72), mats["iron"], 0.12)
    for x in (-1.25, 1.25):
        hardware_pin("Depot plaque stud", x, -9.84, 7.52, mats["brass"], 0.09)


def build_housing(mats):
    width, depth, height = 17.0, 9.0, 7.0
    box("Housing dressed-stone footing", (0.0, 0.0, 0.36), (16.4, 8.5, 0.72), mats["stone"], 0.20)
    door = (-4.1, 2.55, 2.7, 4.7)
    left_window = (1.1, 2.95, 2.55, 2.6)
    right_window = (5.0, 2.95, 2.55, 2.6)
    openings = [door, left_window, right_window]
    clad_front(width - 0.8, -4.05, 0.74, 4.85, openings, mats, "Housing front")
    plank_wall(width - 0.8, 4.0, 0.74, 4.85, mats, "Housing rear")
    for side in (-1, 1):
        for row in range(6):
            z = 1.15 + row * 0.7
            box("Housing side-board siding", (side * 8.0, 0.0, z), (0.34, 7.7, 0.61), mats["oak"] if row % 3 else mats["dark_wood"], 0.05)
        for y in (-3.5, 3.5):
            box("Housing corner timber", (side * 8.12, y, 2.8), (0.54, 0.52, 4.4), mats["dark_wood"], 0.075)
    for x in (-7.8, 7.8):
        box("Housing front upright", (x, -4.16, 2.8), (0.48, 0.48, 4.4), mats["dark_wood"], 0.07)
    framed_opening(door[0], -4.05, door[1], door[2], door[3], 1.2, mats, "Housing entry", True)
    framed_opening(left_window[0], -4.05, left_window[1], left_window[2], left_window[3], 0.85, mats, "Housing window west")
    framed_opening(right_window[0], -4.05, right_window[1], right_window[2], right_window[3], 0.85, mats, "Housing window east")
    box("Housing timber sill", (0.0, -4.45, 0.91), (15.9, 0.45, 0.30), mats["dark_wood"], 0.05)
    gable_roof(16.4, 8.6, 4.95, 6.96, mats, "Housing shingle roof", 7)
    # A modest ceramic flue and copper cap are attached to the rear slope.
    box("Housing chimney shaft", (5.8, 1.7, 5.7), (1.15, 1.1, 2.3), mats["stone"], 0.12)
    box("Housing chimney crown", (5.8, 1.7, 6.88), (1.48, 1.42, 0.24), mats["copper"], 0.06)
    for z in (5.05, 6.1):
        for x in (-7.0, 0.0, 7.0):
            hardware_pin("Housing rafter tie", x, -4.34, z, mats["brass"], 0.075)


def build_workarea(mats):
    width, depth, height = 23.0, 12.0, 9.0
    box("Workarea pegged platform", (0.0, 0.0, 0.28), (22.0, 11.2, 0.56), mats["oak"], 0.16)
    for i in range(12):
        x = -10.4 + i * 1.9
        box("Workarea floor plank", (x, 0.0, 0.59), (1.78, 10.7, 0.10), mats["dark_wood"] if i % 4 == 0 else mats["oak"], 0.025)
    # Lean-to canopy supported by braced timber posts and a visible iron truss.
    for x in (-10.2, 10.2):
        for y in (-4.8, 4.8):
            box("Workarea post shoe", (x, y, 0.86), (1.0, 1.0, 0.45), mats["iron"], 0.08)
            box("Workarea mortised post", (x, y, 4.6), (0.64, 0.64, 7.1), mats["dark_wood"], 0.11)
            beam("Workarea knee brace", (x * 0.92, y, 3.35), (x * 0.61, y, 6.3), 0.30, 0.30, mats["oak"], 0.045)
    for y in (-4.8, 4.8):
        beam("Workarea upper plate", (-10.7, y, 8.0), (10.7, y, 8.0), 0.52, 0.58, mats["oak"], 0.08)
        for x in (-8.0, 0.0, 8.0):
            beam("Workarea roof tie", (x, y, 7.9), (x, y, 6.5), 0.28, 0.28, mats["iron"], 0.04)
    gable_roof(width - 0.5, depth - 0.6, 8.1, 8.88, mats, "Workarea canopy", 11)
    # Heavy assembly bench with draw-bored legs, dog holes, and a proper vise.
    box("Workarea end-grain assembly surface", (-0.8, 0.0, 3.35), (14.2, 4.0, 0.65), mats["oak"], 0.20)
    for x in (-6.8, 5.2):
        for y in (-1.42, 1.42):
            beam("Workarea trestle leg", (x, y, 0.95), (x - 0.38 if y < 0 else x + 0.38, y, 3.1), 0.52, 0.55, mats["dark_wood"], 0.10)
    beam("Workarea trestle stretcher", (-6.6, 0.0, 1.75), (5.0, 0.0, 1.75), 0.45, 0.45, mats["dark_wood"], 0.08)
    for x in np.linspace(-6.0, 4.5, 9):
        cylinder("Workarea bench dog hole", (x, -1.82, 3.69), 0.11, 0.05, mats["iron"], "Z", 20, 0.01)
    box("Workarea machinist vise", (-7.1, -2.18, 3.95), (1.5, 0.62, 0.62), mats["iron"], 0.08)
    cylinder("Workarea vise screw", (-7.0, -2.6, 3.8), 0.12, 1.1, mats["steel"], "X", 20, 0.025)
    # Tool rail, handwheels, and a belt-driven grinder are grounded in the bench.
    beam("Workarea tool rail", (-7.8, -3.95, 6.1), (6.2, -3.95, 6.1), 0.26, 0.28, mats["iron"], 0.04)
    for i in range(4):
        x = -6.8 + i * 1.65
        cylinder("Workarea hanging hammer handle", (x, -4.0, 5.2), 0.10, 1.1, mats["dark_wood"], "Z", 16, 0.02)
        box("Workarea hanging tool head", (x, -4.0, 5.88), (0.58, 0.34, 0.25), mats["steel"], 0.045)
    cylinder("Workarea grindstone", (6.5, 0.0, 2.55), 1.0, 0.58, mats["stone"], "Y", 48, 0.08)
    gear("Workarea drive wheel", (6.5, -0.55, 2.55), 0.58, 0.20, 12, mats["brass"])
    tube("Workarea leather belt", [(5.9, -0.63, 3.1), (6.5, -0.63, 3.35), (7.1, -0.63, 3.1)], 0.09, mats["dark_wood"], 3)


def texture_image(name: str, rgb: np.ndarray, non_color: bool = False):
    size = int(rgb.shape[0])
    rgba = np.ones((size, size, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(rgb, 0.0, 1.0)
    image = bpy.data.images.new(name, width=size, height=size, alpha=False, float_buffer=False)
    image.colorspace_settings.name = "Non-Color" if non_color else "sRGB"
    image.pixels.foreach_set(rgba.ravel())
    image.pack()
    return image


def pbr_material(name: str, base: tuple[float, float, float], metallic: float, roughness: float, grain: str = "wood", alpha: float = 1.0):
    rng = np.random.default_rng(sum(ord(c) for c in name) + 113)
    size = 256
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    x /= float(size)
    y /= float(size)
    random_field = rng.standard_normal((size, size), dtype=np.float32)
    broad = (
        np.sin((x * 13.0 + y * 3.2) * math.tau)
        + 0.52 * np.sin((x * 27.0 - y * 2.1) * math.tau + 0.7)
        + 0.24 * np.sin((x * 57.0 + y * 0.8) * math.tau + 1.8)
    ) / 1.76
    if grain == "wood":
        height = broad * 0.45 + random_field * 0.08
        variation = broad * 0.12 + random_field * 0.018
    elif grain == "stone":
        height = random_field * 0.12 + np.sin(x * 25.0 + np.sin(y * 19.0) * 3.0) * 0.11
        variation = random_field * 0.08 + np.sin(x * 21.0 + y * 17.0) * 0.045
    elif grain == "fabric":
        weave = (np.sin(x * size * 0.55 * math.tau) * np.sin(y * size * 0.55 * math.tau))
        height = weave * 0.035 + random_field * 0.028
        variation = weave * 0.035 + random_field * 0.016
    elif grain == "copper":
        height = random_field * 0.055 + np.sin(x * 40.0 + y * 23.0) * 0.035
        variation = random_field * 0.035 + np.sin(x * 16.0 + y * 24.0) * 0.035
    else:
        height = broad * 0.08 + random_field * 0.025
        variation = broad * 0.035 + random_field * 0.012
    base_arr = np.asarray(base, dtype=np.float32).reshape((1, 1, 3))
    albedo = np.clip(base_arr * (1.0 + variation[:, :, None]), 0.0, 1.0)
    gx, gy = np.gradient(height)
    normal = np.stack(
        [0.5 - np.clip(gx * 0.7, -0.45, 0.45), 0.5 - np.clip(gy * 0.7, -0.45, 0.45), np.ones_like(gx)],
        axis=2,
    )
    normal /= np.maximum(np.linalg.norm(normal, axis=2, keepdims=True), 1e-6)
    normal = normal * 0.5 + 0.5
    rough_map = np.clip(roughness + random_field * 0.025 + broad * 0.025, 0.04, 0.98)
    rough_rgb = np.repeat(rough_map[:, :, None], 3, axis=2)

    material = bpy.data.materials.new(name)
    material.diffuse_color = (*base, alpha)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Alpha"].default_value = alpha
    shader.inputs["IOR"].default_value = 1.48
    output.location = (420, 0)
    shader.location = (160, 0)
    material.node_tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    albedo_node = nodes.new("ShaderNodeTexImage")
    albedo_node.image = texture_image(name + "_BaseColor", albedo)
    albedo_node.location = (-520, 180)
    rough_node = nodes.new("ShaderNodeTexImage")
    rough_node.image = texture_image(name + "_Roughness", rough_rgb, True)
    rough_node.location = (-520, -20)
    normal_node = nodes.new("ShaderNodeTexImage")
    normal_node.image = texture_image(name + "_Normal", normal, True)
    normal_node.location = (-520, -240)
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = 0.24 if grain in {"wood", "stone", "fabric"} else 0.12
    normal_map.location = (-160, -220)
    links = material.node_tree.links
    links.new(albedo_node.outputs["Color"], shader.inputs["Base Color"])
    links.new(rough_node.outputs["Color"], shader.inputs["Roughness"])
    links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
    return material


def set_up_materials():
    return {
        "oak": pbr_material("Quarter-sawn oak", (0.33, 0.18, 0.08), 0.0, 0.46, "wood"),
        "dark_wood": pbr_material("Smoke-stained walnut", (0.16, 0.085, 0.041), 0.0, 0.48, "wood"),
        "paint_green": pbr_material("Deep enamel green", (0.055, 0.19, 0.15), 0.15, 0.31, "metal"),
        "copper": pbr_material("Weathered copper", (0.39, 0.19, 0.10), 0.78, 0.31, "copper"),
        "brass": pbr_material("Aged brass", (0.53, 0.36, 0.13), 0.78, 0.29, "metal"),
        "iron": pbr_material("Forged blue-black iron", (0.055, 0.078, 0.083), 0.82, 0.37, "metal"),
        "steel": pbr_material("Brushed steel", (0.28, 0.32, 0.32), 0.86, 0.28, "metal"),
        "stone": pbr_material("Mottled fieldstone", (0.30, 0.28, 0.23), 0.0, 0.84, "stone"),
        "mortar": pbr_material("Warm lime mortar", (0.43, 0.38, 0.30), 0.0, 0.91, "stone"),
        "roof": pbr_material("Oxidised copper roofing", (0.105, 0.22, 0.20), 0.67, 0.42, "copper"),
        "glass": pbr_material("Low-iron glass", (0.36, 0.55, 0.59), 0.08, 0.10, "metal", 0.34),
        "paper": pbr_material("Warm book paper", (0.75, 0.67, 0.51), 0.0, 0.82, "fabric"),
        "book_red": pbr_material("Burgundy bookcloth", (0.28, 0.075, 0.055), 0.0, 0.76, "fabric"),
        "book_green": pbr_material("Bottle green bookcloth", (0.08, 0.18, 0.12), 0.0, 0.76, "fabric"),
        "book_blue": pbr_material("Indigo bookcloth", (0.075, 0.14, 0.22), 0.0, 0.76, "fabric"),
        "book_ochre": pbr_material("Ochre bookcloth", (0.52, 0.34, 0.10), 0.0, 0.76, "fabric"),
        "dark_rubber": pbr_material("Matte vulcanised rubber", (0.026, 0.032, 0.032), 0.0, 0.86, "metal"),
        "window_oak": pbr_material("Photographic warm window oak", (0.43, 0.245, 0.105), 0.0, 0.43, "wood"),
        "window_glass": pbr_material("Clear household window glass", (0.52, 0.68, 0.72), 0.02, 0.12, "metal", 0.22),
    }


def bevel(obj, width: float, segments: int = 3):
    if width > 0.0:
        modifier = obj.modifiers.new("Small manufactured edge radius", "BEVEL")
        modifier.width = width
        modifier.segments = segments
        modifier.limit_method = "ANGLE"
        modifier.harden_normals = True
        weighted = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
        weighted.keep_sharp = True
    return obj


def box(name: str, location, size, material, radius: float = 0.06, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation is not None:
        obj.rotation_euler = rotation
    if material is not None:
        obj.data.materials.append(material)
    min_edge = min(float(v) for v in size)
    bevel(obj, min(radius, min_edge * 0.38), 3)
    return obj


def cylinder(name: str, location, radius: float, depth: float, material, axis: str = "Z", vertices: int = 32, edge: float = 0.035):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    if axis == "X":
        obj.rotation_euler[1] = math.pi / 2.0
    elif axis == "Y":
        obj.rotation_euler[0] = math.pi / 2.0
    if material is not None:
        obj.data.materials.append(material)
    bevel(obj, min(edge, radius * 0.32, depth * 0.2), 3)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def beam(name: str, start, end, width: float, depth: float, material, radius: float = 0.045):
    start_v, end_v = Vector(start), Vector(end)
    delta = end_v - start_v
    obj = box(name, (start_v + end_v) * 0.5, (width, depth, delta.length), material, radius)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    return obj


def tube(name: str, points, radius: float, material, resolution: int = 3):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 12
    curve.bevel_depth = radius
    curve.bevel_resolution = resolution
    spline = curve.splines.new("BEZIER" if len(points) < 4 else "POLY")
    if spline.type == "BEZIER":
        spline.bezier_points.add(len(points) - 1)
        for point, position in zip(spline.bezier_points, points, strict=True):
            point.co = position
            point.handle_left_type = "AUTO"
            point.handle_right_type = "AUTO"
    else:
        spline.points.add(len(points) - 1)
        for point, position in zip(spline.points, points, strict=True):
            point.co = (*position, 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    if material is not None:
        obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.object


def profile_prism(name: str, points_xz, y_front: float, y_back: float, material, bevel_width: float = 0.025):
    points = list(points_xz)
    count = len(points)
    vertices = [(x, y_front, z) for x, z in points] + [(x, y_back, z) for x, z in points]
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, 2 * count))]
    for i in range(count):
        j = (i + 1) % count
        faces.append((i, j, j + count, i + count))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bevel(obj, bevel_width, 2)
    return obj


def gear(name: str, center, radius: float, thickness: float, teeth: int, material):
    cx, cy, cz = center
    points = []
    for tooth in range(teeth):
        start = math.tau * tooth / teeth
        for fraction, scale in ((0.00, 0.91), (0.18, 0.91), (0.24, 1.0), (0.67, 1.0), (0.73, 0.91), (0.98, 0.91)):
            angle = start + math.tau * fraction / teeth
            points.append((math.cos(angle) * radius * scale, math.sin(angle) * radius * scale))
    n = len(points)
    y0, y1 = cy - thickness * 0.5, cy + thickness * 0.5
    vertices = [(cx + x, y0, cz + z) for x, z in points] + [(cx + x, y1, cz + z) for x, z in points]
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bevel(obj, min(0.035, thickness * 0.18), 2)
    return obj


def surface_uvs():
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for obj in mesh_objects:
        if not obj.data.uv_layers:
            obj.data.uv_layers.new(name="UVMap")
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        try:
            bpy.ops.uv.smart_project(island_margin=0.015, scale_to_bounds=True)
        except RuntimeError:
            pass
        bpy.ops.object.mode_set(mode="OBJECT")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    for image in list(bpy.data.images):
        if image.users == 0:
            bpy.data.images.remove(image)


def stone_course(width: float, depth: float, y: float, z: float, course_height: float, mats, seed: int = 0):
    rng = np.random.default_rng(seed)
    x = -width * 0.5
    index = 0
    while x < width * 0.5 - 0.1:
        span = min(float(rng.uniform(2.2, 3.8)), width * 0.5 - x)
        offset = float(rng.uniform(-0.055, 0.055))
        material = mats["stone"] if index % 3 else mats["mortar"]
        obj = box(
            f"Ashlar stone {index}",
            (x + span * 0.5, y, z + offset),
            (span - 0.08, depth, course_height + float(rng.uniform(-0.08, 0.08))),
            material,
            0.14,
        )
        obj.rotation_euler[1] = float(rng.uniform(-0.018, 0.018))
        x += span
        index += 1


def plank_wall(width: float, y: float, z0: float, z1: float, mats, prefix: str, face="front", x_offset: float = 0.0):
    """Staggered board cladding with a thin shadow gap and distinct end grain."""
    height = z1 - z0
    board_height = 0.74
    rows = math.ceil(height / board_height)
    colors = [mats["oak"], mats["dark_wood"], mats["oak"]]
    for row in range(rows):
        z = z0 + row * board_height + board_height * 0.5
        if z > z1:
            continue
        length = width * 0.5 + 1.0
        direction = 1.0 if row % 2 else -1.0
        centers = [-width * 0.25, width * 0.25]
        for piece, cx in enumerate(centers):
            if face == "front":
                location = (cx + (0.22 * direction if piece == 0 else -0.22 * direction) + x_offset, y, z)
                size = (length, 0.28, min(board_height - 0.065, z1 - z0))
            else:
                location = (y, cx + (0.22 * direction if piece == 0 else -0.22 * direction), z)
                size = (0.28, length, min(board_height - 0.065, z1 - z0))
            box(f"{prefix} board course {row}-{piece}", location, size, colors[(row + piece) % len(colors)], 0.045)


def gable_roof(width: float, depth: float, eave_z: float, ridge_z: float, mats, prefix: str, seams: int = 8):
    half = width * 0.5
    left = [(-half - 0.2, eave_z), (0.0, ridge_z), (0.0, ridge_z - 0.42), (-half - 0.2, eave_z - 0.42)]
    right = [(0.0, ridge_z), (half + 0.2, eave_z), (half + 0.2, eave_z - 0.42), (0.0, ridge_z - 0.42)]
    profile_prism(prefix + " left folded roof plane", left, -depth * 0.5, depth * 0.5, mats["roof"], 0.035)
    profile_prism(prefix + " right folded roof plane", right, -depth * 0.5, depth * 0.5, mats["roof"], 0.035)
    beam(prefix + " ridge cap", (0.0, -depth * 0.5 - 0.12, ridge_z + 0.04), (0.0, depth * 0.5 + 0.12, ridge_z + 0.04), 0.50, 0.36, mats["copper"], 0.09)
    for side in (-1.0, 1.0):
        for i in range(seams):
            along = (i + 0.5) / seams
            x = side * half * along
            z = ridge_z + (eave_z - ridge_z) * along + 0.12
            tube(f"{prefix} standing seam {side}-{i}", [(x, -depth * 0.5 - 0.08, z), (x, depth * 0.5 + 0.08, z)], 0.045, mats["copper"], 2)
        for y in np.linspace(-depth * 0.5 + 1.1, depth * 0.5 - 1.1, 4):
            beam(f"{prefix} visible rafter", (side * (half - 0.12), y, eave_z - 0.35), (side * 0.12, y, ridge_z - 0.30), 0.27, 0.27, mats["dark_wood"], 0.045)


def trim_nails(points, y, material, radius=0.07):
    for x, z in points:
        cylinder("Hand-forged clout nail", (x, y, z), radius, 0.07, material, "Y", 12, 0.015)


def window_frame(width: float, height: float, depth: float, mats, prefix: str, transom=True):
    """A double-sash assembly with glazed lights, jambs, sill, and hardware."""
    half_w, half_h = width * 0.5, height * 0.5
    face_y = -depth * 0.5
    casing = max(0.85, min(width, height) * 0.032)
    sash = casing * 0.58
    wood, oak = mats["dark_wood"], mats["oak"]
    for x in (-half_w + casing * 0.5, half_w - casing * 0.5):
        box(prefix + " jamb", (x, 0.0, 0.0), (casing, depth * 0.72, height), wood, 0.12)
        box(prefix + " casing side", (x * 1.035, face_y, 0.0), (casing * 1.42, depth * 0.2, height + casing * 0.35), oak, 0.14)
    box(prefix + " head jamb", (0.0, 0.0, half_h - casing * 0.5), (width - casing * 1.6, depth * 0.72, casing), wood, 0.11)
    box(prefix + " projecting sill", (0.0, -depth * 0.12, -half_h + casing * 0.42), (width + casing * 0.58, depth * 1.05, casing * 1.08), oak, 0.18)
    inner_w = width - casing * 2.25
    inner_h = height - casing * 2.25
    inner_top = half_h - casing * 1.12
    inner_bottom = -half_h + casing * 1.24
    for x in (-inner_w * 0.5, inner_w * 0.5):
        box(prefix + " sash stile", (x, face_y + depth * 0.28, 0.0), (sash, depth * 0.28, inner_h), oak, 0.09)
    for z in (inner_bottom, inner_top):
        box(prefix + " sash rail", (0.0, face_y + depth * 0.28, z), (inner_w + sash, depth * 0.28, sash), oak, 0.09)
    split_z = inner_bottom + inner_h * (0.70 if transom else 0.50)
    box(prefix + " meeting rail", (0.0, face_y - depth * 0.02, split_z), (inner_w + sash * 0.5, depth * 0.34, sash * 0.78), wood, 0.075)
    pane_front = face_y + depth * 0.33
    upper_height = max(0.2, inner_top - split_z - sash * 0.42)
    lower_height = max(0.2, split_z - inner_bottom - sash * 0.42)
    for z, pane_height in (
        (split_z + sash * 0.5 + upper_height * 0.5, upper_height),
        (inner_bottom + sash * 0.5 + lower_height * 0.5, lower_height),
    ):
        for x in (-inner_w * 0.25, inner_w * 0.25):
            box(prefix + " glazed light", (x, pane_front, z), (inner_w * 0.5 - sash * 0.44, depth * 0.11, pane_height), mats["glass"], 0.025)
    box(prefix + " centre mullion", (0.0, face_y - depth * 0.04, 0.0), (sash * 0.50, depth * 0.36, inner_h - sash * 0.72), oak, 0.045)
    if transom:
        upper_rail = split_z + sash * 1.2
        box(prefix + " transom crossbar", (0.0, face_y - depth * 0.035, upper_rail), (inner_w, depth * 0.36, sash * 0.55), oak, 0.045)
    for x in (-sash * 0.75, sash * 0.75):
        cylinder(prefix + " sash lock plate", (x, face_y - depth * 0.10, split_z), 0.18, 0.07, mats["brass"], "Y", 20, 0.015)
        box(prefix + " sash lift", (x, face_y - depth * 0.16, inner_bottom + sash * 0.62), (0.22, 0.16, 0.36), mats["brass"], 0.055)
    for x in (-half_w + casing * 0.52, half_w - casing * 0.52):
        for z in (-half_h + casing * 0.72, half_h - casing * 0.72):
            cylinder(prefix + " countersunk screw", (x, face_y - depth * 0.18, z), 0.075, 0.035, mats["steel"], "Y", 16, 0.009)


def paneled_door(width: float, height: float, depth: float, mats, prefix: str, glazed: bool = False):
    half_w, half_h = width * 0.5, height * 0.5
    face_y = -depth * 0.5
    frame = max(0.45, min(width, height) * 0.035)
    stile = max(0.42, min(width, height) * 0.042)
    wood, trim = mats["dark_wood"], mats["oak"]
    box(prefix + " leaf core", (0.0, 0.0, 0.0), (width - frame * 1.35, depth * 0.44, height - frame * 1.1), wood, 0.12)
    for x in (-half_w + stile * 0.7, half_w - stile * 0.7):
        box(prefix + " door stile", (x, face_y - depth * 0.16, 0.0), (stile, depth * 0.25, height - frame), trim, 0.08)
    for z in (-half_h + frame * 0.75, half_h - frame * 0.75, -height * 0.18):
        box(prefix + " door rail", (0.0, face_y - depth * 0.16, z), (width - stile * 0.65, depth * 0.25, frame * 0.95), trim, 0.08)
    if glazed:
        glass_top, glass_bottom = half_h - frame * 1.45, -height * 0.20
        for x in (-width * 0.245, width * 0.245):
            for row in range(3):
                z = glass_bottom + (glass_top - glass_bottom) * (row + 0.5) / 3.0
                pane_h = (glass_top - glass_bottom) / 3.0 - frame * 0.25
                box(prefix + " glazed light", (x, face_y + depth * 0.02, z), (width * 0.43 - stile * 0.55, depth * 0.08, pane_h), mats["glass"], 0.022)
        box(prefix + " central astragal", (0.0, face_y - depth * 0.07, (glass_top + glass_bottom) * 0.5), (stile * 0.42, depth * 0.22, glass_top - glass_bottom), trim, 0.035)
    else:
        panel_height = height * 0.24
        for z in (-height * 0.29, height * 0.20):
            box(prefix + " recessed panel shadow", (0.0, face_y - depth * 0.02, z), (width * 0.52, depth * 0.06, panel_height), mats["dark_wood"], 0.075)
            for x in (-width * 0.30, width * 0.30):
                box(prefix + " raised panel stile", (x, face_y - depth * 0.10, z), (frame * 0.6, depth * 0.1, panel_height), wood, 0.055)
            for zz in (z - panel_height * 0.5, z + panel_height * 0.5):
                box(prefix + " raised panel rail", (0.0, face_y - depth * 0.10, zz), (width * 0.6, depth * 0.1, frame * 0.58), wood, 0.055)
    for z in (-height * 0.34, height * 0.34):
        box(prefix + " leaf hinge", (-half_w + frame * 0.42, face_y - depth * 0.23, z), (frame * 0.55, depth * 0.12, frame * 0.72), mats["brass"], 0.035)
    cylinder(prefix + " latch backplate", (width * 0.31, face_y - depth * 0.22, -height * 0.02), frame * 0.18, depth * 0.08, mats["brass"], "Y", 20, 0.018)
    tube(prefix + " lever handle", [(width * 0.31, face_y - depth * 0.18, -height * 0.02), (width * 0.42, face_y - depth * 0.18, -height * 0.02), (width * 0.46, face_y - depth * 0.18, -height * 0.10)], 0.055, mats["brass"], 3)


def place_module(builder, offset, *args, **kwargs):
    before = set(bpy.context.scene.objects)
    builder(*args, **kwargs)
    delta = Vector(offset)
    for obj in bpy.context.scene.objects:
        if obj not in before:
            obj.location += delta


def clad_front(width: float, y: float, z0: float, z1: float, openings, mats, prefix: str):
    """Horizontal, staggered siding stops at real framed window and door apertures."""
    step = 0.72
    board_h = 0.62
    z = z0 + board_h * 0.5
    row = 0
    while z < z1:
        spans = [(-width * 0.5, width * 0.5)]
        for cx, cz, ow, oh in openings:
            if cz - oh * 0.5 - 0.16 <= z <= cz + oh * 0.5 + 0.16:
                cut_l, cut_r = cx - ow * 0.5, cx + ow * 0.5
                next_spans = []
                for left, right in spans:
                    if cut_r <= left or cut_l >= right:
                        next_spans.append((left, right))
                    else:
                        if cut_l > left + 0.08:
                            next_spans.append((left, cut_l))
                        if cut_r < right - 0.08:
                            next_spans.append((cut_r, right))
                spans = next_spans
        for index, (left, right) in enumerate(spans):
            length = right - left
            if length < 0.18:
                continue
            material = mats["oak"] if (row + index) % 4 else mats["dark_wood"]
            box(f"{prefix} bevel-lapped siding {row}-{index}", ((left + right) * 0.5, y, z), (length, 0.26, board_h), material, 0.035)
        z += step
        row += 1


def framed_opening(cx: float, y: float, cz: float, width: float, height: float, depth: float, mats, prefix: str, door=False):
    trim = mats["oak"]
    dark = mats["dark_wood"]
    jamb = max(0.24, min(width, height) * 0.06)
    for x in (cx - width * 0.5 - jamb * 0.5, cx + width * 0.5 + jamb * 0.5):
        box(prefix + " structural jamb", (x, y, cz), (jamb, depth, height + jamb), dark, 0.055)
        box(prefix + " moulded casing", (x, y - depth * 0.56, cz), (jamb * 0.48, depth * 0.30, height + jamb * 1.25), trim, 0.065)
    box(prefix + " header", (cx, y, cz + height * 0.5 + jamb * 0.38), (width + jamb * 1.35, depth, jamb * 0.82), dark, 0.055)
    if door:
        place_module(paneled_door, (cx, y, cz), width, height, depth, mats, prefix, False)
        box(prefix + " threshold", (cx, y - depth * 0.14, cz - height * 0.5 - 0.11), (width + jamb * 1.2, depth * 1.3, 0.22), mats["stone"], 0.045)
    else:
        place_module(window_frame, (cx, y, cz), width, height, depth, mats, prefix, height > width * 0.55)


def hardware_pin(name: str, x: float, y: float, z: float, material_or_palette, radius: float = 0.09):
    material = material_or_palette["brass"] if isinstance(material_or_palette, dict) else material_or_palette
    cylinder(name, (x, y, z), radius, 0.055, material, "Y", 16, 0.012)


def bookcase(mats):
    width, depth, height = 40.0, 20.0, 52.0
    front = -depth * 0.5
    # Cabinet carcass, face frame, toe kick, crown moulding, and fitted back panel.
    box("Bookcase recessed carcass back", (0.0, depth * 0.39, height * 0.52), (width - 2.5, 0.55, height - 3.5), mats["dark_wood"], 0.13)
    for x in (-width * 0.5 + 0.85, width * 0.5 - 0.85):
        box("Bookcase solid side panel", (x, 0.0, height * 0.52), (1.7, depth - 1.2, height - 3.4), mats["oak"], 0.18)
        box("Bookcase inside stile", (x + (0.42 if x < 0 else -0.42), front - 0.34, height * 0.54), (0.38, 0.48, height - 4.0), mats["dark_wood"], 0.07)
    box("Bookcase plinth", (0.0, 0.0, 1.0), (width, depth, 2.0), mats["dark_wood"], 0.22)
    box("Bookcase plinth bead", (0.0, front - 0.28, 1.65), (width - 0.75, 0.42, 0.42), mats["oak"], 0.12)
    box("Bookcase crown lower moulding", (0.0, 0.0, height - 2.4), (width, depth, 1.25), mats["dark_wood"], 0.12)
    box("Bookcase crown cap", (0.0, 0.0, height - 1.0), (width + 0.5, depth + 0.35, 1.0), mats["oak"], 0.22)
    inner_width = width - 3.6
    for x in (-6.4, 6.4):
        box("Bookcase full-height bay divider", (x, 0.12, height * 0.53), (0.82, depth - 2.0, height - 7.0), mats["dark_wood"], 0.11)
    shelf_levels = [9.0, 19.0, 29.0, 39.0, 47.0]
    for i, z in enumerate(shelf_levels):
        box(f"Bookcase mortise shelf {i}", (0.0, 0.15, z), (inner_width, depth - 2.4, 0.88), mats["oak"] if i % 2 else mats["dark_wood"], 0.11)
        box(f"Bookcase front nosing {i}", (0.0, front - 0.55, z + 0.14), (inner_width, 0.52, 0.58), mats["oak"], 0.12)
        for x in (-inner_width * 0.34, 0.0, inner_width * 0.34):
            cylinder(f"Shelf support pin {i}", (x, front + 0.3, z - 0.48), 0.075, 0.22, mats["brass"], "Y", 16, 0.01)
    # Lower pair of framed cabinet doors with inset panels and separate working hardware.
    for index, x in enumerate((-9.5, 9.5)):
        door_w, door_h, door_z = 15.0, 7.7, 5.7
        box("Lower cupboard door slab", (x, front - 0.28, door_z), (door_w, 0.42, door_h), mats["oak"], 0.15)
        box("Cupboard inset field", (x, front - 0.51, door_z), (door_w - 1.9, 0.15, door_h - 1.9), mats["dark_wood"], 0.12)
        for dx in (-door_w * 0.5 + 0.42, door_w * 0.5 - 0.42):
            box("Cupboard raised stile", (x + dx, front - 0.58, door_z), (0.52, 0.16, door_h - 0.2), mats["oak"], 0.08)
        for dz in (-door_h * 0.5 + 0.38, door_h * 0.5 - 0.38):
            box("Cupboard raised rail", (x, front - 0.58, door_z + dz), (door_w - 0.22, 0.16, 0.48), mats["oak"], 0.08)
        for z in (door_z - 2.55, door_z + 2.55):
            box("Cupboard hinge leaf", (x - door_w * 0.45, front - 0.69, z), (0.55, 0.11, 0.82), mats["brass"], 0.04)
        cylinder("Cupboard brass escutcheon", (x + (0.65 if index == 0 else -0.65), front - 0.74, door_z), 0.26, 0.11, mats["brass"], "Y", 24, 0.03)
        cylinder("Cupboard turned knob", (x + (0.65 if index == 0 else -0.65), front - 0.86, door_z), 0.13, 0.20, mats["steel"], "Y", 20, 0.045)
    # Removable, fitted parts trays give the shelving its actual workshop role.
    tray_colors = [mats["oak"], mats["dark_wood"]]
    for row, shelf_z in enumerate(shelf_levels[:-1]):
        for bay, center_x in enumerate((-12.1, 0.0, 12.1)):
            tray_w, tray_h, tray_depth = 10.6, 6.8, 11.2
            tray_z = shelf_z + 0.46 + tray_h * 0.5
            tray_front = front - 0.18
            tray_back = tray_front + tray_depth
            tray_mat = tray_colors[(row + bay) % 2]
            box("Parts tray bottom", (center_x, (tray_front + tray_back) * 0.5, shelf_z + 0.66), (tray_w, tray_depth, 0.34), tray_mat, 0.06)
            for x in (center_x - tray_w * 0.5, center_x + tray_w * 0.5):
                box("Parts tray side", (x, (tray_front + tray_back) * 0.5, tray_z), (0.32, tray_depth, tray_h), mats["dark_wood"], 0.07)
            box("Parts tray rear stop", (center_x, tray_back, tray_z), (tray_w, 0.36, tray_h), mats["dark_wood"], 0.07)
            box("Parts tray raised front", (center_x, tray_front, tray_z), (tray_w, 0.42, tray_h * 0.84), tray_mat, 0.10)
            box("Parts tray brass label frame", (center_x, tray_front - 0.27, tray_z + 0.62), (tray_w * 0.46, 0.12, 0.95), mats["brass"], 0.07)
            box("Parts tray enamel label", (center_x, tray_front - 0.35, tray_z + 0.62), (tray_w * 0.36, 0.045, 0.52), mats["paint_green"], 0.025)
            for x in (center_x - tray_w * 0.36, center_x + tray_w * 0.36):
                hardware_pin("Tray label rivet", x, tray_front - 0.39, tray_z + 0.62, mats, 0.055)
            # A few large, readable repair parts stand above each tray rim.
            component_y = tray_front + tray_depth * 0.58
            gear("Stored replacement gear", (center_x - 2.45, component_y, shelf_z + 1.52), 1.25, 0.24, 12 + (bay % 2) * 4, mats["brass"])
            cylinder("Stored bearing race", (center_x + 1.2, component_y, shelf_z + 1.30), 0.75, 0.30, mats["steel"], "Y", 32, 0.035)
            cylinder("Stored shaft collar", (center_x + 3.35, component_y, shelf_z + 1.26), 0.38, 1.6, mats["copper"], "X", 24, 0.03)


def build_window(mats):
    width, depth, height = 96.0, 4.0, 68.0
    window_frame(width, height, depth, mats, "Luna north double-hung window", True)
    # The photograph shows deep stained-oak trim with a substantial sill;
    # apply its warm wood response consistently to the joinery parts.
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH" or not obj.name.startswith("Luna north"):
            continue
        if any(tag in obj.name for tag in ("glazed light",)):
            continue
        if any(tag in obj.name for tag in ("jamb", "casing", "stile", "rail", "mullion", "crossbar", "sill", "sash lift")):
            obj.data.materials.clear()
            obj.data.materials.append(mats["window_oak"])


def build_french_door(mats):
    width, depth, height = 66.0, 4.0, 82.0
    jamb = 2.4
    for x in (-width * 0.5 - jamb * 0.5, width * 0.5 + jamb * 0.5):
        box("French door structural jamb", (x, 0.0, height * 0.5), (jamb, depth * 0.74, height + jamb), mats["dark_wood"], 0.20)
        box("French door stepped casing", (x, -depth * 0.60, height * 0.5), (jamb * 0.74, depth * 0.32, height + jamb * 1.45), mats["window_oak"], 0.26)
    box("French door head casing", (0.0, -depth * 0.34, height + jamb * 0.45), (width + jamb * 2.1, depth * 0.56, jamb), mats["window_oak"], 0.20)
    place_module(paneled_door, (0.0, 0.0, height * 0.5), width, height, depth, mats, "Photo matched French pair", True)
    # A separate central astragal and weather sill establish the double-leaf join.
    box("French door central meeting stile", (0.0, -depth * 0.66, height * 0.49), (0.68, depth * 0.44, height * 0.94), mats["window_oak"], 0.10)
    box("French door sill", (0.0, -depth * 0.05, 0.12), (width + jamb * 2.0, depth * 0.60, 0.24), mats["steel"], 0.06)
    for x in (-width * 0.25, width * 0.25):
        cylinder("French door deadbolt escutcheon", (x, -depth * 0.76, height * 0.46), 0.27, 0.10, mats["brass"], "Y", 24, 0.025)


def apply_modifiers_and_merge_by_material():
    """Bake manufactured edge profiles, unwrap, and merge into material batches."""
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for obj in mesh_objects:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    # Keep a consistent texture density across the separately authored parts.
    for obj in mesh_objects:
        if not obj.data.uv_layers:
            obj.data.uv_layers.new(name="UVMap")
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        try:
            bpy.ops.uv.smart_project(island_margin=0.025, scale_to_bounds=False)
        except RuntimeError:
            pass
        bpy.ops.object.mode_set(mode="OBJECT")
    material_groups: dict[str, list] = {}
    for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
        material_name = obj.data.materials[0].name if obj.data.materials else "unassigned"
        material_groups.setdefault(material_name, []).append(obj)
    for material_name, objects in material_groups.items():
        if len(objects) < 2:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        bpy.context.object.name = "MaterialBatch_" + material_name.replace(" ", "_")


def run_blender_generation(asset_type: str, output_path: Path) -> None:
    clear_scene()
    mats = set_up_materials()
    builders = {
        "workshop": build_workshop,
        "depot": build_depot,
        "housing": build_housing,
        "workarea": build_workarea,
        "bookcase": bookcase,
        "window": build_window,
        "french_door": build_french_door,
    }
    builder = builders.get(asset_type)
    if builder is None:
        raise ValueError(f"unsupported production batch asset type: {asset_type}")
    builder(mats)
    corners = [obj.matrix_world @ Vector(corner) for obj in bpy.context.scene.objects if obj.type == "MESH" for corner in obj.bound_box]
    if corners:
        minimum = Vector((min(point.x for point in corners), min(point.y for point in corners), min(point.z for point in corners)))
        maximum = Vector((max(point.x for point in corners), max(point.y for point in corners), max(point.z for point in corners)))
        print(f"ROOMSCALE_BATCH01_GEOMETRY_BOUNDS_BLENDER min={tuple(round(v, 3) for v in minimum)} max={tuple(round(v, 3) for v in maximum)} extent={tuple(round(v, 3) for v in maximum - minimum)}")
    apply_modifiers_and_merge_by_material()
    bpy.ops.object.select_all(action="SELECT")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
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
    if not output_path.is_file() or output_path.stat().st_size < 1024:
        raise RuntimeError(f"Blender did not create a usable GLB: {output_path}")
    print(f"ROOMSCALE_BATCH01_BLENDER_PASS type={asset_type} path={output_path} bytes={output_path.stat().st_size}")


def main() -> int:
    if IN_BLENDER:
        arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
        if len(arguments) != 2:
            raise SystemExit("Blender invocation requires <asset_type> <output.glb> after --")
        run_blender_generation(arguments[0], Path(arguments[1]))
        return 0
    return dispatch_to_blender()


if __name__ == "__main__":
    raise SystemExit(main())
