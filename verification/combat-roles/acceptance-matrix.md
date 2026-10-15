# Combat-role acceptance matrix

Verification date: 2026-10-15. Executable source: `bca5c6a8603d3a394e0ff4573d4bed4a8111ec62`.
The preceding `a795241` contains identical gameplay; bca5c6a fixes health-bar
presentation and was reverified with three fresh role processes including graphics.
All receipts use pinned Godot 4.7.2. Report/source boundaries are explicit; generated
logs remain under `verification/stabilization/runs/combat-roles-final/`.

Evidence keys:

- **S**: `scripts/combat_roles_test.gd`, 136 passing focused assertions; Fast log
  `fast/combat_roles_test.log`. Exact source stats/profile contract and armor formula.
- **B**: [role-verification-summary.json](role-verification-summary.json), actual
  scene targeting/navigation fixtures, real CitizenAgent grade/mortality assays,
  per-role movement and fifteen-citizen all-role three-party battle. Three identical
  fresh-process observations, first using the real graphical renderer.
- **C**: [conflict-replay-summary.json](conflict-replay-summary.json), ordinary
  conflict (3), innovation-enabled three-party conflict (3), Room B (2), with
  committed IDs/loadouts and all-attack ordering fingerprints.
- **M**: [mixed-policy-summary.json](mixed-policy-summary.json), three identical
  fresh processes; includes reversed runtime/participant order, limited survivor
  withdrawal, survival elimination, peaceful-pair exclusion, peaceful-claim capture
  block, elimination-only capture, and continued attacks after first elimination.
- **V**: [visual-manifest.json](visual-manifest.json), 17 deliberately selected
  actual-game PNGs, inspected directly. Includes matched one-second Line/Heavy
  images, withdrawal and flanking positions, close equipment/inspection views,
  mixed formation/fighting and return.
- **R**: [implementation-report.md](implementation-report.md), exact command list,
  regression receipts, source freeze and documented assertion replacements.
- **D**: [COMBAT_ROLES.md](../../docs/COMBAT_ROLES.md), architecture, exact modifiers,
  behavior, validation, composition and future extension seams.

| Criterion | Result | Evidence |
|---|---|---|
| AC-01 Five generic roles | PASS | S; B.mixed.fire_roles includes all five |
| AC-02 Validated baseline stats | PASS | S validates all six exact baseline stats per role, invalid/nonfinite data |
| AC-03 Deterministic armor-aware damage | PASS | S minimum/armor/Artillery/survival tests; B.grades real mortality |
| AC-04 Three civilizations implement five roles | PASS | S exact definitions; B.mixed.commitments has 15 real assignments |
| AC-05 Clockwork matrix | PASS | S; B.mixed.commitments, D exact resolved stats |
| AC-06 Verdant matrix | PASS | S; B.mixed.commitments, D exact resolved stats |
| AC-07 Scavenger matrix | PASS | S; B.mixed.commitments, D exact resolved stats |
| AC-08 Exactly 1/1/2/1 grades | PASS | S validates every profile and rejects malformed distributions |
| AC-09 Shared data grade effects | PASS | S monotonic stats; B.grades live damage/health/armor assays; shared QUALITY/QUALITY_STAT data |
| AC-10 Persistent citizen identity | PASS | B checks every committed citizen object/ID each tick; C retains terminal citizen nodes |
| AC-11 Mixed simultaneous force | PASS | B five distinct roles on each of three sides |
| AC-12 Line closes/melee | PASS | B.line final gap 0.5; B.mixed SCREEN/MELEE and actual attacks; V Line images |
| AC-13 Ranged preserves range | PASS | B.ranged restores gap 1.5 to 5.5; B.mixed WITHDRAW; V before/after |
| AC-14 Heavy slow durable assault | PASS | B.heavy 4.55 in/s, 0.5 final gap; B.grades survival; B.mixed MELEE; V one-second comparison |
| AC-15 Artillery rear/range/slow cycle | PASS | B.artillery restores gap 1.5 to 12 at 3.575 in/s; B.mixed support/withdraw/attacks and cycle assertions; V |
| AC-16 Skirmisher mobility/reposition | PASS | B.skirmisher 8.775 in/s, FLANK/ADVANCE; B.mixed WITHDRAW/FLANK; V |
| AC-17 Deterministic role targets | PASS | B direct threat/vulnerability/range/ID/peace tests; C/M/B fresh replay equality |
| AC-18 Mixed casualties affect morale | PASS | B.mixed two survivor retreats after mixed losses; M mixed intensity with unchanged policy assertions |
| AC-19 Elimination distinct from retreat | PASS | M terminal elimination events/idempotence/no survival morale retreat; three_survival has two eliminations |
| AC-20 Physical uncontested capture | PASS | C checks no premature ownership; M peaceful claimant block and elimination capture; B mixed capture |
| AC-21 Survivors return to production | PASS | B and C require each surviving committed citizen to finish ordinary post-battle work |
| AC-22 Existing navigation/no teleports | PASS | B/C/M per-actor speed bounds; B obstacle/bounds/height rejection; existing navigation regressions R |
| AC-23 Role/stat inspection | PASS | B diagnostics contract; V role detail images show instance, role/grade, HP, armor, damage, range, cycle, movement, state |
| AC-24 All three pass combat | PASS | B all-role three-party and C innovation-enabled three-party replays |
| AC-25 Identical fresh replays | PASS | B 3/3; C 3/3 + 3/3 + 2/2; M 3/3. Every attack contributes to digest including attacker, target, tick, damage, role |
| AC-26 Relevant regression gates green | PASS | R: full Fast, Canonical, Regression including 20/20 exploration scenarios, conflict/pressure and innovation gates |
| AC-27 No civilization-ID combat branches | PASS | Manual source review of CombatSystem/CombatRoles: behavior dispatch only; faction matrices in JSON |
| AC-28 Future extension boundaries | PASS | D roles/implementations/capabilities/innovation/equipment authorities, with deferred mechanics explicit |
