# POC 5.3 force elimination cleanup

Baseline: `c3f9e64f2a2cf3bed630a4c822b3ba038ae00132`. Target: PR #8,
`codex/innovation-foundation-fixes`. Verification date: 2026-10-13.

## State and events

`retreated_sides: instance_id -> tick` contains only living forces permitted to
withdraw on morale. `eliminated_sides: instance_id -> tick` contains only committed
forces with zero living members. The sets are disjoint, idempotent and cleared at
new commitment. Public transition guards reject retreat by a survival force and
elimination of a living force. Elimination does not alter `retreating_side` or
`retreat_tick`, assign movement or emit a retreat event. Both departures apply the
existing 600-second cooldown and stop targeting/participation.

`FORCE_ELIMINATED` records instance ID, casualties, initial committed force,
per-side intensity/cause/objective and tick, with normal journal seconds. Its message
is "committed force eliminated". `RETREAT` retains morale, living survivor count and
physical rally movement. Winner cleanup considers both sets. Multiple remaining
forces continue fighting; the last elimination enters `SECURE` directly, while the
last withdrawal retains `RETREAT`. Physical presence/hold and peaceful-claim rules
remain in force. No larger combat-state bug was exposed.

## Mixed-war receipt

The complete [receipt](mixed-war-receipt.json) includes journal evidence and a
separate elimination-only physical test. Three fresh runs are identical; each runs
both encounters again with reversed runtime/participant ordering. 5,772 assertions
pass per receipt, including terminal death through subsequent physical withdrawal.

```text
eliminated_sides:
  clockwork_alpha: 362
retreated_sides:
  scavenger_alpha: 372
survivors_at_retreat:
  scavenger_alpha: 1
winner: verdant_alpha
attacks: 81
casualties: clockwork 4, scavenger 1, verdant 2
```

The surviving hostile pair keeps fighting after tick 362. Scavenger subsequently
returns home through normal movement; a living peaceful claimant still prevents
exclusive capture. Changing that test relation back to hostile confirms the dead
force cannot block secure. In the separate survival-only encounter, Clockwork is
eliminated at tick 387; Verdant captures after the physical ten-second hold at tick
487. No side is recorded as retreated and retreat metadata remains unset.

## Regression results

| Gate | Result |
|---|---|
| Mixed intensity, 3 fresh runs plus reversed encounters | PASS, identical receipts |
| Two-party deterministic combat, 3 runs | PASS; Clockwork capture tick 1620 |
| Two-party baseline gameplay fingerprint comparison | PASS, every pre-existing fingerprint field identical |
| Three-party combat, 3 runs | PASS; Verdant capture tick 1868 |
| Second conflict room | PASS; Clockwork capture tick 1973 |
| Scarcity/conflict pressure | PASS |
| Combined innovation + combat | PASS; Verdant capture tick 1868 and paid physical innovation |
| Fast room/contract suite | PASS |
| Git whitespace validation | PASS |

The baseline two-party comparison includes contact/start ticks, forces, casualties,
retreating side, winner/capture, attacks, morale, returns, populations and retreat set.
Existing two-/three-party scenarios have no eliminated sides. Receipts and the
repeatability wrapper now include the elimination set alongside retreat state.

Damage, attack interval/range, initiative, force-size policies, scarcity thresholds,
morale formulas, innovation and visuals remain unchanged. The HUD's outcome text
now labels eliminated forces separately. No new civilizations or diplomacy were added.

GitHub Actions is checked at the pushed commit before reporting readiness to merge;
PR #8 must remain open and unmerged.
