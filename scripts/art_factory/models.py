"""Durable JSON contracts for the offline RoomScale Art Factory."""

from __future__ import annotations

import re
from dataclasses import asdict, dataclass, field
from typing import Any

SCHEMA_VERSION = 1
RUBRIC_DIMENSIONS = (
    "semantic_recognizability",
    "silhouette_quality",
    "proportion",
    "geometric_detail",
    "material_realism",
    "surface_variation",
    "close_up_quality",
    "gameplay_readability",
    "scale_fidelity",
    "art_direction_fit",
    "technical_integration",
    "source_resemblance",
)
QUALITY_TIERS = {"A", "B", "C", "D"}
CANDIDATE_STATES = {"challenger", "incumbent", "rejected", "accepted", "blocked"}
EVALUATION_DECISIONS = {"continue", "promote", "reject", "blocked"}
VISUAL_CRAFT_CHECKS = (
    "edge_treatment",
    "joins",
    "thickness",
    "hardware",
    "material_response",
    "surface_variation",
    "manufacturing_detail",
)
VISUAL_STYLE_FLAGS = (
    "low_poly",
    "blocky_geometry",
    "placeholder_geometry",
    "primitive_geometry",
    "simplified_programmer_art",
    "materially_flat",
    "substantially_stylized",
)
_UNACCEPTABLE_STYLE_PATTERNS = (
    re.compile(r"\blow[ -]poly\b", re.IGNORECASE),
    re.compile(r"\bblocky\b", re.IGNORECASE),
    re.compile(r"\bplaceholder(?:[ -](?:art|geometry|asset|model|mesh|form|object))?\b", re.IGNORECASE),
    re.compile(r"\b(?:obvious )?programmer[ -]art\b", re.IGNORECASE),
    re.compile(r"\b(?:blocky|primitive) (?:geometry|geometr(?:y|ies)|forms?|construction)\b", re.IGNORECASE),
    re.compile(r"\b(?:reads?|looks?|feels?) (?:as |like )?(?:a )?(?:primitive|blocky)\b", re.IGNORECASE),
    re.compile(r"\bsimplified (?:programmer[ -]art )?(?:geometry|mesh|forms?|construction)\b", re.IGNORECASE),
    re.compile(r"\bmaterially flat\b|\bflat (?:material|surface|appearance)\b", re.IGNORECASE),
    re.compile(r"\b(?:substantially|intentionally|obviously|heavily) styl(?:i|y)z(?:ed|ed)\b", re.IGNORECASE),
    re.compile(r"\bmore styl(?:i|y)z(?:ed|ed) than\b", re.IGNORECASE),
    re.compile(r"\bsimple but deliberate\b", re.IGNORECASE),
)


def _has_unacceptable_style_language(text: str) -> bool:
    """Catch affirmative style descriptions while allowing explicit negation."""
    for pattern in _UNACCEPTABLE_STYLE_PATTERNS:
        for match in pattern.finditer(text):
            prefix = text[max(0, match.start() - 36) : match.start()]
            if re.search(
                r"\b(?:not|no|without|free of|rather than|avoid(?:s|ed)?)\s+"
                r"(?:(?:obvious|any|a|an|the|does|do|did|is|are|be|being|read(?:s|ing)?|"
                r"look(?:s|ing)?|feel(?:s|ing)?|have|has|show(?:s|ing)?|contain(?:s|ing)?|as)\s+){0,4}$",
                prefix,
                re.IGNORECASE,
            ):
                continue
            return True
    return False


@dataclass(frozen=True)
class ArtBrief:
    asset_id: str
    semantic_type: str
    display_name: str
    category: str
    intended_dimensions: tuple[float, float, float]
    gameplay_invariants: dict[str, Any]
    reference_images: list[str]
    visual_target: str
    materials: dict[str, Any]
    required_features: list[str]
    prohibited_changes: list[str]
    camera_distances: list[float]
    quality_tier: str
    iteration_budget: int
    source_room_definition: str = ""
    schema_version: int = SCHEMA_VERSION
    allow_stylization: bool = False
    stylization_rationale: str = ""

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> ArtBrief:
        data = dict(value)
        data["intended_dimensions"] = tuple(float(v) for v in data["intended_dimensions"])
        return cls(**data)

    def to_dict(self) -> dict[str, Any]:
        result = asdict(self)
        result["intended_dimensions"] = list(self.intended_dimensions)
        return result

    def validate(self) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(f"unsupported brief schema_version={self.schema_version}")
        for field_name in (
            "asset_id",
            "semantic_type",
            "display_name",
            "category",
            "visual_target",
        ):
            if not getattr(self, field_name).strip():
                errors.append(f"{field_name} must be non-empty")
        if len(self.intended_dimensions) != 3 or any(
            value <= 0 for value in self.intended_dimensions
        ):
            errors.append("intended_dimensions must contain three positive values in inches")
        if self.quality_tier not in QUALITY_TIERS:
            errors.append(f"quality_tier must be one of {sorted(QUALITY_TIERS)}")
        if self.iteration_budget < 0:
            errors.append("iteration_budget must be zero or greater")
        if self.allow_stylization and not self.stylization_rationale.strip():
            errors.append("allow_stylization requires an explicit stylization_rationale")
        if not self.required_features:
            errors.append("required_features must define recognizable features")
        if not self.prohibited_changes:
            errors.append("prohibited_changes must define preserved invariants")
        if any(distance <= 0 for distance in self.camera_distances):
            errors.append("camera_distances must be positive inches")
        return errors


@dataclass(frozen=True)
class ArtRecipe:
    method: str
    instructions: str
    parameters: dict[str, Any]
    source_inputs: list[str]
    tool: str
    tool_version: str
    post_processing: list[str]
    material_method: str
    import_configuration: dict[str, Any]
    deterministic_seed: int | None = None
    generator_command: list[str] = field(default_factory=list)
    schema_version: int = SCHEMA_VERSION

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> ArtRecipe:
        return cls(**dict(value))

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def validate(self) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(f"unsupported recipe schema_version={self.schema_version}")
        for field_name in ("method", "instructions", "tool", "tool_version", "material_method"):
            if not getattr(self, field_name).strip():
                errors.append(f"{field_name} must be non-empty")
        if not self.import_configuration:
            errors.append("import_configuration must record the intended import settings")
        return errors


@dataclass
class ArtCandidate:
    candidate_id: str
    asset_id: str
    version: int
    status: str
    asset_files: list[str]
    recipe_file: str
    created_at_utc: str
    parent_candidate_id: str = ""
    generation_result: dict[str, Any] = field(default_factory=dict)
    technical_validation: dict[str, Any] = field(default_factory=dict)
    renders: list[dict[str, Any]] = field(default_factory=list)
    evaluation_file: str = ""
    schema_version: int = SCHEMA_VERSION

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> ArtCandidate:
        return cls(**dict(value))

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def validate(self) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(f"unsupported candidate schema_version={self.schema_version}")
        if not self.candidate_id.strip() or not self.asset_id.strip():
            errors.append("candidate_id and asset_id must be non-empty")
        if self.version < 1:
            errors.append("candidate version must be positive")
        if self.status not in CANDIDATE_STATES:
            errors.append(f"unknown candidate status={self.status}")
        if not self.asset_files and self.status != "blocked":
            errors.append("candidate must contain at least one asset file")
        return errors


@dataclass
class ArtEvaluation:
    candidate_id: str
    scores: dict[str, int]
    observations: dict[str, str]
    hard_fail_reasons: list[str]
    defects: list[str]
    likely_causes: list[str]
    next_action_hypothesis: str
    incumbent_comparison: str
    decision: str
    render_evidence: list[str]
    created_at_utc: str
    incumbent_candidate_id: str = ""
    incumbent_comparison_result: str = ""
    schema_version: int = SCHEMA_VERSION
    visual_gate: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> ArtEvaluation:
        return cls(**dict(value))

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def validate(
        self,
        source_resemblance_required: bool = False,
        allow_stylization: bool = False,
    ) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(f"unsupported evaluation schema_version={self.schema_version}")
        if self.decision not in EVALUATION_DECISIONS:
            errors.append(f"unknown evaluation decision={self.decision}")
        errors.extend(
            self._validate_visual_gate(
                allow_stylization=allow_stylization,
                photo_character_required=source_resemblance_required,
            )
        )
        if self.incumbent_comparison_result and self.incumbent_comparison_result not in {
            "first_pass",
            "better",
            "same",
            "worse",
        }:
            errors.append(f"unknown incumbent comparison result={self.incumbent_comparison_result}")
        for dimension, score in self.scores.items():
            if dimension not in RUBRIC_DIMENSIONS or not 1 <= score <= 5:
                errors.append(f"invalid rubric score {dimension}={score}")
            if not self.observations.get(dimension, "").strip():
                errors.append(f"score {dimension} requires an evidence observation")
        required = [
            dimension for dimension in RUBRIC_DIMENSIONS if dimension != "source_resemblance"
        ]
        if source_resemblance_required:
            required.append("source_resemblance")
        for dimension in required:
            if dimension not in self.scores:
                errors.append(f"missing applicable rubric dimension {dimension}")
        if self.decision == "promote" and not self.render_evidence:
            errors.append("promotion requires production render evidence")
        if self.decision == "continue" and (
            not self.defects or not self.likely_causes or not self.next_action_hypothesis.strip()
        ):
            errors.append(
                "continued candidates require defects, likely causes, and a targeted next action"
            )
        if self.decision == "promote":
            if self.hard_fail_reasons:
                errors.append("hard visual failures prohibit promotion")
            for dimension, score in self.scores.items():
                threshold = (
                    5 if dimension in {"semantic_recognizability", "technical_integration"} else 4
                )
                if score < threshold:
                    errors.append(
                        f"promotion threshold not met: {dimension}={score}, requires {threshold}"
                    )
        return errors

    def _validate_visual_gate(
        self,
        allow_stylization: bool,
        photo_character_required: bool,
    ) -> list[str]:
        errors: list[str] = []
        failures: list[str] = []
        gate = self.visual_gate
        if not gate:
            return ["missing explicit visual_gate answers"]

        def require_answer(name: str, description: str) -> None:
            answer = gate.get(name)
            if not isinstance(answer, dict):
                errors.append(f"visual_gate.{name} must include an explicit answer, pass, and evidence")
                return
            if not str(answer.get("answer", "")).strip():
                errors.append(f"visual_gate.{name}.answer must explicitly answer the review question")
            if not isinstance(answer.get("pass"), bool):
                errors.append(f"visual_gate.{name}.pass must be a boolean")
            elif not answer["pass"]:
                failures.append(f"visual gate failed: {description}")
            if not str(answer.get("evidence", "")).strip():
                errors.append(f"visual_gate.{name}.evidence is required")

        require_answer(
            "neutral_viewer_realism",
            "a neutral viewer would read the asset as low-poly/stylized game geometry",
        )
        require_answer(
            "close_inspection",
            "the asset does not hold up at close inspection",
        )
        craft = gate.get("craftsmanship")
        if not isinstance(craft, dict):
            errors.append("visual_gate.craftsmanship must answer all seven manufacturing checks")
        else:
            if not str(craft.get("answer", "")).strip():
                errors.append("visual_gate.craftsmanship.answer must explicitly answer whether all manufacturing details are believable")
            for check in VISUAL_CRAFT_CHECKS:
                value = craft.get(check)
                if not isinstance(value, dict):
                    errors.append(f"visual_gate.craftsmanship.{check} must include pass and evidence")
                    continue
                if not isinstance(value.get("pass"), bool):
                    errors.append(f"visual_gate.craftsmanship.{check}.pass must be a boolean")
                elif not value["pass"]:
                    failures.append(f"visual gate failed: craftsmanship {check.replace('_', ' ')} is not believable")
                if not str(value.get("evidence", "")).strip():
                    errors.append(f"visual_gate.craftsmanship.{check}.evidence is required")

        photo = gate.get("photo_character")
        if not isinstance(photo, dict) or not isinstance(photo.get("applicable"), bool):
            errors.append("visual_gate.photo_character must state applicability, pass, and evidence")
        elif photo["applicable"] != photo_character_required:
            errors.append(
                "visual_gate.photo_character applicability must match whether the ArtBrief has source imagery"
            )
        elif photo["applicable"]:
            if not str(photo.get("answer", "")).strip():
                errors.append("visual_gate.photo_character.answer must explicitly answer the source-character question")
            if not isinstance(photo.get("pass"), bool):
                errors.append("visual_gate.photo_character.pass must be a boolean when a photograph exists")
            elif not photo["pass"]:
                failures.append("visual gate failed: render does not materially approach the photographed object's visual character")
            if not str(photo.get("evidence", "")).strip():
                errors.append("visual_gate.photo_character.evidence is required when applicable")
        elif not str(photo.get("answer", "")).strip():
            errors.append("visual_gate.photo_character.answer must explain why this question is not applicable")
        elif photo.get("pass") is not None:
            errors.append("visual_gate.photo_character.pass must be null when not applicable")
        elif not str(photo.get("evidence", "")).strip():
            errors.append("visual_gate.photo_character.evidence must explain why it is not applicable")

        flags = gate.get("style_flags")
        if not isinstance(flags, dict):
            errors.append("visual_gate.style_flags must explicitly answer each hard style gate")
        else:
            for flag in VISUAL_STYLE_FLAGS:
                value = flags.get(flag)
                if not isinstance(value, bool):
                    errors.append(f"visual_gate.style_flags.{flag} must be a boolean")
                elif value and not allow_stylization:
                    failures.append(f"unapproved stylization hard fail: {flag}")

        if not allow_stylization:
            evidence_text = " ".join(
                [str(value) for value in self.observations.values()]
                + _collect_strings(gate)
            )
            if _has_unacceptable_style_language(evidence_text):
                failures.append("unapproved low-poly, primitive, simplified, flat, or substantially stylized appearance described in visual evidence")
        if failures:
            if self.decision == "promote":
                errors.extend(failures)
            elif not self.hard_fail_reasons:
                errors.append("failed visual gate answers must be preserved in hard_fail_reasons")
        return errors


def _collect_strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [part for nested in value.values() for part in _collect_strings(nested)]
    if isinstance(value, (list, tuple)):
        return [part for nested in value for part in _collect_strings(nested)]
    return []
