"""Evidence-only audit. Does not modify simulation source or scenario inputs."""
from pathlib import Path
import hashlib
import json
import statistics
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT / "scripts"))
import poc472_campaign as campaign

EVIDENCE = ROOT / "verification/poc472"
FINAL = EVIDENCE / "final"
def read(path): return json.loads(path.read_text())
def normalized(path): return hashlib.sha256(path.read_bytes().replace(b"\r\n",b"\n")).hexdigest()
def write(path,value): path.write_text(json.dumps(value,indent=2,sort_keys=True)+"\n")

def main():
    frozen = read(EVIDENCE / "freeze-manifest.json")
    results = [read(p) for p in sorted(FINAL.glob("*/result.json"))]
    assert len(results) == 127, f"Incomplete final campaign: {len(results)}/127"
    assert len({r["id"] for r in results}) == 127
    assert all(r["result"] == "PASS" for r in results)
    assert all(r["tested_commit"] == frozen["frozen_commit"] for r in results)
    assert all(r["source_hashes"] == frozen["source_hashes"] for r in results)
    for name,digest in frozen["source_hashes"].items(): assert normalized(ROOT / name) == digest, name
    for name,digest in frozen["harness_hashes"].items(): assert normalized(ROOT / name) == digest, name
    by_id = {r["id"]:r for r in results}
    input_preservation = []
    admitted = []
    for old_dir in [ROOT / "verification/poc471/final",ROOT / "verification/poc471/exploration"]:
        for config_path in sorted(old_dir.glob("*/config.json")):
            config = read(config_path)
            old_definition = config_path.parent / Path(config["room_file"]).name
            current_definition = FINAL / config["id"] / old_definition.name
            identical = old_definition.read_bytes() == current_definition.read_bytes()
            assert identical, config["id"]
            input_preservation.append(dict(id=config["id"],identical_bytes=identical,sha256=hashlib.sha256(old_definition.read_bytes()).hexdigest()))
            if config["classification"] == "positive" and read(config_path.parent / "result.json")["result"] == "PASS": admitted.append(config["id"])
    assert len(input_preservation) == 95 and len(admitted) == 79
    assert all(by_id[sid]["result"] == "PASS" for sid in admitted)
    for r in results:
        case_dir = FINAL / r["id"]
        config = read(case_dir / "config.json")
        definition = case_dir / Path(config["room_file"]).name
        assert hashlib.sha256(definition.read_bytes()).hexdigest() == r["definition_sha256"]
        assert hashlib.sha256((case_dir / "config.json").read_bytes()).hexdigest() == r["config_sha256"]
        for name,digest in r["harness_hashes"].items(): assert normalized(ROOT / name) == digest
        log = (case_dir / "run.log").read_text()
        assert "SCRIPT ERROR:" not in log and "ERROR:" not in log
        assert "POC471_OBSERVER_PASS" in log or r["id"] == "NEG-05"
        if r["id"] != "NEG-05":
            assert abs(r["final"]["seconds"]-float(config["days"])*600) < .001
            assert r["final"]["placement_checks"] > 0
    summary = campaign.review(results,FINAL)
    assert summary["previous_79_positive_passes"] == 79
    assert summary["placement_positive_passes"] == 31
    assert summary["generator_rejections"] == 0
    assert len(summary["determinism_results"]) == 6 and all(r["identical"] for r in summary["determinism_results"])
    assert summary["deadlock_count"] == 0 and summary["invariant_violation_count"] == 0
    control = read(EVIDENCE / "observer-control-final/POS-001/result.json")
    assert control["tested_commit"] == frozen["frozen_commit"] and control["source_hashes"] == frozen["source_hashes"]
    assert control["fingerprint"] == by_id["POS-001"]["fingerprint"]
    extra = read(EVIDENCE / "supplemental/EXTRA-NARROW-01/result.json")
    assert extra["result"] == "PASS" and not extra["violations"]
    assert extra["tested_commit"] == frozen["frozen_commit"] and extra["source_hashes"] == frozen["source_hashes"]
    assert abs(extra["final"]["seconds"]-4800) < .001
    extra_config = read(EVIDENCE / "supplemental/EXTRA-NARROW-01/config.json")
    extra_definition = read(EVIDENCE / "supplemental/EXTRA-NARROW-01" / Path(extra_config["room_file"]).name)
    prefix = read(EVIDENCE / "packing-prefix-replay/PLACE-031/result.json")
    assert prefix["result"] == "PASS" and prefix["tested_commit"] == frozen["frozen_commit"]
    old_prefix_config = read(EVIDENCE / "packing-development/PLACE-031/config.json")
    prefix_name = Path(old_prefix_config["room_file"]).name
    assert (EVIDENCE / "packing-development/PLACE-031" / prefix_name).read_bytes() == (EVIDENCE / "packing-prefix-replay/PLACE-031" / prefix_name).read_bytes()
    regression_commands = read(EVIDENCE / "regressions/commands.json")
    assert len(regression_commands) == 15 and all(c["Passed"] for c in regression_commands)
    regressions = {}
    for path in sorted((EVIDENCE / "regressions").glob("*/summary.json")):
        items = read(path)
        if isinstance(items,dict): items = [items]
        assert all(item["Passed"] for item in items), path
        regressions[path.parent.name] = items
    markers = {"poc471_navigation_test":"POC471_NAVIGATION_PASS","poc471_unreachable_task_test":"POC471_UNREACHABLE_PASS","poc471_midlink_test":"POC471_MIDLINK_PASS","poc472_planner_test":"POC472_PLANNER_PASS","poc472_packing_test":"POC472_PACKING_PASS","room-definition-fast":"ROOMSCALE_FAST_TEST_PASS"}
    for name,marker in markers.items():
        log = (EVIDENCE / "regressions" / (name+".log")).read_text()
        assert marker in log and "SCRIPT ERROR:" not in log and "ERROR:" not in log,name
    packing = by_id["PLACE-031"]["final"]["settlement_plan"]["decisions"][0]
    assert packing["selected"]["rank"] > 0 and packing["rejection_reasons"].get("downstream founding arrangement",0) > 0
    decisions = [d for r in results for d in r.get("final",{}).get("settlement_plan",{}).get("decisions",[])]
    assert all(d["connectivity"] and d["downstream_feasible"] for d in decisions)
    assert max(d["navigation_trials"] for d in decisions) <= 2048
    base_room = read(ROOT / "rooms/room_poc47.json")
    base_quantities = {o["id"]:o.get("resource_profile",{}).get("contents",{}) for o in base_room["objects"]}
    assert extra_definition["civilization"]["stock"] == base_room["civilization"]["stock"]
    assert {o["id"]:o.get("resource_profile",{}).get("contents",{}) for o in extra_definition["objects"] if o["id"] in base_quantities} == base_quantities
    for sid in [f"PLACE-{i:03}" for i in range(1,32)]:
        r = by_id[sid]
        config = read(FINAL / sid / "config.json")
        definition = read(FINAL / sid / Path(config["room_file"]).name)
        assert definition["civilization"]["stock"] == base_room["civilization"]["stock"]
        assert {o["id"]:o.get("resource_profile",{}).get("contents",{}) for o in definition["objects"] if o["id"] in base_quantities} == base_quantities
        assert {o["id"]:o.get("resource_profile",{}).get("stages",[]) for o in definition["objects"] if o["id"] in base_quantities} == {o["id"]:o.get("resource_profile",{}).get("stages",[]) for o in base_room["objects"]}
    soaks = []
    for sid,days in [("SOAK-01",90),("SOAK-02",60),("SOAK-03",60)]:
        r = by_id[sid]; f = r["final"]
        assert abs(f["seconds"]-days*600) < .001
        soaks.append(dict(id=sid,days=days,result=r["result"],population=f["population"],shelter=f["shelter"],projects=len(f["projects"]),tasks=f["tasks"],journal=len(f["journal"]),journal_sequence=f["journal_sequence"],suppression_keys=f["suppression_keys"],governor=f["governor"],growth=f["growth_reason"],available=f["ledger"]["available"],consumed=f["ledger"]["consumed"],remaining={res:sum(float(s["remaining"].get(res,0)) for s in f["sources"].values()) for res in ["food","water"]},maxima=r["maxima"],execution_seconds=r["execution_seconds"]))
    exhausted = soaks[2]
    assert exhausted["remaining"] == {"food":0,"water":0}
    assert exhausted["available"]["food"] == 0 and exhausted["available"]["water"] == 0
    assert exhausted["governor"]["emergency"]
    report = dict(frozen_commit=frozen["frozen_commit"],production_commit=frozen["production_commit"],total=127,previous_79=79,new_placement_positives=31,formerly_rejected={sid:by_id[sid]["result"] for sid in ["POS-023","POS-029"]},declared_positive_worlds=summary["valid_scenarios"],feasible_former_negative="NEG-03",genuine_negative_worlds=5,retained_negative_inputs=5,negative_classification_results=summary["expected_negative_outcomes"],generator_rejections=0,pre_tick_physical_rejections=["NEG-05"],determinism=summary["determinism_results"],observer_control_identical=True,soaks=soaks,regressions=regressions,regression_commands=regression_commands,markers=markers,continuous_ticks=sum(round(r.get("final",{}).get("seconds",0)*10) for r in results),continuous_simulation_days=sum(r.get("final",{}).get("seconds",0)/600 for r in results),planner_decisions=len(decisions),planner_navigation_trial_max=max(d["navigation_trials"] for d in decisions),planner_reused_decisions=sum(d["reused"] for d in decisions),packing_evidence=packing,source_and_harness_unchanged=True,retained_definitions_identical=input_preservation)
    report["supplemental_placement"] = {"id":extra["id"],"result":extra["result"],"milestones":extra["milestones"],"final_population":extra["final"]["population"],"layout":extra["final"]["settlement_plan"]["decisions"][0],"execution_seconds":extra["execution_seconds"]}
    report["new_placement_positives_including_supplemental"] = 32
    report["all_inputs_including_supplemental"] = 128
    report["original_packing_prefix_replayed_unchanged"] = True
    write(EVIDENCE / "audit.json",report)
    print(json.dumps({k:report[k] for k in ["frozen_commit","total","previous_79","new_placement_positives","declared_positive_worlds","genuine_negative_worlds","generator_rejections","observer_control_identical","planner_decisions","planner_navigation_trial_max","source_and_harness_unchanged"]}))

if __name__ == "__main__": main()
