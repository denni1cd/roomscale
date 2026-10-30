#!/usr/bin/env python3
"""Build a reproducible inventory of RoomScale's visible 3D art sources.

The scan joins RoomDefinitions, both visual registries, material definitions,
scene files, and runtime GDScript geometry builders. Human-authored assessment
rules describe impact and production method; generated counts and source paths
come from the repository so coverage can be refreshed after each batch.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
ROOM_PATTERNS = ("rooms/**/*.json", "verification/poc2/candidates/**/*.json")
MESH_TOKENS = (
    "MeshInstance3D.new()",
    "BoxMesh.new()",
    "SphereMesh.new()",
    "CylinderMesh.new()",
    "CapsuleMesh.new()",
    "SurfaceTool.new()",
    "ArrayMesh.new()",
    "MultiMeshInstance3D.new()",
    "ImmediateMesh.new()",
    "CSGBox3D.new()",
)
TIER_ORDER = {"Tier 1 — Scene-defining": 1, "Tier 2 — Civilization-defining": 2,
              "Tier 3 — Supporting": 3, "Tier 4 — Low-visibility": 4}

SHELL_RULES: dict[str, dict[str, Any]] = {
    "room_shell_floor": {
        "semantic_identity": "room.shell.floor",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — defines the playable human-room surface",
        "visual_prominence": "dominant — spans nearly the full room footprint",
        "approx_screen_space_importance": "very high; room floor is a major plane in every overview",
        "current_visual_quality": "procedural plank shader now adds board joints and grain; the integrated overview still reads as a broad, lightly varied plane without source-matched PBR response",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "Room-scale seamless PBR material authored as a bounded Art Factory candidate; preserve RoomDefinition extents and floor height",
        "backlog_status": "scene-foundation material work; production backlog carries floor/material presentation follow-up",
    },
    "room_shell_wall_finish": {
        "semantic_identity": "room.shell.wall_finish",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — establishes room identity and scale",
        "visual_prominence": "dominant — continuous wall planes frame the normal camera",
        "approx_screen_space_importance": "very high; walls and windows dominate overview framing",
        "current_visual_quality": "large flat color fields with box-segment construction; paint lacks a dedicated textured finish",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "RoomDefinition-driven modular wall finish and source-matched PBR material; keep openings and wall dimensions authoritative",
        "backlog_status": "scene-foundation architecture/material work",
    },
    "room_shell_ceiling": {
        "semantic_identity": "room.shell.ceiling",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "medium — room enclosure and lighting context",
        "visual_prominence": "high in cutaway and reconstructed-room views; hidden in some normal cameras",
        "approx_screen_space_importance": "high in overhead/cutaway views; low when camera is below the ceiling",
        "current_visual_quality": "single broad colored surface or omitted in legacy RoomDefinitions",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "RoomDefinition-driven surface/material reuse, with visibility tested across cutaway and standard cameras",
        "backlog_status": "scene-foundation architecture work",
    },
    "room_shell_trim": {
        "semantic_identity": "room.shell.trim",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "low — presentation only",
        "visual_prominence": "medium; repeated along room perimeter",
        "approx_screen_space_importance": "low-to-medium depending on camera distance",
        "current_visual_quality": "repeated cuboid baseboard/crown sections with basic wood shading",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "Reusable trim profile and shared wood material; retain RoomDefinition dimensions",
        "backlog_status": "scene-foundation architecture work",
    },
    "room_shell_openings": {
        "semantic_identity": "room.shell.openings",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "medium — room identity and camera/light context",
        "visual_prominence": "high; windows and doors are high-contrast architectural anchors",
        "approx_screen_space_importance": "high for reconstructed rooms with large openings",
        "current_visual_quality": "procedural frames, muntins, glass panels, and simple exterior cards",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "Source-matched modular window/door components and physically credible glass; preserve opening dimensions",
        "backlog_status": "scene-foundation architecture work",
    },
}

SYSTEM_RULES: dict[str, dict[str, Any]] = {
    "clockwork_citizen": {
        "semantic_identity": "civilization.clockwork.citizen",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — repeated living population and civilization read",
        "visual_prominence": "high in settlement views; repeated 50 times at miniature scale",
        "approx_screen_space_importance": "high in population/settlement cameras; small per figure at room overview",
        "current_visual_quality": "MPFB2 anatomical rig and workwear are best-current review art; strict visual result remains continue",
        "programmer_art_or_primitive": False,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reuse current MPFB2 anatomy/rig and fitted role-workwear; prioritize broad role coverage, animation and LOD rather than restarting a citizen-only loop",
        "backlog_status": "citizen role readability, animation, variation, and cost remain in production-art backlog",
    },
    "verdant_citizen": {
        "semantic_identity": "civilization.verdant.citizen",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — repeated living population and faction identity",
        "visual_prominence": "high in settlement views; repeated population asset",
        "approx_screen_space_importance": "high in population/settlement cameras; small per figure at room overview",
        "current_visual_quality": "review-only MPFB2 anatomical body/rig with faction-colored workwear, leaf mantle, and cap; the production render still reads as generic workwear with weak botanical role identity",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reuse the rigged human foundation with Verdant-specific workwear and botanical equipment as a faction variant",
        "backlog_status": "Verdant role/faction visual coverage needs production inventory and batch treatment",
    },
    "clockwork_settlement": {
        "semantic_identity": "civilization.clockwork.settlement",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — settlement structures communicate the miniature civilization",
        "visual_prominence": "high in settlement views; multiple structures repeat in each room",
        "approx_screen_space_importance": "high in settlement views; moderate in room overview",
        "current_visual_quality": "modular timber/iron/copper Art Factory buildings with meaningful detail; broad room ground and context remain sparse",
        "programmer_art_or_primitive": False,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reuse and batch-coordinate existing accepted settlement building family; prioritize shared materials and contextual ground/infrastructure",
        "backlog_status": "architecture finish, context, lighting, and whole-set coherence remain in backlog",
    },
    "verdant_settlement": {
        "semantic_identity": "civilization.verdant.settlement",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "high — faction identity and living infrastructure",
        "visual_prominence": "medium-to-high in Verdant settlement views",
        "approx_screen_space_importance": "medium; repeated low buildings, vines, and vegetation",
        "current_visual_quality": "runtime-built root deck and branching nursery canopy with leaf cards, pods, vines, moss, and labels; the nursery is more structured but foliage remains visibly flat and supporting architecture remains primitive",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Blender-authored modular organic structures and reusable instanced foliage/materials, fitted to existing sites",
        "backlog_status": "Verdant architecture and material treatment are a major production batch",
    },
    "scavenger_citizen": {
        "semantic_identity": "civilization.scavenger.citizen",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — repeated living population and faction identity",
        "visual_prominence": "high across settlement and citizen views; 50 figures repeat",
        "approx_screen_space_importance": "small per figure at room overview; medium in settlement and close inspection views",
        "current_visual_quality": "review-only MPFB2 anatomical body/rig with salvage-color workwear, cap, patches, and belt details; at close range the silhouette still reads as generic workwear rather than a distinctive scavenger role",
        "programmer_art_or_primitive": False,
        "photo_resemblance_required": False,
        "recommended_production_method": "Keep the shared review-only anatomy/rig as a reference; author a coherent fitted salvage coat, cap, straps, gloves, boots, and role equipment as a bounded faction kit; do not promote the review adapter",
        "backlog_status": "role identity and modular salvage-workwear geometry remain production-art follow-up",
    },
    "scavenger_settlement": {
        "semantic_identity": "civilization.scavenger.settlement",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "high — structures establish the civilization's settlement identity",
        "visual_prominence": "high at settlement scale; several structures repeat in the active room",
        "approx_screen_space_importance": "medium at room overview; high in settlement inspection views",
        "current_visual_quality": "reuses the accepted Clockwork building family with presentation-only scrap roof and side panels; the set is coherent and game geometry is preserved, but the cladding remains simple and faction character is modest",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Build a cohesive salvage-material kit that fits the existing modular building surfaces; retain authoritative site dimensions and gameplay structures",
        "backlog_status": "Scavenger building identity, layered salvage materials, and attachment quality need a later bounded architecture batch",
    },
    "traversal_machinery": {
        "semantic_identity": "traversal.grapple_system",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "high — traversal deployment and climbing affordance",
        "visual_prominence": "high when deployed; equipment and cable recur across gameplay",
        "approx_screen_space_importance": "medium in overview; high in traversal close views",
        "current_visual_quality": "integrated articulated grapple asset; strict close-workmanship result remains failure; cables and anchors partly procedural",
        "programmer_art_or_primitive": False,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reuse current grapple mechanics and candidate; batch-build consistent cable/anchor/fixing presentation without changing traversal geometry",
        "backlog_status": "close workmanship and route/cable context remain in production-art backlog",
    },
    "construction_visuals": {
        "semantic_identity": "civilization.construction_visuals",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "high — construction progress and citizen activity are primary feedback",
        "visual_prominence": "medium-to-high during build events",
        "approx_screen_space_importance": "medium; transient, concentrated around settlement sites",
        "current_visual_quality": "procedural component boxes/cylinders, blueprint planes, particle/glow accents, and progress markers",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reusable authored construction kit and stage-specific material/assembly variants",
        "backlog_status": "construction equipment and materials need a cohesive production pass",
    },
    "resource_and_tool_visuals": {
        "semantic_identity": "civilization.resources_and_tools",
        "priority_tier": "Tier 2 — Civilization-defining",
        "gameplay_importance": "medium-to-high — repeated cargo and work tools communicate behavior",
        "visual_prominence": "medium; high during hauling/work interactions",
        "approx_screen_space_importance": "low at room overview, medium in settlement/citizen views",
        "current_visual_quality": "small box, cylinder, badge, and simple tool geometry assembled at runtime",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Reusable shared semantic prop set with instance variation and material-family consistency",
        "backlog_status": "resource items, cargo, tools, and storage detail require batch coverage",
    },
    "lighting_and_environment": {
        "semantic_identity": "room.presentation.lighting",
        "priority_tier": "Tier 1 — Scene-defining",
        "gameplay_importance": "medium — defines legibility, material response, and room scale",
        "visual_prominence": "dominant influence across every rendered asset",
        "approx_screen_space_importance": "whole-frame effect",
        "current_visual_quality": "single directional key, broad omni fill, ambient color, and small boiler light; AO and reflections are not consistently present",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": True,
        "recommended_production_method": "Bounded Godot environment/material tuning against matched production views, only where it improves the integrated scene",
        "backlog_status": "lighting, glass handling, shadow/AO quality, and contrast remain in production-art backlog",
    },
    "interaction_and_hud_markers": {
        "semantic_identity": "room.presentation.interaction_markers",
        "priority_tier": "Tier 3 — Supporting",
        "gameplay_importance": "medium — selection, destination, and construction feedback",
        "visual_prominence": "medium in active interactions; low otherwise",
        "approx_screen_space_importance": "small screen-space footprint but repeated overlays",
        "current_visual_quality": "flat outline boxes, translucent planes, bars, and labels",
        "programmer_art_or_primitive": True,
        "photo_resemblance_required": False,
        "recommended_production_method": "Shared style/material treatment for outlines, route indicators, blueprints, badges, and labels",
        "backlog_status": "supporting presentation pass after scene-defining coverage",
    },
}


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def load_json(path: Path, default: Any = None) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default


def slug(value: str) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value).strip("_")
    return value or "unnamed"


def room_definitions() -> list[dict[str, Any]]:
    found: dict[str, dict[str, Any]] = {}
    for pattern in ROOM_PATTERNS:
        for path in sorted(ROOT.glob(pattern)):
            data = load_json(path)
            if not isinstance(data, dict) or not {"id", "dimensions", "floor", "objects"}.issubset(data):
                continue
            path_text = rel(path)
            scope = "playable room" if path.parent == ROOT / "rooms" and data["id"] in {"room_a", "room_b"} else "RoomDefinition candidate or scenario"
            found[path_text] = {"path": path_text, "id": data["id"], "scope": scope, "data": data}
    return list(found.values())


def art_context() -> dict[str, Any]:
    production = load_json(ROOT / "art/registry.json", {}) or {}
    review = load_json(ROOT / "verification/poc25/final/best-current-art-showcase-registry-v089.json", {}) or {}
    catalog = load_json(ROOT / "visual/catalog.json", {}) or {}
    materials = load_json(ROOT / "visual/materials.json", {}) or {}
    art_briefs = {p.parent.name for p in (ROOT / "art").glob("*/brief.json")}
    registry_entries = production.get("entries", {}) if isinstance(production, dict) else {}
    review_entries = review.get("entries", {}) if isinstance(review, dict) else {}
    return {
        "production_registry": registry_entries,
        "review_registry": review_entries,
        "catalog": catalog.get("entries", {}) if isinstance(catalog, dict) else {},
        "catalog_defaults": catalog.get("defaults", {}) if isinstance(catalog, dict) else {},
        "materials": materials if isinstance(materials, dict) else {},
        "art_briefs": art_briefs,
        "strict_incumbent_audit": load_json(ROOT / "verification/poc25/final/strict-incumbent-visual-gate-reaudit.json", {}) or {},
    }


def kind_family(kind: str, name: str) -> tuple[str, str]:
    k = kind.lower().replace("-", "_")
    n = name.lower()
    if k == "settlement":
        normalized = slug(name)
        aliases = {"work_area": "workarea", "workarea": "workarea"}
        return "civilization structure", "settlement_" + aliases.get(normalized, normalized)
    if any(word in k or word in n for word in ("desk", "table", "chair", "stool", "bench", "bookcase", "wardrobe", "cabinet", "rug", "sofa", "hammock", "fireplace", "lamp", "cushion", "blanket", "artwork", "map", "monitor", "laptop", "computer", "box", "bin", "plant", "mat", "decoration")):
        existing = slug(n)
        aliases = {
            "desk": "desk", "office_desk": "desk", "computer_desk": "desk",
            "office_chair": "office_chair", "rocking_chair": "rocking_chair",
            "display_cabinet": "display_cabinet", "hammock_with_stand": "hammock_with_stand",
            "hammock": "hammock_with_stand", "rug": "rug", "bookcase": "bookcase",
            "wardrobe": "wardrobe", "workbench": "workbench", "stool": "stool",
        }
        return "human-room furniture and props", aliases.get(existing, "room_" + existing)
    if k in {"food_cache", "water_container", "storage_bin", "resource", "resource_node"}:
        return "resource and storage prop", "room_" + slug(name or kind)
    if k in {"wall_art", "wall art", "framed_artwork", "framed artwork", "wall_decoration", "wall decoration"}:
        return "room decoration", "room_" + slug(name or kind)
    return "room object", "room_" + slug(name or kind)


def current_asset_state(asset_id: str, context: dict[str, Any]) -> dict[str, Any]:
    production = context["production_registry"].get(asset_id, {})
    review = context["review_registry"].get(asset_id, {})
    has_brief = asset_id in context["art_briefs"]
    exists = has_brief or bool(production) or bool(review)
    candidate_id = str(review.get("candidate_id") or production.get("candidate_id") or "")
    status = "best_current_review" if review else str(production.get("status", "not registered"))
    evaluation: dict[str, Any] = {}
    candidate_match = re.search(r"-v(\d+)$", candidate_id)
    evaluation_path: Path | None = None
    if candidate_match:
        evaluation_path = ROOT / "art" / asset_id / "iterations" / f"v{int(candidate_match.group(1)):03d}" / "evaluation.json"
        evaluation = load_json(evaluation_path, {}) or {}
    strict_result = None
    strict_evidence_path = None
    for pilot in (context.get("strict_incumbent_audit", {}).get("pilots", {}) or {}).values():
        if str(pilot.get("candidate_id", "")) == candidate_id:
            strict_result = str(pilot.get("strict_gate_result", "")).lower() or None
            strict_evidence_path = "verification/poc25/final/strict-incumbent-visual-gate-reaudit.json"
            break
    if strict_result is None and review:
        strict_result = str(review.get("strict_pilot_gate_status", "")).split(" — ")[0].lower() or None
    return {
        "art_factory_id_exists": exists,
        "runtime_registry_active": bool(production) or bool(review),
        "existing_art_factory_id": asset_id if exists else None,
        "production_registry_status": str(production.get("status", "not registered")),
        "review_registry_status": status if review else "not in review registry",
        "best_current_candidate": candidate_id or None,
        "strict_evaluation_decision": evaluation.get("decision"),
        "strict_evaluation_path": rel(evaluation_path) if evaluation_path is not None and evaluation_path.exists() else None,
        "strict_gate_result": strict_result,
        "strict_gate_evidence_path": strict_evidence_path,
    }


def resolve_room_object_visual(obj: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    """Mirror VisualResolver's semantic/catalog/registry selection for inventory evidence."""
    appearance = obj.get("appearance", {})
    appearance = appearance if isinstance(appearance, dict) else {}
    semantic = str(obj.get("kind") or "unknown").lower()
    archetype = str(appearance.get("archetype", semantic)).lower()
    catalog = context["catalog"]
    recipe = dict(context.get("catalog_defaults", {}))
    recipe.update(catalog.get(archetype, catalog.get(semantic, {})))
    runtime_asset_id = str(appearance.get("asset_id", semantic)).lower()
    state = current_asset_state(runtime_asset_id, context)
    if state["runtime_registry_active"]:
        production = context["production_registry"].get(runtime_asset_id, {})
        review = context["review_registry"].get(runtime_asset_id, {})
        registered_path = review.get("path") or production.get("path")
        return {
            "runtime_semantic_id": semantic,
            "runtime_catalog_id": archetype,
            "runtime_art_factory_asset_id": runtime_asset_id,
            "runtime_art_factory_registry_active": True,
            "runtime_source": registered_path,
            "runtime_source_type": "Art Factory registry asset",
            "catalog_asset": recipe.get("asset"),
            "catalog_fallback": recipe.get("fallback"),
            "strict_gate_result": state["strict_gate_result"],
        }
    return {
        "runtime_semantic_id": semantic,
        "runtime_catalog_id": archetype,
        "runtime_art_factory_asset_id": runtime_asset_id,
        "runtime_art_factory_registry_active": False,
        "runtime_source": recipe.get("asset") or recipe.get("fallback") or "procedural_fallback",
        "runtime_source_type": "catalog import" if recipe.get("asset") else ("catalog detailed_furniture fallback" if recipe.get("fallback") == "detailed_furniture" else "procedural fallback"),
        "catalog_asset": recipe.get("asset"),
        "catalog_fallback": recipe.get("fallback"),
        "strict_gate_result": state["strict_gate_result"],
    }


def relevant_geometry_sources(sources_by_role: dict[str, list[dict[str, Any]]], category: str, display_name: str) -> list[str]:
    name = display_name.lower()
    role_terms: list[str]
    if category == "human-room furniture and props":
        role_terms = ["room shell, room-object fallback"]
    elif category == "civilization structure":
        role_terms = ["procedural settlement geometry", "room shell, room-object fallback"]
    elif "citizen" in name:
        role_terms = ["citizen cargo", "verdant citizens", "citizen authored model"]
    elif "settlement" in name or "workshop" in name or "housing" in name or "depot" in name:
        role_terms = ["procedural settlement geometry", "verdant citizens"]
    elif "traversal" in name or "grapple" in name:
        role_terms = ["traversal machinery"]
    elif "construction" in name or "resource" in name:
        role_terms = ["construction sites", "citizen cargo"]
    elif "lighting" in name or "interaction" in name:
        role_terms = ["room shell, room-object fallback", "Verdant citizens"]
    else:
        role_terms = ["room shell, room-object fallback"]
    selected = [record["path"] for role, records in sources_by_role.items() if any(term in role for term in role_terms) for record in records]
    return sorted(set(selected))


def code_visual_sources() -> tuple[list[dict[str, Any]], dict[str, list[dict[str, Any]]]]:
    source_index: list[dict[str, Any]] = []
    files_by_role: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in sorted((ROOT / "scripts").rglob("*.gd")):
        if path.stem.endswith("_test") or "tests" in path.parts:
            continue
        if "art_factory" in path.relative_to(ROOT / "scripts").parts:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        tokens = [token for token in MESH_TOKENS if token in text]
        if not tokens:
            continue
        functions = []
        current = "module_scope"
        for number, line in enumerate(text.splitlines(), 1):
            match = re.match(r"\s*(?:static\s+)?func\s+([A-Za-z0-9_]+)", line)
            if match:
                current = match.group(1)
            if any(token in line for token in MESH_TOKENS):
                functions.append({"function": current, "line": number, "constructors": [t for t in MESH_TOKENS if t in line]})
        record = {"path": rel(path), "constructors": tokens, "geometry_builder_sites": functions}
        source_index.append(record)
        name = path.name.lower()
        role = "runtime presentation geometry"
        if "pipeline_proof" in name:
            role = "room shell, room-object fallback, openings, lighting, and presentation"
        elif "civilization_presentation" in name or "civilization_visual" in name:
            role = "Verdant citizens, structures, vines, vegetation, effects, and markers"
        elif "citizen_agent" in name:
            role = "citizen cargo, badges, and fallback body geometry"
        elif "construction" in name:
            role = "construction sites, stages, tools, and progress geometry"
        elif "settlement" in name:
            role = "procedural settlement geometry"
        elif "grapple" in name:
            role = "traversal machinery and cable geometry"
        files_by_role[role].append({"path": rel(path), "site_count": len(functions), "constructors": tokens})
    # These runtime adapters integrate authored scenes or material assets rather
    # than constructing geometry inline, so include them as presentation sources.
    adapters = {
        "scripts/visuals/visual_resolver.gd": "semantic asset resolution and Art Factory integration",
        "scripts/visuals/asset_registry.gd": "semantic asset resolution and Art Factory integration",
        "scripts/visuals/citizen_art_adapter.gd": "Clockwork citizen authored model adapter",
        "scripts/visuals/material_library.gd": "shared runtime materials and textures",
        "scripts/visuals/settlement_details.gd": "settlement authored model integration and details",
    }
    for relative, role in adapters.items():
        path = ROOT / relative
        if path.exists() and all(record["path"] != relative for records in files_by_role.values() for record in records):
            files_by_role[role].append({"path": relative, "site_count": 0, "constructors": [], "source_kind": "runtime adapter/material integration"})
    return source_index, files_by_role


def inventory_rows(definitions: list[dict[str, Any]], context: dict[str, Any], sources_by_role: dict[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    groups: dict[tuple[str, str], dict[str, Any]] = {}
    for definition in definitions:
        data = definition["data"]
        room_id = str(data["id"])
        for obj in data.get("objects", []):
            if not isinstance(obj, dict):
                continue
            name = str(obj.get("name") or obj.get("id") or obj.get("kind") or "Unnamed object")
            kind = str(obj.get("kind") or "unknown")
            family, asset_id = kind_family(kind, name)
            key = (family, slug(name))
            row = groups.setdefault(key, {"name": name, "kind": kind, "family": family, "assigned_asset_factory_id": asset_id,
                                          "room_examples": [], "source_paths": set(), "photo_rooms": set(),
                                          "runtime_resolutions": [], "runtime_semantic_ids": set(), "runtime_art_factory_ids": set(),
                                          "active_instances": 0, "all_definition_occurrences": 0,
                                          "max_dimensions": [0.0, 0.0, 0.0], "gameplay_flags": set()})
            row["source_paths"].add(definition["path"])
            resolution = resolve_room_object_visual(obj, context)
            row["runtime_semantic_ids"].add(resolution["runtime_semantic_id"])
            row.setdefault("runtime_catalog_ids", set()).add(resolution["runtime_catalog_id"])
            row["runtime_art_factory_ids"].add(resolution["runtime_art_factory_asset_id"])
            if resolution not in row["runtime_resolutions"]:
                row["runtime_resolutions"].append(resolution)
            occurrence = {"room_id": room_id, "room_definition": definition["path"], "object_id": str(obj.get("id", "")),
                          "kind": kind, "dimensions": obj.get("dimensions"), "blocks_navigation": bool(obj.get("blocks_navigation", False)),
                          "has_surface": isinstance(obj.get("surface"), dict), "runtime_visual_resolution": resolution}
            if occurrence not in row["room_examples"]:
                row["room_examples"].append(occurrence)
                row["all_definition_occurrences"] += 1
            if definition["scope"] == "playable room":
                row["active_instances"] += 1
            if "photo" in room_id or room_id == "room_hearth_living_room":
                row["photo_rooms"].add(room_id)
            dimensions = obj.get("dimensions", [])
            if isinstance(dimensions, list) and len(dimensions) == 3:
                row["max_dimensions"] = [max(float(a), float(b)) for a, b in zip(row["max_dimensions"], dimensions)]
            if obj.get("blocks_navigation"):
                row["gameplay_flags"].add("navigation footprint stored in RoomDefinition")
            if isinstance(obj.get("surface"), dict):
                row["gameplay_flags"].add("goal-surface ID/anchor stored in RoomDefinition")

    rows: list[dict[str, Any]] = []
    for group in groups.values():
        asset_id = group["assigned_asset_factory_id"]
        state = current_asset_state(asset_id, context)
        catalog_id_exists = asset_id in context["catalog"]
        name = group["name"]
        family = group["family"]
        tier = "Tier 2 — Civilization-defining" if family in {"civilization structure", "resource and storage prop"} else "Tier 3 — Supporting"
        importance = "medium — contributes to room scale, identity, or active play"
        prominence = "medium; depends on room layout and camera"
        screen = "medium; multiple authored rooms place this class in normal gameplay views"
        resolutions = group["runtime_resolutions"]
        active_resolutions = [entry for entry in resolutions if entry["runtime_art_factory_registry_active"]]
        if any(entry["runtime_source_type"] == "procedural fallback" for entry in resolutions):
            primitive: bool | None = True
        elif any(entry.get("strict_gate_result") == "fail" for entry in active_resolutions):
            primitive = True
        elif active_resolutions and all(entry.get("strict_gate_result") == "pass" for entry in active_resolutions):
            primitive = False
        else:
            primitive = None
        quality = "Runtime source is listed below; no strict asset evaluation is attached to this room-object instance."
        method = "reuse an appropriate shared semantic asset where possible; otherwise create a bounded Art Factory candidate for this class"
        if family == "civilization structure":
            tier, importance, prominence, screen = "Tier 1 — Scene-defining", "high — core civilization landmark", "high in settlement view; repeated per room", "medium-to-high in settlement views"
            quality = "Settlement asset sources and current strict gate state are linked below; presentation may use Art Factory assets or runtime fallbacks."
            method = "reuse the matching accepted Art Factory building and shared family materials"
        elif family == "human-room furniture and props":
            major_tokens = ("desk", "table", "bed", "sofa", "couch", "chair", "bookcase", "shelving", "wardrobe", "cabinet", "fireplace", "hammock", "workbench", "piano")
            max_extent = max(group["max_dimensions"], default=0.0)
            if any(token in name.lower() for token in major_tokens) and max_extent >= 14.0:
                tier, importance, prominence = "Tier 1 — Scene-defining", "high — recognizable large human-room object", "high in room and inspection views"
                screen = "high for large furniture; dimensions and runtime source are listed"
            else:
                tier, importance, prominence = "Tier 3 — Supporting", "low-to-medium — room richness or active-play context", "low-to-medium; size and placement dependent"
                screen = "small or secondary in room overview; assess at close/context view"
            quality = "Mixed runtime sources; active resolution, Art Factory assignment, and strict status are reported separately below."
            method = "reuse shared quality furniture where it fits; use source-conditioned Art Factory production for distinctive photographed objects"
        elif name.lower() in {"food cache", "water container", "staging crate", "storage box", "storage bin"}:
            tier, importance = "Tier 2 — Civilization-defining", "medium — visible cargo/storage in work interactions"
            prominence, screen = "medium during work/hauling", "low-to-medium at room overview; medium at settlement scale"
            method = "shared modular container/resource-prop kit with material variants"
        source_paths = sorted(group["source_paths"])
        rows.append({
            "semantic_identity": f"{family.replace(' ', '_')}.{slug(name)}",
            "asset_factory_id": asset_id,
            "art_factory_id_exists_before_deployment": state["art_factory_id_exists"],
            "assigned_visual_catalog_id_exists": catalog_id_exists,
            "runtime_visual_catalog_ids": sorted(group["runtime_catalog_ids"]),
            "runtime_visual_catalog_id_exists": any(identifier in context["catalog"] for identifier in group["runtime_catalog_ids"]),
            "assigned_or_reused_asset_factory_id": asset_id,
            "category": family,
            "display_name": name,
            "room_definition_kind": group["kind"],
            "source_paths": source_paths,
            "room_instances": group["room_examples"],
            "runtime_semantic_ids": sorted(group["runtime_semantic_ids"]),
            "runtime_catalog_ids": sorted(group["runtime_catalog_ids"]),
            "runtime_art_factory_ids": sorted(group["runtime_art_factory_ids"]),
            "runtime_visual_resolutions": resolutions,
            "active_room_definition_instances": group["active_instances"],
            "definition_occurrences_across_playable_and_candidate_rooms": group["all_definition_occurrences"],
            "max_dimensions_inches_xyz": group["max_dimensions"],
            "gameplay_importance": importance,
            "visual_prominence": prominence,
            "approx_screen_space_importance": screen,
            "repetition_frequency": {"playable_room_instances": group["active_instances"], "room_definition_examples": group["all_definition_occurrences"]},
            "current_visual_quality": quality,
            "programmer_art_or_primitive": primitive,
            "programmer_art_assessment_basis": "runtime procedural fallback or strict visual gate failure" if primitive is True else ("strict visual gate PASS" if primitive is False else "unknown; assigned Art Factory identity alone is not treated as evidence"),
            "source_photo_resemblance_requirement": bool(group["photo_rooms"]),
            "photo_room_examples": sorted(group["photo_rooms"]),
            "gameplay_geometry_coupling": "; ".join(sorted(group["gameplay_flags"])) or "presentation transform is fitted under RoomDefinition-owned placement and dimensions; collision/navigation remain separate",
            "canonical_registry_status": state["production_registry_status"],
            "assigned_candidate_strict_gate_result": state["strict_gate_result"],
            "assigned_candidate_legacy_evaluation_decision": state["strict_evaluation_decision"],
            "best_current_candidate": state["best_current_candidate"],
            "strict_evaluation_path": state["strict_evaluation_path"],
            "production_art_backlog_status": "covered by production-art backlog" if slug(name) in (ROOT / "verification/poc25/PRODUCTION_ART_BACKLOG.md").read_text(encoding="utf-8").lower() else "not individually named in current backlog; assess by tier during batch planning",
            "recommended_production_method": method,
            "priority_tier": tier,
            "linked_runtime_geometry_sources": relevant_geometry_sources(sources_by_role, family, name),
        })

    for key, rule in SHELL_RULES.items():
        state = current_asset_state(key, context)
        rows.append({
            **rule,
            "asset_factory_id": key,
            "art_factory_id_exists_before_deployment": state["art_factory_id_exists"],
            "existing_visual_catalog_id_exists": key in context["catalog"],
            "assigned_or_reused_asset_factory_id": key,
            "category": "room shell / architecture",
            "display_name": key.removeprefix("room_shell_").replace("_", " ").title(),
            "source_paths": ["scripts/pipeline_proof.gd", "scripts/room_definition.gd", "visual/materials.json", "visual/floor_wood.gdshader"],
            "room_instances": [{"scope": "RoomDefinition room shell", "room_count": len(definitions)}],
            "active_room_definition_instances": len([d for d in definitions if d["scope"] == "playable room"]),
            "definition_occurrences_across_playable_and_candidate_rooms": len(definitions),
            "max_dimensions_inches_xyz": None,
            "repetition_frequency": {"playable_rooms": len([d for d in definitions if d["scope"] == "playable room"]), "room_definition_examples": len(definitions)},
            "photo_room_examples": sorted({d["id"] for d in definitions if "photo" in d["id"]}),
            "gameplay_geometry_coupling": "RoomDefinition owns shell/floor extents, wall dimensions, opening locations, trim, and camera cutaway semantics; material/mesh changes must not alter them",
            "canonical_registry_status": state["production_registry_status"],
            "best_current_candidate": state["best_current_candidate"],
            "strict_evaluation_path": state["strict_evaluation_path"],
            "existing_visual_catalog_id_exists": False,
            "production_art_backlog_status": rule["backlog_status"],
            "linked_runtime_geometry_sources": ["scripts/pipeline_proof.gd", "scripts/visuals/material_library.gd"],
        })

    system_asset_links = {
        "clockwork_citizen": ["citizen"],
        "verdant_citizen": [],
        "clockwork_settlement": ["settlement_workshop", "settlement_housing", "settlement_depot", "settlement_workarea"],
        "verdant_settlement": [],
        "traversal_machinery": ["grapple"],
        "construction_visuals": [],
        "resource_and_tool_visuals": [],
        "lighting_and_environment": [],
        "interaction_and_hud_markers": [],
    }
    for key, rule in SYSTEM_RULES.items():
        state = current_asset_state(key, context)
        linked_asset_ids = system_asset_links.get(key, [key] if state["runtime_registry_active"] else [])
        linked_states = {asset_id: current_asset_state(asset_id, context) for asset_id in linked_asset_ids}
        linked_sources = sorted({source for asset_id in linked_asset_ids for source in [str((context["review_registry"].get(asset_id, {}) or context["production_registry"].get(asset_id, {})).get("path", ""))] if source})
        linked_candidates = {asset_id: linked_state["best_current_candidate"] for asset_id, linked_state in linked_states.items() if linked_state["best_current_candidate"]}
        rows.append({
            **rule,
            "asset_factory_id": key,
            "art_factory_id_exists_before_deployment": state["art_factory_id_exists"] or any(entry["art_factory_id_exists"] for entry in linked_states.values()),
            "existing_visual_catalog_id_exists": key in context["catalog"],
            "assigned_or_reused_asset_factory_id": key,
            "category": "runtime-generated presentation system",
            "display_name": key.replace("_", " ").title(),
            "source_paths": relevant_geometry_sources(sources_by_role, "runtime presentation system", key) + linked_sources,
            "room_instances": [{"scope": "runtime-generated; see procedural source index", "room_count": len(definitions)}],
            "active_room_definition_instances": None,
            "definition_occurrences_across_playable_and_candidate_rooms": len(definitions),
            "max_dimensions_inches_xyz": None,
            "repetition_frequency": {"runtime": "population and activity dependent"},
            "source_photo_resemblance_requirement": False,
            "photo_room_examples": [],
            "gameplay_geometry_coupling": "presentation-only geometry/materials; gameplay logic and collision are constructed by separate systems",
            "canonical_registry_status": state["production_registry_status"] if state["art_factory_id_exists"] else ("linked Art Factory asset family" if linked_asset_ids else "not registered as one visual asset"),
            "linked_art_factory_ids": linked_asset_ids,
            "linked_art_factory_registry_state": linked_states,
            "best_current_candidate": state["best_current_candidate"] or linked_candidates or None,
            "strict_evaluation_path": state["strict_evaluation_path"],
            "strict_gate_result": state["strict_gate_result"] or ({asset_id: linked_state["strict_gate_result"] for asset_id, linked_state in linked_states.items()} if any(linked_state["strict_gate_result"] for linked_state in linked_states.values()) else None),
            "existing_visual_catalog_id_exists": key in context["catalog"],
            "production_art_backlog_status": rule["backlog_status"],
            "linked_runtime_geometry_sources": relevant_geometry_sources(sources_by_role, "runtime presentation system", key),
        })

    return sorted(rows, key=lambda row: (TIER_ORDER.get(row["priority_tier"], 4), row["category"], row["display_name"].lower()))


def build_inventory() -> dict[str, Any]:
    definitions = room_definitions()
    context = art_context()
    sources, sources_by_role = code_visual_sources()
    rows = inventory_rows(definitions, context, sources_by_role)
    scene_files = []
    scene_paths = sorted(set((ROOT / "scenes").rglob("*.tscn")) | set((ROOT / "assets").rglob("*.tscn")))
    visible_types = {"MeshInstance3D", "Sprite3D", "MultiMeshInstance3D", "CSGBox3D", "GPUParticles3D", "CPUParticles3D", "Label3D", "DirectionalLight3D", "OmniLight3D", "SpotLight3D"}
    presentation_scripts = {"scripts/pipeline_proof.gd", "scripts/visuals/visual_resolver.gd", "scripts/visuals/citizen_art_adapter.gd"}
    for path in scene_paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        node_types = re.findall(r"\[node\s+name=\"[^\"]+\"\s+type=\"([^\"]+)\"", text)
        scripts = re.findall(r'path="res://([^\"]+\.gd)"', text)
        if any(t in visible_types for t in node_types) or any(script in presentation_scripts for script in scripts):
            scene_files.append({"path": rel(path), "script_sources": scripts, "node_type_counts": {t: node_types.count(t) for t in sorted(set(node_types)) if t in visible_types}})
    active_room_defs = [d for d in definitions if d["scope"] == "playable room"]
    material_names = sorted(context["materials"].keys())
    registry_names = sorted(context["production_registry"].keys())
    coverage = {
        "room_definition_files_scanned": len(definitions),
        "playable_room_definition_files": [d["path"] for d in active_room_defs],
        "candidate_and_scenario_room_definition_files": len(definitions) - len(active_room_defs),
        "room_object_records_scanned": sum(len(d["data"].get("objects", [])) for d in definitions),
        "unique_room_object_classes": len({(str(o.get("kind", "unknown")), slug(str(o.get("name") or o.get("id") or "unnamed"))) for d in definitions for o in d["data"].get("objects", []) if isinstance(o, dict)}),
        "art_factory_production_registry_entries": len(registry_names),
        "art_factory_production_registry_ids": registry_names,
        "visual_catalog_entries": len(context["catalog"]),
        "material_categories": material_names,
        "runtime_scripts_with_primitive_or_dynamic_mesh_builders": len(sources),
        "runtime_geometry_builder_sites": sum(len(s["geometry_builder_sites"]) for s in sources),
        "runtime_presentation_sources_by_role": sources_by_role,
        "active_scenes_with_visible_art_or_runtime_presentation": len(scene_files),
        "active_scene_file_index": scene_files,
        "excluded_candidate_history_scenes": "art/**/iterations/** and verification/** scenes are candidate history/evidence rather than active production static scenes; currently active registry paths are recorded per asset class",
        "asset_class_rows": len(rows),
        "excluded": ["test-only scene copies and generated import cache files are scanned only where they define RoomDefinition input; they are not treated as independent production assets"],
    }
    return {
        "schema_version": 1,
        "title": "RoomScale Art Factory Production Deployment — Full Visible-Art Inventory",
        "source_commit": "1e111d37325e7ad00030266efec201796b7fc07d",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "inventory_scope": "Playable room definitions, reconstructed/candidate RoomDefinitions, canonical and review registries, visual/material catalogs, static scenes, and runtime code that creates visible geometry/material/light/presentation nodes.",
        "coverage": coverage,
        "room_definitions": [{"path": d["path"], "id": d["id"], "scope": d["scope"], "object_count": len(d["data"].get("objects", [])), "shell_wall_count": len(d["data"].get("room_shell", {}).get("walls", [])) if isinstance(d["data"].get("room_shell"), dict) else 0} for d in definitions],
        "procedural_geometry_sources": sources,
        "asset_classes": rows,
        "runtime_cross_check": {
            "closure_overview_capture": "verification/poc25/final/matched-visual-comparison/final-matched.png",
            "overview_assessment": "The room floor now has deterministic board joints and grain; the integrated room still reads as broad, lightly varied surfaces. Review renders show the current Verdant branch-and-leaf nursery and Scavenger salvage overlays over shared structures, while citizen faction identity and supporting architecture remain visibly unfinished.",
            "additional_view_evidence": ["verification/art_factory_production/batch-09/verdant-room-a/receipt.json", "verification/art_factory_production/batch-11/scavenger-room-a/receipt.json", "screenshots/room_a-initial-room.png", "screenshots/room_b-initial-room.png"],
            "limitation": "Static inventory enumerates source-defined asset classes and runtime builders; visually hidden/test-only candidates may not appear in the current camera. Production batches must keep rechecking representative camera views.",
        },
    }


def markdown_report(data: dict[str, Any]) -> str:
    cov = data["coverage"]
    lines = [
        "# RoomScale Full Visible-Art Inventory",
        "",
        f"Generated: `{data['generated_at_utc']}`",
        "",
        f"Starting state: POC 2.5 closure `{data['source_commit']}`",
        "Purpose: production prioritization only; no POC 2.5 reopening.",
        "",
        "## Automated coverage",
        "",
        f"- RoomDefinition files: {cov['room_definition_files_scanned']} ({len(cov['playable_room_definition_files'])} playable Room A/B; {cov['candidate_and_scenario_room_definition_files']} candidate/scenario variants).",
        f"- Room object records / unique object classes: {cov['room_object_records_scanned']} / {cov['unique_room_object_classes']}.",
        f"- Canonical Art Factory registry entries: {cov['art_factory_production_registry_entries']}; visual catalog entries: {cov['visual_catalog_entries']}; material categories: {len(cov['material_categories'])}.",
        f"- Runtime GDScript files with procedural/dynamic geometry: {cov['runtime_scripts_with_primitive_or_dynamic_mesh_builders']}; geometry builder sites: {cov['runtime_geometry_builder_sites']}.",
        f"- Active scenes with visible art nodes or a runtime presentation controller: {cov['active_scenes_with_visible_art_or_runtime_presentation']}.",
        f"- Catalogued asset classes and presentation systems: {cov['asset_class_rows']}.",
        "",
        "The inventory joins source-defined room content with the canonical/review asset registries and scans runtime GDScript geometry builders, so hardcoded and procedural visible art is included alongside registered models. See the adjacent JSON for full paths, occurrences, geometry code sites, and field-level records.",
        "",
        "## Priority and current coverage",
        "",
        "| Tier | Asset class | Instances/examples | Assigned ID and current runtime path | Current visual assessment | First production direction |",
        "|---|---|---:|---|---|---|",
    ]
    for row in data["asset_classes"]:
        assigned = str(row.get("assigned_or_reused_asset_factory_id", ""))
        assigned_text = f"`{assigned}` exists" if row.get("art_factory_id_exists_before_deployment") else f"planned `{assigned}`"
        resolutions = row.get("runtime_visual_resolutions", [])
        if resolutions:
            runtime = "; ".join(sorted({f"{entry['runtime_art_factory_asset_id']} → {entry['runtime_source_type']}" for entry in resolutions}))
        elif row.get("linked_art_factory_ids"):
            runtime = "linked " + ", ".join(f"`{asset_id}`" for asset_id in row["linked_art_factory_ids"])
        else:
            runtime = "runtime-built / shared presentation"
        exists = f"{assigned_text}; {runtime}"
        reps = row.get("active_room_definition_instances", row.get("definition_occurrences_across_playable_and_candidate_rooms", "runtime"))
        quality = str(row.get("current_visual_quality", ""))
        strict_status = row.get("assigned_candidate_strict_gate_result", row.get("strict_gate_result"))
        if strict_status:
            quality += f" Strict result: `{strict_status}`."
        method = str(row.get("recommended_production_method", ""))
        lines.append(f"| {row['priority_tier'].split(' — ')[0]} | `{row['asset_factory_id']}` — {row['display_name']} | {reps} | {exists} | {quality} | {method} |")
    lines += [
        "",
        "## Runtime cross-check",
        "",
        data["runtime_cross_check"]["overview_assessment"],
        "",
        f"Representative evidence: `{data['runtime_cross_check']['closure_overview_capture']}`, `{data['runtime_cross_check']['additional_view_evidence'][0]}`, and the Room A/B initial-room screenshots.",
        "",
        f"Coverage limitation: {data['runtime_cross_check']['limitation']}",
        "",
        "## Use",
        "",
        "Production batches should coordinate high-impact room surfaces and furniture with visible settlement architecture, all civilization citizen presentation, traversal, and shared lighting/material response. Continue across asset classes rather than polishing one asset indefinitely.",
        "",
        "The JSON is the source of truth for stable semantic identities and per-class fields. Re-run `python scripts/art_factory/visual_inventory.py` after a meaningful production batch to refresh automated coverage and occurrences.",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json-output", default="verification/art_factory_production/visual_inventory.json")
    parser.add_argument("--markdown-output", default="verification/art_factory_production/visual_inventory.md")
    args = parser.parse_args()
    data = build_inventory()
    json_path = ROOT / args.json_output
    md_path = ROOT / args.markdown_output
    json_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md_path.write_text(markdown_report(data), encoding="utf-8")
    print("ROOMSCALE_VISUAL_INVENTORY_PASS", json.dumps(data["coverage"], ensure_ascii=False))
    print(f"inventory_json={rel(json_path)}")
    print(f"inventory_markdown={rel(md_path)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
