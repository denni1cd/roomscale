# POC 4 acceptance matrix

**Overall PASS — 45/45 criteria, 2026-10-02.** Contract: [project plan](../../docs/history/poc4/RoomScale_POC_4_Project_Plan.md). See [final report](final-report.md) for commands, statistics and limits.

Evidence shorthand below is relative to this directory: **F** = [final fast tests](final-fast/fast.log); **C** = [final contract tests](final-fast/contract.log); **R** = [final full batch](release/summary.json), including five complete scenarios and [30-day accounting](release/stability-30days.json); **S** = [rendered seven-day scenario](final-evidence/sustained-7days.json); **V** = [inspected visual review](visual-review.md). Scenario JSON checks 01–25 are assertions against actual production state. Tests execute the same fixed simulation tick as interactive play, with high-level directives only.

| Criterion from plan | Result | Evidence and demonstrated behavior |
| --- | --- | --- |
| AC-1 — Existing Gameplay Regression | PASS | Baseline before implementation; final `regression/cross-room/summary.md` A→B→A 3/3; `regression/photo-room.log`, `audited-room-b.log`, `release-fast.log`, `release-visuals/`. Loading, barriers, delivery, construction, climbing and exploration retained. |
| AC-2 — Autonomous Citizen Needs | PASS | F two-day production population and R/S ongoing cycles; persistent food/water/fatigue per citizen, not HUD counters alone. |
| AC-3 — Food Consumption | PASS | F; R thirty-day total 3,108 actual meals and food units consumed through exclusive tickets. |
| AC-4 — Water Consumption | PASS | F; R thirty-day total 4,684 drinks and units consumed; initial stock genuinely falls to zero before recovery. |
| AC-5 — Rest | PASS | F validates rest ownership/recovery; R 2,368 completed rests and ongoing reserved rest positions. |
| AC-6 — Shelter Capacity | PASS | F deliberately uses shelter 44 for  50 citizens and finite slots; UI exposes capacity/shortage; canonical capacity 50/rest 12. |
| AC-7 — Need Consequences | PASS | F self-care interruption and critical work penalty; actual production need tasks and R recovery cycles. |
| AC-8 — Civilization Forecast | PASS | F population-based forecasts; V starting/declining/recovered water and S demand  100 food/ 150 water per day. |
| AC-9 — Wood Resource | PASS | R/S 13 salvaged wood received, 4 consumed by construction, 9 remaining. |
| AC-10 — Metal Resource | PASS | R/S  4 metal physically recovered, delivered and consumed by construction. |
| AC-11 — Correct Resource Accounting | PASS | F exclusive reservation/cancellation/carried-drop tests; continuous R/S conservation audits across source, bundles and all ticket states; no double spending. |
| AC-12 — High-Level Priorities | PASS | F verifies normal dropdown state/control synchronization; V four category controls. No individual worker assignment. |
| AC-13 — Priority Effects | PASS | F deterministic rank changes and production labor change when exploration is disabled; emergency self-care retained. |
| AC-14 — Secure Resource Directive | PASS | F directive validation; R/S check 07 invokes Secure Water through civilization planner; V normal button. |
| AC-15 — Salvage Directive | PASS | R/S check 12 authorizes object only; citizens choose work; V authorization control/state. |
| AC-16 — Protected Objects | PASS | F protected work rejected; R/S check 10 ensures no pre-authorization destruction; V shortage screenshot intact protected chair. |
| AC-17 — Generic Resource Profile | PASS | F semantic/material chair/table/box derivation; production resource profiles independent of room IDs/coordinates; alternate source fixture also completes. |
| AC-18 — AI-Room-Compatible Contract | PASS | C six malformed metadata/source-geometry cases rejected and standard room accepted; optional metadata documented in `docs/RoomDefinition_Contract.md`; historical definitions pass unchanged. |
| AC-19 — Staged Salvage | PASS | F/R/S four actual transitions STRIPPED→PARTIAL→FRAME→DEPLETED, requiring 42 work seconds. |
| AC-20 — Visible World Change | PASS | V stage 1–4 images: upholstery/back removed, panel/legs reduced, brace frame, empty floor. |
| AC-21 — Persistent Destruction | PASS | R 30 days and S seven days after recovery: stage stays 4, no intact mesh/obstacle/surface restoration. |
| AC-22 — No Duplicate Harvest | PASS | F rejects repeated stage work/yields; R continuous audit keeps total  13 wood/ 4 metal throughout 30 further days. |
| AC-23 — Real Salvage Work | PASS | Production floor paths, physical edge access and work before yields; every R/S salvage WORK tick checks distance ≤ 0.3 in to object; V citizen work image plus state sidecar. |
| AC-24 — Resource Bundles | PASS | F/R/S harvested yields create reserved world bundles, not immediate depot stock; V stage/hauling captures. |
| AC-25 — Real Hauling | PASS | F five pickups/deliveries; R/S check 16 observes carry and delivery; V visible carried metal parcel. |
| AC-26 — Planner Shortage Recognition | PASS | R/S checks 04/11; zero starting materials prevent progression, planner requests authorized material source. |
| AC-27 — Explainable Blocker | PASS | V `material-shortage.png` and work shot show no authorized wood/metal source and project W0/4 M0/4; subsequent delivery counts update. |
| AC-28 — Existing Traversal Reuse | PASS | R/S existing barrier coordinator, construction stages, cable deployment and shared route_between navigation; `alternate-surface.log/json` completes water access on SUPPLY_SURFACE despite different initial target. |
| AC-29 — Needs Drive Expansion | PASS | R/S checks 05–09: consumption lowers reserve, Secure Water seeks unreachable source, physical investigation creates project. |
| AC-30 — Canonical Material Shortage | PASS | `rooms/room_poc4.json` starts wood0/metal0; R/S pre-authorization stalled project; no material injection. |
| AC-31 — Salvage Solves Material Shortage | PASS | R/S check 17 observes exclusive project materials; actual  4 wood/ 4 metal from authorized furniture consumed. |
| AC-32 — Traversal Completion | PASS | R/S check 18 completed existing construction and connected route; V launcher/cable and 100% project. |
| AC-33 — Resource Access After Traversal | PASS | R/S check 19 observes continuous climbing, elevated extraction and return to depot; V climb/acquisition shots. |
| AC-34 — Crisis Recovery | PASS | Each R run recovers at 741s with reserve >1 day; S recovered image water162/1.08 days, final water415/2.77 days. |
| AC-35 — No Citizen Micromanagement | PASS | Scenario driver only changes category priorities, issues Secure Water and authorizes furniture. Production planner dispatches all work. |
| AC-36 — Simulation Speed Controls | PASS | F verifies Pause,4x,10x and 0.1s fixed tick; V normal controls. Sustained tests accelerate the same step without movement shortcuts. |
| AC-37 — Seven-Day Sustained Run | PASS | R five fresh scenarios each continue seven days after recovery; S rendered run reaches total8.235 days, with food/water/rest and altered room maintained. |
| AC-38 — Fast Test Layer | PASS | F needs/economy/planner/profiles/salvage/geometry/UI/speed checks; C metadata/source geometry. Final fast23.75s, contract0.30s. |
| AC-39 — Production-Code Full Test | PASS | `scripts/poc4_scenario_test.gd` loads actual production scene and drives `CivilizationSimulation.step`; no substitute economy, injected materials, teleports or forced worker assignment. |
| AC-40 — Five-Run Repeatability | PASS | R repeat-01 through repeat-05, consecutive fresh processes, all complete chain plus seven days, recovery 741s each. |
| AC-41 — Thirty-Day Stability | PASS | R thirty days AFTER recovery, total31.235 days. Max history500, tickets25, bundles10, active task249.5s; finite needs/positions, movement≤0.650004 in/tick, no failed tasks/duplicate salvage/conservation violations. |
| AC-42 — Approximately Fifty Citizens | PASS | All R/S checks maintain population50; separate production agents with needs and task cycles. |
| AC-43 — No LLM Citizen Logic | PASS | Code inspection: deterministic planner, need rates, task scoring, shared coordinator; no runtime model/HTTP requests in new simulation systems. |
| AC-44 — No Manual Godot Authoring | PASS | Code-generated scene/UI/stages and standard JSON; setup/launch/test scripts exercised. No user editor/resource repair required. |
| AC-45 — POC 3 Presentation Preserved | PASS | V compares retained baseline and final production captures; generated desk, shared furniture/materials, citizens/settlement, lighting and grapple presentation retained; regression visual resolver/assets/presentation checks pass. Earlier POC3 human art acceptance is not recertified. |

No failing or blocked POC4 criterion remains. See final report for deliberately bounded simulation scope and retained failed development iterations.
