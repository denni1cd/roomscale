"""Command line entry points for the offline RoomScale Art Factory."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from .factory import ArtFactory
from .godot_bridge import GodotArtBridge
from .models import ArtBrief, ArtEvaluation, ArtRecipe


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected a JSON object: {path}")
    return value


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(prog="roomscale-art", description=__doc__)
    result.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="RoomScale repository root (defaults to the parent of scripts/)",
    )
    commands = result.add_subparsers(dest="command", required=True)

    brief = commands.add_parser("save-brief", help="validate and persist an ArtBrief JSON")
    brief.add_argument("brief", type=Path)

    generate = commands.add_parser(
        "generate", help="run a recorded recipe and preserve its attempt"
    )
    generate.add_argument("asset_id")
    generate.add_argument("recipe", type=Path)
    generate.add_argument("--timeout", type=int, default=1200)
    generate.add_argument("--parent", default="", help="prior candidate ID this recipe responds to")

    validate = commands.add_parser(
        "validate", help="Godot-import and technically validate a candidate"
    )
    validate.add_argument("candidate_id")
    validate.add_argument("--godot", type=Path, required=True)

    render = commands.add_parser("render", help="capture standardized production RoomScale renders")
    render.add_argument("candidate_id")
    render.add_argument("--godot", type=Path, required=True)
    render.add_argument(
        "--room-file", default="verification/poc2/candidates/primary/attempt-7/room_photo_luna.json"
    )

    evaluate = commands.add_parser(
        "record-evaluation", help="validate and store evidence-backed evaluation JSON"
    )
    evaluate.add_argument("evaluation", type=Path)

    promote = commands.add_parser(
        "promote", help="promote a passing challenger to the stable registry"
    )
    promote.add_argument("candidate_id")

    verify = commands.add_parser("verify", help="verify the registered asset and content hash")
    verify.add_argument("asset_id")

    commands.add_parser("registry", help="show the stable accepted-asset registry")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    factory = ArtFactory(args.project_root)
    if args.command == "save-brief":
        brief = ArtBrief.from_dict(_read_json(args.brief))
        print(factory.save_brief(brief))
    elif args.command == "generate":
        recipe = ArtRecipe.from_dict(_read_json(args.recipe))
        candidate = factory.generate_candidate(
            args.asset_id, recipe, args.timeout, parent_candidate_id=args.parent
        )
        print(json.dumps(candidate.to_dict(), indent=2))
        return 0 if candidate.generation_result.get("status") == "pass" else 2
    elif args.command == "validate":
        result = GodotArtBridge(factory, args.godot).validate_candidate(args.candidate_id)
        print(json.dumps(result, indent=2))
    elif args.command == "render":
        result = GodotArtBridge(factory, args.godot).render_candidate(
            args.candidate_id, room_file=args.room_file
        )
        print(json.dumps(result, indent=2))
    elif args.command == "record-evaluation":
        evaluation = ArtEvaluation.from_dict(_read_json(args.evaluation))
        print(factory.record_evaluation(evaluation))
    elif args.command == "promote":
        print(json.dumps(factory.promote(args.candidate_id), indent=2))
    elif args.command == "verify":
        passed, detail = factory.registry.verify(args.asset_id)
        print(
            json.dumps({"asset_id": args.asset_id, "verified": passed, "detail": detail}, indent=2)
        )
        return 0 if passed else 2
    elif args.command == "registry":
        print(json.dumps(factory.registry.read(), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
