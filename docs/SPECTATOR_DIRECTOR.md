# Spectator Director (POC 5.5)

The observer controls sit beside the ordinary simulation speed controls. **OFF / FREE** leaves the camera with you and keeps recent stories/alerts running. **PRIORITY** chooses important eligible stories. **RANDOM** cruises across societies and real activity, including ordinary work. Choose a live subject from the subject selector to **FOLLOW** it. Citizens, active projects/sites and active conflicts use stable identities, resolved against current state. Ended/invalid Follow targets return to OFF without a replacement.

Right-drag orbit, middle-drag pan, wheel zoom, WASD/arrows, Q/E, presets 1/2/3 and intentional citizen selection immediately return the Director to OFF. It stays OFF until you explicitly choose a mode or Follow target. No idle timer or new event re-enables it. Programmatic Director requests do not emit manual-input signals.

The persistent recent-story feed is bounded to 64 cards (about eight visible at 1080p, with scrolling). Each card shows priority, day, relevant society, headline and context. Click an enabled card to smoothly frame a live subject, project/site/conflict, or its stored historical location. The yellow ring identify the selection for four seconds, following a live subject when available. The camera then remains yours. Events with no valid focus remain readable and disabled. F3 opens technical diagnostics and citizen inspection.

## Authority and extension

Simulation systems publish facts through the existing `EventJournal.record(seconds, kind, message, evidence, focus, suppression_key, context)` call. Existing six-argument producers remain valid. An omitted focus is explicitly invalid; an explicit finite origin is valid. Context contains normalized society/civilization, subject, project/site/conflict, related entity and story identity plus genuine domain state. `configure_context` supplies society defaults. `validate` reports malformed records. Journal sequence and bounded duplicate suppression remain authoritative.

`spectator_sources.gd` makes detached snapshots of existing world/society journals, sorted by seconds/source/id. Source-qualified keys prevent local sequence collisions. It is an adapter, not another durable history. `event_fact_context.gd` constructs fact context at existing producers.

Add event presentation policy in `spectator_event_catalog.gd` and narrative text in `fishbowl_narrative_adapter.gd`. Priority, category, framing, duration and eligibility are presentation policy. The four levels are Critical, High, Medium and Low. Unknown kinds become readable Low cards. Ordinary work is eligible for Random and not an ordinary Priority interrupt. Event-local civilization data drives terminology; Director core has no civilization-ID branches.

The existing `fishbowl_camera_director.gd` owns selection/state, and the existing `strategy_camera.gd` owns physical transforms/interpolation. `manual_camera_input(action)` is the explicit ownership boundary. `request_spectator_frame` does not emit it. `spectator_target.gd` descriptors use stable identity rather than retaining a stale Node as identity. New user-facing camera actions must emit the manual-input contract.

Automatic shots normally dwell eight real seconds, independent of simulation speed. Critical stories may take the next cut after five seconds. Bounded story/subject/location history restrains repetition; a room-wide context shot returns around forty seconds. Random uses a dedicated seedable RandomNumberGenerator; it never touches simulation RNG. Society-first then activity-class sampling prevents a busy event stream from crowding out quiet societies.

All observers are read-only to resources, tasks, needs, governor, military, equipment, navigation and deterministic clock/order. Event clicks and highlights issue no citizen orders. Military facts are transitions (equipment/readiness, muster, deployment, battle, casualties, retreat, capture and return), never attack/HP/path tick logs.

## Verification commands

From the repository root in PowerShell:

```powershell
./TEST_ROOM_SCALE_POC55.ps1 -Mode Focused
./TEST_ROOM_SCALE_POC55.ps1 -Mode Isolation
./TEST_ROOM_SCALE_POC55.ps1 -Mode Graphics
./TEST_ROOM_SCALE_POC46.ps1 -Mode Fast
./TEST_ROOM_SCALE_POC54.ps1 -RunCount 2
```

Graphics requires a real renderer. It captures the Director on a major event, Random on ordinary work, multiple priorities, click highlight, manual OFF, military framing and society identification. Review actual PNGs for text, occlusion, controls, clipping, zoom, framing and marker visibility. A headless pass cannot prove graphical quality.

Isolation runs fresh three-party production scenarios in all four modes, comparing canonical simulation snapshots at 1000, 3000 and 6200 ticks. Snapshots include citizen/task/needs state, resources, economy, development/innovation, doctrine/equipment, military outcomes, casualties, retreat, capture and attack-order digest. The comparison excludes only TaskCoordinator wall-clock diagnostic fields `created_at`, `started_at`, `finished_at`, `picked_up_at`, and `delivered_at` (all populated by `Time.get_ticks_msec()`); task IDs, states, simulation timestamps, ownership and outcomes remain included. A fixed spectator seed reproduces Random traces.

## Superseded POC 4.6 camera assertions

The empty transient panel/decorative event-panel assertions are superseded by persistent readable bounded history with actual input capture and focus validity. Idle text fading is superseded by persistent feed readability. A boolean toggle is replaced by four explicit states. The old directly assigned activity shot/tracking heuristic is replaced by explicit stable-ID Follow, live focus resolution, physical rig convergence, invalid-target rejection and manual OFF persistence after 600 real seconds. Population, economy, navigation, construction and other gameplay assertions are retained. The new POC55 input harness dispatches real camera input and feed-row clicks in addition to testing shared contracts.
