# Milestone 4 — Validation and Repair

Status: **PASS — attempt 2 passes structural and runtime-navigation validation.**

The documented same-context AI repair loop was exercised. Attempt 1 was preserved unchanged; it was not hand-edited or validated using a modified copy in place.

## Attempts

| Attempt | Candidate | Validator evidence | Result |
| --- | --- | --- | --- |
| 1 — original Luna generation | `verification/poc2/candidates/primary/attempt-1/room_photo_luna.json` | `verification/poc2/candidates/primary/attempt-1/validation.log` | FAIL, exit code 1. Exact structural errors: `object computer_desk bounds exceed the room floor`; `object hammock bounds exceed the room floor`. `derived` and `navigation_errors` were empty because structural validation stopped before runtime-navigation checks. |
| 2 — AI repair | `verification/poc2/candidates/primary/attempt-2/room_photo_luna.json` | `verification/poc2/candidates/primary/attempt-2/validation.log` | PASS, exit code 0. Schema and runtime navigation both pass; 6 generated blocking obstacles, 3 reachable target approaches, and reachable construction site `[82.0,0.0,-78.0]` for target `DESK_SURFACE`. |

The attempt 2 repair changed only the desk navigation padding from `[5,0,4]` to `[5,0,1]`, and the hammock padding from `[2,0,2]` to `[0,0,2]`. The validator-reported footprint overflow was resolved while the photo-estimated object positions, sizes, rotation, target, and visual appearance stayed unchanged. Details are in `verification/poc2/candidates/primary/attempt-2/repair-response.md`. This used one repair attempt, within the skill's three-attempt limit.

## Reproduction

```powershell
./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-1/room_photo_luna.json -LogPath verification/poc2/candidates/primary/attempt-1/validation.log
./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/candidates/primary/attempt-2/room_photo_luna.json -LogPath verification/poc2/candidates/primary/attempt-2/validation.log
```

Both commands used the repository's `VALIDATE_ROOM_SCALE.ps1` wrapper and packaged Godot 4.7.2. The final candidate path is `verification/poc2/candidates/primary/attempt-2/room_photo_luna.json`; its JSON `id` matches its filename. This milestone's scope is structural and derived-navigation validation. Separate M5/M6 evidence now records production visual review and gameplay runs for this unchanged candidate; it does not change the candidate validation result above.
