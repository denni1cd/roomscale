> Historical milestone plan. Current project behavior and engineering commands are described in README.md and docs/ARCHITECTURE.md. This file retains its original milestone scope.

# RoomScale POC 3 — Visual Fidelity & Automated Asset Pipeline

## 1. Purpose

RoomScale POC 1 proved the core tiny-civilization gameplay loop.

RoomScale POC 1.5 established that the same civilization simulation can operate against multiple data-driven `RoomDefinition` inputs without room-specific gameplay code.

RoomScale POC 2 establishes the photo-to-room boundary:

**ordinary room photographs → multimodal AI + reconstruction skill → RoomDefinition → RoomScale**

POC 3 exists to prove the next boundary:

> Can RoomScale render its rooms, civilization, citizens, structures, and traversal machinery at a level that looks like a compelling stylized game rather than a blockout or engineering visualization, while preserving the existing data-driven simulation architecture and requiring no manual asset-authoring workflow from the user?

POC 3 is not a full production-art pass.

It is a focused proof that RoomScale can support a scalable visual-content pipeline.

The target is a polished vertical slice containing:

- one room;
- one miniature settlement;
- approximately 50 citizens;
- one major elevated target;
- one complete grapple/traversal sequence;
- improved lighting, materials, effects, animation, and visual presentation.

The final result should demonstrate that the RoomScale concept can be visually impressive without abandoning the automation and agent-driven development constraints that define the project.

---

## 2. Central POC Question

The primary question is:

> Can Aphrael and GPT-6.1 Sol autonomously transform the current blocky RoomScale presentation into a visually compelling stylized 3D vertical slice using a reusable asset-resolution and asset-generation pipeline, without manual Blender modeling, manual Godot scene construction, or coupling gameplay to presentation assets?

POC 3 succeeds only if the improvement is architectural and reproducible.

A one-off hand-built showcase is insufficient.

---

## 3. Primary Development Model

Primary implementation model:

**GPT-6.1 Sol**

Aphrael acts as orchestrator, reviewer, acceptance-gate enforcer, and escalation layer.

Sol is responsible for:

- repository inspection;
- visual architecture;
- asset-pipeline implementation;
- procedural modeling where appropriate;
- automated asset import;
- material systems;
- shaders where appropriate;
- lighting;
- particle effects;
- citizen visual redesign;
- settlement visual redesign;
- traversal machinery visual redesign;
- animation;
- performance testing;
- screenshot generation;
- regression testing;
- documentation;
- verification evidence.

Do not silently switch implementation to another primary coding model.

If Sol cannot complete a milestone after reasonable attempts, preserve the failure evidence and report the blocker so the user can decide whether to escalate.

POC 3 is partly intended to test the practical capabilities of GPT-6.1 Sol on an art-heavy, engine-integrated task.

---

## 4. Non-Negotiable User Constraint

The user is not the 3D artist, Blender operator, Godot level designer, texture artist, or manual asset integrator.

The implementation must not require the user to:

- model assets in Blender;
- edit meshes;
- unwrap UVs;
- paint textures;
- create materials manually;
- rig characters manually;
- manually place objects in Godot;
- configure import settings object by object;
- repair generated geometry;
- fix scene files;
- manually orient or scale imported assets;
- create particle systems in the Godot editor;
- author animations through the Godot editor;
- manually configure lights;
- write shaders;
- write or debug code.

The user may perform a one-time installation, authentication, permission, download, or API-key configuration step if a selected external asset-generation tool genuinely requires it and the agent cannot perform that step automatically.

After the required environment exists, Aphrael/Sol owns the implementation.

If a proposed visual workflow requires repetitive manual art labor, redesign the workflow.

---

## 5. Existing Architecture Must Survive

POC 3 must preserve the architectural boundaries established by POC 1.5 and POC 2.

Conceptually:

`RoomDefinition → gameplay geometry/navigation/simulation`

must remain independent from:

`RoomDefinition semantics/appearance → visual resolution → render assets`

Gameplay must not begin depending on detailed render meshes.

Examples:

- collision/navigation should not depend on the exact polygons of a decorative desk mesh;
- citizen task logic must not depend on citizen model bones;
- traversal logic must not depend on decorative grapple geometry;
- photo reconstruction must not need to understand the internal topology of production art assets.

The visual layer may consume semantic and appearance information from RoomDefinition.

It must not become the authoritative source of gameplay truth.

---

## 6. Visual Resolution Layer

Introduce a formal presentation boundary.

Conceptually:

`RoomDefinition object`
→ `semantic identity`
→ `visual resolver`
→ `visual asset/material recipe`
→ `rendered object`

Example:

```text
semantic_type: desk
shape/archetype: writing_desk
material_category: dark_wood
base_color: ...
dimensions: ...
```

may resolve to:

```text
DeskVisual_A
+ dark oak material
+ brass drawer hardware
+ scale/orientation fitting
```

The exact implementation is flexible.

Possible implementations include:

- asset catalog;
- procedural generators;
- parameterized scene templates;
- generated GLB/GLTF assets;
- hybrid assets assembled from reusable parts;
- semantic visual recipes.

The important rule is:

**RoomDefinition describes what the room contains. The visual layer decides how that thing is rendered.**

---

## 7. Procedural Fallback Requirement

Every visual category used by normal gameplay must retain a valid fallback.

If a high-quality asset is unavailable, invalid, incompatible, or fails import, RoomScale must still render a usable representation.

Fallbacks may include:

- existing primitive geometry;
- improved procedural geometry;
- generic semantic replacements.

Example:

```text
preferred desk asset fails
→ fallback stylized procedural desk
→ gameplay continues
```

Visual-asset failure must not make a valid RoomDefinition unplayable.

---

## 8. Art Direction

The target remains:

**stylized 3D diorama**

POC 3 should not pursue strict photorealism.

The human-scale room should be visually believable and recognizable.

The miniature civilization should carry most of the fantasy and stylistic identity.

Desired overall qualities:

- readable silhouettes;
- exaggerated but coherent scale;
- rich material separation;
- warm miniature-world presentation;
- strong depth cues;
- visually clear tiny-versus-human scale;
- enough geometric detail to survive close citizen-level viewing;
- consistent stylization across generated and procedural content.

The scene should resemble a finished stylized strategy/simulation game more than a blockout.

---

## 9. Civilization Art Direction

The first civilization remains:

**steampunk / clockwork**

Core visual language:

- brass;
- copper;
- dark iron;
- stained wood;
- canvas;
- leather;
- gears;
- pipes;
- boilers;
- pistons;
- flywheels;
- chains;
- pulleys;
- ropes;
- cables;
- steam;
- lanterns;
- gauges;
- mechanical tools;
- improvised tiny engineering.

The civilization should visually contrast with the larger ordinary human room.

At a room-level camera distance it should read as a warm, active miniature settlement.

At settlement scale it should reveal machinery, buildings, work areas, and movement.

At citizen scale individual characters, tools, props, and construction activity should remain visually intelligible.

---

## 10. Human Room Visual Target

The room should no longer look primarily constructed from unmodified boxes.

Major objects should have identifiable structure.

For example:

### Desk

Should visibly contain enough detail to read as a real stylized desk, potentially including:

- top surface;
- thickness;
- legs or pedestal structure;
- drawers;
- handles;
- support framing;
- bevels;
- material variation.

### Chair

Should visibly contain:

- seat;
- back;
- support structure;
- legs or base;
- meaningful silhouette.

### Bookshelf / Dresser / Cabinet

Should contain:

- structural frame;
- shelves or drawers;
- handles where appropriate;
- believable depth;
- visual breakup.

### Room shell

Improve:

- wall/floor material response;
- trim/baseboards where appropriate;
- carpet/rug appearance;
- room depth cues;
- lighting response.

Not every piece of clutter must receive a custom asset.

POC 3 prioritizes major visual landmarks.

---

## 11. Furniture Asset Strategy

Create a reusable approach for major human-scale furniture.

The system should support one or more of:

1. procedural stylized asset generation;
2. parameterized reusable meshes;
3. externally generated GLB/GLTF assets;
4. approved reusable asset libraries;
5. hybrid composition from modular parts.

POC 3 should deliberately test whether AI-generated 3D assets can be integrated into the RoomScale pipeline.

Do not assume generated assets will automatically be usable.

They must be validated.

---

## 12. Automated Asset Generation Experiment

POC 3 must include a bounded experiment in AI-assisted 3D asset generation.

The experiment should test whether Aphrael/Sol can autonomously:

1. formulate an asset requirement;
2. create or request the asset;
3. retrieve the resulting asset;
4. place it in the repository or generated-asset cache;
5. validate the file;
6. import it into Godot;
7. determine or correct orientation;
8. determine or correct scale;
9. apply or repair materials;
10. instantiate it through the visual-resolution layer;
11. launch RoomScale;
12. capture evidence that the asset renders correctly.

The pipeline should prefer standard interchange formats.

Preferred:

- `.glb`
- `.gltf`

Other formats may be used only when there is a demonstrated reason.

---

## 13. External Asset/Service Policy

POC 3 may evaluate external asset-generation tools or services.

However:

- no paid service should be introduced without explicit user approval;
- no service should become a hidden runtime dependency;
- generated assets should be stored locally/repository-side when licensing permits;
- service-specific integration should be isolated from RoomScale gameplay;
- credentials must not be committed;
- generated asset provenance should be documented;
- usage/licensing restrictions must be recorded.

If an external service is not suitable for deterministic or automatable use, it may be rejected.

The POC must not depend on the user manually downloading, editing, and re-uploading every generated asset.

---

## 14. Asset Validation

Create automated validation for imported/generated visual assets.

Where practical, validate:

- file exists;
- supported format;
- Godot can import it;
- mesh contains geometry;
- bounding box is non-zero;
- scale is within plausible limits;
- orientation is usable or can be normalized;
- material slots resolve;
- texture references resolve;
- no unsupported external dependency is required;
- asset does not cause load-time errors;
- asset can be instantiated in an automated test scene.

Invalid assets should produce actionable diagnostics.

---

## 15. Asset Normalization

Different generated/imported assets may use different:

- units;
- forward axes;
- up axes;
- origins;
- pivots;
- scale;
- naming conventions.

Create a normalization layer where practical.

The normal workflow should not require manually correcting each asset in Blender.

Normalization may include:

- calculated scale fitting;
- root-node transforms;
- pivot adjustment through wrapper scenes;
- automatic orientation correction;
- material reassignment;
- metadata sidecars.

Do not destructively modify source assets unless necessary.

---

## 16. Visual Asset Catalog

Create a version-controlled visual catalog or registry.

The exact format is flexible.

It should support mapping semantic content to preferred render assets.

Example concept:

```text
desk:
  default: assets/furniture/desk_a.glb
  fallback: procedural_desk
  compatible_styles:
    - modern
    - traditional

chair:
  default: assets/furniture/chair_a.glb
  fallback: procedural_chair
```

The catalog should support:

- semantic type;
- style/archetype;
- asset path;
- expected orientation;
- approximate source dimensions if useful;
- scale policy;
- material overrides;
- fallback;
- optional tags.

Avoid hard-coding asset paths throughout gameplay scripts.

---

## 17. Materials

Create a reusable stylized material system.

At minimum, visually distinguish:

- painted wall;
- carpet/rug;
- wood;
- brass;
- copper;
- dark iron/steel;
- leather;
- canvas/cloth;
- glass where needed;
- rope;
- emissive lamp/window elements.

Materials should respond coherently to scene lighting.

Avoid giving every surface the same roughness/specular response.

The target is material readability, not physically perfect realism.

---

## 18. Geometry Quality

Major close-view objects should no longer rely solely on razor-sharp primitive edges.

Use appropriate methods such as:

- bevelled geometry;
- rounded profiles;
- cylinders with sufficient radial resolution;
- layered geometry;
- decorative trim;
- reusable detail pieces;
- normal maps if available and useful.

Do not spend excessive geometry on areas that are never visible.

---

## 19. Lighting

Create a deliberate lighting presentation.

POC 3 should evaluate and implement appropriate Godot 4 lighting features such as:

- directional/room lighting;
- local practical lights;
- shadows;
- ambient lighting;
- environment settings;
- screen-space or equivalent ambient occlusion where appropriate;
- reflection/environment response where practical.

Lighting must support all three camera scales:

- room view;
- settlement view;
- citizen view.

Do not optimize solely for one screenshot.

---

## 20. Scale Communication

A defining RoomScale requirement is that approximately half-inch citizens feel tiny relative to ordinary furniture.

POC 3 must strengthen this perception.

Use visual cues such as:

- recognizable furniture detail;
- grain/material scale;
- baseboards;
- carpet fibers or stylized carpet texture;
- oversized furniture hardware;
- human-scale object proportions;
- dramatic citizen-to-furniture size contrast;
- localized settlement lighting;
- camera depth cues.

Avoid visual choices that accidentally make the room resemble a miniature dollhouse inhabited by normal-sized people.

---

## 21. Citizen Visual Redesign

Replace or substantially improve the current primitive citizen representation.

Citizens should retain efficient simulation.

Presentation may use a shared base asset with variants.

Required goals:

- recognizable humanoid or clockwork-person silhouette;
- readable head/body/limb structure;
- visual steampunk identity;
- believable size at approximately 0.5 inches;
- clear movement;
- suitable close-up appearance;
- efficient rendering for approximately 50 simultaneous citizens.

Citizens need not become realistic human characters.

Stylization is preferred.

---

## 22. Citizen Role Readability

POC 3 should visually distinguish major active roles where practical.

Candidate roles:

- general citizen;
- explorer;
- builder;
- resource carrier.

Role differences may use:

- helmet/goggles;
- backpack;
- tools;
- color/material accent;
- carried object;
- pose/animation;
- accessory attachment.

Do not create a separate complex character pipeline for every task.

A shared modular system is preferred.

---

## 23. Citizen Animation

Improve citizen animation beyond simple primitive oscillation.

Possible implementation options:

- procedural joint animation;
- lightweight skeleton animation;
- imported reusable animation clips;
- hybrid procedural + skeletal animation.

POC 3 may introduce skeletal animation if it can remain automated.

Required visually distinguishable states should include:

- idle;
- walking/travel;
- carrying;
- building/working;
- climbing/traversing.

Perfect animation blending is not required.

Movement must remain synchronized with actual simulation state.

---

## 24. Settlement Redesign

Upgrade the settlement from blockout structures to a coherent tiny steampunk settlement.

At minimum improve:

- workshop;
- storage depot;
- housing/tents;
- construction/work area.

Possible detail:

- roofs;
- wood beams;
- metal plates;
- pipes;
- chimneys;
- tiny windows;
- doors;
- crates;
- barrels;
- work benches;
- lanterns;
- steam vents;
- mechanical equipment.

The settlement should remain procedurally placeable.

It must not become a manually authored one-off Godot scene tied to one room coordinate.

---

## 25. Settlement Life

Add presentation-only ambient activity where practical.

Examples:

- turning gears;
- piston movement;
- flywheels;
- steam puffs;
- chimney smoke;
- lantern flicker;
- workshop sparks;
- moving gauges;
- tiny mechanical motion.

These effects must not pretend to be simulation systems that do not exist.

Presentation may decorate real simulation state, but must not fabricate gameplay outcomes.

---

## 26. Resource Visuals

Resource transport should visually communicate what citizens are doing.

Replace generic blocks where practical with recognizable bundles or containers representing:

- wood;
- metal;
- mechanical parts.

Possible forms:

- bundled tiny planks;
- small metal plates/ingots;
- gear/component crates.

Carried resources must remain attached to the actual citizen performing the delivery task.

---

## 27. Grapple Redesign

The grappling installation is the visual centerpiece of the POC 3 gameplay sequence.

Upgrade it substantially.

It should visibly communicate:

- base/winch;
- mechanical launcher;
- gears;
- spool/drum;
- supports;
- rope/cable;
- upper attachment point;
- working machinery.

The design should look improvised by a tiny steampunk civilization but mechanically understandable.

---

## 28. Grapple Construction States

Construction must visibly evolve.

Avoid:

```text
nothing
→ complete final machine
```

Instead provide staged presentation such as:

1. marked construction area;
2. foundation/base parts;
3. structural frame;
4. machinery installed;
5. winch/launcher installed;
6. final detail;
7. deployment.

Visual construction stages must remain tied to real construction progress.

They may be coarse.

---

## 29. Grapple Deployment

Deployment should be visually satisfying.

Possible sequence:

1. machinery activates;
2. gears/flywheel begin turning;
3. launcher moves;
4. cable deployment begins;
5. upper connection appears/locks;
6. cable tensions;
7. route activates;
8. citizens begin climbing.

No projectile physics are required.

No rope simulation is required.

The visible sequence must correspond to actual traversal activation state.

---

## 30. Cable Presentation

The cable must look correctly scaled for half-inch citizens.

Requirements:

- clearly visible at citizen/settlement view;
- not absurdly thick at room view;
- visibly attached to lower and upper mechanisms;
- visually stable;
- no obvious floating endpoints;
- no requirement for rope physics.

A Curve3D/tube or equivalent generated mesh remains acceptable if presentation quality is sufficient.

---

## 31. Effects

Introduce restrained visual effects.

Candidates include:

- steam;
- smoke;
- sparks;
- dust;
- construction debris particles;
- subtle light glow;
- tiny exhaust puffs.

Effects must reinforce actions and machinery.

Avoid excessive particles that obscure the miniature scale or reduce performance.

---

## 32. Camera Presentation

Preserve the free strategy camera.

Improve presentation where useful:

- smoother motion;
- smoother zoom;
- sensible near/far clipping;
- close-up stability;
- optional focus behavior;
- improved framing defaults.

The camera must still support:

- room view;
- settlement view;
- citizen view.

The new visual assets must survive inspection across all three.

---

## 33. Vertical Slice Scope

POC 3 must remain narrow.

The canonical visual vertical slice contains:

- one selected RoomDefinition;
- one complete room;
- one settlement;
- approximately 50 citizens;
- several major furniture objects;
- one elevated target;
- one grapple construction/deployment;
- one traversal route;
- post-traversal activity.

Do not require every RoomScale semantic object type to receive final art.

The pipeline matters more than breadth.

---

## 34. Canonical POC 3 Room

Select one existing RoomScale room as the canonical visual benchmark.

Prefer the room that best demonstrates:

- human-room scale;
- clear furniture;
- visible settlement;
- elevated target;
- compelling grapple sequence;
- strong camera viewpoints.

Do not create POC-3-specific gameplay rules for this room.

The room remains an ordinary RoomDefinition.

---

## 35. Existing Room Compatibility

POC 3 must not break:

- Room A;
- Room B;
- the canonical POC 2 reconstructed room, once available.

Rooms without premium visual mappings should use:

- semantic asset defaults;
- procedural fallback assets;
- existing RoomDefinition appearance data.

A room should not require hand-authored visual overrides merely to remain usable.

---

## 36. Visual Benchmark Capture

Create deterministic screenshot capture positions.

At minimum capture:

1. room overview;
2. settlement overview;
3. settlement close view;
4. citizen close view;
5. citizen carrying resources;
6. grapple under construction;
7. complete grapple;
8. grapple deployment;
9. citizen climbing;
10. citizens active on elevated surface.

Capture equivalent baseline images from the pre-POC-3 build where practical.

The repository should preserve before/after evidence.

---

## 37. Screenshot Comparison

POC 3 visual acceptance is partly subjective.

Automated image metrics are not sufficient to determine whether art is good.

However, automated screenshot capture is required so visual review is repeatable.

The acceptance evidence should include:

- fixed camera transform;
- room identifier;
- build/version;
- screenshot filename;
- relevant simulation state;
- baseline screenshot where available;
- final screenshot.

The user should not be required to manually stage screenshots.

---

## 38. Visual Review Gate

Aphrael/Sol must not mark a visual milestone complete merely because:

- an asset imports;
- no error occurs;
- a shader compiles;
- a model technically renders.

The asset must be inspected through captured evidence.

Review should check for obvious defects such as:

- wrong scale;
- wrong orientation;
- floating geometry;
- missing materials;
- broken textures;
- bizarre generated topology;
- visual mismatch with art direction;
- clipping;
- unreadable citizen silhouettes;
- oversized or undersized props.

Where available, image-capable review should be used.

---

## 39. Performance

POC 3 must preserve acceptable performance with approximately 50 active citizens.

The art pass must avoid unreasonable:

- draw-call explosion;
- extremely high polygon counts;
- excessive transparent particles;
- excessive shadow-casting lights;
- oversized texture memory;
- per-citizen unique materials;
- per-frame expensive presentation logic.

Use techniques such as shared assets/materials and instancing where appropriate.

Optimization should be evidence driven.

---

## 40. Performance Measurement

Record at least:

- average or representative FPS;
- major frame-time spikes if observable;
- approximate draw-call/object counts where practical;
- loaded asset count;
- obvious memory issues;
- citizen count.

Compare against the pre-POC-3 build if practical.

Do not destroy visual quality merely to optimize a problem that has not been measured.

---

## 41. LOD / Distance Strategy

POC 3 should define a simple distance strategy if needed.

Examples:

- reduced citizen detail at room view;
- disabling tiny mechanical effects at long distance;
- simpler shadows beyond a threshold;
- simplified settlement props at room scale.

A complex production LOD system is not required unless performance demands it.

---

## 42. Test Architecture

Preserve existing gameplay tests.

Add visual/pipeline tests where deterministic verification is possible.

Automated tests should verify:

- visual catalog loads;
- mapped assets exist;
- fallback assets resolve;
- generated/imported GLB assets import;
- asset normalization metadata parses;
- material definitions load;
- citizen visual instances spawn;
- 50 citizens remain active;
- construction stages change with real progress;
- grapple deployment visual state tracks traversal state;
- all required benchmark scenes launch without errors.

Do not attempt to replace visual review with unit tests.

---

## 43. Regression Gate

Before major presentation changes:

1. run the existing fast deterministic tests;
2. run the canonical complete gameplay scenario;
3. record baseline status.

After each major visual subsystem change:

1. rerun relevant fast tests;
2. run the affected scene;
3. inspect screenshot evidence;
4. rerun the complete gameplay scenario when shared runtime systems changed.

At final verification, prior functional acceptance criteria must still pass.

---

## 44. Anti-Fake Requirement

POC 3 visual improvements must correspond to real runtime content.

Permitted:

- generated meshes;
- imported meshes;
- procedural meshes;
- simplified animation;
- scripted deployment;
- particle effects;
- stylized materials;
- coarse construction stages;
- visual role variants.

Not permitted:

- using rendered concept art as fake gameplay;
- replacing live scenes with pre-rendered backgrounds;
- screenshots from Blender presented as RoomScale output;
- manually staged scenes disconnected from simulation;
- fake citizens added only for screenshots;
- fake construction state;
- fake traversal animation;
- hidden manual asset placement;
- hand-correcting canonical scenes in the Godot editor and treating them as automated.

If it looks impressive, it must be the actual running RoomScale build.

---

## 45. Repository Structure

Exact layout may vary, but POC 3 should establish clear homes for visual content.

Example:

```text
assets/
  furniture/
  civilization/
  citizens/
  traversal/
  props/
  materials/
  textures/
  generated/

visual/
  catalog/
  recipes/
  normalization/

scripts/
  visuals/
  asset_pipeline/

verification/
  poc3/
    baseline/
    final/
    logs/
```

Generated or licensed content should be organized so its provenance is understandable.

---

## 46. Asset Provenance

Maintain metadata for non-original external/generated assets.

Where applicable record:

- asset name;
- source;
- generation tool/service;
- generation prompt or recipe when useful;
- generation date;
- license/usage terms;
- modifications;
- intended semantic mapping.

Do not commit assets with unclear or incompatible usage rights.

---

## 47. Documentation

Update repository documentation to describe:

- POC 3 purpose;
- visual architecture;
- asset resolver;
- asset catalog;
- fallback behavior;
- how generated assets enter the project;
- how assets are validated;
- how materials are defined;
- how screenshot verification works;
- how to rerun visual benchmarks;
- performance notes;
- external-tool setup if applicable.

Another Aphrael/Sol session should be able to continue without relying on conversation history.

---

## 48. Milestone 0 — Baseline and Regression Gate

Preserve the current known-good RoomScale state.

Tasks:

1. run existing deterministic tests;
2. run complete canonical gameplay;
3. capture current screenshots at the planned benchmark views;
4. record current presentation limitations;
5. identify current rendering/performance baseline.

### Exit Condition

A reproducible pre-POC-3 baseline exists and functional gameplay passes.

---

## 49. Milestone 1 — Visual Architecture

Implement:

- visual-resolution layer;
- asset catalog/registry;
- semantic mapping;
- fallback resolution;
- separation from gameplay geometry.

### Exit Condition

A RoomDefinition object can resolve to a preferred visual representation without gameplay systems knowing which render asset was selected.

---

## 50. Milestone 2 — Material and Lighting Foundation

Implement:

- stylized material library;
- improved room materials;
- improved environment/lighting;
- shadows and depth cues;
- required rendering configuration.

### Exit Condition

The existing blockout room shows a substantial presentation improvement before major mesh replacement.

---

## 51. Milestone 3 — Furniture Fidelity

Upgrade a limited set of important room objects.

Required canonical set should include approximately:

- desk;
- chair;
- bookshelf/dresser/cabinet;
- one or two additional major props.

Use the reusable visual-resolution pipeline.

### Exit Condition

Major furniture no longer reads primarily as raw primitive blocks at settlement and citizen viewing distances.

---

## 52. Milestone 4 — Automated 3D Asset Pipeline Experiment

Select at least one meaningful asset category and exercise the complete automated generation/import pipeline.

Prefer a non-trivial asset such as:

- desk;
- chair;
- steampunk workshop;
- grapple machinery;
- citizen base model.

### Exit Condition

At least one externally generated or AI-assisted 3D asset is automatically acquired/generated, normalized, validated, imported, resolved, rendered, and evidenced without manual Blender/Godot asset repair.

If the experiment demonstrates that current external generation tools are unsuitable, document the evidence and use a different automated strategy. The milestone is about establishing the correct pipeline, not forcing a failed provider.

---

## 53. Milestone 5 — Citizen Visual Pass

Implement:

- improved citizen model;
- visual role variants;
- improved motion;
- carrying representation;
- builder representation;
- climber representation.

### Exit Condition

Individual citizens look intentional and recognizable at citizen view while approximately 50 remain viable simultaneously.

---

## 54. Milestone 6 — Settlement Visual Pass

Upgrade:

- workshop;
- storage;
- housing/tents;
- work area;
- props;
- lighting;
- ambient mechanical activity.

### Exit Condition

The settlement reads unmistakably as a tiny steampunk civilization rather than a set of placeholder blocks.

---

## 55. Milestone 7 — Grapple Hero Sequence

Upgrade:

- construction stages;
- machinery;
- gears/winch;
- cable;
- anchors;
- deployment;
- effects;
- climbing presentation.

### Exit Condition

The complete grapple sequence is visually understandable and compelling from construction through first traversal.

---

## 56. Milestone 8 — Integrated Visual Vertical Slice

Run the complete canonical scenario:

**settlement activity → target selection → investigation → resource transport → construction → grapple deployment → climb → elevated exploration**

with the new visual presentation.

### Exit Condition

The entire sequence runs from a clean start without developer intervention and maintains visual coherence across room, settlement, and citizen views.

---

## 57. Milestone 9 — Performance and Stability

Profile the integrated visual slice.

Fix demonstrated issues involving:

- unacceptable frame rate;
- severe frame spikes;
- broken imports;
- asset-loading failures;
- excessive visual-system CPU cost;
- major rendering errors.

### Exit Condition

Approximately 50 citizens and the enhanced environment run without obvious presentation-induced simulation stalls on the target PC.

---

## 58. Milestone 10 — Final Visual Verification

Generate the fixed benchmark screenshot set.

Compare against baseline.

Review:

- room recognizability;
- material quality;
- scale perception;
- furniture quality;
- settlement identity;
- citizen readability;
- construction readability;
- grapple quality;
- lighting;
- effects;
- overall game-like presentation.

### Exit Condition

POC 3 satisfies the visual acceptance criteria and preserves previous functional behavior.

---

# 59. Acceptance Criteria

### AC-01 — Functional Regression

Existing RoomScale gameplay continues to function after POC 3 changes.

### AC-02 — Visual Layer Separation

Gameplay/navigation logic does not depend on detailed presentation meshes.

### AC-03 — Visual Resolver

Semantic room/civilization objects can resolve to presentation assets through a dedicated visual layer.

### AC-04 — Asset Catalog

Preferred assets and fallbacks are defined through an inspectable centralized catalog/registry rather than scattered hard-coded asset paths.

### AC-05 — Procedural Fallback

Failure or absence of a premium visual asset does not make a valid RoomDefinition unusable.

### AC-06 — Improved Room Materials

Walls, floor, rug/carpet, and major furniture no longer share generic placeholder material behavior.

### AC-07 — Material Readability

Wood, brass, dark metal, cloth/leather, rope, wall, and floor materials are visually distinguishable where used.

### AC-08 — Improved Lighting

The canonical scene uses deliberate lighting/shadows/environment settings that materially improve depth and presentation.

### AC-09 — Scale Readability

The room clearly communicates that citizens are approximately half an inch tall.

### AC-10 — Furniture Detail

Canonical major furniture objects contain enough structure and shape detail not to read primarily as simple boxes.

### AC-11 — Desk Quality

The primary elevated target visually reads as an intentional furniture asset at close viewing range.

### AC-12 — Asset Pipeline

A repeatable automated asset-ingestion pipeline exists.

### AC-13 — Generated Asset Experiment

At least one meaningful AI-assisted/external generated 3D asset passes the automated pipeline and appears correctly in running RoomScale, or the attempted approach is rejected with evidence and replaced by a viable automated alternative.

### AC-14 — Asset Validation

Invalid or unusable assets are detected with actionable diagnostics.

### AC-15 — Asset Normalization

Imported assets can be normalized for RoomScale orientation/scale without requiring routine manual Blender correction.

### AC-16 — No Manual Art Requirement

The POC can be built and reproduced without requiring the user to model, rig, texture, orient, or manually place assets.

### AC-17 — Citizen Redesign

Citizens have a substantially improved intentional visual design.

### AC-18 — Citizen Close View

Citizens remain visually coherent at citizen-view camera distance.

### AC-19 — Citizen Role Readability

Explorer, builder, carrier, or equivalent major activity roles have useful visual differentiation.

### AC-20 — Citizen Movement Presentation

Idle, movement, carrying, building, and traversal states have visually distinct animation/presentation.

### AC-21 — Fifty-Citizen Population

Approximately 50 visual citizen instances can coexist while normal simulation continues.

### AC-22 — Settlement Redesign

The canonical settlement reads as a tiny steampunk/clockwork settlement rather than placeholder structures.

### AC-23 — Settlement Detail

Workshop, storage, housing, and work area contain meaningful visual differentiation.

### AC-24 — Ambient Mechanical Activity

At least some settlement machinery/effects provide continuous visual life without faking simulation state.

### AC-25 — Resource Readability

Transported wood, metal, and mechanical-part resources are visually recognizable or clearly differentiated.

### AC-26 — Grapple Redesign

The traversal installation reads as a believable tiny steampunk mechanical device.

### AC-27 — Visible Construction Stages

The grapple/hero structure visibly evolves with actual construction progress.

### AC-28 — Visible Deployment

The completed traversal system performs a visible deployment sequence before route activation.

### AC-29 — Cable Quality

Cable thickness, placement, and attachment are visually believable relative to citizen scale.

### AC-30 — Climbing Presentation

Citizens visibly traverse the enhanced route without teleportation.

### AC-31 — Effects

Steam/smoke/sparks or equivalent effects reinforce selected machinery and construction without overwhelming the scene.

### AC-32 — Camera Compatibility

The enhanced visuals remain usable at room, settlement, and citizen viewing scales.

### AC-33 — Existing Room Compatibility

Room A and Room B remain loadable and playable.

### AC-34 — POC 2 Room Compatibility

The canonical reconstructed room remains loadable/playable once available, using visual defaults/fallbacks where dedicated art is absent.

### AC-35 — Fixed Screenshot Benchmarks

The project can automatically reproduce the canonical visual screenshot set.

### AC-36 — Baseline Evidence

Pre-POC-3 screenshots are preserved where practical for direct comparison.

### AC-37 — Runtime Evidence

Final visual evidence comes from the actual running RoomScale build.

### AC-38 — No Staged Fake Demo

No required acceptance screenshot depends on manually staged developer-only scene state.

### AC-39 — Performance

The enhanced vertical slice does not introduce obvious rendering-induced stalls with approximately 50 citizens on the target PC.

### AC-40 — Asset Provenance

External/generated assets have adequate provenance and licensing metadata.

### AC-41 — Repository Documentation

The visual architecture and asset workflow are documented well enough for a fresh Aphrael/Sol session to resume work.

### AC-42 — Full Visual Gameplay Loop

The canonical vertical slice completes:

**select target → investigate → deliver resources → construct → deploy → climb → explore → autonomous reuse**

using the enhanced presentation.

### AC-43 — Game-Like Presentation

At settlement and citizen view, the canonical RoomScale vertical slice should visually read as an intentional stylized game rather than primarily as a technical visualization of game systems.

This criterion requires human visual review of the generated evidence.

---

## 60. Explicitly Out of Scope

POC 3 does not require:

- production-quality art for every RoomScale object;
- photorealism;
- physically based rope simulation;
- projectile-based grappling;
- realistic cloth simulation;
- realistic fluid simulation;
- motion-captured animation;
- facial animation;
- lip synchronization;
- unique citizen faces;
- unique citizen clothing;
- hundreds of citizen variants;
- full character customization;
- production-ready LOD system;
- production-ready texture streaming;
- open-world asset streaming;
- full post-processing suite;
- cinematic cutscenes;
- manual Blender cleanup workflow;
- manual Godot scene authoring;
- conversion of every existing procedural object to a bespoke asset;
- a commercial asset marketplace dependency;
- paid asset-generation services without approval;
- deeper economy;
- combat;
- diplomacy;
- technology trees;
- new civilization simulation systems;
- multiple civilization art styles;
- photo-real texture reconstruction from the POC 2 photographs;
- final UI redesign;
- final audio;
- music;
- sound-effect production.

Do not expand scope without explicit approval.

---

## 61. Failure Policy

When a visual implementation fails:

1. preserve the failing asset/code/configuration;
2. capture the actual runtime/import error or visual evidence;
3. identify whether the defect belongs to:
   - source asset;
   - generation provider;
   - asset normalization;
   - Godot import;
   - material system;
   - visual resolver;
   - animation;
   - renderer;
   - performance;
   - RoomDefinition appearance metadata;
4. correct the generalized layer where possible;
5. rerun the affected automated tests;
6. relaunch the actual scene;
7. capture new screenshot evidence;
8. rerun gameplay regressions if shared systems changed.

Do not solve a pipeline problem by manually repairing each canonical asset unless that repair itself can be automated and generalized.

---

## 62. Definition of Done

RoomScale POC 3 is complete when:

1. the existing RoomScale simulation still functions;
2. a formal visual-resolution layer cleanly separates presentation assets from gameplay geometry;
3. major room furniture no longer appears primarily as raw primitive blocks;
4. materials and lighting provide strong visual depth and material differentiation;
5. approximately 50 improved citizens remain active;
6. the settlement clearly reads as a miniature steampunk/clockwork civilization;
7. resource transport and construction are visually understandable;
8. the grappling mechanism has a strong visual construction and deployment sequence;
9. citizens visibly climb the completed route;
10. at least one automated AI-assisted/external 3D asset workflow has been seriously tested and integrated or rejected with evidence in favor of a viable automated alternative;
11. no routine Blender/Godot art-authoring work is required from the user;
12. fixed-camera screenshots provide reproducible before/after visual evidence;
13. performance remains acceptable on the target PC;
14. existing rooms remain compatible through preferred visuals or procedural fallbacks;
15. a human reviewer looking at the settlement/citizen-scale result can reasonably recognize it as a stylized game presentation rather than a blockout.

The desired end state is:

**RoomDefinition + RoomScale simulation**
→ **semantic visual resolution**
→ **automated/procedural/generated stylized assets**
→ **coherent materials, lighting, effects, and animation**
→ **a compelling miniature civilization running inside an ordinary human room**

That is RoomScale POC 3.
