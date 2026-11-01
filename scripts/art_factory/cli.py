"""Command line entry points for the offline RoomScale Art Factory."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from .factory import ArtFactory
from .godot_bridge import GodotArtBridge
from .models import ArtBrief, ArtEvaluation, ArtRecipe
from .visual_director import VisualDirectorGateRequired


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

    visual_director = commands.add_parser(
        "visual-director", help="prepare and record policy-gated visual target development"
    )
    visual_director_commands = visual_director.add_subparsers(
        dest="visual_director_command", required=True
    )
    visual_status = visual_director_commands.add_parser(
        "status", help="show policy, target, best 3D candidate, and production asset"
    )
    visual_status.add_argument("asset_id")
    visual_prepare = visual_director_commands.add_parser(
        "prepare", help="open a visual-development case and scaffold its VisualBrief"
    )
    visual_prepare.add_argument("asset_id")
    visual_approve = visual_director_commands.add_parser(
        "approve", help="record a pixel-reviewed approved visual target"
    )
    visual_approve.add_argument("asset_id")
    visual_approve.add_argument("--target", required=True, help="project-relative image path")
    visual_approve.add_argument("--review", required=True, help="project-relative pixel-review evidence")
    visual_approve.add_argument("--concept-id", default="")
    visual_backlog = visual_director_commands.add_parser(
        "backlog",
        help="stop a reviewed target episode and preserve its best 3D/production assets",
    )
    visual_backlog.add_argument("asset_id")
    visual_backlog.add_argument(
        "--reason", required=True, help="specific unresolved visual-transfer defect"
    )
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    factory = ArtFactory(args.project_root)
    if args.command == "save-brief":
        brief = ArtBrief.from_dict(_read_json(args.brief))
        print(factory.save_brief(brief))
    elif args.command == "generate":
        recipe = ArtRecipe.from_dict(_read_json(args.recipe))
        try:
            candidate = factory.generate_candidate(
                args.asset_id, recipe, args.timeout, parent_candidate_id=args.parent
            )
        except VisualDirectorGateRequired as exc:
            print(json.dumps({
                "status": "visual_director_required",
                "asset_id": exc.asset_id,
                "reasons": exc.reasons,
                "case_file": exc.case_file,
                "visual_brief_file": exc.visual_brief_file,
                "next_step": (
                    "Generate and pixel-review concept directions, then record a passing target "
                    "with `roomscale-art visual-director approve`."
                ),
            }, indent=2))
            return 3
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
    elif args.command == "visual-director":
        if args.visual_director_command == "status":
            result = factory.visual_director_status(args.asset_id)
        elif args.visual_director_command == "prepare":
            result = factory.prepare_visual_director(args.asset_id)
        elif args.visual_director_command == "backlog":
            result = factory.backlog_visual_director_case(args.asset_id, args.reason)
        else:
            result = factory.approve_visual_target(
                args.asset_id, args.target, args.review, concept_id=args.concept_id
            )
        print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
