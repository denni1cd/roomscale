# POC 4.7 milestone record

Branch: `codex/roomscale-poc47-founder-start`. Baseline:
`801060bd3b265e5fcb2d207b36434f9149d31e3a`. Main was not merged.

| Milestone | Result | Implementation and gate evidence |
| --- | --- | --- |
| M0 Baseline | PASS | POC46 fast, full rendered eight-day scenario, POC45 fast, POC4 fast/contract/cleanup ran before production edits; `baseline/`. |
| M1 Founder start | PASS | Room-defined population/origin/empty infrastructure, portable supplies, zero capabilities, 1x config; final fast checks and actual launcher receipt. |
| M2 Primitive construction | PASS | Shelter uses finite salvage, delivery tickets and CitizenAgent work; all ticks check earned shelter capacity; final scenario and shelter-stage images. |
| M3 Settlement establishment | PASS | Depot/workshop physically supplied and built; capabilities read completed projects; final project records and render checkpoints. |
| M4 Organic growth | PASS | Individual admission, real nodes, reserve drop, sustained stability/cooldowns; negative fast gates and full scenario cohort records. |
| M5 1x pacing | PASS | Five-second retry removes transient site blockage gap; production timeline, actual 1x launcher and live rendered first-shelter observation. |
| M6 Advanced expansion | PASS | Reach/project APIs require workshop; ordinary deployment and physical climb reach elevated resources. |
| M7 Spectator integration | PASS | Founder framing, individual arrival camera, milestone cards, primitive build stages, compact HUD; final POC46 fast regression and visual review. |
| M8 Full founding scenario | PASS | Three fresh eight-day production runs plus rendered full run; no strategic test commands or injected stock. |
| M9 Verification/docs | PASS | Acceptance matrix, repeatability fingerprints, guide, README/current plan, evidence and final report. |

## Corrections made during verification

- Baseline rendered gameplay passed all assertions, but its wrapper rejected a Windows
  WASAPI output-device invalidation. A fresh rendered run with `--audio-driver Dummy`
  passed without the audio error. The failed wrapper receipt and clean rerun remain.
- The initial observer had a GDScript inferred-type error. Explicitly typing its
  shelter total fixed parsing. A later observer assertion compared dictionaries with
  integer requirements and floating deliveries; it now compares numeric quantities.
- Depot deliveries originally shared the cache approach. They now go to a distinct
  side approach, with actual route/distance checks and proposed-navigation validation.
- Initial renders showed a solid primitive floor at the planned stage. A site outline
  now precedes material-backed structural stages. Founder startup framing was tightened;
  manually framed screenshots hide unrelated automatic-camera titles.
- Sixty-second retries of a temporarily occupied depot site delayed establishment.
  Five-second essential-site retries reduced depot completion from 464.8 to 223.8
  seconds and workshop completion from 606.9 to 374.5 seconds. Safety checks remain.
- The launcher smoke initially waited for its PowerShell parent, which exits after
  detaching the GUI. The corrected receipt validates the actual Godot startup line;
  cleanup targeted only the child with that recorded parent PID.
- A live rerun exited without its completion marker. The authoritative live result
  uses a fresh directory and a runner that requires a fresh PASS marker, result and
  successful process exit. Earlier local iterations are not release evidence.

Intermediate checks ran as systems were added; final fast/full/rendered gates cover
the combined implementation. Historical verification files were not rewritten.
