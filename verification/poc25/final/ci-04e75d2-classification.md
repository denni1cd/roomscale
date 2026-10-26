# POC 2.5 CI Failure Classification — run 40256472981

**Commit under review:** `04e75d2842346ff7262ca9268c37cdb2c4d75807`
**Run:** GitHub Actions quality run 40256472981
**Classification:** the reported failures are POC 2.5 regressions exposed by the Windows runner. The available run logs do not support classifying them as pre-existing failures. The Windows line-ending behavior is the environmental trigger for one regression, not a reason to dismiss it.

| Job / evidence | Result | Contract classification | Repair / follow-up |
|---|---|---|---|
| `fast` — Python quality step | Passed | No failure | Ruff/Python quality succeeded. |
| `fast` — civilization visual contract | Failed: `Clockwork cap must be hidden for Verdant citizen` | POC 2.5 integration regression | The registered Clockwork citizen pilot was applied without reliably limiting it to Clockwork, bypassing Verdant's own citizen styling. The adapter now only applies this Clockwork pilot to `civilization_id=clockwork`; the local Verdant civilization contract passes. |
| Clockwork Room A / Room B and Verdant Room A / Room B smoke jobs | Failed accepted-asset SHA-256 checks on `grapple-v006` and `citizen-v007`; downstream accepted-asset identity assertions consequently failed | POC 2.5 registry portability regression, triggered by Windows checkout configuration | Git for Windows converted LF text scenes to CRLF while the registry compared raw hashes. Python and Godot runtime checks now canonicalize line endings for text resources and preserve raw hashing for binary resources. A CRLF-specific runtime resolver regression test passes. |
| Conflict job | Passed | No failure | No repair required. |
| Node/action deprecation and runtime package warnings | Warnings only | Environmental / non-blocking | These warnings did not cause a failed check. |

## Verification after repair

The local fast deterministic suite, civilization definitions, and Verdant presentation contract pass. Clockwork Room A smoke passes with 50 citizens, deliveries, construction, and real traversal. A Verdant Room A smoke exposes a separate prerequisite failure in the current uncommitted POC 3/5 working tree: its modified `construction_system.gd` stores `target_anchor` from a room-region anchor but deploys to `current_project.destination_position`; the living-vine anchor assertion then fails. `04e75d2` uses one authoritative `target_anchor` for both, and the uncommitted expansion changes are outside this POC 2.5 repair, so they were preserved and not edited. Clockwork Room B smoke also passes with the same gameplay proofs in `repair-rerun/smoke-room_b-clockwork.log`. The current local Verdant smoke is therefore classified as a broader-worktree prerequisite issue, not a POC 2.5 regression or a failure observed in GitHub run 40256472981. A GitHub rerun on the repair commit remains the remote confirmation.
