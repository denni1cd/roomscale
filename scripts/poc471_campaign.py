"""Deterministic RoomDefinition transformations and fresh production observers.

Only input definitions are changed. Godot owns validation, navigation, fixed ticks,
governor decisions, physical citizens, material accounting and all progression.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import copy
import hashlib
import json
import os
from pathlib import Path
import random
import statistics
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
NAMES = ["Long Salvage Haul", "Long Water Haul", "Crowded Settlement Origin",
         "Alternative Founder Origin", "Constrained Build Sites", "Mixed Obstacle Routing",
         "Low Bootstrap Reserves", "Resource Separation", "Traversal Distance Variation",
         "Late Growth Pressure"]
ORIGINS = [[0, 0, 46], [-34, 0, 50], [34, 0, 54], [-68, 0, 46], [62, 0, 12], [4, 0, 8]]


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n", encoding="utf-8")


def obstacle(identifier, x, z, width=8, depth=8):
    # Protected ordinary furniture; never a test-side completed structure.
    return dict(id=identifier, name=identifier, kind="box", position=[x, 0, z],
                dimensions=[width, 6, depth], blocks_navigation=True,
                navigation_padding=[0, 0, 0], resource_profile={"protected": True})


def clear_floor(room, x, z):
    """Conservative input sampling only; authoritative validation stays in Godot."""
    origin = room["start"]["origin"]
    if abs(x-origin[0]) <= 14 and abs(z-(origin[2]-9)) <= 14:
        return False
    for o in room["objects"]:
        if not o.get("blocks_navigation"):
            continue
        half_x = o["dimensions"][0]/2 + o.get("navigation_padding", [0, 0, 0])[0] + 4
        half_z = o["dimensions"][2]/2 + o.get("navigation_padding", [0, 0, 0])[2] + 4
        if abs(x-o["position"][0]) <= half_x and abs(z-o["position"][2]) <= half_z:
            return False
    return True


def generate(index, seed, negative=False):
    rng = random.Random(seed)
    room = json.loads((ROOT / "rooms/room_poc47.json").read_text())
    sid = f"NEG-{index + 1:02}" if negative else f"POS-{index + 1:03}"
    room["id"] = sid
    objects = {o["id"]: o for o in room["objects"]}
    changes = {}
    name = NAMES[index] if not negative and index < 10 else "Combined layout variation"
    if negative:
        if index == 0:
            name = "No Reachable Water"
            for key in ["spilled_water", "water_cup"]:
                objects[key]["resource_profile"]["contents"] = {}
            room["civilization"]["stock"]["water"] = 3
        elif index == 1:
            name = "Insufficient Shelter Materials"
            for o in room["objects"]:
                o.setdefault("resource_profile", {})["protected"] = True
            objects["chair"]["resource_profile"].update(protected=False, stages=[dict(name="DEPLETED", work=8, yields={"wood":3})])
        elif index == 2:
            name = "No Valid Depot Site"
            room["objects"].append(obstacle("depot_blocker", 0, 37, 4, 4))
        elif index == 3:
            name = "Critical Elevated Resource Before Workshop"
            objects["spilled_water"]["resource_profile"]["contents"] = {}
            room["civilization"]["stock"]["water"] = 3
        else:
            name = "Disconnected Spawn"
            room["spawn"]["center"] = [90, 0, 70]
            room["spawn"]["dimensions"] = [12, 0, 10]
            room["objects"].append(obstacle("separating_wall", 60, 0, 4, 178))
        changes["intentional_impossibility"] = name
    else:
        origin = copy.deepcopy(ORIGINS[index % len(ORIGINS)] if index >= 10 else [0, 0, 46])
        if index == 3:
            origin = [-68, 0, 46]
        room["start"]["origin"] = origin
        room["spawn"]["center"] = [origin[0] + rng.choice([-4, 0, 4]), 0, origin[2] + 4]
        room["spawn"]["dimensions"] = [rng.choice([20, 24, 28, 32]), 0, 12]
        if index >= 10:
            for key in ["storage_box", "packing_crate", "spare_crate", "side_table"]:
                objects[key]["position"][0] += rng.choice([-8, -4, 0, 4])
                objects[key]["position"][2] += rng.choice([-8, -4, 0, 4])
            dx = rng.choice([0, 4, 8])
            for key in ["desk", "chair", "water_cup"]:
                objects[key]["position"][0] += dx
            objects["desk"]["surface"]["anchor"][0] += dx
            safe_points = [(x,z) for x in [-84,-40,-12,20,60,88] for z in [20,32,60,72] if clear_floor(room,x,z)]
            for key in ["food_cache", "spilled_water"]:
                x,z = rng.choice(safe_points)
                objects[key]["position"] = [x,0,z]
        if index == 0:
            # Make every safe salvage object far away; desk remains protected support.
            for key, at in {"chair": [74, 0, -18], "side_table": [90, 0, 10],
                            "storage_box": [98, 0, 40], "packing_crate": [40, 0, -65],
                            "spare_crate": [102, 0, 65], "bookcase": [91, 0, -63]}.items():
                objects[key]["position"] = at
        elif index == 1:
            objects["spilled_water"]["position"] = [96, 0, 76]
        elif index in [2, 4]:
            for n, (dx, dz) in enumerate([(-16, 0), (16, 0), (-16, -16), (16, -16)] if index == 2
                                         else [(-16, 0), (16, 0), (-16, -16), (16, -16), (-32, 0), (32, 0), (0, 32)]):
                room["objects"].append(obstacle(f"local_constraint_{n}", origin[0] + dx, origin[2] + dz, 6, 6))
        elif index == 5:
            for n, (x, z) in enumerate([(-24, 36), (-32, 12), (20, 28), (16, -4)]):
                room["objects"].append(obstacle(f"route_detour_{n}", x, z, 8, 12))
        elif index == 6:
            room["civilization"]["stock"].update(food=15, water=23)
            objects["spilled_water"]["resource_profile"]["contents"]["water"] = 45
        elif index == 7:
            objects["food_cache"]["position"] = [-90, 0, 70]
            objects["spilled_water"]["position"] = [90, 0, 76]
            objects["chair"]["position"] = [-20, 0, -20]
        elif index == 8:
            for key in ["desk", "chair", "water_cup"]:
                objects[key]["position"][0] += 16
            objects["desk"]["surface"]["anchor"][0] += 16
        elif index == 9:
            objects["food_cache"]["resource_profile"]["contents"]["food"] = 180
            objects["water_cup"]["resource_profile"]["contents"]["water"] = 270
        if index != 9:
            for key, resource in [("food_cache", "food"), ("water_cup", "water"), ("spilled_water", "water")]:
                objects[key]["resource_profile"]["contents"][resource] = round(objects[key]["resource_profile"]["contents"][resource] * rng.choice([0.75, 0.85, 1, 1.15, 1.25]), 2)
        # Explicit, finite stage yields: same production labor semantics, ±25% materials.
        multiplier = rng.choice([0.75, 1, 1.25])
        for o in room["objects"]:
            if o["id"] not in ["chair", "storage_box", "packing_crate", "spare_crate", "side_table", "bookcase"]:
                continue
            dims = o["dimensions"]
            quantity = max(8, int(dims[0] * dims[1] * dims[2] // 800))
            wood = max(8, round(quantity * multiplier))
            parts = [int(wood * .4), int(wood * .3)]
            o.setdefault("resource_profile", {})["stages"] = [
                dict(name="STRIPPED", work=8, yields={"metal": 2}),
                dict(name="PARTIAL", work=12, yields={"wood": parts[0], "metal": 2}),
                dict(name="FRAME", work=12, yields={"wood": parts[1]}),
                dict(name="DEPLETED", work=10, yields={"wood": wood - sum(parts)})]
        changes.update(origin=origin, spawn=room["spawn"], salvage_yield_multiplier=multiplier,
                       object_positions={o["id"]: o["position"] for o in room["objects"]},
                       quantities={o["id"]: o.get("resource_profile", {}) for o in room["objects"]},
                       initial_stock=room["civilization"]["stock"])
    return dict(id=sid, seed=seed, name=name, classification="negative" if negative else "positive",
                mutations=changes, definition=room, days=8, generator_version=2)


def execute(config, output, godot):
    case_dir = output / config["id"]
    definition_path = case_dir / (config["definition"]["id"] + ".json")
    write(definition_path, config["definition"])
    config_path = case_dir / "config.json"
    saved = {k: v for k, v in config.items() if k != "definition"}
    saved["room_file"] = str(definition_path.resolve())
    saved["reproduction"] = f'./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario "{config_path.relative_to(ROOT).as_posix()}" -OutputDirectory verification/poc471/reproduced'
    write(config_path, saved)
    env = os.environ.copy()
    env.update(ROOMSCALE_ROOM_FILE=str(definition_path.resolve()), ROOMSCALE_POC471_CONFIG=str(config_path.resolve()),
               ROOMSCALE_POC471_RESULT=str((case_dir / "result.json").resolve()), ROOMSCALE_FISHBOWL="1",
               ROOMSCALE_DISABLE_STARTUP_CAPTURE="1", ROOMSCALE_VISUAL_DIR="")
    receipt = dict(tested_commit=subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
                   source_hashes={str(p.relative_to(ROOT)).replace("\\","/"):hashlib.sha256(p.read_bytes().replace(b"\r\n",b"\n")).hexdigest()
                                  for p in sorted((ROOT/"scripts").rglob("*.gd"))},
                   harness_hashes={name:hashlib.sha256((ROOT/name).read_bytes().replace(b"\r\n",b"\n")).hexdigest()
                                   for name in ["scripts/poc471_campaign.py","scripts/poc471_observer.gd","scripts/poc471_evidence.py","TEST_ROOM_SCALE_POC471.ps1"]})
    started = time.perf_counter()
    cmd = [godot, "--headless", "--path", str(ROOT), "--script", "res://scripts/poc471_observer.gd"]
    error = ""
    with (case_dir / "run.log").open("w", encoding="utf-8") as log:
        try:
            process = subprocess.run(cmd, env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=1200)
        except subprocess.TimeoutExpired:
            error = "Wall-clock timeout; production process killed after 1200s"
            process = None
    result_path = case_dir / "result.json"
    result = json.loads(result_path.read_text()) if result_path.exists() else dict(result="ERROR", failure=error or "Observer produced no result")
    log_text = (case_dir / "run.log").read_text()
    if "SCRIPT ERROR:" in log_text or "ERROR:" in log_text or process and process.returncode != 0 and result.get("result") == "PASS":
        result.update(result="ERROR", failure="Engine/script/process error; inspect run.log")
    result.update(id=config["id"], seed=config["seed"], name=config["name"], classification=config["classification"],
                  execution_seconds=round(time.perf_counter() - started, 3), reproduction=saved["reproduction"],
                  config_sha256=hashlib.sha256(config_path.read_bytes()).hexdigest(),
                  definition_sha256=hashlib.sha256(definition_path.read_bytes()).hexdigest())
    result.update(receipt)
    if result.get("failure", "").startswith("Generator invalid:"):
        result.update(result="REJECTED", classification="rejected")
    write(result_path, result)
    if result["result"] not in ["PASS","REJECTED"]:
        write(case_dir / "failure-package.json", dict(config=saved, definition=config["definition"], diagnostics=result))
    print(f'{config["id"]} {result["result"]} {result.get("failure", "")} wall={result["execution_seconds"]}s', flush=True)
    return result


def distribution(values):
    if not values:
        return None
    values = sorted(values)
    return dict(min=min(values), median=statistics.median(values), mean=statistics.mean(values),
                p90=values[min(len(values) - 1, int(.9 * (len(values) - 1)))], max=max(values))


def summarize(results, output):
    positives = [r for r in results if r["classification"] == "positive"]
    negatives = [r for r in results if r["classification"] == "negative"]
    soaks = [r for r in results if r["classification"] == "soak"]
    repeats = [r for r in results if r["classification"] == "repeat"]
    milestone_keys = sorted({k for r in positives for k in r.get("milestones", {})})
    timings = {k: distribution([r["milestones"][k] for r in positives if k in r.get("milestones", {})]) for k in milestone_keys}
    determinism = []
    for repeat in repeats:
        original = next((r for r in positives if repeat["id"].startswith(r["id"] + "-")), None)
        determinism.append(dict(id=repeat["id"], identical=bool(original and original.get("fingerprint") == repeat.get("fingerprint")),
                                original=original.get("fingerprint") if original else None, repeat=repeat.get("fingerprint")))
    summary = dict(total_scenarios=len(results), valid_scenarios=len(positives),
                   generator_rejections=sum(r["classification"] == "rejected" for r in results),
                   named_adversarial_passes=[r["name"] for r in positives if r["name"] in NAMES and r["result"] == "PASS"],
                   valid_passes=sum(r["result"] == "PASS" for r in positives),
                   valid_failures=sum(r["result"] != "PASS" for r in positives), negative_scenarios=len(negatives),
                   expected_negative_outcomes=sum(r["result"] == "PASS" for r in negatives),
                   unexpected_negative_outcomes=sum(r["result"] != "PASS" for r in negatives),
                   population=distribution([r.get("final", {}).get("population", 5) for r in positives]),
                   shelter=distribution([r.get("final", {}).get("shelter", 0) for r in positives]),
                   structure_completion_counts={k: sum(r.get("structures", {}).get(k, 0) for r in positives) for k in ["shelter", "depot", "workshop", "housing"]},
                   traversal_success_count=sum("elevated_territory" in r.get("milestones", {}) for r in positives),
                   milestone_timing_distributions=timings,
                   deadlock_count=sum(r.get("deadlock", False) for r in results),
                   invariant_violation_count=sum(len(r.get("violations", [])) for r in results),
                   long_soak_results=soaks, determinism_results=determinism,
                   scenario_seeds={r["id"]: r["seed"] for r in results},
                   execution_durations={r["id"]: r["execution_seconds"] for r in results},
                   production_bugs_discovered=[], production_bugs_fixed=[], unresolved_bugs=[], regression_results={},
                   results=[{k: r.get(k) for k in ["id", "name", "seed", "classification", "result", "failure", "fingerprint", "execution_seconds", "validation", "milestones", "final", "maxima", "stall_windows", "reproduction"]} for r in results])
    write(output / "campaign-summary.json", summary)
    lines = ["# POC 4.7.1 scenario matrix", "", "Times are production simulation seconds. Missing milestones are shown as —.", "",
             "| ID | Seed | Class | Name / mutations | Validation | Result | Shelter | Depot | Workshop | Sixth | Traversal | Population | Failure |",
             "|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|---|"]
    for r in results:
        m = r.get("milestones", {})
        times = [str(round(m[k], 1)) if k in m else "—" for k in ["shelter_complete", "depot_complete", "workshop_complete", "sixth_citizen", "traversal_complete"]]
        lines.append("| " + " | ".join([r["id"], str(r["seed"]), r["classification"], r["name"],
                     str(r.get("validation", {}).get("solvable", "rejected")), r["result"], *times,
                     str(r.get("final", {}).get("population", "—")), r.get("failure", "").replace("|", "/")]) + " |")
    lines.extend(["", "## Timing outliers", ""])
    for k in ["shelter_complete", "workshop_complete", "sixth_citizen", "traversal_complete"]:
        available = sorted([r for r in positives if k in r.get("milestones", {})], key=lambda r: r["milestones"][k], reverse=True)
        lines.append(f"- {k}: " + "; ".join(f'{r["id"]} {r["milestones"][k]:.1f}s' for r in available[:3]))
    (output / "scenario-matrix.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return summary


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--mode", choices=["short", "full", "soak", "reproduce", "generate", "review", "explore"], default="full")
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", default="verification/poc471/final")
    parser.add_argument("--count", type=int, default=40)
    parser.add_argument("--seed", type=int, default=471000)
    parser.add_argument("--days", type=float, default=8)
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--scenario")
    args = parser.parse_args()
    # The Windows console launcher starts a child engine. Run the engine itself
    # so subprocess timeout cleanup cannot leave an orphan simulation running.
    engine_path = Path(args.godot.replace("_console.exe",".exe"))
    if engine_path.exists():
        args.godot = str(engine_path)
    output = (ROOT / args.output).resolve()
    output.relative_to(ROOT)
    if args.mode == "review":
        results = [json.loads(p.read_text()) for p in sorted(output.glob("*/result.json"))]
        summary = summarize(results,output)
        print(json.dumps({k:summary[k] for k in ["total_scenarios","valid_passes","valid_failures","generator_rejections"]}))
        return 0
    if args.mode == "reproduce":
        saved = json.loads((ROOT / args.scenario).read_text())
        saved["definition"] = json.loads(Path(saved["room_file"]).read_text())
        configs = [saved]
    else:
        count = 10 if args.mode == "short" else args.count
        configs = [generate(i, args.seed + i) for i in range(count)]
        for c in configs:
            c["days"] = args.days
        if args.mode != "generate":
            configs += [generate(i, args.seed + 1000 + i, True) for i in range(5)] if args.mode in ["short", "full"] else []
        if args.mode in ["full", "soak"]:
            soaks = []
            for n, index in enumerate([0, 5, 9]):
                c = generate(index, args.seed + index)
                c.update(id=f"SOAK-{n + 1:02}", days=90 if n == 0 else 60, classification="soak")
                soaks.append(c)
            if args.mode == "soak":
                configs = soaks
            else:
                configs += soaks
                for index in [0, 5, 8]:
                    for n in [1, 2]:
                        c = generate(index, args.seed + index)
                        c.update(id=f'{c["id"]}-REPEAT-{n}', classification="repeat", days=args.days)
                        configs.append(c)
        if args.mode == "explore":
            # Small increments around observed placement and supply weak points.
            configs = []
            for n, extra in enumerate([0,1,2,3,4,5]):
                c = generate(5,args.seed+5)
                c.update(id=f"EXP-ROUTING-{n:02}")
                for j in range(extra):
                    c["definition"]["objects"].append(obstacle(f"additional_detour_{j}", -44+j*16, 60,6,6))
                c["mutations"]["additional_detours"] = extra
                configs.append(c)
            for n, amount in enumerate([30,37.5,45,52.5,60,75]):
                c = generate(1,args.seed+1)
                c.update(id=f"EXP-WATER-{n:02}")
                next(o for o in c["definition"]["objects"] if o["id"] == "spilled_water")["resource_profile"]["contents"]["water"] = amount
                c["mutations"]["bootstrap_water"] = amount
                configs.append(c)
            for n, origin in enumerate([[0,0,8],[4,0,8],[8,0,8],[4,0,12],[4,0,16],[4,0,20]]):
                c = generate(17,args.seed+17)
                c.update(id=f"EXP-ORIGIN-{n:02}")
                c["definition"]["start"]["origin"] = origin
                c["definition"]["spawn"]["center"] = [origin[0]+4,0,origin[2]+4]
                c["mutations"]["origin_probe"] = origin
                configs.append(c)
            for n in range(2):
                c = generate(8,args.seed+8)
                c.update(id=f"EXP-IDENTITY-{n:02}")
                for o in c["definition"]["objects"]:
                    o["id"] = "alternative_" + o["id"]
                    if o.get("surface"):
                        o["surface"]["region_id"] = "ALTERNATIVE_TARGET"
                    if o.get("resource_profile",{}).get("region_id"):
                        o["resource_profile"]["region_id"] = "ALTERNATIVE_TARGET"
                c["definition"]["target_surface_id"] = "ALTERNATIVE_TARGET"
                if n == 1:
                    c["definition"]["objects"].reverse()
                c["mutations"]["identity_probe"] = "all object IDs and target region renamed; reversed order" if n else "all object IDs and target region renamed"
                configs.append(c)
    # Prove same generation call produces identical bytes before executing anything.
    for i in range(40):
        assert generate(i, args.seed + i) == generate(i, args.seed + i)
    if args.mode == "generate":
        for c in configs:
            write(output / c["id"] / "generated.json", c)
        return 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
        results = list(executor.map(lambda c: execute(c, output, args.godot), configs))
    summary = summarize(results, output)
    print(json.dumps({k: summary[k] for k in ["total_scenarios", "valid_passes", "valid_failures", "expected_negative_outcomes", "unexpected_negative_outcomes", "invariant_violation_count", "deadlock_count"]}))
    required_positive_count = 30 if args.mode == "full" else 10 if args.mode == "short" else 0
    return int(any(r["result"] not in ["PASS","REJECTED"] for r in results)
               or summary["valid_scenarios"] < required_positive_count
               or args.mode in ["short","full"] and set(summary["named_adversarial_passes"]) != set(NAMES)
               or any(not r["identical"] for r in summary["determinism_results"]))


if __name__ == "__main__":
    raise SystemExit(main())
