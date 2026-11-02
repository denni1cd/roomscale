"""Boundary tests for persistent candidate history and promotion safeguards."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

from art_factory import visual_inventory
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
    iteration_budget: int | None = 8,
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
        iteration_budget=iteration_budget,
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

    def test_visual_inventory_prefers_current_visual_director_candidate(self) -> None:
        state_path = self.root / "art/test-settlement/visual_director/state.json"
        state_path.parent.mkdir(parents=True)
        state_path.write_text(
            json.dumps(
                {
                    "status": "in_progress",
                    "best_3d_candidate": {"candidate_id": "test-settlement-v003"},
                }
            ),
            encoding="utf-8",
        )
        evaluation_path = self.root / "art/test-settlement/iterations/v003/evaluation.json"
        evaluation_path.parent.mkdir(parents=True)
        evaluation_path.write_text(json.dumps({"decision": "continue"}), encoding="utf-8")

        previous_root = visual_inventory.ROOT
        visual_inventory.ROOT = self.root
        self.addCleanup(setattr, visual_inventory, "ROOT", previous_root)
        state = visual_inventory.current_asset_state(
            "test-settlement",
            {
                "production_registry": {
                    "test-settlement": {
                        "candidate_id": "test-settlement-v001",
                        "status": "accepted",
                    }
                },
                "review_registry": {
                    "test-settlement": {
                        "candidate_id": "test-settlement-v002",
                        "strict_pilot_gate_status": "promote",
                    }
                },
                "art_briefs": {"test-settlement"},
                "strict_incumbent_audit": {},
            },
        )

        self.assertEqual(state["best_current_candidate"], "test-settlement-v003")
        self.assertEqual(
            state["best_current_candidate_source"], "Visual Director best 3D candidate"
        )
        self.assertEqual(state["strict_evaluation_decision"], "continue")
        self.assertIsNone(state["strict_gate_result"])
        self.assertEqual(state["production_registry_status"], "accepted")

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

    def test_dimension_tolerance_must_be_finite_and_non_negative(self) -> None:
        self.assertNotIn("dimension_tolerance_inches", make_brief().to_dict())
        self.assertEqual(replace(make_brief(), dimension_tolerance_inches=0.01).validate(), [])
        self.assertTrue(
            any(
                "dimension_tolerance_inches" in error
                for error in replace(make_brief(), dimension_tolerance_inches=-0.01).validate()
            )
        )
        self.assertTrue(
            any(
                "dimension_tolerance_inches" in error
                for error in replace(
                    make_brief(), dimension_tolerance_inches=float("nan")
                ).validate()
            )
        )
        self.assertTrue(
            any(
                "dimension_tolerance_inches" in error
                for error in replace(make_brief(), dimension_tolerance_inches="0.01").validate()
            )
        )

    def test_visual_target_approval_records_the_actual_pixel_reviewer(self) -> None:
        target = self.root / "art/test-desk/visual_director/round-01/target.png"
        review = self.root / "art/test-desk/visual_director/round-01/pixel-review.md"
        target.parent.mkdir(parents=True)
        target.write_bytes(b"reviewed image bytes")
        review.write_text("Pixel review evidence.", encoding="utf-8")

        result = self.factory.approve_visual_target(
            "test-desk",
            target.relative_to(self.root).as_posix(),
            review.relative_to(self.root).as_posix(),
            reviewer="Codex visual review",
        )

        self.assertEqual(
            result["approved_visual_target"]["review_method"],
            "pixel inspection; review evidence recorded by Codex visual review",
        )

    def test_unbounded_pilot_brief_can_create_more_than_eight_challengers(self) -> None:
        brief_path = self.factory.save_brief(make_brief(iteration_budget=None))
        recorded = ArtBrief.from_dict(json.loads(brief_path.read_text(encoding="utf-8")))
        self.assertIsNone(recorded.iteration_budget)
        self.assertEqual(recorded.validate(), [])

        candidates = [
            self.factory.create_candidate(
                "test-desk", make_recipe(), {"mesh/test.glb": self.source}
            )
            for _ in range(10)
        ]
        self.assertEqual(candidates[-1].candidate_id, "test-desk-v010")

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
                "parameters": {
                    "outputs": ["mesh.bin"],
                    "visual_director_strategy": "initial",
                },
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

    def test_blocked_visual_director_generation_can_resume_without_spending_an_art_attempt(
        self,
    ) -> None:
        brief = ArtBrief(
            **{
                **make_brief().to_dict(),
                "category": "room_furniture",
                "priority_tier": 1,
            }
        )
        self.factory.save_brief(brief)
        target_path = "art/test-desk/visual_director/round-01/target.png"
        review_path = "art/test-desk/visual_director/round-01/pixel-review.md"
        target_file = self.root / target_path
        review_file = self.root / review_path
        target_file.parent.mkdir(parents=True)
        target_file.write_bytes(b"approved pixel target")
        review_file.write_text("Target pixels reviewed.", encoding="utf-8")
        self.factory.approve_visual_target(
            "test-desk",
            target_path=target_path,
            review_path=review_path,
            concept_id="test-bookcase-r01",
            reviewer="test reviewer",
        )
        recipe = ArtRecipe(
            **{
                **make_recipe().to_dict(),
                "source_inputs": [target_path],
                "parameters": {
                    "outputs": ["mesh.bin"],
                    "visual_director_strategy": "initial",
                },
                "generator_command": [
                    sys.executable,
                    "-c",
                    "import os, pathlib, sys; output = pathlib.Path(os.environ['ROOMSCALE_ART_FACTORY_OUTPUT_DIR']); print('initial execution blocked'); sys.exit(7) if 'run-002' not in output.as_posix() else None; (output / 'mesh.bin').write_bytes(b'generated')",
                ],
            }
        )

        candidate = self.factory.generate_candidate("test-desk", recipe)
        self.assertEqual(candidate.candidate_id, "test-desk-v001")
        self.assertEqual(candidate.status, "blocked")
        initial_log = self.root / "art/test-desk/iterations/v001/generation.log"
        self.assertIn("initial execution blocked", initial_log.read_text(encoding="utf-8"))
        self.factory.backlog_visual_director_case(
            "test-desk", "Generator dependency was unavailable."
        )

        resumed = self.factory.retry_candidate_generation(candidate.candidate_id)
        self.assertEqual(resumed.candidate_id, candidate.candidate_id)
        self.assertEqual(resumed.status, "challenger")
        self.assertEqual(resumed.generation_result["status"], "pass")
        self.assertEqual([run["status"] for run in resumed.generation_attempts], ["fail", "pass"])
        self.assertEqual(resumed.visual_director_provenance["target_episode_attempt"], 1)
        self.assertTrue((self.root / resumed.asset_files[0]).is_file())
        self.assertIn("initial execution blocked", initial_log.read_text(encoding="utf-8"))

        state = json.loads(
            (self.root / "art/test-desk/visual_director/state.json").read_text(encoding="utf-8")
        )
        self.assertEqual(len(state["target_episode"]["attempts"]), 1)
        self.assertEqual(state["target_episode"]["attempts"][0]["attempt"], 1)
        self.assertEqual(state["target_episode"]["attempts"][0]["status"], "awaiting_render_review")
        self.assertEqual(state["target_episode"]["attempts"][0]["generation_executions"], 2)
        self.assertEqual(state["status"], "in_progress")
        self.assertNotIn("backlog_reason", state)

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
        evaluation.incumbent_comparison = "The challenger remains primitive geometry."
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

    def test_visual_director_craftsmanship_must_cite_registered_production_renders(self) -> None:
        candidate_id = self.create_candidate()
        candidate = self.factory.load_candidate(candidate_id)
        candidate.visual_director_provenance = {
            "approved_visual_target": {"path": "art/test-desk/visual_director/target.png"}
        }
        self.factory._save_candidate(candidate)

        evaluation = make_evaluation(candidate_id)
        render_path = candidate.renders[0]["path"]
        evaluation.render_evidence = [render_path]
        with self.assertRaisesRegex(ValueError, "evidence_refs"):
            self.factory.record_evaluation(evaluation)

        for check in VISUAL_CRAFT_CHECKS:
            evaluation.visual_gate["craftsmanship"][check]["evidence_refs"] = [render_path]
        evaluation.visual_transfer_diagnosis = {
            "primary_causes": ["geometry_loss"],
            "lost_visual_information": ["No target detail was lost in this fixture."],
            "preserved_components": ["The test desk frame remains present."],
            "corrective_action": "No correction is required for this test fixture.",
        }
        self.factory.record_evaluation(evaluation)

    def test_visual_director_rejects_copied_craftsmanship_text_from_another_asset(self) -> None:
        candidate_id = self.create_candidate()
        candidate = self.factory.load_candidate(candidate_id)
        candidate.visual_director_provenance = {
            "approved_visual_target": {"path": "art/test-desk/visual_director/target.png"}
        }
        self.factory._save_candidate(candidate)

        evaluation = make_evaluation(candidate_id)
        render_path = candidate.renders[0]["path"]
        evaluation.render_evidence = [render_path]
        for check in VISUAL_CRAFT_CHECKS:
            evaluation.visual_gate["craftsmanship"][check]["evidence_refs"] = [render_path]
        evaluation.visual_transfer_diagnosis = {
            "primary_causes": ["geometry_loss"],
            "lost_visual_information": ["No target detail was lost in this fixture."],
            "preserved_components": ["The test desk frame remains present."],
            "corrective_action": "No correction is required for this test fixture.",
        }

        previous_asset_assessment = (
            self.root / "art/other-asset/visual_director/round-01/assessments/other-v001.json"
        )
        previous_asset_assessment.parent.mkdir(parents=True)
        previous_asset_assessment.write_text(
            json.dumps(
                {
                    "visual_gate": {
                        "craftsmanship": {
                            "edge_treatment": {
                                "evidence": evaluation.visual_gate["craftsmanship"][
                                    "edge_treatment"
                                ]["evidence"]
                            }
                        }
                    }
                }
            ),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(ValueError, "repeats wording recorded for semantic asset"):
            self.factory.record_evaluation(evaluation)

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


class VisualDirectorIntegrityTest(unittest.TestCase):
    root = Path(__file__).resolve().parents[1]

    @staticmethod
    def _read_json(path: Path) -> dict[str, object]:
        return json.loads(path.read_text(encoding="utf-8"))

    def test_production_state_registry_evaluation_and_receipts_agree(self) -> None:
        registry = self._read_json(self.root / "art/registry.json")
        cases = (
            (
                "display_cabinet",
                "display_cabinet-v003",
                "production_pass",
                "v003",
                "display_cabinet-v003",
            ),
            (
                "room_photo_window_production",
                "room_photo_window_production-v004",
                "production_pass",
                "v004",
                "room_photo_window_production-v004",
            ),
            (
                "settlement_workshop",
                "settlement_workshop-v004",
                "backlog",
                "v004",
                "settlement_workshop-v008",
            ),
        )
        for asset_id, production_id, expected_state, version, best_3d_id in cases:
            with self.subTest(asset_id=asset_id):
                asset_root = self.root / "art" / asset_id
                state = self._read_json(asset_root / "visual_director/state.json")
                candidate = self._read_json(asset_root / "iterations" / version / "candidate.json")
                evaluation = self._read_json(
                    asset_root / "iterations" / version / "evaluation.json"
                )
                entry = registry["entries"][asset_id]
                production = state["production_asset"]
                self.assertEqual(state["status"], expected_state)
                self.assertEqual(state["best_3d_candidate"]["candidate_id"], best_3d_id)
                self.assertEqual(production["candidate_id"], production_id)
                self.assertEqual(entry["candidate_id"], production_id)
                self.assertEqual(candidate["candidate_id"], production_id)
                self.assertEqual(candidate["status"], "accepted")
                self.assertEqual(evaluation["candidate_id"], production_id)
                self.assertEqual(evaluation["decision"], "promote")

                asset_path = entry["path"]
                self.assertEqual(production["path"], asset_path)
                self.assertIn(asset_path, candidate["asset_files"])
                self.assertEqual(production.get("sha256", entry["sha256"]), entry["sha256"])
                self.assertEqual(sha256_file(self.root / asset_path), entry["sha256"])

                receipt_root = asset_root / "iterations" / version / "render-runs/run-001"
                receipt = self._read_json(receipt_root / "receipt.json")
                self.assertEqual(receipt["asset_id"], asset_id)
                self.assertEqual(receipt["candidate_id"], production_id)
                self.assertEqual(receipt["loaded_candidate_id"], production_id)
                self.assertEqual(receipt["loaded_asset_path"], "res://" + asset_path)
                self.assertTrue(receipt["production_path"])
                if (receipt_root / "candidate-registry.json").is_file():
                    render_registry = self._read_json(receipt_root / "candidate-registry.json")
                    self.assertEqual(
                        render_registry["entries"][asset_id]["candidate_id"], production_id
                    )
                    self.assertEqual(render_registry["entries"][asset_id]["path"], asset_path)
                if best_3d_id != production_id:
                    best_version = best_3d_id.rsplit("-v", maxsplit=1)[1]
                    best_root = asset_root / "iterations" / f"v{int(best_version):03d}"
                    best_candidate = self._read_json(best_root / "candidate.json")
                    best_evaluation = self._read_json(best_root / "evaluation.json")
                    self.assertEqual(best_candidate["candidate_id"], best_3d_id)
                    self.assertEqual(best_evaluation["candidate_id"], best_3d_id)
                    self.assertEqual(
                        state["best_3d_candidate"]["evaluation_file"],
                        f"art/{asset_id}/iterations/v{int(best_version):03d}/evaluation.json",
                    )
                    self.assertEqual(best_evaluation["incumbent_comparison_result"], "better")

        workshop_state = self._read_json(
            self.root / "art/settlement_workshop/visual_director/state.json"
        )
        final_candidate = self._read_json(
            self.root / "art/settlement_workshop/iterations/v009/candidate.json"
        )
        final_evaluation = self._read_json(
            self.root / "art/settlement_workshop/iterations/v009/evaluation.json"
        )
        self.assertEqual(final_candidate["candidate_id"], "settlement_workshop-v009")
        self.assertEqual(final_evaluation["decision"], "continue")
        self.assertEqual(final_evaluation["incumbent_candidate_id"], "settlement_workshop-v008")
        self.assertEqual(final_evaluation["incumbent_comparison_result"], "worse")
        self.assertEqual(workshop_state["status"], "backlog")
        self.assertEqual(workshop_state["target_episode"]["status"], "backlog")
        self.assertEqual(len(workshop_state["target_episode"]["attempts"]), 3)
        self.assertEqual(
            workshop_state["target_episode"]["attempts"][-1]["candidate_id"],
            final_candidate["candidate_id"],
        )
        self.assertEqual(
            workshop_state["production_asset"]["candidate_id"], "settlement_workshop-v004"
        )
        self.assertEqual(
            workshop_state["best_3d_candidate"]["candidate_id"], "settlement_workshop-v008"
        )
        self.assertNotIn("backlog_reason", workshop_state)
        self.assertNotIn("backlog_reason", workshop_state["target_episode"])

        final_renders = {render["path"]: render for render in final_candidate.get("renders", [])}
        for check in VISUAL_CRAFT_CHECKS:
            for evidence_path in final_evaluation["visual_gate"]["craftsmanship"][check][
                "evidence_refs"
            ]:
                self.assertIn(evidence_path, final_evaluation["render_evidence"])
                self.assertTrue(final_renders[evidence_path]["production_path"])

    def test_batch_craftsmanship_evidence_is_asset_specific_and_render_linked(self) -> None:
        cases = (
            ("display_cabinet", "v003"),
            ("room_photo_window_production", "v003"),
            ("room_photo_window_production", "v004"),
            ("settlement_workshop", "v007"),
        )
        evidence_by_asset: dict[str, set[str]] = {}
        for asset_id, version in cases:
            candidate_id = f"{asset_id}-{version}"
            with self.subTest(candidate_id=candidate_id):
                asset_root = self.root / "art" / asset_id
                iteration_root = asset_root / "iterations" / version
                candidate = self._read_json(iteration_root / "candidate.json")
                evaluation = self._read_json(iteration_root / "evaluation.json")
                assessment = self._read_json(
                    asset_root / "visual_director/round-01/assessments" / f"{candidate_id}.json"
                )
                self.assertEqual(evaluation["candidate_id"], candidate_id)
                craft = evaluation["visual_gate"]["craftsmanship"]
                assessment_craft = assessment["visual_gate"]["craftsmanship"]
                self.assertEqual(craft, assessment_craft)
                registered_renders = {
                    render["path"]: render for render in candidate.get("renders", [])
                }
                asset_evidence: set[str] = set()
                for check in VISUAL_CRAFT_CHECKS:
                    result = craft[check]
                    self.assertTrue(result["evidence"].strip())
                    self.assertTrue(result["evidence_refs"])
                    for evidence_path in result["evidence_refs"]:
                        self.assertIn(evidence_path, evaluation["render_evidence"])
                        self.assertTrue(
                            evidence_path.startswith(
                                f"art/{asset_id}/iterations/{version}/render-runs/"
                            )
                        )
                        self.assertTrue(registered_renders[evidence_path]["production_path"])
                    asset_evidence.add(result["evidence"].casefold())
                evidence_by_asset.setdefault(asset_id, set()).update(asset_evidence)

        window_evidence = evidence_by_asset["room_photo_window_production"]
        for unrelated_asset in ("display_cabinet", "settlement_workshop"):
            unrelated_evidence = evidence_by_asset[unrelated_asset]
            self.assertTrue(window_evidence.isdisjoint(unrelated_evidence))
            joined = " ".join(unrelated_evidence)
            self.assertNotRegex(joined, r"\b(?:window|sash|jambs?|transom|sill|muntin)\b")
        self.assertRegex(
            " ".join(window_evidence), r"\b(?:window|sash|jambs?|transom|sill|latch)\b"
        )


if __name__ == "__main__":
    unittest.main()
