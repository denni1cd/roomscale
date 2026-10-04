# POC 4.7: five founders

```powershell
./RUN_ROOM_SCALE_FISHBOWL.ps1
# Previous established colony, including its legacy 10x setting:
./RUN_ROOM_SCALE_FISHBOWL.ps1 -Room room_poc45
```

The canonical room is `room_poc47`. It starts at **1x with five CitizenAgents**,
20 food, 30 water, zero construction materials and no completed settlement buildings.
There is no shelter, rest capacity, storage capability, workshop or grapple.
Five small packs mark the portable cache. Pause, 1x, 4x, 10x, automatic camera,
citizen inspection and Details/F3 remain available. Normal launch remains manual.

This deliberately replaces POC 4.5's 50-person prebuilt settlement and POC 4.6's
10x canonical launch. `room_poc45` and its regression tests remain available.

## How the settlement is built

The existing governor evaluates every five simulation seconds. Its ordinary
survival directives, safe salvage policy and development interface now support
an empty start. Development considers shelter, depot, workshop and then housing.
Survival emergencies restrain new development. There are no worker commands in
the governor or verification scenario.

| Project | Wood | Metal | Base worker seconds | Completed benefit |
| --- | ---: | ---: | ---: | --- |
| Founder shelter | 4 | 0 | 60 | Five shelter places and five rest slots |
| Depot | 4 | 1 | 70 | Permanent storage capability around the cache apron |
| Workshop | 8 | 4 | 100 | Advanced construction; subsequent development needs 15% less work |
| Permanent housing | 10 | 2 | 90 | Ten shelter places and two additional rest slots |

Every project uses the existing economy reservations, physical citizen delivery,
builder tasks and navigation. Materials come from finite, authorized room salvage.
Projects never create stock. FOUNDATION/FRAME/SHELL/COMPLETE reflect actual supplied
materials and work. Primitive structures use a site outline before structural work,
then posts, enclosure and a roof. Completed structures persist as navigation obstacles.

Storage is built beside the original ground cache. The pickup apron remains in the
same place, so existing supplies and in-flight bundles are never relocated. Builders
receive construction materials at the depot's side approach. That approach is checked
against proposed navigation before accepting the site.

`has_capability()` reads initial infrastructure and **completed** development projects.
The Reach API and traversal project creation both reject advanced construction before
the workshop exists. The normal planner first uses accessible finite floor supplies;
when those run out, it can seek elevated supplies through ordinary Reach, construction,
deployment and climbing. The room includes a finite 60-unit water spill for bootstrap,
as well as the existing elevated water source. Neither replenishes.

## Population and demand

Founder growth adds **one real citizen**. Admission requires completed storage and
workshop, shelter headroom, healthy food/water forecasts, no survival emergency or
material blocker, a five-day finite source horizon and 300 sustained healthy seconds.
The cooldown is 600 seconds; the existing safety cap is 150. Projected food/water
reserves must still cover two days after admission.

Arrival uses a validated connected floor position. New nodes receive normal needs,
movement, self-care and shared production tasks. Cohort evidence records the immediate
decrease in reserve days from the larger population. Legacy growth remains five at
a time. This is abstract arrival, with no families, pregnancy, children or aging.

## Start data

The new optional `start` object contains `origin`, `population` and `infrastructure`.
The existing `spawn` defines the arrival region. Portable stock, `initial_speed` and
`cohort_size` live in `civilization`.

For an empty infrastructure list, RoomDefinition derives compatibility activity
anchors from the origin and sets shelter/rest capacity to zero. These floor anchors
grant no building capability and produce no settlement meshes. An empty start rejects
prebuilt settlement objects. Founder fallback activity is patrol rather than pretending
to maintain nonexistent buildings. Legacy definitions without `start` retain their
established settlement behavior.

## Measured pacing at 1x

The final deterministic production scenario observes:

| Event | Simulation time / equivalent 1x time |
| --- | ---: |
| First project requested | 5 seconds |
| Meaningful resource work | 12 seconds |
| First salvage work | 39 seconds |
| Material hauling | 49.3 seconds |
| First shelter completed | 2:36 |
| Depot completed | 3:44 |
| Workshop completed | 6:15 |
| Permanent housing completed | 8:00 |
| Sixth citizen | 13:05 |
| Grapple deployed | 24:07 |
| Elevated territory reached | 24:42 |

These are measured outcomes, not scripted deadlines. The live rendered test leaves
the normal `_process` clock and automatic camera running at 1x through first shelter
completion. The full eight-day observer advances identical production ticks efficiently.
The camera/presenter receive 0.1 presentation seconds per 0.1 simulated seconds in
that observer, matching the 1x relationship.

The pacing change is a five-second retry for temporarily occupied essential founder
sites, instead of the previous sixty-second development retry. Before this change,
passing citizens caused several unlucky retries and a four-minute wait after shelter.
Collision checks are unchanged; workers are never moved to clear a site. Material
unavailability retains a sixty-second retry. Existing need decay, walking speed,
salvage yields, housing/workshop costs and growth timers are unchanged.

## Verification

```powershell
./TEST_ROOM_SCALE_POC47.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC47.ps1 -Mode All
./TEST_ROOM_SCALE_POC47.ps1 -Mode Scenario -CaptureVisuals
# Real wall-clock 1x observer, approximately three minutes:
& ./.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . --script res://scripts/poc47_live_test.gd
./TEST_ROOM_SCALE_POC46.ps1 -Mode Scenario
./TEST_ROOM_SCALE_POC45.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC4.ps1 -Mode Scenario
./TEST_ROOM_SCALE_FAST.ps1
```

`All` requires three fresh complete eight-day founder scenarios. The observer checks
every tick for movement bounds, valid needs, shelter effects, workshop prerequisites,
economy/source/bundle conservation and source-backed material generation. It also
checks real work/delivery records, exact project consumption, visible stages, real
growth, increased demand, cooldowns and task/project age. Rendered mode uses dummy
audio to avoid an unrelated Windows output-device invalidation seen in the baseline.

See [final report](../verification/poc47/final-report.md),
[acceptance matrix](../verification/poc47/acceptance.md),
[milestones](../verification/poc47/milestones.md) and
[visual review](../verification/poc47/visual-review.md).

## Limits

Finite room resources eventually exhaust. The final eight-day check reaches 12 citizens;
it is not a new sixty-day or 150-citizen performance claim. The live 1x check covers
the opening three minutes; later pacing is measured using production tick time.
Art remains procedural and primitive buildings are deliberately simple. Citizens
remain tiny in whole-room shots. Save/load, crafting, farming and runtime model
planning are outside this milestone.
