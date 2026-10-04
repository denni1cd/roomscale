# Evidence and artifact review

Baseline evidence occupied 353.05 MiB across 3,359 tracked files (all milestones).
The entire Git tree was measured and PNG copies compared by SHA-256. Historical
commits are preserved; deleting files here does not shrink Git history.

## Keep permanently

- Final milestone reports, acceptance matrices, compact campaign/soak summaries,
  source freeze/change manifests and performance qualifications.
- All unique canonical visual images and sidecars. POC3 human visual acceptance
  remains a historical outstanding judgment; cleanup does not grant it.
- RoomDefinition candidates and unique rejected/bug fixtures, including pre-fix
  source snapshots and failed reproduction packages needed by root-cause reports.
- POC471 final/exploration definitions, configs and all independent execution
  receipts. The later settlement-planner campaign depends on these exact inputs.
- Independently executed repeatability records, even when resulting JSON/log bytes
  are identical. Identical outcomes are meaningful determinism evidence.

## Archive externally / regenerate

Large raw successful campaign logs, per-tick timelines and screenshots from future
runs are reproducible from the retained config/definition/seed and exact command.
Do not publish every development iteration. Keep compact final summaries and source
provenance in Git, and deliberately select needed raw evidence with `git add -f`.
No unique historical raw evidence is removed by this stabilization; archiving it
would require a durable archive location and a reference audit beyond this task.

## Delete

Exactly 20 redundant PNG copies (11,324,795 bytes; 10.80 MiB) have identical SHA-256
bytes to retained images. `artifact-manifest.json` maps every removed path to its
retained image/hash. Historical generated sidecars retain original output locations;
use the manifest when reviewing those old receipts. Original files are recoverable
from baseline Git history. No JSON, log, seed, fixture, unique image or test is deleted.

## Keep ignored

`verification/stabilization/runs/`, future raw milestone runs/replays, temporary
stdout/stderr, generated import/translation sidecars, engine .godot state, downloaded
.tools runtime, local .venv, Python/Ruff caches and developer environment files.
The former blanket `!verification/poc471/**` rule is removed. Existing tracked files
remain tracked; new raw output requires conscious inclusion. Authored photo candidates,
regression fixtures and compact root reports retain explicit allowlists.

`verification/.gdignore` stops Godot importing evidence images/snapshot scripts;
production regression harnesses load RoomDefinition fixtures directly via FileAccess.
Source script UIDs and asset import configuration are source metadata and are retained.

## Reference and safety checks

Deletion is restricted to resolved regular PNG paths inside verification, and each
removed/retained pair is rehashed immediately before removal. Markdown references to
removed exact image paths are redirected to the retained copy; historical machine
receipts are preserved and mapped in the manifest. All non-PNG evidence is untouched.
Final tests must confirm direct fixture loading works with .gdignore.
