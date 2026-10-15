# POC 5.4 implementation report

Branch: `codex/poc54-military-doctrine`. Base: accepted combat-role
`a46d8a5badac9c3699d6e700479ae6fcbffeb6e7`. Gameplay source freeze: `7621e2a`; final focused verification harness: `524e350`
(full SHAs in verification summaries). Documentation/evidence commits follow it.
Status: **PASS**; all 47 acceptance criteria are mapped in [acceptance-matrix.md](acceptance-matrix.md).

## What changed

War policy now requests readiness instead of assigning free combat roles. Generic
doctrine scores the approved role grades. Each society's ArmorySystem manufactures
persistent kits through EconomySystem reservations and native citizen work. Real
citizens reserve equipment, physically muster, receive a stable issued kit, deploy
through existing navigation, fight through the accepted CombatSystem and return
equipment after walking home. Terminal deaths lose kits without material refunds.

Clockwork uses Prepared Fire, Verdant uses Pathfinder Maneuvers and Scavenger uses
Jury-Rig Equipment through capability handlers. Optional role/equipment learned gates
resolve through existing InnovationRuntime. No military research tree, canonical
resource, separate material balance, soldier population or navigation graph was added.

Exact doctrine, equipment bills, capability rules, identity/ownership boundaries and
extension seams are in [the current architecture guide](../../docs/MILITARY_DOCTRINE_MOBILIZATION.md).
Combat-role baselines, grade modifiers and `max(1,damage-armor)` remain unchanged.

## Milestone progression

- M0: fetched current origin, selected the explicit accepted combat-role base,
  audited authorities, ran Fast, repeated roles/conflict and extensibility before edits.
  [baseline.md](baseline.md) records the evidence and preserved unrelated files.
- M1: shared catalog, doctrine formula, capability assignments and validation;
  exact approved composition fixtures passed before production integration (`886147d`).
- M2: atomic owned tickets, bounded projects, native production callbacks, stable kit
  creation, real interruption, crisis/concurrency limits and accounting fixtures.
- M3/M4: readiness, missing equipment and safe salvage; deterministic candidate
  preflight, real muster/issue, minimum-equipped deployment, cancellation and reuse.
- M5/M6: signature handlers, real Prepared Fire attack timestamps, legal cluttered
  route proof, physical returns, health preservation and terminal equipment loss.
- M7: actual zero-stock three-party production and battle with shared paid innovation,
  graphical capture/review and three fresh-process fingerprints.
- M8: current regression suites, documented fixture adaptations, source audit and
  curated summaries/matrix. Integrated implementation `b2bdb1d`; fixture/evidence
  refinements `9d34bf5`; deployment-gate/policy coverage `76d097c`; explicit
  completed-force reuse `7621e2a`; shorter-route Pathfinder proof `524e350`.

## Necessary adaptations

1. The original conflict-room finite metal could be consumed by ordinary settlement
   work before a society made a single kit. Four existing conflict rooms now author
   one visible **48-metal** tray: two real salvage stages, each 12 work seconds and
   24 metal. Salvage workers, bundles and ordinary hauling deliver it. No depot stock
   is granted; ordinary founder/single-civilization rooms keep their original budgets.
   Scarcity and protected-ticket fixtures still require economic failure when stock
   is insufficient. This preserves the existing restriction that construction material
   comes from salvage stages, rather than introducing a metal-extraction subsystem.
2. Existing tactical fixtures explicitly author initially issued assets in test code.
   The pressure fixture authors stocked assets for the scarce pair before any steps,
   then uses real muster. This isolates policy/role assertions from affordability.
   Its original 450-second window and all fight/peaceful-exclusion/capture assertions
   remain. It also validates newly admitted peaceful citizens without assuming the
   initial roster can never grow. **Live** conflict tests assert zero initial military
   stock, one paid completed native-work project per kit, correct loss/return states
   and every survivor completing ordinary post-battle work. There is no free gameplay
   equipment branch.
3. Role-cycle timing assertions now use the actual previous attack's effective
   interval, including Prepared Fire, rather than pretending capability bonuses do
   not exist. Five-role and mixed-policy assertions remain enabled.
4. A legacy governor fixture has no military service. The governor explicitly handles
   that existing non-military fixture, preserving all previous survival/development
   assertions. Real society runtimes always own the armory/readiness services.
5. Return duty targets the existing depot, where equipment is actually stored, before
   ordinary production resumes. Reserved unissued kits can be released immediately;
   issued kits require physical return. Health fraction remains unchanged.
6. Close graphical review exposed oversized home labels obscuring readiness views.
   Home labels now hide at close camera distances, as objective labels already did.
   Citizen selection explicitly shows inspection during conflict. No final art work
   or military management UI was added.

## Verification

Pinned Godot 4.7.2, PowerShell process isolation/timeout/error/pass-marker conventions,
and `.venv/Scripts/python.exe` were used. Raw runs remain ignored under
`verification/stabilization/runs/poc54-final/`; selected outputs accompany this report.

| Gate | Result |
|---|---|
| Fast | PASS; includes original contracts, 14 Python tooling tests, Ruff and new military data validation |
| Canonical | PASS; 3 identical fresh founder runs |
| Regression | PASS; POC4/45/46, seven-day sustained, Room A/B full production smoke, navigation/unreachable/midlink/placement and 20/20 exploration scenarios; zero invariant violations/deadlocks |
| Combat roles | PASS; 3 identical processes, five-role movement/grade/identity/cycle contracts retained |
| Ordinary conflict | PASS; 3 identical processes, Clockwork capture tick 2255 |
| Room B conflict | PASS; 2 identical processes, Clockwork capture tick 3245 |
| Conflict pressure | PASS; original bilateral/peaceful-third coverage with explicit prepared asset fixture |
| Extensibility | PASS; innovation and mixed-policy combat each 3 identical processes |
| Civilizations | PASS; definition and real Verdant presentation/authority contracts |
| Innovation foundation/robustness | PASS |
| Innovation live | PASS; all three civilizations, twice each |
| POC54 data/armory/behavior | PASS; production and behavior each 3 identical fresh processes, graphical first behavior run |
| Zero-stock POC54 live three-party + innovation | PASS; 3 identical processes, graphical evidence |

The final POC54 live campaign, Fast, Canonical and role replays cover the gameplay
freeze. Ordinary/Room B conflict, policy and historical production gates also passed;
the later explicit completed-force remobilization transition has dedicated fresh-process
reuse coverage. The final harness-only Pathfinder refinement was reverified three
times, including graphics, and changes no gameplay source. Optional Robustness/90–60–60-day Soak modes are not claimed.

## Economic, physical and deterministic results

The live scenario starts with **zero kits/projects** in three twelve-citizen societies.
Each manufactures two kits and physically equips two citizens, satisfying the policy
minimum of two inside the authorized maximum of three. Desired doctrine remains the
specified size-three result; there are no mid-battle reinforcements.

- Clockwork: normal Artillery + Heavy, 3 wood / 7 metal / 30 citizen work seconds.
- Verdant: normal Skirmisher + Line, 2 wood / 2 metal / 12 citizen work seconds.
- Scavenger: jury-rigged Heavy + Line, 6 wood / 2 metal / 22.5 citizen work seconds.

Military totals: **11 wood, 11 metal, 64.5 citizen work seconds**. All material
consumption occurs through owned EconomySystem tickets. Four kits physically return
to STOCKED; two casualty kits remain LOST. Clockwork wins after 21 attacks and
captures at tick 4339. Casualties: Clockwork 0, Verdant 1, Scavenger 1. Returned
survivors: 2/1/1 respectively. Each survivor completes ordinary production afterward.
The all-attack digest is
`c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2`.

Replay comparison includes desired doctrine, reservation ticket IDs, project order,
stable kit IDs, muster/citizen/issue mappings, capability events, every-attack digest,
casualties, retreat/elimination/capture and final armory/economy snapshots. The
focused behavior fixture additionally proves cancellation, asset reuse and retained
health fraction; native production rejects forged work and resumes after urgent care.
Prepared Fire records 11-tick Ranged and 30-tick Artillery prepared cadences under
the existing fixed clock. Pathfinder compares all seven real legal route lengths,
retains baseline navigation/speed and physically walks the chosen route.

## Visual evidence and limitations

Actual graphical Godot captures were inspected for equipment production/readiness,
walking muster, equipped predeployment forces, Prepared Fire state/effective cycle,
Scavenger jury-rig variant, live mixed combat, capture and survivor return/work.
The cluttered Pathfinder fixture shows the selected legal route over real room
geometry before/after physical movement. Original PNG hashes are in the visual manifest.
Functional placeholder equipment and miniature overview labels remain; closer views
are used for kit/stat inspection. Test route markers are presentation-only evidence.

Minimum-equipped deployment can field fewer citizens than the ideal maximum. Some
finite worlds may legitimately remain blocked; no emergency resources are supplied.
Projects use the existing depot/workshop and one worker at a time per project; this
does not model transport of individual manufactured kits between buildings. Kit
issue is the physical transfer at the depot. The existing one-encounter world and
cooldown remain; focused remobilization proves reuse without adding a campaign AI.

Deferred: military research tree, tactical control, standing professional soldiers,
counter matrices, ammunition, upkeep, durability/repair, wounds/medics, officers,
veterancy, prisoners, pursuit, suppression, cover, fortification construction,
battlefield salvage, captured equipment/technology, diplomacy, treaties and trade.

All intentional source/documentation/evidence are committed and pushed on the
milestone branch. Main is not merged. Pre-existing unrelated untracked plans, UID
files and poc51 visuals are preserved.
