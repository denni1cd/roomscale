"""Policy and project evidence helpers for the Art Factory Visual Director gate."""

from __future__ import annotations

from typing import Any


class VisualDirectorGateRequired(RuntimeError):
    def __init__(
        self,
        asset_id: str,
        case_file: str,
        visual_brief_file: str,
        reasons: list[str],
    ) -> None:
        self.asset_id = asset_id
        self.case_file = case_file
        self.visual_brief_file = visual_brief_file
        self.reasons = reasons
        super().__init__(f"Visual Director approval is required for {asset_id}")


def classify_visual_director_policy(brief: Any) -> dict[str, Any]:
    """Determine whether an asset needs an approved visual target before 3D work."""
    category = str(brief.category).strip().lower()
    dimension_max = max(brief.intended_dimensions)
    priority = int(getattr(brief, "priority_tier", 0) or 0)
    screen_space = int(getattr(brief, "screen_space_importance", 3) or 3)
    inferred = []

    if priority == 0:
        if category == "architectural_opening":
            priority, screen_space = 1, max(screen_space, 5)
            inferred.append("architectural_opening defaults to Tier 1 / very high screen space")
        elif category == "settlement_structure":
            priority, screen_space = 1, max(screen_space, 4)
            inferred.append("settlement_structure defaults to Tier 1 / high screen space")
        elif category == "room_furniture" and dimension_max >= 30.0:
            priority, screen_space = 1, max(screen_space, 4)
            inferred.append("large room_furniture defaults to Tier 1 / high screen space")
        else:
            priority = 3
            inferred.append("unclassified asset defaults to supporting Tier 3")

    source_required = bool(getattr(brief, "source_photo_required", False))
    if not source_required and brief.reference_images and category in {
        "architectural_opening", "room_furniture"
    }:
        source_required = True
        inferred.append("source imagery on a room asset implies source-character review")

    faction_defining = bool(getattr(brief, "faction_defining", False))
    current_quality = str(getattr(brief, "current_quality", "unknown"))
    reasons = []
    if priority == 1:
        reasons.append("Tier 1 scene-defining asset")
    if priority == 2 and faction_defining:
        reasons.append("Tier 2 faction-defining asset")
    if screen_space >= 5:
        reasons.append("very high screen-space importance")
    elif screen_space >= 4:
        reasons.append("high screen-space importance")
    if source_required and screen_space >= 4:
        reasons.append("source-photo character is required for a prominent asset")
    if current_quality == "below_target" and priority <= 2:
        reasons.append("current production quality is below target")

    return {
        "required": bool(reasons),
        "reasons": reasons,
        "inputs": {
            "priority_tier": priority,
            "screen_space_importance": screen_space,
            "source_photo_required": source_required,
            "source_images_present": bool(brief.reference_images),
            "faction_defining": faction_defining,
            "current_quality": current_quality,
            "category": category,
            "inferred": inferred,
        },
    }


def visual_brief_scaffold(brief: Any) -> dict[str, Any]:
    """Create an editable VisualBrief draft without claiming image approval."""
    source_constraints = None
    if brief.reference_images:
        source_constraints = (
            "Inspect the listed source images and state which visible features are evidenced, "
            "which are occluded, and which construction details remain assumptions: "
            + ", ".join(brief.reference_images)
        )
    materials = brief.materials if isinstance(brief.materials, dict) else {}
    construction_materials = [
        {
            "part": str(part),
            "construction": "Specify the visible assembly and joins during visual development.",
            "material": str(material),
        }
        for part, material in materials.items()
    ]
    if not construction_materials:
        construction_materials = [
            {
                "part": "primary assembly",
                "construction": "Specify the visible assembly and joins during visual development.",
                "material": "Use the ArtBrief material requirements.",
            }
        ]
    return {
        "asset_id": brief.asset_id,
        "semantic_identity": brief.semantic_type,
        "intended_function": brief.visual_target,
        "dimensions_inches": list(brief.intended_dimensions),
        "citizen_scale": {
            "citizen_height_inches": 0.5,
            "ratio_or_view": (
                f"Use the exact {brief.intended_dimensions[1]:g}-inch height against a "
                "0.5-inch citizen; derive a schematic if generated scale is inaccurate."
            ),
        },
        "silhouette_requirements": list(brief.required_features),
        "construction_materials": construction_materials,
        "art_direction": f"RoomScale category: {brief.category}. {brief.visual_target}",
        "faction_identity": brief.semantic_type if brief.faction_defining else None,
        "gameplay_distance_readability": (
            "Keep required features legible at the ArtBrief gameplay camera distances: "
            + ", ".join(str(value) for value in brief.camera_distances)
            + " inches."
        ),
        "source_photo_constraints": source_constraints,
        "visual_references": [
            {"path": path, "role": "source image", "provenance": "ArtBrief reference_images"}
            for path in brief.reference_images
        ],
        "prohibited_failure_modes": list(brief.prohibited_changes),
        "roomdefinition_authority": (
            f"ArtBrief dimensions are {brief.intended_dimensions}; "
            f"source RoomDefinition: {brief.source_room_definition or 'not specified'}. "
            "RoomDefinition remains authoritative for placement and gameplay."
        ),
        "separate_room_assets": [],
    }

