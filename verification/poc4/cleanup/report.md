# Narrow POC 4 cleanup

**PASS.** Same branch `codex/roomscale-poc3-visual-fidelity`, based on `6d278c5319496d92078301693714f2fe30f69a76`. No branch merge, gameplay expansion, balance/canonical data change, navigation rewrite, planner redesign, UI or visual overhaul.

## Authorization transaction (AC-16, AC-23)

Previously, `CivilizationSimulation.authorize_salvage()` cleared navigation padding before validating physical approach candidates. If all approaches failed, only the authorization flag was reset; the room-definition padding and obstacle rectangles stayed modified, giving a protected object leaked edge access.

Now candidate validation uses a temporary FloorNavigation configured from a deep copy of the live navigation definition, with only the proposed object's padding removed. Production bounds, obstacle and path checks remain intact. The temporary node is freed before any return; if candidates are absent, the live navigation, salvage flag, targets and planner permissions are untouched. Only a valid candidate plus successful salvage authorization commits edge access to the live navigation.

The deterministic production-code fixture starts protected with nonzero padding and real blockers on all four approaches. It proves failed authorization, unchanged authorization/planner/targets, exact equality of definition and obstacle rectangles, every live grid cell unchanged, unchanged path/walkability, and continued obstacle rejection of the blocked approaches. A successful case checks edge access commits while the physical object obstacle remains.

## Resource derivation (AC-17, AC-18, AC-22)

Previously, default stages were derived from inferred/appearance material, then explicit profile material was merged. A wood-semantic object's explicit metal profile therefore retained wood-oriented stages.

Now the explicit material override is resolved before automatic stage derivation. The existing final merge still gives explicit custom stages precedence. Appearance-based material inference and conservative unknown/nonmaterial behavior remain intact; profile and RoomDefinition validators still reject invalid materials. Canonical metadata is unchanged.

Targeted cases: inferred wood furniture, appearance-derived metal, explicit metal on otherwise wood-semantic furniture with no stages, explicit custom stages, conservative unknown/plant, invalid material at both validation layers, and canonical four stages totaling 13 wood/4 metal.

## Documentation-only shelter clarification

`docs/POC4_GAMEPLAY.md` and the final report explicitly describe finite capacity, sheltered/unsheltered state, rest reservations and visible shortage. Unsheltered citizens have no strong penalties or differentiated behavior in this POC. Exposure/health/morale/homelessness consequences, household ownership and shelter construction remain future scope. No shelter code changed.

## Files

- `scripts/civilization_simulation.gd`: validate proposed navigation before committing authorization.
- `scripts/resource_system.gd`: final material drives automatic stages.
- `scripts/poc4_cleanup_test.gd`: targeted deterministic production regressions.
- `TEST_ROOM_SCALE_POC4.ps1`: include cleanup regression in Fast/All.
- `docs/POC4_GAMEPLAY.md`, `verification/poc4/final-report.md`: shelter limitation and cleanup evidence link.
- `verification/poc4/cleanup/`: retained test results and this report.

## Commands actually run

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/poc4_cleanup_test.gd
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc4/cleanup/fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Scenario -OutputDirectory verification/poc4/cleanup/scenario
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc4/cleanup/regression-fast.log
```

The targeted test was also run against the original two production scripts from HEAD, restoring the corrected scripts in a finally block. It correctly failed on the mismatched metal stages, leaked definition/obstacle changes and rejected padding access. Restored fixed code immediately passed. [Pre-fix failure](pre-fix-regression.log), [final targeted pass](targeted-final.log).

| Gate | Result | Evidence |
| --- | --- | --- |
| Targeted regressions | PASS | `targeted-final.log`; original defects demonstrably fail same assertions |
| POC4 fast production checks | PASS, 14.82s | `fast/fast.log` |
| Metadata/source contract | PASS, 0.30s | `fast/contract.log` |
| Cleanup in Fast runner | PASS, 0.30s | `fast/cleanup.log`; three-job `fast/summary.json` |
| Full canonical scenario | PASS, 5.34s | `scenario/scenario.log/json`, all twenty causal-chain assertions |
| Existing room/navigation fast regression | PASS | `regression-fast.log`: Room A/B, 26 malformed cases, rotated geometry/approaches, derived sites, navigation, bounded history |

Canonical recovery remains 741 simulation seconds. Four salvage stages produce exactly 13 wood/4 metal; construction consumes 4 wood/4 metal, leaving 9 wood. No canonical behavior or yields changed. Five-run repeatability and thirty-day stability were not repeated: the success path/canonical derivation is unchanged as confirmed by the full scenario and fast suite, and the patch has no ongoing tick/task/need/accounting changes.

The first targeted-test attempt included an extra positive-case assertion that a reconfigured existing grid clears old solid cells. That expectation does not describe the retained navigation implementation; the positive check was corrected to verify obstacle-edge access and physical obstacle preservation. The required rejection assertions still compare every grid cell and all navigation state exactly. No production navigation validation was weakened. That diagnostic is retained as `targeted-attempt-1.log`.
