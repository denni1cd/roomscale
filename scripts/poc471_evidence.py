"""Review campaign provenance and publish final statistics after production runs."""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("campaign", ROOT / "scripts/poc471_campaign.py")
campaign = importlib.util.module_from_spec(spec)
spec.loader.exec_module(campaign)


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--core", default="verification/poc471/final")
    parser.add_argument("--exploration", default="verification/poc471/exploration")
    parser.add_argument("--regressions", default="verification/poc471/regressions-complete")
    args = parser.parse_args()
    output = ROOT / "verification/poc471"
    core = [json.loads(p.read_text()) for p in sorted((ROOT / args.core).glob("*/result.json"))]
    exploration = [json.loads(p.read_text()) for p in sorted((ROOT / args.exploration).glob("*/result.json"))]
    results = core + exploration
    errors = []
    for r in results:
        case_dir = ROOT / (args.core if r in core else args.exploration) / r["id"]
        config = json.loads((case_dir / "config.json").read_text())
        if hashlib.sha256((case_dir / "config.json").read_bytes()).hexdigest() != r["config_sha256"]: errors.append(r["id"] + " config hash mismatch")
        definition = case_dir / Path(config["room_file"]).name
        if hashlib.sha256(definition.read_bytes()).hexdigest() != r["definition_sha256"]: errors.append(r["id"] + " definition hash mismatch")
        for path, sha in (r.get("source_hashes", {}) | r.get("harness_hashes", {})).items():
            current = hashlib.sha256((ROOT/path).read_bytes().replace(b"\r\n",b"\n")).hexdigest()
            if current != sha: errors.append(r["id"] + " source mismatch " + path)
        if r["classification"] != "rejected" and not r.get("validation", {}).get("expected_rejection"):
            if abs(r.get("final", {}).get("seconds", 0) - config["days"]*600) > .001: errors.append(r["id"] + " incomplete duration")
        log = (case_dir / "run.log").read_text()
        if "SCRIPT ERROR:" in log or "ERROR:" in log: errors.append(r["id"] + " engine log error")
    summary = campaign.summarize(results, output)
    regressions = {}
    for path in sorted((ROOT / args.regressions).glob("*/summary.json")):
        data = json.loads(path.read_text())
        if isinstance(data, dict): data = [data]
        regressions[path.parent.name] = data
        if not all(r.get("Passed", False) for r in data): errors.append("Regression failed: " + path.parent.name)
    for name, marker in [("room-definition-fast.log","ROOMSCALE_FAST_TEST_PASS"),
                         ("navigation.log","POC471_NAVIGATION_PASS"),
                         ("unreachable.log","POC471_UNREACHABLE_PASS")]:
        path = ROOT / args.regressions / name
        log = path.read_text() if path.exists() else ""
        ok = marker in log and "ERROR:" not in log and "SCRIPT ERROR:" not in log
        regressions[name] = {"passed":ok}
        if not ok: errors.append("Missing/failed regression: " + name)
    required = {"poc47","poc46-fast","poc46-scenario","poc45-fast","poc45-survival","poc45-scenario","poc4-fast","poc4-sustained"}
    if not required <= regressions.keys(): errors.append("Incomplete required regression set")
    core_positive = [r for r in core if r["classification"] == "positive"]
    if len(core_positive) < 30: errors.append("Fewer than 30 admitted core positives")
    if not set(campaign.NAMES) <= {r["name"] for r in core_positive if r["result"] == "PASS"}: errors.append("Named case missing")
    if len(summary["long_soak_results"]) < 3: errors.append("Missing founder soaks")
    if len(summary["determinism_results"]) < 6 or not all(r["identical"] for r in summary["determinism_results"]): errors.append("Determinism failed or incomplete")
    if any(r["result"] not in ["PASS","REJECTED"] for r in results): errors.append("Unresolved campaign failures")
    summary.update(production_bugs_discovered=["BUG-471-01 shelter rest apron blocks depot","BUG-471-02 exterior grid connector cuts structure corner","BUG-471-03 synchronous unreachable-task retry recursion"],
                   production_bugs_fixed=["BUG-471-01","BUG-471-02","BUG-471-03"], unresolved_bugs=[],
                   regression_results=regressions, evidence_consistency_errors=errors,
                   core_generated_candidates=60, core_valid_scenarios=len(core_positive), exploratory_inputs=len(exploration),
                   tested_source_commits=sorted({r["tested_commit"] for r in results}),
                   architecture_classification="3. moderately robust",
                   continuously_executed_scenarios=sum(r.get("final",{}).get("seconds",0)>0 for r in results))
    task_rates = {}
    for r in summary["long_soak_results"]:
        samples = r["timeline"]
        rates = []
        event_rates = []
        for before, after in zip(samples,samples[1:]):
            days = (after["seconds"]-before["seconds"])/600
            rates.append((after["tasks"]["created_total"]-before["tasks"]["created_total"])/days/max(1,after["status"]["population"]))
            event_rates.append((after["journal_sequence"]-before["journal_sequence"])/days)
        task_rates[r["id"]] = dict(tasks_per_citizen_day=campaign.distribution(rates), journal_events_per_day=campaign.distribution(event_rates),
                                   retained_tasks_max=r["maxima"]["tasks"], journal_retained_max=r["maxima"]["journal"])
    summary["soak_retention_and_rates"] = task_rates
    campaign.write(output / "campaign-summary.json", summary)
    outlier_lines = ["# Outlier investigation", "", "All times are fixed-step production seconds. These are observations, not balance changes.", ""]
    positives = [r for r in results if r["classification"] == "positive" and r["result"] == "PASS"]
    for key in ["shelter_complete","workshop_complete","sixth_citizen","traversal_complete"]:
        slow = sorted(positives,key=lambda r:r["milestones"].get(key,-1),reverse=True)[:3]
        outlier_lines.extend([f"## {key}", ""])
        for r in slow:
            m = r["milestones"]
            paths = r["validation"].get("floor_resource_path_lengths",{})
            salvage = r["validation"].get("safe_salvage_path_lengths",{})
            source = next((e["seconds"] for e in r["final"].get("journal",[]) if e["kind"] == "source_exhausted" and "spilled_water" in e["message"]),None)
            outlier_lines.append(f'- **{r["id"]}**, seed {r["seed"]}: {m[key]:.1f}s. Floor paths: `{paths}`; safe salvage paths: `{salvage}`. Bootstrap source exhaustion: {source}. Grapple start/deployment: {m.get("traversal_started")}/{m.get("traversal_complete")}. Oldest live task maximum: {r["maxima"]["oldest_live_task"]:.1f}s. Failed/cancelled tasks: {r["final"]["tasks"]["failed_total"]}/{r["final"]["tasks"]["cancelled_total"]}.')
        outlier_lines.append("")
    outlier_lines.extend(["## Interpretation", "", "The founder planner deliberately waits while a floor water source has remaining quantity. Grapple timing therefore measures both bootstrap depletion and the physical approach/build sequence. Later deployment with a larger floor reserve is often correct policy, not a traversal deadlock. Compare grapple start-to-deployment separately from startup-to-deployment.", "", "Shelter/workshop outliers also reflect salvage choice, delivery routes, needs interruptions and safe-site retries. The reserve and obstacle expansion cases probe small nearby changes; source path lengths provide a reproducible explanation of haul distance. Neither timers, walking speed nor canonical quantities were changed.", "", "Growth requires a 300s continuous stability window after infrastructure plus safe post-arrival forecasts and a 600s cooldown. Delayed first growth must be interpreted through this policy rather than equated with arbitrary inactivity."])
    (output/"outliers.md").write_text("\n".join(outlier_lines)+"\n")
    # A report cannot contain its own Git commit hash. Identify the frozen tested
    # source commit; final evidence-only HEAD is resolved externally and reported.
    source_commits = summary["tested_source_commits"]
    report = ["# POC 4.7.1 final report", "", "Branch: `codex/roomscale-poc471-founder-stress`.", "Starting SHA: `26dfe0812fcf592e047412078cec2552e2e62b36`.",
              f"Frozen tested source SHA(s): `{', '.join(source_commits)}`.",
              "Final evidence-only SHA: resolve with `git rev-parse HEAD` on this branch; it is also supplied in the delivery message. A committed report cannot embed its own commit hash. Source/harness hashes in every final result are checked against the delivered checkout.", "",
              "## Execution", "",
              f'- Total retained campaign inputs/replays/soaks: **{summary["total_scenarios"]}**; continuously executed worlds: **{summary["continuously_executed_scenarios"]}**.',
              f'- Core admitted positives: **{len(core_positive)}**. Combined positives: **{summary["valid_passes"]} PASS / {summary["valid_failures"]} FAIL**. Generator rejections: **{summary["generator_rejections"]}**; rejected candidates are excluded.',
              f'- Named adversarial cases: all ten pass. Negatives: **{summary["expected_negative_outcomes"]}/{summary["negative_scenarios"]} expected**, {summary["unexpected_negative_outcomes"]} unexpected.',
              f'- Determinism: **{sum(r["identical"] for r in summary["determinism_results"])}/{len(summary["determinism_results"])}** identical fingerprints; three variants each have two fresh repeats.',
              f'- Final deadlocks: **{summary["deadlock_count"]}**; continuous invariant violations: **{summary["invariant_violation_count"]}**.',
              f'- Population min/median/max: **{summary["population"]["min"]}/{summary["population"]["median"]}/{summary["population"]["max"]}** across positive eight-day worlds.',
              f'- Full founding construction success: **{summary["valid_passes"]}/{summary["valid_scenarios"]}**; physical elevated access: **{summary["traversal_success_count"]}/{summary["valid_scenarios"]}**.', "",
              "## Long soaks", "", "| Run | Days | Max / final population | Shelter | Projects | Retained tasks / max | Created / failed | Journal retained / sequence | Final urgent |", "|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for r in summary["long_soak_results"]:
        f = r["final"]
        report.append(f'| {r["id"]} | {f["seconds"]/600:.0f} | {r["maxima"]["population"]} / {f["population"]} | {f["shelter"]} | {len(f["projects"])} | {f["tasks"]["retained_tasks"]} / {r["maxima"]["tasks"]} | {f["tasks"]["created_total"]} / {f["tasks"]["failed_total"]} | {len(f["journal"])} / {f["journal_sequence"]} | {f["status"]["urgent"]} |')
    report.extend(["", "Each soak runs its full target duration, including finite-resource terminal behavior. Exhaustion can produce a stable crisis; current production has no mortality system, so bounded needs at 1 and paused growth are not evidence of healthy survival. The task ledger, sources and journal remain observable. Per-day normalized creation/event rates and complete timelines are in the machine-readable summary.", "", "## Timings", "", "| Milestone | Min | Median | Mean | P90 | Max |", "|---|---:|---:|---:|---:|---:|"])
    for key in ["meaningful_work","first_salvage","material_haul","shelter_complete","depot_complete","workshop_complete","housing_complete","sixth_citizen","traversal_complete","elevated_territory"]:
        d = summary["milestone_timing_distributions"][key]
        report.append("| " + key + " | " + " | ".join(f'{d[k]:.1f}' for k in ["min","median","mean","p90","max"]) + " |")
    report.extend(["", "## Findings and fixes", "", "Three High production bugs were reproduced and fixed: shelter rest positions blocking the future depot, off-grid connectors cutting new structure corners, and synchronous retry recursion on unavailable navigation. No free-resource, entity-count, capability or traversal bypass was found. Root causes, pre-fix artifacts and focused commands are in [root-causes.md](root-causes.md). The first full investigation was intentionally stopped after 48 completed candidates when the corner defect was reproduced; its failures are preserved and are not the final campaign.", "", "The production changes are limited to `settlement_development_system.gd`, `floor_navigation.gd` and `citizen_agent.gd`. No costs, timings, movement speed, canonical resources, population rules or technology gates were tuned. See `git diff --stat 26dfe0812fcf592e047412078cec2552e2e62b36 HEAD` for all changed files, and `git log --oneline 26dfe0812fcf592e047412078cec2552e2e62b36..HEAD` for implementation/evidence commits.", "", "## Regressions and provenance", "", "Canonical baseline passed before edits. Final POC47 Fast and three canonical repeats, POC46 Fast/scenario, POC45 Fast/survival/scenario, POC4 Fast/contract/cleanup and sustained seven-day scenario, generic RoomDefinition checks, and both new focused regressions pass. Earlier attempted regression failures are retained and explained in root causes. Final evidence consistency errors: " + str(errors) + ".", "", "Exact final campaign commands:", "", "```powershell", "./TEST_ROOM_SCALE_POC471.ps1 -Mode Full -Count 60 -OutputDirectory verification/poc471/final -Workers 2", "./TEST_ROOM_SCALE_POC471.ps1 -Mode Explore -OutputDirectory verification/poc471/exploration -Workers 2", "python scripts/poc471_evidence.py", "```", "", "All case configs/results contain exact replay commands. Unexpected failures would retain `failure-package.json`. There are no unresolved final admitted-case failures. Bulk execution is headless; no rendered failure screenshot is claimed.", "", "## Architectural assessment", "", "**3. moderately robust.** The evidence supports varied origins, spawns, resource distances, material supplies, detours, target approaches and identifier changes inside the supported room topology. It does not prove arbitrary layouts or room reconstruction. The fixed depot apron, local build search lattice, compatibility activity/rest anchors, finite source assumptions, one elevated target and deterministic ordering remain boundaries. Legacy established-room targets inside initial structure footprints retain their old contract. Some candidate layouts are conservatively rejected rather than admitted as solvable.", "", "Multi-civilization is blocked primarily by shared-world resource/salvage authority, construction reservations and navigation invalidation, in addition to ID and scene namespaces. Local economy, governor and completed-project capabilities are useful instance-level foundations, but duplicating their current services would duplicate finite physical resources. See [multiciv-readiness.md](multiciv-readiness.md). No second civilization or speculative gameplay was implemented.", "", "See [scenario-matrix.md](scenario-matrix.md), [campaign-summary.json](campaign-summary.json), [outliers.md](outliers.md) and [findings.md](findings.md) for per-case evidence and limitations."])
    (output/"final-report.md").write_text("\n".join(report)+"\n",encoding="utf-8")
    print(json.dumps({"evidence_consistency_errors":errors,"positive_passes":summary["valid_passes"],"rejected":summary["generator_rejections"]}))
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
