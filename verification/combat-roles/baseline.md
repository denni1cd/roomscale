# Combat roles baseline audit

Source: origin/main 16d9e9f (2026-10-15), branch codex/combat-roles.
Pre-existing untracked plans, UID files and poc51 visual evidence preserved.

WorldSimulation owns the fixed 0.1s clock, global citizen registry, shared finite
resources, TerritorySystem and CombatSystem. Society runtimes own boards, economy,
needs, development and innovation. CombatSystem selects real eligible citizens,
preflights legal stations, assigns duties and authorizes attacks in citizen-ID order.
CitizenAgent owns terminal life/health, identity, waypoints and return to ordinary
work. FloorNavigation/SurfaceNavigation remain the sole physical route authorities.
TerritorySystem owns bilateral relations and uncontested timed capture. Presentation
consumes state. Innovation retains separate research/work/material authorities.

Before edits: Fast PASS; conflict 2/2 fresh processes identical (Clockwork capture
1620); three-party PASS (Verdant capture 1868); innovation_extensibility and
combat_mixed PASS. Raw logs: verification/stabilization/runs/combat-roles-baseline/.
Fast's printed error-fixture messages are expected tooling negative cases; the gate
completed PASS. README has stale two-faction/identical-stat prose; current code and
POC5/innovation docs already implement all three societies and mixed war policies.

Necessary adaptations: normalize morale by per-loadout maximum health instead of
100; movement bounds must use assigned role speed rather than universal 6.5 in/s.
Old exact casualty/winner assertions may encode superseded homogeneous combat
balance; preserve their policy, identity, mortality, capture and ordering contracts
with equally strong role-aware assertions and record each replacement.
