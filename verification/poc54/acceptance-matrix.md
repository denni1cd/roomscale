# POC 5.4 acceptance matrix

Date: 2026-10-15. Gameplay source: `7621e2a`; final focused harness: `524e350` (full SHAs in receipts).

Evidence keys: **Data** = poc54_data_test.gd; **Armory** = [economic-armory-summary.json](economic-armory-summary.json); **Behavior** = [behavior-summary.json](behavior-summary.json); **Live/Replay** = [deterministic-replay-summary.json](deterministic-replay-summary.json); **Roles/Mixed** = retained role/extensibility gates in [regression-summary.json](regression-summary.json); **Visual** = [visual-manifest.json](visual-manifest.json). Exact commands/adaptations: [implementation-report.md](implementation-report.md).

| Criterion | Result | Concrete evidence |
|---|---|---|
| AC-01: Doctrine planning is generic and deterministic. | PASS | Data: generic composer; Behavior: stock fallback and synthetic profile; Replay: identical doctrine. |
| AC-02: Existing war policy still owns authorized force size. | PASS | MilitaryDoctrine.authorized_size uses existing policy; Roles/Mixed retain force-count and per-side policy assertions. |
| AC-03: Grade weights are Great 4 / Good 3 / Neutral 2 / Bad 1. | PASS | Data verifies WEIGHTS 4/3/2/1. |
| AC-04: Repeat-role diversity penalty is 1.25 per already-selected same role. | PASS | Data verifies REPEAT_PENALTY 1.25; exact composition fixtures exercise repetition. |
| AC-05: Front-line and ranged coverage bonuses are implemented as specified. | PASS | Data expected compositions exercise front +1.5 and fire +1 coverage, stable order. |
| AC-06: Clockwork size-3 doctrinal composition resolves Artillery / Heavy / Ranged. | PASS | Data exact Clockwork fixture: Artillery/Heavy/Ranged; Live readiness snapshot. |
| AC-07: Verdant size-3 doctrinal composition resolves Skirmisher / Line / Ranged. | PASS | Data exact Verdant fixture: Skirmisher/Line/Ranged; Live readiness snapshot. |
| AC-08: Scavenger size-3 doctrinal composition resolves Heavy / Line / Artillery. | PASS | Data exact Scavenger fixture: Heavy/Line/Artillery; Live readiness snapshot. |
| AC-09: Composition changes generically when grade data changes. | PASS | Data synthetic grade mutations change composition without planner changes. |
| AC-10: Five validated persistent equipment definitions exist with the approved costs/work. | PASS | Data exact five kit bills/work and malformed-cost/material rejection. |
| AC-11: Equipment is not added to ResourceVocabulary as a fake canonical resource. | PASS | ResourceVocabulary unchanged; kits stored in ArmorySystem.kits. |
| AC-12: ArmorySystem owns kit/project state while EconomySystem remains material authority. | PASS | Armory/Economy controlled fixture and Live audits: assets/projects versus canonical ticket ledger. |
| AC-13: Equipment manufacture reserves and consumes real finite materials. | PASS | Armory real reserved tickets; Live one paid completed project per kit and exact economy audit. |
| AC-14: Real citizen work is required to manufacture kits. | PASS | Armory rejects forged labor; project.workers records native active owned CitizenAgent work. |
| AC-15: At most two equipment projects are active per society and at most one new order starts per governor evaluation. | PASS | Armory rejects same-evaluation second order and third active project; Live verifies unique evaluations and <=2 active. |
| AC-16: Survival crisis prevents new military equipment orders. | PASS | Armory crisis fixture rejects new order; governor passes its existing crisis state. |
| AC-17: Existing legitimate reservations cannot be stolen for military production. | PASS | Armory retains unrelated construction ticket through reservations and completion. |
| AC-18: A finished kit persists in stock across time/battles until issued/lost. | PASS | Behavior muster/cancel/remuster retains exact kit IDs; Live survivors remain STOCKED. |
| AC-19: Live autonomous combat cannot freely instantiate missing equipment. | PASS | Live starts with zero kits/projects, requires paid native-work completion; CombatSystem rejects absent/incorrect ISSUED assets. |
| AC-20: Citizens physically muster before equipment issue/deployment. | PASS | Behavior real muster movement and remote-issue rejection; Live muster captures and per-actor speed checks. |
| AC-21: Equipment issue maps a stable kit ID to a persistent CitizenAgent. | PASS | Armory ownership audit; Live ordered KIT_RESERVED/KIT_ISSUED events map stable IDs to persistent citizens. |
| AC-22: Force deployment waits until accepted members are physically equipped. | PASS | Behavior READY only after all accepted citizens physically issued; Live FORCE_DEPLOYED follows readiness. |
| AC-23: No mid-battle conscription/reinforcement is introduced. | PASS | CombatSystem snapshots issued members once; readiness DEPLOYED/COMPLETE never orders reinforcements; Live commitments stable. |
| AC-24: Surviving kits return to stock only through physical demobilization. | PASS | Behavior physical cancellation/return and health retention; Live return_kit depot-arrival checks and all survivor kits STOCKED. |
| AC-25: Equipment on dead combatants becomes LOST and is not automatically recovered. | PASS | Live two terminal casualties have LOST kits; no loss handler refunds or creates salvage; ledger unchanged except real consumption. |
| AC-26: Clockwork PREPARED_FIRE implements the exact 2.0 s / 0.25 in / 0.85 interval rules. | PASS | Behavior 1.9/2.0 seconds, inclusive .25 tolerance, exact 1.02/2.975 cycles; real attack timestamps 11/30 ticks. |
| AC-27: Prepared Fire clears on movement and does not change damage/armor/range/speed/grade. | PASS | Behavior .26 displacement clears, re-preparation restores; combat_stats dictionary remains identical. |
| AC-28: Verdant PATHFINDER_MANEUVERS uses the exact bounded candidate set and shortest legal route. | PASS | Behavior exact seven candidates versus independently computed real route-length minimum; graphical cluttered route. |
| AC-29: Pathfinder never bypasses existing navigation legality or changes movement speed. | PASS | Behavior same FloorNavigation, real endpoint walking/obstacle/speed assertions; accepted navigation regressions. |
| AC-30: Scavenger JURY_RIG_EQUIPMENT tries the standard recipe first. | PASS | Behavior standard Heavy at 3 metal stays normal even with capability. |
| AC-31: Jury-rig may replace at most 1 metal with 2 wood and multiplies work by 1.25. | PASS | Behavior Heavy 3 wood/2 metal/15s and Ranged 3 wood/0 metal/10s; Live jury-rigged Heavy/Line native work. |
| AC-32: Jury-rigged equipment has the same combat stats as its normal equipment definition. | PASS | Kit variant is asset metadata; issued stats resolve the unchanged accepted role/grade catalog; Live commitments and Roles stat contracts. |
| AC-33: Signature abilities are capability-driven with no civilization-ID branches in core systems. | PASS | Behavior synthetic capabilities; source audit finds no faction IDs in military handlers. |
| AC-34: A synthetic/non-current civilization can receive a capability and obtain its generic behavior. | PASS | Behavior synthetic_society receives Prepared Fire, Pathfinder and Jury-Rig without identity dispatch. |
| AC-35: Optional future innovation-capability prerequisites can gate equipment/roles generically. | PASS | Behavior absent STEAM_POWER blocks Heavy; existing resolver unlocks it and implies POWER_SOURCE equipment gate; deployment rechecks gates. |
| AC-36: No new military technology tree is authored in this milestone. | PASS | No innovation problems/capabilities/technology catalogs or research UI changed. |
| AC-37: Mobilization/readiness state is inspectable with explicit blocking reasons. | PASS | Readiness snapshot and Live HUD captures show plan/stock/missing/projects/state/blocker/capability. |
| AC-38: Citizen inspection exposes kit ID/variant and relevant ability state. | PASS | Live muster/jury/prepared screenshots show kit ID/variant, stats and effective cycle; real click inspection enabled. |
| AC-39: Real live conflict demonstrates manufacturing → muster → deployment → battle → demobilization/loss. | PASS | Live zero-stock 3/3: manufacture, real muster, deployment, attacks, deaths/kit loss, physical return and ordinary work. |
| AC-40: All three civilizations exercise their doctrine and signature capability in verification. | PASS | Data all matrices/doctrine; Live all three manufacture/muster/fight/return; Behavior exact capability fixtures. |
| AC-41: Existing morale/retreat/elimination/capture semantics remain correct. | PASS | Mixed 3/3 retains surviving retreat, distinct elimination, continued fighting, peaceful capture block and secure capture. |
| AC-42: Survivors return to ordinary production after demobilization. | PASS | Live verifies each surviving committed citizen completes ordinary post-battle task. |
| AC-43: Final economy audit exactly includes military material consumption. | PASS | Live material tickets consumed once; armory/economy audits each tick; economic-armory summary reconciles 11 wood/11 metal. |
| AC-44: Identical fresh-process runs produce identical mobilization and combat fingerprints. | PASS | Replay 3/3 includes projects/tickets/kits, issue/muster, abilities, all attacks, casualties, loss/return/capture, final economy/armory. |
| AC-45: Relevant current RoomScale regression gates remain green. | PASS | Regression summary: Fast/Canonical/Regression, roles/conflict/pressure/extensibility/civilizations/innovation/live/POC54. |
| AC-46: Core military planning, armory, movement and combat contain no Clockwork/Verdant/Scavenger ID dispatch. | PASS | Manual and rg source audit: no Clockwork/Verdant/Scavenger IDs in doctrine, armory, readiness, abilities, governor or combat. |
| AC-47: Documentation records exact doctrine formula, equipment bills, capability rules, ownership boundaries and future extension seams. | PASS | docs/MILITARY_DOCTRINE_MOBILIZATION.md plus README/architecture/combat/testing updates; report documents adaptations and deferred scope. |
