"""Persistent candidate, render, evaluation, and promotion workflow."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Any

from .models import ArtBrief, ArtCandidate, ArtEvaluation, ArtRecipe
from .registry import AssetRegistry, atomic_write_json, sha256_file, validate_asset_id


def _now_utc() -> str:
    return datetime.now(UTC).isoformat(timespec="seconds")


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected a JSON object: {path}")
    return value


def _safe_relative_path(value: str) -> PurePosixPath:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or not path.parts or any(part in {"", ".", ".."} for part in path.parts):
        raise ValueError(f"path must be a safe project-relative path: {value!r}")
    return path


class ArtFactory:
    """Offline content authoring. Runtime RoomScale code consumes only accepted registry entries."""

    def __init__(self, project_root: Path) -> None:
        self.project_root = project_root.resolve()
        self.art_root = self.project_root / "art"
        self.registry = AssetRegistry(self.project_root)

    def save_brief(self, brief: ArtBrief) -> Path:
        errors = brief.validate()
        if errors:
            raise ValueError("invalid ArtBrief: " + "; ".join(errors))
        validate_asset_id(brief.asset_id)
        path = self.art_root / brief.asset_id / "brief.json"
        atomic_write_json(path, brief.to_dict())
        return path

    def load_brief(self, asset_id: str) -> ArtBrief:
        validate_asset_id(asset_id)
        brief = ArtBrief.from_dict(_read_json(self.art_root / asset_id / "brief.json"))
        errors = brief.validate()
        if errors:
            raise ValueError("invalid ArtBrief: " + "; ".join(errors))
        return brief

    def create_candidate(
        self,
        asset_id: str,
        recipe: ArtRecipe,
        source_files: dict[str, Path],
        parent_candidate_id: str = "",
    ) -> ArtCandidate:
        """Materialize a reproducible attempt from files produced by its recorded recipe."""
        validate_asset_id(asset_id)
        brief = self.load_brief(asset_id)
        errors = recipe.validate()
        if errors:
            raise ValueError("invalid ArtRecipe: " + "; ".join(errors))
        if len(source_files) == 0:
            raise ValueError("a candidate needs at least one generated/import-ready file")
        version, candidate_id, candidate_root = self._reserve_candidate(
            asset_id, brief.iteration_budget
        )
        candidate_root.mkdir(parents=True, exist_ok=False)
        copied_files: list[str] = []
        try:
            for destination, source in source_files.items():
                relative = _safe_relative_path(destination)
                source = source.resolve()
                if not source.is_file():
                    raise ValueError(f"candidate source file does not exist: {source}")
                target = candidate_root.joinpath(*relative.parts)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
                copied_files.append(target.relative_to(self.project_root).as_posix())
            recipe_path = candidate_root / "recipe.json"
            atomic_write_json(recipe_path, recipe.to_dict())
            candidate = ArtCandidate(
                candidate_id=candidate_id,
                asset_id=asset_id,
                version=version,
                status="challenger",
                asset_files=copied_files,
                recipe_file=recipe_path.relative_to(self.project_root).as_posix(),
                created_at_utc=_now_utc(),
                parent_candidate_id=parent_candidate_id,
            )
            self._save_candidate(candidate)
        except BaseException:
            shutil.rmtree(candidate_root, ignore_errors=True)
            raise
        return candidate

    def generate_candidate(
        self,
        asset_id: str,
        recipe: ArtRecipe,
        timeout_seconds: int = 1200,
        parent_candidate_id: str = "",
    ) -> ArtCandidate:
        """Run a recorded local generator and preserve outputs or a blocked attempt."""
        validate_asset_id(asset_id)
        brief = self.load_brief(asset_id)
        errors = recipe.validate()
        if errors:
            raise ValueError("invalid ArtRecipe: " + "; ".join(errors))
        if not recipe.generator_command:
            raise ValueError(
                "recipe has no local generator command; use create_candidate for externally generated files"
            )
        if parent_candidate_id:
            parent = self.load_candidate(parent_candidate_id)
            if parent.asset_id != asset_id:
                raise ValueError("challenger parent must belong to the same stable asset id")
        version, candidate_id, candidate_root = self._reserve_candidate(
            asset_id, brief.iteration_budget
        )
        candidate_root.mkdir(parents=True, exist_ok=False)
        generated_root = candidate_root / "generated"
        generated_root.mkdir()
        recipe_path = candidate_root / "recipe.json"
        atomic_write_json(recipe_path, recipe.to_dict())
        candidate = ArtCandidate(
            candidate_id=candidate_id,
            asset_id=asset_id,
            version=version,
            status="challenger",
            asset_files=[],
            recipe_file=recipe_path.relative_to(self.project_root).as_posix(),
            created_at_utc=_now_utc(),
            parent_candidate_id=parent_candidate_id,
        )
        command = [
            argument.format(
                project_root=str(self.project_root),
                output_dir=str(generated_root),
                brief_path=str(self.art_root / asset_id / "brief.json"),
                recipe_path=str(recipe_path),
            )
            for argument in recipe.generator_command
        ]
        environment = os.environ.copy()
        environment.update(
            {
                "ROOMSCALE_ART_FACTORY_OUTPUT_DIR": str(generated_root),
                "ROOMSCALE_ART_FACTORY_ASSET_ID": asset_id,
                "ROOMSCALE_ART_FACTORY_BRIEF": str(self.art_root / asset_id / "brief.json"),
                "ROOMSCALE_ART_FACTORY_RECIPE": str(recipe_path),
                "ROOMSCALE_ART_FACTORY_CANDIDATE": candidate_id,
            }
        )
        try:
            process = subprocess.run(
                command,
                cwd=self.project_root,
                env=environment,
                capture_output=True,
                text=True,
                errors="replace",
                timeout=timeout_seconds,
                check=False,
            )
            output = process.stdout + process.stderr
            result: dict[str, Any] = {
                "status": "pass" if process.returncode == 0 else "fail",
                "exit_code": process.returncode,
            }
        except subprocess.TimeoutExpired as exc:
            stdout = (
                exc.stdout.decode(errors="replace")
                if isinstance(exc.stdout, bytes)
                else exc.stdout or ""
            )
            stderr = (
                exc.stderr.decode(errors="replace")
                if isinstance(exc.stderr, bytes)
                else exc.stderr or ""
            )
            output = stdout + stderr + f"\nTimed out after {timeout_seconds}s.\n"
            result = {"status": "fail", "exit_code": None, "timed_out": True}
        if result.get("status") == "pass":
            script_errors = [
                line.strip()
                for line in output.splitlines()
                if line.lstrip().startswith("SCRIPT ERROR:")
            ]
            if script_errors:
                result = {
                    "status": "fail",
                    "exit_code": result.get("exit_code"),
                    "reason": f"generator emitted a script error: {script_errors[0]}",
                }
        (candidate_root / "generation.log").write_text(output, encoding="utf-8")
        declared_outputs = recipe.parameters.get("outputs", [])
        if result["status"] == "pass":
            if not isinstance(declared_outputs, list) or not declared_outputs:
                result = {
                    "status": "fail",
                    "exit_code": result["exit_code"],
                    "reason": "recipe must declare generated outputs",
                }
            else:
                for output_path in declared_outputs:
                    relative = _safe_relative_path(str(output_path))
                    target = generated_root.joinpath(*relative.parts)
                    if not target.is_file():
                        result = {
                            "status": "fail",
                            "exit_code": result["exit_code"],
                            "reason": f"declared generator output is missing: {output_path}",
                        }
                        break
                    candidate.asset_files.append(target.relative_to(self.project_root).as_posix())
        candidate.generation_result = {
            **result,
            "recorded_at_utc": _now_utc(),
            "command": command,
        }
        if result["status"] != "pass":
            candidate.status = "blocked"
            candidate.technical_validation = {
                "status": "fail",
                "reason": result.get("reason", "generator returned a failure"),
                "recorded_at_utc": _now_utc(),
            }
        self._save_candidate(candidate)
        return candidate

    def load_candidate(self, candidate_id: str) -> ArtCandidate:
        asset_id, version = self._split_candidate_id(candidate_id)
        path = self.art_root / asset_id / "iterations" / f"v{version:03d}" / "candidate.json"
        candidate = ArtCandidate.from_dict(_read_json(path))
        errors = candidate.validate()
        if errors:
            raise ValueError("invalid ArtCandidate: " + "; ".join(errors))
        return candidate

    def record_validation(self, candidate_id: str, result: dict[str, Any]) -> ArtCandidate:
        candidate = self.load_candidate(candidate_id)
        if result.get("status") not in {"pass", "fail"}:
            raise ValueError("technical validation status must be 'pass' or 'fail'")
        result = {**result, "recorded_at_utc": _now_utc()}
        candidate.technical_validation = result
        if result["status"] == "fail":
            candidate.status = "rejected"
        self._save_candidate(candidate)
        return candidate

    def record_render(
        self, candidate_id: str, phase: str, render_file: Path, metadata: dict[str, Any]
    ) -> ArtCandidate:
        candidate = self.load_candidate(candidate_id)
        if metadata.get("production_path") is not True:
            raise ValueError(
                "candidate evidence must be captured through the production RoomScale render path"
            )
        if not phase.strip():
            raise ValueError("render phase must be named")
        source = render_file.resolve()
        if not source.is_file():
            raise ValueError(f"render does not exist: {source}")
        candidate_root = self._candidate_root(candidate)
        try:
            source.relative_to(candidate_root)
            target = source
        except ValueError:
            target = candidate_root / "renders" / f"{phase}{source.suffix.lower()}"
            target.parent.mkdir(parents=True, exist_ok=True)
            if source != target.resolve():
                shutil.copy2(source, target)
        source_relative = target.relative_to(self.project_root).as_posix()
        evidence = dict(metadata)
        evidence.update(
            {
                "phase": phase,
                "path": source_relative,
                "sha256": sha256_file(target),
                "captured_at_utc": _now_utc(),
            }
        )
        candidate.renders.append(evidence)
        self._save_candidate(candidate)
        return candidate

    def record_evaluation(self, evaluation: ArtEvaluation) -> Path:
        candidate = self.load_candidate(evaluation.candidate_id)
        brief = self.load_brief(candidate.asset_id)
        source_imagery_required = bool(brief.source_room_definition or brief.reference_images)
        errors = evaluation.validate(
            source_resemblance_required=source_imagery_required,
            allow_stylization=brief.allow_stylization,
        )
        if errors:
            raise ValueError("invalid ArtEvaluation: " + "; ".join(errors))
        if evaluation.candidate_id != candidate.candidate_id:
            raise ValueError("evaluation candidate ID mismatch")
        for evidence_path in evaluation.render_evidence:
            relative = _safe_relative_path(evidence_path)
            if not self.project_root.joinpath(*relative.parts).is_file():
                raise ValueError(f"evaluation references missing render evidence: {evidence_path}")
            if not any(render.get("path") == evidence_path for render in candidate.renders):
                raise ValueError(
                    f"evaluation evidence was not registered as a production render: {evidence_path}"
                )
        candidate_root = self._candidate_root(candidate)
        evaluation_path = candidate_root / "evaluation.json"
        atomic_write_json(evaluation_path, evaluation.to_dict())
        candidate.evaluation_file = evaluation_path.relative_to(self.project_root).as_posix()
        if evaluation.decision == "reject":
            candidate.status = "rejected"
        elif evaluation.decision == "blocked":
            candidate.status = "blocked"
        self._save_candidate(candidate)
        return evaluation_path

    def promote(self, candidate_id: str) -> dict[str, Any]:
        candidate = self.load_candidate(candidate_id)
        brief = self.load_brief(candidate.asset_id)
        if candidate.technical_validation.get("status") != "pass":
            raise ValueError("only technically validated candidates can be promoted")
        if not candidate.evaluation_file:
            raise ValueError("candidate has no recorded visual evaluation")
        evaluation_path = self.project_root / _safe_relative_path(candidate.evaluation_file)
        evaluation = ArtEvaluation.from_dict(_read_json(evaluation_path))
        source_imagery_required = bool(brief.source_room_definition or brief.reference_images)
        errors = evaluation.validate(
            source_resemblance_required=source_imagery_required,
            allow_stylization=brief.allow_stylization,
        )
        if errors or evaluation.decision != "promote":
            raise ValueError(
                "candidate did not pass the evidence-based visual gate: " + "; ".join(errors)
            )
        production_renders = [
            render for render in candidate.renders if render.get("production_path") is True
        ]
        if not production_renders:
            raise ValueError(
                "promotion requires at least one registered production-path Godot render"
            )
        for relative in candidate.asset_files:
            file_path = self.project_root / _safe_relative_path(relative)
            if not file_path.is_file():
                raise ValueError(
                    f"candidate asset is missing; refusing fallback promotion: {relative}"
                )
        incumbent_entry = self.registry.resolve(candidate.asset_id)
        comparison_result = (
            evaluation.incumbent_comparison_result or evaluation.incumbent_comparison
        )
        if incumbent_entry is not None:
            if comparison_result != "better":
                raise ValueError("challenger did not clearly beat the current incumbent")
            if (
                evaluation.incumbent_candidate_id
                and evaluation.incumbent_candidate_id != incumbent_entry.get("candidate_id")
            ):
                raise ValueError("challenger was compared against a stale best-so-far candidate")
            if incumbent_entry.get("candidate_id") == candidate_id:
                raise ValueError("candidate is already the incumbent")
            incumbent_eval = self._load_candidate_evaluation(str(incumbent_entry["candidate_id"]))
            for dimension, old_score in incumbent_eval.scores.items():
                if dimension in evaluation.scores and evaluation.scores[dimension] < old_score:
                    raise ValueError(f"challenger regresses the incumbent on {dimension}")
        elif comparison_result not in {"first_pass", "better"}:
            raise ValueError("initial accepted candidate needs an explicit passing decision")

        primary_file = self.project_root / _safe_relative_path(candidate.asset_files[0])
        entry = {
            "status": "accepted",
            "semantic_type": brief.semantic_type,
            "path": primary_file.relative_to(self.project_root).as_posix(),
            "candidate_id": candidate_id,
            "sha256": sha256_file(primary_file),
            "accepted_at_utc": _now_utc(),
            "dimensions_inches": list(brief.intended_dimensions),
        }
        self.registry.accept(candidate.asset_id, entry)
        candidate.status = "accepted"
        self._save_candidate(candidate)
        return entry

    def _load_candidate_evaluation(self, candidate_id: str) -> ArtEvaluation:
        candidate = self.load_candidate(candidate_id)
        if not candidate.evaluation_file:
            raise ValueError(f"incumbent {candidate_id} has no evaluation record")
        path = self.project_root / _safe_relative_path(candidate.evaluation_file)
        return ArtEvaluation.from_dict(_read_json(path))

    def _candidate_root(self, candidate: ArtCandidate) -> Path:
        return self.art_root / candidate.asset_id / "iterations" / f"v{candidate.version:03d}"

    def _save_candidate(self, candidate: ArtCandidate) -> None:
        errors = candidate.validate()
        if errors:
            raise ValueError("invalid ArtCandidate: " + "; ".join(errors))
        atomic_write_json(self._candidate_root(candidate) / "candidate.json", candidate.to_dict())

    def _reserve_candidate(
        self, asset_id: str, iteration_budget: int | None
    ) -> tuple[int, str, Path]:
        iteration_root = self.art_root / asset_id / "iterations"
        versions = [
            int(path.name[1:])
            for path in iteration_root.glob("v[0-9][0-9][0-9]")
            if path.name[1:].isdigit()
        ]
        version = max(versions, default=0) + 1
        if iteration_budget is not None and version > iteration_budget + 1:
            raise ValueError(f"iteration budget exhausted for {asset_id}: {iteration_budget}")
        candidate_id = f"{asset_id}-v{version:03d}"
        return version, candidate_id, iteration_root / f"v{version:03d}"

    @staticmethod
    def _split_candidate_id(candidate_id: str) -> tuple[str, int]:
        if "-v" not in candidate_id:
            raise ValueError(f"invalid candidate id: {candidate_id!r}")
        asset_id, version_text = candidate_id.rsplit("-v", 1)
        validate_asset_id(asset_id)
        if len(version_text) != 3 or not version_text.isdigit() or int(version_text) < 1:
            raise ValueError(f"invalid candidate version: {candidate_id!r}")
        return asset_id, int(version_text)
