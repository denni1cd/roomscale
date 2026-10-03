# RoomScale POC 4.6 final report

## Result

PASS: compact fishbowl spectator presentation, authoritative context and event cards,
automatic camera titles/details, hidden diagnostics, 10x startup, and safe separated
cohort arrivals. All 60 acceptance criteria are mapped in [acceptance.md](acceptance.md).

Branch: `codex/roomscale-poc46-spectator-ui`.
Baseline: `c0b93c5dd74081bc20068b7455ec9805dc5fb71d`.
Implementation commit: recorded in the release commit receipt below after code commit.
Main was not merged. User explicitly waived Aphrael for this work.

## Changes

- Narrative adapter maps production state/journal into friendly language without
  changing decisions. Event presenter has an eight-card priority queue and 128-key
  dedupe history; major cards last eight real seconds, minor cards five.
- Compact HUD reads live stock, reserves, population/shelter, governor and project
  work/materials. Details/F3 exposes preserved diagnostics and journal. Quiet UI
  fades to 76% after ten real seconds and wakes on events or interaction.
- Camera holds shots at least eight real seconds, favors major production events,
  returns to overview every forty seconds and follows actual workers. Titles expire
  after six seconds and hide if the described task changes. Live subtitles avoid
  stale population counts. Subject displacement compensation keeps workers visible
  at 10x while the initial camera offset eases into place.
- Fishbowl defaults to 10x, normal/manual to 1x; Pause/1x/4x/10x remain authoritative.
- Cohort admission selects five deterministic distinct grid centers within sixteen
  inches of the safe arrival anchor, checks obstacles/bounds/connectivity and uses
  four-inch separation. Failure blocks the entire cohort before creating nodes.
- Development task progress reads development work instead of traversal progress.
- New development housing/workshop visuals now use citizen proportions: 0.7-inch
  doors versus 0.5-inch citizens, 0.9-inch floors, two-storey housing and one-storey
  workshop. Existing navigation footprint, costs, work and capacity are preserved.

Main implementation files: `fishbowl_hud.gd`, `fishbowl_narrative_adapter.gd`,
`fishbowl_event_presenter.gd`, `fishbowl_camera_director.gd`, `population_system.gd`,
`civilization_simulation.gd`, `task_coordinator.gd`, `settlement_development_system.gd`.
Tests: `TEST_ROOM_SCALE_POC46.ps1` and four `poc46_*_test.gd` scripts.

## Verification

| Gate | Result |
|---|---|
| Before edits: POC45 fast/scenario | PASS; 9.17 / 69.80 seconds |
| Before edits: POC4 fast/contract/cleanup | PASS; baseline retained |
| After edits: POC45 fast | PASS; 11.36 seconds |
| After edits: POC4 fast/contract/cleanup | PASS; 21.91 / 0.35 / 0.55 seconds |
| Three consecutive fresh eight-day runs | PASS; 62.64 / 63.08 / 59.95 seconds |
| Final fast suite | PASS; 0.71 seconds, including scale, tracking and title checks |
| Final rendered eight-day scenario | PASS; 63.39 seconds |
| Uninterrupted automatic worker detail | PASS; image inspected |
| Real normal/fishbowl launcher smoke | PASS; logged 1.0 / 10.0 defaults |
| 1080p and 1440p layout / F3 / controls | PASS; automated assertions and rendered review |

All three repeatability runs end at 80 real citizens, shelter 90, four housing blocks,
one workshop and zero failed tasks. Wood consumed is 52 and metal consumed 16;
remaining available wood is 16 and metal 0. Conservation checks pass. Survival,
salvage, traversal and expansion use production systems without scenario stock
injection, scripted strategic decisions or citizen relocation. Isolated fast fixtures
are explicitly separate from autonomous scenario tests.

Scenario timings measure accelerated verification, not gameplay FPS. No new frame-rate
benchmark or sixty-day stability run is claimed. Later scale/camera edits are
presentation-only; final rendered scenario and fast suite were rerun after them.

The first launcher checker expected `10` while Godot logged `10.0`; the smoke receipt
records the corrected interpretation of actual startup output. Visual iterations
found and corrected issues listed in [visual-review.md](visual-review.md). Intermediate
captures are retained locally; final captures are the release evidence.

## Remaining limits

Legacy initial settlement geometry is unchanged. Citizens remain tiny in whole-room
views. At 10x arrivals promptly disperse and historical event cards can trail the
live action; dates distinguish event history from current context. Resource limits
remain finite, with no new save/load or runtime LLM/API planning. No manual Godot
editor work is required.

See [spectator guide](../../docs/POC46_SPECTATOR.md) for controls and verification
commands, and [visual-review.md](visual-review.md) for capture methods and coverage.
