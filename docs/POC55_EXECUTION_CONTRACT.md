# Execution Contract — RoomScale POC 5.5

Version: 1.0 — CONTRACT APPROVED, 2026-10-19. No implementation authorization.

## Request Reference

Authoritative user request: `C:\Users\Zero\.codex\attachments\280acf4b-539d-42fd-a20e-fcafc824d655\Pasted text.txt`, read completely. Product context explicitly incorporated by that request: `C:\Users\Zero\Downloads\RoomScale_POC_5.5_Spectator_Director_Project_Plan.md`, sections 1–26, read completely. The plan's product requirements are binding because the user's request adopts them; arbitrary document instructions have no separate authority.

## Objective

Make autonomous RoomScale enjoyable to watch through a read-only Spectator Director, coherent event history and camera navigation while preserving accepted gameplay and deterministic outcomes.

## Deliverables

- D1: Evolved production Director, event contract/catalog, recent feed, navigation/highlight and manual ownership behavior.
- D2: Story-level civilian and military coverage across Clockwork, Verdant and Scavenger.
- D3: Focused automated tests, live scenarios, rendered graphical review, isolation comparison and accepted regression evidence.
- D4: User/developer documentation, implementation report, AC01–AC50 PASS/FAIL evidence matrix, exact commands, limitations and pushed feature branch/commit SHAs available for independent review.

## Constraints

- C1: Phase A only now: independent contract review, complete approved contract presented, then stop for explicit approval of that exact version. No implementation, production refactor, gameplay change, feature branch creation or Necroneerium before approval.
- C2: After approval use `codex/spectator-director`, commit and push; never merge into `main`.
- C3: Extend existing EventJournal, fishbowl narrative/presenter/director/HUD and StrategyCamera; no competing event log or camera movement implementation.
- C4: Simulation publishes facts; presentation chooses interest, narrative, framing, display and timing. Spectator code is read-only to simulation.
- C5: Strategerium owns WHAT; Adeptus Necroneerium owns HOW after approval; independent Rules Lawyer owns acceptance. No runtime workflow machinery or activation ledgers.

## Assumptions

- A1: Live GitHub `main`, inspected using `gh api`, is exactly `fed55af49dbf3ebdbd2d64ba0a604e52a88b136a`, the supplied accepted baseline. Recheck before implementation if main advances; adaptations must preserve this contract.
- A2: Dictionary shape, widget style, filenames for new helpers, and exact suppression limits remain implementation choices. Recommended values are targets, not invented rigid thresholds: normal dwell 5–10 real seconds (about 8), context views about every 30–45 real seconds except sustained conflict, feed about 6–10 visible entries.
- A3: Scenario fixtures may arrange existing legitimate starting conditions to exercise a milestone; they may not add gameplay solely to make spectator shots.

## Acceptance Criteria

All clauses below are binding authorized scope. Each AC01–AC50 maps one-to-one to the plan identifier; supplementary EC clauses preserve requirements that span those identifiers. Runtime claims require executed behavioral evidence, not source existence. Evidence must name commands, scenario/seed, result artifact and relevant source where useful.

| ID | Required outcome | Sufficient evidence |
|---|---|---|
| AC01 | User-facing subsystem is named Spectator Director. | Rendered controls and user documentation. |
| AC02 | Exposes explicit OFF/FREE, FOLLOW, PRIORITY, RANDOM; active mode always obvious; FOLLOW available for a valid user selection. | Exercised state transitions and rendered controls. |
| AC03 | OFF/FREE performs no automatic cuts or tracking; events/alerts continue and controls work. | Extended real-time OFF run with moving subjects and newly generated events. |
| AC04 | PRIORITY chooses highest eligible high-interest stories using presentation metadata. | V2/V6 mixed-priority executed selection trace. |
| AC05 | RANDOM broadly samples events, work, projects, citizens and overviews; routine life can appear and selection is not Priority delegation. | V7 seeded quiet-colony trace containing multiple classes and routine activity, with assertion that fails for Priority delegation. |
| AC06 | Explicit FOLLOW tracks valid live citizen, active project/site and active conflict/encounter focus. | V5 exercised all three target classes including moving citizen/group. |
| AC07 | Invalid/dead/removed/ended FOLLOW target exits to OFF, without replacement. | V5 invalidation/termination tests. |
| AC08 | All supported manual camera movements/actions immediately exit all three active modes to OFF via explicit input contract. | V3 input coverage matrix plus real graphical input path. |
| AC09 | Manual override persists indefinitely until explicit mode selection, including after idle, events and scene cuts. | Extended real-time advance/event test, then explicit re-enable test. |
| AC10 | Director-generated camera movement never falsely causes manual override. | Executed programmatic motion in active modes. |
| AC11 | Existing bounded EventJournal remains authoritative; no unrelated competing history. | Architecture inspection plus live source-to-feed trace and bounded retention test. |
| AC12 | Preserve stable id/seconds/day/kind/message/evidence/focus and validated structured identity/story context. | V1 schema, legacy producer/migration, monotonic ID and focus-validation tests. |
| AC13 | Simulation producers decide no distance, yaw/tilt, camera priority, dwell, UI color, mode, interrupt or headline wording policy. | All-producer audit plus exercised records. |
| AC14 | Generic presentation catalog/adapter owns category, priority, headline/subtitle, eligibility, display duration, grouping/cooldown, framing and routine feed-only policy; reuse narrative translation. | Catalog fixture tests and extension documentation. |
| AC15 | Unknown/unsupported kinds degrade safely without feed/Director crash. | Executed malformed/unknown-kind consumer fixtures. |
| AC16 | Journal/card duplicates, story/subject/location cooldowns and pending queues remain bounded; meaningful later milestones survive suppression. | Flood/repeated-story tests showing bounds, restraint and milestone distinction. |
| AC17 | Pipeline supports Critical > High > Medium > Low. | V2 ordered fixture assertions and multi-priority rendered feed. |
| AC18 | Critical covers casualty/death, morale break, retreat, capture, severe survival crisis and civilization-threatening state. | Catalog mapping fixtures for each class. |
| AC19 | High covers deployment/march, first hostile contact, major battle, major structure/technology/solution completion, traversal/access, major reach and mobilization completion. | Catalog mapping fixtures for each class. |
| AC20 | Medium covers equipment completed/ordered, muster, new citizen/cohort, construction start, salvage authorization, important resource change, research start and unusual noncritical transition. | Catalog mapping fixtures for each class. |
| AC21 | Low covers routine salvage/hauling/work, construction/research progress, patrol/movement and normal life without ordinary Priority interrupts. | V2 mapping/interrupt tests and V7 routine selection. |
| AC22 | Normal fishbowl UI has compact bounded recent feed rather than transient-only event text. | Live accumulating/retention run and rendered view; target about 6–10 visible events. |
| AC23 | Feed has readable narrative headline/context, day/time and priority cue; no raw debug dictionaries. | Rendered populated feed review. |
| AC24 | Multi-society events identify relevant society when necessary. | Live three-society feed captures and event identity assertions. |
| AC25 | Valid focusable events are actually clickable. | V4 real UI click plus resolver tests. |
| AC26 | Event click enters OFF/FREE and leaves camera with player. | V4 click/state trace and extended no-recapture run. |
| AC27 | Click smoothly frames best valid live subject, then site/project/conflict focus. | V4 executed live subject/site cases and rendered transition/final framing. |
| AC28 | Missing live subject permits stored valid historical position fallback. | V4 removed-subject historical-focus case. |
| AC29 | No valid focus leaves event readable and nonfocusable, with no fabricated location. | V4 invalid/no-focus test and UI evidence. |
| AC30 | Click highlight is visible, temporary, presentation-only, expires, follows moving subject briefly when practical and has no collision/navigation effects. | Executed appearance/movement/expiration checks, rendered capture and authority inspection. |
| AC31 | Normal automatic dwell stays 5–10 real seconds, default near 8. | V6 real-time shot timestamps. |
| AC32 | Simulation speed does not multiply cuts. | Equal real-time shot cadence comparisons at supported speeds. |
| AC33 | Priority ties use no RNG and deterministically favor newer unseen event, materially different story/subject, then stable event ID order. | V6 replayed tie fixtures and identical selection traces. |
| AC34 | Random uses isolated spectator RNG and cannot affect simulation determinism. | RNG authority audit plus V10 digest comparison. |
| AC35 | Fixed spectator seed reproduces Random sequence. | Repeated fresh seeded V7 runs. |
| AC36 | Cooldowns prevent rapid repeat cuts to same story/subject/location and adjacent states. | V6/V7 repetition traces. |
| AC37 | Automatic modes periodically restore room/settlement context, about 30–45 real seconds normally; sustained conflict exception documented. | V6/V7 wide-shot timing traces. |
| AC38 | Generic framing classes/helpers request legal existing StrategyCamera transforms; subsystems do not own movement. | Architecture audit and rendered diverse-class framing. |
| AC39 | Founder, survival, salvage, traversal, development, population and innovation stories remain functional. | Live scenario coverage for EC5 civilian enumeration and narrative fixtures. |
| AC40 | Accepted military simulation publishes meaningful equipment/readiness, muster, deployment, combat and resolution stories. | Live POC5.4 scenarios proving EC6 full military enumeration; not synthetic-only. |
| AC41 | Combat journal records story milestones, never every attack, HP change, waypoint or tick. | Live attack-versus-journal trace and event rate/grouping assertions. |
| AC42 | Priority, Random and Follow can frame military activity without CombatSystem camera ownership. | Exercised military focus in each mode and boundary audit. |
| AC43 | Clockwork/Verdant/Scavenger appear correctly through generic core; no identity bias or permanent Random starvation. | V9 live three-party run and seeded fairness coverage; core inspection and per-society narrative assertions. |
| AC44 | Director/feed never mutate resources, tasks, citizens, combat, governor, doctrine, armory, navigation, hostility, speed or simulation ordering. | Authority audit and V10 executed state/digest comparison. |
| AC45 | Identical fresh inputs yield identical accepted simulation outputs under OFF, PRIORITY, seeded RANDOM and FOLLOW where practical. | V10 matching outputs listed in EC7; explicit reason if a specific Follow comparison is inapplicable. |
| AC46 | Existing pan/orbit/zoom, WASD/arrows, Q/E, presets and citizen inspection remain functional. | Exercised controls/inspection regression and graphical input evidence. |
| AC47 | F3/details remains available for technical evidence; normal cards remain readable narrative. | Real F3 toggle and rendered normal/details views. |
| AC48 | Real rendered verification proves controls/feed, framing, highlight and override. | V11 seven required captures and recorded visual review in EC8. |
| AC49 | Accepted gameplay regression suites pass; superseded camera assertions require documented strictly stronger replacements, never simple weakening. | V12 executed suite results, replacement rationale/assertions and clean `git diff --check`. |
| AC50 | Documentation explains modes, override, feed/navigation, event extension rules and determinism/isolation. | Reviewed user/developer docs plus report/evidence matrix under EC10. |

- EC1 — Workflow and publication (covers D1–D4, C1/C2/C5): Complete independent Strategerium contract review, resolve revisions, present complete approved version and stop for explicit user approval. Only afterward invoke installed Adeptus Necroneerium: Lich shapes actual repository architecture; Vampire supplies executable contracts/skeletons/seams; Skeleton implements; independent Shade executes tests/graphics and inspects evidence, patches bounded defects or routes failures backward. Lich/Vampire must leave executable repository value. Work may choose safe implementation/refactors but cannot redefine scope. Work submits READY FOR REVIEW, never COMPLETE. Independent Strategerium Rules Lawyer examines code, tests, images and deterministic outputs against contract and original plan; targeted repairs continue until accepted or real blocker. Only that reviewer may issue COMPLETE. Material scope defects require corrected reviewed contract and fresh explicit approval. Commit/push feature branch and report SHAs; never merge main. Evidence: role artifacts, explicit approval record, commits/remote verification and independent review. No guard machinery, activation ledger, installation forensics or fail-closed metadata blocking useful work.
- EC2 — Camera/input/focus contract (covers AC03/06–10/25–30/38/46, C3): Reuse StrategyCamera as physical authority and evolve current director. Explicit manual ownership covers right-drag orbit, middle-drag pan, wheel zoom, WASD, arrows, Q/E, room/settlement/citizen presets, direct user selection/focus and any added camera navigation; transform-delta heuristics prohibited. Target identity includes type, stable ID, current valid focus, optional framing class, validity and display name; raw stale Node reference is not sole identity where ID exists. Active development, traversal, innovation, armory or equivalent exposed stable sites are supported; conflict focus derives from participants/site, not hard-coded room coordinate. Eligible shots require finite valid focus, existing live target where required, legal room framing, mode eligibility and cooldown clearance. Director never invents activity. Evidence: V3–V5 path/target matrices, finite/out-of-bounds cases, camera legality and authority inspection.
- EC3 — Event context/integration (covers AC11–16/24/39–43, C3/C4): Validate/document layout preserving fields, normalize relevant society instance/civilization, subject type/ID, related stable entities, project/site/conflict or relation endpoints, story key and genuine domain severity/state. Preserve simple producers or intentionally migrate them. World and society existing journal sources must all reach coherent spectator consumers with stable source identity, deterministic ordering and no ID-collision loss; no competing unrelated journal. Narrative must use event's relevant society rather than global selected-profile wording. Evidence: all-producer inventory and migration matrix, V1 schema/bounds/ID tests and V8/V9 live traces.
- EC4 — Selection/observer restraint (covers AC04/05/16/31–38/43): Critical may replace next queued shot/preempt only after minimum readable dwell; ordinary High/Medium cannot interrupt before normal minimum. Random pool genuinely includes recent events, workers, haulers, salvagers, builders, researchers, military workers, projects, settlements, conflict activity and overviews when available; importance is not primary Random weight. Recent-history/cooldown and society handling prevent visible repetition/permanent starvation. Generic framing may include room-wide, settlement-wide, site-medium, group-medium, citizen-close, conflict-wide/detail; exact helper representation discretionary. Evidence: V6/V7 mixed-stream/quiet/live activity tests and traces with class/society coverage; no requirement for unavailable activity to be fabricated.
- EC5 — Civilian enumeration (covers AC39): Preserve founders arriving; crisis begins/recovers; salvage authorized; first/important salvage; source/object exhaustion; traversal starts/completes; territory/reach gained; construction starts/completes; shelter capacity increases; new citizens/cohorts; research starts; technology completes; innovation solution starts/completes; existing meaningful growth pauses/material constraints. Civilization-specific terms remain narrative/data-driven. Evidence: per-class live event trace and adapter assertions, not static catalog alone.
- EC6 — Military enumeration (covers AC18–21/40–43): Story-level events at existing authorities cover (1) hostile contact/contest activation, (2) force commitment, (3) meaningful equipment/material readiness blockage changes, (4) equipment order, (5) kit completion, (6) muster begins, (7) force ready/muster complete, (8) deployment/march, (9) battle/engagement begins, (10) casualty/death, (11) morale break, (12) retreat begins, (13) elimination where applicable, (14) strategic security/capture, (15) meaningful demobilization/return start or completion, (16) meaningful issued-equipment loss on death. Multiple facts may share one meaningful event; no invented mechanics or per-tick spam. Evidence: live accepted POC5.4 scenario coverage matrix with actual records, feed/shot evidence and explicit applicability for conditional milestones; fixtures only supplement.
- EC7 — Isolation/regression enumeration (covers AC44/45/49): Compare fresh-mode runs for citizen IDs/tasks; economy/resources; construction/development/innovation; doctrine/equipment; attack order; casualties; retreat/capture; population; current accepted fingerprints. Preserve founder mode, autonomous governor, finite economy, task assignment, needs/self-care, development, traversal/navigation, innovation, growth, multi-civilization, conflict pressure, doctrine, armory, physical muster, five combat roles/faction capabilities, morale/retreat, capture, death persistence, demobilization, manual controls and citizen inspection. Journal consumer presence cannot change simulation behavior. Evidence: accepted fast/canonical/visual/conflict/military suites appropriate to inspected main, matched V10 results and no weakened gameplay assertions.
- EC8 — Graphics/normal UI (covers AC22–30/46–48): Maintain observer emphasis on world/current stories/compact status/readable history/obvious mode, with optional inspection rather than tactical management or debug text covering normal screen. Alerts can remain transient alongside feed without mandatory clicks. V11 real rendered captures must show (1) Priority major event, (2) Random ordinary work, (3) multi-priority feed, (4) click/highlight, (5) manual override OFF, (6) combat/mobilization framing, (7) multi-civilization identification. Review and repair occlusion, unreadable text, hidden controls, clipping, excessive zoom, poor framing and invisible highlights. Evidence: images plus review findings, real input-path capture and resolution/context metadata.
- EC9 — Milestone/commit strategy (covers C1/C2/C5): M0 audit is Phase A only. After approval, use reviewable coherent commits tracking M1 event context/catalog; M2 states/RNG/timing; M3 manual ownership; M4 feed/click/highlight; M5 follow targets; M6 military/multi-society; M7 live/isolation evidence; M8 graphics/regression/docs/report. Closely related milestones may share a commit; every milestone must be traceable to code/tests/evidence and final SHAs. Exact architecture and test implementation remain Necroneerium discretion. Evidence: milestone-to-commit/evidence table and pushed branch.
- EC10 — Final package/scope (covers D1–D4, AC50, C2–C5): Deliver production behavior, structured journal, generic catalog, persistent feed, click/highlight, four modes, manual contract, military events, focused tests, live/rendered/isolation/regression evidence, updated docs, implementation report, AC01–AC50 PASS/FAIL with exact evidence/test/scenario/source, final branch/SHA(s), exact commands and genuine out-of-scope limitations. Known gaps in binding criteria are failures/blockers, not limitations excusing completion. Do not add any excluded feature below. Evidence: independently inspectable package and remote branch; no PASS merely because code exists.

## Baseline Audit and Repository Touchpoints

Live read-only audit: GitHub API main SHA above; tree and source inspected directly while clone `work/roomscale` transfers. No production edits or implementation branch created. Audit copies are in `work/audit`. No tests or graphical execution claimed during Phase A.

- `scripts/event_journal.gd`: RefCounted bounded 128 records, monotonic sequence, suppression dictionary bounded at 2×limit, basic fields plus major flag; focus defaults to zero (validity cannot be inferred from zero alone).
- `scripts/fishbowl_narrative_adapter.gd`: existing narrative event-card mapping; global selected civilization profile and Verdant substitutions need event-local society handling.
- `scripts/fishbowl_event_presenter.gd`: real-time transient presenter, pending limit 8, seen limit 128, cursor assumes one journal ID stream.
- `scripts/fishbowl_camera_director.gd`: enabled boolean, 8-second dwell, 40-second wide rhythm, major events/activity and citizen array indexing; evolves into four-state generic Director with stable identity lookup.
- `scripts/strategy_camera.gd`: current input and physical transform authority, legal scale limits and focus helpers; no explicit manual-input signal currently.
- `scripts/fishbowl_hud.gd`: Auto camera boolean, single event card, speed controls/F3; consumes only runtime journal. Evolve same HUD.
- `scripts/civilization_simulation.gd`, `scripts/world_simulation.gd`, `scripts/conflict_startup.gd`, `scripts/conflict_scenario.gd` and scene/startup wiring: societies have individual journals; world owns another journal and global citizen allocation; conflict currently owns overlay setup/camera presentation paths. Coherent world/runtime consumption and camera ownership integration are required risks, not permission for a replacement log/camera.
- Producer inventory from live scripts: CivilizationSimulation (founders_arrived, first_salvage, territory_reached, object_depleted); AutonomousGovernor (governor, traversal_started/complete, source_exhausted, directive, salvage_authorized); SettlementDevelopmentSystem (growth_paused, development_started, materials_supplied, structure_complete, shelter_increased, advanced_available); PopulationSystem (growth_paused, cohort_joined); InnovationRuntime (problem_detected, research_started, solution_started, technology_complete, solution_complete); ArmorySystem.record (KIT_ORDERED, KIT_COMPLETED, KIT_RESERVED, KIT_ISSUED, KIT_RELEASED, KIT_RETURNED, KIT_LOST); MilitaryReadiness through ArmorySystem (READINESS_TARGET, CITIZEN_MUSTERING, MOBILIZATION_READY) plus KIT_BLOCKED directly; WorldSimulation (SITE_TARGETED, CONFLICT_PRESSURE_CHANGED, FORCE_DEPLOYED through armory); TerritorySystem (FIRST_CONTACT, SITE_CONTESTED, HOSTILITY_DECLARED, COMPETITION_DECLARED, HOSTILITY_ENDED, SITE_CAPTURED); CombatSystem (FORCE_COMMITTED, FORCE_ARRIVED, COMBAT_CASUALTY, RETREAT, FORCE_ELIMINATED, CONFLICT_STOOD_DOWN). Implementation must reconfirm exhaustive producer inventory against checkout, including indirect wrapper calls.
- Identity inventory: CitizenAgent.citizen_id and CivilizationSimulation.citizen_for; world.allocate_citizen_id; runtime.instance_id and definition identity; development.active.id/site/target; innovation research.id and active.id/site; armory projects keyed `instance:equipment:sequence`; traversal project/site status; territory.sites keyed anchor ID with site_id/position; combat.site_id, participants and relation endpoint pair. No dedicated stable encounter ID established by inspected code; representation may derive stable site/relation/story identity without changing simulation authority.
- Existing verification touchpoints: `poc46_fast_test.gd`, `poc46_scenario_test.gd`, `poc46_visual_test.gd`, `poc46_camera_visual_test.gd`; `poc54_data_test.gd`, `poc54_armory_test.gd`, `poc54_behavior_test.gd`, `economy_ownership_test.gd`; conflict/pressure/combat role/mixed tests; scenario JSONs `clockwork_vs_verdant`, `mixed_intensity_conflict`, `three_party_conflict`.
- Accepted entry points discovered: TEST_ROOM_SCALE_FAST.ps1; TEST_ROOM_SCALE.ps1 and REPEATABILITY; POC4/POC45/POC46/POC47/POC471/POC472/POC472_REGRESSIONS; CIVILIZATIONS; CROSSROOM; INNOVATION/INNOVATION_LIVE/EXTENSIBILITY; VISUALS; CONFLICT/CONFLICT_PRESSURE/COMBAT_ROLES/POC54; TOOLING/SMOKE/VALIDATE. Select appropriate accepted suites by their current wrappers, preserving every EC7 domain. POC46 supports Fast/Scenario/Repeatability/Stability/All and CaptureVisuals. POC54 runs data/armory/behavior/ownership and three-party live conflict; conflict wrapper currently sets manual-camera environment and requires adaptation for spectator-specific evidence, not weakening baseline tests.

## False-Completion Traps

- Renaming Auto camera without real states; Random delegating to Priority or never showing routine work; stale pinned identity without moving tracking.
- Transform heuristics causing Director to disable itself; manual override auto-resuming; event clicks showing text without navigation or camera being stolen back.
- Simulation carrying camera policy; second unrelated log/movement system; world/runtime ID collisions silently dropping stories; one global narrative profile mislabeling other societies.
- Combat journaling attacks/HP/path/ticks; suppression hiding meaningful milestones; fabricated focus or activity; random consuming simulation RNG or changing gameplay.
- Static-only tests, synthetic-only military coverage, absent rendered evidence, or civilization branches needed for ordinary future civilization treatment.
- Green tests obtained by weakened assertions; summaries accepted in place of actual artifacts; work process declaring COMPLETE without independent acceptance.

## Out of Scope

Tactical combat control; citizen orders from feed; pause-on-alert; replay/rewind/save-load expansion; saved cinematics; keyframe editor; first-person spectator; photo/video export pipeline; voice/LLM narration; diplomacy/trade UI; strategic map/minimap; permanent marker per event; attack-by-attack log; full notification settings; per-event priority customization; automatic simulation-speed changes; gameplay added solely for shots. Ordinary existing speed controls remain available to the player.

## Specialist Use

None. Live source audit provides sufficient bounded technical grounding; independent Rules Lawyer review follows.

## Contract Status

CONTRACT APPROVED — independent Rules Lawyer review passed; execution awaits explicit user approval of exact v1.0.

## Execution authorization

The user explicitly approved this exact version with “go ahead” on 2026-10-19. The approved scope above is unchanged. Implementation branch: `codex/spectator-director`; no merge to main is authorized.
