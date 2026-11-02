"""Persistent candidate, render, evaluation, and promotion workflow."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Any

from .models import VISUAL_CRAFT_CHECKS, ArtBrief, ArtCandidate, ArtEvaluation, ArtRecipe
from .registry import AssetRegistry, atomic_write_json, sha256_file, validate_asset_id
from .visual_director import (
    VisualDirectorGateRequired,
    classify_visual_director_policy,
    visual_brief_scaffold,
)


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
        visual_director_provenance = self._require_visual_director_target(brief, recipe)
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
                visual_director_provenance=visual_director_provenance,
            )
            self._save_candidate(candidate)
            self._record_visual_director_candidate(candidate)
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
        visual_director_provenance = self._require_visual_director_target(brief, recipe)
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
            visual_director_provenance=visual_director_provenance,
        )
        files, result, execution = self._run_recorded_generator(
            asset_id=asset_id,
            candidate_id=candidate_id,
            recipe=recipe,
            candidate_root=candidate_root,
            output_dir=generated_root,
            log_file=candidate_root / "generation.log",
            execution_number=1,
            timeout_seconds=timeout_seconds,
        )
        candidate.generation_attempts.append(execution)
        candidate.generation_result = result
        if result["status"] == "pass":
            candidate.asset_files = files
        else:
            candidate.status = "blocked"
            candidate.technical_validation = {
                "status": "fail",
                "reason": result.get("reason", "generator returned a failure"),
                "recorded_at_utc": result["recorded_at_utc"],
            }
        self._save_candidate(candidate)
        self._record_visual_director_candidate(candidate)
        return candidate

    def retry_candidate_generation(
        self, candidate_id: str, timeout_seconds: int = 1200
    ) -> ArtCandidate:
        """Resume a blocked candidate without consuming another visual strategy attempt."""
        candidate = self.load_candidate(candidate_id)
        if candidate.status != "blocked" or candidate.generation_result.get("status") == "pass":
            raise ValueError("only a candidate blocked during generation can be retried")
        if candidate.asset_files or candidate.renders or candidate.evaluation_file:
            raise ValueError(
                "generation retry is only allowed before candidate assets, renders, or evaluations exist"
            )
        if candidate.technical_validation.get("status") == "pass":
            raise ValueError("a technically validated candidate cannot be retried")

        recipe_path = self.project_root / _safe_relative_path(candidate.recipe_file)
        if not recipe_path.is_file():
            raise ValueError(f"candidate recipe is missing: {candidate.recipe_file}")
        recipe = ArtRecipe.from_dict(_read_json(recipe_path))
        errors = recipe.validate()
        if errors or not recipe.generator_command:
            raise ValueError("candidate recipe is not runnable: " + "; ".join(errors))

        provenance = candidate.visual_director_provenance
        target = provenance.get("approved_visual_target")
        if target:
            case_path = self._visual_director_case_path(candidate.asset_id)
            state = _read_json(case_path) if case_path.is_file() else {}
            approved_target = state.get("approved_visual_target", {})
            episode = state.get("target_episode", {})
            attempt_record = next(
                (
                    item
                    for item in episode.get("attempts", [])
                    if item.get("candidate_id") == candidate.candidate_id
                ),
                None,
            )
            if (
                not self._approved_target_is_current(target)
                or approved_target.get("sha256") != target.get("sha256")
                or episode.get("target_sha256") != target.get("sha256")
                or not attempt_record
                or attempt_record.get("status") != "blocked"
                or attempt_record.get("attempt")
                != provenance.get("target_episode_attempt")
            ):
                raise ValueError(
                    "only the still-current Visual Director target's blocked generation attempt can be resumed"
                )

        candidate_root = self._candidate_root(candidate)
        if not candidate.generation_attempts:
            previous = candidate.generation_result
            candidate.generation_attempts.append(
                {
                    "execution_number": 1,
                    "status": previous.get("status", "fail"),
                    "exit_code": previous.get("exit_code"),
                    "recorded_at_utc": previous.get("recorded_at_utc", candidate.created_at_utc),
                    "command": previous.get("command", []),
                    "log_file": (
                        candidate_root / "generation.log"
                    ).relative_to(self.project_root).as_posix(),
                    "output_dir": (candidate_root / "generated")
                    .relative_to(self.project_root)
                    .as_posix(),
                    "preserved_legacy_execution": True,
                }
            )

        execution_number = len(candidate.generation_attempts) + 1
        execution_root = candidate_root / "generation-attempts" / f"run-{execution_number:03d}"
        output_dir = execution_root / "generated"
        log_file = execution_root / "generation.log"
        if execution_root.exists():
            raise ValueError(f"generation retry evidence already exists: {execution_root}")
        files, result, execution = self._run_recorded_generator(
            asset_id=candidate.asset_id,
            candidate_id=candidate.candidate_id,
            recipe=recipe,
            candidate_root=candidate_root,
            output_dir=output_dir,
            log_file=log_file,
            execution_number=execution_number,
            timeout_seconds=timeout_seconds,
        )
        candidate.generation_attempts.append(execution)
        candidate.generation_result = result
        if result["status"] == "pass":
            candidate.asset_files = files
            candidate.status = "challenger"
            candidate.technical_validation = {}
        else:
            candidate.status = "blocked"
            candidate.technical_validation = {
                "status": "fail",
                "reason": result.get("reason", "generator returned a failure"),
                "recorded_at_utc": result["recorded_at_utc"],
            }
        self._save_candidate(candidate)
        self._record_visual_director_candidate(candidate)
        return candidate

    def _run_recorded_generator(
        self,
        *,
        asset_id: str,
        candidate_id: str,
        recipe: ArtRecipe,
        candidate_root: Path,
        output_dir: Path,
        log_file: Path,
        execution_number: int,
        timeout_seconds: int,
    ) -> tuple[list[str], dict[str, Any], dict[str, Any]]:
        output_dir.mkdir(parents=True, exist_ok=True)
        command = [
            argument.format(
                project_root=str(self.project_root),
                output_dir=str(output_dir),
                brief_path=str(self.art_root / asset_id / "brief.json"),
                recipe_path=str(candidate_root / "recipe.json"),
            )
            for argument in recipe.generator_command
        ]
        environment = os.environ.copy()
        environment.update(
            {
                "ROOMSCALE_ART_FACTORY_OUTPUT_DIR": str(output_dir),
                "ROOMSCALE_ART_FACTORY_ASSET_ID": asset_id,
                "ROOMSCALE_ART_FACTORY_BRIEF": str(self.art_root / asset_id / "brief.json"),
                "ROOMSCALE_ART_FACTORY_RECIPE": str(candidate_root / "recipe.json"),
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
        log_file.parent.mkdir(parents=True, exist_ok=True)
        log_file.write_text(output, encoding="utf-8")
        declared_outputs = recipe.parameters.get("outputs", [])
        files: list[str] = []
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
                    target = output_dir.joinpath(*relative.parts)
                    if not target.is_file():
                        result = {
                            "status": "fail",
                            "exit_code": result["exit_code"],
                            "reason": f"declared generator output is missing: {output_path}",
                        }
                        break
                    files.append(target.relative_to(self.project_root).as_posix())
        recorded_at = _now_utc()
        log_relative = log_file.relative_to(self.project_root).as_posix()
        output_relative = output_dir.relative_to(self.project_root).as_posix()
        result = {
            **result,
            "recorded_at_utc": recorded_at,
            "command": command,
            "execution_number": execution_number,
            "log_file": log_relative,
            "output_dir": output_relative,
        }
        execution = {
            "execution_number": execution_number,
            "status": result["status"],
            "exit_code": result.get("exit_code"),
            "recorded_at_utc": recorded_at,
            "command": command,
            "log_file": log_relative,
            "output_dir": output_relative,
        }
        if result.get("timed_out"):
            execution["timed_out"] = True
        if result.get("reason"):
            execution["reason"] = result["reason"]
        return files, result, execution

    def visual_director_status(self, asset_id: str) -> dict[str, Any]:
        """Return policy and separate visual-target / 3D / production incumbents."""
        brief = self.load_brief(asset_id)
        case_path = self._visual_director_case_path(asset_id)
        policy = classify_visual_director_policy(brief)
        state = _read_json(case_path) if case_path.is_file() else {}
        state.update(
            {
                "schema_version": 1,
                "asset_id": asset_id,
                "policy": policy,
                "case_file": case_path.relative_to(self.project_root).as_posix(),
                "visual_brief_file": (
                    self._visual_director_root(asset_id) / "visual-brief-draft.json"
                )
                .relative_to(self.project_root)
                .as_posix(),
                "production_asset": self._production_asset_record(asset_id),
            }
        )
        if "best_3d_candidate" not in state:
            production = state["production_asset"]
            state["best_3d_candidate"] = production
        if state.get("status") in {"backlog", "production_pass"}:
            pass
        elif state.get("approved_visual_target") and not self._approved_target_is_current(
            state["approved_visual_target"]
        ):
            state["status"] = "target_stale"
        elif state.get("approved_visual_target"):
            state["status"] = "approved"
        elif policy["required"]:
            state["status"] = "target_pending"
        else:
            state["status"] = "bypass_allowed"
        return state

    def prepare_visual_director(self, asset_id: str) -> dict[str, Any]:
        """Automatically open a visual-development case and scaffold its VisualBrief."""
        brief = self.load_brief(asset_id)
        root = self._visual_director_root(asset_id)
        root.mkdir(parents=True, exist_ok=True)
        draft_path = root / "visual-brief-draft.json"
        if not draft_path.exists():
            atomic_write_json(draft_path, visual_brief_scaffold(brief))
        case_path = self._visual_director_case_path(asset_id)
        state = _read_json(case_path) if case_path.is_file() else {}
        state.setdefault("approved_visual_target", None)
        state.setdefault("best_3d_candidate", self._production_asset_record(asset_id))
        state.setdefault("candidate_history", [])
        approved_target = state.get("approved_visual_target")
        if state.get("status") in {"backlog", "production_pass"}:
            state_status = state["status"]
        elif isinstance(approved_target, dict) and self._approved_target_is_current(
            approved_target
        ):
            state_status = "approved"
        elif classify_visual_director_policy(brief)["required"]:
            state_status = "target_stale" if approved_target else "target_pending"
        else:
            state_status = "bypass_allowed"
        state.update(
            {
                "schema_version": 1,
                "asset_id": asset_id,
                "status": state_status,
                "policy": classify_visual_director_policy(brief),
                "case_file": case_path.relative_to(self.project_root).as_posix(),
                "visual_brief_file": draft_path.relative_to(self.project_root).as_posix(),
                "production_asset": self._production_asset_record(asset_id),
                "updated_at_utc": _now_utc(),
            }
        )
        atomic_write_json(case_path, state)
        return state

    def approve_visual_target(
        self,
        asset_id: str,
        target_path: str,
        review_path: str,
        concept_id: str = "",
        reviewer: str = "Luna",
    ) -> dict[str, Any]:
        """Record a pixel-reviewed concept as the separate appearance incumbent."""
        if not reviewer.strip():
            raise ValueError("visual target reviewer must be non-empty")
        self.prepare_visual_director(asset_id)
        target_relative = _safe_relative_path(target_path)
        review_relative = _safe_relative_path(review_path)
        target_file = self.project_root.joinpath(*target_relative.parts)
        review_file = self.project_root.joinpath(*review_relative.parts)
        if not target_file.is_file():
            raise ValueError(f"approved visual target does not exist: {target_path}")
        if target_file.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".svg"}:
            raise ValueError("approved visual target must be a PNG, JPEG, WebP, or SVG image")
        if not review_file.is_file():
            raise ValueError(f"pixel-review evidence does not exist: {review_path}")
        case_path = self._visual_director_case_path(asset_id)
        state = _read_json(case_path)
        target = {
            "path": target_relative.as_posix(),
            "sha256": sha256_file(target_file),
            "review_path": review_relative.as_posix(),
            "approved_at_utc": _now_utc(),
            "concept_id": concept_id or target_file.stem,
            "approval": "pass",
            "review_method": f"pixel inspection; review evidence recorded by {reviewer.strip()}",
        }
        state["approved_visual_target"] = target
        state["status"] = "approved"
        previous_episode = state.get("target_episode", {})
        if previous_episode.get("target_sha256") != target["sha256"]:
            state["target_episode"] = {
                "target_sha256": target["sha256"],
                "status": "ready_for_3d",
                "attempts": [],
            }
        state["updated_at_utc"] = _now_utc()
        atomic_write_json(case_path, state)
        return self.visual_director_status(asset_id)

    def backlog_visual_director_case(self, asset_id: str, reason: str) -> dict[str, Any]:
        """Stop a target episode while preserving its target, best candidate, and production asset."""
        if not reason.strip():
            raise ValueError("backlog requires a concrete visual-transfer reason")
        state = self.prepare_visual_director(asset_id)
        if not state.get("approved_visual_target"):
            raise ValueError("cannot backlog a Visual Director case without an approved target")
        episode = state.get("target_episode", {})
        if not episode.get("attempts"):
            raise ValueError(
                "cannot backlog a Visual Director case before a 3D candidate is reviewed"
            )
        if state.get("status") == "production_pass":
            raise ValueError("a production-passed Visual Director case cannot be backlogged")
        episode["status"] = "backlog"
        episode["backlog_reason"] = reason.strip()
        state["target_episode"] = episode
        state["status"] = "backlog"
        state["backlog_reason"] = reason.strip()
        state["updated_at_utc"] = _now_utc()
        atomic_write_json(self._visual_director_case_path(asset_id), state)
        return self.visual_director_status(asset_id)

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
        # A RoomDefinition supplies fit/gameplay context, not a photograph.
        source_imagery_required = bool(brief.reference_images)
        visual_director_candidate = bool(
            candidate.visual_director_provenance.get("approved_visual_target")
        )
        errors = evaluation.validate(
            source_resemblance_required=source_imagery_required,
            allow_stylization=brief.allow_stylization,
            require_craftsmanship_render_references=visual_director_candidate,
        )
        if errors:
            raise ValueError("invalid ArtEvaluation: " + "; ".join(errors))
        if evaluation.candidate_id != candidate.candidate_id:
            raise ValueError("evaluation candidate ID mismatch")
        if (
            candidate.visual_director_provenance.get("approved_visual_target")
            and not evaluation.visual_transfer_diagnosis
        ):
            raise ValueError(
                "Visual Director candidates require a visual_transfer_diagnosis with causes, "
                "lost information, preserved components, and corrective action"
            )
        for evidence_path in evaluation.render_evidence:
            relative = _safe_relative_path(evidence_path)
            if not self.project_root.joinpath(*relative.parts).is_file():
                raise ValueError(f"evaluation references missing render evidence: {evidence_path}")
            if not any(
                render.get("path") == evidence_path
                and (not visual_director_candidate or render.get("production_path") is True)
                for render in candidate.renders
            ):
                raise ValueError(
                    f"evaluation evidence was not registered as a production render: {evidence_path}"
                )
        if visual_director_candidate:
            registered_paths = {
                str(render.get("path", ""))
                for render in candidate.renders
                if render.get("production_path") is True
            }
            for check in evaluation.visual_gate["craftsmanship"].values():
                if not isinstance(check, dict):
                    continue
                for evidence_path in check.get("evidence_refs", []):
                    if evidence_path not in registered_paths:
                        raise ValueError(
                            "Visual Director craftsmanship evidence must reference a registered "
                            f"production Godot render: {evidence_path}"
                        )
            self._reject_reused_visual_evidence(candidate, evaluation)
        candidate_root = self._candidate_root(candidate)
        evaluation_path = candidate_root / "evaluation.json"
        atomic_write_json(evaluation_path, evaluation.to_dict())
        candidate.evaluation_file = evaluation_path.relative_to(self.project_root).as_posix()
        if evaluation.decision == "reject":
            candidate.status = "rejected"
        elif evaluation.decision == "blocked":
            candidate.status = "blocked"
        self._save_candidate(candidate)
        self._record_visual_director_evaluation(candidate, evaluation)
        if evaluation.decision != "reject" and evaluation.incumbent_comparison_result in {
            "better",
            "first_pass",
        }:
            self._set_best_3d_candidate(candidate)
        return evaluation_path

    def _reject_reused_visual_evidence(
        self, candidate: ArtCandidate, evaluation: ArtEvaluation
    ) -> None:
        new_evidence = {
            str(evaluation.visual_gate["craftsmanship"][check]["evidence"])
            .strip()
            .casefold(): check
            for check in VISUAL_CRAFT_CHECKS
        }
        existing_paths = list(self.art_root.glob("*/iterations/v*/evaluation.json"))
        existing_paths.extend(self.art_root.glob("*/visual_director/round-*/assessments/*.json"))
        for path in existing_paths:
            try:
                other_asset_id = path.relative_to(self.art_root).parts[0]
                if other_asset_id == candidate.asset_id:
                    continue
                other = _read_json(path)
            except (OSError, ValueError, IndexError):
                continue
            other_craft = other.get("visual_gate", {}).get("craftsmanship", {})
            if not isinstance(other_craft, dict):
                continue
            for item in other_craft.values():
                if not isinstance(item, dict):
                    continue
                phrase = str(item.get("evidence", "")).strip().casefold()
                if phrase in new_evidence:
                    check = new_evidence[phrase]
                    raise ValueError(
                        "Visual Director craftsmanship evidence for "
                        f"{check} repeats wording recorded for semantic asset "
                        f"{other_asset_id} at {path.as_posix()}; write new asset-specific evidence"
                    )

    def promote(self, candidate_id: str) -> dict[str, Any]:
        candidate = self.load_candidate(candidate_id)
        brief = self.load_brief(candidate.asset_id)
        if candidate.technical_validation.get("status") != "pass":
            raise ValueError("only technically validated candidates can be promoted")
        if not candidate.evaluation_file:
            raise ValueError("candidate has no recorded visual evaluation")
        evaluation_path = self.project_root / _safe_relative_path(candidate.evaluation_file)
        evaluation = ArtEvaluation.from_dict(_read_json(evaluation_path))
        # A RoomDefinition supplies fit/gameplay context, not a photograph.
        source_imagery_required = bool(brief.reference_images)
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
        self._set_best_3d_candidate(candidate, production_asset=entry)
        return entry

    def _load_candidate_evaluation(self, candidate_id: str) -> ArtEvaluation:
        candidate = self.load_candidate(candidate_id)
        if not candidate.evaluation_file:
            raise ValueError(f"incumbent {candidate_id} has no evaluation record")
        path = self.project_root / _safe_relative_path(candidate.evaluation_file)
        return ArtEvaluation.from_dict(_read_json(path))

    def _candidate_root(self, candidate: ArtCandidate) -> Path:
        return self.art_root / candidate.asset_id / "iterations" / f"v{candidate.version:03d}"

    def _visual_director_root(self, asset_id: str) -> Path:
        return self.art_root / asset_id / "visual_director"

    def _visual_director_case_path(self, asset_id: str) -> Path:
        return self._visual_director_root(asset_id) / "state.json"

    def _production_asset_record(self, asset_id: str) -> dict[str, Any] | None:
        entry = self.registry.resolve(asset_id)
        if not entry:
            return None
        return {
            "candidate_id": entry.get("candidate_id", ""),
            "path": entry.get("path", ""),
            "accepted_at_utc": entry.get("accepted_at_utc", ""),
        }

    def _approved_target_is_current(self, target: dict[str, Any]) -> bool:
        try:
            relative = _safe_relative_path(str(target.get("path", "")))
            path = self.project_root.joinpath(*relative.parts)
            return path.is_file() and sha256_file(path) == target.get("sha256")
        except (ValueError, OSError):
            return False

    def _require_visual_director_target(self, brief: ArtBrief, recipe: ArtRecipe) -> dict[str, Any]:
        state = self.prepare_visual_director(brief.asset_id)
        policy = classify_visual_director_policy(brief)
        target = state.get("approved_visual_target")
        if policy["required"] and not (
            isinstance(target, dict) and self._approved_target_is_current(target)
        ):
            status = "target_stale" if isinstance(target, dict) else "target_pending"
            state["status"] = status
            state["updated_at_utc"] = _now_utc()
            atomic_write_json(self._visual_director_case_path(brief.asset_id), state)
            raise VisualDirectorGateRequired(
                asset_id=brief.asset_id,
                case_file=state["case_file"],
                visual_brief_file=state["visual_brief_file"],
                reasons=policy["reasons"],
            )
        attempt = None
        strategy = str(recipe.parameters.get("visual_director_strategy", "bypass"))
        if policy["required"]:
            target_path = str(target["path"])
            if target_path not in recipe.source_inputs:
                raise ValueError(
                    "3D recipe must list the approved visual target in source_inputs so it "
                    "drives production"
                )
            episode = state.setdefault(
                "target_episode",
                {"target_sha256": target["sha256"], "status": "ready_for_3d", "attempts": []},
            )
            attempts = episode.setdefault("attempts", [])
            if len(attempts) >= 3:
                episode["status"] = "backlog"
                state["status"] = "backlog"
                state["updated_at_utc"] = _now_utc()
                atomic_write_json(self._visual_director_case_path(brief.asset_id), state)
                raise ValueError(
                    "Visual Director remediation budget is exhausted for this approved target; "
                    "preserve best_3d_candidate and backlog the transfer defect"
                )
            attempt = len(attempts) + 1
            expected_strategy = {
                1: "initial",
                2: "targeted_correction",
                3: "alternate_strategy",
            }[attempt]
            if strategy != expected_strategy:
                raise ValueError(
                    f"Visual Director attempt {attempt} requires "
                    f"parameters.visual_director_strategy={expected_strategy!r}"
                )
            history = state.get("candidate_history", [])
            if attempt > 1:
                diagnosis_ref = str(recipe.parameters.get("diagnosis_ref", ""))
                previous_record = next(
                    (
                        item
                        for item in history
                        if str(item.get("candidate_id", "")) == diagnosis_ref
                    ),
                    None,
                )
                if not diagnosis_ref or previous_record is None:
                    raise ValueError(
                        "targeted Visual Director remediation requires diagnosis_ref to name a "
                        "prior candidate"
                    )
                previous_candidate = self.load_candidate(diagnosis_ref)
                if not previous_candidate.evaluation_file:
                    raise ValueError(
                        "targeted Visual Director remediation requires a recorded prior evaluation"
                    )
                previous_evaluation = self._load_candidate_evaluation(diagnosis_ref)
                if not previous_evaluation.visual_transfer_diagnosis:
                    raise ValueError(
                        "targeted Visual Director remediation requires the prior evaluation to "
                        "contain a visual_transfer_diagnosis"
                    )
            if attempt == 3:
                if not recipe.parameters.get("materially_different_strategy"):
                    raise ValueError(
                        "the third Visual Director attempt must declare "
                        "materially_different_strategy=true"
                    )
                first = next(
                    (item for item in history if item.get("visual_director_attempt") == 1), None
                )
                first_recipe_path = (
                    self.project_root / _safe_relative_path(first.get("recipe_file", ""))
                    if first
                    else None
                )
                if not first_recipe_path or not first_recipe_path.is_file():
                    raise ValueError(
                        "the initial candidate recipe is missing; cannot verify strategy change"
                    )
                first_recipe = ArtRecipe.from_dict(_read_json(first_recipe_path))
                if (
                    recipe.tool == first_recipe.tool
                    and recipe.material_method == first_recipe.material_method
                ):
                    raise ValueError(
                        "alternate_strategy must change the tool/backend or material_method from "
                        "the initial attempt"
                    )
        case_relative = (
            self._visual_director_case_path(brief.asset_id)
            .relative_to(self.project_root)
            .as_posix()
        )
        return {
            "policy": policy,
            "status": "approved" if target else "bypass_allowed",
            "case_file": case_relative,
            "approved_visual_target": target,
            "target_episode_attempt": attempt,
            "strategy": strategy,
        }

    def _record_visual_director_candidate(self, candidate: ArtCandidate) -> None:
        case_path = self._visual_director_case_path(candidate.asset_id)
        if not case_path.is_file():
            return
        state = _read_json(case_path)
        history = state.setdefault("candidate_history", [])
        if not any(item.get("candidate_id") == candidate.candidate_id for item in history):
            history.append(
                {
                    "candidate_id": candidate.candidate_id,
                    "created_at_utc": candidate.created_at_utc,
                    "parent_candidate_id": candidate.parent_candidate_id,
                    "candidate_file": (self._candidate_root(candidate) / "candidate.json")
                    .relative_to(self.project_root)
                    .as_posix(),
                    "recipe_file": candidate.recipe_file,
                    "visual_director_attempt": candidate.visual_director_provenance.get(
                        "target_episode_attempt"
                    ),
                    "visual_director_provenance": candidate.visual_director_provenance,
                }
            )
        if candidate.visual_director_provenance.get("approved_visual_target"):
            episode = state.setdefault(
                "target_episode",
                {
                    "target_sha256": candidate.visual_director_provenance["approved_visual_target"][
                        "sha256"
                    ],
                    "status": "in_progress",
                    "attempts": [],
                },
            )
            attempts = episode.setdefault("attempts", [])
            attempt_record = next(
                (
                    item
                    for item in attempts
                    if item.get("candidate_id") == candidate.candidate_id
                ),
                None,
            )
            generation_result = candidate.generation_result or {}
            blocked = (
                candidate.status == "blocked" or generation_result.get("status") != "pass"
            )
            if attempt_record is None:
                attempt_record = {
                    "candidate_id": candidate.candidate_id,
                    "strategy": candidate.visual_director_provenance.get("strategy"),
                    "attempt": candidate.visual_director_provenance.get(
                        "target_episode_attempt"
                    ),
                }
                attempts.append(attempt_record)
            if blocked:
                failure_reason = generation_result.get("reason") or candidate.technical_validation.get(
                    "reason", "generation did not produce a candidate mesh"
                )
                log_file = generation_result.get("log_file")
                generation_log = (
                    self.project_root / _safe_relative_path(log_file)
                    if log_file
                    else self._candidate_root(candidate) / "generation.log"
                )
                if generation_log.is_file():
                    log_lines = [
                        line.strip()
                        for line in generation_log.read_text(
                            encoding="utf-8", errors="replace"
                        ).splitlines()
                        if line.strip()
                    ]
                    exception_line = next(
                        (
                            line
                            for line in reversed(log_lines)
                            if line.startswith(("RuntimeError:", "ValueError:", "Error:"))
                        ),
                        None,
                    )
                    if exception_line:
                        failure_reason = exception_line
                attempt_record.update(
                    {
                        "status": "blocked",
                        "failure_reason": failure_reason,
                        "generation_executions": len(candidate.generation_attempts),
                    }
                )
                if episode.get("status") != "backlog":
                    episode["status"] = "in_progress"
            elif attempt_record.get("status") == "blocked":
                attempt_record.update(
                    {
                        "status": "awaiting_render_review",
                        "generation_executions": len(candidate.generation_attempts),
                    }
                )
                attempt_record.pop("failure_reason", None)
                episode["status"] = "in_progress"
                episode.pop("backlog_reason", None)
                state["status"] = "in_progress"
                state.pop("backlog_reason", None)
            elif attempt_record.get("status") not in {"evaluated", "awaiting_render_review"}:
                attempt_record.update(
                    {
                        "status": "awaiting_render_review",
                        "generation_executions": len(candidate.generation_attempts),
                    }
                )
                episode["status"] = "in_progress"
            state["target_episode"] = episode
        state["updated_at_utc"] = _now_utc()
        state["production_asset"] = self._production_asset_record(candidate.asset_id)
        atomic_write_json(case_path, state)

    def _record_visual_director_evaluation(
        self, candidate: ArtCandidate, evaluation: ArtEvaluation
    ) -> None:
        if not candidate.visual_director_provenance.get("approved_visual_target"):
            return
        case_path = self._visual_director_case_path(candidate.asset_id)
        if not case_path.is_file():
            return
        state = _read_json(case_path)
        episode = state.get("target_episode", {})
        attempts = episode.get("attempts", [])
        record = next(
            (item for item in attempts if item.get("candidate_id") == candidate.candidate_id),
            None,
        )
        if record is None:
            return
        record.update(
            {
                "status": "evaluated",
                "evaluation_file": candidate.evaluation_file,
                "decision": evaluation.decision,
                "incumbent_comparison_result": evaluation.incumbent_comparison_result,
                "visual_transfer_diagnosis": evaluation.visual_transfer_diagnosis,
                "evaluated_at_utc": _now_utc(),
            }
        )
        episode["attempts"] = attempts
        if evaluation.decision == "promote":
            episode["status"] = "ready_for_promotion"
        elif len(attempts) >= 3:
            episode["status"] = "backlog"
            state["status"] = "backlog"
        else:
            episode["status"] = "remediation_needed"
        state["target_episode"] = episode
        state["updated_at_utc"] = _now_utc()
        atomic_write_json(case_path, state)

    def _set_best_3d_candidate(
        self,
        candidate: ArtCandidate,
        production_asset: dict[str, Any] | None = None,
    ) -> None:
        case_path = self._visual_director_case_path(candidate.asset_id)
        if not case_path.is_file():
            return
        state = _read_json(case_path)
        evaluation_path = candidate.evaluation_file
        state["best_3d_candidate"] = {
            "candidate_id": candidate.candidate_id,
            "candidate_file": (self._candidate_root(candidate) / "candidate.json")
            .relative_to(self.project_root)
            .as_posix(),
            "evaluation_file": evaluation_path,
            "updated_at_utc": _now_utc(),
        }
        state["production_asset"] = production_asset or self._production_asset_record(
            candidate.asset_id
        )
        if production_asset is not None:
            state["status"] = "production_pass"
            episode = state.get("target_episode", {})
            if episode:
                episode["status"] = "production_pass"
                state["target_episode"] = episode
        state["updated_at_utc"] = _now_utc()
        atomic_write_json(case_path, state)

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
