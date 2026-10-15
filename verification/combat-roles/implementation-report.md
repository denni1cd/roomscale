# Combat roles implementation and verification report

Date: 2026-10-15. Branch: `codex/combat-roles`, based on current fetched main
`16d9e9f`. Executable source freeze: `bca5c6a8603d3a394e0ff4573d4bed4a8111ec62`.
Overall acceptance: **PASS, all 28 criteria**; see [acceptance-matrix.md](acceptance-matrix.md).

## Implementation

M0 audited current code and documentation before edits; [baseline.md](baseline.md)
records original green gates and authority boundaries. M1 added shared validated
role/grade definitions and all three approved civilization matrices, committed as
`e7556dc` after 136 focused assertions. M2/M3 attached loadouts to existing citizens,
added armor damage and real per-role movement, and exercised controlled role slices.
M4/M5 integrated mixed forces and all three actual profiles, followed by M6 fresh
process replay and current regression campaigns. `a795241` records that integrated
slice; M7 inspection/image review found and fixed health-bar draw order in `bca5c6a`.
Documentation/evidence commits follow the executable freeze.

CombatSystem remains the battle authority. CitizenAgent retains persistent identity,
terminal life state, work and motion. FloorNavigation retains physical geometry,
legal connectors and A*. TerritorySystem retains bilateral hostility and site hold.
Innovation, production, materials, construction and population remain their existing
authorities. There is no duplicate simulation and no faction-ID dispatch in combat.

Damage is `max(1, attacker_damage - defender_armor)`, without RNG. Exact role stats,
modifiers, faction matrices and target priorities are in
[COMBAT_ROLES.md](../../docs/COMBAT_ROLES.md). Great/Good/Neutral/Bad multiply only
Line/Heavy health or Ranged/Artillery/Skirmisher damage by 1.20/1.10/1.00/0.85.
Grade assays apply actual damage to real CitizenAgents and verify ordered survival
capacity or damage-per-cycle under the shared armor formula, not just UI labels.

Line closes and screens rear threats; Heavy advances more slowly and absorbs damage;
Ranged restores range; Artillery starts rearward and fires on a slow cycle;
Skirmishers seek vulnerable targets and flank/withdraw more frequently. All movement
uses physical waypoints, and each citizen's actual speed is checked every observed
tick. Survivors remove equipment after walking home and finish ordinary production.

## Necessary architecture adaptations and assertion replacements

1. Precise melee endpoints are smaller than the existing four-inch grid. A short
   route query in **existing FloorNavigation** uses the same segment/obstacle/bounds
   tests and falls back to its ordinary A*. CitizenAgent performs all motion. Ordinary
   march/return routing keeps the existing legacy activity-endpoint contract.
2. Morale retains weights and policy, but normalizes health by loadout maximum.
   Otherwise healthy Heavy citizens would get an unintended bonus from HP >100.
3. The six-inch site-presence rule stays distinct from weapon range. Withdrawn
   citizens clear max(6, own range), and a real surviving capturer walks to the site.
   This prevents rear support or a stale maneuver route from stalling capture.
4. Old universal 0.65001-inch movement assertions were superseded by Skirmisher's
   required 0.8775-inch fixed-tick movement. **Stronger replacement:** every actor
   is checked against its own role speed, plus an absolute maximum safety bound.
5. The old mixed-policy fixture assumed Clockwork elimination happened before the
   limited party's withdrawal. New roles legitimately reverse those timings. It
   now requires fighting after the first departure, retains all original policy,
   casualty, survivor, peaceful-pair and capture assertions, and adds a separate
   **three-survival-party fixture requiring real attacks after the first elimination,
   two distinct eliminations, and legitimate capture**. No regression was bypassed.
6. Graphical review found facing-dependent health-fill occlusion. Explicit billboard
   draw order fixes it; warning color now uses health fraction. Real renderer
   captures and three fresh role processes were repeated after that fix.

## Verification commands and outcomes

All commands use the repository's timeout/error/pass-marker conventions and pinned
Godot 4.7.2. Python quality uses `.venv/Scripts/python.exe`. Commands below passed
unless explicitly pending. Raw output prefix is
`verification/stabilization/runs/combat-roles-final/`.

| Command | Result / evidence |
|---|---|
| `TEST_ROOM_SCALE.ps1 -Mode Fast` | PASS: Ruff, 14 tooling tests, schemas, founders, evidence/core, combat roles, navigation/unreachable/midlink/placement |
| `TEST_ROOM_SCALE.ps1 -Mode Canonical` | PASS: three identical fresh founder runs, canonical repeatability marker |
| `TEST_ROOM_SCALE.ps1 -Mode Regression` | PASS: POC4/45/46, seven-day sustained, Room A/B full production smoke, focused navigation/placement, and 20/20 final exploration scenarios; zero invariant violations/deadlocks |
| `TEST_ROOM_SCALE_COMBAT_ROLES.ps1 -RunCount 3 -CaptureVisuals` | PASS: 136 stats assertions; 131204 behavior/identity/economy/speed/return assertions in graphical first run; three identical observations |
| `TEST_ROOM_SCALE_CONFLICT.ps1 -RunCount 3` | PASS 3/3 identical: Verdant, capture tick 1641 |
| `TEST_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_c -Scenario three_party_conflict -Innovation -RunCount 3` | PASS 3/3 identical: Verdant, capture tick 2005; real paid shared innovation route/use preserved |
| `TEST_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_b -RunCount 2` | PASS 2/2 identical: Verdant, capture tick 2013 |
| `TEST_ROOM_SCALE_EXTENSIBILITY.ps1 -RunCount 3` | PASS 3/3 each: innovation extensibility and strengthened mixed-policy combat |
| `TEST_ROOM_SCALE_CONFLICT_PRESSURE.ps1` | PASS existing pressure contracts |
| `TEST_ROOM_SCALE_CIVILIZATIONS.ps1` | PASS definition contracts and existing Verdant real-scene presentation ownership |
| `TEST_ROOM_SCALE_INNOVATION.ps1` | PASS foundation and robustness |
| `TEST_ROOM_SCALE_INNOVATION_LIVE.ps1` | PASS all three civilizations, two fresh processes each |
| `git diff --check` | PASS after removing an extra test-file EOF blank line |

Fast/Canonical/Regression ran against the role gameplay source; the final subsequent
executable change is cosmetic health-bar sorting/color only. Final role graphics and
replays cover that change. No gameplay edit followed the final conflict replay runs.

## Mixed-force and determinism evidence

The all-role fixture commits fifteen **existing** citizens, five per civilization,
with actual profile grades. All five roles perform attacks. Scavenger wins after 96
attacks, capturing at tick 875. Casualties: Clockwork 4, Verdant 4, Scavenger 3.
Clockwork and Verdant withdraw with living survivors. All four survivors physically
return and complete ordinary tasks. Maximum observed step is 0.877502 inches,
within per-role tolerance. The complete repeated attack digest is
`548f6d95034facb443e24899cfc40bc0e97290c182383530d12da4368ff6ba6b`.

[role-verification-summary.json](role-verification-summary.json) preserves the full
commitment/loadout set, live grade assays, movement observations and battle outcome.
[conflict-replay-summary.json](conflict-replay-summary.json) preserves ordinary and
three-party production replay fingerprints. These include committed IDs/roles,
attack tick/attacker/target/damage/role order, casualties, retreats/eliminations,
winner, secure capture and returns. Every attack is folded into the digest; the
first 256 diagnostic events are bounded separately. Given the same initial citizen
health, identical ordered damage also fixes casualty identity and order. Mixed-policy
receipts include explicit elimination-event identity/timing and reversed-order proofs.

## Visual inspection

Launched actual graphical Godot through existing process/capture conventions and
inspected captures directly. [visual-manifest.json](visual-manifest.json) lists 17
selected original PNGs with SHA-256 hashes. Reviewed matched one-second Line/Heavy
positions (Heavy visibly farther from the target), Line reaching melee, Ranged
withdrawal, Artillery's rear displacement, Skirmisher flanking/repositioning, mixed
formation/fighting/return, equipment differences and live inspection values.
Close-ups verify role labels, shields/armor, larger Artillery, scaled weapons and
normalized health bars. Existing society identity assets are retained. Overviews
remain miniature and labels are small at whole-battle scale; close inspection is
the supported verification view. These are functional placeholders, not final art.

## Limits and next-round work

Composition is a deterministic cycle or authored list, not a military optimizer.
Default three-citizen limited forces use the first three roles; the dedicated
verification battle demonstrates all five. Movement has bounded alternatives and
can report BLOCKED; it does not promise globally optimal tactics, collision-free
formations or pursuit. Initiative still favors low citizen IDs. Balance perfection
and arbitrary room layouts are not claimed. The campaign verifies relevant current
gates; optional Robustness and 90/60/60-day Soak modes were not rerun for this scope.

Implementation IDs and inert capability lists reserve extension seams. Future
technology gates should use existing innovation authority; equipment costs should
use existing economy reservations. Abilities, diplomacy/trade, suppression, wounds,
medics, officers, veterancy, prisoners, pursuit, fortifications, equipment industry,
battlefield salvage and captured technology remain deferred, as requested.

All intentional changes/evidence are committed on the milestone branch. Pre-existing
untracked plans, two UID files and poc51 visual evidence are preserved untouched;
they are not new milestone residue. Nothing was pushed or merged into main.
