# POC 2 Acceptance Matrix

This is the current disposition against the 48 criteria in `RoomScale_POC_2_Project_Plan.md`. “PASS” has supporting run or artifact evidence. “DOCUMENTED” means the behavior/workflow is present in repository instructions but was not exercised end to end. “PARTIAL” means some evidence exists but a fresh confirmation is still needed. Visual findings are limited to the saved images and reviewer observations; they do not imply photo-realism or exact dimensions.

| Criterion | Disposition | Evidence / limit |
| --- | --- | --- |
| AC-1 — Reconstruction Skill Exists | PASS | `skills/roomscale-room-reconstruction/SKILL.md`; `m1-status.md`. |
| AC-2 — Skill Is Self-Contained | PARTIAL | A fresh reader reviewed the M1 skeleton (`m1-fresh-reader-review.md`) and an independent fresh-Luna run produced a valid candidate (`m7-status.md`); the original reader review predates the v2 contract expansion. |
| AC-3 — Repository Documentation | PASS | `README.md`, `docs/RoomDefinition_Contract.md`, skill references, this matrix, and `m9-status.md`. |
| AC-4 — Flexible Photo Count | DOCUMENTED | Skill accepts any number of same-room photographs; no separate variable-count run was performed. |
| AC-5 — Ordinary Photo Input | PASS | The canonical workflow used ordinary room photographs in `photo_holder/`; no specialized capture hardware was used. |
| AC-6 — Optional Scale Reference | DOCUMENTED | Skill permits known measurements but does not require them; both independent reconstructions disclosed approximate scale. |
| AC-7 — Coverage Awareness | PASS | Primary and fresh-Luna reconstruction notes identify occlusion, perimeter ambiguity, estimates, and limits. |
| AC-8 — Actionable Additional-Photo Request | DOCUMENTED | The skill requests a specific additional view only when a material ambiguity cannot be resolved; canonical views were sufficient, so a request was not exercised. |
| AC-9 — Same-Room Reconciliation | PASS | Four-view primary reconstruction note treats the photos as one physical room. |
| AC-10 — Cross-View Object Association | PASS | Primary note associates repeated windows, desk, stool, hammock, and doors rather than duplicating them. |
| AC-11 — Cross-View Consistency | PASS | Primary candidate and note encode a single layout hypothesis and disclose uncertain wall assignments and dimensions. |
| AC-12 — Room Shell Reconstruction | PASS | Schema-v2 floor/walls and shell appearance in the candidate; M5 captures and M2 validation. |
| AC-13 — Architectural Openings | PASS | Candidate contains window and French-door openings; validator and production rendering support actual cutouts. |
| AC-14 — Major Object Identification | PASS | Desk, cabinet, hammock, chair, stool, lamp, and art are represented; small clutter is omitted and disclosed. |
| AC-15 — Semantic Classification | PASS | Candidate objects use semantic kinds plus generic appearance archetypes; `m2-status.md` covers renderer behavior. |
| AC-16 — Relative Geometry | PASS | Candidate bounds, rotation, raised target, and derived navigation validate; dimensions remain explicitly approximate. |
| AC-17 — Visual Appearance Data | PASS | V2 contract supports general room-shell/object color and material data; candidate and M5 visuals exercise it. |
| AC-18 — Recognizable Reconstruction | PASS | Reviewer reports the whole-room initial view reads as the photographed room; limitations are in `m5-status.md`. |
| AC-19 — Major Layout Fidelity | PASS | Primary note and whole-room image preserve the desk/cabinet/openings and other major relationships; exact wall assignments remain estimates. |
| AC-20 — Recognition Over Exact Measurement | PASS | Skill and reconstruction note prioritize recognizable proportions and label measurements as estimates. |
| AC-21 — Navigable Floor | PASS | Candidate runtime-navigation validation; final M2 production marker. |
| AC-22 — Obstacle Generation | PASS | Candidate derives six blocking obstacles; M2 production output reports obstacle-aware detour. |
| AC-23 — Elevated Surface Generation | PASS | `DESK_SURFACE` derives three reachable approaches; M3/M4 validation and production target investigation. |
| AC-24 — Traversal-Relevant Geometry | PASS | M5 deploys segmented cable and validates the route from floor to target height. |
| AC-25 — Standard RoomDefinition Output | PASS | Primary and independent candidates use the accepted v2 RoomDefinition schema; v1 remains supported. |
| AC-26 — Runtime AI Independence | PASS | Gameplay runs use the saved JSON and local simulation; no runtime AI service is invoked. |
| AC-27 — Model-Separated Architecture | PASS | Runtime architecture audit and full test show no Luna-specific reconstruction dependency. |
| AC-28 — Validator Pass | PASS | Primary attempt 2 passes `VALIDATE_ROOM_SCALE.ps1`; see M4 and its candidate log. |
| AC-29 — AI Repair Loop | PASS | Preserved attempt 1 failure was returned for one AI repair; attempt 2 passes without hand-editing. |
| AC-30 — Skill Documents Repair | PASS | `references/validation-and-repair.md` specifies exact candidate validation and new-attempt repair. |
| AC-31 — Inspectable Artifact | PASS | Canonical JSON and reconstruction/repair notes remain under `verification/poc2/candidates/primary/`. |
| AC-32 — Honest Uncertainty | PASS | Primary note distinguishes photo evidence, scale/layout estimates, generic-shape substitutions, and omitted detail. |
| AC-33 — Zero Manual Level Authoring | PASS | Candidate is generated as JSON; rendering, navigation, and gameplay are produced by code. No Godot editor repositioning was used. |
| AC-34 — No Room-Specific Gameplay Changes | PASS | Candidate runs through generalized navigation, task, construction, and traversal code; no candidate ID/coordinate gameplay branch was introduced. |
| AC-35 — Reconstructed Room Loads | PASS | Final candidate full log contains M2 success and all downstream pass markers. |
| AC-36 — Normal Camera Works | PASS | M8 camera easing/inspection assertions pass; M5 camera captures saved. |
| AC-37 — Citizens Navigate Reconstruction | PASS | M2 obstacle-aware movement/detour and M3 investigation pass. |
| AC-38 — Reconstructed Elevated Target | PASS | Production M3 assigns investigators to `DESK_SURFACE` and verifies arrival. |
| AC-39 — Existing Barrier Logic | PASS | M3 reports no navigation connection from floor to desk before construction. |
| AC-40 — Existing Construction Logic | PASS | M4 completes all 11 deliveries, all three gates, and builders return. |
| AC-41 — Existing Traversal Logic | PASS | M5 verifies continuous route travel and target height; sampled speed and interval are logged. |
| AC-42 — Full Gameplay Loop | PASS | Final canonical log includes M2–M6/M8; M6 records 3 arrivals, 3 explorations, and 2 reuses. |
| AC-43 — Canonical Photo Test | PASS | The four photos in `photo_holder/` are identified as the canonical input in M3 evidence. |
| AC-44 — Canonical Room Recognizable | PASS | Reviewer-approved whole-room view; ceiling color is present in the data but not clearly shown by the saved open-top view. |
| AC-45 — Canonical Room Playable | PASS | Final candidate completes the production loop without candidate-specific gameplay source changes. |
| AC-46 — Fresh-Context Reproducibility | PASS | Independent fresh-Luna candidate passes after documented repairs; this is workflow/validation evidence, not gameplay evidence. |
| AC-47 — Secondary AI Usability | PASS | Distinct Astra context produced a candidate that passed after two repairs; no gameplay claim for that room. |
| AC-48 — Durable Repository Workflow | DOCUMENTED | README now documents photo input, candidate location, validator/repair loop, and production run; a clean clone/new-room trial was not performed. |

## Overall disposition

The canonical candidate passes structural/runtime-navigation validation and the complete production gameplay loop. The visual reconstruction is recognizable at whole-room scale, but the small citizen/cable are difficult to resolve in gameplay screenshots, and the saved open-top view does not clearly demonstrate the turquoise ceiling plane. AC-2 and AC-48 retain documented limitations above. Root review is complete; the Aphrael Work handoff remains pending, and this matrix does not declare the overall POC complete.
