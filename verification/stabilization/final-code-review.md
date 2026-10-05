# Review of the stabilization changes

Source candidate: `136d2350b6825999f49110ed2c8c25de28bc282e`.
Independent second review completed before acceptance; executable source is unchanged
while final gates run. This document is a review receipt, not the final acceptance report.

## Correctness and behavior

All changed core production scripts and focused fixtures were reviewed independently.
The public stepping/replanning/navigation wrappers retain the original bodies, delta and
fixed-tick order. Construction costs/work, citizen speed/need decay, founder count,
resource amounts, shelter/growth/capability policies and finite exhaustion remain unchanged.

A second reviewer caught a malformed-field hazard in the new effective resource-profile
validator. It was corrected before the source-candidate commit: kind/material must have
validated String types before derivation; focused assertions require diagnostics rather
than a crash. This correction does not weaken schema checks.

The 150-citizen fixture invokes production population construction and creates actual
CitizenAgent entities with contiguous IDs. Its fixture camera bypasses only unrelated
scene-ready setup. Atomic invalid-roster and blocked-return fixtures test real boundaries;
they do not claim earned founder integration. Five/50 canonical starting positions are
identical to old production calculations. New canonical receipts compare all 15 production
fields and require PASS/complete fields. Host metadata alone is excluded.

Final canonical production fingerprint equals the baseline fingerprint exactly:
`67c88227dc59d62210f2d2a5547e3453894bffc253c7bc16e0c85a777c207b6f`.
Every checkpoint difference is 0.0 simulation seconds. Three final runs match each other.
Full generated-world and soak conclusions belong in final-report after completion.

## Verification integrity

Reviewed shared PowerShell quoting, asynchronous stream draining, bounded timeout kill,
child environment isolation, root-relative paths and error/marker/JSON propagation.
Legacy room/log/capture calls still delegate the old smoke contract. Specialized scenario
assertions remain; no historical integration coverage is deleted. Campaign stale receipts
are deleted before launch; execution errors cannot be restamped as accepted PASS.
Failed evidence audit preserves the accepted summary/matrix/report and writes diagnostics.

Ruff formatting is separated conceptually from the small process/provenance changes;
review did not treat formatting as evidence of simulation correctness. High-value rules
E4/E7/E9/F/I avoid an indiscriminate style rewrite. Historical evidence and local tooling
are excluded from lint, not active developer programs. Python source grows from two to
four files for the explicit comparator and meaningful tooling tests.

Shared PNG/JSON writes reduce identical historical helper blocks. M4/M5/M6 and named
live/camera drivers propagate write failure; the report does not claim every older capture
path was migrated. Broader scenario inheritance, camera private APIs, task dictionary
encapsulation, global constants and scene decomposition remain explicit deferred debt.

## Repository and documentation

Every removed PNG has a retained identical SHA-256 replacement: 20 files, 11,324,795
bytes. No unique image, RoomDefinition/seed/config, independent receipt, historical report
or regression fixture is deleted. Baseline history remains recoverable. Ignore rules
require deliberate raw-evidence publication, while tracked evidence stays tracked.
Verification/.gdignore avoids import clutter and Fast confirms direct FileAccess fixtures.
Source UID sidecars are intentionally retained source metadata; asset import options are
unchanged. No giant file moves or historical commit rewrite occurred.

README/architecture/testing describe the selected stable baseline and limitations.
Old plans/status are labeled historical; POC472 is excluded due the startup gate.
The 500 bound is qualified as terminal task history rather than every live task.
CI runs Windows Python quality/import/Fast only, and its remote execution is unverified
until GitHub Actions actually runs. No subjective visual acceptance is newly claimed.

The added-text audit found zero private-key patterns, credential-value patterns or
user-machine absolute paths. Raw absolute-path execution receipts remain ignored;
published manifests/reports use project-relative paths. Diff whitespace checks pass.
The main merge gate remains blocked by the pending/excluded latest milestone baseline,
even if all stabilization regressions pass. No automatic release tag is created.
