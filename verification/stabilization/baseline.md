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
