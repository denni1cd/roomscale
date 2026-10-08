# RoomScale POC 5 verification and implementation report

Branch: `feature/poc5-multi-civ-conflict`. Accepted main baseline:
`8621b08f9156cdeda305f90eb5442e5947d11f00`. Frozen implementation:
`502cc1ef65d6b978be7d2092594f3ad95917160d`. Subsequent evidence-only commit adds
this report, normalized source hashes and deliberately selected images. PR [#4](https://github.com/denni1cd/roomscale/pull/4) targets main and is not merged.
The final evidence commit is provided in the delivery.

## Architecture

One WorldSimulation initializes one ResourceSystem and SalvageSystem and owns fixed time,
territory, combat, bundle visuals, occupancy roster and global citizen ID allocation. The
existing single FloorNavigation/SurfaceNavigation remain the live movement authorities.
CivilizationSimulation serves as each society runtime, with independent definition,
roster, needs, economy, development, population and governor/planner. Compatibility
wrappers delegate advance/step to the world, so old founder observers retain production
ordering. Scoped boards and traversal projects hold shared navigation/source references.
Tasks and tickets carry instance IDs. Manual Reach/Explore filters the combined world
roster by ownership/life/duty; direct player/project/traversal/exploration assignment
rejects foreign or military-bound citizens before changing their existing task. Claims reject foreign/dead citizens. Source
reservations track their owners; foreign extraction/cancellation cannot consume/release
another owner's quantities. Bundles bind global citizen and instance identity and reject
foreign inventory receipt. Every production tick conserves finite source and inventory
state. Shared salvage has once-only stage progression and society-specific legal approaches.

Development considers all world occupants, other societies' project/future reservations,
rest/home/work access and the objective. Its IDs are globally unique. Completed physical
obstacles refresh the shared grid and replan every traveling citizen. Traversal commitment
is serialized by shared objective; existing links remain available to either civilization.

## Canonical gameplay

Two twelve-person founder societies start with ordinary authored 20 food/30 water and no
construction materials or completed buildings. The dedicated room preserves accepted
room_poc47 data and authors two generic start slots plus a larger single floor spill,
allowing two societies to recover reserves without duplicated sources. Both physically
haul and earn shelter; both continue normal development after battle.

The shared `frontier_cache` strategic region is the frontier supply approach. At tick
1316 actual scouts make contact and overlapping claims become hostile/contested. Each
side commits three existing citizens and marches to distinct legal stations. Both forces
fully arrive before firing. Equal 100 health, 10 damage, one-second attack interval and
six-inch range apply to both. There is no tactical randomness or civilization combat bonus.

All five accepted runs resolve identically: 55 attacks, zero Clockwork casualties, one
Verdant casualty, Verdant retreat, Clockwork capture at tick 1620 (162 seconds). Morale
ends at .865/.5816666667. Three Clockwork and two Verdant survivors physically return and
each completes ordinary work. Living populations remain 12/11 after another 100 seconds.
The dead CitizenAgent remains lost, stationary and excluded from working/living counts;
future replacement uses the usual earned production admission policy. No mortality other
than combat is added. Initiative resolves in global citizen-ID order; Clockwork's earlier
roster IDs are an explicit starting condition, not a balance claim.

Second-room Maker Loft derivative also passes: different anchors, first contact/commit
at its own production ticks, Clockwork capture at tick 1973, one Verdant casualty,
retreat and both populations surviving. Full records, transition events, society projects
and normalized source/image hashes are in [acceptance-summary.json](acceptance-summary.json).

## Exact final verification commands

PowerShell 7 and the existing repository `.venv` provide the working tooling environment.
All gates below finished successfully. Engine/script errors, stale results, missing
markers, failed assertions and timeouts remain hard failures.

| Command | Exact result |
|---|---|
| `python -m ruff check . (repository .venv interpreter)` | PASS: All checks passed; exit 0 |
| `python -m ruff format --check . (repository .venv interpreter)` | PASS: 6 files already formatted; exit 0 |
| `./TEST_ROOM_SCALE.ps1 -Mode Fast -PythonExecutable ./.venv/Scripts/python.exe` | PASS: ROOMSCALE_CATEGORY_PASS category=Fast; exit 0 |
| `./TEST_ROOM_SCALE_CIVILIZATIONS.ps1` | PASS: ROOMSCALE_CIVILIZATION_CHECKS_PASS definitions=true verdant_visual=true; exit 0 |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization clockwork -LogPath verification/stabilization/runs/poc5/manual-ownership-smokes/room_a-clockwork.log` | PASS: M2, M3, M4, M5, M6, M8 and civilization production smoke; exit 0 |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_a -Civilization verdant -LogPath verification/stabilization/runs/poc5/manual-ownership-smokes/room_a-verdant.log` | PASS: M2, M3, M4, M5, M6, M8 and civilization production smoke; exit 0 |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_b -Civilization clockwork -LogPath verification/stabilization/runs/poc5/manual-ownership-smokes/room_b-clockwork.log` | PASS: M2, M3, M4, M5, M6, M8 and civilization production smoke; exit 0 |
| `./TEST_ROOM_SCALE_SMOKE.ps1 -Room room_b -Civilization verdant -LogPath verification/stabilization/runs/poc5/manual-ownership-smokes/room_b-verdant.log` | PASS: M2, M3, M4, M5, M6, M8 and civilization production smoke; exit 0 |
| `./TEST_ROOM_SCALE_CONFLICT.ps1 -RunCount 5 -OutputDirectory verification/stabilization/runs/poc5/manual-ownership-repeatability` | PASS: 5/5 identical; all five exit 0 |
| `./TEST_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_b -OutputDirectory verification/stabilization/runs/poc5/manual-ownership-second-room` | PASS: Clockwork capture tick 1973; exit 0 |
| `./TEST_ROOM_SCALE_CONFLICT.ps1 -CaptureVisuals -OutputDirectory verification/stabilization/runs/poc5/manual-ownership-visual` | PASS: real graphical renderer, same strategic outcome; 14 PNGs captured, 13 selected; exit 0 |
| `./TEST_ROOM_SCALE_POC47.ps1 -Mode Scenario -OutputDirectory verification/stabilization/runs/poc5/manual-ownership-founder -PythonExecutable ./.venv/Scripts/python.exe` | PASS: earned eight-day single-society founder progression; POC47_BATCH_PASS runs=1; exit 0 |
| `Godot 4.7.2 --headless --path . --editor --import` | PASS: import completes without script/engine errors; exit 0 |
| `git diff --check` | PASS: no whitespace errors; exit 0 |

## Baseline and intermediate diagnostics

Before editing, git status/branch/log/fetch, main switch/ff-only pull and ancestry check
confirmed the requested main SHA. The two untracked user prompt/plan files were preserved.
Baseline Fast and all four existing civilization/room smokes passed before refactoring.
Owner identity Fast plus three initial smokes passed; the final owner smoke was run with
the world extraction, whose Fast and complete four-smoke matrix passed before enabling
coexistence. Final verification above reruns the complete required coverage.

Initial default `python` lacked Ruff. The existing `.venv` supplied pinned Ruff 0.15.20.
Sandboxed Fast encountered Windows temporary-directory permission errors, and sandboxed
smokes completed gameplay but failed on Godot user-log permission errors. Approved runs
outside the sandbox passed; the harnesses were not weakened. One approval review timed
out; its permitted retry succeeded. Phase A's planner fixture needed its actual production
instance owner when reserving a directly staged fixture bundle. Phase B initially exposed
GDScript inference errors after removing default resource objects; typed world references
fixed them. An isolated fixture now explicitly creates its local test authorities. All
of these diagnostic failures were repaired before final acceptance.

Rendered review found unreadable objective labels, premature battle captures, overlapping
stations, a stale shared-salvage work approach and global-ID shelter allocation. Those
issues were fixed and all final gates rerun. A final review found manual Reach/Explore still received the
combined roster; owner/life/duty filters and direct-assignment guards closed that path,
with negative probes on real tasks and a complete verification rerun. Earlier capture iterations/raw logs remain
ignored. This report publishes only deliberate evidence, never a giant capture directory.

## Rendered evidence and limits

Thirteen reviewed PNGs total about 2.7 MB: room overview, contact/objective, both forces
marching, active battle, both weapons/citizen figures, retreat, capture, both societies
continuing, both earned settlement styles and restrained casualty. See [evidence](evidence/).
Far room shots keep half-inch citizens tiny; close shots reveal the same animated figure
with held brass/barrel or thorn/leaf attachments. Bolts and seed/pollen flashes are
cosmetic. The captured marker changes to the winner's industrial gear; an organic marker
exists for a Verdant victory. No gore or projectile physics is present.

Limits/debt: one strategic anchor and one encounter per scenario, a 600-second loser
commitment cooldown, no diplomacy/trade/treaties/pursuit, no asymmetric balance, no
civilian targeting, no combat during vertical traversal, no automatic repeated wars.
The procedural weapon pose and distant retreat figures are modest POC presentation;
fallen silhouettes can foreshorten by camera angle. General multi-instance HUD/tool
selection and broader multi-society traversal visual review remain follow-up work. The
large composition root retains a compatibility startup teardown before the fixed clock
begins; it never creates duplicate finite resources or navigation authorities. Society
boards/projects remain scoped service nodes rather than a generalized entity framework.
Current single-civilization Clockwork/Verdant contracts and both-room production smokes
pass, and an additional earned founder scenario passed. No expensive long soaks are
claimed. GitHub Actions was extended with five conflict repeats and second-room coverage;
remote execution status is reported separately from local acceptance. The PR is not merged.
