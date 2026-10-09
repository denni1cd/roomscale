# RoomScale POC 5.1 — Scarcity-Driven Conflict

## Purpose

POC 5 proved that two autonomous civilizations can share one finite room, encounter one another, fight with real citizens, suffer persistent casualties, retreat, capture a strategic site, and resume ordinary work.

POC 5.1 changes **why** that conflict happens.

A territorial encounter must not automatically create hostility. Civilizations should fight because a finite thing they depend on is scarce and another civilization is competing for it.

The core rule is:

> **Abundance permits coexistence. Scarcity creates pressure. Competition over scarce necessities can escalate to war.**

Space is a first-class scarce resource alongside material resources.

---

## Conflict Model

For a contested asset, each civilization receives an inspectable pressure value. The conceptual model is:

**Conflict pressure = scarcity × dependency × competition**

POC 5.1 uses deterministic numeric implementations of that idea rather than an LLM or random hostility roll.

A conflict decision records separately:

- **cause** — `SPACE` or `RESOURCE`;
- **resource** — for a material conflict, the specific resource such as food or water;
- **intensity** — how desperate the conflict is;
- **objective** — what outcome would satisfy the civilization.

---

## Space as a Resource

POC 5.1 models territory as discrete strategic capacity rather than a continuous painted-border map.

Each civilization has secured home-space capacity. Strategic sites may add additional `space_capacity` when controlled.

Population saturation creates territorial pressure. A civilization with ample secured capacity has no reason to fight merely because another civilization exists. As population approaches or exceeds its secured capacity, additional usable territory becomes increasingly valuable.

This is deliberately smaller than a full territorial-ownership system. Continuous borders, arbitrary parcel subdivision, and generalized settlement zoning remain future work.

---

## Material Scarcity

Strategic sites may identify finite resource sources that control access to food, water, wood, metal, or future resources.

When evaluating a resource conflict, RoomScale considers secured stock plus reachable alternative supplies. The contested source is excluded from that secured supply calculation.

Therefore:

- a scarce contested source with plentiful reachable alternatives should not cause war;
- a source both civilizations depend on with inadequate alternatives may create war pressure;
- the specific resource must be preserved as the conflict reason.

The current canonical POC 5 encounter is a **space-conflict fixture**. The material-resource path is part of the same production pressure system and is covered by deterministic contract assertions; future strategic sites can bind real source IDs to exercise it as a full scenario.

---

## Intensity Ladder

| Level | Meaning | Combat behavior |
|---|---|---|
| `PEACE` | Needs comfortably satisfied | No combat |
| `COMPETITION` | Asset is useful and pressure exists, but war is not justified | Claims remain contested; no combat |
| `LIMITED_WAR` | Civilization is willing to fight for the specific asset | ~25% force commitment, normal morale retreat, objective is control of the contested asset |
| `MAJOR_WAR` | Shortage is severe | ~50% force commitment, lower retreat tendency |
| `SURVIVAL_WAR` | Failure to secure the need threatens civilization survival | Up to the full eligible population commits; ordinary morale retreat is disabled; objective becomes removal of the existential blocker |

A survival war is not a generic genocide flag. Its simulation objective is that the rival can no longer prevent access to the survival-critical need. POC 5.1 has no surrender, absorption, refugee, or negotiated-expulsion system, so the current mechanical expression is all-in combat among eligible citizens.

---

## De-escalation

Conflict pressure continues to be evaluated after contact.

If the underlying pressure falls below the war threshold before or during active combat:

1. hostility ends;
2. both forces stand down;
3. living combatants physically return home;
4. the site may remain politically contested;
5. no new battle starts while scarcity remains below the threshold.

This prevents historical hostility from becoming a permanent autonomous war trigger after the original cause has disappeared.

---

## Canonical POC 5.1 Scenario

`clockwork_vs_verdant.json` remains the canonical encounter in both `room_conflict` and `room_conflict_b`.

Each civilization starts with:

- population: `12`;
- secured home-space capacity: `11`.

The shared strategic frontier offers:

- additional space capacity: `12`.

At contact, this produces a bounded `LIMITED_WAR` over `SPACE` rather than an authored unconditional battle.

The expected objective is `SECURE_TERRITORY`.

The existing POC 5 combat behavior should therefore remain visually recognizable while now having a real simulation reason.

---

## Acceptance Criteria

### AC-01 — Contact Is Not Hostility

Two claims create contact and a contested site. `territory_system` does not independently declare war.

### AC-02 — Abundance Blocks War

Pressure below the war threshold never starts combat, even after both civilizations have claimed the same site.

### AC-03 — Resource Reason

When a strategic site controls a scarce resource and both civilizations lack adequate secured alternatives, the pressure result identifies `RESOURCE` and the specific resource.

### AC-04 — Resource Abundance

When secured supply is comfortably above demand, resource scarcity evaluates to zero and cannot initiate resource war.

### AC-05 — Space Is First-Class

Secured territorial capacity and population saturation can independently produce conflict pressure with cause `SPACE`.

### AC-06 — Limited War

The canonical scenario begins as `LIMITED_WAR`, commits a bounded force, permits morale retreat, and seeks `SECURE_TERRITORY` rather than destruction of the rival civilization.

### AC-07 — Major War

Major-war policy commits a materially larger fraction of the population and lowers the retreat threshold.

### AC-08 — Survival War

Survival-war policy may commit the full eligible population and disables ordinary morale retreat.

### AC-09 — Pressure Is Inspectable

The active pressure score, cause, intensity, and resource where applicable are available in simulation state, event history, and the conflict HUD.

### AC-10 — Cause Can Resolve

If an active conflict falls below the war threshold, combat stands down and survivors return to ordinary life rather than continuing because of historical hostility.

### AC-11 — Capture Relieves Space Pressure

Owned strategic space capacity contributes to the winner's secured capacity in subsequent evaluations.

### AC-12 — Existing Combat Remains Real

Marching, attack range, damage, persistent death, morale, retreat movement, secure hold, capture, and return to work continue to use the POC 5 production systems.

### AC-13 — Cross-Room Regression

The scarcity-driven canonical scenario works in both `room_conflict` and `room_conflict_b` without room-specific combat code.

### AC-14 — Deterministic Contract

Conflict thresholds and force policies are deterministic and directly testable.

---

## Explicitly Out of Scope

POC 5.1 does not add:

- diplomacy or treaties;
- trade;
- personalities, hatred, ideology, or historical grudges;
- continuous floor-wide territorial borders;
- arbitrary territorial parcel generation;
- surrender or vassalization;
- civilian targeting rules;
- refugees or population displacement;
- negotiated access rights;
- reinforcement waves during an already active battle;
- alliances or multi-party wars;
- recurring strategic-site selection across the entire room.

Those systems can build on the pressure/cause/intensity contract later.

---

## Definition of Done

POC 5.1 is complete when the production simulation can truthfully answer all of these questions before a fight starts:

**What do we need? How scarce is it? Who else wants it? How desperate are we? What are we trying to achieve?**

Combat may begin only when the resulting pressure justifies the corresponding level of war.
