# POC 4 simulation and verification

Read RoomScale_POC_4_Project_Plan.md as the acceptance contract. Milestone evidence and the final criterion matrix live in verification/poc4/.

## Gameplay

Launch `./RUN_ROOM_SCALE.ps1 -Room room_poc4`. Watch food/water reserves, raise Survival and Resources, issue Secure Water, then select Chair and Authorize Salvage when the planner reports missing materials. Citizens select work autonomously; no individual assignment is required. Pause/1x/4x/10x controls affect fixed simulation ticks. F3 retains existing diagnostics, camera controls and citizen inspection.

The canonical room is normal RoomDefinition data: 50 citizens, 300 food, 100 water, zero wood/metal, 50 shelter capacity, 12 simultaneous rest positions, an elevated finite water container, and an accessible finite food cache. Resource content is finite and never refills. Starting construction inventory cannot solve the water problem.

## State and architecture

- NeedSystem owns food/water/fatigue, severity, effort consequences, and finite rest reservations. One day is 600 simulation seconds. Food demand is 2 rations/citizen/day, water 3. A ration relieves .65 need. Serious/critical shortages interrupt optional routine work; critical shortages reduce building/salvage effort to 25%. Rest requires a valid reserved housing position and meaningful recovery duration.
- EconomySystem owns four resources with exclusive available/reserved/in-transit/delivered/consumed states. Reservation subtracts availability; physical pickup and delivery advance the ticket; eating/drinking or project completion consumes it. Cancelled carried inventory becomes a physical dropped bundle. Conservation audits include that transfer.
- ResourceSystem derives furniture profiles from semantic/material data, owns finite source reservations and transportable bundles, and adds depot stock only after verified citizen delivery. Completed bundle records are removed. Source depletion persists.
- SalvageSystem owns explicit authorization and once-only stage work/yields. STRIPPED, PARTIAL, FRAME, DEPLETED are production state transitions, rendered as predetermined component geometry. Final depletion removes the obstacle and any surface; active infrastructure/source surfaces are protected from unsafe salvage.
- CivilizationPlanner owns priorities (Disabled/Low/Normal/High/Critical), Secure Food/Water, salvage permissions, task scoring, labor counters and causal explanations. Survival emergencies retain self-care even with disabled priorities. No runtime LLM is involved.
- CivilizationSimulation coordinates fixed 0.1-second ticks and runs the planner every simulation second. Interactive speed and accelerated tests use the same tick. It delegates task records/lifecycle to the existing coordinator, locomotion to existing citizens/navigation, and construction/deployment to the existing construction and surface-route systems.

Historical rooms remain valid regression fixtures; adding optional civilization/resource_profile metadata enables the same generalized simulation in other rooms. Four-resource economy construction reuses the grapple stages with wood/metal costs; the historical mechanical-parts fixture inventory remains only in legacy scenarios.

## Commands

```powershell
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc4/regression/fast.log
./TEST_ROOM_SCALE_VISUALS.ps1 -LogDirectory verification/poc4/regression/visuals
./TEST_ROOM_SCALE_CROSSROOM.ps1 -OutputDirectory verification/poc4/regression/cross-room
./TEST_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-7/room_photo_luna.json -LogPath verification/poc4/regression/photo-room.log
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Scenario -CaptureVisuals -OutputDirectory verification/poc4/presentation
./TEST_ROOM_SCALE_POC4.ps1 -Mode Sustained
./TEST_ROOM_SCALE_POC4.ps1 -Mode Repeatability
./TEST_ROOM_SCALE_POC4.ps1 -Mode Stability
./TEST_ROOM_SCALE_POC4.ps1 -Mode All
```

The runner rejects nonzero exits, missing markers/results, script/errors and timeouts. Repeatability uses five fresh complete scenarios, each with seven days after recovery. Stability runs the same scenario followed by thirty additional days; no resources are injected after initialization. JSON retains accounting, stage state, source quantities, movement and task bounds; screenshot sidecars retain actual simulation state.

## Limits

No death, reproduction, farming, crafting chains, save/load, arbitrary fracture or collapse. Stages use conservative predetermined geometry and aggregate material bundles. Shelter represents finite capacity, sheltered/unsheltered citizen state, finite rest reservations and a visible shortage. Unsheltered citizens do not yet have strong penalties or differentiated behavior. There are no exposure, health, morale or homelessness consequences, household ownership, or shelter construction systems; shelter gameplay expansion belongs to a future POC. The current construction system handles one active traversal project per session, as in the prior POCs. Prior POC3 human art acceptance remains a separate historical gate; POC4 preserves that presentation rather than recertifying it.
