# RoomScale POC 4 final report

**Result: PASS. Milestones 0–9 complete. All 45 acceptance criteria PASS.** Completed 2026-10-02 against [the POC4 plan](../../RoomScale_POC_4_Project_Plan.md). The individual evidence-backed results are in [acceptance.md](acceptance.md); milestone history is in `implementation-plan.md`, `m0-m2-status.md`, `m3-m7-status.md`, `m8-status.md`, and [PROJECT_PROGRESS.md](../../PROJECT_PROGRESS.md).

## Delivered gameplay

Fifty production citizens consume food/water, grow fatigued, reserve finite rest capacity, and select survival/work tasks autonomously. Starting water is insufficient and construction stock is zero. Secure Water causes real investigation of the unreachable source and creates the existing traversal project. The planner explains missing wood/metal. High-level authorization permits furniture dismantling through four visible stages; citizens work at the object's physical edge, carry yields to storage, deliver project materials, build the existing grapple, climb to the source, extract finite water, return it to storage, and recover the reserve forecast. No individual citizen commands are required.

Launch `./RUN_ROOM_SCALE.ps1` (now defaults to `room_poc4`). Raise Survival/Resources/Construction, issue Secure Water, select Chair and Authorize Salvage when the project lacks materials. Pause/1x/4x/10x, normal citizen inspection, object inspection and F3 diagnostics are available. Historical rooms remain selectable explicitly.

## Architecture and important files

New `scripts/need_system.gd`, `economy_system.gd`, `civilization_planner.gd`, `resource_system.gd`, `salvage_system.gd`, `civilization_simulation.gd`, and `civilization_ui.gd` own needs, exclusive resource tickets, deterministic priorities/directives, generalized profiles/finite sources/bundles, authorized once-only stages, fixed-tick orchestration, and the normal HUD.

Existing `citizen_agent.gd`, `task_coordinator.gd`, `construction_system.gd`, `floor_navigation.gd`, `surface_navigation.gd`, `room_definition.gd`, and `pipeline_proof.gd` integrate those systems into actual movement, task lifecycle, material gates, navigation/world changes, standard room validation and production rendering. The existing Reach/barrier/construction/cable/route systems remain authoritative. Four-resource construction uses wood/metal; mechanical parts remain in historical fixtures only. Cancelled carried stock becomes a real dropped bundle. Task history is bounded and routine work is not duplicated when interrupted by self-care.

`rooms/room_poc4.json` is ordinary RoomDefinition data with optional civilization/source metadata. Generic semantic/material derivation supports furniture without canonical-room conditionals. The alternate-source fixture moves water to SUPPLY_SURFACE while preserving the initial target; the full chain succeeds in 629 simulation seconds (`alternate-surface.log/json`), demonstrating source-driven expansion through the generalized layer.

Added `scripts/poc4_fast_test.gd`, `poc4_contract_test.gd`, `poc4_scenario_test.gd`, and `TEST_ROOM_SCALE_POC4.ps1`. Updated `RUN_ROOM_SCALE.ps1`, `.gitignore`, `README.md`, `PROJECT_PROGRESS.md`, `docs/RoomDefinition_Contract.md`; added `docs/POC4_GAMEPLAY.md` and retained all earlier plans/evidence. Tests load production nodes and use the same 0.1s simulation step as interactive play. Full scenarios issue only category priorities, Secure Water and salvage authorization; no stock injection, citizen teleportation or test-only economy.

## Verification actually executed

Baseline before needs implementation: fast checks, visual resolver/assets/presentation checks, full Room B, A→B→A, accepted photo-room attempt 7, and rendered launch capture. All passed. Post-change regressions repeat fast/visual checks, complete A→B→A 3/3, accepted photo-room, and audited Room B. Logs remain in `baseline/` and `regression/`.

Final commands executed from repository root:

```powershell
./TEST_ROOM_SCALE_POC4.ps1 -Mode All -OutputDirectory verification/poc4/release
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc4/final-fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Sustained -CaptureVisuals -OutputDirectory verification/poc4/final-evidence
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc4/regression/release-fast.log
./TEST_ROOM_SCALE_VISUALS.ps1 -LogDirectory verification/poc4/regression/release-visuals
./TEST_ROOM_SCALE_CROSSROOM.ps1 -OutputDirectory verification/poc4/regression/cross-room
./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-7/room_photo_luna.json -LogPath verification/poc4/regression/photo-room.log
```

Intermediate Scenario, Fast, Sustained and earlier All batches were also run, with logs retained. Final UI-only edits after the release batch passed final-fast (23.75s plus contract 0.30s) and the rendered full-chain seven-day run. No simulation behavior changed after the final thirty-day batch. A final ordinary production launch (Godot --path, --quit-after 300, room_poc4) exited 0; `default-launch.log/png` records 50 active citizens and the normal HUD without a scenario driver.

### Five consecutive full scenarios

[Final batch summary](release/summary.json): 8/8 jobs passed in 316.08 seconds. Each of the following fresh processes completes all twenty canonical chain assertions, then five sustained assertions for seven additional days. All recover at 741 simulation seconds, maintain 50 citizens, and salvage exactly 13 wood/4 metal with 4 wood/4 metal consumed by construction.

| Run | Result | Wall seconds | Days after recovery | Evidence |
| --- | --- | ---: | ---: | --- |
| repeat-01 | PASS | 34.43 | 7 | [log](release/repeat-01.log), [state](release/repeat-01.json) |
| repeat-02 | PASS | 32.92 | 7 | [log](release/repeat-02.log), [state](release/repeat-02.json) |
| repeat-03 | PASS | 33.02 | 7 | [log](release/repeat-03.log), [state](release/repeat-03.json) |
| repeat-04 | PASS | 33.01 | 7 | [log](release/repeat-04.log), [state](release/repeat-04.json) |
| repeat-05 | PASS | 33.11 | 7 | [log](release/repeat-05.log), [state](release/repeat-05.json) |

### Seven-day sustained and thirty-day stability

Rendered final seven-day run: **PASS**, 39.17 wall seconds, total 8.235 simulated days (seven AFTER recovery). Consumed 800 food/1,229 water, completed 603 rests; final food 297/2.97 days, water 415/2.77 days. Four salvage stages remain depleted and construction remains operational. [Log](final-evidence/sustained-7days.log), [state](final-evidence/sustained-7days.json).

Final stability: **PASS**, 134.34 wall seconds, thirty days AFTER recovery, total 31.235 days. Consumed 3,108 food/4,684 water and completed 2,368 rests. Final available food 291/2.91 days, water 415/2.77 days, wood 9, metal 0. Finite source quantities decline rather than refill. Max task history 500, tickets 25, bundles 10, active task age 249.5 simulation seconds. Max movement 0.650004in per 0.1s tick matches walking speed with floating-point tolerance. Continuous conservation, finite needs/positions, no failed tasks, no duplicate stage yields and bounded lifecycle checks pass. [Log](release/stability-30days.log), [state](release/stability-30days.json).

## Evidence and diagnosis

Seventeen inspected real viewport images plus JSON sidecars cover start, forecast decline, protected material shortage, authorization, all four salvage stages, work, bundles/carrying, project deliveries, built traversal, source climb/acquisition, recovery and the sustained altered room. See [visual review](visual-review.md) and [capture directory](final-evidence/sustained-7days-visuals/). Useful images include `material-shortage.png`, `citizen-carrying-material.png`, `salvage-stage-2.png`, `construction-supplied.png`, `water-acquisition.png`, `water-recovered.png`, and `sustained-altered-room.png`.

Failed development iterations remain available: initial need interruptions exposed routine-task backlog (fixed in coordinator); first full scenario had a test-driver parse error (fixed without changing gameplay); early presentation showed overlapping/stale HUD and work-point padding mismatch (fixed UI and physical edge access, then rerun all gameplay gates). They are superseded by final-fast/release/final-evidence, not removed or counted as successful runs.

## Remaining limits and blockers

No known blocking POC4 defect. Deliberate scope limits: finite sources eventually exhaust; no farming/regeneration, death/reproduction, relationships/combat, crafting chains, structural physics or save/load. Shelter is aggregate finite capacity and rest reservations rather than individual home ownership. Salvage uses predetermined component stages and aggregate material parcels. Existing construction supports one active traversal project per session. Planner/UI causal text refreshes every simulation second. Earlier POC3 human art acceptance remains an independent historical gate; POC4 preserves its current presentation rather than claiming new human approval.
