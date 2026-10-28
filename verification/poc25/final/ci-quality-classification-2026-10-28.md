# POC 2.5 GitHub Actions Quality Classification — 2026-10-28

## Runs reviewed

| Run | Commit | Result | Failure classification |
|---|---|---|---|
| [40738817339](https://github.com/denni1cd/roomscale/actions/runs/40738817339) | `7d550c425ade270e2bf36d82d9c5e5e3d0bf19d3` | Failed | POC 2.5 authoring-code formatting regression. `ruff format --check .` flagged ten v053-v055 MPFB worker or candidate-snapshot files. Three civilization smoke jobs passed; one matrix job was cancelled. |
| [40756019436](https://github.com/denni1cd/roomscale/actions/runs/40756019436) | `f0bcbc31dc2645ba88856b778de8af72ad92b093` | Failed | POC 2.5 authoring-code lint regression. `ruff check .` reported 16 findings in eight v073-v076 MPFB Blender worker files (canonical workers and preserved candidate-local copies): unsorted imports (`I001`) and unused `base` locals (`F841`). The fast job stopped at Python quality before its remaining checks. The conflict check and all four civilization-smoke jobs passed. |

Neither run produced evidence of a gameplay, renderer, registry, or citizen-runtime regression. Both failures are still POC 2.5 regressions because the repository's required Python quality job covers its versioned authoring workers.

## Repairs in the local review package

- Applied Ruff formatting to the v053-v055 worker scripts and the v054-v055 candidate-local snapshots flagged by run `40738817339`.
- Sorted imports and removed unused `base` assignments in both the canonical and preserved candidate-local v073-v076 Blender worker sources.
- Cleaned the v087 worker and its preserved candidate-local copy. The pressure-gauge builder is still called for its scene side effect; only its unused return-value assignment was removed. This keeps the v087 generated output intact.
- Ruff check and format check pass across all 47 tracked Python files plus the six new v087, Grapple v009, and Desk v058 worker sources/snapshots included for review. No asset evaluation, candidate status, incumbent, or production registry was changed by this code-quality repair.
- The exact local command output is preserved in [ruff-quality-repair-rerun.log](ruff-quality-repair-rerun.log).

## Current-run status

GitHub Actions run [40776228395](https://github.com/denni1cd/roomscale/actions/runs/40776228395) completed successfully on review-package commit `73e5e1b1be56c6a2d683f82d9f4c4c48cf79c738`. All six jobs passed: Python quality and focused/startup regressions, conflict checks including the second room, and Clockwork/Verdant civilization smoke in Room A and Room B. This verifies the formatting/lint repairs and the committed review package. GitHub emitted a non-blocking Node.js 20 deprecation annotation for checkout/cache actions; it did not fail any job.
