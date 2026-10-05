"""Replay retained POC471 definitions exactly; add finite spatial adversaries."""

from __future__ import annotations

import argparse
import concurrent.futures
import copy
import json
import random
from pathlib import Path

import poc471_campaign as prior

ROOT = prior.ROOT


def retained(path: Path) -> dict:
    config = json.loads(path.read_text(encoding="utf-8"))
    config["definition"] = json.loads(
        (path.parent / Path(config["room_file"]).name).read_text(encoding="utf-8")
    )
    return config


def placements():
    cases = []
    for index in range(30):
        seed = 472000 + index
        rng = random.Random(seed)
        room = json.loads((ROOT / "rooms/room_poc47.json").read_text(encoding="utf-8"))
        group, variant = divmod(index, 5)
        additions = []
        if group == 0:
            name = "Wall-adjacent founders"
            origin = [[0, 0, 76], [104, 0, 80], [-104, 0, 76], [110, 0, -20], [-108, 0, -16]][
                variant
            ]
        elif group == 1:
            name = "Large furniture beside origin"
            origin = [[42, 0, 44], [62, 0, 24], [86, 0, 72], [-32, 0, 44], [-78, 0, 44]][variant]
            additions.append(
                prior.obstacle(
                    "large_furniture",
                    origin[0],
                    origin[2] + (23 if origin[2] < 60 else -23),
                    28 + variant * 2,
                    12,
                )
            )
        elif group == 2:
            name = "Narrow legal settlement corridor"
            origin = [0, 0, 44]
            for side in [-1, 1]:
                additions.append(
                    prior.obstacle(
                        f"corridor_{side}", side * (25 + variant), 48, 6, 48 + variant * 4
                    )
                )
        elif group == 3:
            name = "Separated open areas with legal connecting gaps"
            origin = [-24 + variant * 2, 0, 58]
            additions += [
                prior.obstacle("divider_south", 34, 36, 6, 62),
                prior.obstacle("divider_north", 34, -48, 6, 62 - variant * 2),
            ]
        elif group == 4:
            name = "Irregular obstacle arrangement"
            origin = [40 + variant * 4, 0, 56]
            for n in range(5):
                block = prior.obstacle(f"irregular_{n}", -8 + n * 22, 38 + (n % 2) * 32, 6, 8)
                block["rotation_degrees"] = rng.choice([15, 30, 45])
                additions.append(block)
        else:
            name = "Nearest legal site threatens downstream combinations"
            origin = [0, 0, 54]
            for side in [-1, 1]:
                additions.append(
                    prior.obstacle(f"pocket_side_{side}", side * (24 + variant), 58, 4, 40)
                )
            additions.append(prior.obstacle("pocket_cap", 0, 80, 52 + variant * 2, 4))
        room["objects"] += additions
        if group == 2:
            next(o for o in room["objects"] if o["id"] == "spilled_water")["position"] = [0, 0, 16]
        room["start"]["origin"] = origin
        room["spawn"] = dict(center=origin.copy(), dimensions=[8, 0, 8])
        room["id"] = f"PLACE-{index + 1:03}"
        cases.append(
            dict(
                id=room["id"],
                seed=seed,
                name=name,
                classification="positive",
                days=8,
                definition=room,
                generator_version=1,
                mutations=dict(
                    origin=origin,
                    protected_obstacles=additions,
                    finite_quantities="unchanged canonical",
                ),
            )
        )
    cases.append(packing_layout())
    return cases


def packing_layout():
    room = copy.deepcopy(impossible_layout()["definition"])
    room["objects"] = [o for o in room["objects"] if not o["id"].startswith("placement_block_")]
    # Keep the connected 12-inch aisles, carving exactly one 46x38 building
    # pocket from protected tiles. A central apron wastes a required column.
    for x in range(-108, 109, 24):
        for z in [-68, -44, -20, 4, 28, 52, 76]:
            left, right, bottom, top = x - 6, x + 6, z - 6, z + 6
            ix0, ix1 = max(left, -23), min(right, 23)
            iz0, iz1 = max(bottom, 32), min(top, 70)
            rectangles = [(left, right, bottom, top)]
            if ix0 < ix1 and iz0 < iz1:
                rectangles = [
                    (left, ix0, bottom, top),
                    (ix1, right, bottom, top),
                    (ix0, ix1, bottom, iz0),
                    (ix0, ix1, iz1, top),
                ]
            for n, (a, b, c, d) in enumerate(rectangles):
                if b - a > 0.01 and d - c > 0.01:
                    room["objects"].append(
                        prior.obstacle(
                            f"pocket_tile_{x}_{z}_{n}", (a + b) / 2, (c + d) / 2, b - a, d - c
                        )
                    )
    room["objects"] += [
        prior.obstacle("pocket_west", -25, 51, 4, 38),
        prior.obstacle("pocket_east", 25, 51, 4, 38),
        prior.obstacle("pocket_north", 0, 72, 46, 4),
        prior.obstacle("pocket_door_left", -13.5, 30, 19, 4),
        prior.obstacle("pocket_door_right", 13.5, 30, 19, 4),
    ]
    room["start"]["origin"] = [0, 0, 8]
    room["spawn"] = dict(center=[0, 0, 8], dimensions=[8, 0, 8])
    room["id"] = "PLACE-031"
    return dict(
        id=room["id"],
        seed=472030,
        name="Only some legal apron combinations fit the founding chain",
        classification="positive",
        days=8,
        definition=room,
        mutations=dict(
            proof="one 46x38 pocket within protected 12-inch aisles; central apron cannot preserve four sites",
            finite_quantities="unchanged canonical",
        ),
    )


def impossible_layout():
    room = json.loads((ROOT / "rooms/room_poc47.json").read_text(encoding="utf-8"))
    # Tile the only formerly open region with protected obstacles, leaving
    # connected 12-inch aisles. No 20x18 reserved construction apron can fit.
    for x in range(-108, 109, 24):
        for z in [-68, -44, -20, 4, 28, 52, 76]:
            room["objects"].append(prior.obstacle(f"placement_block_{x}_{z}", x, z, 12, 12))
    room["start"]["origin"] = [0, 0, 48]
    room["spawn"] = dict(center=[0, 0, 48], dimensions=[8, 0, 8])
    room["id"] = "NEG-PLACEMENT-01"
    return dict(
        id=room["id"],
        seed=472999,
        name="No Complete Founding Layout",
        classification="negative",
        days=8,
        definition=room,
        mutations=dict(
            proof="12-inch gaps between 12-inch protected boxes on 24-inch spacing; a 20x18 apron cannot fit"
        ),
    )


def review(results, output, *, publish: bool = True):
    summary = prior.summarize(results, output, publish=False)
    summary["former_fixed_apron_negative"] = next(
        (r for r in summary["results"] if r["id"] == "NEG-03"), None
    )
    summary["placement_positive_passes"] = sum(
        r["id"].startswith("PLACE-") and r["result"] == "PASS" for r in results
    )
    summary["previous_79_positive_passes"] = sum(
        r["id"].startswith(("POS-", "EXP-", "EDGE-"))
        and "REPEAT" not in r["id"]
        and r["result"] == "PASS"
        and r["id"] not in ["POS-023", "POS-029"]
        for r in results
    )
    summary["formerly_rejected"] = {
        r["id"]: r["result"] for r in results if r["id"] in ["POS-023", "POS-029"]
    }
    if publish:
        prior.summarize(results, output)
        matrix = output / "scenario-matrix.md"
        matrix.write_text(
            matrix.read_text(encoding="utf-8").replace(
                "# POC 4.7.1 scenario matrix", "# POC 4.7.2 scenario matrix", 1
            ),
            encoding="utf-8",
        )
        prior.write(output / "campaign-summary.json", summary)
    return summary


def acceptance_errors(results: list[dict], mode: str) -> list[str]:
    """Campaign acceptance checks remain active with optimized Python."""
    errors = []
    ids = [r["id"] for r in results]
    if not results or len(set(ids)) != len(ids):
        errors.append("Empty campaign or duplicate scenario IDs")
    if any(r["result"] != "PASS" for r in results):
        errors.append("Unexpected campaign outcome")
    if any(r.get("violations") or r.get("deadlock") for r in results):
        errors.append("Invariant violation or deadlock")
    counts = {
        "full": 127,
        "development": 37,
        "placement": 31,
        "soak": 3,
        "control": 1,
        "reproduce": 1,
    }
    if mode in counts and len(results) != counts[mode]:
        errors.append(f"Incomplete {mode} campaign: {len(results)}/{counts[mode]}")
    by_id = {r["id"]: r for r in results}
    if mode in ("full", "development", "placement"):
        if not {f"PLACE-{i:03}" for i in range(1, 32)} <= by_id.keys():
            errors.append("Missing required placement case")
    if mode == "full":
        # Retained 471:61 declared positives +20 exploration;31 new placements.
        if sum(r["classification"] == "positive" for r in results) != 112:
            errors.append("Expected all112 declared positive worlds")
        expected = {f"POS-{i:03}" for i in range(1, 61)} | {"EDGE-FRACTION-01", "NEG-PLACEMENT-01"}
        expected |= {f"NEG-{i:02}" for i in range(1, 6)}
        expected |= {f"EXP-ROUTING-{i:02}" for i in range(6)}
        expected |= {f"EXP-WATER-{i:02}" for i in range(6)}
        expected |= {f"EXP-ORIGIN-{i:02}" for i in range(6)}
        expected |= {f"EXP-IDENTITY-{i:02}" for i in range(2)}
        expected |= {f"POS-{i:03}-REPEAT-{repeat}" for i in (1, 6, 9) for repeat in (1, 2)}
        expected |= {f"SOAK-{i:02}" for i in range(1, 4)}
        expected |= {f"PLACE-{i:03}" for i in range(1, 32)}
        if set(ids) != expected:
            errors.append("Required full campaign scenario set differs")
        repeats = [r for r in results if r["classification"] == "repeat"]
        if len(repeats) != 6 or any(
            not r.get("fingerprint")
            or r["fingerprint"] != by_id.get(r["id"].split("-REPEAT-")[0], {}).get("fingerprint")
            for r in repeats
        ):
            errors.append("Six deterministic repeats are missing or different")
        if by_id.get("NEG-05", {}).get("validation", {}).get("expected_rejection") is not True:
            errors.append("Disconnected NEG-05 must retain expected preflight rejection")
        if abs(by_id.get("NEG-03", {}).get("final", {}).get("seconds", 0) - 4800) > 0.001:
            errors.append("Former fixed-apron NEG-03 must complete its feasible production run")
    if mode in ("full", "soak"):
        for sid, days in (("SOAK-01", 90), ("SOAK-02", 60), ("SOAK-03", 60)):
            if abs(by_id.get(sid, {}).get("final", {}).get("seconds", 0) - days * 600) > 0.001:
                errors.append(f"Incomplete required soak: {sid}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "--mode",
        choices=["development", "full", "placement", "soak", "reproduce", "review", "control"],
        default="full",
    )
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", default="verification/poc472/final")
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--scenario")
    args = parser.parse_args()
    if args.workers < 1:
        parser.error("workers must be positive")
    if args.mode == "reproduce" and not args.scenario:
        parser.error("reproduce requires --scenario")
    engine = Path(args.godot.replace("_console.exe", ".exe"))
    if engine.exists():
        args.godot = str(engine)
    output = (ROOT / args.output).resolve()
    output.relative_to(ROOT)
    if args.mode == "review":
        results = [
            json.loads(p.read_text(encoding="utf-8")) for p in sorted(output.glob("*/result.json"))
        ]
        errors = acceptance_errors(results, "full")
        if errors:
            print(json.dumps({"acceptance_errors": errors}))
            return 1
        review(results, output)
        return 0
    if args.mode == "control":
        configs = [retained(ROOT / "verification/poc471/final/POS-001/config.json")]
    elif args.mode == "reproduce":
        configs = [retained(ROOT / args.scenario)]
    elif args.mode == "placement":
        configs = placements()
    else:
        core_paths = sorted((ROOT / "verification/poc471/final").glob("*/config.json"))
        exploration_paths = sorted((ROOT / "verification/poc471/exploration").glob("*/config.json"))
        if len(core_paths) != 75 or len(exploration_paths) != 20:
            raise ValueError("Incomplete retained baseline input set")
        configs = [retained(p) for p in core_paths + exploration_paths]
        if len({c["id"] for c in configs}) != 95:
            raise ValueError("Duplicate retained baseline input")
        if args.mode == "soak":
            configs = [c for c in configs if c["classification"] == "soak"]
        if args.mode == "development":
            configs = [
                c
                for c in configs
                if c["id"] in ["POS-001", "POS-006", "POS-018", "POS-023", "POS-029", "NEG-03"]
            ] + placements()
        if args.mode == "full":
            configs += placements() + [impossible_layout()]
    if placements() != placements():
        raise ValueError("Non-deterministic generator")
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
        results = list(
            executor.map(
                lambda c: prior.execute(
                    c,
                    output,
                    args.godot,
                    observer="res://scripts/poc472_unobserved.gd"
                    if args.mode == "control"
                    else "res://scripts/poc472_observer.gd",
                    extra_harness=(
                        "scripts/poc472_campaign.py",
                        "scripts/poc472_observer.gd",
                        "TEST_ROOM_SCALE_POC472.ps1",
                        "scripts/poc472_unobserved.gd",
                    ),
                ),
                configs,
            )
        )
    summary = review(results, output)
    print(
        json.dumps(
            {
                k: summary[k]
                for k in [
                    "total_scenarios",
                    "valid_passes",
                    "valid_failures",
                    "generator_rejections",
                    "expected_negative_outcomes",
                    "unexpected_negative_outcomes",
                    "placement_positive_passes",
                    "previous_79_positive_passes",
                    "formerly_rejected",
                    "invariant_violation_count",
                    "deadlock_count",
                ]
            }
        )
    )
    errors = acceptance_errors(results, args.mode)
    if errors:
        print(json.dumps({"acceptance_errors": errors}))
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
