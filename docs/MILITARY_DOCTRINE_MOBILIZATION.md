# POC 5.4 — Military doctrine and mobilization

War now requires persistent equipment assets manufactured with finite materials and
real citizen labor. The five combat roles, grades, armor formula and battle authority
remain the accepted combat-role implementation. No military technology tree is added.

## Authority and doctrine

Conflict pressure and bilateral per-side policy still authorize war, maximum force
size, minimum commitment and retreat. `MilitaryReadiness` consumes that authorization;
it does not invent hostility. `MilitaryDoctrine` selects roles inside the existing
size rule: `min(max_force, max(min_force, ceil(living_population * force_fraction)))`.

Select one slot at a time with:

`score = grade_weight - 1.25 * already_selected_count_for_role + coverage_bonus`

Grade weights: Great 4, Good 3, Neutral 2, Bad 1. If no Line/Heavy exists, those roles
receive +1.5. If no Ranged/Artillery/Skirmisher exists, those roles receive +1.0.
Exact ties use Line, Ranged, Heavy, Artillery, Skirmisher order. Recompute after
every slot. Full availability and size three produce:

| Civilization | Doctrine |
|---|---|
| Clockwork | Artillery / Heavy / Ranged |
| Verdant | Skirmisher / Line / Ranged |
| Scavenger | Heavy / Line / Artillery |

These results emerge from profile data. There is no faction-ID branch or opponent
counter matrix. The desired plan considers all valid learned-gate-permitted roles;
the equipped plan scores only finished available stock and can fall back to other
equipped roles. Deployment waits below the policy minimum. It can accept fewer
than the desired maximum once the minimum is equipped; no reinforcement follows.

## Equipment and production

Each society owns one `ArmorySystem`, its projects, stable kit IDs, state transitions
and EconomySystem reservation tickets. Equipment is an asset, **not** a new canonical
ResourceVocabulary material. EconomySystem alone owns all material balances.
Every reservation mutation (`pickup`, `deliver`, `consume`, `release`, `drop`,
`recover_delivered`) requires an exact expected owner at the ledger boundary.
Unknown tickets, wrong owners and illegal states fail without ledger changes.
Armory project ownership preflight remains in place as an additional check.

| Equipment | Role | Wood | Metal | Citizen work |
|---|---|---:|---:|---:|
| line_kit | Line | 1 | 1 | 6s |
| ranged_kit | Ranged | 1 | 1 | 8s |
| heavy_kit | Heavy | 1 | 3 | 12s |
| artillery_kit | Artillery | 2 | 4 | 18s |
| skirmisher_kit | Skirmisher | 1 | 1 | 6s |

`military_catalog.gd` defines and validates equipment, prerequisites and capability
IDs. Civilization role entries select an economic `equipment` family separately
from their existing combat/presentation `implementation` ID. The family must match
the role. Additional same-role equipment families can extend the catalog without
faction dispatch. Baseline recipes require no mechanical_parts or innovation.

On each five-second governor evaluation, readiness can order at most one missing
kit, with no more than two active equipment projects per society. Active survival
crisis blocks new orders. Peacetime has no standing-army target. Military shortage
joins existing safe-salvage reasoning; earlier construction/innovation reservations
remain protected because only available stock can be reserved.

An order preflights its complete bill, reserves every material through EconomySystem
atomically (releasing its own partial reservation if necessary), and exposes an
`ARMORY_BUILD` production option at the society depot. Existing TaskCoordinator
claims the job for an owned citizen. Work occurs only inside the native CitizenAgent
WORK callback: real living owner, matching active task, depot proximity, finite
effort bounded by the fixed step, and at most once per actor/tick. Urgent self-care
interrupts normally; the project and its reserved bill remain available to a later
worker. Pause/wall-clock time alone never manufactures a kit.

Completion consumes the project tickets once and creates one kit. Repeated completion
cannot duplicate it. Started projects may finish after hostility ends; their kits
remain owned and no material refund is generated. The governor neither works nor
moves actors nor modifies material stock directly. New discretionary development
waits while readiness is active; existing paid projects keep their reservations.

Project IDs are `<instance>:equipment:<order number>`; kit IDs are
`<instance>:kit:<completion number>`. Both sequences are deterministic.

## Physical muster and asset lifecycle

The live sequence is:

`hostility → doctrine/readiness → manufacture → select/reserve → MUSTER → issue → deploy → battle → physical return/loss`

When finished kits meet the minimum, readiness scores the available composition,
selects real eligible citizens by existing objective-distance/citizen-ID order, and
preflights their normal navigation paths to the depot. An unreachable candidate is
skipped deterministically before any task/kit commitment. Selected kits become
RESERVED before citizens receive MUSTER duty. Citizens walk at ordinary speed before
equipment issue. Their pending role/kit can be inspected without granting a loadout.

Only arrival at the depot (within 0.1 inch with actual route arrival) permits issue.
The kit becomes ISSUED to that persistent CitizenAgent and its accepted role stats
are attached, preserving health fraction. Every accepted member must be issued and
physically assembled before readiness becomes READY. CombatSystem then preflights
existing legal battle stations and starts the deployment march. It refuses missing,
unissued or incorrectly owned equipment; no free gameplay loadout path remains.

| Kit state | Meaning |
|---|---|
| STOCKED | Finished, owned, reusable at the depot |
| RESERVED | Allocated to a specific mustering citizen, not yet issued |
| ISSUED | Carried by that real living citizen through deployment, battle and withdrawal |
| LOST | Issued citizen died; terminal loss with no refund or automatic recovery |

If authorization disappears before deployment, unissued reservations return to
stock; issued citizens physically return to the depot before their kits return.
Manufactured equipment remains owned. After battle, surviving citizens likewise
walk home to the depot before returning equipment, removing their role and resuming
ordinary production. Health fraction persists. Terminal citizens retain their IDs
and nodes; their kits stay LOST. No ammunition, durability, repairs or salvage system
is introduced.

## Signature capabilities

Civilization definitions assign one capability each through `combat.capabilities`.
Core handlers dispatch on capability properties/IDs, never civilization IDs. Unknown
capabilities and malformed role/equipment gates fail validation.

### PREPARED_FIRE

Clockwork Ranged and Artillery become PREPARED after 2.0 continuous fixed-clock
seconds within 0.25 inch of their preparation anchor. Displacement beyond tolerance
clears preparation immediately and starts a new anchor/timer. While prepared, the
attack interval alone is multiplied by 0.85: Ranged 1.2 → 1.02s; Artillery 3.5 →
2.975s. No loadout stat/grade changes. Actual cooldowns are scheduled when an attack
fires and resolve on 0.1-second ticks (11 and 30 ticks respectively for subsequent
stationary prepared attacks). A cooldown already scheduled before preparation is
not retroactively shortened. Diagnostics expose prepared state and effective cycle.

### PATHFINDER_MANEUVERS

Verdant tactical endpoint selection evaluates direct, +30°, -30°, +60°, -60°,
+90°, -90°. Each route is requested from existing FloorNavigation, including its
same bounds, floor, obstacle/segment and A* rules. Choose shortest **real route
length**, including the connector from the current position; exact numeric ties
keep candidate order. Ordinary societies retain direct/+45°/-45°, first legal.
Speed and traversal restrictions are unchanged. Its benefit depends on clutter;
it provides no cover bonus or separate navigation graph.

### JURY_RIG_EQUIPMENT

Scavenger always uses the normal bill when affordable. Only a normal **metal**
shortage permits replacing at most one metal with two wood, multiplying work by
1.25. Other resource shortages do not trigger substitution. Substituted tickets are
reserved and consumed normally; finished stats remain the accepted role/grade stats.
The kit records variant `jury_rigged`.

| Example | Normal | Jury-rigged |
|---|---|---|
| Heavy | 1 wood + 3 metal / 12s | 3 wood + 2 metal / 15s |
| Ranged | 1 wood + 1 metal / 8s | 3 wood + 0 metal / 10s |

Food, water and mechanical_parts are never substituted by this capability.

## Learned gates and diagnostics

Role and equipment definitions may declare `requires` containing existing innovation
capability IDs. Planning, manufacturing and issue resolve those requirements through
the society's InnovationRuntime resolver, including capability implications. Without
a learned requirement they remain currently available. Missing capability excludes
the option. A synthetic fixture demonstrates blocked/unlocked roles and equipment
using the existing STEAM_POWER → POWER_SOURCE implication. No military technologies,
research problems or tech-tree UI were authored.

Conflict HUD shows doctrine, missing equipment, stocked kits, active projects,
readiness state, blocker and signature capability. Click a mustering/equipped citizen
for kit ID, production variant, role/grade, stats, duty and Prepared Fire. World labels
hide in close views to preserve readable inspection. Meaningful orders, readiness,
muster, issue, capability transitions, deployment, returns and losses are journaled;
identical blocked-order messages use existing suppression.

## Verification and scenario adaptation

Run `./TEST_ROOM_SCALE_POC54.ps1 -RunCount 3 -CaptureVisuals`. It covers data,
real production/interruption/accounting, scarce recipes, synthetic capabilities,
physical muster/cancellation/reuse, actual prepared attack timestamps, legal cluttered
Pathfinder movement, and a zero-kit three-civilization live battle with paid shared
innovation. Fresh-process fingerprints include all armory events, project/ticket/kit
IDs, citizen mappings, capability transitions, every-attack digest, casualties,
departures, capture and final economy/armory snapshots. Fast includes data contracts.

Focused tactical/policy fixtures may author initial prepared assets explicitly in
test code. Live conflict drivers assert zero starting military stock and never import
the prepared-armory fixture. They require exactly one completed, paid, citizen-worked
project per kit, audited issue/loss/return state, and each survivor completing real
post-battle production. Tactical cycle assertions use actual capability-adjusted
attack intervals rather than disabling their timing checks.

Conflict rooms now contain an explicit visible 48-metal tray in two salvage stages
(12 seconds/24 metal each). The previous finite budget could be exhausted by ordinary
settlements before equipment production. This is shared authored room supply worked
through existing salvage/haul accounting, not a depot grant or hidden military pool.
Ordinary founder/single-civilization rooms retain their original supplies. Scarcity
fixtures still verify failure with insufficient stock and protected reservations.

The [POC 5.4 report](../verification/poc54/implementation-report.md) records exact
gates, adaptations, visual review and the 47-criterion acceptance matrix. Composition
is reactive and bounded. One existing encounter and cooldown remain; this adds no
autonomous recurring campaign, tactical control, standing soldiers, opponent counter
matrix, upkeep, ammo, durability, wounds, medics, officers, veterancy, pursuit,
prisoners, fortifications, diplomacy/trade, salvage or captured technology. Balance
perfection and globally optimal formation/path selection are not claimed.

## Pre-merge hardening

Prepared Fire update, interval calculation and citizen inspection consume the
canonical PREPARED_FIRE catalog definition; its roles, duration, tolerance and
multiplier have one production source. Focused verification also uses an isolated
synthetic definition without modifying approved catalog values.

If the ordinary depot return route is unavailable, CitizenAgent retains RETREAT
duty with inspectable `RETURN_BLOCKED` state and `combat_arrived = false`. It stops
its previous route and retains the issued kit. Each native simulation step makes
at most one retry through existing FloorNavigation. Existing geometry-triggered
replanning preserves military duty and applies the same return failure handling.
A permanently unavailable route remains blocked; no kit is stocked until actual
depot arrival. Cancellation, stand-down, morale retreat and post-victory return all
use this shared path. No alternate navigation or resource recovery is introduced.
