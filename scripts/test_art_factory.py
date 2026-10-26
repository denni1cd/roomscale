"""Boundary tests for persistent candidate history and promotion safeguards."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from art_factory.factory import ArtFactory
from art_factory.models import (
    RUBRIC_DIMENSIONS,
    VISUAL_CRAFT_CHECKS,
    VISUAL_STYLE_FLAGS,
    ArtBrief,
    ArtEvaluation,
    ArtRecipe,
)
from art_factory.registry import sha256_file


def make_brief(
    source_room_definition: str = "",
    allow_stylization: bool = False,
) -> ArtBrief:
    return ArtBrief(
        asset_id="test-desk",
        semantic_type="desk",
        display_name="Test Desk",
        category="human_furniture",
        intended_dimensions=(68.0, 30.0, 34.0),
        gameplay_invariants={"navigation_blocking": True, "obstacle_dimensions": [68, 30, 34]},
        reference_images=["photo_holder/Sample (2).jpg"] if source_room_definition else [],
        visual_target="Black glass computer desk with visible construction details.",
        materials={"top": "black glass", "frame": "dark painted metal"},
        required_features=["wide top", "recognizable frame"],
        prohibited_changes=["gameplay bounds", "navigation identity"],
        camera_distances=[2.0, 20.0, 300.0],
        quality_tier="B",
        iteration_budget=8,
        source_room_definition=source_room_definition,
        allow_stylization=allow_stylization,
        stylization_rationale="The requested target is intentionally stylized."
        if allow_stylization
        else "",
    )


def make_recipe() -> ArtRecipe:
    return ArtRecipe(
        method="procedural mesh",
        instructions="Build a desk with a glass top and four supported legs.",
        parameters={"bevel": 0.08},
        source_inputs=["photo_holder/Sample (2).jpg"],
        tool="Godot",
        tool_version="4.7.2",
        post_processing=[],
        material_method="material library with imported albedo map",
        import_configuration={"format": "GLB", "up_axis": "Y"},
        deterministic_seed=25,
    )


def make_scores(raised: str = "semantic_recognizability") -> dict[str, int]:
    scores = {dimension: 4 for dimension in RUBRIC_DIMENSIONS if dimension != "source_resemblance"}
    scores["semantic_recognizability"] = 5
    scores["technical_integration"] = 5
    if raised in scores:
        scores[raised] = 5
    return scores


def make_visual_gate(photo_applicable: bool = False) -> dict[str, object]:
    return {
        "neutral_viewer_realism": {
            "answer": "Yes",
            "pass": True,
            "evidence": "The production render reads as a convincingly constructed physical asset.",
        },
        "close_inspection": {
            "answer": "Yes",
            "pass": True,
            "evidence": "The close production render holds together without obvious primitive construction.",
        },
        "craftsmanship": {
            "answer": "Yes",
            **{
                check: {
                    "pass": True,
                    "evidence": f"The close production render shows believable {check.replace('_', ' ')}.",
                }
                for check in VISUAL_CRAFT_CHECKS
            },
        },
        "photo_character": {
            "applicable": photo_applicable,
            "answer": "Yes" if photo_applicable else "N/A",
            "pass": True if photo_applicable else None,
            "evidence": "The production render materially approaches the photographed object."
            if photo_applicable
            else "This asset brief has no source photograph.",
        },
        "style_flags": {flag: False for flag in VISUAL_STYLE_FLAGS},
        "style_evidence": "The production evidence supports the stated physical-art direction and shows no prohibited style characteristics.",
    }


def make_evaluation(
    candidate_id: str,
    decision: str = "promote",
    comparison: str = "first_pass",
    scores: dict[str, int] | None = None,
    source_resemblance: bool = False,
) -> ArtEvaluation:
    scores = scores or make_scores()
    if source_resemblance:
        scores["source_resemblance"] = 4
    return ArtEvaluation(
        candidate_id=candidate_id,
        scores=scores,
        observations={
            dimension: "Observed directly in the registered production render."
            for dimension in scores
        },
        hard_fail_reasons=[],
        defects=[] if decision == "promote" else ["The frame reads too uniformly flat."],
        likely_causes=[]
        if decision == "promote"
        else ["The recipe uses one material response on every component."],
        next_action_hypothesis="Separate glass, steel, and wood roughness values."
        if decision != "promote"
        else "",
        incumbent_comparison=comparison,
        decision=decision,
        render_evidence=[f"art/test-desk/iterations/{candidate_id[-4:]}/renders/close.png"],
        created_at_utc="2026-10-25T12:00:00+00:00",
        visual_gate=make_visual_gate(source_resemblance),
    )


class ArtFactoryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.factory = ArtFactory(self.root)
        self.factory.save_brief(make_brief())
        self.source = self.root / "generated.glb"
        self.source.write_bytes(b"glTF test asset")
        self.render = self.root / "godot-render.png"
        self.render.write_bytes(b"production render evidence")

    def create_candidate(self, *, parent: str = "") -> str:
        candidate = self.factory.create_candidate(
            "test-desk", make_recipe(), {"mesh/test.glb": self.source}, parent
        )
        self.factory.record_validation(
            candidate.candidate_id, {"status": "pass", "checks": ["mesh", "bounds"]}
        )
        self.factory.record_render(
            candidate.candidate_id,
            "close",
            self.render,
            {"production_path": True, "camera_distance_inches": 2.0, "resolution": [1280, 720]},
        )
        return candidate.candidate_id

    def submit_evaluation(self, candidate_id: str, **overrides: object) -> None:
        evaluation = make_evaluation(candidate_id, **overrides)
        candidate = self.factory.load_candidate(candidate_id)
        evidence_path = candidate.renders[0]["path"]
        evaluation.render_evidence = [evidence_path]
        self.factory.record_evaluation(evaluation)

    def test_brief_and_recipe_preserve_creation_constraints(self) -> None:
        brief_path = self.factory.save_brief(make_brief("room.json"))
        self.assertEqual(
            ArtBrief.from_dict(json.loads(brief_path.read_text())).intended_dimensions,
            (68.0, 30.0, 34.0),
        )
        self.assertIn("procedural mesh", make_recipe().to_dict()["method"])
        self.assertEqual(make_brief().validate(), [])
        self.assertEqual(make_recipe().validate(), [])

    def test_candidate_files_and_recipe_are_preserved(self) -> None:
        candidate_id = self.create_candidate()
        candidate = self.factory.load_candidate(candidate_id)
        self.assertEqual(candidate.status, "challenger")
        self.assertTrue((self.root / candidate.asset_files[0]).is_file())
        recipe = json.loads((self.root / candidate.recipe_file).read_text(encoding="utf-8"))
        self.assertEqual(recipe["deterministic_seed"], 25)

    def test_recorded_generator_command_creates_candidate_and_log(self) -> None:
        recipe = make_recipe()
        recipe = ArtRecipe(
            **{
                **recipe.to_dict(),
                "parameters": {"outputs": ["mesh.bin"]},
                "generator_command": [
                    sys.executable,
                    "-c",
                    "import os; from pathlib import Path; Path(os.environ['ROOMSCALE_ART_FACTORY_OUTPUT_DIR'], 'mesh.bin').write_bytes(b'generated')",
                ],
            }
        )
        candidate = self.factory.generate_candidate("test-desk", recipe)
        self.assertEqual(candidate.status, "challenger")
        self.assertEqual(candidate.generation_result["status"], "pass")
        self.assertTrue((self.root / candidate.asset_files[0]).is_file())
        self.assertTrue((self.root / "art/test-desk/iterations/v001/generation.log").is_file())

    def test_failed_generator_preserves_a_blocked_attempt(self) -> None:
        recipe = ArtRecipe(
            **{
                **make_recipe().to_dict(),
                "parameters": {"outputs": ["missing.bin"]},
                "generator_command": [sys.executable, "-c", "raise SystemExit(7)"],
            }
        )
        candidate = self.factory.generate_candidate("test-desk", recipe)
        self.assertEqual(candidate.status, "blocked")
        self.assertEqual(candidate.generation_result["exit_code"], 7)
        self.assertEqual(candidate.technical_validation["status"], "fail")
        self.assertTrue((self.root / "art/test-desk/iterations/v001/generation.log").is_file())

    def test_runtime_script_error_blocks_zero_exit_generator(self) -> None:
        recipe = ArtRecipe(
            **{
                **make_recipe().to_dict(),
                "parameters": {"outputs": ["mesh.bin"]},
                "generator_command": [
                    sys.executable,
                    "-c",
                    "import os; from pathlib import Path; print('SCRIPT ERROR: simulated generator failure'); Path(os.environ['ROOMSCALE_ART_FACTORY_OUTPUT_DIR'], 'mesh.bin').write_bytes(b'incomplete')",
                ],
            }
        )
        candidate = self.factory.generate_candidate("test-desk", recipe)
        self.assertEqual(candidate.status, "blocked")
        self.assertEqual(candidate.generation_result["exit_code"], 0)
        self.assertIn("emitted a script error", candidate.generation_result["reason"])
        self.assertEqual(candidate.technical_validation["status"], "fail")
        self.assertEqual(candidate.asset_files, [])
        self.assertTrue((self.root / "art/test-desk/iterations/v001/generated/mesh.bin").is_file())

    def test_nonproduction_render_is_not_accepted_as_evidence(self) -> None:
        candidate = self.factory.create_candidate(
            "test-desk", make_recipe(), {"mesh/test.glb": self.source}
        )
        with self.assertRaisesRegex(ValueError, "production RoomScale render path"):
            self.factory.record_render(
                candidate.candidate_id, "close", self.render, {"production_path": False}
            )
        self.assertEqual(self.factory.load_candidate(candidate.candidate_id).renders, [])

    def test_render_inside_candidate_uses_project_relative_evidence_path(self) -> None:
        candidate = self.factory.create_candidate(
            "test-desk", make_recipe(), {"mesh/test.glb": self.source}
        )
        in_candidate = self.root / "art/test-desk/iterations/v001/render-runs/run-001/close.png"
        in_candidate.parent.mkdir(parents=True)
        in_candidate.write_bytes(b"production viewport capture")
        self.factory.record_render(
            candidate.candidate_id,
            "close",
            in_candidate,
            {"production_path": True, "resolution": [1280, 720]},
        )
        evidence_path = self.factory.load_candidate(candidate.candidate_id).renders[0]["path"]
        self.assertEqual(
            evidence_path, "art/test-desk/iterations/v001/render-runs/run-001/close.png"
        )
        self.assertTrue((self.root / evidence_path).is_file())

    def test_hard_fail_and_low_scores_block_promotion(self) -> None:
        candidate_id = self.create_candidate()
        scores = make_scores()
        scores["material_realism"] = 3
        with self.assertRaisesRegex(ValueError, "material_realism=3"):
            self.submit_evaluation(candidate_id, scores=scores)

        candidate_id = self.create_candidate(parent="test-desk-v001")
        self.submit_evaluation(candidate_id, decision="continue", comparison="same")
        evaluation_path = self.root / self.factory.load_candidate(candidate_id).evaluation_file
        value = json.loads(evaluation_path.read_text(encoding="utf-8"))
        value["hard_fail_reasons"] = ["reads as placeholder geometry"]
        evaluation_path.write_text(json.dumps(value), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "did not pass the evidence-based visual gate"):
            self.factory.promote(candidate_id)

    def test_passed_candidate_promotes_and_incumbent_is_reversible(self) -> None:
        first = self.create_candidate()
        self.submit_evaluation(first)
        first_entry = self.factory.promote(first)
        self.assertEqual(first_entry["candidate_id"], first)
        self.assertEqual(self.factory.registry.verify("test-desk")[0], True)

        second = self.create_candidate(parent=first)
        scores = make_scores("material_realism")
        self.submit_evaluation(second, comparison="better", scores=scores)
        second_entry = self.factory.promote(second)
        self.assertEqual(second_entry["candidate_id"], second)
        self.assertEqual(self.factory.load_candidate(first).status, "accepted")
        self.assertEqual(self.factory.load_candidate(second).status, "accepted")
        registry = self.factory.registry.read()["entries"]["test-desk"]
        self.assertEqual(registry["candidate_id"], second)
        self.assertNotEqual(registry["path"], first_entry["path"])

    def test_worse_challenger_cannot_replace_incumbent(self) -> None:
        first = self.create_candidate()
        self.submit_evaluation(
            first,
            scores={
                dimension: 5 for dimension in RUBRIC_DIMENSIONS if dimension != "source_resemblance"
            },
        )
        self.factory.promote(first)
        second = self.create_candidate(parent=first)
        scores = {
            dimension: 5 for dimension in RUBRIC_DIMENSIONS if dimension != "source_resemblance"
        }
        scores["scale_fidelity"] = 4
        self.submit_evaluation(second, comparison="better", scores=scores)
        with self.assertRaisesRegex(ValueError, "scale_fidelity"):
            self.factory.promote(second)
        self.assertEqual(self.factory.registry.resolve("test-desk")["candidate_id"], first)

    def test_missing_candidate_does_not_replace_existing_incumbent(self) -> None:
        first = self.create_candidate()
        self.submit_evaluation(first)
        self.factory.promote(first)
        second = self.create_candidate(parent=first)
        self.submit_evaluation(second, comparison="better", scores=make_scores("material_realism"))
        candidate = self.factory.load_candidate(second)
        (self.root / candidate.asset_files[0]).unlink()
        with self.assertRaisesRegex(ValueError, "asset is missing"):
            self.factory.promote(second)
        self.assertEqual(self.factory.registry.resolve("test-desk")["candidate_id"], first)

    def test_photo_brief_requires_source_resemblance_evidence(self) -> None:
        self.factory.save_brief(make_brief("verification/poc2/canonical-room.json"))
        candidate_id = self.create_candidate()
        evaluation = make_evaluation(candidate_id)
        evaluation.render_evidence = [self.factory.load_candidate(candidate_id).renders[0]["path"]]
        with self.assertRaisesRegex(ValueError, "source_resemblance"):
            self.factory.record_evaluation(evaluation)

    def test_explicit_visual_gate_answers_are_required(self) -> None:
        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate = {}
        self.assertIn("missing explicit visual_gate answers", evaluation.validate())

        evaluation = make_evaluation("test-desk-v001")
        del evaluation.visual_gate["close_inspection"]["answer"]
        self.assertTrue(any("close_inspection.answer" in error for error in evaluation.validate()))

    def test_low_poly_descriptions_and_style_flags_block_pass(self) -> None:
        evaluation = make_evaluation("test-desk-v001")
        evaluation.observations["geometric_detail"] = "The desk is polished low-poly geometry."
        self.assertTrue(any("unapproved low-poly" in error for error in evaluation.validate()))

        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["style_flags"]["primitive_geometry"] = True
        self.assertTrue(
            any("unapproved stylization hard fail" in error for error in evaluation.validate())
        )

        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["style_flags"]["blocky_geometry"] = True
        self.assertTrue(
            any("unapproved stylization hard fail" in error for error in evaluation.validate())
        )

        evaluation = make_evaluation("test-desk-v001")
        evaluation.observations["geometric_detail"] = "The model still looks like a placeholder."
        self.assertTrue(any("unapproved low-poly" in error for error in evaluation.validate()))

        for field_name in ("defects", "likely_causes"):
            evaluation = make_evaluation("test-desk-v001")
            getattr(evaluation, field_name).append("The render still reads as primitive geometry.")
            self.assertTrue(any("unapproved low-poly" in error for error in evaluation.validate()))

        evaluation = make_evaluation("test-desk-v001")
        evaluation.next_action_hypothesis = "The current result remains simplified programmer art."
        self.assertTrue(any("unapproved low-poly" in error for error in evaluation.validate()))

        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["close_inspection"]["answer"] = (
            "No, it still reads as low-poly construction."
        )
        self.assertTrue(any("unapproved low-poly" in error for error in evaluation.validate()))

    def test_visual_gate_answers_must_match_their_pass_evidence(self) -> None:
        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["neutral_viewer_realism"]["answer"] = "Yes, but still stylized."
        self.assertTrue(
            any("must be exactly Yes or No" in error for error in evaluation.validate())
        )

        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["neutral_viewer_realism"]["answer"] = "No"
        self.assertTrue(
            any("answer contradicts its pass boolean" in error for error in evaluation.validate())
        )

        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["craftsmanship"]["answer"] = "No"
        self.assertTrue(
            any("craftsmanship.answer contradicts" in error for error in evaluation.validate())
        )

        evaluation = make_evaluation("test-desk-v001", source_resemblance=True)
        evaluation.visual_gate["photo_character"]["answer"] = "No"
        self.assertTrue(
            any(
                "photo_character.answer contradicts" in error
                for error in evaluation.validate(source_resemblance_required=True)
            )
        )

        repair = make_evaluation("test-desk-v001", decision="continue")
        repair.visual_gate["neutral_viewer_realism"]["pass"] = False
        repair.visual_gate["neutral_viewer_realism"]["answer"] = "No"
        repair.hard_fail_reasons = ["does not read as realistic furniture"]
        self.assertEqual(repair.validate(), [])

    def test_only_explicit_brief_stylization_allows_style_flags(self) -> None:
        brief = make_brief(allow_stylization=True)
        self.assertEqual(brief.validate(), [])
        evaluation = make_evaluation("test-desk-v001")
        evaluation.visual_gate["style_flags"]["substantially_stylized"] = True
        self.assertEqual(evaluation.validate(allow_stylization=True), [])
        self.assertIn(
            "allow_stylization requires an explicit stylization_rationale",
            make_brief()
            .__class__(**{**make_brief().__dict__, "allow_stylization": True})
            .validate(),
        )

    def test_comparison_result_is_validated(self) -> None:
        evaluation = make_evaluation("test-desk-v001", decision="continue", comparison="same")
        evaluation.incumbent_comparison_result = "probably_better"
        self.assertIn("unknown incumbent comparison result=probably_better", evaluation.validate())

    def test_registry_rejects_paths_outside_project(self) -> None:
        with self.assertRaisesRegex(ValueError, "escapes the project root"):
            self.factory.registry.local_path({"path": "../../outside.glb"})

    def test_text_asset_hash_ignores_windows_checkout_line_endings(self) -> None:
        lf_file = self.root / "asset.tscn"
        crlf_file = self.root / "asset-copy.tscn"
        lf_file.write_bytes(b'[gd_scene format=4]\n[node name="Root"]\n')
        crlf_file.write_bytes(lf_file.read_bytes().replace(b"\n", b"\r\n"))
        self.assertEqual(sha256_file(lf_file), sha256_file(crlf_file))
        crlf_file.write_bytes(crlf_file.read_bytes().replace(b"Root", b"Other"))
        self.assertNotEqual(sha256_file(lf_file), sha256_file(crlf_file))


if __name__ == "__main__":
    unittest.main()
