# POC 2.5 CI Failure Classification — run 40256472981

**Commit under review:** `04e75d2842346ff7262ca9268c37cdb2c4d75807`
**Run:** GitHub Actions quality run 40256472981
**Classification:** the reported failures are POC 2.5 regressions exposed by the Windows runner. The available run logs do not support classifying them as pre-existing failures. The Windows line-ending behavior is the environmental trigger for one regression, not a reason to dismiss it.

| Job / evidence | Result | Contract classification | Repair / follow-up |
|---|---|---|---|
| `fast` — Python quality step | Passed | No failure | Ruff/Python quality succeeded. |
| `fast` — civilization visual contract | Failed: `Clockwork cap must be hidden for Verdant citizen` | POC 2.5 integration regression | The registered Clockwork citizen pilot was applied without reliably limiting it to Clockwork, bypassing Verdant's own citizen styling. The adapter now only applies this Clockwork pilot to `civilization_id=clockwork`; the local Verdant civilization contract passes. |
| Clockwork Room A / Room B and Verdant Room A / Room B smoke jobs | Failed accepted-asset SHA-256 checks on `grapple-v006`, `citizen-v007`, and settlement workshop v004, depot v003, housing v002, and workarea v005; downstream accepted-asset identity assertions consequently failed | POC 2.5 registry portability regression, triggered by Windows checkout configuration | Git for Windows converted LF text scenes to CRLF while the registry compared raw hashes. Python and Godot runtime checks now canonicalize line endings for text resources and preserve raw hashing for binary resources. The fix covers all six affected text scenes; a CRLF-specific runtime resolver regression test passes. |
| Conflict job | Passed | No failure | No repair required. |
| Node/action deprecation and runtime package warnings | Warnings only | Environmental / non-blocking | These warnings did not cause a failed check. |

## Verification after repair

The local fast deterministic suite, civilization definitions, and Verdant presentation contract pass. Clockwork Room A smoke passes with 50 citizens, deliveries, construction, and real traversal. A Verdant Room A smoke exposes a separate prerequisite failure in the current uncommitted POC 3/5 working tree: its modified `construction_system.gd` stores `target_anchor` from a room-region anchor but deploys to `current_project.destination_position`; the living-vine anchor assertion then fails. `04e75d2` uses one authoritative `target_anchor` for both, and the uncommitted expansion changes are outside this POC 2.5 repair, so they were preserved and not edited. Clockwork Room B smoke also passes with the same gameplay proofs in `repair-rerun/smoke-room_b-clockwork.log`. The current local Verdant smoke is therefore classified as a broader-worktree prerequisite issue, not a POC 2.5 regression or a failure observed in GitHub run 40256472981.

## Follow-up CI runs

Run `40346965008` on `5a4236c` validated Ruff lint but failed format check on `scripts/art_factory/models.py` and `scripts/test_art_factory.py`, a POC 2.5 formatting defect. Commit `23a3d70` applied Ruff formatting. The other jobs in `40346965008` were canceled when the branch advanced, so they do not count as verification. Full remote run `40347158916` on `23a3d70` completed successfully: Python quality, all four Clockwork/Verdant Room A/Room B smoke jobs, and conflict checks passed. GitHub Actions run `40350083579` on commit `5e3c696a99efddbcecefb5dd919c97bbe843db3d` also passed all six jobs. The latest accepted Actions run, `40417656855`, subsequently passed all six jobs and supersedes those earlier green baselines. That run predates the current review-only additions; local validation is recorded below.

## Review-only showcase verification after run 40417656855

The current review worktree adds a separate explicitly opted-in best-current registry mode, metadata propagation for citizen art, evidence capture framing, and review documentation. Local coverage passes: 20 Art Factory unit tests, Ruff lint/format for `godot_bridge.py`, the Godot visual-resolver contract test, and fresh Clockwork smoke runs in Room A, Room B, and reconstructed `room_photo_luna`. The 14-view review-only production capture also passes. Run `40417656855` predates these additions and is not remote CI validation for the current worktree; keep that distinction until a new Actions run reports results.
