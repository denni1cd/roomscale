# POC 4.6 visual review

## Review performed

Inspected all 47 scale-corrected scenario captures through eight contact sheets,
plus full-resolution housing and worker views. Reviewed the final rerun's six-image
`final-visuals/review.jpg` after correcting title freshness and tracking. Earlier
1080p startup, crisis, salvage, housing frame, cohort, quiet HUD, diagnostics and
1440p images were also inspected at full resolution. Final evidence is in
`final-visuals/scenario-visuals/`; the uninterrupted automatic worker shot is in
`visuals-release/scenario-visuals/automatic-worker-detail.png`.

| Coverage | Image(s) | Review |
|---|---|---|
| Startup | startup-spectator, initial-settlement | Room remains primary; no empty event rectangle or duplicate dense HUD. |
| Water crisis | autonomous-water-crisis, card-water-reserve-low | Readable dated event and low reserve value. |
| Salvage | autonomous-salvage, salvage-intermediate-stage, altered-room-object, shot-salvage-operation | Real object depletion stages; title identifies selected operation. |
| Worker details | citizen-salvage-work, citizen-material-hauling, citizen-development-work | Citizen/tool/cargo visible in inspection views. |
| Automatic worker detail | automatic-worker-detail | Visible centered citizen carrying water; live task matches title. |
| Traversal | traversal-context, citizen-water-climb, card-new-route-complete | Context materials readable; real elevated route and climber visible. |
| Housing | first-housing-project, housing-frame, housing-shell, completed-housing | Actual project stages and material/work progress. |
| Scale correction | housing-citizen-scale | Two floors, three normal-height doors, small windows; reserved yard surrounds building. No citizen was moved to pose beside it. |
| Workshop | workshop-frame, workshop-shell, completed-workshop | Smaller one-storey building, staged construction preserved. |
| Cohort | distinct-cohort-arrival, card-new-arrivals | Separate real citizens visible; JSON records five world/screen positions. Other nearby citizens also appear. |
| Expansion | multiple-structures, population-65-plus, later-expanded-settlement | Expanded settlement; final subtitle and status both report 65 at milestone. |
| Diagnostics | diagnostics-open | Scrollable details readable, no overlap with controls. |
| Manual camera | manual-camera-off | Auto toggle off, compact HUD intact. |
| Quiet state | quiet-faded-hud | Vital signs remain readable at reduced alpha. |
| 1440p | layout-1440p | Edge anchoring and clear center retained. |

## Corrections from inspection

Removed an empty startup event panel, strengthened controls contrast, corrected
new building doors from 4.4 inches to 0.7 inches for 0.5-inch citizens, refreshed
population subtitles, hid obsolete activity captions, and compensated camera
tracking for fast-moving citizens. An earlier worker capture had no visible worker;
the corrected uninterrupted replay centers the real subject.

## Capture limits

The eight-day visual observer advances production fixed ticks and a 10x presentation
clock. Named milestone inspection views deliberately frame actual subjects; they
are not evidence that the automatic director chose those exact views. `shot-*`
images and the separate automatic-worker replay exercise the director. At first
cohort the observer stops advancing simulation ticks while wall-clock event/camera
holds finish. It does not spawn extra citizens, move them or inject resources.

Cards show event dates, so queued historical events can differ from the current
project or camera subject. At 10x this is noticeable. Whole-room citizens remain
tiny; detail shots provide inspection. Legacy starting settlement art retains its
previous scale. These are presentation limits, not claims of a cinematic finished game.
