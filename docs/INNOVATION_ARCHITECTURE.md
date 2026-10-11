# RoomScale Innovation Architecture

RoomScale innovation is problem-driven and autonomous. It is intentionally not a conventional player-selected technology tree.

## Core rule

**The room creates problems. Experience reveals problems. Technologies grant capabilities. Capabilities make civilization-specific solutions possible. Solutions change the room.**

The contracts are separated so future civilizations can be added without adding civilization-specific branches to the core simulation.

## Layers

### Problems

`innovation/problems.json` defines civilization-agnostic problem ids such as `VERTICAL_ACCESS`, `WATER_SHORTAGE`, and `LONG_HAUL_DISTANCE`.

World systems may report active problem instances through `ProblemRegistry`. A world detector must not choose or name a civilization-specific invention. For example, an inaccessible shelf reports `VERTICAL_ACCESS`; it never reports `NEEDS_GRAPPLE`.

### Capabilities

`innovation/capabilities.json` defines shared abstract capabilities. Technologies grant capabilities and solutions require them.

Capabilities may imply more general capabilities. For example, `STEAM_POWER` implies `POWER_SOURCE`, so an authored solution can require generic powered machinery without knowing which civilization-specific technology supplied the power.

### Civilization innovation catalogs

Each civilization owns one data file at:

`innovation/civilizations/<civilization_id>.json`

The file contains:

- authored technologies and the capabilities they grant;
- optional capability prerequisites for technologies;
- authored solutions;
- the shared problems each solution addresses;
- capability requirements for each solution;
- solution/research priority weights and future construction metadata.

`InnovationCatalog` loads these files by convention. `InnovationSystem` contains no Clockwork/Verdant switch statement.

### Resolver

`InnovationSystem` deterministically evaluates current problems against one civilization's catalog and current capabilities.

It can answer:

- which technologies are currently researchable;
- which solutions are already viable for a problem;
- which research candidates move the civilization toward authored solutions;
- which candidate has the highest deterministic score.

Identical state produces identical results. Future cultural/personality weights should enter as data/scoring inputs rather than civilization-specific code branches.

## Combination example

Clockwork's `steam_lift` addresses vertical access and logistics problems. It requires:

- `CABLE_ENGINEERING`;
- `POWER_SOURCE`;
- `LOAD_BEARING_FRAMES`.

Those capabilities can be assembled through multiple technologies. In the initial Clockwork catalog, grapple engineering supplies cable engineering, steam power satisfies the generic power source requirement, and structural engineering supplies load-bearing frames. The lift becomes viable only after the combination exists.

Verdant receives the same `VERTICAL_ACCESS` world problem but has authored biological solutions instead, such as a climbing vine or climbing tree.

## Adding another civilization

A new civilization should normally require:

1. Its existing `civilizations/<id>.json` presentation definition.
2. A new `innovation/civilizations/<id>.json` innovation catalog.
3. New shared problem or capability definitions only when the concept truly is general and does not already exist.
4. Civilization-specific visuals/behavior for its authored solutions when those solutions are integrated into the physical simulation.

Adding a civilization must not require editing `InnovationSystem` merely to recognize its id.

## Current scope

This foundation does **not** yet replace the existing workshop/grapple progression. It also does not yet provide automatic room problem detectors, citizen research work, physical prototype construction, deployment, or spectator UI notifications.

Those runtime pieces should integrate through these contracts rather than bypassing them. This keeps the accepted fishbowl simulation stable while the innovation mechanics are introduced incrementally.
