# POC 4 implementation plan

Authoritative contract: RoomScale_POC_4_Project_Plan.md (all 45 acceptance criteria).

1. M0: preserve source; run fast, visual, A/B/A and accepted photo-room regressions. Record actual results before gameplay changes (AC-1,45).
2. M1: add persistent NeedSystem and stock-backed autonomous eat/drink/rest tasks, finite shelter and deterministic fixed stepping. Extend citizen_agent.gd and task_coordinator.gd; verify fifty production citizens (AC-2–7,42,43).
3. M2: add EconomySystem with exclusive reservation/transit/delivery/consumption ledger, demand forecasts and normal UI (AC-8–11).
4. M3: add CivilizationPlanner priorities/directives and scoring through the shared coordinator (AC-12–16,26,27,35).
5. M4: add ResourceSystem semantic/material profile derivation and optional validated standard RoomDefinition resource metadata (AC-17,18).
6. M5: add SalvageSystem stage work, authorization, physical bundles/hauling, staged geometry and navigation updates (AC-19–25).
7. M6: connect stock-backed construction to existing barrier/infrastructure/route systems. Author room_poc4.json as standard room data; no room-ID runtime branches (AC-28–34).
8. M7: verify seven integrated simulated days, bounded task history and persistent sources/infrastructure (AC-21,36,37).
9. M8: extend PowerShell verification with production scenario, five fresh runs and 30-day run; repeat regressions (AC-38–41).
10. M9: verify UI, object/citizen inspection, real stage captures; preserve POC 3 rendering, update README/contract/acceptance evidence (AC-20,27,44,45).

Planned files: scripts/need_system.gd, economy_system.gd, civilization_planner.gd, resource_system.gd, salvage_system.gd, civilization_simulation.gd; existing citizen_agent.gd, task_coordinator.gd, construction_system.gd, floor_navigation.gd, surface_navigation.gd, room_definition.gd, pipeline_proof.gd; scripts/poc4_fast_test.gd and poc4_scenario_test.gd; TEST_ROOM_SCALE_POC4.ps1; rooms/room_poc4.json; verification/poc4/; README.md, PROJECT_PROGRESS.md, docs/RoomDefinition_Contract.md.

Use the existing code-generated production scene and renderer. Preserve prior room fixtures and historical evidence. Tests drive the same fixed simulation tick as normal gameplay; allow only civilization-level intent in integrated scenarios. Retain failures and capture accounting state on failure. Do not claim visual acceptance or end-to-end success from compilation.
