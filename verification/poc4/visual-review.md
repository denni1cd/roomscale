# POC 4 final production visual review

**PASS, 2026-10-02.** All 17 PNGs in [final rendered evidence](final-evidence/sustained-7days-visuals/) were opened and inspected. Each has a JSON sidecar with simulation time, economy, stage and camera state. Captures are from the real production viewport during the tested seven-day scenario, not reconstructed illustrations.

Compared against the retained pre-change baseline `baseline/launch.png` and POC3 final-polish settlement capture. Existing generated desk, furniture scale/materials, clockwork citizens, linked settlement, floor, lighting, and mechanical traversal retain their presentation. Canonical food/water props and predetermined salvage components add simulation information without replacing the renderer. Existing resolver/assets/presentation regressions pass in `regression/release-visuals/`.

| Captures | Findings |
| --- | --- |
| starting-settlement, declining-water | Normal HUD displays population50, food300/3days, water100/0.67days then82/0.55days, demand, materials, finite rest/shelter, category controls and speed controls. |
| material-shortage, salvage-authorized | Intact chair is protected before authorization. Project W0/4 M0/4 and lack of authorized sources explain the blocker; authorization then visibly changes object permissions. |
| citizen-salvage-work | Focused citizen is genuinely in WORK/SALVAGE with changing work progress and real needs. Close framing crops the human-sized furniture, so numerical object-edge assertions and the sidecar supplement this image. |
| salvage-stage-1, -2, -3, -4 | Distinct bare seat/legs, reduced seat/posts, brace frame, and empty floor. Persistent stage/yield UI matches authority. Stage geometry is intentionally predetermined, with no fracture physics. |
| citizen-carrying-material, resource-hauling | Visible metal parcel in citizen hands; CARRY/BUNDLE HAUL state and two materials in transit. Wider shot establishes chair/depot route scale. |
| construction-supplied, traversal-complete | Project supply advances and reaches W4/4 M4/4,100%; existing launcher and cable are visible. |
| water-source-climb, water-acquisition | Citizen on launcher/shared route, then doing RESOURCE COLLECT beside elevated blue water container. |
| water-recovered, sustained-altered-room | Water162/1.08days at recovery and415/2.77days after seven further days; stage4 remains depleted; route remains deployed, active needs/tasks remain visible. |

Inspection of earlier captures found overlapping HUD rows, stale priority controls, irrelevant citizen inspection, and salvage work outside a conservative navigation padding envelope. These were corrected in the production UI and navigation/work-access layers; the final gameplay batch was rerun after the physical work-point fix. See `presentation-before/review.md` for retained diagnosis. Final left HUD and right citizen panel have no control/text overlap. In the frame immediately after cable deployment, the previous blocker text may remain until the next one-second planning refresh; subsequent climb/acquisition captures show it cleared.

Close citizen captures use camera-only tighter framing than normal zoom controls. Camera changes do not alter citizen position, task, stock or world geometry. The normal room view prioritizes room scale; half-inch citizens are intentionally small there. POC4 visual preservation passes; this review does not replace the historical POC3 human acceptance gate.
