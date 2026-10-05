# Stabilization acceptance commands

All final acceptance uses frozen source/harness
`ef5ebd325351ae6c3702a7ab8d89266aafed59ea`, pinned Godot 4.7.2 and Python 3.13.
Run from repository root in PowerShell 7 with .venv activated. Raw output is ignored;
compact audited evidence is published only after success. Tests produce actual current
Git SHA receipts; do not restamp another source revision as this accepted freeze.

```powershell
python -m ruff check .
python -m ruff format --check .
python -O -m unittest discover -s scripts -p test_tooling.py
./TEST_ROOM_SCALE.ps1 -Mode Fast -OutputDirectory verification/stabilization/runs/final
./TEST_ROOM_SCALE.ps1 -Mode Canonical -OutputDirectory verification/stabilization/runs/final
./TEST_ROOM_SCALE_POC472.ps1 -Mode Full -Workers 8 -OutputDirectory verification/stabilization/runs/final/final
./TEST_ROOM_SCALE_POC472_REGRESSIONS.ps1 -OutputDirectory verification/stabilization/runs/final/regressions
./TEST_ROOM_SCALE_POC472.ps1 -Mode Control -OutputDirectory verification/stabilization/runs/final/observer-control-final
./TEST_ROOM_SCALE_POC472.ps1 -Mode Reproduce -Scenario verification/poc472/supplemental/EXTRA-NARROW-01/config.json -OutputDirectory verification/stabilization/runs/final/supplemental
./TEST_ROOM_SCALE_POC472.ps1 -Mode Reproduce -Scenario verification/poc472/packing-development/PLACE-031/config.json -OutputDirectory verification/stabilization/runs/final/packing-prefix-replay
python verification/poc472/gather_evidence.py --evidence verification/stabilization/runs/final --manifest verification/stabilization/freeze-manifest.json --regressions verification/stabilization/runs/final/regressions
```

Use `-Workers 8` (separate parameter/value); use `-PythonExecutable` for an explicit
venv interpreter if it is not activated. Each room below also receives structural/
runtime validation and the full M2-M6/M8 production smoke with a 1200-second limit:

- room_a
- room_b
- verification/poc2/candidates/primary/attempt-7/room_photo_luna.json
- verification/poc2/candidates/secondary-room/fresh-context/room_hearth_living_room_fresh.json

```powershell
./VALIDATE_ROOM_SCALE.ps1 -Room room_a -LogPath verification/stabilization/runs/final/validation/room_a.log
./TEST_ROOM_SCALE.ps1 -Mode Smoke -Room room_a -TimeoutSeconds 1200 -LogPath verification/stabilization/runs/final/legacy/room_a.log
```

Expanded 15 shared commands and actual pass/error-free markers are in the compact final
audit. The renderer proof runs `poc46_camera_visual_test.gd` through the shared bounded
process helper with a current ignored visual directory, requires an actual renderer,
checks PASS/exit/log cleanliness and inspects the resulting PNG/JSON. Invalid-output
and headless rejection fixtures are explicitly separated from successful visual proof.

For exact historical reproduction, create a detached checkout of the frozen SHA and
copy its published freeze manifest there before auditing. Current main includes only
subsequent documentation/evidence changes. New runs on main correctly receipt its actual
HEAD; use a fresh local manifest with that actual HEAD and verified unchanged source
hashes, without overwriting accepted committed manifests. Historical 472 audit requires
its own frozen source, rather than running against changed stabilization source.

Before main merge, inspect normal diff/history, clean tree, source manifests and all
current gates. No force push, history rewrite, automatic release tag or branch deletion.

