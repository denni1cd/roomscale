"""Focused process/provenance regressions; controlled fixtures never claim gameplay."""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import canonical_results
import poc471_campaign as campaign
import poc471_evidence as evidence


class CampaignExecutionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "scripts").mkdir()
        for name in ["poc471_campaign.py", "poc471_observer.gd", "poc471_evidence.py"]:
            (self.root / "scripts" / name).write_text("fixture\n", encoding="utf-8")
        (self.root / "TEST_ROOM_SCALE_POC471.ps1").write_text("fixture\n", encoding="utf-8")
        self.output = self.root / "runs"
        self.config = {
            "id": "fixture",
            "seed": 1,
            "name": "Unicode café",
            "classification": "positive",
            "definition": {"id": "fixture"},
            "days": 8,
        }
        self.result_path = self.output / "fixture/result.json"
        campaign.write(self.result_path, {"result": "PASS", "fingerprint": "stale"})

    def run_case(self, fake_run) -> dict:
        with (
            patch.object(campaign, "ROOT", self.root),
            patch.object(campaign.subprocess, "check_output", return_value="fixture-sha"),
            patch.object(campaign.subprocess, "run", side_effect=fake_run),
        ):
            return campaign.execute(self.config, self.output, "fixture-engine")

    def test_timeout_cannot_reuse_previous_pass(self) -> None:
        def timeout(command, **kwargs):
            self.assertFalse(self.result_path.exists())
            kwargs["stdout"].write("partial café output\n")
            raise subprocess.TimeoutExpired(command, 3600)

        result = self.run_case(timeout)
        self.assertEqual(result["result"], "ERROR")
        self.assertIn("timeout", result["failure"])
        self.assertNotIn("fingerprint", result)
        self.assertIn("café", (self.output / "fixture/run.log").read_text(encoding="utf-8"))
        self.assertTrue((self.output / "fixture/failure-package.json").exists())

    def test_nonzero_exit_overrides_written_pass(self) -> None:
        def failed(_command, **_kwargs):
            campaign.write(self.result_path, {"result": "PASS"})
            return SimpleNamespace(returncode=7)

        self.assertEqual(self.run_case(failed)["result"], "ERROR")

    def test_engine_errors_override_written_pass(self) -> None:
        def failed(_command, **kwargs):
            campaign.write(self.result_path, {"result": "PASS"})
            kwargs["stdout"].write("SCRIPT ERROR: controlled fixture\n")
            return SimpleNamespace(returncode=0)

        self.assertEqual(self.run_case(failed)["result"], "ERROR")

    def test_success_is_fresh_utf8_and_environment_isolated(self) -> None:
        def succeeded(command, **kwargs):
            self.assertIsInstance(command, list)
            self.assertNotIn("ROOMSCALE_POISON", kwargs["env"])
            campaign.write(self.result_path, {"result": "PASS", "fingerprint": "fresh café"})
            return SimpleNamespace(returncode=0)

        with patch.dict(os.environ, {"ROOMSCALE_POISON": "inherited"}):
            result = self.run_case(succeeded)
            self.assertEqual(os.environ["ROOMSCALE_POISON"], "inherited")
        self.assertEqual(result["fingerprint"], "fresh café")
        self.assertEqual(
            json.loads(self.result_path.read_text(encoding="utf-8"))["name"], "Unicode café"
        )


class EvidenceAuditTests(unittest.TestCase):
    def test_failed_audit_preserves_accepted_report(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = root / "verification/poc471/final-report.md"
            report.parent.mkdir(parents=True)
            report.write_text("accepted report\n", encoding="utf-8")
            summary = report.parent / "campaign-summary.json"
            summary.write_text('{"accepted": true}\n', encoding="utf-8")
            matrix = report.parent / "scenario-matrix.md"
            matrix.write_text("accepted matrix\n", encoding="utf-8")
            with patch.object(evidence, "ROOT", root), patch("sys.argv", ["poc471_evidence.py"]):
                self.assertEqual(evidence.main(), 1)
            self.assertEqual(report.read_text(encoding="utf-8"), "accepted report\n")
            self.assertEqual(summary.read_text(encoding="utf-8"), '{"accepted": true}\n')
            self.assertEqual(matrix.read_text(encoding="utf-8"), "accepted matrix\n")
            self.assertTrue((report.parent / "evidence-audit-errors.json").exists())


class CanonicalComparisonTests(unittest.TestCase):
    def test_host_metadata_is_excluded_but_milestones_are_compared(self) -> None:
        first = dict.fromkeys(canonical_results.FIELDS, {})
        first.update(result="PASS", captures=["first/path.png"], wall_seconds=10)
        second = first.copy()
        second.update(captures=["second/path.png"], wall_seconds=30)
        self.assertEqual(
            canonical_results.fingerprint(first), canonical_results.fingerprint(second)
        )
        second["checkpoints"] = {"shelter_complete": 123}
        self.assertNotEqual(
            canonical_results.fingerprint(first), canonical_results.fingerprint(second)
        )

    def test_incomplete_or_failed_receipts_cannot_pass(self) -> None:
        with self.assertRaises(ValueError):
            canonical_results.fingerprint({"result": "PASS"})
        with self.assertRaises(ValueError):
            canonical_results.fingerprint(dict.fromkeys(canonical_results.FIELDS, "FAIL"))


if __name__ == "__main__":
    unittest.main()
