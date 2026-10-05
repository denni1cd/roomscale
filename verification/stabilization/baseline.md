# Stabilization baseline gate

Gate inspected on 2026-10-04 before changing production or test source.

Selected branch: `codex/roomscale-poc471-founder-stress`.
Selected baseline SHA: `923e8e600e43a892a21b846e908c9036194e0747`.
Cleanup branch: `codex/roomscale-stabilization`, isolated checkout.

POC 4.7.2 was **pending and excluded** at the startup gate. Its local HEAD was
`9a7df235a80ea5df03fa37826cc727bc6da64afd`, a descendant of the accepted baseline.
Its source was committed, but `verification/poc472/` was untracked, no final-report.md
existed, three Godot processes and campaign Python processes were running, and the
owning chat's latest turn was in progress. Its acceptance matrix and freeze manifest
are provisional evidence, not a coherent completed final report. No remote POC472
branch was present in the initial local remote refs. The original checkout is left
untouched so the campaign can finish.

The accepted 4.7.1 final report records frozen source b11fe41, evidence-only final
commit 923e8e6, 79 admitted positive passes, five expected negatives, full 90/60/60-day
soaks, six identical repeats, no admitted unresolved positive failures, and shared
legacy regressions. Cleanup starts from exactly that accepted commit. Three fresh
canonical repeats and a POS-001 eight-day observer replay also pass before editing.

**Main merge is prohibited for this stabilization run.** The required deliverable
is a pushed cleanup-ready branch/report for later rebasing onto completed 4.7.2.
A later milestone completion does not retroactively make this selected baseline the
latest accepted production source. Rebase and rerun the current milestone gates first.
No history rewrite, forced main update, release tag or feature-branch deletion.

## Completed POC 4.7.2 baseline update (reviewed before integration)

During stabilization, the previously pending milestone completed on 2026-10-04.
The new required baseline is `efa5950e4a03a318bf030eb0217e6cb184714053` on
`codex/roomscale-poc472-settlement-planner`, descendant of accepted 4.7.1.
Its frozen source is `9a7df235a80ea5df03fa37826cc727bc6da64afd`; later commits
are evidence only. Independent reviews verified all 65 source hashes, all 127 main
receipts plus the supplemental receipt, required durations, retained inputs and
shared regressions. All expected outcomes pass with zero violations/deadlocks.
The original checkout is clean. Initial 4.7.1 measurements remain historical;
acceptance will compare against completed 4.7.2 and rerun current gates.

The complete newly active source/tooling delta was reviewed before integration.
Additional findings, each fixed now unless stated otherwise:

| ID | Severity | Evidence, risk and proposed action |
|---|---|---|
| M19 | Medium | Settlement planner caches failed RoomDefinition geometry although search depends on transient bundle anchors and planning request. Collection can leave a permanent stale rejection. Include relevant planning inputs in cache identity; focused fail/remove/retry fixture. |
| M20 | Medium | POC472 campaign Review returns success for empty/failed evidence and Full does not require the complete expected scenario/repeat set; assert gates disappear under Python -O. Add explicit acceptance checks and failure exit status. |
| M21 | Medium | POC472 regression runner resolves Python imports from caller CWD and invokes focused Godot without bounded process/environment/result handling. Use repository-root paths and shared process runner. |
| M22 | Medium | Active verification/poc472/gather_evidence.py is excluded from Ruff, uses implicit encoding/assert acceptance, and publishes reports before all audits finish. Include this active tool in quality gates, explicit errors/encoding, publish only after success. |
| M23 | Medium | POC472 launcher assumes PATH Python and omits positive workers/reproduction validation. Add PythonExecutable and strict argument validation. |
| M24 | Medium | POC472 review/publish logic duplicates campaign logic and can scan stale corpora. Reuse bounded review helpers without early publication. |
| L09 | Low | Planner navigation_trials excludes leaf and acceptance/completion cloned-navigation checks. Count consistently or qualify precisely; bounded search remains intact. |

Combined review counts: **0 Critical, 2 High, 24 Medium, 9 Low** (35 findings).
The latest baseline gate is now eligible for main merge evaluation, conditional on
all stabilization tests, final review, clean tree and frozen-source receipts.
