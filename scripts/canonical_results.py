"""Compare complete canonical production receipts without host/capture metadata."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

FIELDS = (
    "result",
    "failure",
    "initial",
    "checks",
    "checkpoints",
    "status",
    "projects",
    "cohorts",
    "timeline",
    "sources",
    "salvage",
    "tasks",
    "events",
    "oldest_task_seconds",
    "oldest_project_seconds",
)


def fingerprint(result: dict) -> str:
    missing = set(FIELDS) - result.keys()
    if missing or result["result"] != "PASS":
        raise ValueError(f"Missing canonical fields or non-PASS result: {sorted(missing)}")
    data = {key: result[key] for key in FIELDS}
    return hashlib.sha256(
        json.dumps(data, sort_keys=True, ensure_ascii=False, allow_nan=False).encode("utf-8")
    ).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--run-count", type=int)
    args = parser.parse_args()
    if args.run_count is not None and args.run_count < 3:
        parser.error("Canonical repeatability requires at least three fresh receipts")
    paths = (
        [args.directory / f"repeat-{index:02}.json" for index in range(1, args.run_count + 1)]
        if args.run_count is not None
        else sorted(args.directory.glob("repeat-*.json"))
    )
    if len(paths) < 3:
        parser.error("Canonical repeatability requires at least three fresh receipts")
    fingerprints = {
        path.name: fingerprint(json.loads(path.read_text(encoding="utf-8-sig"))) for path in paths
    }
    identical = len(set(fingerprints.values())) == 1
    summary = {
        "identical": identical,
        "runs": len(paths),
        "fingerprints": fingerprints,
        "compared_fields": FIELDS,
        "excluded_metadata": ["captures", "wall_seconds"],
    }
    (args.directory / "determinism-summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print("ROOMSCALE_CANONICAL_DETERMINISM_" + ("PASS" if identical else "FAIL"))
    return int(not identical)


if __name__ == "__main__":
    raise SystemExit(main())
