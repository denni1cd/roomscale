# POC 3 visual implementation

## Scene refinement

`settlement_composition.gd` derives streets, utility lines, satellite housing,
stores and work-yard machinery from existing landmarks. It adds no collision
or navigation data. Street boards use MultiMesh; utilities clear citizen height.
Solid decorative props stay in the original reserved building yards. The human
pencil is approximately seven inches long and the coin one inch across.

The shared floor shader uses world coordinates, low-contrast grain, roughness
variation and derivative-antialiased board joints that fade with distance.
The floor is more neutral than miniature stained wood, copper and warm windows.
Nonwood photo floors keep their appearance mapping.

F3 switches between the default compact HUD and existing diagnostics.
Reach / Explore remains available in both. Close captures temporarily hide the
overlay without changing simulation; wide captures preserve state in sidecars.

Builders face an assembly block at the actual construction site. Their hammer
follows the animated arm endpoint during active work. An open-frame foundation
exposes the worker position, and a local work lamp improves shadow readability.
Tasks drive chest accents, the existing pack/tool/cargo and a safety clip.

The generated desk adds leg collars; chairs have stretchers and upholstery
buttons; shelves have face stiles, cornice and plinth. The canonical refinement
captures and ten-question assessment are in `verification/poc3/refinement/review.md`.
Earlier reviewed captures are unchanged. To preserve earlier performance data,
set `ROOMSCALE_PERFORMANCE_PATH=res://verification/poc3/refinement/performance.json`
when running the existing benchmark script alone.

Work is on `codex/roomscale-poc3-visual-fidelity`; the authoritative scope is
`RoomScale_POC_3_Project_Plan.md`. Evidence and limitations live under
`verification/poc3/`. Baseline details are in `verification/poc3/m0-status.md`.

`scripts/visuals/visual_resolver.gd` loads `visual/catalog.json`. It resolves
appearance archetype first, then semantic kind, then defaults. It only creates
render nodes. Floor obstacles, surface geometry, selection colliders, and
traversal continue to derive from RoomDefinition and real simulation state.
Missing, unsupported, empty, or unimported preferred assets produce an
actionable warning and call the existing procedural renderer. Existing photo
appearance recipes remain available as fallbacks.

Imported scene sources live under `assets/`. The resolver wraps the source,
applies catalog yaw, measures transformed mesh bounds, fits dimensions to
RoomDefinition, and centers X/Z while placing the lowest Y at the object base.
Sources are never destructively scaled. Nonuniform fitting is currently the
catalog default; authored props must tolerate that policy. Imported art must
not contain gameplay scripts or collision authorities.

Resolver tests:

```powershell
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/visuals/visual_resolver_test.gd
./TEST_ROOM_SCALE_FAST.ps1 -LogPath verification/poc3/logs/fast.log
```

Reproduce baseline-equivalent benchmark views and complete real gameplay:

```powershell
./TEST_ROOM_SCALE.ps1 -Room room_a -CaptureVisuals -VisualDirectory verification/poc3/final -LogPath verification/poc3/logs/final-room-a.log -TimeoutSeconds 360
```

The capture runner records camera recipes, engine, viewport, render counters,
and live-subject task/state where applicable. Additional phases include
`settlement-close`, `citizen-close`, `resource-carry-close`, `grapple-complete`.
Close subjects are followed for capture; no acceptance state is staged.
Existing phase captures are retained for comparisons. FPS is capped and samples
must not be described as uncapped throughput.

The canonical final 18-phase set is `verification/poc3/final-benchmark/`.
Earlier iterations are preserved under `final-reviewed/`, `hero-corrected/`
and other named milestone directories. Fixed subject cameras use a 2in
distance and a front-quarter yaw relative to the live subject. Camera sidecars
record the resulting transform and the real task/state. Keep failed iterations
for diagnosis; see the acceptance record before using a screenshot as evidence.

Build the local AI-authored GLB asset and run presentation/performance checks:

```powershell
./BUILD_ROOM_SCALE_ASSETS.ps1
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://scripts/visuals/presentation_test.gd
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --path . --script res://scripts/visuals/performance_benchmark.gd
```

The asset experiment uses an original procedural modeling recipe authored by
the implementation AI, exports GLB through Godot's GLTFDocument, validates its
header/version/length, imports it, validates mesh/material bounds, tests yaw and
nonunit dimension fitting, then resolves it in the real room. It needs no
paid service, credentials or editor repairs. Source provenance is beside the
asset. The pipeline is a tested local alternative, not a claim of neural 3D
generation. Generated art has no hidden runtime service dependency.

Citizen fine details have a 12in visibility threshold sampled every 0.4s;
body/head/limbs remain visible, and simulation continues at every distance.
Materials and rounded furniture/character meshes are shared. Machinery details
reveal from real stage work, and the traversal connection is created only after
the visible cable is attached and settles. Selected pressure steam follows
actual building/deploying state.

The performance script loads the real scene and 50 active citizens, disables
VSync in that process, warms each view, samples at least 360 frame intervals
over at least eight seconds at room,
settlement and citizen scales, and records median/p95/max, FPS, draw calls and
primitives to `verification/poc3/performance.json`. Run it alone for comparable
numbers. Concurrent/capped capture telemetry is retained but not used as an
isolated renderer throughput claim.

`visual/materials.json` and `scripts/visuals/material_library.gd` define shared
lit material categories and deterministic noise textures. Integration and
visual approval status must be recorded per milestone before claiming success.
