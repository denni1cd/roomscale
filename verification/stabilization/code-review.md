# Repository review before stabilization

Reviewed accepted baseline `923e8e600e43a892a21b846e908c9036194e0747` before
significant source refactoring. Review categories cover correctness, state authority,
coupling, deterministic order, fixture legitimacy, tooling, documentation and artifacts.
No gameplay additions or rebalancing are proposed.

## Scope and method

All active Python (2), PowerShell (16) and GDScript sources (61; all active bodies, including pipeline_proof) were inventoried.
Independent reviews read runtime systems, presentation/visual/asset systems and every
active test/evidence driver. The scene, project settings, visual catalogs/materials,
shader, generated desk provenance/import settings and five room configurations were
inspected. The reconstruction skill and four source/reference Markdown files, current
RoomDefinition contract and milestone guides, historical plans/status reports, evidence
references and tracked artifact sizes/duplicate hashes were inspected. Historical
snapshot GDScripts under verification are evidence, not active runtime programs.
The review does not assert correctness from lint or static inspection alone.

Baseline verification: three fresh canonical runs PASS; POS-001 eight-day production
observer PASS with zero invariant violations. Baseline Ruff default check: 15 findings;
both Python files require formatting. Ruff 0.15.20 is installed in an ignored local
virtual environment using ordinary venv/pip tooling. Godot is the existing pinned
4.7.2 runtime, not an engine upgrade.

## Critical

None identified.

## High

| ID | File/system and evidence | Issue and risk | Proposed action / disposition |
|---|---|---|---|
| H01 | `scripts/poc471_campaign.py`, execute, old lines 176-202 | Existing result.json survives a rerun; timeout sets process=None, then the old PASS can be loaded and assigned current provenance. False acceptance of unexecuted source. | Fix now: clear stale output; timeout/nonzero/engine errors always fail; reproduce with controlled subprocess tests. |
| H02 | `scripts/pipeline_proof.gd`, population initialization, old lines 1436-1453; RoomDefinition permits population 1..150 | Fixed five-row divisor pushes larger valid starts outside their spawn; skipped failed positions leave sparse IDs while simulation/growth index citizens by ID. Invalid roster and possible crashes. | Fix now: atomically validate the complete roster, derive rows, preserve accepted canonical positions, fail explicitly when no complete legal roster exists. |

## Medium

| ID | File/system and evidence | Issue and risk | Proposed action / disposition |
|---|---|---|---|
| M01 | PowerShell Start-Process ArgumentList in smoke/Fast/validator/POC4/45/46/47/visual runners | Array arguments join into an unquoted command string on Windows; a project path with spaces breaks launch. | Fix now with shared ProcessStartInfo.ArgumentList invocation; verify real paths with spaces. |
| M02 | Same runners, especially FAST timeout and VISUALS cleanup | Repeated process lifecycle code drift: discarded timeout diagnostics, unbounded wait after kill, leftover temporary files. | Fix now: bounded process cleanup, capture both streams, retain useful logs and propagate failures. |
| M03 | Script output path boundaries | Caller-relative and project-relative paths differ; launches outside project write evidence in unexpected locations. | Fix now with consistent root-relative resolution and explicit absolute-path handling. |
| M04 | TEST_ROOM_SCALE.ps1 / historical specialized entry points | Top-level runner exposes only old smoke; current focused/canonical/regression/robustness/soak hierarchy is unclear. | Fix now: documented modes, existing runner delegation, practical Fast; retain legacy -Room behavior. |
| M05 | Python tooling / both campaign and evidence scripts | No Ruff configuration; implicit encoding and compressed statements at important file/process boundaries. | Fix now: high-value E4/E7/E9/F/I rules, formatting, UTF-8, boundary hints; document historical evidence exclusions. |
| M06 | scripts/poc471_evidence.py report publication | Affirmative final report is overwritten even when consistency errors exist. Failed audit can publish misleading acceptance text. | Fix now: publish diagnostics on failure, preserve accepted reports until all audit gates pass. |
| M07 | scripts/surface_navigation.gd reverse surface-to-floor branch, old lines 101-105 | Empty floor exit still yields reachable=true and a path ending at link base. Citizen can be stranded rather than reaching requested depot. | Fix now: reject unreachable exit; focused deployed-link fixture. |
| M08 | scripts/resource_system.gd derive vs RoomDefinition appearance validation | Validator accepts material case-insensitively, derivation compares original case. Accepted WOOD/METAL silently loses salvage yields. | Fix now: normalize the accepted appearance material; focused schema/derivation regression. |
| M09 | RoomDefinition effective resource profile / Salvage.configure | harvestable=true on unknown material without stages is accepted but immediately depleted. Authoring boundary admits unusable resource. | Fix now: validate effective harvestable stages; retain explicit valid overrides and protected-object semantics. |
| M10 | POC45/46 scenario observers | Approximately 190 lines of near-identical scenario verification can drift. | Defer broad inheritance/hooks: preserving independent existing assertions outweighs new framework risk in this cleanup. |
| M11 | m4/m5/m6 visual evidence, poc47_live, poc46_camera_visual | save_png errors can be followed by PASS; camera driver neither creates output directory nor checks write. Evidence can claim nonexistent images. | Fix now: small shared checked capture helper, explicit failure propagation. |
| M12 | fishbowl_camera_director / strategy_camera | Director reaches into private camera focus and transform internals. Ownership is unclear. | Defer wider camera API change; documented single-camera scene contract, no current lifetime defect found. |
| M13 | Historical test entrypoints / inherited ROOMSCALE_ROOM_FILE | Room selection may be overridden by parent environment. Tests can exercise a different definition. | Fix now at top-level configuration isolation; specialized production scenario paths continue their current explicit settings. |
| M14 | README / PROJECT_PROGRESS / old plan files | New engineer must reconstruct current behavior from chronological POC prose; some old status text appears current. | Fix now: current README/architecture/test guide and clear historical labels. |
| M15 | .gitignore / verification artifacts / Godot import scanning | Broad milestone ** exceptions admit whole future campaigns; local caches not generally ignored. Godot imports historical screenshots unnecessarily. | Fix now: opt-in compact receipts/fixtures, ignored run scratch and cache directories, verification/.gdignore; preserve tracked evidence. |
| M16 | simulation/development/population/task ownership boundaries | Production calls engine _process, private route/grid/task fields and mutates task dictionaries. Multiple writers create maintenance risk. | Fix explicit stepping/replan/grid-refresh contracts where bounded; defer broad task/domain object migration, namespaces and shared-world ownership. |

| M17 | Room object IDs / pipeline_proof and apply_salvage_stage | Valid arbitrary object IDs are sanitized as Node names, but salvage looks up a raw NodePath. Stage visuals and geometry removal can silently fail. | Fix now: explicit object-root lookup keyed authored ID; retain schema compatibility. |

## Low

| ID | File/system and evidence | Issue and risk | Proposed action / disposition |
|---|---|---|---|
| L01 | TEST_ROOM_SCALE_POC47.ps1 Days==60 block | No jobs use 60 days; unreachable copied stability gate. | Remove now; document expensive historical All semantics. |
| L02 | scripts/poc471_evidence.py dynamic import + unused subprocess | Unnecessary import machinery at module load. | Simplify now while preserving direct script invocation. |
| L03 | Path lengths/rest offsets/need rates | Identical path length methods and several repeated domain values; risk of accidental future divergence. | Extract only identical path helper if clearly useful; defer global constants/rest-target redesign. |
| L04 | citizen get_travelled_distance, surface investigation_route, construction traversal_arrival | Full reference search shows no consumers. | Remove now after confirming exact references; retain used legacy APIs and all regression paths. |
| L05 | fishbowl_camera_director old lines 68-70 | governor/directive framing branch is unreachable behind event filter. | Remove now. |
| L06 | asset_pipeline/generate_desk texture wait | Fixed one-second delay for async texture readiness may be brittle on other hosts. | Defer to asset regeneration; no art/asset pipeline feature work here. |
| L07 | Historical duplicate PNG evidence | SHA-256-identical images occupy multiple historical folders. | Deduplicate only exact image bytes with a replacement manifest; keep all unique images, repeated execution receipts and reproduction inputs. |

| L08 | pipeline_proof.gd | Large rendering/input/simulation composition class; two unused wrapper/build methods. | Remove proven dead methods; defer class decomposition to avoid broad visual/scene churn. |

Counts: **0 Critical, 2 High, 17 Medium, 8 Low**. Proposed dispositions are not proof
of completed fixes; final report maps each finding to its implemented/deferred result.

## Authority and test legitimacy

RoomDefinition owns validated authored input. Floor/surface navigation owns geometry
and deployed links. ResourceSystem owns finite source remaining/reserved/extracted
ledgers; Salvage owns finite stages/authorization/yield; Economy owns available,
reserved, transit, delivered and consumed inventory; Coordinator owns task identity and
lifecycle; Citizen owns physical position/current work; Simulation owns fixed tick/order
and service wiring. Development owns construction projects/capabilities after completion;
Population owns growth policy and creates actual entities; NeedSystem owns needs/rest
slots. HUD, narrative and camera consume snapshots/events and must not create stock,
capabilities, citizens or links. See the new architecture document for detailed contracts.

Current economy/task/project dictionaries are intentionally retained. Do not convert
all dictionaries to classes or duplicate services for another civilization: finite source,
salvage and navigation authority would diverge. Citizen ID==array index, fixed scene node
names and legacy established-room interior anchors are explicit current contracts.

POC45/46 Fast stock/position/project mutation is controlled unit fixture setup, not
production integration proof. POC4 scenarios exercise player intent. POC45/46/47
scenarios and POC471 observers use earned production progression, physical extraction,
hauling, labor, population admission and continuously checked ledgers/navigation. No
cleanup integration test may inject resources, teleport entities or grant completion.
Historical compatibility M2-M6 and legacy non-economy construction remain covered.
