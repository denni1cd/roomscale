# Main delivery and post-merge verification

Accepted POC4.7.2 baseline: `efa5950e4a03a318bf030eb0217e6cb184714053`.
Frozen source/harness: `ef5ebd325351ae6c3702a7ab8d89266aafed59ea`.
Stabilization delivery: `0e3657257b5f91577a2de653fac5eadf3383de7f`.

The clean merge-ready stabilization branch was pushed after all required local gates
passed. Existing main was fast-forwarded to reviewed origin/main3055736 and normally
merged with `--no-ff`, preserving accepted milestone/mainline history. Merge commit:
`167e80b13396bae6830460819158a22de443a074`. Its tree is identical to stabilization.
No source/config/asset/harness differs from the frozen 188-file manifest.

The normal push to origin/main succeeded. `git ls-remote` independently returned that
exact merge SHA before post-merge testing. The primary checkout is now on main.
A fresh Godot import and the full Fast mode passed from that actual main revision:
Ruff check/format,14 Python tests,PowerShell boundary tests,schema/founder,
checked evidence/core,navigation/retry/midlink,planner and packing. Tree and source
integrity checks passed after smoke. Log hashes are recorded in main-merge.json.

AC01–AC32 are satisfied locally, including clean-tree enforcement, conditional normal
merge, verified remote main and post-merge Fast. Later delivery commits only record
these results; final main SHA is provided at delivery because a commit cannot embed
its own hash. All 188 frozen source/config/asset/harness hashes remain unchanged.

Remote CI status at recording: **queued, no hosted Windows runner acquired**.
[Stabilization CI](https://github.com/denni1cd/roomscale/actions/runs/37366757200)
and [merged main CI](https://github.com/denni1cd/roomscale/actions/runs/37367267476)
are not claimed as PASS. Local quality/import/Fast and all expensive acceptance gates
passed. The workflow exists and dispatched; remote execution remains unverified.

No force push, history rewrite, automatic tag or historical branch deletion occurred.
Recommend a user-selected future `roomscale-founder-stable` tag.
