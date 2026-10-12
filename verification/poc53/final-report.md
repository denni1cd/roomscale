# Innovation and multi-party completion review

Date: 2026-10-12. Branch: `codex/innovation-foundation-fixes`. Baseline: `71a2d1a96d8024e95e18e051e2e8632ee360ac1c`.
Verification was completed before committing or pushing these changes. No pull request
or deployment was performed as part of verification.
The [source manifest](change-manifest.json) identifies the local working tree using
normalized SHA-256 hashes; [acceptance receipts](acceptance-summary.json) retain compact results.

## Outcome and review

The original foundation issues are fixed: typed fail-closed loaders, atomic data publication,
strict numeric/ID validation, prerequisite-aware research and deterministic exact ordering.
The review additionally reproduced priority multiplication overflow with finite 1e308 weights;
common scaling bounds scoring while preserving relative priorities.

The live vertical-access flow now runs through the production clock, task board, citizens,
economy and shared navigation. Citizens earn a workshop, perform catalog research there,
haul paid materials, fabricate parts from metal, construct a visible route and physically
use it. No invention, stock, work or link is seeded by the positive observer. Scavenger is
added through real definition/catalog data and exercises a three-technology prerequisite chain.
Live work rejects forged effort and duplicate callbacks. Urgent self-care and pause still apply.
Cancellation recovers delivered material as physical bundles, releases ownership/tickets and
allows the ordinary simulation to rebuild. Shared settlement planning protects innovation sites.

A renderer review exposed an unsupported right-angle bend in the first route draft.
The final route is anchored at a real furniture edge, then continues on the supported surface.
Exact segment/rotated-volume checks prevent crossing furniture, including thin obstacles
between waypoints. The route remains a kinematic traversal abstraction, without structural physics.

Combat no longer chooses a winner after the first retreat. Every hostile party commits a legal
force; bilateral pressure and hostility keep comfortable third parties outside a scarce pair's war.
Each side withdraws independently, remaining hostile forces continue fighting, and capture needs
one surviving force, withdrawn rivals and ten seconds of uncontested physical hold. A surviving
peaceful claimant prevents exclusive capture. Invalid scenarios and unavailable forces publish
no partial roster/battle authority. HUD population/forces/losses and outcome text cover every side.

## Acceptance evidence

| Gate | Result |
|---|---|
| Innovation foundation | Original contracts plus **97 robustness assertions** pass |
| Live catalogs | Clockwork, Verdant, Scavenger: **2 identical runs each** |
| Recovery | Actual delivery cancelled, physically recovered and rebuilt successfully |
| Conflict boundaries | Invalid/duplicate/unknown data, rejected full-force commitment and peaceful third claimant pass |
| Two-party compatibility | **5 identical runs**; second conflict room passes |
| Three-party battle | **3 identical runs**, both losing sides independently withdraw |
| Combined innovation/combat | **2 matching combat runs**, exactly one shared paid route and real elevated access |
| Regression | Fast, **3 canonical repeats**, full historical regression and **20/20 exploration cases** pass |
| Original production smokes | Clockwork/Verdant × Room A/B: **4/4** pass |
| Renderer | Verdant research/route/access and three-party battle captures inspected |

The three-party scenario commits three citizens per side; Scavenger captures at tick
1870. Withdrawals occur at ticks
1721 (Clockwork) and
1755 (Verdant). These outcomes follow global
citizen initiative and physical formation/travel, not civilization combat bonuses.
Every surviving combatant returns to ordinary work.

Raw logs and real-renderer PNGs remain under ignored
`verification/stabilization/runs/final-validation/`; the historical regression and original
smoke logs are under `verification/stabilization/runs/next-phase-*.log`.
The CI workflow now includes live/recovery, three-party and combined gates. These are
locally verified commands; no remote Actions run is claimed.

## Launch and scope

```powershell
./RUN_ROOM_SCALE_FISHBOWL.ps1 -Civilization verdant -Innovation
./RUN_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_c -Scenario three_party_conflict -Innovation
```

Live implementation covers vertical-access detection and cable/vine/rope routes. Other
catalog examples (powered lifts, bridges, water reservoirs and shelter upgrades) require
additional detectors/adapters; they are excluded from live research rather than silently
scheduled without deployment support. Scavenger reuses industrial citizen meshes with its
own identity/palette and rope access. Combat covers one contested floor site; diplomacy,
coalition ownership and elevated combat are outside this milestone. Long soaks and arbitrary
large-party placement campaigns were not run. Original user plan files and prior QA evidence
are preserved.
