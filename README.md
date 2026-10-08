# RoomScale

RoomScale is a 3D civilization simulation in which half-inch citizens treat a human
room as a landscape. Authored RoomDefinition JSON supplies furniture, finite resources,
spawn geometry and elevated surfaces. Citizens physically salvage, haul, build, rest,
climb and explore. One selected civilization operates in one room.

The accepted production baseline is **POC 4.7.2**, completed at
`efa5950e4a03a318bf030eb0217e6cb184714053`. Stabilization includes that verified
settlement planner and preserves its earned production progression; see the
[baseline decision](verification/stabilization/baseline.md).

## Current gameplay

The canonical autonomous start is `room_poc47`: **five founders at 1x**, 20 food,
30 water, no construction materials and no prebuilt shelter, depot, workshop or housing.
The governor evaluates survival and development using ordinary production interfaces.
Citizens earn shelter, storage, workshop and housing through finite salvage, deliveries
and labor. Completed workshop capability gates advanced traversal. Growth adds one real
citizen at a time after shelter, reserves, stability and cooldown checks.

Resources never replenish. Exhaustion can legitimately pause growth or leave a colony
in crisis. There is no mortality, farming, combat, diplomacy, simultaneous competing
civilizations, save/load or multiplayer. Existing established-colony and manual room
scenarios remain regression coverage. Photo reconstruction behavior and visual features
remain room-data driven.

## Civilizations

RoomScale now separates the physical world from the civilization that inhabits it.
`RoomDefinition` describes the room. `CivilizationDefinition` describes civilization
identity, resource vocabulary and presentation while the same production simulation
continues to own needs, economy, tasks, construction progress, legal movement and
traversal state.

Two civilizations are currently selectable:

- **Clockwork** — the existing brass, timber, steam, gears and grapple/cable society.
  Its traversal construction reads as Base → Winch → Launcher and uses Wood, Metal and
  Mechanical Parts.
- **Verdant** — gnome/faerie-like woodland folk whose settlement grows as a living grove:
  branching tree nurseries, willow seed caches, rooted pod homes and cultivated saplings.
  The same production resource slots present as Living Fiber, Resin and Growth Spores;
  traversal construction reads as Root Bed → Growth Lattice → Bloom Anchor and the
  completed real route is presented as a growing, twining living vine. Blossoms and growth
  spores suggest nature magic; construction effects consume real production stage state.
  Bounded deterministic moss, roots and fungi visually reclaim occupied areas without
  changing collision or navigation. Earned founder structures grow roots, branches and
  canopies as their actual construction stages advance.

Clockwork and Verdant intentionally share the same underlying pacing and gameplay
capabilities at this stage. Civilization choice is not yet a difficulty or balance choice.
Only one civilization inhabits a run; coexistence, diplomacy and competition are future work.

Definitions live in `civilizations/`. Clockwork remains the default when no explicit
civilization is supplied.

## Setup and launch

Use **PowerShell 7** (`pwsh`) on Windows. Setup downloads the repository-pinned Godot
4.7.2 standard x86-64 runtime into ignored `.tools/` if absent. Python 3.13+ is needed
for developer campaign tooling, not for normal gameplay. No API key is required.

```powershell
./SETUP_ROOM_SCALE.ps1

# Canonical five-founder fishbowl
./RUN_ROOM_SCALE_FISHBOWL.ps1
./RUN_ROOM_SCALE_FISHBOWL.ps1 -Civilization verdant
./RUN_ROOM_SCALE_FISHBOWL.ps1 -Civilization verdant -ManualCamera

# Established/manual rooms
./RUN_ROOM_SCALE.ps1 -Civilization clockwork
./RUN_ROOM_SCALE.ps1 -Civilization verdant
./RUN_ROOM_SCALE.ps1 -Room room_a -Civilization verdant
./RUN_ROOM_SCALE.ps1 -Room room_b -Civilization verdant
```

Room parameters accept a safe ID in `rooms/` or a project-local JSON file. The file's
stem must match its `id`. Civilization selection is independent of room selection; room
files do not contain Clockwork- or Verdant-specific traversal coordinates or presentation.
See [RoomDefinition contract](docs/RoomDefinition_Contract.md) and
[reconstruction workflow](skills/roomscale-room-reconstruction/SKILL.md).

Pause/1x/4x/10x control time; F3/Details opens diagnostics. Click a citizen to inspect
its work. Keys 1/2/3 select room/settlement/citizen views. WASD/arrows pan, right drag
orbits, middle drag pans, wheel zooms and Q/E change height. In manual mode select an
elevated surface and choose Reach/Explore; POC4 also exposes priorities, Secure Water
and explicit salvage authorization. F12 saves a local capture under `verification/`.

## Development and quality gates

```powershell
python -m venv .venv
./.venv/Scripts/Activate.ps1
python -m pip install -r requirements-dev.txt
python -m ruff check .
python -m ruff format --check .
./TEST_ROOM_SCALE.ps1 -Mode Fast
./TEST_ROOM_SCALE.ps1 -Mode Canonical
./TEST_ROOM_SCALE.ps1 -Mode Regression

# Civilization-specific production smoke
./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization clockwork
./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization verdant
```

Fast contains focused fixtures, schema/navigation checks, civilization-definition and
Verdant main-scene presentation contracts, and milestone fast gates. Canonical runs three
fresh current founder scenarios with repeatability checks. Regression runs meaningful
historical POC4/45/46 integration, navigation/placement checks and sustained gates.
The GitHub Actions civilization matrix runs the same production smoke scenario for
Clockwork and Verdant across Room A and Room B.

Robustness and Soak are explicit expensive modes; All includes them and is unsuitable
for every edit. Full mode definitions, environment isolation and replay commands are
in [testing guide](docs/TESTING.md). The legacy `TEST_ROOM_SCALE.ps1 -Room room_a`
command remains a full M2-M6/M8 room smoke test.

Changes to protected `main` use pull requests and require the GitHub Actions `fast`
check with an up-to-date branch; no human approval is required.
[Verified protection](verification/repository-hygiene/main-protection.md) records the rule.

Headless CI checks Python quality, Fast, civilization contracts and production room
smokes on Windows. Campaigns, soaks and subjective final art acceptance remain explicit
rather than running on every edit. Raw runs are ignored; publish compact receipts and
deliberately selected evidence, following
[artifact policy](verification/stabilization/artifact-review.md).

## Architecture and repository

`CivilizationSimulation` owns the shared 0.1-second deterministic society tick. Need decay,
citizen work, construction, governor/planner decisions and population admission use that
clock. It is deliberately different from `CivilizationDefinition`, which describes which
society is selected and how shared production concepts are presented.

`TaskCoordinator` owns tasks; `CitizenAgent` owns motion and work. `EconomySystem`
tracks inventory transactions; `ResourceSystem` and `SalvageSystem` own finite world
supplies. Development owns earned structures/capabilities, and floor/surface navigation
owns legal routes and completed traversal links. Civilization presentation consumes those
real states: it does not create alternate task, navigation or economy simulations.
See [architecture and authority](docs/ARCHITECTURE.md) for contracts and current debt.

- `rooms/`: authoritative physical-world inputs.
- `civilizations/`: data-driven civilization identity and presentation vocabulary.
- `scripts/civilization_definition.gd`: civilization loading/validation contract.
- `scripts/civilization_presentation.gd`: selected civilization presentation over production state.
- `scripts/verdant_development_presentation.gd`: Verdant styling for structures earned later by the fishbowl lifecycle.
- `scripts/`: production services, presentation and specialized verification drivers.
- `scripts/visuals/`, `scripts/asset_pipeline/`, `visual/`, `assets/`: procedural appearance/catalog/desk assets.
- `scenes/`: code-built production scene entry point.
- `docs/`: current architecture/testing/RoomDefinition guides and milestone guides.
- `skills/roomscale-room-reconstruction/`: existing portable room-authoring workflow.
- `verification/`: historical reports, reproduction fixtures and selected evidence; local runs ignored.
- `screenshots/`, `photo_holder/`: historical canonical captures/reference photos.
- `.tools/`, `.godot/`, `.venv/`: ignored local tooling/cache state.

## Limits and historical evidence

Current supported worlds use rectangular floor bounds, conservative furniture footprints,
one initial elevated target and deterministic single-active-civilization ordering. POC472
founding uses bounded connected layout search, downstream site reservations and planned
rest positions; it does not prove arbitrary layouts. Verdant and Clockwork currently share
production resource slots and pacing; civilization-specific economy bonuses, asymmetric
technology and multi-civilization world authority are not claimed.

Legacy established-room interior activity anchors are a documented compatibility contract.
Citizen IDs are contiguous and append-only. No lifetime/deletion or shared-world authority
model is claimed. Large scene composition, raw task dictionaries and some camera internals
remain documented maintainability debt.

[POC472 report](verification/poc472/final-report.md) records 127 main expected
outcomes plus a supplemental layout, all 79 previous positives, both recovered
exclusions, six identical repeats and 90/60/60-day soaks. Those receipts are historical
source-specific evidence; fresh cleanup verification is in the
[stabilization report](verification/stabilization/final-report.md).
[POC47 founders](docs/POC47_FOUNDERS.md), [POC46 spectator](docs/POC46_SPECTATOR.md),
[POC45 fishbowl](docs/POC45_FISHBOWL.md), [POC4 economy](docs/POC4_GAMEPLAY.md) and
[historical plans](docs/history/README.md) preserve milestone scope/history. They do not override current guides.
POC3's historical subjective visual-review requirement is not silently accepted here.

The accepted POC2 photo workflow remains available. Its canonical input is
`verification/poc2/candidates/primary/attempt-7/room_photo_luna.json`; the
[POC2 acceptance matrix](verification/poc2/acceptance-matrix.md) preserves its
source-specific verification. Ordinary windows add no exterior scenery unless
validated room data explicitly supplies exterior primitives.
