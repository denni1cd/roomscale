# Final repository hygiene and main protection

Starting main: `5ae70f0828af80796d9e2e1bf507890b76dc72bd`.
Verified hygiene main merge: `038edabc0633e89356718ceaf3398703298fb4a0`.
Branch: `codex/roomscale-final-hygiene`; [hygiene PR1](https://github.com/denni1cd/roomscale/pull/1)
merged normally, without admin bypass. The final delivery adds this results-only report
through a protected PR. Its final main SHA is reported at delivery (`git rev-parse main`);
a committed report cannot embed its own containing merge SHA.

## Protection

[Ruleset24544582](https://github.com/denni1cd/roomscale/rules/24544582) is active for
refs/heads/main and was read back before and after merge. PRs and exact **fast** check,
bound to GitHub Actions app15368, are required; branches must be up to date.
The check was discovered from successful .github/workflows/quality.yml execution,
not guessed. PR1 was BLOCKED with pending checks, then CLEAN after both checks passed.
Zero human approvals; code-owner,last-push,extra approval and thread requirements false.
No signatures,linear history,deployments,Robustness or Soak requirement. Force pushes
and deletion blocked; no standing bypass. Owner admin permission still permits emergency
editing/disabling of this specific ruleset. No permission limitation occurred.
main-protection.md/protection-readback.json preserve exact configuration.

## Files and artifact policy

Nine historical plans/prompts moved with git mv; milestone scopes remain unchanged:

| Directory | Files moved from root |
|---|---|
| docs/history/poc1 | poc_project_plan.md |
| docs/history/poc15 | RoomScale_POC_1.5_Project_Plan.md |
| docs/history/poc2 | RoomScale_POC_2_Project_Plan.md |
| docs/history/poc3 | RoomScale_POC_3_Project_Plan.md |
| docs/history/poc4 | RoomScale_POC_4_Project_Plan.md |
| docs/history/poc45 | RoomScale_POC_4.5_Project_Plan.md |
| docs/history/poc46 | RoomScale_POC_4.6_Project_Plan.md; RoomScale_POC_4.6_Implementation_Prompt.md |
| docs/history/poc47 | RoomScale_POC_4.7_Project_Plan.md |

The [history index](../../docs/history/README.md) also links accepted4.7.1/4.7.2 reports.
README,PROJECT_PROGRESS,architecture/testing,setup/run/test scripts and configs remain
at their current entry points. README,index,guides and historical evidence references
were updated; five links inside moved4.7 were rebased. Historical bodies were not
rewritten to current behavior; only path references and guidance annotations changed.
113 relative links checked with zero broken targets; new report links also resolve.
No PowerShell references a moved document; no fixture or executable source moved.

15 representative future generated paths are ignored; five intended compact-report/
authored-fixture cases remain addable. Scoped screenshot PNG/JSON/log ignores and
repository-hygiene report exceptions were added. Raw campaigns,soaks,replay scratch,
stdout/stderr,caches,venv,Godot/runtime state,test scratch and captures remain ignored.
Existing tracked unique images,definitions,seeds,fixtures and evidence are retained.
No history rewrite,force push or mass evidence deletion occurred.

## Verification and scope

Baseline,post-move and post-merge Ruff check/format and local Fast PASS, including14
Python tooling tests and runtime schema/founder/core/navigation/planner/packing gates.
[PR quality37385973246](https://github.com/denni1cd/roomscale/actions/runs/37385973246)
and [merged main quality37386200728](https://github.com/denni1cd/roomscale/actions/runs/37386200728)
PASS. Actions YAML parses and remains byte-identical. Protection still applies after
merge. No production gameplay,test,launch,workflow,scenario or architecture code changed.
Full90/60/60soaks were deliberately not rerun for this documentation/ignore-only pass.
Compact real verification evidence is in validation.json; raw scratch is ignored.

All substantive acceptance criteria AC01–AC22 pass. Final report-only protected delivery
receives its own required CI and final-main verification, recorded in task delivery.
No remaining user action is required for protection or hygiene. Temporary branch is kept.
Deferred debt remains deferred: pipeline decomposition,raw task dictionaries,camera
private APIs,legacy observer inheritance,geometry/constants,asset readiness,
multi-civilization ownership and shared-resource authority. No gameplay or POC work.
