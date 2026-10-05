# Stabilization baseline gate

Selected required baseline: **POC 4.7.2**, branch
`codex/roomscale-poc472-settlement-planner`, final SHA
`efa5950e4a03a318bf030eb0217e6cb184714053`.
Frozen milestone production/harness SHA:
`9a7df235a80ea5df03fa37826cc727bc6da64afd`.
Cleanup branch: `codex/roomscale-stabilization`, isolated checkout.

At the initial 2026-10-04 gate, 4.7.2 was actively verifying, lacked a final report
and had untracked evidence. Cleanup correctly started from accepted 4.7.1
`923e8e600e43a892a21b846e908c9036194e0747`, leaving the active checkout untouched.
The full initial review and first candidate are retained as useful investigation
history; their measurements are not final 4.7.2 acceptance.

During this task, 4.7.2 completed and was pushed. A second gate independently
verified the clean committed state, descendant relationship, final report, all
65 frozen source hashes, 127 main receipts plus one supplemental, required legacy
regressions, six repeat fingerprints and full 90/60/60-day soaks. All expected
outcomes pass with zero invariant violations/deadlocks and no unresolved admitted
positive failure. Later milestone commits only publish evidence. All 95 retained
RoomDefinition blobs remain unchanged. NEG-03 is now physically feasible and must
succeed; NEG-05 correctly rejects disconnected spawn before stepping.

The complete newly active delta was reviewed before its integration/refactoring.
See the supplemental findings in code-review.md. A normal merge preserves accepted
milestone history. Fresh baseline measurements: three canonical PASS runs at
12.05/12.03/11.92 seconds and POS-001 PASS at 19.792 seconds.

Main merge is permitted only after current 4.7.2 stabilization verification,
frozen-source evidence, final review/report and every user merge gate passes.
No history rewrite, forced main update, release tag or feature-branch deletion.
