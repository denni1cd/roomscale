"""Focused process/provenance regressions; controlled fixtures never claim gameplay."""

from __future__ import annotations

import json
import os
import runpy
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import canonical_results
import poc471_campaign as campaign
import poc471_evidence as evidence
import poc472_campaign as placement


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

    def rejection_receipt(self) -> dict:
        return {
            "result": "FAIL",
            "failure": "Generator invalid: insufficient feasibility certificate",
            "validation": {
                "structural": True,
                "solvable": False,
                "solvability_errors": ["No legal bootstrap depot site"],
            },
            "initial": {"seconds": 0.0},
            "final": {"seconds": 0.0},
            "violations": [],
            "deadlock": False,
            "milestones": {},
            "timeline": [],
        }

    def execute_rejection(self, receipt: dict, code: int = 1, extra_log: str = "") -> dict:
        def rejected(_command, **kwargs):
            self.assertFalse(self.result_path.exists())
            campaign.write(self.result_path, receipt)
            kwargs["stdout"].write(f"POC471_OBSERVER_FAIL {receipt['failure']}\n{extra_log}")
            return SimpleNamespace(returncode=code)

        return self.run_case(rejected)

    def test_fresh_pre_simulation_admission_rejection_is_distinct(self) -> None:
        result = self.execute_rejection(self.rejection_receipt())
        self.assertEqual(result["result"], "REJECTED")
        self.assertEqual(result["classification"], "rejected")
        self.assertFalse((self.output / "fixture/failure-package.json").exists())

    def test_unknown_exit_or_malformed_rejection_is_an_error(self) -> None:
        for mutation, code, log in [
            ({}, 7, ""),
            ({"final": {"seconds": 0.1}}, 1, ""),
            (
                {"validation": {"structural": True, "solvable": True, "solvability_errors": []}},
                1,
                "",
            ),
            ({"violations": ["startup invariant"]}, 1, ""),
            ({"milestones": {"meaningful_work": 1}}, 1, ""),
            ({}, 1, "SCRIPT ERROR: controlled failure"),
            ({"final": {}}, 1, ""),
            ({"result": "PASS"}, 1, ""),
        ]:
            with self.subTest(mutation=mutation, code=code, log=log):
                receipt = self.rejection_receipt() | mutation
                self.assertEqual(self.execute_rejection(receipt, code, log)["result"], "ERROR")

    def test_timeout_remains_error_even_after_rejection_receipt(self) -> None:
        def timed_out(command, **kwargs):
            receipt = self.rejection_receipt()
            campaign.write(self.result_path, receipt)
            kwargs["stdout"].write(f"POC471_OBSERVER_FAIL {receipt['failure']}\n")
            raise subprocess.TimeoutExpired(command, 3600)

        self.assertEqual(self.run_case(timed_out)["result"], "ERROR")

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


class PlacementPublicationTests(unittest.TestCase):
    def test_failed_audit_does_not_publish_acceptance(self) -> None:
        audit = runpy.run_path(str(placement.ROOT / "verification/poc472/gather_evidence.py"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            output = root / "verification/poc472"
            output.mkdir(parents=True)
            accepted = output / "audit.json"
            accepted.write_text("accepted evidence", encoding="utf-8")
            frozen = output / "freeze-manifest.json"
            frozen.write_text("{}", encoding="utf-8")
            audit["main"].__globals__["ROOT"] = root
            with (
                patch("sys.argv", ["audit"]),
                self.assertRaisesRegex(AssertionError, "Incomplete final campaign"),
            ):
                audit["main"]()
            self.assertEqual(accepted.read_text(encoding="utf-8"), "accepted evidence")
            self.assertFalse((output / "final/campaign-summary.json").exists())


class PlacementAcceptanceTests(unittest.TestCase):
    @staticmethod
    def full_cases() -> list[dict]:
        paths = sorted((placement.ROOT / "verification/poc471/final").glob("*/config.json"))
        paths += sorted((placement.ROOT / "verification/poc471/exploration").glob("*/config.json"))
        configs = [placement.retained(path) for path in paths]
        configs += placement.placements() + [placement.impossible_layout()]
        cases = [
            {
                "id": c["id"],
                "classification": c["classification"],
                "result": "PASS",
                "fingerprint": c["id"].split("-REPEAT-")[0],
                "violations": [],
                "deadlock": False,
                "final": {"seconds": c["days"] * 600},
                "validation": {"expected_rejection": c["id"] == "NEG-05"},
            }
            for c in configs
        ]
        return cases

    def test_complete_corpus_is_required(self) -> None:
        cases = self.full_cases()
        self.assertEqual(placement.acceptance_errors(cases, "full"), [])
        for sid in ("POS-023", "PLACE-031", "SOAK-01", "POS-001-REPEAT-1"):
            with self.subTest(sid=sid):
                self.assertTrue(
                    placement.acceptance_errors([c for c in cases if c["id"] != sid], "full")
                )
        self.assertTrue(placement.acceptance_errors([], "full"))

    def test_duration_allows_roundoff_but_rejects_missing_ticks(self) -> None:
        cases = self.full_cases()
        negative = next(c for c in cases if c["id"] == "NEG-03")
        negative["final"]["seconds"] = 4799.99999999993
        self.assertEqual(placement.acceptance_errors(cases, "full"), [])
        negative["final"]["seconds"] = 4799.9
        self.assertTrue(placement.acceptance_errors(cases, "full"))

    def test_invariants_repeat_and_negative_semantics_cannot_be_hidden(self) -> None:
        for sid, key, value in (
            ("POS-001", "violations", ["conservation"]),
            ("POS-001-REPEAT-1", "fingerprint", "different"),
            ("NEG-05", "validation", {}),
            ("NEG-03", "final", {"seconds": 0}),
        ):
            with self.subTest(sid=sid, key=key):
                cases = self.full_cases()
                next(c for c in cases if c["id"] == sid)[key] = value
                self.assertTrue(placement.acceptance_errors(cases, "full"))


if __name__ == "__main__":
    unittest.main()
