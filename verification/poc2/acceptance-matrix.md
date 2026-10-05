# POC 2 Acceptance Matrix

This is the current disposition against the 48 criteria in `RoomScale_POC_2_Project_Plan.md`. “PASS” has supporting run or artifact evidence. “DOCUMENTED” means the behavior/workflow is present in repository instructions but was not exercised end to end. “PARTIAL” means some evidence exists but a fresh confirmation is still needed. Visual findings are limited to the saved images and reviewer observations; they do not imply photo-realism or exact dimensions.

| Criterion | Disposition | Evidence / limit |
| --- | --- | --- |
| AC-1 — Reconstruction Skill Exists | PASS | `skills/roomscale-room-reconstruction/SKILL.md`; `m1-status.md`. |
| AC-2 — Skill Is Self-Contained | PASS | A new Luna context used only the current packaged skill/references, two canonical photos, and the validator interface; after validator-directed repair it produced a valid candidate. See `fresh-luna-final/final-report.md` and `m7-status.md`. |
| AC-3 — Repository Documentation | PASS | `README.md`, `docs/RoomDefinition_Contract.md`, skill references, this matrix, and `m9-status.md`. |
| AC-4 — Flexible Photo Count | PASS | The current-skill fresh-context run used exactly two of the four canonical photos and produced a structurally/runtime-navigation-valid candidate after repair; see `fresh-luna-final/final-report.md`. |
| AC-5 — Ordinary Photo Input | PASS | The canonical workflow used ordinary room photographs in `photo_holder/`; no specialized capture hardware was used. |
| AC-6 — Optional Scale Reference | PASS | The canonical and final current-skill fresh-Luna runs state that no known dimension or photo scale was supplied; both produce approximate dimensions from ordinary object proportions (`candidates/primary/attempt-1/reconstruction-note.md`, `fresh-luna-final/final-report.md`). |
| AC-7 — Coverage Awareness | PASS | Primary and fresh-Luna reconstruction notes identify occlusion, perimeter ambiguity, estimates, and limits. |
| AC-8 — Actionable Additional-Photo Request | PASS | The second-room review identified the specific missing reverse room view and asked for it as an optional fidelity improvement while continuing from the four available photos. The requested angle and reason are preserved in `secondary-room/additional-view-request.md`; no new photo is required to proceed. |
| AC-9 — Same-Room Reconciliation | PASS | Four-view primary reconstruction note treats the photos as one physical room. |
| AC-10 — Cross-View Object Association | PASS | Primary note associates repeated windows, desk, stool, hammock, and doors rather than duplicating them. |
| AC-11 — Cross-View Consistency | PASS | Primary candidate and note encode a single layout hypothesis and disclose uncertain wall assignments and dimensions. |
| AC-12 — Room Shell Reconstruction | PASS | Schema-v2 floor/walls and shell appearance in the candidate; M5 captures and M2 validation. |
| AC-13 — Architectural Openings | PASS | Candidate contains window and French-door openings; ordinary windows add no outdoor scenery unless `exterior_scene` data is present. The fast fixture proves both absent-data and explicit-data behavior. |
| AC-14 — Major Object Identification | PASS | Desk, cabinet, hammock, chair, stool, lamp, and art are represented; small clutter is omitted and disclosed. |
| AC-15 — Semantic Classification | PASS | Candidate objects use semantic kinds plus generic appearance archetypes; `m2-status.md` covers renderer behavior. |
| AC-16 — Relative Geometry | PASS | Candidate bounds, rotation, raised target, and derived navigation validate; dimensions remain explicitly approximate. |
| AC-17 — Visual Appearance Data | PASS | Synchronized v2 contracts cover room-shell/object colors, materials, transparency, generic archetypes, and optional validated opening-relative exterior primitives. The canonical candidate exercises explicit exterior data; the fast fixture proves it renders only declared shapes. |
| AC-18 — Recognizable Reconstruction | PASS (current test scope) | The user reviewed attempt 7 and said it looks much better and will work for current tests. The user explicitly deferred closer visual resemblance to future graphics work. The procedural render remains stylized, with estimated dimensions and simplified artwork; this is accepted for the current POC test scope, not a claim of photorealism. See `candidates/primary/attempt-7/alignment-note.md` and `screenshots/poc2/photo-alignment-attempt-7-*.png`. |
| AC-19 — Major Layout Fidelity | PASS (current test scope) | The candidate represents the major desk, hammock, window, cabinet, and door relationships, and the user accepts attempt 7 for current tests. Dimensions and some wall assignments remain estimates; additional visual alignment is deferred. |
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
| AC-34 — No Room-Specific Gameplay Changes | PASS | Candidate runs through generalized navigation, task, construction, and traversal code; no room-ID or coordinate branch exists. Exterior scenery is opening data, and this cleanup does not change gameplay systems. |
| AC-35 — Reconstructed Room Loads | PASS | Primary attempt-7 production rerun contains M2 success and downstream pass markers (`candidates/primary/attempt-7/production-full.log`). |
| AC-36 — Normal Camera Works | PASS | M8 camera easing/inspection assertions pass; M5 camera captures saved. |
| AC-37 — Citizens Navigate Reconstruction | PASS | M2 obstacle-aware movement/detour and M3 investigation pass. |
| AC-38 — Reconstructed Elevated Target | PASS | Production M3 assigns investigators to `DESK_SURFACE` and verifies arrival. |
| AC-39 — Existing Barrier Logic | PASS | M3 reports no navigation connection from floor to desk before construction. |
| AC-40 — Existing Construction Logic | PASS | M4 completes all 11 deliveries, all three gates, and builders return. |
| AC-41 — Existing Traversal Logic | PASS | M5 verifies continuous route travel and target height; sampled speed and interval are logged. |
| AC-42 — Full Gameplay Loop | PASS | Primary attempt 2 historically passed; attempt 6 rerun and attempt 7 each include M2–M6/M8, with M6 reporting 3 arrivals, 3 explorations, and 2 reuses. |
| AC-43 — Canonical Photo Test | PASS | The four photos in `photo_holder/` are identified as the canonical input in M3 evidence. |
| AC-44 — Canonical Room Recognizable | PASS (current test scope) | The user reviewed attempt 7 and accepted it for current tests while deferring closer graphic resemblance to future work. This records the user's scoped acceptance; it does not assert photo-realistic or dimensionally exact reconstruction. |
| AC-45 — Canonical Room Playable | PASS | Final candidate completes the production loop without candidate-specific gameplay source changes. |
| AC-46 — Fresh-Context Reproducibility | PASS | A fresh Luna context used the current skill with only two canonical photos and passed structural/runtime-navigation validation after one repair; see `fresh-luna-final/final-report.md`. This is not gameplay evidence. |
| AC-47 — Secondary AI Usability | PASS | Distinct Astra context produced a candidate that passed after two repairs; no gameplay claim for that room. |
| AC-48 — Durable Repository Workflow | PASS | A new clone at `C:\Users\Zero\AppData\Local\Temp\roomscale-ac48-fresh-context-20260928` began at commit `2dda51b979850794a5f1d292705d37bb51756b02` with empty `git status --short` before inputs. This fresh context used the cloned README, reconstruction skill/references, `docs/RoomDefinition_Contract.md`, and only the four photos copied to `photo_holder/second_room`; no earlier second-room artifact was used. `candidates/secondary-room/fresh-context/room_hearth_living_room_fresh.json` and attempt 1 are preserved; structural/runtime-navigation validation passes with four reachable approaches and a valid construction site, and the 360-second gameplay run exits 0 with M2–M6/M8 pass markers. Note, provenance, and logs are in `candidates/secondary-room/fresh-context/`. The earlier clone evidence remains preserved under `clean-clone-secondary-room/`. |

## Overall disposition

The primary attempt-7 candidate and fresh-context secondary-room candidate pass validation and the full production gameplay loop. The final architecture cleanup also passes the fast suite, Room A and Room B regressions, and refreshed gameplay for both photo rooms; the renderer captures are saved under `architecture-cleanup-visual/`. Ordinary windows receive no default outdoor elements, and the canonical deck/rail/tree/foliage scene is described in attempt 7's `exterior_scene` data. AC-18, AC-19, and AC-44 remain accepted for the stated current-test scope; closer visual resemblance is deferred future graphics work. AC-48 remains PASS based on its preserved fresh-context candidate, validator/gameplay logs, and clone provenance. AC-8's reverse-view photo is optional and is not a current blocker.
