"""Stable semantic identities for accepted render assets."""

from __future__ import annotations

import hashlib
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any

ASSET_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")


def validate_asset_id(asset_id: str) -> None:
    if not ASSET_ID_PATTERN.fullmatch(asset_id):
        raise ValueError(f"invalid stable asset id: {asset_id!r}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2, sort_keys=True)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


class AssetRegistry:
    """Maps stable semantic IDs to reversible, content-hashed accepted assets."""

    def __init__(self, project_root: Path, registry_path: Path | None = None) -> None:
        self.project_root = project_root.resolve()
        self.path = registry_path or self.project_root / "art" / "registry.json"

    def read(self) -> dict[str, Any]:
        if not self.path.exists():
            return {"schema_version": 1, "entries": {}}
        value = json.loads(self.path.read_text(encoding="utf-8"))
        if value.get("schema_version") != 1 or not isinstance(value.get("entries"), dict):
            raise ValueError(f"invalid Art Factory registry: {self.path}")
        for asset_id, entry in value["entries"].items():
            validate_asset_id(asset_id)
            if not isinstance(entry, dict) or entry.get("status") != "accepted":
                raise ValueError(f"registry entry {asset_id} is not an accepted asset")
            if not str(entry.get("path", "")).strip() or not str(entry.get("sha256", "")).strip():
                raise ValueError(f"registry entry {asset_id} needs a path and SHA-256")
        return value

    def resolve(self, asset_id: str) -> dict[str, Any] | None:
        validate_asset_id(asset_id)
        return self.read()["entries"].get(asset_id)

    def local_path(self, entry: dict[str, Any]) -> Path:
        relative = str(entry.get("path", ""))
        if relative.startswith(("/", "\\")) or ":" in relative:
            raise ValueError("registry asset paths must be project-relative")
        target = (self.project_root / Path(relative)).resolve()
        if not target.is_relative_to(self.project_root):
            raise ValueError("registry asset path escapes the project root")
        return target

    def verify(self, asset_id: str) -> tuple[bool, str]:
        entry = self.resolve(asset_id)
        if entry is None:
            return False, f"no accepted asset registered for {asset_id}"
        path = self.local_path(entry)
        if not path.is_file():
            return False, f"accepted asset is missing: {path}"
        actual = sha256_file(path)
        if actual != entry["sha256"]:
            return (
                False,
                f"accepted asset hash mismatch for {asset_id}: expected {entry['sha256']}, got {actual}",
            )
        return True, str(path)

    def accept(self, asset_id: str, entry: dict[str, Any]) -> None:
        validate_asset_id(asset_id)
        if entry.get("status") != "accepted":
            raise ValueError("only explicitly accepted candidates can enter the registry")
        self.local_path(entry)
        current = self.read()
        current["entries"][asset_id] = dict(entry)
        atomic_write_json(self.path, current)
