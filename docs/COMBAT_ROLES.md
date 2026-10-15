# Citizen combat roles

The combat-role milestone extends POC 5/5.3. WorldSimulation still owns the fixed
0.1-second clock and shared CombatSystem. Citizens remain the original persistent
CitizenAgents, with globally append-only IDs. Equipment is a temporary assignment;
there is no military entity population, second movement system or parallel battle.

## Exact neutral stats

Distances are inches; cycle is seconds; movement multiplies the citizen's 6.5 in/s.

| Role | Health | Armor | Damage | Cycle | Range | Movement |
|---|---:|---:|---:|---:|---:|---:|
| Line | 120 | 3 | 18 | 1.0 | 0.6 | 1.00 |
| Ranged | 90 | 1 | 14 | 1.2 | 7 | 1.00 |
| Heavy | 180 | 8 | 24 | 1.5 | 0.6 | 0.70 |
| Artillery | 80 | 0 | 45 | 3.5 | 15 | 0.55 |
| Skirmisher | 80 | 0 | 11 | 0.9 | 5 | 1.35 |

`damage_taken = max(1, attacker.damage - defender.armor)`. Valid attacks hit.
No RNG, criticals, penetration or status effects. Attack cooldowns use the fixed
simulation clock, starting at the actual attack; ticks can round a cycle upward.
Actors resolve in global citizen-ID order and morale is checked after every attack.

`combat_roles.gd` contains the shared catalog, validation and grade data. Great is
1.20, Good 1.10, Neutral 1.00, Bad 0.85. **Only health** changes for Line/Heavy;
**only damage** changes for Ranged/Artillery/Skirmisher. Armor, range, cycle and
movement never change with grade. This intentionally chooses a single relevant
effectiveness axis rather than stacking multiple bonuses. Damage after armor and
integer hits-to-death can make realized advantages differ from the nominal percent.

| Civilization | Line | Ranged | Heavy | Artillery | Skirmisher |
|---|---|---|---|---|---|
| Clockwork | Bad | Good | Neutral | Great | Neutral |
| Verdant | Neutral | Good | Bad | Neutral | Great |
| Scavenger | Good | Bad | Great | Neutral | Neutral |

The exact changed stats are Clockwork Line HP 102, Ranged damage 15.4, Artillery
damage 54; Verdant Ranged damage 15.4, Heavy HP 153, Skirmisher damage 13.2;
Scavenger Line HP 132, Ranged damage 11.9, Heavy HP 216. Other stats are neutral.
Loaders reject missing roles/implementations, unknown grades and distributions
other than one Great, one Good, two Neutral and one Bad.

## Commitment and identity

Existing bilateral pressure and per-side war policies determine force size. No
mid-battle conscription occurs. Eligible citizens retain the existing distance/ID
selection order. Their roles cycle through Line, Ranged, Heavy, Artillery,
Skirmisher. Smaller forces use the corresponding prefix; the default three-citizen
limited force does not demonstrate all five roles. A policy can author `roles`,
or a civilization can declare optional `combat.composition`; the list cycles to
fill the already-authorized size. These lists are validated, not army optimizers.
The focused all-role battle authors five citizens per side, with all three actual
civilization profiles, through the production commitment API.

Each civilization's `combat.roles` supplies a grade and an implementation ID per
role. CombatSystem snapshots the resolved loadout and original ID at commitment.
CitizenAgent owns `combat_role`, `combat_stats`, health, maximum health, duty,
positioning state and its ordinary waypoint traversal. Equipment changes preserve
health fraction. Returning survivors remove the assignment and restore ordinary
movement, retaining their health fraction; there is no healing mechanic. Death
remains terminal and keeps the same node/ID, with no work or population recycling.

## Deterministic behavior and targeting

Targets must be living, committed bilateral hostiles that have not departed.
An out-of-range candidate must have a legal floor route. Priorities below sort
first, then distance squared, then citizen ID. Within-range attacks use the first
candidate from that order that is actually in the attacker's range. Civilians and
peaceful parties are excluded.

| Behavior | Priority | Positioning |
|---|---|---|
| Line / screen | Enemy within 3 inches of friendly Ranged or Artillery before other enemies | Close to 0.5 inch, intercept rear threats; decide every 1s |
| Heavy / assault | Already in melee; vulnerable armor <=1 within 3 inches; other enemies | Close to 0.5 inch at 0.70x, decide every 1s |
| Ranged | In-range candidates before out-of-range | Approach to 5.5 inches; withdraw when nearest enemy is within 3.575 inches; decide every 1s |
| Artillery / support | In-range candidates before out-of-range | Start 8 inches farther rearward, approach to 12 inches only if needed; withdraw below 7.8 inches; decide every 2s |
| Skirmisher / harass | Vulnerable armor <=1 before armored targets | Approach to 4 inches, withdraw below 2.6 inches, otherwise flank by 2 inches; decide every 0.7s |

Ranged starts 4 inches farther rearward. Formation stations are preflighted before
any task mutation; bounded deterministic alternatives resolve occupied cells.
The sign of Skirmisher flank movement follows citizen-ID parity. When a desired
endpoint is blocked, try +45 then -45 degrees in that fixed order. If none is legal,
record BLOCKED and retain the prior legal route. There is no tactical player control,
collision avoidance, pursuit, cover system or optimal formation planner.

Maneuvers call FloorNavigation's `combat_path_between`: it checks the same physical
room bounds, floor height, obstacle rectangles and segment intersection authority.
A clear short segment uses its precise endpoint; obstructed movement falls back to
the existing A* path. This is necessary because melee is smaller than the four-inch
grid. CitizenAgent still walks every waypoint with the assigned speed. March and
return preserve the existing ordinary route contract, including legacy activity
endpoints. No teleportation or alternate collision geometry is introduced.

## Morale and resolution

Force-level morale retains its casualty/disadvantage/health weights and per-side
retreat policies. Health contribution now uses each survivor's health/max-health
fraction, avoiding a hidden Heavy morale bonus. Survival war still forbids ordinary
retreat. Elimination is terminal loss of the whole committed force, distinct from
a withdrawal with living survivors. Remaining hostile parties continue fighting.

The winner sends its nearest living citizen (ID breaks ties) to the physical
objective. Capture retains the six-inch presence radius and ten-second secure hold.
Withdrawn rivals must clear the greater of six inches and their own role range.
Peaceful living claimants still block exclusive capture. Survivors walk home and
rejoin ordinary production; neither victory nor render state grants ownership.

## Inspection and presentation

Click a combatant to inspect civilization instance, role/grade, health/max health,
armor, damage, range, attack cycle, movement and duty/positioning state. The same
values are exposed by `get_inspection_status`. Health bars use normalized health.
Role labels, melee shields/spears, Heavy armor, larger Artillery and smaller
Skirmisher weapons distinguish assignments while retaining existing civilization
figure/palette/organic-industrial presentation. Visuals do not authorize damage.

## Verification and extensions

Run `./TEST_ROOM_SCALE_COMBAT_ROLES.ps1 -RunCount 3 -CaptureVisuals`. It runs the
stat/grade contract and actual-scene targeting, damage/grade mortality assays,
independent role movement, fifteen-citizen three-party mixed combat, capture and
return to real completed work. Every actor's actual role speed is checked per tick.
Fresh-process fingerprints include commitment IDs/stats, attack-order digest,
casualties, departures, winner, capture and returns. The digest folds **every**
attack; the diagnostic history retains only the first 256 events. Raw runs live in
ignored `verification/stabilization/runs/`; selected receipts are curated under
`verification/combat-roles/`. Existing conflict replays now include role commitment
and attack digests as well. Fast includes the role data contract.

Core combat consumes behavior/stat definitions, never civilization IDs. A new
civilization supplies the standard profile and implementation names in its JSON.
A new role with existing behavior extends catalog/order and the standard-profile
validator; a new behavior adds a generic behavior implementation. The standard
five-role distribution deliberately remains a five-role schema contract.

Implementation IDs reserve the seam for multiple equipment/presentation variants;
the current renderer uses shared role geometry and existing civilization style.
The validated `combat.capabilities` list is reserved and grants no gameplay effects.
Future faction abilities can consume that seam through generic capabilities;
technology prerequisites should resolve at commitment through InnovationRuntime;
equipment bills should reserve through EconomySystem before commitment. Neither
research gates, equipment manufacturing/costs nor an ability execution system is
implemented. Diplomacy, trade, suppression, wounds, medics, veterancy, prisoners,
pursuit, fortifications, salvage and captured technology remain later milestones.

The acceptance matrix and implementation report document verification and the
explicit replacement of historical homogeneous-combat assertions.
