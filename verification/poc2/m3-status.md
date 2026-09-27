# Milestone 3 — First Canonical Reconstruction

Status: **PASS — first-pass candidate produced. M4 structural/runtime-navigation validation also passes after one documented AI repair.**

The current Luna reconstruction context used only the packaged reconstruction skill and its current references, the authoritative contract/plan, and direct visual inspection of the four canonical photographs. The candidate was authored from the photo evidence; it was not modeled in Godot, copied from a Room A/B layout, or manually repaired after generation.

| Artifact | Path | Status |
| --- | --- | --- |
| Original first-pass RoomDefinition | `verification/poc2/candidates/primary/attempt-1/room_photo_luna.json` | Preserved unchanged; its failed validation diagnostics remain beside it. |
| Photo evidence and uncertainty note | `verification/poc2/candidates/primary/attempt-1/reconstruction-note.md` | Records four-view inventory, coordinate hypothesis, scale estimates, object relationships, ambiguity, and renderer limitations. |
| Repaired/final validator candidate | `verification/poc2/candidates/primary/attempt-2/room_photo_luna.json` | Current candidate after reducing only desk/hammock navigation padding in response to validator diagnostics. |
| Repair provenance | `verification/poc2/candidates/primary/attempt-2/repair-response.md` | Exact failure-to-correction mapping; all photo-estimated room geometry and appearance remain unchanged. |
| Attempt 1 validation output | `verification/poc2/candidates/primary/attempt-1/validation.log` | Retained first-pass failure diagnostics. |
| Attempt 2 validation output | `verification/poc2/candidates/primary/attempt-2/validation.log` | PASS: schema plus derived-navigation validation. |

The first pass represents the deep green shell, turquoise ceiling, heavy wood trim, two large windows, French-door opening, computer desk/monitors and raised desk target, glass-front cabinet, hammock, rocking chair, green stool, lamp, and large wall art. Exact scale/orientation and some architectural details remain estimates; the note lists them. No new photo request was necessary for a coherent playable approximation.

The AI repair loop used one attempt after the first pass. Attempt 1 failed structural bounds checks; attempt 2 passed with six generated blockers, three reachable target approaches, and construction site `[82,0,-78]`. The exact validator command and results are in `verification/poc2/m4-status.md`. Production visual and full-loop runs later used the unchanged attempt 2 candidate; their distinct M5/M6 evidence and visual limitations are recorded in `verification/poc2/m5-status.md` and `verification/poc2/m6-status.md`.
