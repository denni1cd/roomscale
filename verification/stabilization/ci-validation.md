# Remote CI validation follow-up

Initial [main run](https://github.com/denni1cd/roomscale/actions/runs/37367466464)
for ba73fea failed to allocate a hosted runner and executed zero steps. It was retried.
GitHub annotation: “The job was not acquired by Runner of type hosted even after multiple attempts”.

The [bb26107 run](https://github.com/denni1cd/roomscale/actions/runs/37373403455)
acquired a runner. Python quality and Godot import passed, but Fast failed in the
controlled `PlacementPublicationTests` fixture. Windows TEMP used RUNNER~1 while
`Path.resolve()` in the real audit expanded it to runneradmin. The fixture's synthetic
ROOT was unresolved, so lexical containment rejected two aliases of the same directory.
The real audit ROOT already resolves its own file path; production was unaffected.

One line in `scripts/test_tooling.py` now initializes the fixture root with
`Path(directory).resolve()`. No production, campaign runner/observer, real audit,
workflow, configuration or scenario input changed. The correction is frozen at
`487583a39bce5666688a14f70c5bfe885943fcae` before acceptance. All original188 manifest
hashes match except this explicitly identified unit-test file. Relevant Fast,14
ordinary tests,14 optimized tests and a direct native Windows short-TEMP-alias test
pass. Hosted [correction CI](https://github.com/denni1cd/roomscale/actions/runs/37373885965)
**completed successfully**. Python quality, Godot import and complete Fast all passed
on the hosted Windows runner for exact frozen revision487583a. The failure-artifact
upload step was correctly skipped. The run/job result and log hash are retained in
`ci-validation.json`.

The original complete-harness freeze is historical rather than claimed to match the
current unit-test file. `ci-portability-manifest.json` records the replacement freeze
and all188 current hashes. Original ef5ebd3 campaign receipts remain attached to their
original source/harness; none is relabeled. Relevant verification is rerun for this
fixture-only change; full gameplay acceptance logic and production remain identical.

Final delivery only records this passing result; no executable or test-harness change
follows frozen487583a. The prior failed attempts remain documented, not replaced.
