"""Godot import, technical validation, and production-scene render boundary."""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Any

from .factory import ArtFactory
from .registry import atomic_write_json, sha256_file


class GodotArtBridge:
    def __init__(self, factory: ArtFactory, executable: Path) -> None:
        self.factory = factory
        self.project_root = factory.project_root
        self.executable = executable.resolve()
        if not self.executable.is_file():
            raise FileNotFoundError(f"Godot executable not found: {self.executable}")

    def validate_candidate(self, candidate_id: str, timeout_seconds: int = 1200) -> dict[str, Any]:
        candidate = self.factory.load_candidate(candidate_id)
        if candidate.status == "blocked" or not candidate.asset_files:
            raise ValueError(f"candidate has no generated asset to validate: {candidate_id}")
        relative_asset = candidate.asset_files[0]
        asset_path = self._resource_path(relative_asset)
        candidate_root = self.factory._candidate_root(candidate)
        validation_report = candidate_root / "technical-validation.json"
        log_path = candidate_root / "technical-validation.log"
        environment = os.environ.copy()
        environment.update(
            {
                "ROOMSCALE_ART_FACTORY_ASSET_PATH": asset_path,
                "ROOMSCALE_ART_FACTORY_BRIEF": self._resource_path(
                    (self.factory.art_root / candidate.asset_id / "brief.json").relative_to(
                        self.project_root
                    )
                ),
                "ROOMSCALE_ART_FACTORY_VALIDATION_OUTPUT": str(validation_report),
            }
        )
        import_result = self._run(
            ["--headless", "--editor", "--import"],
            environment,
            timeout_seconds,
        )
        validation_result: subprocess.CompletedProcess[str] | None = None
        if import_result.returncode == 0:
            validation_result = self._run(
                ["--headless", "--script", "res://scripts/art_factory/validate_candidate.gd"],
                environment,
                timeout_seconds,
            )
        log = "=== Godot import ===\n" + import_result.stdout + import_result.stderr
        if validation_result is not None:
            log += (
                "\n=== candidate validation ===\n"
                + validation_result.stdout
                + validation_result.stderr
            )
        log_path.write_text(log, encoding="utf-8")
        report = self._read_report(validation_report)
        passed = (
            import_result.returncode == 0
            and validation_result is not None
            and validation_result.returncode == 0
        )
        if not report:
            report = {"status": "fail", "issues": ["Godot did not produce a validation report"]}
        result = {
            **report,
            "status": "pass" if passed and report.get("status") == "pass" else "fail",
            "import_exit_code": import_result.returncode,
            "validation_exit_code": validation_result.returncode if validation_result else None,
            "log": log_path.relative_to(self.project_root).as_posix(),
            "report": validation_report.relative_to(self.project_root).as_posix(),
        }
        self.factory.record_validation(candidate_id, result)
        if result["status"] != "pass":
            raise RuntimeError(f"Godot candidate validation failed: {candidate_id}: {result}")
        return result

    def render_candidate(
        self,
        candidate_id: str,
        timeout_seconds: int = 1200,
        room_file: str = "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json",
    ) -> dict[str, Any]:
        candidate = self.factory.load_candidate(candidate_id)
        if candidate.technical_validation.get("status") != "pass":
            raise ValueError(
                f"candidate needs a passing technical validation before render: {candidate_id}"
            )
        if not candidate.asset_files:
            raise ValueError(f"candidate has no resource to render: {candidate_id}")
        asset_file = self.project_root / candidate.asset_files[0]
        if not asset_file.is_file():
            raise FileNotFoundError(f"candidate asset is missing: {asset_file}")
        candidate_root = self.factory._candidate_root(candidate)
        run_root = self._next_render_run(candidate_root)
        run_root.mkdir(parents=True, exist_ok=False)
        registry_relative = run_root / "candidate-registry.json"
        relative_asset = asset_file.relative_to(self.project_root).as_posix()
        brief = self.factory.load_brief(candidate.asset_id)
        override = self.factory.registry.read()
        override["registry_type"] = "poc25_best_current_showcase"
        override["purpose"] = (
            "Temporary Art Factory candidate-review registry. It is never the production-accepted registry."
        )
        # These canonical pilots were re-evaluated under the repaired strict
        # gate and remain visually deficient. Keep their paths available to
        # the complete production scene without presenting old promotions as
        # current strict-gate passes.
        for incumbent_id in ("desk", "citizen"):
            incumbent_entry = override.setdefault("entries", {}).get(incumbent_id)
            if incumbent_entry is not None:
                incumbent_entry["status"] = "best_current_review"
                incumbent_entry["review_label"] = "BEST CURRENT / PRODUCTION ART FOLLOW-UP REQUIRED"
        override.setdefault("entries", {})[candidate.asset_id] = {
            "status": "best_current_review",
            "review_label": "BEST CURRENT / PRODUCTION ART FOLLOW-UP REQUIRED",
            "semantic_type": brief.semantic_type,
            "path": relative_asset,
            "candidate_id": candidate_id,
            "sha256": sha256_file(asset_file),
            "accepted_at_utc": candidate.created_at_utc,
            "dimensions_inches": list(brief.intended_dimensions),
        }
        atomic_write_json(registry_relative, override)
        environment = os.environ.copy()
        environment.update(
            {
                "ROOMSCALE_ART_REGISTRY": self._resource_path(
                    registry_relative.relative_to(self.project_root)
                ),
                "ROOMSCALE_ART_REGISTRY_MODE": "review_showcase",
                "ROOMSCALE_ART_FACTORY_ASSET_ID": candidate.asset_id,
                "ROOMSCALE_ART_FACTORY_CANDIDATE": candidate_id,
                "ROOMSCALE_ART_FACTORY_ROOM_FILE": room_file,
                "ROOMSCALE_ART_FACTORY_EXPECTED_ASSET": self._resource_path(relative_asset),
                "ROOMSCALE_ART_FACTORY_RENDER_DIR": str(run_root),
                "ROOMSCALE_ART_FACTORY_BRIEF": str(
                    self.factory.art_root / candidate.asset_id / "brief.json"
                ),
            }
        )
        harness = (
            "res://scripts/art_factory/grapple_render_harness.gd"
            if candidate.asset_id == "grapple"
            else "res://scripts/art_factory/render_harness.gd"
        )
        result = self._run(
            ["--script", harness],
            environment,
            timeout_seconds,
        )
        log_path = run_root / "render.log"
        log_path.write_text(result.stdout + result.stderr, encoding="utf-8")
        receipt_path = run_root / "receipt.json"
        receipt = self._read_report(receipt_path)
        if result.returncode != 0 or not receipt or receipt.get("production_path") is not True:
            raise RuntimeError(f"Godot production render failed for {candidate_id}; see {log_path}")
        for capture in receipt.get("captures", []):
            image_path = Path(str(capture.get("path", ""))).resolve()
            metadata = {
                **capture,
                "production_path": True,
                "room_id": receipt.get("room_id"),
                "asset_id": receipt.get("asset_id"),
                "candidate_id": receipt.get("candidate_id"),
                "renderer": receipt.get("renderer"),
                "engine": receipt.get("engine"),
            }
            self.factory.record_render(candidate_id, str(capture["phase"]), image_path, metadata)
        return receipt

    def _run(
        self,
        arguments: list[str],
        environment: dict[str, str],
        timeout_seconds: int,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.executable), "--path", str(self.project_root), *arguments],
            cwd=self.project_root,
            env=environment,
            capture_output=True,
            text=True,
            errors="replace",
            timeout=timeout_seconds,
            check=False,
        )

    def _resource_path(self, path: Path | str) -> str:
        relative = Path(path)
        if relative.is_absolute():
            relative = relative.resolve().relative_to(self.project_root)
        return "res://" + relative.as_posix().removeprefix("./")

    @staticmethod
    def _read_report(path: Path) -> dict[str, Any]:
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}
        return value if isinstance(value, dict) else {}

    @staticmethod
    def _next_render_run(candidate_root: Path) -> Path:
        runs = candidate_root / "render-runs"
        versions = [
            int(path.name.removeprefix("run-"))
            for path in runs.glob("run-[0-9][0-9][0-9]")
            if path.name.removeprefix("run-").isdigit()
        ]
        return runs / f"run-{max(versions, default=0) + 1:03d}"
