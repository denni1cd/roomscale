"""Durable JSON contracts for the offline RoomScale Art Factory."""

from __future__ import annotations

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

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> ArtEvaluation:
        return cls(**dict(value))

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def validate(self, source_resemblance_required: bool = False) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(f"unsupported evaluation schema_version={self.schema_version}")
        if self.decision not in EVALUATION_DECISIONS:
            errors.append(f"unknown evaluation decision={self.decision}")
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
